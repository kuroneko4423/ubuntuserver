FROM ubuntu:22.04

# 必要なパッケージをインストール
RUN apt-get update && \
    apt-get install -y \
    wget \
    openssl \
    ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# MinIOユーザーを作成
RUN useradd -r -s /bin/false -u 1000 -g 0 minio

# MinIOバイナリをダウンロード
RUN wget https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/local/bin/minio && \
    chmod +x /usr/local/bin/minio

# 証明書とデータディレクトリを作成
RUN mkdir -p /root/.minio/certs /data && \
    chown -R minio:root /data

# 証明書生成スクリプトをコピー
COPY generate-cert-docker.sh /tmp/generate-cert.sh
RUN chmod +x /tmp/generate-cert.sh

# 証明書を生成
RUN /tmp/generate-cert.sh

# クリーンアップ
RUN rm /tmp/generate-cert.sh

# 証明書の権限を設定
RUN chown -R minio:root /root/.minio && \
    chmod 600 /root/.minio/certs/private.key && \
    chmod 644 /root/.minio/certs/public.crt

# MinIO設定ディレクトリを作成
RUN mkdir -p /home/minio/.minio/certs && \
    cp -r /root/.minio/certs/* /home/minio/.minio/certs/ && \
    chown -R minio:root /home/minio/.minio && \
    chmod 600 /home/minio/.minio/certs/private.key && \
    chmod 644 /home/minio/.minio/certs/public.crt

# MinIOユーザーに切り替え
USER minio

# 環境変数を設定
ENV MINIO_CERTS_DIR=/home/minio/.minio/certs

# ポートを公開
EXPOSE 9000 9001

# ボリュームを定義
VOLUME ["/data"]

# エントリポイント
ENTRYPOINT ["/usr/local/bin/minio"]