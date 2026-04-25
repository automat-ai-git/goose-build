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
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 2000 workspace_users && \
    useradd -u 1002 -g 2000 -m -s /bin/bash goose

USER goose
WORKDIR /home/goose

RUN curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh | CONFIGURE=false bash

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

ENV PATH="/home/goose/.local/bin:$PATH"

WORKDIR /workspace
