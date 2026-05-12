#!/bin/bash
set -e
cd "$(dirname "$0")"

if [ ! -f "../.env" ]; then
    echo "请先创建 .env 文件"
    exit 1
fi

mkdir -p data/uploads

UVICORN_BIN="../.venv/bin/uvicorn"
if [ ! -x "$UVICORN_BIN" ]; then
    UVICORN_BIN="uvicorn"
fi

PORT="${MENTORAIX_API_PORT:-58888}"

exec "$UVICORN_BIN" app.main:app --reload --host 0.0.0.0 --port "$PORT"
