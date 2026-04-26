#!/bin/bash
set -e

mkdir -p /home/goose/.local/share/goose/logs/cli
mkdir -p /home/goose/.local/share/goose/sessions
mkdir -p /home/goose/.local/state/goose/logs/cli
mkdir -p /home/goose/.config/goose

chown -R goose:workspace_users /home/goose/.local/
chown -R goose:workspace_users /home/goose/.config/goose/ 2>/dev/null || true

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

exec ttyd -p 7681 -W -u 1002 bash --init-file /etc/goose-init