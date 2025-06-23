#!/bin/bash

# JupyterHub インストールスクリプト for Ubuntu 22.04

# rootとして実行されていることを確認
if [[ $EUID -ne 0 ]]; then
   echo "このスクリプトはroot権限で実行する必要があります。sudo を使用してください。"
   exit 1
fi

# 変数設定
JUPYTERHUB_VERSION="3.0.0"
NODEJS_VERSION="16.x"
ADMIN_USER="jupyteradmin"
DOMAIN="jupyterhub.example.com"
LETSENCRYPT_EMAIL="your-email@example.com"

# システムの更新
echo "システムを更新しています..."
apt update && apt upgrade -y

# 必要な依存関係のインストール
echo "必要な依存関係をインストールしています..."
apt install -y \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    nodejs \
    npm \
    nginx \
    software-properties-common \
    curl \
    git \
    certbot \
    python3-certbot-nginx

# Node.jsの最新版をインストール
curl -fsSL https://deb.nodesource.com/setup_${NODEJS_VERSION} | bash -
apt install -y nodejs

# Pythonの仮想環境を作成
echo "Pythonの仮想環境を作成しています..."
python3 -m venv /opt/jupyterhub
source /opt/jupyterhub/bin/activate

# JupyterHubとJupyterLabのインストール
echo "JupyterHubをインストールしています..."
pip install \
    jupyterhub==${JUPYTERHUB_VERSION} \
    jupyterlab \
    notebook \
    ipykernel

# configディレクトリの作成
mkdir -p /etc/jupyterhub
cd /etc/jupyterhub

# JupyterHubの設定ファイルを生成
jupyterhub --generate-config

# 設定ファイルをカスタマイズ
cat > /etc/jupyterhub/jupyterhub_config.py << EOL
c.JupyterHub.port = 8000
c.JupyterHub.bind_url = 'http://0.0.0.0:8000'
c.Authenticator.admin_users = {'${ADMIN_USER}'}
c.JupyterHub.authenticator_class = 'jupyterhub.auth.PAMAuthenticator'
c.JupyterHub.spawner_class = 'jupyterhub.spawner.SystemUserSpawner'
c.Spawner.default_url = '/lab'
c.Spawner.cmd = ['jupyter-labhub']
EOL

# Systemdサービスの作成
cat > /etc/systemd/system/jupyterhub.service << EOL
[Unit]
Description=JupyterHub
After=syslog.target network.target

[Service]
User=root
ExecStart=/opt/jupyterhub/bin/jupyterhub -f /etc/jupyterhub/jupyterhub_config.py
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Nginxリバースプロキシ設定
cat > /etc/nginx/sites-available/jupyterhub << EOL
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://${DOMAIN}\$request_uri;
}

server {
    listen 443 ssl;
    server_name ${DOMAIN};

    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

    # SSL設定の最適化
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH;
    ssl_ecdh_curve secp384r1;
    ssl_session_timeout  10m;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

# Nginx設定の有効化
ln -s /etc/nginx/sites-available/jupyterhub /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

# Let's Encryptを使用したSSL証明書の取得
certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos -m ${LETSENCRYPT_EMAIL}

# 管理者ユーザーの作成
echo "管理者ユーザーを作成しています..."
adduser --disabled-password --gecos "" ${ADMIN_USER}

# JupyterHubサービスの有効化と起動
systemctl daemon-reload
systemctl enable jupyterhub
systemctl start jupyterhub

# ファイアウォールの設定
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8000/tcp
ufw reload

echo "JupyterHubのインストールが完了しました。"
echo "https://jupyterhub.example.com にアクセスしてください。"
echo "管理者ユーザー: ${ADMIN_USER}"