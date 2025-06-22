#!/bin/bash

# Nextcloudインストールスクリプト セットアップ
# 必要な権限設定と初期チェックを行います

set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 関数定義
error_exit() {
    echo -e "${RED}エラー: $1${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# バナー表示
show_banner() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║    Nextcloud完全自動インストールスクリプト セットアップ        ║
║                                                               ║
║    Ubuntu環境でNextcloudを完全自動インストール                 ║
║    LAMP環境 + SSL + セキュリティ + バックアップ + 監視         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# システム要件チェック
check_system_requirements() {
    info "システム要件をチェックしています..."
    
    # OS チェック
    if ! grep -q "Ubuntu" /etc/os-release; then
        error_exit "このスクリプトはUbuntu専用です"
    fi
    
    local version=$(lsb_release -rs)
    if [[ ! "$version" =~ ^(20\.04|22\.04|24\.04)$ ]]; then
        warning "サポートされていないUbuntuバージョン: $version"
        warning "Ubuntu 20.04, 22.04, 24.04での動作を推奨します"
    else
        success "Ubuntu $version を検出しました"
    fi
    
    # メモリチェック
    local total_mem=$(free -m | awk 'NR==2{print $2}')
    if [ "$total_mem" -lt 2048 ]; then
        warning "メモリが不足している可能性があります: ${total_mem}MB (推奨: 4GB以上)"
    else
        success "メモリ: ${total_mem}MB"
    fi
    
    # ディスク容量チェック
    local available_space=$(df / | awk 'NR==2 {print $4}')
    local available_gb=$((available_space / 1024 / 1024))
    if [ "$available_gb" -lt 20 ]; then
        warning "ディスク容量が不足している可能性があります: ${available_gb}GB (推奨: 50GB以上)"
    else
        success "利用可能ディスク容量: ${available_gb}GB"
    fi
    
    # インターネット接続チェック
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        success "インターネット接続: OK"
    else
        error_exit "インターネット接続が必要です"
    fi
}

# 権限チェック
check_permissions() {
    info "権限をチェックしています..."
    
    if [ "$EUID" -eq 0 ]; then
        warning "rootユーザーで実行されています"
        warning "セキュリティのため、sudo権限を持つ一般ユーザーでの実行を推奨します"
    else
        if sudo -n true 2>/dev/null; then
            success "sudo権限: OK"
        else
            error_exit "sudo権限が必要です"
        fi
    fi
}

# ファイル存在チェック
check_files() {
    info "必要なファイルをチェックしています..."
    
    local required_files=(
        "install-nextcloud.sh"
        "manage-nextcloud.sh"
        "security-hardening.sh"
        "monitoring.sh"
        ".env.example"
        "README.md"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ -f "$SCRIPT_DIR/$file" ]; then
            success "ファイル存在確認: $file"
        else
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        error_exit "必要なファイルが見つかりません: ${missing_files[*]}"
    fi
}

# 実行権限設定
set_permissions() {
    info "実行権限を設定しています..."
    
    local script_files=(
        "install-nextcloud.sh"
        "manage-nextcloud.sh"
        "security-hardening.sh"
        "monitoring.sh"
        "setup.sh"
    )
    
    for script in "${script_files[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            chmod +x "$SCRIPT_DIR/$script"
            success "実行権限設定: $script"
        fi
    done
}

# 設定ファイルの準備
prepare_config() {
    info "設定ファイルを準備しています..."
    
    local env_file="$SCRIPT_DIR/.env"
    local env_example="$SCRIPT_DIR/.env.example"
    
    if [ ! -f "$env_file" ]; then
        if [ -f "$env_example" ]; then
            cp "$env_example" "$env_file"
            success ".envファイルを作成しました"
            warning "インストール前に .env ファイルを編集してください"
        else
            error_exit ".env.example ファイルが見つかりません"
        fi
    else
        success ".envファイルは既に存在します"
    fi
    
    # 設定ファイルの権限設定
    chmod 600 "$env_file"
    success ".envファイルの権限を設定しました (600)"
}

# 依存パッケージの事前チェック
check_dependencies() {
    info "依存パッケージをチェックしています..."
    
    local required_commands=(
        "curl"
        "wget"
        "unzip"
    )
    
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            success "コマンド確認: $cmd"
        else
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        warning "以下のパッケージがインストールされていません: ${missing_commands[*]}"
        warning "インストールスクリプトが自動的にインストールします"
    fi
}

# 設定ガイダンス表示
show_configuration_guide() {
    echo
    echo -e "${BLUE}=== 設定ガイダンス ===${NC}"
    echo
    echo "インストールを開始する前に、以下の設定を行ってください："
    echo
    echo -e "${YELLOW}1. .envファイルの編集${NC}"
    echo "   nano .env"
    echo
    echo -e "${YELLOW}2. 必須設定項目${NC}"
    echo "   - DOMAIN_NAME: あなたのドメイン名"
    echo "   - EMAIL: 管理者メールアドレス"
    echo "   - DB_ROOT_PASSWORD: MySQLルートパスワード"
    echo "   - DB_PASSWORD: データベースパスワード"
    echo "   - NEXTCLOUD_ADMIN_PASSWORD: Nextcloud管理者パスワード"
    echo
    echo -e "${YELLOW}3. DNS設定の確認${NC}"
    echo "   ドメインがサーバーのIPアドレスを正しく指していることを確認してください"
    echo
    echo -e "${YELLOW}4. ファイアウォール設定${NC}"
    echo "   ポート80(HTTP)とポート443(HTTPS)が開放されていることを確認してください"
    echo
    echo -e "${GREEN}設定完了後、以下のコマンドでインストールを開始してください：${NC}"
    echo "   sudo ./install-nextcloud.sh"
    echo
}

# セキュリティ警告表示
show_security_warnings() {
    echo
    echo -e "${RED}=== セキュリティに関する重要な注意事項 ===${NC}"
    echo
    echo -e "${YELLOW}⚠ パスワード設定${NC}"
    echo "   - 強力なパスワードを使用してください（12文字以上、英数字記号混在）"
    echo "   - デフォルトのパスワードは絶対に使用しないでください"
    echo
    echo -e "${YELLOW}⚠ .envファイルの管理${NC}"
    echo "   - .envファイルには機密情報が含まれています"
    echo "   - ファイルの権限は600に設定されています"
    echo "   - バージョン管理システムにコミットしないでください"
    echo
    echo -e "${YELLOW}⚠ 定期的なメンテナンス${NC}"
    echo "   - システムとNextcloudを定期的にアップデートしてください"
    echo "   - バックアップが正常に動作していることを確認してください"
    echo "   - ログを定期的に確認してください"
    echo
}

# 次のステップ表示
show_next_steps() {
    echo
    echo -e "${GREEN}=== セットアップ完了 ===${NC}"
    echo
    echo "次のステップ："
    echo
    echo -e "${BLUE}1. 設定ファイルの編集${NC}"
    echo "   nano .env"
    echo
    echo -e "${BLUE}2. 設定内容の確認${NC}"
    echo "   cat .env"
    echo
    echo -e "${BLUE}3. インストール実行${NC}"
    echo "   sudo ./install-nextcloud.sh"
    echo
    echo -e "${BLUE}4. インストール後の管理${NC}"
    echo "   sudo ./manage-nextcloud.sh status"
    echo "   sudo ./security-hardening.sh --all"
    echo "   sudo ./monitoring.sh monitor"
    echo
    echo -e "${BLUE}5. ドキュメント確認${NC}"
    echo "   詳細な使用方法は README.md を参照してください"
    echo
}

# メイン処理
main() {
    show_banner
    
    echo "セットアップを開始します..."
    echo
    
    check_system_requirements
    echo
    
    check_permissions
    echo
    
    check_files
    echo
    
    set_permissions
    echo
    
    prepare_config
    echo
    
    check_dependencies
    echo
    
    show_configuration_guide
    show_security_warnings
    show_next_steps
    
    echo -e "${GREEN}セットアップが完了しました！${NC}"
}

# スクリプト実行
main "$@"