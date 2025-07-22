# Nextcloud インストールスクリプト

このディレクトリには、Ubuntu ServerにNextcloudをインストールするためのスクリプトとDocker Compose構成が含まれています。

## ファイル構成

### 通常インストール用
- [`install_nextcloud.sh`](install_nextcloud.sh) - Nextcloudのインストールスクリプト

### Docker Compose用
- `docker-compose.yml` - Docker Compose構成ファイル
- `.env.example` - 環境変数のテンプレート
- `nginx.conf` - Nginx設定ファイル
- `.gitignore` - Git除外設定

## 機能

- Nextcloud 29.0.7（最新安定版）の自動インストール
- PHP 8.2/8.3対応
- Apache Webサーバーの設定
- MariaDBデータベースの設定
- SSL証明書の自動取得（Let's Encrypt）
- 必要なPHP拡張モジュールのインストール
- Apache仮想ホストの自動設定
- ファイアウォールの設定

## 使用方法

## インストール方法

### 方法1: 通常インストール（install_nextcloud.sh使用）

#### 前提条件

- Ubuntu 20.04 LTS または 22.04 LTS
- root権限でのアクセス
- インターネット接続
- ドメイン名の設定（DNSレコードが正しく設定されていること）
- 最低2GB以上のRAM推奨

#### インストール手順

1. スクリプトを実行可能にする：
   ```bash
   chmod +x install_nextcloud.sh
   ```

2. スクリプト内の変数を編集：
   ```bash
   nano install_nextcloud.sh
   ```
   - `NEXTCLOUD_VERSION`: 29.0.7（PHP 8.3対応版）
   - `PHP_VERSION`: 8.2（推奨）
   - `DOMAIN`: 実際のドメイン名に変更
   - `LETSENCRYPT_EMAIL`: Let's Encrypt登録用のメールアドレスに変更
   - `DB_NAME`: nextcloud（データベース名）
   - `DB_USER`: nextcloud（データベースユーザー名）
   - `DB_PASSWORD`: pnextcloud4423（データベースパスワード）

3. スクリプトを実行：
   ```bash
   sudo ./install_nextcloud.sh
   ```

#### インストール後の設定

1. ブラウザで `https://your-domain.com` にアクセス
2. Nextcloudの初期設定画面で以下を入力：
   - 管理者ユーザー名とパスワード（任意に設定）
   - データベース設定：
     - データベースタイプ: MariaDB
     - データベース名: nextcloud
     - データベースユーザー: nextcloud
     - データベースパスワード: pnextcloud4423
     - データベースホスト: localhost

## Apache仮想ホスト設定

スクリプトは自動的に以下の仮想ホスト設定を作成します：

```apache
<VirtualHost *:80>
    ServerName your-domain.com
    ServerAlias *
    DocumentRoot /var/www/html/nextcloud

    # 外部接続のための設定
    Header set Access-Control-Allow-Origin "*"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

    <Directory /var/www/html/nextcloud>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews

        # クロスオリジン設定
        Header set Access-Control-Allow-Origin "*"
        Header set Access-Control-Allow-Methods "GET, POST, OPTIONS"
        Header set Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept"

        <IfModule mod_dav.c>
            Dav off
        </IfModule>
    </Directory>

    # ログ設定
    ErrorLog ${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog ${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
```

### 設定の詳細

- **外部接続設定**: CORS（Cross-Origin Resource Sharing）ヘッダーとセキュリティヘッダーを設定
- **クロスオリジン設定**: 異なるドメインからのアクセスを許可
- **セキュリティヘッダー**: HSTS（HTTP Strict Transport Security）を設定

SSL証明書取得後、自動的にHTTPS設定も追加されます。

## セキュリティ設定

### 推奨設定

1. **強力なパスワードの使用**
   - 管理者アカウントには複雑なパスワードを設定

2. **ファイアウォールの設定**
   - 必要なポートのみを開放（80, 443）

3. **定期的なアップデート**
   ```bash
   sudo apt update && sudo apt upgrade
   ```

4. **バックアップの設定**
   - データディレクトリの定期バックアップ
   - データベースのバックアップ

