# JupyterHub インストールスクリプト

このディレクトリには、Ubuntu ServerにJupyterHubをインストールするためのスクリプトが含まれています。

## ファイル構成

- [`install_jupyterhub.sh`](install_jupyterhub.sh) - JupyterHubのインストールスクリプト

## 機能

- JupyterHub 3.0.0の自動インストール
- JupyterLabの統合
- Nginxリバースプロキシの設定
- SSL証明書の自動取得（Let's Encrypt）
- Systemdサービスの設定
- PAM認証の設定
- ファイアウォールの設定

## 使用方法

### 前提条件

- Ubuntu 20.04 LTS または 22.04 LTS
- root権限でのアクセス
- インターネット接続
- ドメイン名の設定（DNSレコードが正しく設定されていること）
- 最低2GB以上のRAM推奨

### インストール手順

1. スクリプトを実行可能にする：
   ```bash
   chmod +x install_jupyterhub.sh
   ```

2. スクリプト内の変数を編集：
   ```bash
   nano install_jupyterhub.sh
   ```
   - `JUPYTERHUB_VERSION`: 必要に応じてバージョンを変更
   - `ADMIN_USER`: 管理者ユーザー名を変更
   - `DOMAIN`: 実際のドメイン名に変更
   - `LETSENCRYPT_EMAIL`: Let's Encrypt登録用のメールアドレスに変更

3. スクリプトを実行：
   ```bash
   sudo ./install_jupyterhub.sh
   ```

### インストール後の設定

1. ブラウザで `https://your-domain.com` にアクセス
2. システムユーザーでログイン（PAM認証）
3. 管理者ユーザーでログインして設定を確認

## 設定ファイル

### JupyterHub設定

設定ファイル: `/etc/jupyterhub/jupyterhub_config.py`

**主要設定:**
- ポート: 8000
- 認証方式: PAM認証
- スポーナー: SystemUserSpawner
- デフォルトURL: JupyterLab

### Systemdサービス

サービスファイル: `/etc/systemd/system/jupyterhub.service`

**サービス管理コマンド:**
```bash
# サービス状態確認
sudo systemctl status jupyterhub

# サービス開始
sudo systemctl start jupyterhub

# サービス停止
sudo systemctl stop jupyterhub

# サービス再起動
sudo systemctl restart jupyterhub

# ログ確認
sudo journalctl -u jupyterhub -f
```

### Nginx設定

設定ファイル: `/etc/nginx/sites-available/jupyterhub`

**機能:**
- HTTPからHTTPSへのリダイレクト
- SSL/TLS設定の最適化
- リバースプロキシ設定

## ユーザー管理

### 新しいユーザーの追加

```bash
# 新しいユーザーを作成
sudo adduser username

# ユーザーをjupyterhubグループに追加（オプション）
sudo usermod -a -G jupyterhub username
```

### 管理者権限の付与

JupyterHub設定ファイルを編集：
```python
c.Authenticator.admin_users = {'admin_user1', 'admin_user2'}
```

設定変更後はサービスを再起動：
```bash
sudo systemctl restart jupyterhub
```

## セキュリティ設定

### 推奨設定

1. **強力なパスワードポリシー**
   ```bash
   # パスワード複雑性の設定
   sudo apt install libpam-pwquality
   ```

2. **ファイアウォール設定**
   ```bash
   # 必要なポートのみ開放
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

3. **定期的なアップデート**
   ```bash
   # システムアップデート
   sudo apt update && sudo apt upgrade

   # JupyterHub仮想環境でのアップデート
   source /opt/jupyterhub/bin/activate
   pip install --upgrade jupyterhub jupyterlab
   ```

## カスタマイズ

### 追加のPythonパッケージのインストール

システム全体にインストール：
```bash
# 仮想環境をアクティベート
source /opt/jupyterhub/bin/activate

# パッケージをインストール
pip install numpy pandas matplotlib scikit-learn
```

### JupyterLab拡張機能

```bash
# 仮想環境をアクティベート
source /opt/jupyterhub/bin/activate

# 拡張機能をインストール
pip install jupyterlab-git
jupyter labextension install @jupyterlab/git
```

## トラブルシューティング

### よくある問題

1. **JupyterHubが起動しない場合**
   ```bash
   # ログを確認
   sudo journalctl -u jupyterhub -n 50

   # 設定ファイルの構文チェック
   source /opt/jupyterhub/bin/activate
   jupyterhub -f /etc/jupyterhub/jupyterhub_config.py --dry-run
   ```

2. **SSL証明書の問題**
   ```bash
   # 証明書の更新
   sudo certbot renew

   # Nginx設定のテスト
   sudo nginx -t
   ```

3. **ユーザーがログインできない場合**
   - PAM認証の設定確認
   - ユーザーアカウントの存在確認
   - パスワードの確認

4. **メモリ不足エラー**
   ```bash
   # スワップファイルの作成
   sudo fallocate -l 2G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

### ログファイルの場所

- JupyterHub: `sudo journalctl -u jupyterhub`
- Nginx: `/var/log/nginx/error.log`
- システム: `/var/log/syslog`

## パフォーマンス最適化

### 推奨設定

1. **リソース制限の設定**
   ```python
   # jupyterhub_config.py に追加
   c.Spawner.mem_limit = '1G'
   c.Spawner.cpu_limit = 1.0
   ```

2. **アイドルタイムアウトの設定**
   ```python
   c.JupyterHub.services = [
       {
           'name': 'idle-culler',
           'command': [
               sys.executable,
               '-m', 'jupyterhub_idle_culler',
               '--timeout=3600'
           ],
       }
   ]
   ```

詳細な設定については、[JupyterHub公式ドキュメント](https://jupyterhub.readthedocs.io/)を参照してください。