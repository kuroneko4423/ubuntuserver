# Redmineインストールスクリプト

このディレクトリには、UbuntuにRedmineをPostgreSQLデータベースでインストールし、外部アクセスを設定するシェルスクリプトが含まれています。

## 前提条件

- Ubuntu 20.04 LTS以降
- rootまたはsudoアクセス権限
- 最低2GBのRAM
- 10GBの空きディスク容量

## インストール方法

1. スクリプトをUbuntuサーバーにコピー:
   ```bash
   scp install_redmine.sh user@your-server:/tmp/
   ```

2. スクリプトに実行権限を付与:
   ```bash
   chmod +x /tmp/install_redmine.sh
   ```

3. スクリプトを実行:
   ```bash
   cd /tmp
   ./install_redmine.sh
   ```

## スクリプトの処理内容

1. **システム更新**: すべてのシステムパッケージを更新
2. **依存関係**: 必要なパッケージ（Ruby、PostgreSQL、Apacheなど）をインストール
3. **Rubyインストール**: rbenvを使用してRubyをインストール（バージョン管理が容易）
4. **データベース設定**: Redmine用のPostgreSQLデータベースとユーザーを作成
5. **Redmineインストール**: Redmine 5.1（安定版）をダウンロードして設定
6. **Webサーバー**: ApacheとPassengerモジュールを設定
7. **ファイアウォール**: Web アクセスに必要なポートを開放
8. **権限設定**: セキュリティのため適切なファイル権限を設定

## インストール後の設定

インストール完了後：

1. `http://サーバーのIPアドレス/` でRedmineにアクセス
2. デフォルトの認証情報でログイン:
   - ユーザー名: `admin`
   - パスワード: `admin`
3. **重要**: 管理者パスワードをすぐに変更してください！

## セキュリティに関する注意事項

1. **データベースパスワード**: スクリプトはデフォルトパスワードを使用しています。本番環境では変更してください:
   - PostgreSQLでパスワードを更新
   - `/opt/redmine/config/database.yml` を更新

2. **HTTPS設定**: 本番環境ではHTTPSを有効にしてください:
   ```bash
   sudo apt-get install certbot python3-certbot-apache
   sudo certbot --apache -d your-domain.com
   ```

3. **ファイアウォール**: 必要なポートのみを開放:
   - ポート80（HTTP）
   - ポート443（HTTPS）
   - ポート22（SSH）

## トラブルシューティング

### Apacheの状態確認
```bash
sudo systemctl status apache2
```

### Redmineのログ確認
```bash
sudo tail -f /var/log/apache2/redmine_error.log
```

### データベース接続テスト
```bash
psql -U redmine -h localhost -d redmine
```

### サービスの再起動
```bash
sudo systemctl restart apache2
sudo systemctl restart postgresql
```

## カスタマイズ

Redmineをカスタマイズするには：

1. 設定ファイル: `/opt/redmine/config/configuration.yml`
2. メール設定: SMTP設定を追加
3. プラグイン: `/opt/redmine/plugins/` にインストール
4. テーマ: `/opt/redmine/public/themes/` にインストール

## バックアップ

定期的なバックアップに含めるべき項目：
- データベース: `pg_dump -U redmine -h localhost redmine > backup.sql`
- ファイル: `/opt/redmine/files/`
- 設定: `/opt/redmine/config/`