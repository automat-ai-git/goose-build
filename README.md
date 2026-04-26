# Goose в Docker — персональный AI-агент на своём сервере

Готовая сборка [Goose](https://goose-docs.ai) для запуска на личном Linux-сервере.  
Открываешь браузер → вводишь пароль → попадаешь в терминал с AI-агентом.  
Всё работает локально, через Ollama, без облака.

## Что внутри

- **Goose** — AI-агент, который пишет код, управляет файлами и Docker-контейнерами
- **ttyd** — терминал в браузере (порт 7681)
- **Caddy** — авторизация перед входом (настраивается отдельно)
- **Ollama** — локальные модели (подключается через сеть `localai_default`)

## Требования

- Linux-сервер с Docker и Docker Compose
- Запущенный Ollama с нужной моделью (`devstral:24b` рекомендуется)
- Сеть `localai_default` уже существует (`docker network create localai_default`)
- Caddy для авторизации (опционально, но рекомендуется для публичного доступа)

## Установка

```bash
# 1. Клонировать репозиторий
git clone <repo-url> ~/goose
cd ~/goose

# 2. Создать конфиг
cp .env.example .env
cp config/config.yaml.example config/config.yaml

# 3. Узнать GID группы docker
stat -c '%g' /var/run/docker.sock

# 4. Заполнить .env (модель, DOCKER_GID, пароль для Caddy)
nano .env

# 5. Запустить
docker compose -f docker-compose.goose.yml up --build -d
```

Открыть в браузере: `http://сервер:7681`

## Структура файлов

```
~/goose/
├── Dockerfile                   # образ контейнера
├── docker-compose.goose.yml     # запуск сервиса
├── .env.example                 # шаблон переменных (заполнить → .env)
├── .goosehints                  # контекст для Goose (читается каждую сессию)
├── config/
│   ├── config.yaml.example      # шаблон конфига Goose (заполнить → config.yaml)
│   ├── config.yaml              # реальный конфиг (не в git)
│   └── secrets.yaml             # API ключи (не в git)
├── recipes/                     # рецепты — шаблоны сессий
│   ├── server.yaml              # стандартная сессия сервера
│   └── create-recipe.yaml       # как создавать новые рецепты
└── sessions/                    # история сессий SQLite (создаётся само, не в git)
```

### Что в git, что нет

| Файл / папка | В git | Почему |
|---|---|---|
| `Dockerfile`, `docker-compose.goose.yml` | ✓ | основа сборки |
| `.env.example`, `config.yaml.example` | ✓ | шаблоны для старта |
| `.goosehints` | ✓ | контекст сервера |
| `recipes/` | ✓ | шаблоны сессий |
| `caddy-addon/` | ✗ | конфиг с личными настройками сервера |
| `.env` | ✗ | секреты |
| `config/config.yaml`, `secrets.yaml` | ✗ | секреты и личные настройки |
| `sessions/` | ✗ | история разговоров |

## Что сохраняется при пересборке контейнера

Всё важное смонтировано на хост и не теряется:

- `config/` — настройки и расширения Goose
- `recipes/` — рецепты (включая созданные самим Goose)
- `sessions/` — история сессий
- `~/workspace` — общий рабочий workspace

## Доступ через Caddy

Создай конфиг для Caddy (пример в `.env.example`).  
Сгенерируй хэш пароля и добавь в `.env`:

```bash
docker exec caddy caddy hash-password --plaintext "твой_пароль"
```

Затем в `.env`:
```
GOOSE_USERNAME=admin
GOOSE_PASSWORD_HASH=<хэш из команды выше>
```

## Рецепты

Рецепты — это шаблоны сессий с инструкциями для Goose.  
Лежат в `~/goose/recipes/`, доступны внутри контейнера по пути `~/.config/goose/recipes/`.

```bash
# Запустить стандартную сессию сервера
goose session --recipe ~/.config/goose/recipes/server.yaml

# Создать новый рецепт (интерактивно)
goose session --recipe ~/.config/goose/recipes/create-recipe.yaml
```

## Модели

Рекомендуемые модели для агентной работы через Ollama:

| Модель | Размер | Для чего |
|---|---|---|
| `devstral:24b` | 24B | Создана специально для coding agents |
| `qwen3-coder:30b` | 30B | Сильнее в коде, тяжелее |

```bash
ollama pull devstral:24b
```
