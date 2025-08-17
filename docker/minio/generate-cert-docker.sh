#!/bin/bash

# 証明書を格納するディレクトリに移動
cd /root/.minio/certs

# 秘密鍵を生成
openssl genrsa -out private.key 4096

# 証明書署名要求（CSR）を生成
openssl req -new -key private.key -out cert.csr -subj "/C=JP/ST=Tokyo/L=Tokyo/O=MinIO Self-Signed/OU=IT/CN=localhost"

# 自己署名証明書を生成（有効期限10000日）
openssl x509 -req -days 10000 -in cert.csr -signkey private.key -out public.crt

# CSRファイルを削除
rm cert.csr

# 権限を設定
chmod 600 private.key
chmod 644 public.crt

echo "証明書の生成が完了しました:"
echo "  - 秘密鍵: /root/.minio/certs/private.key"
echo "  - 証明書: /root/.minio/certs/public.crt"