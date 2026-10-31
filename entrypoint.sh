#!/bin/bash
set -e

if [ -S /var/run/docker.sock ]; then
    HOST_DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
    if ! getent group "$HOST_DOCKER_GID" >/dev/null; then
        sudo groupadd -g "$HOST_DOCKER_GID" dockerhost
    fi
    sudo usermod -aG "$HOST_DOCKER_GID" goose
fi

sudo chown -R goose:workspace_users /home/goose/.local 2>/dev/null || true
sudo chown -R goose:workspace_users /home/goose/.config 2>/dev/null || true

# ttyd → tmux: каждое подключение аттачится к сессии "main".
# tmux-сервер живёт независимо от соединений — сессия агента
# переживает обрыв связи и релоад Caddy.
exec ttyd -p 7681 -W -I /usr/share/ttyd-index.html \
    bash -c 'tmux attach -d || tmux new -s main -c /workspace'
