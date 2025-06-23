#!/bin/bash

# rootとして実行されていることを確認
if [[ $EUID -ne 0 ]]; then
   echo "このスクリプトはroot権限で実行する必要があります。sudoを使用してください。"
   exit 1
fi

# 変数設定
DOMAIN="gitlab.example.com"  # 実際のドメイン名に置き換えてください
EMAIL="your-email@example.com"   # Let's Encrypt登録用メールアドレスに置き換えてください

# システムの更新と必要な依存関係のインストール
echo "システムを更新しています..."
apt update && apt upgrade -y
apt install -y curl openssh-server ca-certificates tzdata perl

# タイムゾーンの設定
dpkg-reconfigure tzdata

# GitLabリポジトリの追加
echo "GitLabリポジトリを追加しています..."
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash

# GitLabのインストール
echo "GitLabをインストールしています..."
EXTERNAL_URL="https://${DOMAIN}" apt install -y gitlab-ce

# GitLabの初期設定
echo "GitLabを設定しています..."
gitlab-ctl reconfigure

# Let's Encryptを使用したSSL証明書の設定
echo "SSL証明書を設定しています..."
# Let's Encryptを使用するには、事前にcertbotをインストールする必要があります
apt install -y certbot python3-certbot-nginx

# SSL証明書の取得
certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos -m ${EMAIL}

# Nginx設定の更新
gitlab-ctl stop
gitlab-ctl start

# ファイアウォールの設定
echo "ファイアウォールを設定しています..."
ufw allow 'OpenSSH'
ufw allow 'Nginx Full'
ufw enable

# GitLabの初期パスワードを表示
echo "初期パスワードを取得しています..."
sudo grep 'Password:' /etc/gitlab/initial_root_password

# 最終メッセージ
echo "GitLabのインストールが完了しました。"
echo "https://${DOMAIN} にアクセスしてください。"
echo "初期ログインユーザー: root"
echo "初期パスワードは上記で表示されたものを使用してください。"
echo "初回ログイン後、パスワードを変更することを強く推奨します。"