### データベースセキュリティ

スクリプトは自動的に以下のセキュリティ設定を実行します：
- rootパスワードの設定
- 匿名ユーザーの削除
- リモートrootログインの無効化
- テストデータベースの削除
- Nextcloud専用データベースとユーザーの作成：
  - データベース名: nextcloud
  - ユーザー名: nextcloud
  - パスワード: pnextcloud4423

## トラブルシューティング

### よくある問題

1. **SSL証明書の取得に失敗する場合**
   - ドメインのDNSレコードが正しく設定されているか確認
   - ファイアウォールでポート80, 443が開いているか確認

2. **データベース接続エラー**
   - MariaDBサービスの状態確認: `sudo systemctl status mariadb`
   - データベース認証情報の確認：
     - データベース名: nextcloud
     - ユーザー名: nextcloud
     - パスワード: pnextcloud4423
     - ホスト: localhost

3. **ファイルアップロードの問題**
   - PHP設定の確認: `/etc/php/*/apache2/php.ini`
   - `upload_max_filesize` と `post_max_size` の値を調整

4. **権限エラー**
   ```bash
   sudo chown -R www-data:www-data /var/www/html/nextcloud
   sudo chmod -R 755 /var/www/html/nextcloud
   ```

### ログの確認

- Apache エラーログ: `/var/log/apache2/nextcloud_error.log`
- Apache アクセスログ: `/var/log/apache2/nextcloud_access.log`
- Nextcloud ログ: `/var/www/html/nextcloud/data/nextcloud.log`

## パフォーマンス最適化

### 推奨設定

1. **PHP OPcache の有効化**
   ```bash
   sudo nano /etc/php/*/apache2/php.ini
   ```
   ```ini
   opcache.enable=1
   opcache.memory_consumption=128
   opcache.max_accelerated_files=10000
   opcache.revalidate_freq=1
   ```

2. **APCu の設定**
   ```bash
   sudo apt install php-apcu
   ```

3. **データベースの最適化**
   ```bash
   sudo mysql_secure_installation
   ```

4. **定期的なメンテナンスタスクの実行**
   ```bash
   # crontabに追加
   sudo crontab -e
   
   # 毎日午前3時にメンテナンス実行
   0 3 * * * sudo -u www-data php /var/www/html/nextcloud/cron.php
   ```

### ファイルサイズ制限の調整

```bash
sudo nano /etc/php/*/apache2/php.ini
```

```ini
upload_max_filesize = 2G
post_max_size = 2G
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
```

設定変更後はApacheを再起動：
```bash
sudo systemctl restart apache2
```

## バックアップとリストア

### データのバックアップ

```bash
# データディレクトリのバックアップ
sudo tar -czf nextcloud_data_$(date +%Y%m%d).tar.gz /var/www/html/nextcloud/data

# データベースのバックアップ
sudo mysqldump -u nextcloud -ppnextcloud4423 nextcloud > nextcloud_db_$(date +%Y%m%d).sql

# 設定ファイルのバックアップ
sudo cp /var/www/html/nextcloud/config/config.php nextcloud_config_$(date +%Y%m%d).php
```

### 自動バックアップの設定

```bash
# バックアップスクリプトの作成
sudo nano /usr/local/bin/nextcloud_backup.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/backup/nextcloud"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# データベースバックアップ
mysqldump -u nextcloud -ppnextcloud4423 nextcloud > $BACKUP_DIR/nextcloud_db_$DATE.sql

# データディレクトリバックアップ
tar -czf $BACKUP_DIR/nextcloud_data_$DATE.tar.gz /var/www/html/nextcloud/data

# 古いバックアップの削除（7日以上前）
find $BACKUP_DIR -name "nextcloud_*" -mtime +7 -delete
```

```bash
# 実行権限付与
sudo chmod +x /usr/local/bin/nextcloud_backup.sh

# crontabに追加（毎日午前2時実行）
sudo crontab -e
0 2 * * * /usr/local/bin/nextcloud_backup.sh
```

### 方法2: Docker Composeを使用したインストール

#### 前提条件

