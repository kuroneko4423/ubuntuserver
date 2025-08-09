# Nextcloud Docker Setup

DockerでNextcloudを実行するための設定です。

## 構成

- **Nextcloud**: メインアプリケーション（smbclientインストール済み）
- **MySQL 8.0**: データベース
- **Redis**: キャッシュ

## 機能

- SMB/CIFSドライブへの接続対応（smbclientインストール済み）
- 外部ストレージアプリでSMB共有をマウント可能

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

5. ブラウザで `http://localhost:8080` にアクセス

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