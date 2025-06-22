#!/bin/bash

# Nextcloud監視・アラートスクリプト
# システムの健全性を監視し、問題を検出した際にアラートを送信

set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
MONITOR_LOG="/var/log/nextcloud-monitor.log"
STATUS_FILE="/tmp/nextcloud-status.json"

# 関数定義
error_exit() {
    echo -e "${RED}エラー: $1${NC}" >&2
    log_message "ERROR" "$1"
    exit 1
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
    log_message "INFO" "$1"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    log_message "WARN" "$1"
}

info() {
    echo -e "${BLUE}ℹ $1${NC}"
    log_message "INFO" "$1"
}

# ログ出力関数
log_message() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$MONITOR_LOG"
}

# 環境変数読み込み
load_env() {
    if [ -f "$ENV_FILE" ]; then
        set -a
        source "$ENV_FILE"
        set +a
    fi
}

# メール送信関数
send_alert() {
    local subject="$1"
    local message="$2"
    local priority="${3:-normal}"
    
    if [ -n "${EMAIL:-}" ] && command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "[$priority] Nextcloud Alert: $subject" "$EMAIL"
        log_message "INFO" "アラートメールを送信しました: $subject"
    else
        log_message "WARN" "メール送信が設定されていません: $subject"
    fi
}

# Slack通知関数（Webhook URL設定時）
send_slack_notification() {
    local message="$1"
    local color="${2:-warning}"
    
    if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
        local payload=$(cat <<EOF
{
    "attachments": [
        {
            "color": "$color",
            "title": "Nextcloud Monitor Alert",
            "text": "$message",
            "ts": $(date +%s)
        }
    ]
}
EOF
)
        curl -X POST -H 'Content-type: application/json' \
             --data "$payload" \
             "$SLACK_WEBHOOK_URL" >/dev/null 2>&1 || true
    fi
}

