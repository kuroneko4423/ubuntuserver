FROM nextcloud:latest

RUN apt-get update && \
    apt-get install -y smbclient libsmbclient-dev && \
    rm -rf /var/lib/apt/lists/*