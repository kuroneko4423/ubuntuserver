FROM codercom/code-server:latest

USER root

# Install common utilities and dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    sudo \
    gnupg \
    lsb-release \
    software-properties-common \
    build-essential \
    ninja-build \
    libgtk-3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest

# Install Python and pip (using system default Python 3)
RUN apt-get update \
    && apt-get install -y \
    python3 \
    python3-venv \
    python3-dev \
    python3-pip \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# Install Java 17 (OpenJDK)
RUN apt-get update && apt-get install -y openjdk-17-jdk maven gradle

# Install Google Chrome
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable

# Install Flutter
RUN curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz | tar -xJ -C /opt \
    && chown -R coder:coder /opt/flutter

# Install Android SDK Command Line Tools
RUN mkdir -p /opt/android-sdk/cmdline-tools \
    && cd /opt/android-sdk/cmdline-tools \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    && unzip -q commandlinetools-linux-11076708_latest.zip \
    && mv cmdline-tools latest \
    && rm commandlinetools-linux-11076708_latest.zip \
    && chown -R coder:coder /opt/android-sdk

# Create Python virtual environment directory as root
RUN mkdir -p /home/coder/venv && chown -R coder:coder /home/coder/venv

# Add coder to sudoers with no password requirement
RUN echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install global npm packages as root
RUN npm install -g @google/gemini-cli @anthropic-ai/claude-code

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=/home/coder/venv/bin:$PATH:/opt/flutter/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV VIRTUAL_ENV=/home/coder/venv

# Switch to coder user
USER coder

# Create and activate virtual environment, then install Python packages
RUN python3 -m venv /home/coder/venv \
    && /home/coder/venv/bin/pip install --upgrade pip \
    && /home/coder/venv/bin/pip install django fastapi streamlit uvicorn lightgbm

# Configure Flutter
RUN /opt/flutter/bin/flutter config --no-analytics \
    && /opt/flutter/bin/flutter config --android-sdk /opt/android-sdk

# Create necessary directories with proper permissions
RUN mkdir -p /home/coder/.config \
    && mkdir -p /home/coder/project \
    && mkdir -p /home/coder/.local/share/code-server/extensions \
    && chown -R coder:coder /home/coder/.config \
    && chown -R coder:coder /home/coder/.local \
    && chmod -R 755 /home/coder/.config \
    && chmod -R 755 /home/coder/.local

# Copy extension installation script
COPY --chown=coder:coder install-extensions.sh /home/coder/install-extensions.sh
# Convert line endings and make executable
RUN sed -i 's/\r$//' /home/coder/install-extensions.sh \
    && chmod +x /home/coder/install-extensions.sh

# Copy startup script
COPY --chown=coder:coder startup.sh /home/coder/startup.sh
# Convert line endings and make executable
RUN sed -i 's/\r$//' /home/coder/startup.sh \
    && chmod +x /home/coder/startup.sh

# Set working directory
WORKDIR /home/coder/project

# Set entrypoint
ENTRYPOINT ["/bin/bash", "/home/coder/startup.sh"]