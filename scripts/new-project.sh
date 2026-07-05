#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(dirname "$SCRIPT_DIR")"
PRESETS_DIR="$TEMPLATE_ROOT/presets"
CORE_ITEMS=(CLAUDE.md AGENTS.md .editorconfig .gitignore .claude)

usage() {
  echo "Uso: $0 /caminho/do/novo-projeto [--preset <nome>]"
  echo
  echo "Presets disponíveis:"
  if [ -d "$PRESETS_DIR" ]; then
    ls -1 "$PRESETS_DIR" | sed 's/^/  - /'
  fi
  exit 1
}

[ $# -ge 1 ] || usage

TARGET_DIR="$1"
shift

PRESET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --preset)
      [ $# -ge 2 ] || usage
      PRESET="$2"
      shift 2
      ;;
    *)
      echo "Argumento desconhecido: $1"
      usage
      ;;
  esac
done

if [ -n "$PRESET" ] && [ ! -d "$PRESETS_DIR/$PRESET" ]; then
  echo "Preset '$PRESET' não encontrado em $PRESETS_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
PROJECT_NAME="$(basename "$(cd "$TARGET_DIR" && pwd)")"

copy_file() {
  local src="$1"
  local dest="$2"
  if [ -f "$dest" ]; then
    echo "Aviso: $dest já existe, pulando (não sobrescrito)."
    return
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  sed -i.bak "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$dest"
  rm -f "$dest.bak"
}

copy_tree() {
  local src_root="$1"
  local dest_root="$2"
  local exclude_name="${3:-}"
  (cd "$src_root" && find . -type f) | while IFS= read -r rel; do
    rel="${rel#./}"
    if [ -n "$exclude_name" ] && [ "$(basename "$rel")" = "$exclude_name" ]; then
      continue
    fi
    copy_file "$src_root/$rel" "$dest_root/$rel"
  done
}

for item in "${CORE_ITEMS[@]}"; do
  src="$TEMPLATE_ROOT/$item"
  if [ -f "$src" ]; then
    copy_file "$src" "$TARGET_DIR/$item"
  elif [ -d "$src" ]; then
    copy_tree "$src" "$TARGET_DIR/$item"
  fi
done

if [ -n "$PRESET" ]; then
  copy_tree "$PRESETS_DIR/$PRESET" "$TARGET_DIR" "MANIFEST.md"
fi

echo
echo "Projeto criado em: $TARGET_DIR"
echo
echo "Próximos passos:"
echo "  1. cd $TARGET_DIR"
echo "  2. git init"
echo "  3. Preencher AGENTS.md (Stack, Comandos, Arquitetura)"
if [ -n "$PRESET" ]; then
  echo "  4. Ver $PRESETS_DIR/$PRESET/MANIFEST.md para os passos manuais do preset '$PRESET'"
fi
