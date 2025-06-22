#!/bin/bash

# Nextcloudセキュリティ強化スクリプト
# システムのセキュリティを追加で強化するためのスクリプト

set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# SSH設定の強化
harden_ssh() {
    info "SSH設定を強化しています..."
    
    local ssh_config="/etc/ssh/sshd_config"
    local backup_config="${ssh_config}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # 設定ファイルのバックアップ
    cp "$ssh_config" "$backup_config"
    
    # SSH設定の強化
    cat >> "$ssh_config" << 'EOF'

# セキュリティ強化設定
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 2
LoginGraceTime 60
AllowUsers ubuntu
EOF
    
    # SSH設定の検証
    sshd -t || error_exit "SSH設定に問題があります"
    
    systemctl restart ssh
    
    success "SSH設定の強化が完了しました"
}

# ファイアウォール設定の詳細化
enhance_firewall() {
    info "ファイアウォール設定を詳細化しています..."
    
    # 基本的なルール
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # SSH (ポート22) - レート制限付き
    ufw limit ssh
    
    # HTTP/HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # 特定のIPからの管理アクセス（必要に応じて設定）
    # ufw allow from 192.168.1.0/24 to any port 22
    
    # DDoS攻撃対策
    ufw --force enable
    
    # iptablesルールの追加設定
    cat > /etc/ufw/before.rules << 'EOF'
# DDoS攻撃対策
-A ufw-before-input -p tcp --dport 80 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT
-A ufw-before-input -p tcp --dport 443 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT

# SYN flood攻撃対策
-A ufw-before-input -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
-A ufw-before-input -p tcp --syn -j DROP

# Ping flood攻撃対策
-A ufw-before-input -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
-A ufw-before-input -p icmp --icmp-type echo-request -j DROP
EOF
    
    ufw reload
    
    success "ファイアウォール設定の詳細化が完了しました"
}

