# Nextcloud完全自動インストールスクリプト

Ubuntu環境でNextcloudを完全自動インストールするためのスクリプト集です。Apache2、MySQL、PHP8.1以上、SSL証明書（Let's Encrypt）を含む完全なLAMP環境を構築し、ファイアウォール設定、セキュリティ強化、外部アクセス対応、自動バックアップ機能を実装します。

## 📋 目次

- [特徴](#特徴)
- [前提条件](#前提条件)
- [インストール手順](#インストール手順)
- [スクリプト一覧](#スクリプト一覧)
- [設定ファイル](#設定ファイル)
- [使用方法](#使用方法)
- [トラブルシューティング](#トラブルシューティング)
- [セキュリティ](#セキュリティ)
- [バックアップ](#バックアップ)
- [監視](#監視)
- [FAQ](#faq)

## ✨ 特徴

- **完全自動インストール**: 一度の実行でNextcloudが完全に動作する状態まで構築
- **LAMP環境**: Apache2、MySQL/MariaDB、PHP8.1以上の最適化された環境
- **SSL対応**: Let's Encryptによる自動SSL証明書取得・更新
- **セキュリティ強化**: Fail2ban、UFW、システム堅牢化の実装
- **自動バックアップ**: データベースとファイルの定期バックアップ
- **監視・アラート**: システム状態の監視とメール/Slack通知
- **管理ツール**: 日常的な管理作業を簡単にするユーティリティ
- **本番環境対応**: エラーハンドリング、ログ出力、進捗表示

## 🔧 前提条件

### システム要件
- **OS**: Ubuntu 20.04 LTS / 22.04 LTS / 24.04 LTS
- **メモリ**: 最低2GB、推奨4GB以上
- **ストレージ**: 最低20GB、推奨50GB以上
- **ネットワーク**: インターネット接続必須

### 事前準備
- root権限またはsudo権限を持つユーザー
- ドメイン名の取得とDNS設定（SSL証明書取得のため）
- メール送信設定（アラート機能使用時）

## 🚀 インストール手順

### 1. スクリプトのダウンロード

```bash
# リポジトリのクローンまたはファイルのダウンロード
git clone <repository-url>
cd nextcloud
```

### 2. 設定ファイルの準備

```bash
# 設定ファイルのコピー
cp .env.example .env

# 設定ファイルの編集
nano .env
```

### 3. 必須設定項目の入力

`.env`ファイルで以下の項目を必ず設定してください：

```bash
# ドメイン設定
DOMAIN_NAME=your-domain.com
EMAIL=admin@your-domain.com

# データベース設定
DB_ROOT_PASSWORD=your_secure_root_password
DB_PASSWORD=your_secure_db_password

# Nextcloud管理者設定
NEXTCLOUD_ADMIN_PASSWORD=your_secure_admin_password
```

### 4. インストール実行

```bash
# スクリプトに実行権限を付与
chmod +x *.sh

# インストール実行（root権限必須）
sudo ./install-nextcloud.sh
```

### 5. インストール完了確認

インストール完了後、ブラウザで `https://your-domain.com` にアクセスして動作確認を行ってください。

## 📁 スクリプト一覧

### メインスクリプト

| ファイル名 | 説明 | 用途 |
|-----------|------|------|
| `install-nextcloud.sh` | メインインストールスクリプト | 初回インストール時に実行 |
| `manage-nextcloud.sh` | 管理用スクリプト | 日常的な管理作業 |
| `security-hardening.sh` | セキュリティ強化スクリプト | セキュリティ設定の追加強化 |
| `monitoring.sh` | 監視・アラートスクリプト | システム監視とアラート送信 |

### 設定ファイル

| ファイル名 | 説明 |
|-----------|------|
| `.env.example` | 設定ファイルのテンプレート |
| `.env` | 実際の設定ファイル（作成が必要） |

## ⚙️ 設定ファイル

### 主要設定項目

```bash
# ドメイン設定
DOMAIN_NAME=your-domain.com          # あなたのドメイン名
EMAIL=admin@your-domain.com          # 管理者メールアドレス

# データベース設定
DB_ROOT_PASSWORD=secure_password     # MySQLルートパスワード
DB_NAME=nextcloud                    # データベース名
DB_USER=nextcloud_user              # データベースユーザー名
DB_PASSWORD=secure_db_password       # データベースパスワード

# Nextcloud管理者設定
NEXTCLOUD_ADMIN_USER=admin           # 管理者ユーザー名
NEXTCLOUD_ADMIN_PASSWORD=secure_pass # 管理者パスワード

# SSL設定
USE_LETSENCRYPT=true                 # Let's Encrypt使用可否
LETSENCRYPT_EMAIL=admin@domain.com   # Let's Encrypt登録メール

# バックアップ設定
BACKUP_ENABLED=true                  # バックアップ機能有効化
BACKUP_RETENTION_DAYS=30             # バックアップ保持日数
BACKUP_TIME="02:00"                  # バックアップ実行時刻

# セキュリティ設定
FAIL2BAN_ENABLED=true               # Fail2ban有効化
UFW_ENABLED=true                    # UFWファイアウォール有効化

# PHP設定
PHP_VERSION=8.1                     # PHPバージョン
PHP_MEMORY_LIMIT=512M               # PHPメモリ制限
PHP_UPLOAD_MAX_FILESIZE=16G         # アップロード最大サイズ
PHP_POST_MAX_SIZE=16G               # POST最大サイズ
```

## 📖 使用方法

### インストール後の初期設定

```bash
# システム状態確認
sudo ./manage-nextcloud.sh status

# セキュリティ強化（推奨）
sudo ./security-hardening.sh --all

# 監視設定
sudo ./monitoring.sh monitor
```

### 日常的な管理作業

```bash
# メンテナンスモードの切り替え
sudo ./manage-nextcloud.sh maintenance on   # 有効化
sudo ./manage-nextcloud.sh maintenance off  # 無効化

# Nextcloudアップデート
sudo ./manage-nextcloud.sh update

# データベース最適化
sudo ./manage-nextcloud.sh optimize-db

# ファイルスキャン
sudo ./manage-nextcloud.sh scan-files

# バックアップ実行
sudo ./manage-nextcloud.sh backup

# ログ確認
sudo ./manage-nextcloud.sh logs 100
```

### ユーザー管理

```bash
# ユーザー一覧表示
sudo ./manage-nextcloud.sh user list

# ユーザー追加
sudo ./manage-nextcloud.sh user add username password123

# ユーザー削除
sudo ./manage-nextcloud.sh user delete username

# パスワードリセット
sudo ./manage-nextcloud.sh user reset-password username newpassword
```

### アプリ管理

```bash
# アプリ一覧表示
sudo ./manage-nextcloud.sh app list

# アプリ有効化
sudo ./manage-nextcloud.sh app enable calendar

# アプリ無効化
sudo ./manage-nextcloud.sh app disable calendar
```

## 🔍 トラブルシューティング

### よくある問題と解決方法

#### 1. インストールが途中で停止する

```bash
# ログファイルを確認
tail -f /var/log/nextcloud-install.log

# システムリソースを確認
free -h
df -h
```

#### 2. SSL証明書の取得に失敗する

```bash
# ドメインのDNS設定を確認
nslookup your-domain.com

# ファイアウォール設定を確認
sudo ufw status

# 手動でSSL証明書を取得
sudo certbot --apache -d your-domain.com
```

#### 3. データベース接続エラー

```bash
# MariaDBサービス状態確認
sudo systemctl status mariadb

# データベース接続テスト
mysql -u nextcloud_user -p nextcloud
```

#### 4. ファイルアップロードができない

```bash
# PHP設定確認
php -i | grep upload_max_filesize
php -i | grep post_max_size

# ディスク容量確認
df -h /var/nextcloud-data
```

### ログファイルの場所

| ログファイル | 場所 | 内容 |
|-------------|------|------|
| インストールログ | `/var/log/nextcloud-install.log` | インストール時のログ |
| Nextcloudログ | `/var/nextcloud-data/nextcloud.log` | Nextcloud動作ログ |
| Apacheエラーログ | `/var/log/apache2/nextcloud_error.log` | Webサーバーエラー |
| 監視ログ | `/var/log/nextcloud-monitor.log` | 監視スクリプトのログ |

## 🔒 セキュリティ

### 基本セキュリティ機能

- **ファイアウォール**: UFWによるポート制限
- **侵入検知**: Fail2banによる自動IP遮断
- **SSL/TLS**: Let's Encryptによる暗号化通信
- **セキュリティヘッダー**: XSS、CSRF対策
- **システム堅牢化**: カーネルパラメータ最適化

### 追加セキュリティ強化

```bash
# 全セキュリティ機能の有効化
sudo ./security-hardening.sh --all

# 個別機能の有効化
sudo ./security-hardening.sh --ssh        # SSH強化
sudo ./security-hardening.sh --firewall   # ファイアウォール詳細化
sudo ./security-hardening.sh --fail2ban   # Fail2ban詳細化
sudo ./security-hardening.sh --system     # システム堅牢化
sudo ./security-hardening.sh --apache     # Apache強化
sudo ./security-hardening.sh --php        # PHP強化
sudo ./security-hardening.sh --mysql      # MySQL強化
```

### セキュリティ監視

```bash
# セキュリティ状態確認
sudo ./monitoring.sh security

# Fail2ban状態確認
sudo fail2ban-client status

# ファイアウォール状態確認
sudo ufw status verbose
```

## 💾 バックアップ

### 自動バックアップ

インストール時に自動バックアップが設定されます：

- **実行時刻**: 毎日午前2時（設定変更可能）
- **保存場所**: `/var/backups/nextcloud/`
- **保持期間**: 30日間（設定変更可能）
- **バックアップ内容**:
  - データベース（SQL形式）
  - Nextcloudファイル
  - ユーザーデータ

### 手動バックアップ

```bash
# 即座にバックアップ実行
sudo ./manage-nextcloud.sh backup

# バックアップ状態確認
sudo ./monitoring.sh backup
```

### バックアップからの復元

```bash
# データベース復元
mysql -u nextcloud_user -p nextcloud < /var/backups/nextcloud/nextcloud_db_YYYYMMDD_HHMMSS.sql

# ファイル復元
tar -xzf /var/backups/nextcloud/nextcloud_files_YYYYMMDD_HHMMSS.tar.gz -C /var/www/
tar -xzf /var/backups/nextcloud/nextcloud_data_YYYYMMDD_HHMMSS.tar.gz -C /var/

# 権限修正
chown -R www-data:www-data /var/www/nextcloud /var/nextcloud-data
```

## 📊 監視

### 監視機能

システムの健全性を24時間監視：

- **システムリソース**: CPU、メモリ、ディスク使用率
- **サービス状態**: Apache、MySQL、Fail2banの動作状況
- **Nextcloud状態**: アプリケーションの動作確認
- **SSL証明書**: 有効期限の監視
- **ログ監視**: エラーログの異常検知
- **バックアップ状態**: バックアップの実行確認
- **セキュリティ**: 不正アクセスの検知
- **外部接続**: インターネット接続とDNS解決

### 監視の実行

```bash
# 完全監視実行
sudo ./monitoring.sh monitor

# 個別監視項目
sudo ./monitoring.sh system        # システムリソース
sudo ./monitoring.sh services      # サービス状態
sudo ./monitoring.sh nextcloud     # Nextcloud状態
sudo ./monitoring.sh ssl           # SSL証明書
sudo ./monitoring.sh logs          # ログ監視
sudo ./monitoring.sh backup        # バックアップ状態
sudo ./monitoring.sh security      # セキュリティ
sudo ./monitoring.sh connectivity  # 外部接続

# 監視レポート生成
sudo ./monitoring.sh report
```

### アラート設定

#### メールアラート

`.env`ファイルでメールアドレスを設定：

```bash
EMAIL=admin@your-domain.com
```

#### Slackアラート

`.env`ファイルでSlack Webhook URLを設定：

```bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

### 定期監視の設定

```bash
# Cronジョブの設定例
sudo crontab -e

# 5分ごとの監視
*/5 * * * * /path/to/nextcloud/monitoring.sh monitor

# 日次レポート
0 6 * * * /path/to/nextcloud/monitoring.sh report | mail -s 'Nextcloud Daily Report' admin@example.com
```

## ❓ FAQ

### Q: インストールにはどのくらい時間がかかりますか？

A: 通常15-30分程度です。サーバーのスペックとインターネット接続速度によって変動します。

### Q: 既存のApacheやMySQLがある場合はどうなりますか？

A: 既存の設定は保持され、Nextcloud用の設定が追加されます。ただし、競合する可能性があるため、クリーンな環境での実行を推奨します。

### Q: ドメイン名なしでもインストールできますか？

A: 可能ですが、SSL証明書の自動取得ができません。`.env`ファイルで`USE_LETSENCRYPT=false`に設定してください。

### Q: バックアップの暗号化は可能ですか？

A: 現在のスクリプトでは暗号化機能は含まれていません。必要に応じて、バックアップスクリプトをカスタマイズしてください。

### Q: 複数のドメインでアクセスしたい場合は？

A: `.env`ファイルの`TRUSTED_DOMAINS`に追加のドメインを設定し、インストール後にNextcloudの設定を更新してください。

### Q: アップデート時の注意点は？

A: アップデート前に必ずバックアップを取得し、メンテナンスモードを有効にしてから実行してください。

### Q: パフォーマンスを向上させるには？

A: 以下の設定を検討してください：
- Redis/Memcachedの導入
- PHP-FPMの使用
- データベースの最適化
- SSDストレージの使用

### Q: 商用利用は可能ですか？

A: Nextcloud自体はオープンソースソフトウェアですが、商用利用時は適切なライセンスとサポートを検討してください。

## 📞 サポート

### 問題報告

問題が発生した場合は、以下の情報を含めて報告してください：

1. Ubuntu バージョン
2. エラーメッセージ
3. ログファイルの内容
4. 実行したコマンド
5. システム環境（メモリ、ディスク容量など）

### ログの収集

```bash
# システム情報の収集
uname -a > system-info.txt
free -h >> system-info.txt
df -h >> system-info.txt
systemctl status apache2 mariadb fail2ban >> system-info.txt

# ログファイルの収集
tar -czf nextcloud-logs.tar.gz /var/log/nextcloud-*.log /var/log/apache2/nextcloud_*.log
```

## 📄 ライセンス

このスクリプト集はMITライセンスの下で公開されています。

## 🤝 貢献

プルリクエストやイシューの報告を歓迎します。貢献する前に、既存のイシューを確認してください。

---

**注意**: このスクリプトは本番環境での使用を想定していますが、重要なデータを扱う前に必ずテスト環境で動作確認を行ってください。