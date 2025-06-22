#!/bin/bash

# Nextcloud完全自動インストールスクリプト
# Ubuntu 20.04/22.04対応
# 作成者: Nextcloud Auto Installer
# バージョン: 1.0.0

set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログファイル設定
LOG_FILE="/var/log/nextcloud-install.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

# 進捗表示関数
show_progress() {
    local current=$1
    local total=$2
    local message=$3
    local percent=$((current * 100 / total))
    printf "\r${BLUE}[%3d%%]${NC} %s" "$percent" "$message"
    if [ $current -eq $total ]; then
        echo
    fi
}

# ログ出力関数
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# エラーハンドリング関数
error_exit() {
    log "ERROR" "$1"
    echo -e "${RED}エラー: $1${NC}" >&2
    exit 1
}

# 成功メッセージ表示関数
success() {
    log "INFO" "$1"
    echo -e "${GREEN}✓ $1${NC}"
}

# 警告メッセージ表示関数
warning() {
    log "WARN" "$1"
    echo -e "${YELLOW}⚠ $1${NC}"
}

# 情報メッセージ表示関数
info() {
    log "INFO" "$1"
    echo -e "${BLUE}ℹ $1${NC}"
}

# 環境変数読み込み関数
load_env() {
    if [ ! -f "$ENV_FILE" ]; then
        error_exit ".envファイルが見つかりません。.env.exampleをコピーして設定してください。"
    fi
    
    # .envファイルを読み込み
    set -a
    source "$ENV_FILE"
    set +a
    
    # 必須変数のチェック
    local required_vars=(
        "DOMAIN_NAME"
        "EMAIL"
        "DB_ROOT_PASSWORD"
        "DB_NAME"
        "DB_USER"
        "DB_PASSWORD"
        "NEXTCLOUD_ADMIN_USER"
        "NEXTCLOUD_ADMIN_PASSWORD"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            error_exit "必須環境変数 $var が設定されていません。"
        fi
    done
    
    success "環境変数を読み込みました"
}

# root権限チェック
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "このスクリプトはroot権限で実行してください。"
    fi
}

# Ubuntu バージョンチェック
check_ubuntu_version() {
    if ! grep -q "Ubuntu" /etc/os-release; then
        error_exit "このスクリプトはUbuntu専用です。"
    fi
    
    local version=$(lsb_release -rs)
    if [[ ! "$version" =~ ^(20\.04|22\.04|24\.04)$ ]]; then
        warning "サポートされていないUbuntuバージョンです: $version"
        warning "Ubuntu 20.04, 22.04, 24.04での動作を推奨します。"
    fi
    
    success "Ubuntu $version を検出しました"
}

# システム更新
update_system() {
    info "システムを更新しています..."
    apt-get update -qq || error_exit "apt-get update に失敗しました"
    apt-get upgrade -y -qq || error_exit "apt-get upgrade に失敗しました"
    success "システムの更新が完了しました"
}

# 必要なパッケージのインストール
install_dependencies() {
    info "依存パッケージをインストールしています..."
    
    local packages=(
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "curl"
        "wget"
        "gnupg"
        "lsb-release"
        "unzip"
        "cron"
        "fail2ban"
        "ufw"
    )
    
    apt-get install -y "${packages[@]}" || error_exit "依存パッケージのインストールに失敗しました"
    success "依存パッケージのインストールが完了しました"
}

# Apache2のインストールと設定
install_apache() {
    info "Apache2をインストールしています..."
    
    apt-get install -y apache2 || error_exit "Apache2のインストールに失敗しました"
    
    # Apache2モジュールの有効化
    a2enmod rewrite ssl headers env dir mime || error_exit "Apacheモジュールの有効化に失敗しました"
    
    # セキュリティ設定
    cat > /etc/apache2/conf-available/security.conf << EOF
ServerTokens ${APACHE_SERVER_TOKENS:-Prod}
ServerSignature ${APACHE_SERVER_SIGNATURE:-Off}
Header always set X-Content-Type-Options nosniff
Header always set X-Frame-Options DENY
Header always set X-XSS-Protection "1; mode=block"
Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
Header always set Referrer-Policy "no-referrer"
EOF
    
    a2enconf security || error_exit "Apacheセキュリティ設定の有効化に失敗しました"
    
    systemctl enable apache2
    systemctl start apache2
    
    success "Apache2のインストールと設定が完了しました"
}

