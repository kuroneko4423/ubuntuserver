# Code-Server Docker Setup

Code-Serverは、ブラウザから利用できるVS Codeのサーバー版です。このDocker構成により、必要な開発ツールと拡張機能がプリインストールされた完全な開発環境を構築できます。

## 機能

### プリインストール済みのツール
- **Node.js 20 LTS** & npm最新版
- **Python 3** with pip
- **Java 17 (OpenJDK)** with Maven & Gradle
- **Git**
- **Flutter 3.24.5**
- **Android SDK Command Line Tools**
- **Google Chrome**
- **Claude Code** - Anthropic's official CLI for Claude

### プリインストール済みのPythonパッケージ
- Django
- FastAPI
- Streamlit
- Uvicorn
- LightGBM

### プリインストール済みのnpmパッケージ
- @google/gemini-cli
- @anthropic-ai/claude-code

### 自動インストールされるVS Code拡張機能

#### General
- shd101wyy.markdown-preview-enhanced - Markdown Preview Enhanced
- yzhang.markdown-all-in-one - Markdown All in One
- takumii.markdowntable - Markdown Table
- DavidAnson.vscode-markdownlint - Markdown Lint
- jebbs.plantuml - PlantUML
- redhat.vscode-yaml - YAML
- hediet.vscode-drawio - Draw.io Integration
- ms-vscode.vscode-json - JSON Language Features
- streetsidesoftware.code-spell-checker - Code Spell Checker
- ms-vscode.sublime-commands - Sublime Commands
- mechatroner.rainbow-csv - Rainbow CSV

#### Frontend
- george-alisson.html-preview-vscode - HTML Preview
- ms-vscode.vscode-typescript-next - TypeScript Next
- Vue.volar - Vue Language Features
- ms-vscode.vscode-html-language-features - HTML Language Features

#### Java
- vscjava.vscode-java-pack - Java Extension Pack
- vscjava.vscode-spring-boot-dashboard - Spring Boot Dashboard
- vscjava.vscode-spring-initializr - Spring Initializr

#### Python
- ms-python.python - Python
- ms-python.flake8 - Flake8
- ms-python.black-formatter - Black Formatter
- ms-python.django - Django
- ms-toolsai.jupyter - Jupyter
- ms-python.pylint - Pylint

#### AI Agent
- RooVeterinaryInc.roo-cline - Roo Cline

#### Database
- cweijan.vscode-database-client2 - Database Client

#### Mobile Development
- Dart-Code.dart-code - Dart
- Dart-Code.flutter - Flutter

## セットアップ手順

### 1. 環境変数の設定

`.env.example`をコピーして`.env`ファイルを作成します：

```bash
cp .env.example .env
```

`.env`ファイルを編集し、パスワードを設定します：

```env
PASSWORD=your_secure_password
SUDO_PASSWORD=your_sudo_password
```

### 2. Dockerイメージのビルドとコンテナの起動

```bash
docker-compose up -d --build
```

初回起動時は、イメージのビルドと拡張機能のインストールに時間がかかります（約10-15分）。
必要なディレクトリ（config、project、extensions）は自動的に作成されます。

### 3. アクセス

ブラウザで以下のURLにアクセスします：

```
http://localhost:8080
```

設定したパスワードでログインします。

## ディレクトリ構成

```
code-server/
├── Dockerfile           # カスタムDockerイメージ定義
├── docker-compose.yml   # Docker Compose設定
├── .env                 # 環境変数設定（.env.exampleからコピー）
├── .env.example         # 環境変数テンプレート
├── README.md           # ドキュメント
├── install-extensions.sh # VS Code拡張機能インストールスクリプト
├── startup.sh          # コンテナ起動スクリプト
├── config/             # Code-Serverの設定ファイル（自動作成）
├── project/            # プロジェクトファイル（作業ディレクトリ、自動作成）
└── extensions/         # VS Code拡張機能（自動作成）
```

## 環境変数

| 変数名 | 説明 | デフォルト値 |
|--------|------|--------------|
| PASSWORD | Code-Serverのログインパスワード | password |
| SUDO_PASSWORD | ターミナルでのsudoパスワード | password |
| PORT | 公開ポート番号 | 8080 |
| TZ | タイムゾーン | Asia/Tokyo |
| DEFAULT_WORKSPACE | デフォルトワークスペース | /home/coder/project |
| PUID | ユーザーID | 1000 |
| PGID | グループID | 1000 |

## コマンド

### 起動
```bash
docker-compose up -d
```

### 停止
```bash
docker-compose down
```

### ログ確認
```bash
docker-compose logs -f
```

### コンテナに入る
```bash
docker-compose exec code-server /bin/bash
```

## 注意事項

- プロダクション環境で使用する場合は、必ず強力なパスワードを設定してください
- HTTPSを使用することを推奨します（リバースプロキシなどで設定）
- `project`ディレクトリにプロジェクトファイルを配置すると、コンテナ内からアクセスできます
- 拡張機能は`extensions`ディレクトリに永続化されます
- Python環境は仮想環境（/home/coder/venv）で管理されています
- Dockerソケットがマウントされているため、コンテナ内からDockerコマンドが使用可能です

## トラブルシューティング

### パーミッションエラーが発生する場合

ホストのユーザーIDとグループIDを確認し、`.env`ファイルで設定：

```bash
id -u  # ユーザーIDを確認
id -g  # グループIDを確認
```

`.env`ファイルで設定：
```env
PUID=1000
PGID=1000
```

### ポートが使用中の場合

`.env`ファイルでポート番号を変更：

```env
PORT=8081
```

### ビルドエラーが発生する場合

キャッシュをクリアして再ビルド：

```bash
docker-compose build --no-cache
docker-compose up -d
```

### 拡張機能が正しくインストールされない場合

コンテナ内で手動インストール：

```bash
docker-compose exec code-server /home/coder/install-extensions.sh
```