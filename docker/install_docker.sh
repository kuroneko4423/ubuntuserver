#!/bin/bash

# Ubuntu Docker & Docker Compose インストールスクリプト
# 対応バージョン: Ubuntu 20.04, 22.04, 24.04

set -e  # エラー時に停止

echo "🐳 Ubuntu Docker & Docker Compose インストールスクリプト"
echo "=================================================="

# 管理者権限チェック
if [[ $EUID -eq 0 ]]; then
   echo "❌ このスクリプトはrootユーザーで実行しないでください"
   echo "   sudo権限のある一般ユーザーで実行してください"
   exit 1
fi

# sudoコマンドの確認
if ! command -v sudo &> /dev/null; then
    echo "❌ sudoコマンドが見つかりません"
    exit 1
fi

echo "📋 システム情報:"
echo "   OS: $(lsb_release -d | cut -f2)"
echo "   カーネル: $(uname -r)"
echo "   アーキテクチャ: $(uname -m)"
echo ""

# 既存のDockerがインストールされているかチェック
if command -v docker &> /dev/null; then
    echo "⚠️  Dockerが既にインストールされています"
    docker --version
    read -p "既存のDockerを削除して再インストールしますか？ (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  既存のDockerパッケージを削除中..."
        sudo apt-get remove -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
    else
        echo "✅ インストールをスキップします"
        exit 0
    fi
fi

echo "🔄 パッケージリストを更新中..."
sudo apt-get update

echo "📦 必要なパッケージをインストール中..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common

echo "🔑 DockerのGPGキーを追加中..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "📋 Dockerリポジトリを追加中..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "🔄 パッケージリストを再更新中..."
sudo apt-get update

echo "🐳 Docker Engine, CLI, Containerd, Docker Composeをインストール中..."
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo "👥 現在のユーザーをdockerグループに追加中..."
sudo usermod -aG docker $USER

echo "🚀 Dockerサービスを開始・有効化中..."
sudo systemctl start docker
sudo systemctl enable docker

echo "✅ インストール完了確認..."
sudo docker --version
sudo docker compose version

echo ""
echo "🎉 インストールが完了しました！"
echo ""
echo "📝 重要な注意事項:"
echo "   1. dockerグループの変更を反映するため、以下のいずれかを実行してください:"
echo "      - ログアウト/ログインし直す"
echo "      - 'newgrp docker' コマンドを実行"
echo "      - システムを再起動"
echo ""
echo "   2. インストール確認コマンド:"
echo "      docker --version"
echo "      docker compose version"
echo "      docker run hello-world"
echo ""
echo "🔧 使用例:"
echo "   # Dockerコンテナ実行"
echo "   docker run hello-world"
echo ""
echo "   # Docker Compose使用"
echo "   docker compose up -d"
echo ""
echo "📚 詳細なドキュメント: https://docs.docker.com/"