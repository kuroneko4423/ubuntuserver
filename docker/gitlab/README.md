# GitLab Docker Setup

このディレクトリには、Docker Composeを使用してGitLab CEをセットアップするための設定ファイルが含まれています。

## 構成

このセットアップには以下のサービスが含まれます：

- **GitLab CE**: GitLabのコアアプリケーション
- **PostgreSQL**: GitLabのデータベース
- **Redis**: キャッシュとセッション管理

## セットアップ手順

### 1. 環境変数の設定

`.env.example`ファイルを`.env`にコピーして、必要な値を設定します：

```bash
cp .env.example .env
```

`.env`ファイルを編集して、以下の値を変更してください：

- `GITLAB_HOSTNAME`: GitLabのホスト名
- `GITLAB_EXTERNAL_URL`: GitLabの外部URL
- `GITLAB_HTTP_PORT`: HTTPポート（デフォルト: 8929）
- `GITLAB_HTTPS_PORT`: HTTPSポート（デフォルト: 8943）
- `GITLAB_SSH_PORT`: SSHポート（デフォルト: 2224）
- `GITLAB_POSTGRES_PASSWORD`: PostgreSQLのパスワード（必ず変更）
- `GITLAB_REDIS_PASSWORD`: Redisのパスワード（必ず変更）

### 2. GitLabの起動

```bash
docker-compose up -d
```

### 3. 初回セットアップ

GitLabの起動には数分かかります。起動状態は以下のコマンドで確認できます：

```bash
docker-compose logs -f gitlab
```

GitLabが完全に起動したら、ブラウザで`http://localhost:8929`（または設定したポート）にアクセスします。

### 4. 初回ログイン

初回アクセス時に、rootユーザーのパスワードを設定します。
または、以下のコマンドで自動生成されたパスワードを確認できます：

```bash
docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

**注意**: このパスワードは初回設定から24時間後に削除されます。

ユーザー名: `root`

### 5. 停止と再起動

停止：
```bash
docker-compose down
```

再起動：
```bash
docker-compose restart
```

データを含めて完全に削除：
```bash
docker-compose down -v
```

## ポート設定

デフォルトのポート設定：

- HTTP: 8929
- HTTPS: 8943
- SSH: 2224

これらのポートは`.env`ファイルで変更できます。

## データの永続化

以下のDockerボリュームにデータが保存されます：

- `gitlab_config`: GitLabの設定ファイル
- `gitlab_logs`: GitLabのログファイル
- `gitlab_data`: GitLabのアプリケーションデータ
- `gitlab_postgres_data`: PostgreSQLのデータ
- `gitlab_redis_data`: Redisのデータ

## トラブルシューティング

### GitLabが起動しない

ログを確認：
```bash
docker-compose logs gitlab
```

### パスワードを忘れた場合

rootパスワードをリセット：
```bash
docker exec -it gitlab gitlab-rake "gitlab:password:reset[root]"
```

### メモリ不足

GitLabは最低でも4GB以上のRAMを推奨します。`docker-compose.yml`の`shm_size`を調整してください。

## セキュリティ

本番環境で使用する場合は、以下を必ず実施してください：

1. すべてのデフォルトパスワードを変更
2. HTTPSを有効化
3. ファイアウォールの設定
4. 定期的なバックアップ
5. GitLabのバージョンを定期的に更新

## 参考リンク

- [GitLab Documentation](https://docs.gitlab.com/)
- [GitLab Docker Images](https://docs.gitlab.com/ee/install/docker.html)
