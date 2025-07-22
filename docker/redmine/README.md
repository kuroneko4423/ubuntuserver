# Redmine Docker Setup

DockerでRedmineを実行するための設定です。

## 構成

- **Redmine**: メインアプリケーション
- **MySQL 8.0**: データベース

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

4. ブラウザで `http://localhost:3000` にアクセス

## 停止

```bash
docker-compose down
```

## データの永続化

- データベース: `redmine_db` volume
- Redmineファイル: `redmine_data` volume
- プラグイン: `redmine_plugins` volume
- テーマ: `redmine_themes` volume

## 環境変数

`.env`ファイルで以下の変数を設定できます：

- `MYSQL_ROOT_PASSWORD`: MySQLのrootパスワード
- `MYSQL_DATABASE`: データベース名
- `MYSQL_USER`: データベースユーザー名
- `MYSQL_PASSWORD`: データベースパスワード
- `REDMINE_PORT`: 公開ポート（デフォルト: 3000）
- `REDMINE_SECRET_KEY_BASE`: Redmineの秘密鍵

## 初期設定

Redmineの初期設定は以下の通りです：

- 管理者ユーザー: admin
- 管理者パスワード: admin（初回ログイン時に変更を求められます）