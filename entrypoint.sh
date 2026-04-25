#!/bin/bash
set -e

chown -R goose:workspace_users /home/goose/.local/share/goose/ 2>/dev/null || true
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

exec runuser -u goose -- env HOME=/home/goose PATH="/home/goose/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" ttyd -p 7681 -W bash --init-file /etc/goose-init