# MySQL/MariaDBのインストールと設定
install_mysql() {
    info "MySQL/MariaDBをインストールしています..."
    
    # MariaDBのインストール
    apt-get install -y mariadb-server mariadb-client || error_exit "MariaDBのインストールに失敗しました"
    
    systemctl enable mariadb
    systemctl start mariadb
    
    # MySQL secure installation の自動実行
    mysql -e "UPDATE mysql.user SET Password = PASSWORD('${DB_ROOT_PASSWORD}') WHERE User = 'root'"
    mysql -e "DELETE FROM mysql.user WHERE User=''"
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
    mysql -e "DROP DATABASE IF EXISTS test"
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
    mysql -e "FLUSH PRIVILEGES"
    
    # Nextcloud用データベースとユーザーの作成
    mysql -u root -p"${DB_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
    mysql -u root -p"${DB_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
    mysql -u root -p"${DB_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
    mysql -u root -p"${DB_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
    
    success "MySQL/MariaDBのインストールと設定が完了しました"
}

# PHPのインストールと設定
install_php() {
    info "PHP ${PHP_VERSION:-8.1} をインストールしています..."
    
    # PHP リポジトリの追加
    add-apt-repository -y ppa:ondrej/php
    apt-get update -qq
    
    # PHPとモジュールのインストール
    local php_packages=(
        "php${PHP_VERSION:-8.1}"
        "php${PHP_VERSION:-8.1}-fpm"
        "php${PHP_VERSION:-8.1}-mysql"
        "php${PHP_VERSION:-8.1}-xml"
        "php${PHP_VERSION:-8.1}-zip"
        "php${PHP_VERSION:-8.1}-curl"
        "php${PHP_VERSION:-8.1}-gd"
        "php${PHP_VERSION:-8.1}-mbstring"
        "php${PHP_VERSION:-8.1}-intl"
        "php${PHP_VERSION:-8.1}-bcmath"
        "php${PHP_VERSION:-8.1}-gmp"
        "php${PHP_VERSION:-8.1}-imagick"
        "php${PHP_VERSION:-8.1}-redis"
        "php${PHP_VERSION:-8.1}-apcu"
        "libapache2-mod-php${PHP_VERSION:-8.1}"
    )
    
    apt-get install -y "${php_packages[@]}" || error_exit "PHPのインストールに失敗しました"
    
    # PHP設定の最適化
    local php_ini="/etc/php/${PHP_VERSION:-8.1}/apache2/php.ini"
    
    sed -i "s/memory_limit = .*/memory_limit = ${PHP_MEMORY_LIMIT:-512M}/" "$php_ini"
    sed -i "s/upload_max_filesize = .*/upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE:-16G}/" "$php_ini"
    sed -i "s/post_max_size = .*/post_max_size = ${PHP_POST_MAX_SIZE:-16G}/" "$php_ini"
    sed -i "s/max_execution_time = .*/max_execution_time = 3600/" "$php_ini"
    sed -i "s/max_input_time = .*/max_input_time = 3600/" "$php_ini"
    sed -i "s/;date.timezone.*/date.timezone = ${TIMEZONE:-Asia\/Tokyo}/" "$php_ini"
    sed -i "s/;opcache.enable=.*/opcache.enable=1/" "$php_ini"
    sed -i "s/;opcache.memory_consumption=.*/opcache.memory_consumption=128/" "$php_ini"
    sed -i "s/;opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=8/" "$php_ini"
    sed -i "s/;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=10000/" "$php_ini"
    sed -i "s/;opcache.revalidate_freq=.*/opcache.revalidate_freq=1/" "$php_ini"
    sed -i "s/;opcache.save_comments=.*/opcache.save_comments=1/" "$php_ini"
    
    success "PHP ${PHP_VERSION:-8.1} のインストールと設定が完了しました"
}

