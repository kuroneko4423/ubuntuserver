#!/bin/bash

# スクリプトを root として実行する必要があることを確認
if [[ $EUID -ne 0 ]]; then
   echo "このスクリプトは root 権限で実行する必要があります。sudo を使用してください。" 
   exit 1
fi

# 変数設定
NEXTCLOUD_VERSION="27.1.3"  # 最新の安定版バージョン
DOMAIN="nextcloud.example.com"  # 実際のドメイン名に置き換えてください
LETSENCRYPT_EMAIL="your-email@example.com"   # Let's Encrypt登録用メールアドレスに置き換えてください

# システムの更新
echo "システムを更新しています..."
apt update && apt upgrade -y

# 必要な依存関係のインストール
echo "必要な依存関係をインストールしています..."
apt install -y \
    apache2 \
    libapache2-mod-php \
    php \
    php-gd \
    php-mysql \
    php-curl \
    php-mbstring \
    php-intl \
    php-xml \
    php-zip \
    php-bz2 \
    php-ldap \
    php-smbclient \
    php-imap \
    php-bcmath \
    mariadb-server \
    mariadb-client \
    php-mysql \
    unzip \
    wget \
    certbot \
    python3-certbot-apache

# MariaDBの初期設定
echo "MariaDBを設定しています..."
mysql_secure_installation

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
echo "Nextcloudのインストールが完了しました。"
echo "https://${DOMAIN} にアクセスしてNextcloudの初期設定を行ってください。"