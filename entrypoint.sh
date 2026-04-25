#!/bin/bash
set -e

chown -R goose:workspace_users /home/goose/.local/share/goose/ 2>/dev/null || true
chown -R goose:workspace_users /home/goose/.config/goose/ 2>/dev/null || true

exec runuser -u goose -- env HOME=/home/goose PATH="/home/goose/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" ttyd -p 7681 -W goose session