- Docker および Docker Compose がインストール済み
- ドメイン名の設定（SSL証明書取得用）
- 最低2GB以上のRAM推奨

#### インストール手順

1. 環境変数ファイルを作成：
   ```bash
   cp .env.example .env
   ```

2. `.env`ファイルを編集して設定を変更：
   ```bash
   nano .env
   ```
   必須項目：
   - `MYSQL_ROOT_PASSWORD`: データベースのrootパスワード
   - `MYSQL_PASSWORD`: Nextcloud用データベースパスワード
   - `NEXTCLOUD_ADMIN_PASSWORD`: Nextcloud管理者パスワード
   - `NEXTCLOUD_DOMAIN`: 実際のドメイン名
   - `LETSENCRYPT_EMAIL`: SSL証明書通知用メールアドレス

3. コンテナを起動：
   ```bash
   docker-compose up -d
   ```

4. SSL証明書を取得（初回のみ）：
   ```bash
   # ドメイン名とメールアドレスを実際の値に置き換えてください
   docker-compose exec certbot certbot certonly \
     --webroot -w /var/www/certbot \
     -d your-domain.com \
     --email your-email@example.com \
     --agree-tos --non-interactive
   ```

5. Nginxを再起動してSSL設定を適用：
   ```bash
   docker-compose restart nginx
   ```

6. ブラウザで `https://your-domain.com` にアクセス

#### Docker構成の詳細

**含まれるサービス：**
- **Nextcloud 29.0.7**: メインアプリケーション（PHP 8.3対応）
- **MariaDB 10.11**: データベースサーバー
- **Redis**: キャッシュとファイルロック用
- **Nginx**: リバースプロキシとSSL終端
- **Certbot**: Let's Encrypt SSL証明書の自動更新

**ボリューム構成：**
- `./data`: Nextcloudのデータディレクトリ（ローカルマウント）
- `db_data`: MariaDBデータ（名前付きボリューム）
- `nextcloud_data`: Nextcloudアプリケーションファイル（名前付きボリューム）
- `./ssl`: SSL証明書（ローカルマウント）

#### Dockerコマンド集

```bash
# ログを確認
docker-compose logs -f

# 特定のサービスのログを確認
docker-compose logs -f app

# コンテナの状態を確認
docker-compose ps

# コンテナを停止
docker-compose stop

# コンテナを停止して削除
docker-compose down

# データも含めて完全に削除
docker-compose down -v

# Nextcloudのocc コマンドを実行
docker-compose exec --user www-data app php occ [コマンド]

# 例：ファイルスキャンを実行
docker-compose exec --user www-data app php occ files:scan --all
```

#### トラブルシューティング（Docker版）

1. **コンテナが起動しない場合**
   ```bash
   docker-compose logs [サービス名]
   ```
   でエラーログを確認

2. **権限エラーが発生する場合**
   ```bash
   # データディレクトリの権限を修正
   docker-compose exec app chown -R www-data:www-data /var/www/html
   ```

3. **SSL証明書エラー**
   - ドメインのDNS設定を確認
   - ポート80,443が開いていることを確認
   - 初回は証明書取得前にHTTPでアクセス可能か確認

4. **データベース接続エラー**
   ```bash
   # データベースコンテナの状態を確認
   docker-compose exec db mysql -u nextcloud -ppnextcloud4423 -e "SHOW DATABASES;"
   ```

## PHP互換性について

### Nextcloud バージョンとPHP互換性

| Nextcloud | PHP 8.0 | PHP 8.1 | PHP 8.2 | PHP 8.3 |
|-----------|---------|---------|---------|----------|
| 27.x      | ✓       | ✓       | ✓       | ✗        |
| 28.x      | ✓       | ✓       | ✓       | ✓        |
| 29.x      | ✗       | ✓       | ✓       | ✓        |

**推奨構成：**
- Nextcloud 29.0.7 + PHP 8.2（最も安定）
- Nextcloud 29.0.7 + PHP 8.3（最新環境）

詳細な設定については、[Nextcloud公式ドキュメント](https://docs.nextcloud.com/)を参照してください。