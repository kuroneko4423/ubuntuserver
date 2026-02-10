# JupyterHub Docker Setup

JupyterHubをDockerで実行するための設定です。

## 概要

このセットアップでは、JupyterHubをDockerコンテナとして実行し、各ユーザーのJupyterノートブックも個別のDockerコンテナとして起動します。

## ファイル構成

- `docker-compose.yml`: Docker Composeの設定ファイル
- `jupyterhub_config.py`: JupyterHubの設定ファイル
- `Dockerfile`: カスタムJupyterHubイメージのビルド設定

## 機能

- DockerSpawnerを使用した各ユーザーのコンテナベースのノートブック環境
- PAM認証（デフォルト）
- アイドル状態のノートブックの自動停止機能
- ユーザーごとの永続ボリューム

## 起動方法

```bash
# イメージのビルドと起動
docker-compose up -d --build

# ログの確認
docker-compose logs -f jupyterhub
```

## アクセス

ブラウザで `http://localhost:8000` にアクセスしてください。

## 管理者ユーザー

管理者ユーザー（`admin`）は自動的に作成されます。

### パスワードの設定

1. `.env`ファイルを作成（`.env.example`をコピー）：
```bash
cp .env.example .env
```

2. `.env`ファイル内の`ADMIN_PASSWORD`を安全なパスワードに変更：
```
ADMIN_PASSWORD=your_secure_password_here
```

3. 環境変数を設定しない場合、デフォルトパスワードは `admin123` になります。

### ログイン

- ユーザー名: `admin`
- パスワード: `.env`で設定した値（デフォルト: `admin123`）

## SSL/HTTPS設定

HTTPS を有効にする場合は、`jupyterhub_config.py` の最後のSSL設定のコメントを解除し、証明書を配置してください。

## カスタマイズ

### 使用するノートブックイメージの変更

`jupyterhub_config.py` の以下の行を編集：
```python
c.DockerSpawner.image = 'jupyter/scipy-notebook:latest'
```

利用可能なイメージ：
- `jupyter/base-notebook`: 最小構成
- `jupyter/scipy-notebook`: 科学計算用（NumPy, Pandas, Matplotlib等）
- `jupyter/tensorflow-notebook`: TensorFlow環境
- `jupyter/datascience-notebook`: データサイエンス用フルセット

### アイドルタイムアウトの調整

`jupyterhub_config.py` のidle-cullerサービスの設定を変更：
```python
'--timeout=3600',  # アイドルタイムアウト（秒）
'--max-age=7200',  # 最大稼働時間（秒）
```

## トラブルシューティング

### コンテナが起動しない場合

```bash
# ログを確認
docker-compose logs jupyterhub

# Dockerソケットの権限を確認
ls -la /var/run/docker.sock
```

### ユーザーのノートブックが起動しない場合

```bash
# DockerSpawnerのデバッグログを確認
docker-compose logs -f jupyterhub | grep spawner
```