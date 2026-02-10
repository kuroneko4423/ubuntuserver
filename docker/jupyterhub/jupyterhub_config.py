# JupyterHub configuration file
c = get_config()

# Basic configuration
c.JupyterHub.ip = '0.0.0.0'
c.JupyterHub.port = 8000
c.JupyterHub.hub_ip = 'jupyterhub'

# Spawner configuration - Use DockerSpawner for container-based notebooks
c.JupyterHub.spawner_class = 'dockerspawner.DockerSpawner'
c.DockerSpawner.image = 'jupyter/scipy-notebook:latest'
c.DockerSpawner.network_name = 'jupyterhub_jupyterhub-network'
c.DockerSpawner.remove = True
c.DockerSpawner.debug = True

# Notebook directory inside user container
c.DockerSpawner.notebook_dir = '/home/jovyan/work'

# Mount volumes
c.DockerSpawner.volumes = {
    'jupyterhub-user-{username}': '/home/jovyan/work'
}

# User authentication - DummyAuthenticator for testing
c.JupyterHub.authenticator_class = 'jupyterhub.auth.DummyAuthenticator'

# Admin users
c.Authenticator.admin_users = {'admin'}

# Allow specific users (including admin)
c.Authenticator.allowed_users = {'admin'}

# Password for DummyAuthenticator
c.DummyAuthenticator.password = 'jupyteradmin4423'

# Cookie secret and proxy token
c.JupyterHub.cookie_secret_file = '/srv/jupyterhub/jupyterhub_cookie_secret'
c.ConfigurableHTTPProxy.auth_token = ''

# Database location
c.JupyterHub.db_url = 'sqlite:////srv/jupyterhub/jupyterhub.sqlite'

# Logging
c.JupyterHub.log_level = 'INFO'

# Idle culler service (optional) - stops idle notebooks after timeout
c.JupyterHub.services = [
    {
        'name': 'idle-culler',
        'command': [
            'python3', '-m', 'jupyterhub_idle_culler',
            '--timeout=3600',  # 1 hour idle timeout
            '--max-age=7200',  # 2 hour max age
        ],
        'admin': True
    }
]

# SSL configuration (if using HTTPS)
# c.JupyterHub.ssl_cert = '/srv/jupyterhub/ssl/cert.pem'
# c.JupyterHub.ssl_key = '/srv/jupyterhub/ssl/key.pem'