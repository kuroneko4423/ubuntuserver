# Nextcloud Docker Setup

DockerでNextcloudを実行するための設定です。

## 構成

- **Nextcloud**: メインアプリケーション（smbclientインストール済み）
- **MySQL 8.0**: データベース
- **Redis**: キャッシュ

## 機能

- SMB/CIFSドライブへの接続対応（smbclientインストール済み）
- 外部ストレージアプリでSMB共有をマウント可能
- HTTPS接続対応（自己署名SSL証明書を自動生成）

## セットアップ

1. 環境変数ファイルをコピー:
```bash
cp .env.example .env
```

2. `.env`ファイルを編集してパスワードを設定

3. Dockerイメージをビルド:
```bash
docker-compose build
```

4. コンテナを起動:
```bash
docker-compose up -d
```

5. ブラウザでアクセス:
   - HTTP: `http://localhost:8080`
   - HTTPS: `https://localhost:8443` （自己署名証明書のため警告が表示されます）

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
- `NEXTCLOUD_PORT`: HTTP公開ポート（デフォルト: 8080）
- `NEXTCLOUD_HTTPS_PORT`: HTTPS公開ポート（デフォルト: 8443）

## SSL証明書について

このセットアップでは自己署名SSL証明書が自動的に生成されます。
- 証明書の有効期限: 365日
- 証明書のCN: localhost
- 保存場所: コンテナ内の `/etc/ssl/nextcloud/`

本番環境では、Let's Encryptなどの正式な証明書の使用を推奨します。

## SMB/CIFS共有の設定

Nextcloudで外部SMB/CIFS共有を使用するには：

1. 管理者でログイン
2. アプリ管理から「External storage support」を有効化
3. 設定 → 外部ストレージで新しいストレージを追加
4. ストレージタイプで「SMB/CIFS」を選択
5. 接続情報を入力:
   - ホスト: SMBサーバーのIPアドレスまたはホスト名
   - 共有: 共有フォルダ名
   - ユーザー名とパスワード