#!/bin/bash

# rootとして実行されていることを確認
if [[ $EUID -ne 0 ]]; then
   echo "このスクリプトはroot権限で実行する必要があります。sudoを使用してください。"
   exit 1
fi

# 変数設定
DB_USER="postgresadmin"
DB_PASSWORD="postgresadmin_password"
ALLOWED_IP="0.0.0.0/0"  # すべてのIPからの接続を許可（本番環境では制限することを推奨）

# システムの更新
echo "システムを更新しています..."
apt update && apt upgrade -y

# PostgreSQLのインストール
echo "PostgreSQLをインストールしています..."
apt install -y postgresql postgresql-contrib

# PostgreSQLサービスの開始と有効化
systemctl start postgresql
systemctl enable postgresql

# PostgreSQLの設定ファイルのパス
PG_CONF="/etc/postgresql/14/main/postgresql.conf"
PG_HBA="/etc/postgresql/14/main/pg_hba.conf"

# 外部接続の設定
echo "外部接続を設定しています..."
# リスニングアドレスを変更
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $PG_CONF

# pg_hba.confを更新して外部接続を許可
echo "host    all             all             ${ALLOWED_IP}          md5" >> $PG_HBA

# パスワード認証方式に変更
sed -i 's/local   all             postgres                                peer/local   all             postgres                                md5/' $PG_HBA

# PostgreSQLユーザーの作成とパスワード設定
sudo -u postgres psql <<EOF
CREATE USER ${DB_USER} WITH SUPERUSER PASSWORD '${DB_PASSWORD}';
CREATE DATABASE ${DB_USER}_db;
GRANT ALL PRIVILEGES ON DATABASE ${DB_USER}_db TO ${DB_USER};
EOF

# ファイアウォールの設定
echo "ファイアウォールを設定しています..."
apt install -y ufw
ufw allow 5432/tcp
ufw enable

# PostgreSQLの再起動
systemctl restart postgresql

# セキュリティ強化のためのアドバイス
echo "セキュリティに関する注意:"
echo "1. 本番環境では、ALLOWED_IPを具体的なIPアドレスに制限してください"
echo "2. DB_PASSWORDは強力で複雑なパスワードに変更してください"
echo "3. pg_hba.confでさらに詳細なアクセス制御を行うことを推奨します"

# 接続テストの説明
echo "接続テスト方法:"
echo "psql -h <サーバーのホスト> -U ${DB_USER} -d ${DB_USER}_db"

# 最終メッセージ
echo "PostgreSQLのインストールと外部接続設定が完了しました。"