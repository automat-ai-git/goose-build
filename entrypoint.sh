#!/bin/bash
set -e

chown -R goose:workspace_users /home/goose/.local/share/goose/ 2>/dev/null || true
chown -R goose:workspace_users /home/goose/.config/goose/ 2>/dev/null || true

exec runuser -u goose -- ttyd -p 7681 -W goose session
