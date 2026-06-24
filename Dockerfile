FROM ubuntu:24.04

USER root

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    build-essential \
    curl \
    git \
    nano \
    procps \
    lsof \
    ttyd \
    ffmpeg \
    jq \
    ripgrep \
    fd-find \
    sqlite3 \
    unzip \
    zip \
    wget \
    docker.io \
    sudo \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Docker Compose plugin (agent manages compose stacks via docker.sock)
RUN mkdir -p /usr/local/lib/docker/cli-plugins && \
    curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
    -o /usr/local/lib/docker/cli-plugins/docker-compose && \
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

RUN groupadd -g 2000 workspace_users && \
    useradd -u 1002 -g 2000 -m -s /bin/bash goose && \
    echo "goose ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/goose && \
    chmod 0440 /etc/sudoers.d/goose

USER goose
WORKDIR /home/goose

RUN curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh | CONFIGURE=false bash

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

ENV PATH="/home/goose/.local/bin:$PATH"

USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN cat > /etc/goose-init << 'EOF'
[ -f ~/.bashrc ] && source ~/.bashrc

echo ""
echo "  ══════════════════════════════════════"
echo "  🪿  Goose AI Agent"
echo "  ══════════════════════════════════════"
echo "  goose session       — запустить сессию"
echo "  goose configure     — настройка модели и MCP"
echo "  goose --help        — все команды"
echo "  ══════════════════════════════════════"
echo ""
EOF

USER goose
WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]