# Nextcloudのダウンロードとインストール
install_nextcloud() {
    info "Nextcloudをダウンロードしています..."
    
    local nextcloud_dir="/var/www/nextcloud"
    local temp_dir="/tmp/nextcloud-install"
    
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # 最新版のNextcloudをダウンロード
    local download_url="https://download.nextcloud.com/server/releases/latest.zip"
    wget -q "$download_url" -O nextcloud.zip || error_exit "Nextcloudのダウンロードに失敗しました"
    
    # チェックサムの検証
    wget -q "https://download.nextcloud.com/server/releases/latest.zip.sha256" -O nextcloud.zip.sha256
    if ! sha256sum -c nextcloud.zip.sha256; then
        error_exit "Nextcloudのチェックサム検証に失敗しました"
    fi
    
    # 展開とインストール
    unzip -q nextcloud.zip
    
    if [ -d "$nextcloud_dir" ]; then
        rm -rf "$nextcloud_dir"
    fi
    
    mv nextcloud "$nextcloud_dir"
    
    # 権限設定
    chown -R www-data:www-data "$nextcloud_dir"
    chmod -R 755 "$nextcloud_dir"
    
    # データディレクトリの作成
    local data_dir="/var/nextcloud-data"
    mkdir -p "$data_dir"
    chown -R www-data:www-data "$data_dir"
    chmod -R 750 "$data_dir"
    
    success "Nextcloudのインストールが完了しました"
}

