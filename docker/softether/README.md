# SoftEther VPN Server Docker構成

このディレクトリには、DockerでSoftEther VPN Serverを実行するための設定ファイルが含まれています。

## 概要

SoftEther VPN Serverは、多機能なオープンソースのVPNソフトウェアです。このDocker構成では、以下のVPNプロトコルをサポートしています：

- L2TP/IPSec
- OpenVPN
- MS-SSTP
- L2TPv3/IPsec
- EtherIP

## 使用方法

### 1. 環境変数の設定

提供されている`.env.example`ファイルをコピーして、環境変数を設定してください：

```bash
cp .env.example .env
```

`.env`ファイルを編集して、以下の値を適切に設定してください：

- `SOFTETHER_SERVER_PASSWORD`: サーバー管理パスワード
- `SOFTETHER_HUB_PASSWORD`: 仮想HUBパスワード
- `SOFTETHER_IPSEC_PSK`: IPSec事前共有鍵
- `SOFTETHER_USERNAME`: VPNユーザー名
- `SOFTETHER_PASSWORD`: VPNユーザーパスワード

**重要**: セキュリティのため、必ずデフォルト値から変更してください。

### 2. コンテナの起動

```bash
docker-compose up -d
```

初回起動時は、`config/`と`logs/`ディレクトリが自動的に作成されます。

### 3. コンテナの停止

```bash
docker-compose down
```

## ポート設定

以下のポートが公開されています：

- `500/udp`: IPSec IKE
- `4500/udp`: IPSec NAT-T
- `1701/tcp`: L2TP
- `1194/udp`: OpenVPN
- `5555/tcp`: SoftEther VPN Server管理
- `443/tcp`: HTTPS/SSTP

## ボリューム

以下のディレクトリがマウントされます：

- `./config/`: VPNサーバー設定ディレクトリ（設定ファイルや証明書など）
- `./logs/`: 各種ログファイル
  - `./logs/`: サーバーログ
  - `./logs/packet_log/`: パケットログ
  - `./logs/security_log/`: セキュリティログ

## 管理方法

### SoftEther VPN Server Manager（GUI）

Windows、Mac、LinuxでSoftEther VPN Server Managerをダウンロードして使用できます。

接続設定：
- ホスト名: `localhost`または`サーバーのIPアドレス`
- ポート: `5555`
- パスワード: 環境変数で設定したサーバーパスワード

### vpncmd（CLI）

コンテナ内でvpncmdを使用する場合：

```bash
docker exec -it softether-vpn vpncmd
```

## セキュリティに関する注意事項

1. **必ずデフォルトパスワードを変更してください**
2. ファイアウォールで必要なポートのみを開放してください
3. 定期的にログを確認してください
4. 本番環境では、より強固なパスワードとPSKを使用してください

## 初回起動時の注意

初回起動時には以下の処理が自動的に行われます：

1. `config/`ディレクトリの作成と初期設定ファイルの生成
2. `logs/`ディレクトリとサブディレクトリの作成
3. 環境変数で指定したユーザーの作成

設定が完了するまで数分かかる場合があります。`docker-compose logs -f`でログを確認してください。

## トラブルシューティング

### ログの確認

```bash
# コンテナログの確認
docker-compose logs -f softether

# VPNサーバーログの確認
tail -f ./logs/vpn_*.log
```

### コンテナの再起動

```bash
docker-compose restart softether
```

## 参考リンク

- [SoftEther VPN公式サイト](https://www.softether.org/)
- [siomiz/softethervpn Docker Hub](https://hub.docker.com/r/siomiz/softethervpn)

## ファイル構成

```
docker/softether/
├── docker-compose.yml    # Docker Compose設定ファイル
├── .env.example         # 環境変数設定例
├── .env                 # 環境変数設定（.gitignoreで除外）
├── .gitignore           # Git除外設定
├── README.md            # このファイル
├── config/              # VPNサーバー設定ディレクトリ（自動生成）
└── logs/                # ログディレクトリ
    ├── packet_log/      # パケットログ
    └── security_log/    # セキュリティログ
```
