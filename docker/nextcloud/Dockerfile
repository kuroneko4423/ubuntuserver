FROM nextcloud:latest

RUN apt-get update && \
    apt-get install -y \
        smbclient \
        libsmbclient-dev \
        openssl && \
    rm -rf /var/lib/apt/lists/*

# SSL証明書の生成
RUN mkdir -p /etc/ssl/nextcloud && \
    openssl req -x509 -nodes -days 10000 -newkey rsa:2048 \
    -keyout /etc/ssl/nextcloud/nextcloud.key \
    -out /etc/ssl/nextcloud/nextcloud.crt \
    -subj "/C=JP/ST=Tokyo/L=Tokyo/O=Nextcloud/OU=IT/CN=localhost"

# Apache SSL設定
RUN a2enmod ssl && \
    a2enmod rewrite && \
    a2enmod headers

# Apache設定ファイルの作成
RUN echo '<VirtualHost *:443>\n\
    DocumentRoot /var/www/html\n\
    \n\
    SSLEngine on\n\
    SSLCertificateFile /etc/ssl/nextcloud/nextcloud.crt\n\
    SSLCertificateKeyFile /etc/ssl/nextcloud/nextcloud.key\n\
    \n\
    <Directory /var/www/html/>\n\
        Options +FollowSymlinks\n\
        AllowOverride All\n\
        Require all granted\n\
        \n\
        <IfModule mod_dav.c>\n\
            Dav off\n\
        </IfModule>\n\
        \n\
        SetEnv HOME /var/www/html\n\
        SetEnv HTTP_HOME /var/www/html\n\
    </Directory>\n\
    \n\
    <IfModule mod_headers.c>\n\
        Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"\n\
    </IfModule>\n\
</VirtualHost>' > /etc/apache2/sites-available/nextcloud-ssl.conf && \
    a2ensite nextcloud-ssl

# ポート設定（Listen 443がまだ存在しない場合のみ追加）
RUN grep -q "Listen 443" /etc/apache2/ports.conf || echo "Listen 443" >> /etc/apache2/ports.conf

EXPOSE 443