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
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --break-system-packages requests pyyaml python-dotenv

# tmux из исходников (Ubuntu 24.04 даёт только 3.4; extended-keys требует 3.5+).
# Версия на копирование не влияет — 3.5a и 3.8 ведут себя одинаково
RUN apt-get update && apt-get install -y \
    locales libevent-dev libncurses-dev bison pkg-config \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/ru_RU.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen \
    && curl -fsSL https://github.com/tmux/tmux/releases/download/3.8/tmux-3.8.tar.gz | tar xz \
    && cd tmux-3.8 && ./configure && make -j$(nproc) && make install \
    && cd .. && rm -rf tmux-3.8

ENV LANG=ru_RU.UTF-8
ENV LC_ALL=ru_RU.UTF-8

# ttyd frontend с поддержкой OSC52 (копирование в буфер браузера)
# apt-версия ttyd (1.7.x) не имеет @xterm/addon-clipboard,
# поэтому собираем фронтенд из main ветки и подаём через -I.
# + патч ttyd#1565: браузер молча отбрасывает navigator.clipboard.writeText()
# без user activation, а OSC52 прилетает по WebSocket без клика. Патч
# регистрирует обработчик OSC52 через document.execCommand('copy') —
# работает без жеста и на обычном http (PR не влит в upstream)
RUN git clone --depth 1 https://github.com/tsl0922/ttyd.git /tmp/ttyd-src \
    && cd /tmp/ttyd-src \
    && curl -fsSL https://patch-diff.githubusercontent.com/raw/tsl0922/ttyd/pull/1565.diff | git apply \
    && cd html \
    && corepack enable \
    && corepack prepare yarn@3.6.3 --activate \
    && yarn install \
    && yarn build \
    && npx gulp inline \
    && cp dist/inline.html /usr/share/ttyd-index.html \
    && cd / && rm -rf /tmp/ttyd-src

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

# Прогрев npx-кэша MCP-серверов: без него первая сессия висит, пока npx
# качает пакеты (инициализация экстеншенов обрывается по таймауту с EPIPE)
RUN timeout 120 npx -y @modelcontextprotocol/server-filesystem /workspace < /dev/null || true

ENV PATH="/home/goose/.local/bin:$PATH"

USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY yank /usr/local/bin/yank
RUN chmod +x /usr/local/bin/yank

# Шим для строгих Python MCP-серверов (plane, youtubetranscript): отвечают
# криво/падают на новый метод goose server/discover (goose#13177), а fallback
# срабатывает только на -32601 — шим отвечает им от имени сервера
COPY mcp-legacy-shim /usr/local/bin/mcp-legacy-shim
RUN chmod +x /usr/local/bin/mcp-legacy-shim

COPY tmux.conf /home/goose/.tmux.conf
RUN chown goose:workspace_users /home/goose/.tmux.conf

# Баннер печатается в каждой новой tmux-панели (подключён в .bashrc)
RUN cat > /etc/goose-init << 'EOF'
echo ""
echo "  ══════════════════════════════════════"
echo "  🪿  Goose AI Agent (tmux)"
echo "  ══════════════════════════════════════"
echo "  goose session       — запустить сессию"
echo "  goose configure     — настройка модели и MCP"
echo "  goose --help        — все команды"
echo "  ──────────────────────────────────────"
echo "  Копировать:  выделить мышью, отпустить"
echo "  В сессии:    Shift + выделить, отпустить"
echo "  Вставить:    правый клик > Paste / Ctrl+Shift+V"
echo "  tmux: Ctrl+B, C — окно, Ctrl+B, D — отсоединиться"
echo "  Сессия переживает обрыв связи и релоад Caddy"
echo "  ══════════════════════════════════════"
echo ""
EOF

RUN echo 'cat /etc/goose-init 2>/dev/null' >> /home/goose/.bashrc \
    && chown goose:workspace_users /home/goose/.bashrc

USER goose
WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]
