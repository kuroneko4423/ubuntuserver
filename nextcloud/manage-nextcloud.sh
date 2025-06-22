#!/bin/bash

# Nextcloud管理スクリプト
# 日常的な管理タスクを簡単に実行するためのユーティリティ

set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NEXTCLOUD_DIR="/var/www/nextcloud"
DATA_DIR="/var/nextcloud-data"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

# 関数定義
error_exit() {
    echo -e "${RED}エラー: $1${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# root権限チェック
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "このスクリプトはroot権限で実行してください。"
    fi
}

# 環境変数読み込み
load_env() {
    if [ -f "$ENV_FILE" ]; then
        set -a
        source "$ENV_FILE"
        set +a
    fi
}

# occ コマンドの実行
run_occ() {
    cd "$NEXTCLOUD_DIR"
    sudo -u www-data php occ "$@"
}

# システム状態の確認
check_status() {
    info "Nextcloudシステム状態を確認しています..."
    echo
    
    # サービス状態
    echo -e "${BLUE}=== サービス状態 ===${NC}"
    systemctl is-active apache2 && echo -e "Apache2: ${GREEN}稼働中${NC}" || echo -e "Apache2: ${RED}停止中${NC}"
    systemctl is-active mariadb && echo -e "MariaDB: ${GREEN}稼働中${NC}" || echo -e "MariaDB: ${RED}停止中${NC}"
    systemctl is-active fail2ban && echo -e "Fail2ban: ${GREEN}稼働中${NC}" || echo -e "Fail2ban: ${RED}停止中${NC}"
    echo
    
    # ディスク使用量
    echo -e "${BLUE}=== ディスク使用量 ===${NC}"
    df -h "$NEXTCLOUD_DIR" "$DATA_DIR" 2>/dev/null || true
    echo
    
    # Nextcloud状態
    echo -e "${BLUE}=== Nextcloud状態 ===${NC}"
    run_occ status
    echo
    
    # SSL証明書の有効期限
    if [ -f "/etc/letsencrypt/live/${DOMAIN_NAME:-localhost}/fullchain.pem" ]; then
        echo -e "${BLUE}=== SSL証明書情報 ===${NC}"
        openssl x509 -in "/etc/letsencrypt/live/${DOMAIN_NAME:-localhost}/fullchain.pem" -noout -dates
        echo
    fi
}

# メンテナンスモードの切り替え
toggle_maintenance() {
    local mode="$1"
    
    if [ "$mode" = "on" ]; then
        info "メンテナンスモードを有効にしています..."
        run_occ maintenance:mode --on
        success "メンテナンスモードが有効になりました"
    elif [ "$mode" = "off" ]; then
        info "メンテナンスモードを無効にしています..."
        run_occ maintenance:mode --off
        success "メンテナンスモードが無効になりました"
    else
        error_exit "無効なモード: $mode (on または off を指定してください)"
    fi
}

# アップデート実行
update_nextcloud() {
    info "Nextcloudのアップデートを実行しています..."
    
    # メンテナンスモード有効化
    run_occ maintenance:mode --on
    
    # アップデート実行
    run_occ upgrade
    
    # メンテナンスモード無効化
    run_occ maintenance:mode --off
    
    success "Nextcloudのアップデートが完了しました"
}

# データベース最適化
optimize_database() {
    info "データベースを最適化しています..."
    
    # インデックスの追加
    run_occ db:add-missing-indices
    
    # カラムの変換
    run_occ db:convert-filecache-bigint
    
    # データベースの最適化
    mysql -u "${DB_USER:-nextcloud_user}" -p"${DB_PASSWORD}" -e "OPTIMIZE TABLE ${DB_NAME:-nextcloud}.*;" 2>/dev/null || true
    
    success "データベースの最適化が完了しました"
}

# ファイルスキャン
scan_files() {
    local user="${1:-}"
    
    if [ -n "$user" ]; then
        info "ユーザー $user のファイルをスキャンしています..."
        run_occ files:scan "$user"
    else
        info "全ユーザーのファイルをスキャンしています..."
        run_occ files:scan --all
    fi
    
    success "ファイルスキャンが完了しました"
}

# ログの確認
show_logs() {
    local lines="${1:-50}"
    
    echo -e "${BLUE}=== Nextcloudログ (最新 $lines 行) ===${NC}"
    if [ -f "$DATA_DIR/nextcloud.log" ]; then
        tail -n "$lines" "$DATA_DIR/nextcloud.log"
    else
        warning "Nextcloudログファイルが見つかりません"
    fi
    echo
    
    echo -e "${BLUE}=== Apacheエラーログ (最新 $lines 行) ===${NC}"
    if [ -f "/var/log/apache2/nextcloud_error.log" ]; then
        tail -n "$lines" "/var/log/apache2/nextcloud_error.log"
    else
        warning "Apacheエラーログが見つかりません"
    fi
}

