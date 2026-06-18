#!/bin/bash
set -e

# Дать пользователю goose доступ к docker.sock
if [ -S /var/run/docker.sock ]; then
    HOST_DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
    if ! getent group "$HOST_DOCKER_GID" >/dev/null; then
        groupadd -g "$HOST_DOCKER_GID" dockerhost
    fi
    usermod -aG "$HOST_DOCKER_GID" goose
fi

mkdir -p /home/goose/.local/share/goose /home/goose/.config/goose
chown -R goose:workspace_users /home/goose/.local
chown -R goose:workspace_users /home/goose/.config

cat > /etc/goose-init << 'EOF'
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

exec runuser -u goose -- env HOME=/home/goose PATH="/home/goose/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" ttyd -p 7681 -W bash --init-file /etc/goose-init
