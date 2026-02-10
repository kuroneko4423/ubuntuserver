#!/bin/bash

# Create admin user if it doesn't exist
if ! id -u admin >/dev/null 2>&1; then
    echo "Creating admin user..."
    useradd -m -s /bin/bash admin
    echo "admin:${ADMIN_PASSWORD:-admin123}" | chpasswd
    echo "Admin user created successfully"
else
    echo "Admin user already exists"
fi

# Start JupyterHub
exec jupyterhub -f /srv/jupyterhub/jupyterhub_config.py