# バックアップ実行
run_backup() {
    local backup_script="/usr/local/bin/nextcloud-backup.sh"
    
    if [ -f "$backup_script" ]; then
        info "バックアップを実行しています..."
        "$backup_script"
        success "バックアップが完了しました"
    else
        error_exit "バックアップスクリプトが見つかりません: $backup_script"
    fi
}

# ユーザー管理
manage_user() {
    local action="$1"
    local username="${2:-}"
    local password="${3:-}"
    
    case "$action" in
        "list")
            info "ユーザー一覧を表示しています..."
            run_occ user:list
            ;;
        "add")
            if [ -z "$username" ] || [ -z "$password" ]; then
                error_exit "ユーザー名とパスワードを指定してください"
            fi
            info "ユーザー $username を追加しています..."
            run_occ user:add --password-from-env "$username"
            export OC_PASS="$password"
            success "ユーザー $username が追加されました"
            ;;
        "delete")
            if [ -z "$username" ]; then
                error_exit "ユーザー名を指定してください"
            fi
            info "ユーザー $username を削除しています..."
            run_occ user:delete "$username"
            success "ユーザー $username が削除されました"
            ;;
        "reset-password")
            if [ -z "$username" ] || [ -z "$password" ]; then
                error_exit "ユーザー名とパスワードを指定してください"
            fi
            info "ユーザー $username のパスワードをリセットしています..."
            export OC_PASS="$password"
            run_occ user:resetpassword --password-from-env "$username"
            success "ユーザー $username のパスワードがリセットされました"
            ;;
        *)
            error_exit "無効なアクション: $action (list, add, delete, reset-password のいずれかを指定してください)"
            ;;
    esac
}

# アプリ管理
manage_app() {
    local action="$1"
    local app_name="${2:-}"
    
    case "$action" in
        "list")
            info "インストール済みアプリ一覧を表示しています..."
            run_occ app:list
            ;;
        "enable")
            if [ -z "$app_name" ]; then
                error_exit "アプリ名を指定してください"
            fi
            info "アプリ $app_name を有効化しています..."
            run_occ app:enable "$app_name"
            success "アプリ $app_name が有効化されました"
            ;;
        "disable")
            if [ -z "$app_name" ]; then
                error_exit "アプリ名を指定してください"
            fi
            info "アプリ $app_name を無効化しています..."
            run_occ app:disable "$app_name"
            success "アプリ $app_name が無効化されました"
            ;;
        *)
            error_exit "無効なアクション: $action (list, enable, disable のいずれかを指定してください)"
            ;;
    esac
}

# 使用方法の表示
show_usage() {
    echo "Nextcloud管理スクリプト"
    echo
    echo "使用方法:"
    echo "  $0 <コマンド> [オプション]"
    echo
    echo "コマンド:"
    echo "  status                    - システム状態の確認"
    echo "  maintenance <on|off>      - メンテナンスモードの切り替え"
    echo "  update                    - Nextcloudのアップデート"
    echo "  optimize-db               - データベースの最適化"
    echo "  scan-files [ユーザー名]   - ファイルスキャン"
    echo "  logs [行数]               - ログの表示"
    echo "  backup                    - バックアップの実行"
    echo "  user <list|add|delete|reset-password> [ユーザー名] [パスワード]"
    echo "  app <list|enable|disable> [アプリ名]"
    echo "  help                      - このヘルプを表示"
    echo
    echo "例:"
    echo "  $0 status"
    echo "  $0 maintenance on"
    echo "  $0 scan-files admin"
    echo "  $0 user add newuser password123"
    echo "  $0 app enable calendar"
}

# メイン処理
main() {
    check_root
    load_env
    
    local command="${1:-help}"
    
    case "$command" in
        "status")
            check_status
            ;;
        "maintenance")
            toggle_maintenance "${2:-}"
            ;;
        "update")
            update_nextcloud
            ;;
        "optimize-db")
            optimize_database
            ;;
        "scan-files")
            scan_files "${2:-}"
            ;;
        "logs")
            show_logs "${2:-50}"
            ;;
        "backup")
            run_backup
            ;;
        "user")
            manage_user "${2:-}" "${3:-}" "${4:-}"
            ;;
        "app")
            manage_app "${2:-}" "${3:-}"
            ;;
        "help"|*)
            show_usage
            ;;
    esac
}

main "$@"