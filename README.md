# Ubuntu Server ソフトウェアインストールスクリプト集

このリポジトリには、Ubuntu Server環境に各種ソフトウェアを自動インストールするためのシェルスクリプトが含まれています。各ソフトウェアごとにディレクトリが分かれており、それぞれに詳細なドキュメントとインストールスクリプトが用意されています。

## 📁 ディレクトリ構成

```
ubuntuserver/
├── README.md                    # このファイル
├── gitlab/                      # GitLab関連
│   ├── README.md
│   └── install_gitlab.sh
├── nextcloud/                   # Nextcloud関連
│   ├── README.md
│   └── install_nextcloud.sh
├── jupyterhub/                  # JupyterHub関連
│   ├── README.md
│   └── install_jupyterhub.sh
└── postgresql/                  # PostgreSQL関連
    ├── README.md
    └── install_postgresql.sh
```

## 🚀 利用可能なソフトウェア

### [GitLab](gitlab/)
**バージョン管理・CI/CDプラットフォーム**
- GitLab Community Edition
- SSL証明書自動取得
- Nginxリバースプロキシ
- 初期管理者設定

### [Nextcloud](nextcloud/)
**クラウドストレージ・コラボレーションプラットフォーム**
- 最新安定版Nextcloud
- Apache Webサーバー
- MariaDBデータベース
- SSL証明書自動取得
- Apache仮想ホスト自動設定

### [JupyterHub](jupyterhub/)
**マルチユーザーJupyter環境**
- JupyterHub 3.0.0
- JupyterLab統合
- PAM認証
- Nginxリバースプロキシ
- SSL証明書自動取得

### [PostgreSQL](postgresql/)
**高性能リレーショナルデータベース**
- 最新版PostgreSQL
- 外部接続設定
- 管理者ユーザー作成
- セキュリティ設定最適化

## 🛠️ 共通の前提条件

すべてのスクリプトは以下の環境で動作します：

- **OS**: Ubuntu 20.04 LTS または 22.04 LTS
- **権限**: root権限でのアクセス
- **ネットワーク**: インターネット接続
- **ドメイン**: SSL証明書が必要なソフトウェアではドメイン名が必要

## 📋 基本的な使用方法

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd ubuntuserver
```

### 2. 対象ソフトウェアのディレクトリに移動

```bash
cd <software-name>/
```

### 3. READMEを確認

```bash
cat README.md
```

### 4. スクリプトの設定変更

```bash
nano install_<software-name>.sh
```

**重要**: 各スクリプト内の以下の変数を必ず変更してください：
- `DOMAIN`: 実際のドメイン名
- `EMAIL`: Let's Encrypt登録用メールアドレス
- パスワード関連の変数

### 5. スクリプトの実行

```bash
chmod +x install_<software-name>.sh
sudo ./install_<software-name>.sh
```

## ⚠️ 重要な注意事項

### セキュリティ

1. **パスワードの変更**
   - すべてのデフォルトパスワードを強力なものに変更してください
   - パスワードはスクリプト実行前に変更することを強く推奨します

2. **ファイアウォール設定**
   - 必要なポートのみを開放してください
   - 本番環境では適切なIP制限を設定してください

3. **SSL証明書**
   - Let's Encryptを使用する場合、ドメインのDNSレコードが正しく設定されている必要があります
   - 証明書の自動更新設定を確認してください

### システム要件

| ソフトウェア | 最小RAM | 推奨RAM | ディスク容量 |
|-------------|---------|---------|-------------|
| GitLab      | 4GB     | 8GB     | 20GB        |
| Nextcloud   | 2GB     | 4GB     | 10GB        |
| JupyterHub  | 2GB     | 4GB     | 10GB        |
| PostgreSQL  | 1GB     | 2GB     | 5GB         |

## 🔧 トラブルシューティング

### 共通の問題

1. **DNS設定の問題**
   ```bash
   # ドメインの解決確認
   nslookup your-domain.com
   dig your-domain.com
   ```

2. **ファイアウォールの問題**
   ```bash
   # ファイアウォール状態確認
   sudo ufw status
   
   # 必要なポートの開放
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

3. **サービスの状態確認**
   ```bash
   # サービス状態確認
   sudo systemctl status <service-name>
   
   # ログ確認
   sudo journalctl -u <service-name> -f
   ```

### ログファイルの場所

- **システムログ**: `/var/log/syslog`
- **Apache**: `/var/log/apache2/`
- **Nginx**: `/var/log/nginx/`
- **各ソフトウェア固有のログ**: 各READMEを参照

## 🔄 アップデートとメンテナンス

### システムアップデート

```bash
# システム全体のアップデート
sudo apt update && sudo apt upgrade -y

# 再起動が必要な場合
sudo reboot
```

### SSL証明書の更新

```bash
# Let's Encrypt証明書の更新
sudo certbot renew

# 自動更新の設定確認
sudo systemctl status certbot.timer
```

### バックアップ

各ソフトウェアのREADMEでバックアップ方法を確認してください：
- データベースのバックアップ
- 設定ファイルのバックアップ
- ユーザーデータのバックアップ

## 📚 詳細ドキュメント

各ソフトウェアの詳細な設定、カスタマイズ、トラブルシューティングについては、対応するディレクトリ内のREADME.mdを参照してください：

- [GitLab詳細ドキュメント](gitlab/README.md)
- [Nextcloud詳細ドキュメント](nextcloud/README.md)
- [JupyterHub詳細ドキュメント](jupyterhub/README.md)
- [PostgreSQL詳細ドキュメント](postgresql/README.md)

## 🤝 サポートとコントリビューション

### 問題報告

問題が発生した場合は、以下の情報を含めて報告してください：
- Ubuntu のバージョン
- 実行したスクリプト
- エラーメッセージ
- 関連するログファイル

### 改善提案

スクリプトの改善提案や新しいソフトウェアの追加要望は歓迎します。

## 📄 ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。

---

**⚡ クイックスタート例**

GitLabを素早くインストールしたい場合：

```bash
cd gitlab/
nano install_gitlab.sh  # DOMAIN と EMAIL を変更
chmod +x install_gitlab.sh
sudo ./install_gitlab.sh
```

詳細な手順は各ソフトウェアのREADMEを必ず確認してください。