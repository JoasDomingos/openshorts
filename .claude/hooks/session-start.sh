#!/bin/bash
# Instala as dependências de testes (pytest) e do painel (lint/build) nas
# sessões do Claude Code na nuvem. Espelha o que o CI (.github/workflows) instala.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}"

# --- Python: mesmas dependências de teste do CI, sem a pilha pesada de ML ---
pyhashes="$(python3 -I -c 'import sysconfig; print(sysconfig.get_path("purelib"))')/.session-start.sha256"
if ! sha256sum --check --status "$pyhashes" 2>/dev/null; then
  rm -f "$pyhashes"
  python3 -m pip install --quiet pytest pillow httpx pydantic sqlalchemy greenlet numpy \
    opencv-python-headless python-dotenv google-genai fastapi boto3 \
    PyJWT email-validator python-multipart asyncpg >&2
  sha256sum .claude/hooks/session-start.sh > "$pyhashes" || rm -f "$pyhashes"
fi

# --- Painel (dashboard): npm ---
hashes=dashboard/node_modules/.session-start.sha256
if ! sha256sum --check --status "$hashes" 2>/dev/null; then
  rm -f "$hashes"
  (cd dashboard && npm install --no-audit --no-fund) >&2
  sha256sum .claude/hooks/session-start.sh dashboard/package.json dashboard/package-lock.json > "$hashes" || rm -f "$hashes"
fi
