#!/bin/bash

# スクリプトを root として実行する必要があることを確認
if [[ $EUID -ne 0 ]]; then
   echo "このスクリプトは root 権限で実行する必要があります。sudo を使用してください。" 
   exit 1
fi

# 変数設定
NEXTCLOUD_VERSION="29.0.7"  # 最新の安定版バージョン（PHP 8.3対応）
DOMAIN="nextcloud.example.com"  # 実際のドメイン名に置き換えてください
LETSENCRYPT_EMAIL="your-email@example.com"   # Let's Encrypt登録用メールアドレスに置き換えてください
PHP_VERSION="8.2"  # Nextcloudと互換性のあるPHPバージョン
DB_NAME="nextcloud"
DB_USER="nextcloud"
DB_PASSWORD="pnextcloud4423"

# システムの更新
echo "システムを更新しています..."
apt update && apt upgrade -y

# PHP PPAリポジトリの追加（特定のPHPバージョンを指定するため）
echo "PHP PPAリポジトリを追加しています..."
apt install -y software-properties-common
add-apt-repository -y ppa:ondrej/php
apt update

# 必要な依存関係のインストール
echo "必要な依存関係をインストールしています..."
apt install -y \
    apache2 \
    libapache2-mod-php${PHP_VERSION} \
    php${PHP_VERSION} \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-bz2 \
    php${PHP_VERSION}-ldap \
    php${PHP_VERSION}-smbclient \
    php${PHP_VERSION}-imap \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-imagick \
    php${PHP_VERSION}-gmp \
    mariadb-server \
    mariadb-client \
    unzip \
    wget \
    certbot \
    python3-certbot-apache

# デフォルトのPHPバージョンを設定
update-alternatives --set php /usr/bin/php${PHP_VERSION}

# MariaDBの初期設定
echo "MariaDBを設定しています..."
systemctl start mariadb
systemctl enable mariadb

# MariaDBのセキュリティ設定とNextcloud用データベースの作成
mysql -e "UPDATE mysql.user SET Password=PASSWORD('root_password') WHERE User='root';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

echo "データベース設定が完了しました。"
echo "データベース名: ${DB_NAME}"
echo "ユーザー名: ${DB_USER}"

# Nextcloudのダウンロードとインストール
echo "Nextcloudをダウンロードしています..."
cd /var/www/html
wget https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.zip
unzip nextcloud-${NEXTCLOUD_VERSION}.zip
rm nextcloud-${NEXTCLOUD_VERSION}.zip

# ディレクトリの権限設定
chown -R www-data:www-data /var/www/html/nextcloud

# Apacheの設定
echo "Apacheを設定しています..."
a2enmod rewrite headers env dir mime

# Nextcloud用のApache仮想ホスト設定
cat > /etc/apache2/sites-available/nextcloud.conf << EOL
<VirtualHost *:80>
    ServerName ${DOMAIN}
    ServerAlias *
    DocumentRoot /var/www/html/nextcloud

    # 外部接続のための設定
    Header set Access-Control-Allow-Origin "*"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

    <Directory /var/www/html/nextcloud>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews

        # クロスオリジン設定
        Header set Access-Control-Allow-Origin "*"
        Header set Access-Control-Allow-Methods "GET, POST, OPTIONS"
        Header set Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept"

        <IfModule mod_dav.c>
            Dav off
        </IfModule>
    </Directory>

    # ログ設定
    ErrorLog \${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog \${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
EOL

a2ensite nextcloud
systemctl restart apache2

# Let's Encryptを使用したSSL証明書の取得
echo "SSL証明書を取得しています..."
certbot --apache -d ${DOMAIN} --non-interactive --agree-tos -m ${LETSENCRYPT_EMAIL}

# ファイアウォールの設定
echo "ファイアウォールを設定しています..."
ufw allow 'Apache Full'
ufw enable

# 最終メッセージ
echo "========================================"
echo "Nextcloudのインストールが完了しました。"
echo "========================================"
echo ""
echo "アクセスURL: https://${DOMAIN}"
echo ""
echo "初期設定時に以下のデータベース情報を使用してください："
echo "  データベースタイプ: MariaDB"
echo "  データベース名: ${DB_NAME}"
echo "  データベースユーザー: ${DB_USER}"
echo "  データベースパスワード: ${DB_PASSWORD}"
echo "  データベースホスト: localhost"
echo ""
echo "管理者アカウントは初回アクセス時に作成してください。"