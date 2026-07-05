#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEW_PROJECT="$SCRIPT_DIR/new-project.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fail() {
  echo "FALHOU: $1"
  exit 1
}

# Caso 1: sem preset — só arquivos core
TARGET1="$WORK/meu-projeto"
"$NEW_PROJECT" "$TARGET1" >/tmp/new-project-test-out-1.txt

test -f "$TARGET1/CLAUDE.md" || fail "CLAUDE.md não foi criado"
test -f "$TARGET1/AGENTS.md" || fail "AGENTS.md não foi criado"
test -f "$TARGET1/.editorconfig" || fail ".editorconfig não foi criado"
test -f "$TARGET1/.gitignore" || fail ".gitignore não foi criado"
test -f "$TARGET1/.claude/settings.json" || fail ".claude/settings.json não foi criado"
test -f "$TARGET1/.nvmrc" && fail "arquivo de preset vazou sem --preset"

grep -q "# meu-projeto" "$TARGET1/AGENTS.md" || fail "{{PROJECT_NAME}} não foi substituído em AGENTS.md"
grep -q "{{PROJECT_NAME}}" "$TARGET1/AGENTS.md" && fail "placeholder {{PROJECT_NAME}} ainda presente"

# Caso 2: com preset nextjs-pnpm — core + preset, sem MANIFEST.md
TARGET2="$WORK/outro-projeto"
"$NEW_PROJECT" "$TARGET2" --preset nextjs-pnpm >/tmp/new-project-test-out-2.txt

test -f "$TARGET2/CLAUDE.md" || fail "core não copiado com preset"
test -f "$TARGET2/.nvmrc" || fail ".nvmrc do preset não foi copiado"
test -f "$TARGET2/.releaserc.json" || fail ".releaserc.json do preset não foi copiado"
test -f "$TARGET2/commitlint.config.js" || fail "commitlint.config.js do preset não foi copiado"
test -f "$TARGET2/lefthook.yml" || fail "lefthook.yml do preset não foi copiado"
test -f "$TARGET2/.github/workflows/ci.yml" || fail "ci.yml do preset não foi copiado"
test -f "$TARGET2/.env.example" || fail ".env.example do preset não foi copiado"
test -f "$TARGET2/MANIFEST.md" && fail "MANIFEST.md não deveria ser copiado para o projeto"

# Caso 3: idempotência — não sobrescreve arquivo já existente
echo "conteudo manual do dev" > "$TARGET1/.gitignore"
"$NEW_PROJECT" "$TARGET1" >/tmp/new-project-test-out-3.txt
grep -q "conteudo manual do dev" "$TARGET1/.gitignore" || fail "arquivo existente foi sobrescrito"

# Caso 4: preset inexistente falha com código de erro != 0
if "$NEW_PROJECT" "$WORK/terceiro-projeto" --preset inexistente >/tmp/new-project-test-out-4.txt 2>&1; then
  fail "script deveria falhar com preset inexistente"
fi

echo "PASS"
