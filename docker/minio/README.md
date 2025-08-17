# MinIO Docker Setup (HTTPS対応)

MinIOは高性能な分散オブジェクトストレージサーバーです。Amazon S3互換のAPIを提供します。
このセットアップではHTTPS通信に対応しており、自己署名証明書が自動的に生成されます。

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

3. MinIOを起動します（初回起動時に自動的にHTTPS証明書が生成されます）：
   ```bash
   docker-compose up -d
   ```

## アクセス方法

### HTTPSでのアクセス（推奨）
- **MinIO API**: https://localhost:9000
- **MinIO Console (Web UI)**: https://localhost:9001

### HTTPでのアクセス（非推奨）
HTTPSが設定されている場合、HTTPでのアクセスはリダイレクトされます。

MinIO Consoleにアクセスし、`.env`ファイルで設定した認証情報でログインできます。

**注意**: 自己署名証明書を使用しているため、ブラウザで証明書の警告が表示されます。開発環境では警告を受け入れて続行してください。

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

## HTTPS証明書の管理

### 証明書について
証明書はDockerイメージのビルド時に自動的に生成され、コンテナ内に組み込まれます。
- 有効期限: 365日
- 証明書の場所: コンテナ内の `/root/.minio/certs/`
- ベースイメージ: Ubuntu 22.04（`apt-get`を使用）

### 証明書の更新
証明書を更新する場合は、Dockerイメージを再ビルドします：
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### カスタム証明書を使用する場合
独自の証明書を使用したい場合は、Dockerfileを編集して証明書ファイルをコピーするように変更してください。

## ストレージパスの変更
デフォルトではDockerボリュームを使用しますが、ホストの特定のディレクトリを使用したい場合は以下の手順で変更できます。

1. MinIOを停止します：
   ```bash
   docker-compose down
   ```

2. `docker-compose.yml`を編集して、ボリューム設定を変更します：
   ```yaml
   # 変更前（Dockerボリューム）
   volumes:
     - minio_data:/data
   
   # 変更後（ホストディレクトリ）
   volumes:
     - /path/to/your/storage:/data
   ```
   
   例：`/media/ubuntuserver/hdd`を使用する場合
   ```yaml
   volumes:
     - /media/ubuntuserver/hdd/minio:/data
   ```

3. ホストディレクトリに適切な権限を設定します：
   ```bash
   sudo mkdir -p /path/to/your/storage
   sudo chown -R 1000:1000 /path/to/your/storage
   ```

4. MinIOを再起動します：
   ```bash
   docker-compose up -d
   ```

**注意事項**:
- ホストディレクトリは事前に作成しておく必要があります
- MinIOコンテナ内のユーザー（UID:1000）がアクセスできる権限が必要です
- 既存のデータがある場合は、移行前にバックアップを取ることを推奨します