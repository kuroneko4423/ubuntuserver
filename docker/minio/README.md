# MinIO Docker Setup

MinIOは高性能な分散オブジェクトストレージサーバーです。Amazon S3互換のAPIを提供します。

## セットアップ

1. `.env.example`を`.env`にコピーして認証情報を設定します：
   ```bash
   cp .env.example .env
   ```

2. `.env`ファイルを編集して認証情報を変更します：
   ```
   MINIO_ROOT_USER=your_username
   MINIO_ROOT_PASSWORD=your_password
   ```
   
   **重要**: デフォルトの認証情報は本番環境では必ず変更してください。

3. MinIOを起動します：
   ```bash
   docker-compose up -d
   ```

## アクセス方法

- **MinIO API**: http://localhost:9000
- **MinIO Console (Web UI)**: http://localhost:9001

MinIO Consoleにアクセスし、`.env`ファイルで設定した認証情報でログインできます。

## 主な機能

- S3互換API
- ブラウザベースの管理コンソール
- バケットの作成・管理
- ファイルのアップロード・ダウンロード
- アクセスポリシーの設定
- ユーザー管理

## 停止方法

```bash
docker-compose down
```

## データの永続化

データは`minio_data`という名前のDockerボリュームに保存されます。

## トラブルシューティング

### ポートが既に使用されている場合
`docker-compose.yml`のポート設定を変更してください：
```yaml
ports:
  - "9010:9000"  # API
  - "9011:9001"  # Console
```

### ログの確認
```bash
docker-compose logs -f minio
```