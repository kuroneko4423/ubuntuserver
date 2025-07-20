# Docker Compose - Nextcloud & Redmine with HTTPS

このディレクトリには、NextcloudとRedmineをDockerで起動し、Traefikを使用してLet's EncryptでHTTPS化するための設定が含まれています。

## 構成

- **Traefik**: リバースプロキシとLet's Encrypt SSL/TLS証明書の自動管理
- **Nextcloud**: プライベートクラウドストレージ
- **Redmine**: プロジェクト管理ツール
- **MariaDB**: Nextcloud用データベース
- **PostgreSQL**: Redmine用データベース
- **Redis**: Nextcloudのキャッシュ

## 前提条件

- Docker & Docker Composeがインストール済み
- ドメイン名を所有している
- ポート80と443が開放されている（Let's EncryptのHTTP-01チャレンジで必須）

## セットアップ手順

### 1. 環境変数の設定

```bash
cp .env.example .env
```

`.env`ファイルを編集して、以下の値を設定：

- `DOMAIN`: あなたのドメイン名（例: example.com）
- `LETSENCRYPT_EMAIL`: Let's Encrypt通知用のメールアドレス
- 各種パスワード: 安全なパスワードに変更

### 2. Traefik用ディレクトリの準備

```bash
# acme.jsonファイルの作成と権限設定
touch traefik/acme.json
chmod 600 traefik/acme.json
```

### 3. Dockerネットワークの作成

```bash
docker network create proxy
```

### 4. コンテナの起動

```bash
docker-compose up -d
```

### 5. DNS設定

DNSプロバイダーで以下のAレコードを作成：

- `nextcloud.example.com` → サーバーのIPアドレス
- `redmine.example.com` → サーバーのIPアドレス
- `traefik.example.com` → サーバーのIPアドレス（オプション）

## アクセス方法

起動後、以下のURLでアクセス可能：

- **Nextcloud**: https://nextcloud.yourdomain.com
- **Redmine**: https://redmine.yourdomain.com
- **Traefik Dashboard**: https://traefik.yourdomain.com（Basic認証付き）

## 初期ログイン情報

### Nextcloud
- ユーザー名: `.env`の`NEXTCLOUD_ADMIN_USER`で設定した値
- パスワード: `.env`の`NEXTCLOUD_ADMIN_PASSWORD`で設定した値

### Redmine
- ユーザー名: `admin`
- パスワード: `admin`（初回ログイン後に変更必須）

## バックアップ

### 自動バックアップスクリプト

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backup/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Nextcloudデータのバックアップ
docker run --rm -v nextcloud_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/nextcloud_data.tar.gz -C /data .

# Nextcloud DBのバックアップ
docker exec nextcloud_db mysqldump -u root -p${NEXTCLOUD_DB_ROOT_PASSWORD} nextcloud | gzip > $BACKUP_DIR/nextcloud_db.sql.gz

# Redmineファイルのバックアップ
docker run --rm -v redmine_files:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/redmine_files.tar.gz -C /data .

# Redmine DBのバックアップ
docker exec redmine_db pg_dump -U redmine redmine | gzip > $BACKUP_DIR/redmine_db.sql.gz
```

## トラブルシューティング

### ログの確認

```bash
# 全体のログ
docker-compose logs -f

# 特定のサービスのログ
docker-compose logs -f nextcloud
docker-compose logs -f redmine
docker-compose logs -f traefik
```

### SSL証明書が取得できない場合

1. DNS設定が正しいか確認（nslookupやdigコマンドで確認）
2. ポート80がインターネットからアクセス可能か確認
3. Traefikのログを確認: `docker-compose logs -f traefik`
4. Let's Encryptのレート制限に達していないか確認

### サービスの再起動

```bash
# 特定のサービスを再起動
docker-compose restart nextcloud
docker-compose restart redmine

# 全体を再起動
docker-compose restart
```

### コンテナの完全な再作成

```bash
docker-compose down
docker-compose up -d
```

## セキュリティ推奨事項

1. **定期的なアップデート**: 
   ```bash
   docker-compose pull
   docker-compose up -d
   ```

2. **ファイアウォールの設定**:
   - 必要なポート（80, 443）のみを開放
   - SSH（22）は信頼できるIPからのみアクセス可能に

3. **バックアップの自動化**:
   - cronで定期的にバックアップスクリプトを実行
   - バックアップは外部ストレージに保存

4. **監視**:
   - Traefikダッシュボードで定期的に状態を確認
   - ログを監視してエラーや不審なアクセスをチェック

## カスタマイズ

### Nextcloudの拡張

アプリのインストール:
1. Nextcloudにログイン
2. 設定 → アプリ
3. 必要なアプリをインストール

### Redmineのプラグイン

```bash
# プラグインのインストール例
docker exec -it redmine bash
cd plugins
git clone https://github.com/example/redmine_plugin.git
bundle install
rake redmine:plugins:migrate RAILS_ENV=production
```

## 注意事項

- 本番環境では必ず強力なパスワードを使用してください
- 定期的にバックアップを取得してください
- セキュリティアップデートを定期的に適用してください