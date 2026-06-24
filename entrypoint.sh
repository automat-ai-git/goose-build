#!/bin/bash
set -e

if [ -S /var/run/docker.sock ]; then
    HOST_DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
    if ! getent group "$HOST_DOCKER_GID" >/dev/null; then
        sudo groupadd -g "$HOST_DOCKER_GID" dockerhost
    fi
    sudo usermod -aG "$HOST_DOCKER_GID" goose
fi

sudo chown -R goose:workspace_users /home/goose/.local/share/goose/ 2>/dev/null || true
sudo chown -R goose:workspace_users /home/goose/.config/goose/ 2>/dev/null || true

exec ttyd -p 7681 -W bash --init-file /etc/goose-init