# Fail2banの詳細設定
enhance_fail2ban() {
    info "Fail2ban設定を詳細化しています..."
    
    # SSH用設定
    cat > /etc/fail2ban/jail.d/ssh.local << 'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOF
    
    # Apache用設定
    cat > /etc/fail2ban/jail.d/apache.local << 'EOF'
[apache-auth]
enabled = true
port = http,https
filter = apache-auth
logpath = /var/log/apache2/*error.log
maxretry = 3
bantime = 3600
findtime = 600

[apache-badbots]
enabled = true
port = http,https
filter = apache-badbots
logpath = /var/log/apache2/*access.log
maxretry = 2
bantime = 86400
findtime = 600

[apache-noscript]
enabled = true
port = http,https
filter = apache-noscript
logpath = /var/log/apache2/*access.log
maxretry = 6
bantime = 86400
findtime = 600

[apache-overflows]
enabled = true
port = http,https
filter = apache-overflows
logpath = /var/log/apache2/*error.log
maxretry = 2
bantime = 86400
findtime = 600
EOF
    
    # Nextcloud用設定の強化
    cat > /etc/fail2ban/jail.d/nextcloud.local << 'EOF'
[nextcloud]
enabled = true
port = 80,443
protocol = tcp
filter = nextcloud
maxretry = 3
bantime = 3600
findtime = 600
logpath = /var/nextcloud-data/nextcloud.log

[nextcloud-auth]
enabled = true
port = 80,443
protocol = tcp
filter = nextcloud-auth
maxretry = 5
bantime = 1800
findtime = 600
logpath = /var/log/apache2/nextcloud_access.log
EOF
    
    # Nextcloud認証フィルターの作成
    cat > /etc/fail2ban/filter.d/nextcloud-auth.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "POST \/login HTTP.*" 200
ignoreregex =
EOF
    
    systemctl restart fail2ban
    
    success "Fail2ban設定の詳細化が完了しました"
}

# システムの堅牢化
harden_system() {
    info "システムを堅牢化しています..."
    
    # カーネルパラメータの設定
    cat > /etc/sysctl.d/99-security.conf << 'EOF'
# IP Spoofing protection
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Ignore ICMP ping requests
net.ipv4.icmp_echo_ignore_all = 0

# Ignore Directed pings
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable IPv6 if not needed
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

# TCP SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Control buffer overflow attacks
kernel.exec-shield = 1
kernel.randomize_va_space = 2
EOF
    
    # 設定の適用
    sysctl -p /etc/sysctl.d/99-security.conf
    
    # 不要なサービスの無効化
    local services_to_disable=(
        "avahi-daemon"
        "cups"
        "bluetooth"
        "whoopsie"
    )
    
    for service in "${services_to_disable[@]}"; do
        if systemctl is-enabled "$service" 2>/dev/null; then
            systemctl disable "$service"
            systemctl stop "$service" 2>/dev/null || true
            info "サービス $service を無効化しました"
        fi
    done
    
    success "システムの堅牢化が完了しました"
}

# Apache設定の強化
harden_apache() {
    info "Apache設定を強化しています..."
    
    # セキュリティモジュールの有効化
    a2enmod evasive security2 headers rewrite ssl
    
    # mod_evasive設定
    cat > /etc/apache2/mods-available/evasive.conf << 'EOF'
<IfModule mod_evasive24.c>
    DOSHashTableSize    2048
    DOSPageCount        3
    DOSPageInterval     1
    DOSSiteCount        50
    DOSSiteInterval     1
    DOSBlockingPeriod   600
    DOSLogDir           /var/log/apache2
    DOSEmailNotify      admin@localhost
    DOSWhitelist        127.0.0.1
    DOSWhitelist        ::1
</IfModule>
EOF
    
    # セキュリティヘッダーの強化
    cat > /etc/apache2/conf-available/security-headers.conf << 'EOF'
# セキュリティヘッダーの設定
Header always set X-Content-Type-Options nosniff
Header always set X-Frame-Options DENY
Header always set X-XSS-Protection "1; mode=block"
Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self'; media-src 'self'; object-src 'none'; child-src 'self'; frame-ancestors 'none'; form-action 'self'; base-uri 'self';"
Header always set Feature-Policy "geolocation 'none'; midi 'none'; notifications 'none'; push 'none'; sync-xhr 'none'; microphone 'none'; camera 'none'; magnetometer 'none'; gyroscope 'none'; speaker 'none'; vibrate 'none'; fullscreen 'self'; payment 'none';"

# サーバー情報の隠蔽
ServerTokens Prod
ServerSignature Off
Header unset Server
Header always unset X-Powered-By
EOF
    
    a2enconf security-headers
    
    # Apache設定の追加強化
    cat >> /etc/apache2/apache2.conf << 'EOF'

# セキュリティ設定の追加
TraceEnable Off
FileETag None
Timeout 60
KeepAliveTimeout 15
MaxKeepAliveRequests 100
LimitRequestBody 104857600
LimitRequestFields 100
LimitRequestFieldSize 8190
LimitRequestLine 4094
EOF
    
    systemctl restart apache2
    
    success "Apache設定の強化が完了しました"
}

# PHP設定の強化
harden_php() {
    info "PHP設定を強化しています..."
    
    local php_version="${PHP_VERSION:-8.1}"
    local php_ini="/etc/php/${php_version}/apache2/php.ini"
    
    # PHP設定のバックアップ
    cp "$php_ini" "${php_ini}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # セキュリティ設定の適用
    sed -i 's/expose_php = On/expose_php = Off/' "$php_ini"
    sed -i 's/display_errors = On/display_errors = Off/' "$php_ini"
    sed -i 's/display_startup_errors = On/display_startup_errors = Off/' "$php_ini"
    sed -i 's/log_errors = Off/log_errors = On/' "$php_ini"
    sed -i 's/allow_url_fopen = On/allow_url_fopen = Off/' "$php_ini"
    sed -i 's/allow_url_include = On/allow_url_include = Off/' "$php_ini"
    sed -i 's/;session.cookie_httponly =/session.cookie_httponly = 1/' "$php_ini"
    sed -i 's/;session.cookie_secure =/session.cookie_secure = 1/' "$php_ini"
    sed -i 's/;session.use_strict_mode = 0/session.use_strict_mode = 1/' "$php_ini"
    
    # 危険な関数の無効化
    sed -i 's/disable_functions =/disable_functions = exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source/' "$php_ini"
    
    systemctl restart apache2
    
    success "PHP設定の強化が完了しました"
}

# MySQL/MariaDB設定の強化
harden_mysql() {
    info "MySQL/MariaDB設定を強化しています..."
    
    # MySQL設定ファイルの強化
    cat > /etc/mysql/mysql.conf.d/security.cnf << 'EOF'
[mysqld]
# セキュリティ設定
local-infile = 0
skip-show-database
safe-user-create = 1
secure-auth = 1
skip-symbolic-links = 1
skip-networking = 0
bind-address = 127.0.0.1

# ログ設定
log-error = /var/log/mysql/error.log
slow-query-log = 1
slow-query-log-file = /var/log/mysql/slow.log
long_query_time = 2

# パフォーマンス設定
max_connections = 100
connect_timeout = 10
wait_timeout = 600
max_allowed_packet = 64M
thread_cache_size = 128
sort_buffer_size = 4M
bulk_insert_buffer_size = 16M
tmp_table_size = 32M
max_heap_table_size = 32M
EOF
    
    systemctl restart mariadb
    
    success "MySQL/MariaDB設定の強化が完了しました"
}

# ログ監視の設定
setup_log_monitoring() {
    info "ログ監視を設定しています..."
    
    # logrotateの設定
    cat > /etc/logrotate.d/nextcloud << 'EOF'
/var/nextcloud-data/nextcloud.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 640 www-data www-data
    postrotate
        sudo -u www-data php /var/www/nextcloud/occ log:manage --rotate
    endscript
}
EOF
    
    # rsyslogの設定
    cat > /etc/rsyslog.d/49-nextcloud.conf << 'EOF'
# Nextcloud関連ログの設定
:programname, isequal, "nextcloud" /var/log/nextcloud-system.log
& stop
EOF
    
    systemctl restart rsyslog
    
    success "ログ監視の設定が完了しました"
}

# 侵入検知システムの設定
setup_intrusion_detection() {
    info "侵入検知システムを設定しています..."
    
    # AIDE (Advanced Intrusion Detection Environment) のインストール
    apt-get install -y aide aide-common
    
    # AIDE設定
    cat > /etc/aide/aide.conf << 'EOF'
# AIDE設定ファイル
database=file:/var/lib/aide/aide.db
database_out=file:/var/lib/aide/aide.db.new
gzip_dbout=yes
verbose=5
report_url=file:/var/log/aide/aide.log
report_url=stdout

# 監視ルール
/boot f+p+u+g+s+b+m+c+md5+sha1
/bin f+p+u+g+s+b+m+c+md5+sha1
/sbin f+p+u+g+s+b+m+c+md5+sha1
/usr/bin f+p+u+g+s+b+m+c+md5+sha1
/usr/sbin f+p+u+g+s+b+m+c+md5+sha1
/lib f+p+u+g+s+b+m+c+md5+sha1
/usr/lib f+p+u+g+s+b+m+c+md5+sha1
/etc f+p+u+g+s+b+m+c+md5+sha1
/var/www/nextcloud f+p+u+g+s+b+m+c+md5+sha1

# 除外ディレクトリ
!/var/log
!/var/cache
!/tmp
!/var/tmp
!/var/nextcloud-data
EOF
    
    # AIDE データベースの初期化
    aideinit
    
    # 定期チェックのcron設定
    (crontab -l 2>/dev/null; echo "0 3 * * * /usr/bin/aide --check") | crontab -
    
    success "侵入検知システムの設定が完了しました"
}

# 使用方法の表示
show_usage() {
    echo "Nextcloudセキュリティ強化スクリプト"
    echo
    echo "使用方法:"
    echo "  $0 [オプション]"
    echo
    echo "オプション:"
    echo "  --all                 すべてのセキュリティ強化を実行"
    echo "  --ssh                 SSH設定の強化"
    echo "  --firewall            ファイアウォール設定の詳細化"
    echo "  --fail2ban            Fail2ban設定の詳細化"
    echo "  --system              システムの堅牢化"
    echo "  --apache              Apache設定の強化"
    echo "  --php                 PHP設定の強化"
    echo "  --mysql               MySQL/MariaDB設定の強化"
    echo "  --logging             ログ監視の設定"
    echo "  --intrusion           侵入検知システムの設定"
    echo "  --help                このヘルプを表示"
}

# メイン処理
main() {
    check_root
    load_env
    
    local option="${1:---help}"
    
    case "$option" in
        "--all")
            harden_ssh
            enhance_firewall
            enhance_fail2ban
            harden_system
            harden_apache
            harden_php
            harden_mysql
            setup_log_monitoring
            setup_intrusion_detection
            success "すべてのセキュリティ強化が完了しました"
            ;;
        "--ssh")
            harden_ssh
            ;;
        "--firewall")
            enhance_firewall
            ;;
        "--fail2ban")
            enhance_fail2ban
            ;;
        "--system")
            harden_system
            ;;
        "--apache")
            harden_apache
            ;;
        "--php")
            harden_php
            ;;
        "--mysql")
            harden_mysql
            ;;
        "--logging")
            setup_log_monitoring
            ;;
        "--intrusion")
            setup_intrusion_detection
            ;;
        "--help"|*)
            show_usage
            ;;
    esac
}

main "$@"