# Apache仮想ホストの設定
configure_apache_vhost() {
    info "Apache仮想ホストを設定しています..."
    
    # デフォルトサイトの無効化
    a2dissite 000-default
    
    # Nextcloud用仮想ホスト設定
    cat > "/etc/apache2/sites-available/nextcloud.conf" << EOF
<VirtualHost *:80>
    ServerName ${DOMAIN_NAME}
    DocumentRoot /var/www/nextcloud
    
    <Directory /var/www/nextcloud/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
        
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
        
        SetEnv HOME /var/www/nextcloud
        SetEnv HTTP_HOME /var/www/nextcloud
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog \${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
EOF
    
    # SSL用仮想ホスト設定
    cat > "/etc/apache2/sites-available/nextcloud-ssl.conf" << EOF
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName ${DOMAIN_NAME}
    DocumentRoot /var/www/nextcloud
    
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem
    
    # SSL設定の強化
    SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder on
    SSLCompression off
    
    <Directory /var/www/nextcloud/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
        
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
        
        SetEnv HOME /var/www/nextcloud
        SetEnv HTTP_HOME /var/www/nextcloud
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/nextcloud_ssl_error.log
    CustomLog \${APACHE_LOG_DIR}/nextcloud_ssl_access.log combined
</VirtualHost>
</IfModule>
EOF
    
    # サイトの有効化
    a2ensite nextcloud
    
    success "Apache仮想ホストの設定が完了しました"
}

# Let's Encrypt SSL証明書の設定
setup_letsencrypt() {
    if [ "${USE_LETSENCRYPT:-true}" != "true" ]; then
        warning "Let's Encrypt SSL証明書の設定をスキップします"
        return
    fi
    
    info "Let's Encrypt SSL証明書を設定しています..."
    
    # Certbotのインストール
    apt-get install -y certbot python3-certbot-apache || error_exit "Certbotのインストールに失敗しました"
    
    # Apache再起動
    systemctl reload apache2
    
    # SSL証明書の取得
    certbot --apache -d "${DOMAIN_NAME}" --email "${LETSENCRYPT_EMAIL:-$EMAIL}" --agree-tos --non-interactive --redirect || error_exit "SSL証明書の取得に失敗しました"
    
    # SSL仮想ホストの有効化
    a2ensite nextcloud-ssl
    
    # 自動更新の設定
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    success "Let's Encrypt SSL証明書の設定が完了しました"
}

# Nextcloudの初期設定
configure_nextcloud() {
    info "Nextcloudの初期設定を実行しています..."
    
    cd /var/www/nextcloud
    
    # occ コマンドでの初期設定
    sudo -u www-data php occ maintenance:install \
        --database="mysql" \
        --database-name="${DB_NAME}" \
        --database-user="${DB_USER}" \
        --database-pass="${DB_PASSWORD}" \
        --admin-user="${NEXTCLOUD_ADMIN_USER}" \
        --admin-pass="${NEXTCLOUD_ADMIN_PASSWORD}" \
        --data-dir="/var/nextcloud-data" || error_exit "Nextcloudの初期設定に失敗しました"
    
    # 信頼できるドメインの設定
    local trusted_domains="${TRUSTED_DOMAINS:-localhost 127.0.0.1} ${DOMAIN_NAME}"
    local domain_index=0
    for domain in $trusted_domains; do
        sudo -u www-data php occ config:system:set trusted_domains $domain_index --value="$domain"
        ((domain_index++))
    done
    
    # その他の設定
    sudo -u www-data php occ config:system:set overwrite.cli.url --value="https://${DOMAIN_NAME}"
    sudo -u www-data php occ config:system:set htaccess.RewriteBase --value="/"
    sudo -u www-data php occ maintenance:update:htaccess
    
    # メモリキャッシュの設定
    sudo -u www-data php occ config:system:set memcache.local --value="\\OC\\Memcache\\APCu"
    
    # ログレベルの設定
    sudo -u www-data php occ config:system:set loglevel --value=2
    
    success "Nextcloudの初期設定が完了しました"
}

# ファイアウォール設定
configure_firewall() {
    if [ "${UFW_ENABLED:-true}" != "true" ]; then
        warning "ファイアウォール設定をスキップします"
        return
    fi
    
    info "ファイアウォールを設定しています..."
    
    # UFWの設定
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # 必要なポートの開放
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # UFWの有効化
    ufw --force enable
    
    success "ファイアウォールの設定が完了しました"
}

# Fail2banの設定
configure_fail2ban() {
    if [ "${FAIL2BAN_ENABLED:-true}" != "true" ]; then
        warning "Fail2ban設定をスキップします"
        return
    fi
    
    info "Fail2banを設定しています..."
    
    # Nextcloud用Fail2ban設定
    cat > /etc/fail2ban/filter.d/nextcloud.conf << 'EOF'
[Definition]
_groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
failregex = ^\{.*"remoteAddr":"<HOST>".*"message":"Login failed:
            ^\{.*"remoteAddr":"<HOST>".*"message":"Trusted domain error.
ignoreregex =
EOF
    
    cat > /etc/fail2ban/jail.d/nextcloud.local << EOF
[nextcloud]
enabled = true
port = 80,443
protocol = tcp
filter = nextcloud
maxretry = 3
bantime = 3600
findtime = 600
logpath = /var/nextcloud-data/nextcloud.log
EOF
    
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    success "Fail2banの設定が完了しました"
}

# バックアップスクリプトの作成
create_backup_script() {
    if [ "${BACKUP_ENABLED:-true}" != "true" ]; then
        warning "バックアップスクリプトの作成をスキップします"
        return
    fi
    
    info "バックアップスクリプトを作成しています..."
    
    local backup_script="/usr/local/bin/nextcloud-backup.sh"
    
    cat > "$backup_script" << EOF
#!/bin/bash

# Nextcloud自動バックアップスクリプト
set -euo pipefail

BACKUP_DIR="/var/backups/nextcloud"
DATE=\$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}

# バックアップディレクトリの作成
mkdir -p "\$BACKUP_DIR"

# メンテナンスモードの有効化
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on

# データベースバックアップ
mysqldump -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME} > "\$BACKUP_DIR/nextcloud_db_\$DATE.sql"

# ファイルバックアップ
tar -czf "\$BACKUP_DIR/nextcloud_files_\$DATE.tar.gz" -C /var/www nextcloud
tar -czf "\$BACKUP_DIR/nextcloud_data_\$DATE.tar.gz" -C /var nextcloud-data

# メンテナンスモードの無効化
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off

# 古いバックアップの削除
find "\$BACKUP_DIR" -name "nextcloud_*" -type f -mtime +\$RETENTION_DAYS -delete

echo "バックアップが完了しました: \$DATE"
EOF
    
    chmod +x "$backup_script"
    
    # Cronジョブの設定
    (crontab -l 2>/dev/null; echo "0 ${BACKUP_TIME:-02:00} * * * $backup_script") | crontab -
    
    success "バックアップスクリプトの作成が完了しました"
}

# システムサービスの再起動
restart_services() {
    info "システムサービスを再起動しています..."
    
    systemctl restart apache2
    systemctl restart mariadb
    
    # サービスの状態確認
    if ! systemctl is-active --quiet apache2; then
        error_exit "Apache2の起動に失敗しました"
    fi
    
    if ! systemctl is-active --quiet mariadb; then
        error_exit "MariaDBの起動に失敗しました"
    fi
    
    success "システムサービスの再起動が完了しました"
}

# インストール完了メッセージ
show_completion_message() {
    echo
    echo "=========================================="
    echo -e "${GREEN}Nextcloudのインストールが完了しました！${NC}"
    echo "=========================================="
    echo
    echo -e "${BLUE}アクセス情報:${NC}"
    echo "URL: https://${DOMAIN_NAME}"
    echo "管理者ユーザー: ${NEXTCLOUD_ADMIN_USER}"
    echo "管理者パスワード: ${NEXTCLOUD_ADMIN_PASSWORD}"
    echo
    echo -e "${BLUE}データベース情報:${NC}"
    echo "データベース名: ${DB_NAME}"
    echo "データベースユーザー: ${DB_USER}"
    echo
    echo -e "${BLUE}重要なファイル:${NC}"
    echo "Nextcloudディレクトリ: /var/www/nextcloud"
    echo "データディレクトリ: /var/nextcloud-data"
    echo "設定ファイル: /var/www/nextcloud/config/config.php"
    echo "ログファイル: $LOG_FILE"
    echo
    if [ "${BACKUP_ENABLED:-true}" = "true" ]; then
        echo -e "${BLUE}バックアップ:${NC}"
        echo "バックアップディレクトリ: /var/backups/nextcloud"
        echo "バックアップ時刻: ${BACKUP_TIME:-02:00}"
        echo "保持期間: ${BACKUP_RETENTION_DAYS:-30}日"
        echo
    fi
    echo -e "${YELLOW}セキュリティのため、.envファイルを安全な場所に保管してください。${NC}"
    echo "=========================================="
}

# メイン実行関数
main() {
    local total_steps=15
    local current_step=0
    
    echo -e "${BLUE}Nextcloud完全自動インストールスクリプト${NC}"
    echo "=========================================="
    
    # ログファイルの初期化
    echo "Nextcloud自動インストール開始: $(date)" > "$LOG_FILE"
    
    show_progress $((++current_step)) $total_steps "環境変数を読み込んでいます..."
    load_env
    
    show_progress $((++current_step)) $total_steps "root権限をチェックしています..."
    check_root
    
    show_progress $((++current_step)) $total_steps "Ubuntuバージョンをチェックしています..."
    check_ubuntu_version
    
    show_progress $((++current_step)) $total_steps "システムを更新しています..."
    update_system
    
    show_progress $((++current_step)) $total_steps "依存パッケージをインストールしています..."
    install_dependencies
    
    show_progress $((++current_step)) $total_steps "Apache2をインストールしています..."
    install_apache
    
    show_progress $((++current_step)) $total_steps "MySQL/MariaDBをインストールしています..."
    install_mysql
    
    show_progress $((++current_step)) $total_steps "PHPをインストールしています..."
    install_php
    
    show_progress $((++current_step)) $total_steps "Nextcloudをインストールしています..."
    install_nextcloud
    
    show_progress $((++current_step)) $total_steps "Apache仮想ホストを設定しています..."
    configure_apache_vhost
    
    show_progress $((++current_step)) $total_steps "SSL証明書を設定しています..."
    setup_letsencrypt
    
    show_progress $((++current_step)) $total_steps "Nextcloudを設定しています..."
    configure_nextcloud
    
    show_progress $((++current_step)) $total_steps "ファイアウォールを設定しています..."
    configure_firewall
    
    show_progress $((++current_step)) $total_steps "Fail2banを設定しています..."
    configure_fail2ban
    
    show_progress $((++current_step)) $total_steps "バックアップスクリプトを作成しています..."
    create_backup_script
    
    show_progress $((++current_step)) $total_steps "サービスを再起動しています..."
    restart_services
    
    show_completion_message
    
    log "INFO" "Nextcloudのインストールが正常に完了しました"
}

# スクリプト実行
main "$@"