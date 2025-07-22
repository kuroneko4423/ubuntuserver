# Nextcloud Docker Setup

DockerでNextcloudを実行するための設定です。

## 構成

- **Nextcloud**: メインアプリケーション
- **MySQL 8.0**: データベース
- **Redis**: キャッシュ

## セットアップ

1. 環境変数ファイルをコピー:
```bash
cp .env.example .env
```

2. `.env`ファイルを編集してパスワードを設定

3. コンテナを起動:
```bash
docker-compose up -d
```

4. ブラウザで `http://localhost:8080` にアクセス

## 停止

```bash
docker-compose down
```

## データの永続化

- データベース: `nextcloud_db` volume
- Nextcloudデータ: `nextcloud_data` volume

## 環境変数

`.env`ファイルで以下の変数を設定できます：

- `MYSQL_ROOT_PASSWORD`: MySQLのrootパスワード
- `MYSQL_DATABASE`: データベース名
- `MYSQL_USER`: データベースユーザー名  
- `MYSQL_PASSWORD`: データベースパスワード
- `REDIS_PASSWORD`: Redisパスワード
- `NEXTCLOUD_ADMIN_USER`: Nextcloud管理者ユーザー名
- `NEXTCLOUD_ADMIN_PASSWORD`: Nextcloud管理者パスワード
- `NEXTCLOUD_TRUSTED_DOMAINS`: 信頼するドメイン
- `NEXTCLOUD_PORT`: 公開ポート（デフォルト: 8080）