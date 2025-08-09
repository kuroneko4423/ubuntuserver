# PostgreSQL Docker Setup

PostgreSQL 14 (Alpine版) をDockerで実行するための設定です。

## セットアップ

1. `.env.example`を`.env`にコピーして、必要に応じて設定を変更してください：

```bash
cp .env.example .env
```

2. `.env`ファイルを編集して、パスワードなどの設定を変更してください：

```bash
# 必須: パスワードを安全なものに変更
POSTGRES_PASSWORD=your_secure_password_here
```

## 起動方法

```bash
docker-compose up -d
```

## 停止方法

```bash
docker-compose down
```

## 設定情報

設定は`.env`ファイルで管理されます：

- **PostgreSQLバージョン**: 14-alpine
- **ポート**: `.env`の`POSTGRES_PORT`で設定（デフォルト: 5432）
- **データベース名**: `.env`の`POSTGRES_DB`で設定（デフォルト: postgres）
- **ユーザー名**: `.env`の`POSTGRES_USER`で設定（デフォルト: postgres）
- **パスワード**: `.env`の`POSTGRES_PASSWORD`で設定
- **タイムゾーン**: `.env`の`TZ`で設定（デフォルト: Asia/Tokyo）

## データの永続化

PostgreSQLのデータは `postgres_data` ボリュームに保存されます。コンテナを削除してもデータは保持されます。

## 接続方法

### コマンドライン

```bash
psql -h localhost -p 5432 -U postgres -d postgres
```

### 接続文字列

```
postgresql://<POSTGRES_USER>:<POSTGRES_PASSWORD>@localhost:<POSTGRES_PORT>/<POSTGRES_DB>
```

例（デフォルト設定の場合）：
```
postgresql://postgres:your_password@localhost:5432/postgres
```

## コンテナ内でのSQL実行

```bash
docker exec -it postgres psql -U postgres
```

## データベースの作成

```bash
docker exec -it postgres createdb -U postgres mydatabase
```

## バックアップ

```bash
docker exec postgres pg_dump -U postgres postgres > backup.sql
```

## リストア

```bash
docker exec -i postgres psql -U postgres postgres < backup.sql
```

## ログの確認

```bash
docker-compose logs -f postgres
```

## トラブルシューティング

### ポート5432が既に使用されている場合

`.env`ファイルの`POSTGRES_PORT`を変更してください：

```bash
POSTGRES_PORT=5433  # 5433などの空いているポートに変更
```

### データをリセットしたい場合

```bash
docker-compose down -v
```

`-v` オプションでボリュームも削除されます。