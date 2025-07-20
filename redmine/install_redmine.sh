#!/bin/bash

# Ubuntu用Redmineインストールスクリプト
# このスクリプトはRedmineをMySQL/MariaDBとApache2でインストールします

set -e

echo "=== Redmineインストールスクリプト ==="
echo "このスクリプトはUbuntuにRedmineをインストールし、外部アクセスを設定します"
echo ""

# システムパッケージの更新
echo "システムパッケージを更新しています..."
sudo apt-get update
sudo apt-get upgrade -y

# 必要な依存関係のインストール
echo "依存関係をインストールしています..."
sudo apt-get install -y \
    build-essential \
    libmysqlclient-dev \
    imagemagick \
    libmagickwand-dev \
    libxml2-dev \
    libxslt1-dev \
    apache2 \
    libapache2-mod-passenger \
    mysql-server \
    mysql-client \
    git \
    curl \
    gnupg2 \
    ca-certificates \
    lsb-release \
    software-properties-common

# rbenvを使用してRubyをインストール
echo "Rubyをインストールしています..."
if [ ! -d "$HOME/.rbenv" ]; then
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
    echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
fi

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"

# Ruby 3.1.4をインストール（Redmine 5.x推奨バージョン）
RUBY_VERSION="3.1.4"
rbenv install $RUBY_VERSION
rbenv global $RUBY_VERSION
gem install bundler

# MySQLデータベースのセットアップ
echo "MySQLデータベースを設定しています..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS redmine CHARACTER SET utf8mb4;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'redmine'@'localhost' IDENTIFIED BY 'redmine_password';"
sudo mysql -e "GRANT ALL PRIVILEGES ON redmine.* TO 'redmine'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Redmineのダウンロードとインストール
echo "Redmineをダウンロードしています..."
cd /opt
sudo git clone https://github.com/redmine/redmine.git
sudo chown -R $USER:$USER /opt/redmine
cd /opt/redmine

# 安定版（5.1ブランチ）をチェックアウト
git checkout 5.1-stable

# データベース設定
echo "データベースを設定しています..."
cat > config/database.yml << EOF
production:
  adapter: mysql2
  database: redmine
  host: localhost
  username: redmine
  password: redmine_password
  encoding: utf8mb4
EOF

# Gemのインストール
echo "Ruby gemsをインストールしています..."
bundle config set --local without 'development test'
bundle install

# シークレットトークンの生成
echo "シークレットトークンを生成しています..."
bundle exec rake generate_secret_token

# データベース構造の作成
echo "データベース構造を作成しています..."
RAILS_ENV=production bundle exec rake db:migrate

# デフォルトデータの読み込み
echo "デフォルトデータを読み込んでいます..."
RAILS_ENV=production REDMINE_LANG=ja bundle exec rake redmine:load_default_data

# ディレクトリの作成と権限設定
echo "ディレクトリを設定しています..."
mkdir -p tmp/pdf public/plugin_assets
sudo chown -R www-data:www-data files log tmp public/plugin_assets
sudo chmod -R 755 files log tmp public/plugin_assets

# Apacheの設定
echo "Apacheを設定しています..."
sudo a2enmod passenger
sudo a2enmod rewrite

# Apache仮想ホストの作成
sudo tee /etc/apache2/sites-available/redmine.conf << EOF
<VirtualHost *:80>
    ServerName redmine.local
    DocumentRoot /opt/redmine/public
    
    <Directory /opt/redmine/public>
        Options -MultiViews
        Require all granted
        AllowOverride All
    </Directory>
    
    PassengerRoot /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini
    PassengerDefaultRuby /home/$USER/.rbenv/shims/ruby
    PassengerAppEnv production
    
    ErrorLog \${APACHE_LOG_DIR}/redmine_error.log
    CustomLog \${APACHE_LOG_DIR}/redmine_access.log combined
</VirtualHost>
EOF

# サイトを有効化してデフォルトを無効化
sudo a2dissite 000-default
sudo a2ensite redmine

# ファイアウォールの設定（ufwが有効な場合）
if sudo ufw status | grep -q "Status: active"; then
    echo "ファイアウォールを設定しています..."
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
fi

# Apacheの再起動
echo "Apacheを再起動しています..."
sudo systemctl restart apache2

# systemdサービスの作成（オプション）
sudo tee /etc/systemd/system/redmine.service << EOF
[Unit]
Description=Redmine
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/redmine
Environment="RAILS_ENV=production"
ExecStart=/home/$USER/.rbenv/shims/bundle exec rails server -e production -b 0.0.0.0 -p 3000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo "=== インストール完了 ==="
echo ""
echo "Redmineが正常にインストールされました！"
echo ""
echo "アクセス情報:"
echo "- URL: http://サーバーのIPアドレス/"
echo "- デフォルト管理者ユーザー名: admin"
echo "- デフォルト管理者パスワード: admin"
echo ""
echo "重要: 初回ログイン後、必ず管理者パスワードを変更してください！"
echo ""
echo "外部アクセスを許可するには:"
echo "1. サーバーのファイアウォールでポート80（およびHTTPSの場合は443）を許可"
echo "2. クラウドサービス（AWS、Azureなど）の場合はセキュリティグループを設定"
echo "3. ドメインのDNSをこのサーバーに向ける"
echo ""
echo "HTTPS設定にはLet's Encryptの使用を推奨:"
echo "sudo apt-get install certbot python3-certbot-apache"
echo "sudo certbot --apache -d your-domain.com"