# システムリソース監視
check_system_resources() {
    local alerts=()
    
    # CPU使用率チェック
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        alerts+=("CPU使用率が高すぎます: ${cpu_usage}%")
    fi
    
    # メモリ使用率チェック
    local mem_info=$(free | grep Mem)
    local total_mem=$(echo $mem_info | awk '{print $2}')
    local used_mem=$(echo $mem_info | awk '{print $3}')
    local mem_usage=$(echo "scale=2; $used_mem * 100 / $total_mem" | bc)
    if (( $(echo "$mem_usage > 85" | bc -l) )); then
        alerts+=("メモリ使用率が高すぎます: ${mem_usage}%")
    fi
    
    # ディスク使用率チェック
    local disk_usage=$(df /var/www/nextcloud | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 85 ]; then
        alerts+=("ディスク使用率が高すぎます: ${disk_usage}%")
    fi
    
    local data_disk_usage=$(df /var/nextcloud-data | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$data_disk_usage" -gt 85 ]; then
        alerts+=("データディスクの使用率が高すぎます: ${data_disk_usage}%")
    fi
    
    # ロードアベレージチェック
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cpu_cores=$(nproc)
    if (( $(echo "$load_avg > $cpu_cores * 2" | bc -l) )); then
        alerts+=("ロードアベレージが高すぎます: $load_avg (CPUコア数: $cpu_cores)")
    fi
    
    # アラート送信
    if [ ${#alerts[@]} -gt 0 ]; then
        local alert_message=$(printf '%s\n' "${alerts[@]}")
        send_alert "システムリソース警告" "$alert_message" "HIGH"
        send_slack_notification "$alert_message" "danger"
        return 1
    fi
    
    return 0
}

# サービス状態監視
check_services() {
    local alerts=()
    local services=("apache2" "mariadb" "fail2ban")
    
    for service in "${services[@]}"; do
        if ! systemctl is-active --quiet "$service"; then
            alerts+=("サービス $service が停止しています")
            # サービスの自動再起動を試行
            systemctl start "$service" || alerts+=("サービス $service の再起動に失敗しました")
        fi
    done
    
    # アラート送信
    if [ ${#alerts[@]} -gt 0 ]; then
        local alert_message=$(printf '%s\n' "${alerts[@]}")
        send_alert "サービス状態警告" "$alert_message" "CRITICAL"
        send_slack_notification "$alert_message" "danger"
        return 1
    fi
    
    return 0
}

# Nextcloud状態監視
check_nextcloud_status() {
    local alerts=()
    
    # Nextcloudの基本状態チェック
    cd /var/www/nextcloud
    local nc_status=$(sudo -u www-data php occ status --output=json 2>/dev/null || echo '{"installed":false}')
    
    if ! echo "$nc_status" | jq -e '.installed == true' >/dev/null 2>&1; then
        alerts+=("Nextcloudが正常にインストールされていません")
    fi
    
    if echo "$nc_status" | jq -e '.maintenance == true' >/dev/null 2>&1; then
        alerts+=("Nextcloudがメンテナンスモードになっています")
    fi
    
    # データベース接続チェック
    if ! sudo -u www-data php occ db:check-connection >/dev/null 2>&1; then
        alerts+=("データベース接続に問題があります")
    fi
    
    # ファイルシステムチェック
    if ! sudo -u www-data php occ files:check-cache >/dev/null 2>&1; then
        alerts+=("ファイルキャッシュに問題があります")
    fi
    
    # セキュリティスキャン
    local security_scan=$(sudo -u www-data php occ security:check 2>/dev/null || echo "")
    if [ -n "$security_scan" ]; then
        alerts+=("セキュリティ警告: $security_scan")
    fi
    
    # アラート送信
    if [ ${#alerts[@]} -gt 0 ]; then
        local alert_message=$(printf '%s\n' "${alerts[@]}")
        send_alert "Nextcloud状態警告" "$alert_message" "HIGH"
        send_slack_notification "$alert_message" "warning"
        return 1
    fi
    
    return 0
}

# SSL証明書監視
check_ssl_certificate() {
    local alerts=()
    
    if [ -n "${DOMAIN_NAME:-}" ] && [ -f "/etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem" ]; then
        local cert_file="/etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem"
        local expiry_date=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)
        local expiry_timestamp=$(date -d "$expiry_date" +%s)
        local current_timestamp=$(date +%s)
        local days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
        
        if [ "$days_until_expiry" -lt 30 ]; then
            alerts+=("SSL証明書の有効期限が近づいています: ${days_until_expiry}日後に期限切れ")
        fi
        
        if [ "$days_until_expiry" -lt 0 ]; then
            alerts+=("SSL証明書が期限切れです")
        fi
    fi
    
    # アラート送信
    if [ ${#alerts[@]} -gt 0 ]; then
        local alert_message=$(printf '%s\n' "${alerts[@]}")
        send_alert "SSL証明書警告" "$alert_message" "HIGH"
        send_slack_notification "$alert_message" "warning"
        return 1
    fi
    
    return 0
}

# ログ監視
check_logs() {
    local alerts=()
    local error_count=0
    
    # Nextcloudログのエラーチェック（過去1時間）
    if [ -f "/var/nextcloud-data/nextcloud.log" ]; then
        local recent_errors=$(grep -c "\"level\":3\|\"level\":4" /var/nextcloud-data/nextcloud.log 2>/dev/null || echo "0")
        if [ "$recent_errors" -gt 10 ]; then
            alerts+=("Nextcloudログに多数のエラーが記録されています: ${recent_errors}件")
        fi
    fi
    
    # Apacheエラーログチェック（過去1時間）
    if [ -f "/var/log/apache2/nextcloud_error.log" ]; then
        local apache_errors=$(grep -c "$(date '+%a %b %d %H:' -d '1 hour ago')" /var/log/apache2/nextcloud_error.log 2>/dev/null || echo "0")
        if [ "$apache_errors" -gt 20 ]; then
            alerts+=("Apacheエラーログに多数のエラーが記録されています: ${apache_errors}件")
        fi
    fi
    
    # 認証失敗の監視
    local auth_failures=$(grep "authentication failure" /var/log/auth.log | grep "$(date '+%b %d %H:')" | wc -l 2>/dev/null || echo "0")
    if [ "$auth_failures" -gt 10 ]; then
        alerts+=("認証失敗が多発しています: ${auth_failures}件")
    fi
    
    # アラート送信
    if [ ${#alerts[@]} -gt 0 ]; then
        local alert_message=$(printf '%s\n' "${alerts[@]}")
        send_alert "ログ監視警告" "$alert_message" "MEDIUM"
        send_slack_notification "$alert_message" "warning"
        return 1
    fi
    
    return 0
}

# バックアップ状態監視
check_backup_status() {
    local alerts=()
    local backup_dir="/var/backups/nextcloud"
    
    if [ -d "$backup_dir" ]; then
        # 最新のバックアップファイルをチェック
        local latest_backup=$(find "$backup_dir" -name "nextcloud_db_*.sql" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
        
        if [ -n "$latest_backup" ]; then
            local backup_age=$(( ($(date +%s) - $(stat -c %Y "$latest_backup")) / 86400 ))
            if [ "$backup_age" -gt 2 ]; then
                alerts+=("バックアップが古すぎます: ${backup_age}日前")
            fi
        else
            alerts+=("バックアップファイルが見つかりません")
        fi
        
        # バックアップディスクの容量チェック
        local backup_disk_usage=$(df "$backup_dir" | tail -1 | awk '{print $5}' | sed 's/%//')
        if [ "$backup_disk_usage" -gt 90 ]; then
            alerts+=("バックアップディスクの容量が不足しています: ${backup_disk_usage}%")
        fi
    else
        alerts+=("バックアップディレクトリが存在しません")
    fi
    
    # アラート送信
    if [ ${#alerts[@]} -gt 0 ]; then
        local alert_message=$(printf '%s\n' "${alerts[@]}")
        send_alert "バックアップ状態警告" "$alert_message" "MEDIUM"
        send_slack_notification "$alert_message" "warning"
        return 1
    fi
    
    return 0
}

# セキュリティ監視
check_security() {
    local alerts=()
    
    # Fail2banの状態チェック
    if command -v fail2ban-client >/dev/null 2>&1; then
        local banned_ips=$(fail2ban-client status | grep "Number of jail:" | awk '{print $4}')
        if [ "$banned_ips" -gt 0 ]; then
            local jail_status=$(fail2ban-client status)
            alerts+=("Fail2banによりIPがブロックされています: $jail_status")
        fi
    fi
    
    # 不審なログイン試行の検出
    local suspicious_logins=$(grep "Failed password" /var/log/auth.log | grep "$(date '+%b %d')" | wc -l 2>/dev/null || echo "0")
    if [ "$suspicious_logins" -gt 50 ]; then
        alerts+=("不審なログイン試行が多発しています: ${suspicious_logins}件")
    fi
    
    # ファイル改ざん検知（AIDE使用時）
    if command -v aide >/dev/null 2>&1 && [ -f "/var/lib/aide/aide.db" ]; then
        if aide --check >/dev/null 2>&1; then
            local aide_output=$(aide --check 2>&1 | grep -E "Added|Removed|Changed" || echo "")
            if [ -n "$aide_output" ]; then
                alerts+=("ファイル改ざんが検出されました: $aide_output")
            fi
        fi
    fi
    
    # アラート送信
    if [ ${#alerts[@]} -gt 0 ]; then
        local alert_message=$(printf '%s\n' "${alerts[@]}")
        send_alert "セキュリティ警告" "$alert_message" "CRITICAL"
        send_slack_notification "$alert_message" "danger"
        return 1
    fi
    
    return 0
}

# 外部接続監視
check_external_connectivity() {
    local alerts=()
    
    # インターネット接続チェック
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        alerts+=("インターネット接続に問題があります")
    fi
    
    # DNS解決チェック
    if ! nslookup google.com >/dev/null 2>&1; then
        alerts+=("DNS解決に問題があります")
    fi
    
    # Nextcloudへの外部アクセステスト
    if [ -n "${DOMAIN_NAME:-}" ]; then
        local http_status=$(curl -s -o /dev/null -w "%{http_code}" "https://${DOMAIN_NAME}" || echo "000")
        if [ "$http_status" != "200" ]; then
            alerts+=("Nextcloudへの外部アクセスに問題があります (HTTP Status: $http_status)")
        fi
    fi
    
    # アラート送信
    if [ ${#alerts[@]} -gt 0 ]; then
        local alert_message=$(printf '%s\n' "${alerts[@]}")
        send_alert "外部接続警告" "$alert_message" "HIGH"
        send_slack_notification "$alert_message" "warning"
        return 1
    fi
    
    return 0
}

# 統合監視実行
run_full_monitoring() {
    local total_checks=8
    local failed_checks=0
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    info "Nextcloud監視を開始します ($timestamp)"
    
    # 各監視項目の実行
    echo "システムリソース監視..."
    check_system_resources || ((failed_checks++))
    
    echo "サービス状態監視..."
    check_services || ((failed_checks++))
    
    echo "Nextcloud状態監視..."
    check_nextcloud_status || ((failed_checks++))
    
    echo "SSL証明書監視..."
    check_ssl_certificate || ((failed_checks++))
    
    echo "ログ監視..."
    check_logs || ((failed_checks++))
    
    echo "バックアップ状態監視..."
    check_backup_status || ((failed_checks++))
    
    echo "セキュリティ監視..."
    check_security || ((failed_checks++))
    
    echo "外部接続監視..."
    check_external_connectivity || ((failed_checks++))
    
    # 結果の保存
    cat > "$STATUS_FILE" << EOF
{
    "timestamp": "$timestamp",
    "total_checks": $total_checks,
    "failed_checks": $failed_checks,
    "status": "$([ $failed_checks -eq 0 ] && echo "healthy" || echo "warning")"
}
EOF
    
    # 結果の表示
    if [ $failed_checks -eq 0 ]; then
        success "すべての監視項目が正常です ($total_checks/$total_checks)"
    else
        warning "$failed_checks/$total_checks の監視項目で問題が検出されました"
    fi
    
    log_message "INFO" "監視完了: $failed_checks/$total_checks の項目で問題検出"
}

# 監視レポートの生成
generate_report() {
    local report_file="/tmp/nextcloud-monitor-report.txt"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat > "$report_file" << EOF
Nextcloud監視レポート
生成日時: $timestamp

=== システム情報 ===
$(uname -a)
稼働時間: $(uptime)

=== リソース使用状況 ===
$(free -h)
$(df -h)

=== サービス状態 ===
Apache2: $(systemctl is-active apache2)
MariaDB: $(systemctl is-active mariadb)
Fail2ban: $(systemctl is-active fail2ban)

=== Nextcloud状態 ===
$(cd /var/www/nextcloud && sudo -u www-data php occ status 2>/dev/null || echo "状態取得エラー")

=== 最近のログ（エラーのみ） ===
$(tail -n 20 /var/log/nextcloud-monitor.log | grep ERROR || echo "エラーなし")

=== SSL証明書情報 ===
$([ -f "/etc/letsencrypt/live/${DOMAIN_NAME:-localhost}/fullchain.pem" ] && openssl x509 -in "/etc/letsencrypt/live/${DOMAIN_NAME:-localhost}/fullchain.pem" -noout -dates || echo "SSL証明書なし")
EOF
    
    echo "$report_file"
}

# 使用方法の表示
show_usage() {
    echo "Nextcloud監視・アラートスクリプト"
    echo
    echo "使用方法:"
    echo "  $0 <コマンド>"
    echo
    echo "コマンド:"
    echo "  monitor               完全監視の実行"
    echo "  system                システムリソース監視"
    echo "  services              サービス状態監視"
    echo "  nextcloud             Nextcloud状態監視"
    echo "  ssl                   SSL証明書監視"
    echo "  logs                  ログ監視"
    echo "  backup                バックアップ状態監視"
    echo "  security              セキュリティ監視"
    echo "  connectivity          外部接続監視"
    echo "  report                監視レポート生成"
    echo "  help                  このヘルプを表示"
    echo
    echo "Cronジョブ設定例:"
    echo "  # 5分ごとの監視"
    echo "  */5 * * * * $0 monitor"
    echo "  # 日次レポート"
    echo "  0 6 * * * $0 report | mail -s 'Nextcloud Daily Report' admin@example.com"
}

# メイン処理
main() {
    load_env
    
    # 必要なパッケージのインストール確認
    if ! command -v bc >/dev/null 2>&1; then
        apt-get update && apt-get install -y bc jq curl
    fi
    
    local command="${1:-help}"
    
    case "$command" in
        "monitor")
            run_full_monitoring
            ;;
        "system")
            check_system_resources
            ;;
        "services")
            check_services
            ;;
        "nextcloud")
            check_nextcloud_status
            ;;
        "ssl")
            check_ssl_certificate
            ;;
        "logs")
            check_logs
            ;;
        "backup")
            check_backup_status
            ;;
        "security")
            check_security
            ;;
        "connectivity")
            check_external_connectivity
            ;;
        "report")
            local report_file=$(generate_report)
            cat "$report_file"
            ;;
        "help"|*)
            show_usage
            ;;
    esac
}

main "$@"