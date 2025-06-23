# GitLab インストールスクリプト

このディレクトリには、Ubuntu ServerにGitLabをインストールするためのスクリプトが含まれています。

## ファイル構成

- [`install_gitlab.sh`](install_gitlab.sh) - GitLab Community Editionのインストールスクリプト

## 機能

- GitLab Community Editionの自動インストール
- SSL証明書の自動取得（Let's Encrypt）
- Nginxリバースプロキシの設定
- ファイアウォールの設定
- 初期管理者アカウントの設定

## 使用方法

### 前提条件

- Ubuntu 20.04 LTS または 22.04 LTS
- root権限でのアクセス
- インターネット接続
- ドメイン名の設定（DNSレコードが正しく設定されていること）

### インストール手順

1. スクリプトを実行可能にする：
   ```bash
   chmod +x install_gitlab.sh
   ```

2. スクリプト内の変数を編集：
   ```bash
   nano install_gitlab.sh
   ```
   - `DOMAIN`: 実際のドメイン名に変更
   - `EMAIL`: Let's Encrypt登録用のメールアドレスに変更

3. スクリプトを実行：
   ```bash
   sudo ./install_gitlab.sh
   ```

### インストール後の設定

1. ブラウザで `https://your-domain.com` にアクセス
2. 初期ログイン情報：
   - ユーザー名: `root`
   - パスワード: スクリプト実行時に表示されたパスワード
3. 初回ログイン後、パスワードを変更してください

## 注意事項

- スクリプト実行前に、ドメインのDNSレコードが正しく設定されていることを確認してください
- SSL証明書の取得にはドメインが必要です
- 初期パスワードは `/etc/gitlab/initial_root_password` に保存されます（24時間後に自動削除）

## トラブルシューティング

### よくある問題

1. **SSL証明書の取得に失敗する場合**
   - ドメインのDNSレコードが正しく設定されているか確認
   - ファイアウォールでポート80, 443が開いているか確認

2. **GitLabにアクセスできない場合**
   - サービスの状態を確認: `sudo gitlab-ctl status`
   - ログを確認: `sudo gitlab-ctl tail`

3. **メモリ不足エラーが発生する場合**
   - 最低4GB以上のRAMが推奨されます
   - スワップファイルの設定を検討してください