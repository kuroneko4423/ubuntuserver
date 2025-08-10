#!/bin/bash

# Fix permissions for mounted volumes
echo "Fixing permissions..."
sudo chown -R coder:coder /home/coder/.config || true
sudo chown -R coder:coder /home/coder/.local || true
sudo chown -R coder:coder /home/coder/project || true
sudo chmod -R 755 /home/coder/.config || true
sudo chmod -R 755 /home/coder/.local || true
sudo chmod -R 755 /home/coder/project || true

# Check if extensions have been installed
EXTENSIONS_MARKER="/home/coder/.local/share/code-server/.extensions_installed"

if [ ! -f "$EXTENSIONS_MARKER" ]; then
    echo "First time setup - installing extensions..."
    /home/coder/install-extensions.sh
    touch "$EXTENSIONS_MARKER"
    echo "Extensions installation completed."
fi

# Start code-server
exec code-server \
    --bind-addr 0.0.0.0:8080 \
    --auth password \
    --user-data-dir /home/coder/.config/code-server \
    --extensions-dir /home/coder/.local/share/code-server/extensions \
    ${DEFAULT_WORKSPACE:-/home/coder/project}