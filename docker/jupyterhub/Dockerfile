FROM jupyterhub/jupyterhub:latest

# Install DockerSpawner and additional dependencies
RUN pip install --no-cache-dir \
    dockerspawner \
    jupyterhub-idle-culler \
    oauthenticator

# Create necessary directories
RUN mkdir -p /srv/jupyterhub

# Copy the admin user creation script and convert line endings
COPY create_admin_user.sh /usr/local/bin/
RUN dos2unix /usr/local/bin/create_admin_user.sh || \
    sed -i 's/\r$//' /usr/local/bin/create_admin_user.sh && \
    chmod +x /usr/local/bin/create_admin_user.sh

# Expose port
EXPOSE 8000

# Set working directory
WORKDIR /srv/jupyterhub

# Use bash to run the script
ENTRYPOINT ["/bin/bash", "/usr/local/bin/create_admin_user.sh"]