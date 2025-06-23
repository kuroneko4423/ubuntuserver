# PostgreSQL インストールスクリプト

このディレクトリには、Ubuntu ServerにPostgreSQLをインストールし、外部接続を設定するためのスクリプトが含まれています。

## ファイル構成

- [`install_postgresql.sh`](install_postgresql.sh) - PostgreSQLのインストールと設定スクリプト

## 機能

- PostgreSQL最新版の自動インストール
- 外部接続の設定
- 管理者ユーザーの作成
- データベースの作成
- ファイアウォールの設定
- セキュリティ設定の最適化

## 使用方法

### 前提条件

- Ubuntu 20.04 LTS または 22.04 LTS
- root権限でのアクセス
- インターネット接続

### インストール手順

1. スクリプトを実行可能にする：
   ```bash
   chmod +x install_postgresql.sh
   ```

2. スクリプト内の変数を編集（セキュリティのため必須）：
   ```bash
   nano install_postgresql.sh
   ```
   - `DB_USER`: データベース管理者ユーザー名を変更
   - `DB_PASSWORD`: **強力なパスワードに変更**
   - `ALLOWED_IP`: 接続を許可するIPアドレス範囲を制限

3. スクリプトを実行：
   ```bash
   sudo ./install_postgresql.sh
   ```

### インストール後の確認

1. PostgreSQLサービスの状態確認：
   ```bash
   sudo systemctl status postgresql
   ```

2. データベースへの接続テスト：
   ```bash
   psql -h localhost -U postgresadmin -d postgresadmin_db
   ```

## 設定詳細

### デフォルト設定

- **ポート**: 5432
- **管理者ユーザー**: `postgresadmin`
- **データベース**: `postgresadmin_db`
- **接続許可**: すべてのIP（`0.0.0.0/0`）

### 設定ファイル

1. **postgresql.conf**: `/etc/postgresql/14/main/postgresql.conf`
   - `listen_addresses = '*'` - すべてのIPアドレスからの接続を許可

2. **pg_hba.conf**: `/etc/postgresql/14/main/pg_hba.conf`
   - MD5パスワード認証の設定
   - 外部接続の許可設定

## セキュリティ設定

### 重要なセキュリティ対策

1. **パスワードの変更**
   ```sql
   -- PostgreSQLに接続後
   ALTER USER postgresadmin PASSWORD 'new_strong_password';
   ```

2. **接続IP制限**
   ```bash
   # pg_hba.confを編集
   sudo nano /etc/postgresql/14/main/pg_hba.conf
   
   # 例: 特定のIPのみ許可
   host    all             all             192.168.1.0/24          md5
   ```

3. **ファイアウォール設定の確認**
   ```bash
   sudo ufw status
   sudo ufw allow from 192.168.1.0/24 to any port 5432
   ```

### SSL/TLS暗号化の有効化

1. SSL証明書の生成：
   ```bash
   sudo -u postgres openssl req -new -x509 -days 365 -nodes -text \
     -out /var/lib/postgresql/14/main/server.crt \
     -keyout /var/lib/postgresql/14/main/server.key
   ```

2. 設定ファイルの編集：
   ```bash
   sudo nano /etc/postgresql/14/main/postgresql.conf
   ```
   ```
   ssl = on
   ssl_cert_file = 'server.crt'
   ssl_key_file = 'server.key'
   ```

## データベース管理

### 基本的なSQL操作

```sql
-- データベース一覧表示
\l

-- ユーザー一覧表示
\du

-- 新しいデータベース作成
CREATE DATABASE myapp_db;

-- 新しいユーザー作成
CREATE USER myapp_user WITH PASSWORD 'secure_password';

-- 権限付与
GRANT ALL PRIVILEGES ON DATABASE myapp_db TO myapp_user;

-- 接続
\c myapp_db
```

### バックアップとリストア

```bash
# データベースのバックアップ
pg_dump -h localhost -U postgresadmin -d postgresadmin_db > backup.sql

# データベースのリストア
psql -h localhost -U postgresadmin -d postgresadmin_db < backup.sql

# 全データベースのバックアップ
pg_dumpall -h localhost -U postgresadmin > full_backup.sql
```

## パフォーマンス最適化

### 推奨設定

1. **メモリ設定の調整**
   ```bash
   sudo nano /etc/postgresql/14/main/postgresql.conf
   ```
   ```
   shared_buffers = 256MB          # システムRAMの25%程度
   effective_cache_size = 1GB      # システムRAMの75%程度
   work_mem = 4MB                  # 接続数に応じて調整
   maintenance_work_mem = 64MB     # メンテナンス作業用
   ```

2. **接続設定**
   ```
   max_connections = 100           # 同時接続数
   ```

3. **ログ設定**
   ```
   logging_collector = on
   log_directory = 'pg_log'
   log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
   log_statement = 'all'           # 本番環境では'none'推奨
   ```

### 定期メンテナンス

```bash
# 統計情報の更新
sudo -u postgres psql -c "ANALYZE;"

# 不要領域の回収
sudo -u postgres psql -c "VACUUM;"

# 自動バキューム設定の確認
sudo -u postgres psql -c "SHOW autovacuum;"
```

## トラブルシューティング

### よくある問題

1. **接続できない場合**
   ```bash
   # サービス状態確認
   sudo systemctl status postgresql
   
   # ポート確認
   sudo netstat -tlnp | grep 5432
   
   # ログ確認
   sudo tail -f /var/log/postgresql/postgresql-14-main.log
   ```

2. **認証エラー**
   ```bash
   # pg_hba.conf の確認
   sudo cat /etc/postgresql/14/main/pg_hba.conf
   
   # 設定再読み込み
   sudo systemctl reload postgresql
   ```

3. **パフォーマンス問題**
   ```sql
   -- 実行中のクエリ確認
   SELECT * FROM pg_stat_activity;
   
   -- 長時間実行中のクエリ
   SELECT * FROM pg_stat_activity WHERE state = 'active' AND query_start < now() - interval '5 minutes';
   ```

### ログファイルの場所

- PostgreSQLログ: `/var/log/postgresql/postgresql-14-main.log`
- システムログ: `/var/log/syslog`

## 監視とメンテナンス

### 定期的な監視項目

1. **ディスク使用量**
   ```sql
   SELECT pg_size_pretty(pg_database_size('postgresadmin_db'));
   ```

2. **接続数**
   ```sql
   SELECT count(*) FROM pg_stat_activity;
   ```

3. **レプリケーション状態**（該当する場合）
   ```sql
   SELECT * FROM pg_stat_replication;
   ```

### 自動バックアップの設定

```bash
# crontabに追加
sudo crontab -e

# 毎日午前2時にバックアップ
0 2 * * * pg_dump -h localhost -U postgresadmin postgresadmin_db > /backup/postgres_$(date +\%Y\%m\%d).sql
```

詳細な設定については、[PostgreSQL公式ドキュメント](https://www.postgresql.org/docs/)を参照してください。