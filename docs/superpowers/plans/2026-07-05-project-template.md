# Project Template (base global + repositório-template) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar a camada global de configuração do Claude Code (`~/.claude/`) e o repositório `~/DEV/project-template` que juntos servem de base para todos os projetos futuros do Vitor.

**Architecture:** Duas camadas independentes. A global (`~/.claude/CLAUDE.md`, `~/.claude/skills/no-auto-commits.md`, `~/.claude/agents/simplicity-reviewer.md`) não depende de nenhum arquivo do repositório e passa a valer imediatamente em qualquer sessão do Claude Code. O repositório-template é um projeto git autocontido em `~/DEV/project-template` com arquivos "core" (copiados sempre) e "presets" (copiados sob demanda), materializados em projetos novos via `scripts/new-project.sh`.

**Tech Stack:** Markdown (CLAUDE.md/AGENTS.md/skills/agents), JSON (settings.json, .releaserc.json), YAML (lefthook.yml, ci.yml), Bash (script de scaffold + teste do script).

## Global Constraints

- Diretiva de idioma: `~/.claude/CLAUDE.md` deve instruir resposta padrão em português do Brasil, exceto quando o prompt pedir outro idioma explicitamente.
- Nenhum script deste plano executa `git add`, `git commit`, `git push` ou instala dependências automaticamente — apenas materializa arquivos e imprime os próximos passos manuais (consistente com a skill `no-auto-commits`).
- `presets/nextjs-pnpm` fixa Node em `24` (LTS ativo no momento deste plano).
- `.claude/settings.json` do template contém **apenas** permissões de leitura (`git status`, `git diff`, `git log`, `git show`, `ls`, `find`, `grep`, `rg`, `cat`) — nenhuma escrita liberada por padrão.
- Nesta iteração existe só um preset (`nextjs-pnpm`); a estrutura deve permitir adicionar outros depois sem alterar `new-project.sh`.
- `MANIFEST.md` de um preset nunca é copiado para o projeto gerado — é documentação de referência que permanece no template.
- Arquivos já existentes no destino nunca são sobrescritos por `new-project.sh` — o script avisa e pula.

---

### Task 1: CLAUDE.md global

**Files:**
- Create: `/home/vitor/.claude/CLAUDE.md`

**Interfaces:**
- Produces: arquivo lido automaticamente pelo Claude Code em toda sessão, em qualquer diretório. Nenhuma outra task depende do conteúdo exato, só da existência do arquivo.

- [ ] **Step 1: Escrever o arquivo**

Conteúdo completo de `/home/vitor/.claude/CLAUDE.md`:

```markdown
Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

## Language

Always respond in Brazilian Portuguese and always input your questions in Brazilian Portuguese, regardless of the language used in prompts.
The only exception to this is if the prompt asks you to do so in another language. If you use a skill or manipulate a file in another language,
you should translate it to Brazilian Portuguese as well. When manipulating code files, variables or functions may be in English.
```

- [ ] **Step 2: Verificar**

Run: `test -f /home/vitor/.claude/CLAUDE.md && wc -l /home/vitor/.claude/CLAUDE.md`
Expected: caminho existe e retorna uma contagem de linhas > 0 (arquivo não vazio).

Não há commit nesta task — `~/.claude/` não é um repositório git deste projeto.

---

### Task 2: Skill global `no-auto-commits`

**Files:**
- Create: `/home/vitor/.claude/skills/no-auto-commits.md`

**Interfaces:**
- Produces: skill descoberta automaticamente pelo Claude Code em `~/.claude/skills/`. Independente das demais tasks.

- [ ] **Step 1: Criar o diretório e o arquivo**

Run: `mkdir -p /home/vitor/.claude/skills`

Conteúdo completo de `/home/vitor/.claude/skills/no-auto-commits.md`:

```markdown
---
name: no-auto-commits
description: Use when completing any code task — commits, git add, git push, git amend, and any other git write operations are exclusively the developer's responsibility. Never execute git write commands automatically.
---

# No Auto Commits

## Overview

**The developer owns the git history. Always.** Never run `git add`, `git commit`, `git push`, `git amend`, or any other git write operation on behalf of the developer — even when explicitly asked to "commit" as part of a task.

## Rule

**NEVER execute these commands:**
- `git add`
- `git commit`
- `git commit --amend`
- `git push`
- `git push --force`
- `git reset` (when used to rewrite history)
- `git rebase` (interactive or otherwise)
- `git tag` (creating tags)
- `git stash` (modifying stash)

**ALWAYS instead:** show the commands the developer should run, and explain what each does.

## What to Do Instead

When a task is complete, output the git commands for the developer to run:

```
Alterações prontas para commit. Rode:

git add src/omni/dialog/CloseConversationDialog.tsx
git commit -m "feat: add CloseConversationDialog with attendance type selection"
```

If multiple files with different logical groupings, suggest separate commits:

```
Sugiro dois commits:

# 1. Backend
git add api/src/routes/conversations.ts
git commit -m "feat: save tipoAtendimento in metadata on close"

# 2. Frontend
git add src/services/api.ts src/hooks/useConversations.ts
git commit -m "feat: extend updateStatus to forward tipoAtendimento"
```

## Rationalizations to Ignore

| Racionalização | Realidade |
|---|---|
| "O dev pediu para commitar" | Não importa. Mostre o comando, não execute. |
| "Faz parte do plano de implementação" | Planos sugerem comandos, devs executam. |
| "É mais rápido se eu commitar" | Velocidade não justifica tomar controle do histórico. |
| "O skill de subagent-driven-development pede commits" | Esse skill tem prioridade. Mostre o comando. |
| "É só um commit de teste/chore" | Todo commit pertence ao dev. Sem exceções. |
| "O dev disse 'pode commitar'" | Diga que não faz commits — mostre o comando. |
| "Preciso fazer amend para corrigir" | Mostre `git commit --amend` para o dev rodar. |

## Red Flags — Pare Imediatamente

Se você está prestes a digitar qualquer um destes, PARE:

- `git add`
- `git commit`
- `git push`
- `git amend`

Substitua pela versão impressa do comando e entregue ao dev.

## O que não muda

Estes comandos de **leitura** são permitidos:
- `git status`
- `git diff`
- `git log`
- `git show`
- `git branch` (listar)
- `git stash list`
```

- [ ] **Step 2: Verificar**

Run: `test -f /home/vitor/.claude/skills/no-auto-commits.md && head -5 /home/vitor/.claude/skills/no-auto-commits.md`
Expected: mostra o frontmatter (`---`, `name: no-auto-commits`, ...).

Não há commit nesta task.

---

### Task 3: Agent global `simplicity-reviewer`

**Files:**
- Create: `/home/vitor/.claude/agents/simplicity-reviewer.md`

**Interfaces:**
- Produces: subagent `simplicity-reviewer`, invocável via `Agent(subagent_type: "simplicity-reviewer")` em qualquer projeto. Nome escolhido deliberadamente diferente de `code-reviewer` (já usado por outro plugin de mercado) para não colidir.

- [ ] **Step 1: Criar o diretório e o arquivo**

Run: `mkdir -p /home/vitor/.claude/agents`

Conteúdo completo de `/home/vitor/.claude/agents/simplicity-reviewer.md`:

```markdown
---
name: simplicity-reviewer
description: Revisa diffs pela ótica de simplicidade e escopo — over-engineering, abstrações prematuras, mudanças fora do pedido, código que poderia ser mais simples. Não cobre bugs ou segurança (use uma skill/agent de code review geral para isso).
tools: Glob, Grep, Read, Bash
model: sonnet
color: yellow
---

Você é um revisor especializado em simplicidade e escopo, aplicando estas guidelines:

## O que você procura

1. **Over-engineering**: abstrações, configurabilidade ou flexibilidade que não foram pedidas e não têm um segundo uso real hoje.
2. **Escopo vazado**: mudanças no diff que não têm relação direta com o pedido original (refactors não solicitados, formatação de código não tocado, "melhorias" adjacentes).
3. **Complexidade evitável**: se o mesmo resultado poderia ser alcançado com bem menos código, ou com uma estrutura mais direta.
4. **Órfãos**: imports, variáveis ou funções que a própria mudança tornou mortos e que não foram removidos.
5. **Tratamento de erro especulativo**: `try/catch`, validações ou guards para cenários que não podem acontecer no contexto do código.

## O que você NÃO faz

- Não procura bugs de lógica, segurança ou performance — isso é responsabilidade de outra revisão.
- Não sugere estilo de formatação (isso é responsabilidade de linter/formatter).
- Não propõe refactors não relacionados ao diff em análise.

## Processo

1. Rode `git diff` (ou receba o diff/arquivos indicados) para entender exatamente o que mudou.
2. Para cada trecho alterado, pergunte: "essa linha existe porque o pedido exigiu, ou porque pareceu uma boa ideia paralela?"
3. Liste achados com: arquivo:linha, o que está sobre-engenheirado ou fora de escopo, e uma sugestão concreta e mínima de correção.
4. Se o diff já é simples e enxuto, diga isso explicitamente em vez de forçar achados.

## Formato de saída

Para cada achado:

- **Arquivo:linha**
- **Problema**: descrição objetiva
- **Sugestão**: o que remover/simplificar, em uma frase

Se não houver achados, responda apenas: "Diff já está no ponto — sem excesso de escopo ou complexidade evitável encontrado."
```

- [ ] **Step 2: Verificar**

Run: `test -f /home/vitor/.claude/agents/simplicity-reviewer.md && head -6 /home/vitor/.claude/agents/simplicity-reviewer.md`
Expected: mostra o frontmatter com `name: simplicity-reviewer`.

Não há commit nesta task.

---

### Task 4: Arquivos "core" do repositório-template

**Files:**
- Create: `/home/vitor/DEV/project-template/AGENTS.md`
- Create: `/home/vitor/DEV/project-template/CLAUDE.md`
- Create: `/home/vitor/DEV/project-template/.editorconfig`
- Create: `/home/vitor/DEV/project-template/.gitignore`
- Create: `/home/vitor/DEV/project-template/.claude/settings.json`

**Interfaces:**
- Produces: os cinco caminhos acima, que a Task 6 (`new-project.sh`) referencia literalmente no array `CORE_ITEMS=(CLAUDE.md AGENTS.md .editorconfig .gitignore .claude)`.
- `AGENTS.md` contém o literal `{{PROJECT_NAME}}` que a Task 6 substitui via `sed`.

- [ ] **Step 1: `AGENTS.md`**

```markdown
# {{PROJECT_NAME}}

> Preencha as seções abaixo ao iniciar o projeto. As guidelines comportamentais gerais (simplicidade, mudanças cirúrgicas, idioma de resposta) já vêm da configuração global do Claude Code (`~/.claude/CLAUDE.md`) — não repita aqui.

## Stack

<!-- Ex: Next.js 15 + TypeScript + pnpm + Prisma + PostgreSQL -->

## Comandos

<!-- Ex:
- `pnpm dev` — sobe o ambiente de desenvolvimento
- `pnpm test` — roda a suíte de testes
- `pnpm build` — build de produção
-->

## Arquitetura

<!-- Estrutura de pastas, camadas, decisões importantes -->

## Documentação adicional

<!-- Links para ADRs, docs de domínio, tracker de issues, etc. -->
```

- [ ] **Step 2: `CLAUDE.md`**

```markdown
@AGENTS.md
```

- [ ] **Step 3: `.editorconfig`**

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 2

[*.md]
trim_trailing_whitespace = false
```

- [ ] **Step 4: `.gitignore`**

```gitignore
# Dependências
node_modules/
**/node_modules/

# Build
dist/
**/dist/
build/

# Ambiente
.env
.env.local
.env.*.local
!.env.example

# Testes
coverage/
**/coverage/

# Logs e SO
*.log
.DS_Store

# IDE
.vscode/
.idea/

# TypeScript incremental build cache
*.tsbuildinfo
```

- [ ] **Step 5: `.claude/settings.json`**

Run: `mkdir -p /home/vitor/DEV/project-template/.claude`

```json
{
  "permissions": {
    "allow": [
      "Bash(git status)",
      "Bash(git status:*)",
      "Bash(git diff)",
      "Bash(git diff:*)",
      "Bash(git log)",
      "Bash(git log:*)",
      "Bash(git show:*)",
      "Bash(ls)",
      "Bash(ls:*)",
      "Bash(find:*)",
      "Bash(grep:*)",
      "Bash(rg:*)",
      "Bash(cat:*)"
    ]
  }
}
```

- [ ] **Step 6: Verificar**

Run: `cd /home/vitor/DEV/project-template && test -f AGENTS.md && test -f CLAUDE.md && test -f .editorconfig && test -f .gitignore && test -f .claude/settings.json && python3 -m json.tool .claude/settings.json > /dev/null && echo OK`
Expected: `OK` (confirma que os 5 arquivos existem e o JSON é válido).

- [ ] **Step 7: Commit**

```bash
git add AGENTS.md CLAUDE.md .editorconfig .gitignore .claude/settings.json
git commit -m "feat: add core template files (AGENTS.md, CLAUDE.md, editorconfig, gitignore, settings)"
```

---

### Task 5: Preset `nextjs-pnpm`

**Files:**
- Create: `/home/vitor/DEV/project-template/presets/nextjs-pnpm/MANIFEST.md`
- Create: `/home/vitor/DEV/project-template/presets/nextjs-pnpm/.nvmrc`
- Create: `/home/vitor/DEV/project-template/presets/nextjs-pnpm/.releaserc.json`
- Create: `/home/vitor/DEV/project-template/presets/nextjs-pnpm/commitlint.config.js`
- Create: `/home/vitor/DEV/project-template/presets/nextjs-pnpm/lefthook.yml`
- Create: `/home/vitor/DEV/project-template/presets/nextjs-pnpm/.github/workflows/ci.yml`
- Create: `/home/vitor/DEV/project-template/presets/nextjs-pnpm/.env.example`

**Interfaces:**
- Produces: diretório `presets/nextjs-pnpm/` que a Task 6 referencia pelo nome literal `nextjs-pnpm` (usado no teste do script) e cujo `MANIFEST.md` é excluído da cópia.

- [ ] **Step 1: `MANIFEST.md`**

```markdown
# Preset: nextjs-pnpm

Espelha o setup de tooling do projeto `central`, genérico o bastante pra servir de ponto de partida em qualquer app Next.js + TypeScript + pnpm.

## O que este preset adiciona

- `.nvmrc` — versão do Node fixada (24)
- `.releaserc.json` — semantic-release (changelog + git + github, sem publicar no npm)
- `commitlint.config.js` — Conventional Commits
- `lefthook.yml` — typecheck e testes no pre-commit, commitlint no commit-msg
- `.github/workflows/ci.yml` — checkout, install, typecheck, testes em PRs
- `.env.example` — esqueleto de variáveis de ambiente

## Passos manuais depois de gerar o projeto

1. Garantir que o `package.json` do projeto tem os scripts `test` e `build` (o CI e o lefthook assumem `pnpm test`).
2. Instalar as devDependencies necessárias:
   ```bash
   pnpm add -D lefthook @commitlint/cli @commitlint/config-conventional \
     semantic-release @semantic-release/changelog @semantic-release/git
   ```
3. Ativar os git hooks:
   ```bash
   pnpm exec lefthook install
   ```
4. Se for publicar releases automatizadas, configurar o token do GitHub Actions com permissão de `contents: write` no workflow de release (não incluído neste preset — adicionar conforme necessidade).
```

- [ ] **Step 2: `.nvmrc`**

```
24
```

- [ ] **Step 3: `.releaserc.json`**

```json
{
  "branches": ["main", "master"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    ["@semantic-release/npm", { "npmPublish": false }],
    [
      "@semantic-release/git",
      {
        "assets": ["CHANGELOG.md", "package.json"],
        "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
      }
    ],
    "@semantic-release/github"
  ]
}
```

- [ ] **Step 4: `commitlint.config.js`**

```javascript
module.exports = {
  extends: ['@commitlint/config-conventional'],
};
```

- [ ] **Step 5: `lefthook.yml`**

```yaml
pre-commit:
  parallel: true
  commands:
    typecheck:
      run: pnpm exec tsc --noEmit

    tests:
      run: pnpm test

commit-msg:
  commands:
    commitlint:
      run: pnpm exec commitlint --edit {1}
```

- [ ] **Step 6: `.github/workflows/ci.yml`**

Run: `mkdir -p /home/vitor/DEV/project-template/presets/nextjs-pnpm/.github/workflows`

```yaml
name: CI

on:
  pull_request:
    types: [opened, synchronize, reopened]

concurrency:
  group: ci-${{ github.event.pull_request.number }}
  cancel-in-progress: true

jobs:
  validate:
    name: Validação
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v4

      - uses: actions/setup-node@v4
        with:
          node-version-file: .nvmrc
          cache: pnpm

      - name: Instalar dependências
        run: pnpm install --frozen-lockfile

      - name: Typecheck
        run: pnpm exec tsc --noEmit

      - name: Testes
        run: pnpm test
```

- [ ] **Step 7: `.env.example`**

```
# Copie para .env e preencha os valores reais.
# NEXT_PUBLIC_APP_URL=http://localhost:3000
```

- [ ] **Step 8: Verificar**

Run: `cd /home/vitor/DEV/project-template/presets/nextjs-pnpm && test -f MANIFEST.md && test -f .nvmrc && test -f .releaserc.json && test -f commitlint.config.js && test -f lefthook.yml && test -f .github/workflows/ci.yml && test -f .env.example && python3 -m json.tool .releaserc.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 9: Commit**

```bash
git add presets/nextjs-pnpm
git commit -m "feat: add nextjs-pnpm preset"
```

---

### Task 6: `scripts/new-project.sh` + teste

**Files:**
- Create: `/home/vitor/DEV/project-template/scripts/new-project.sh`
- Create: `/home/vitor/DEV/project-template/scripts/new-project.test.sh`

**Interfaces:**
- Consumes: `CORE_ITEMS=(CLAUDE.md AGENTS.md .editorconfig .gitignore .claude)` da Task 4 (caminhos relativos à raiz do template); diretório `presets/nextjs-pnpm/` da Task 5 (usado como preset de teste, excluindo `MANIFEST.md`).
- Produces: `new-project.sh /caminho/destino [--preset <nome>]` — script chamável por qualquer usuário do template; nenhuma outra task depende de seu comportamento interno além da CLI documentada no `README.md` (Task 7).

- [ ] **Step 1: Escrever o teste (vai falhar — o script ainda não existe)**

Conteúdo completo de `/home/vitor/DEV/project-template/scripts/new-project.test.sh`:

```bash
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
```

- [ ] **Step 2: Rodar o teste para confirmar que falha**

Run:
```bash
chmod +x /home/vitor/DEV/project-template/scripts/new-project.test.sh
/home/vitor/DEV/project-template/scripts/new-project.test.sh
```
Expected: falha porque `new-project.sh` não existe (`No such file or directory` ou erro de permissão), exit code != 0.

- [ ] **Step 3: Implementar `new-project.sh`**

Conteúdo completo de `/home/vitor/DEV/project-template/scripts/new-project.sh`:

```bash
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
```

- [ ] **Step 4: Rodar o teste para confirmar que passa**

Run:
```bash
chmod +x /home/vitor/DEV/project-template/scripts/new-project.sh
/home/vitor/DEV/project-template/scripts/new-project.test.sh
```
Expected: última linha impressa é `PASS`, exit code `0`.

- [ ] **Step 5: Commit**

```bash
git add scripts/new-project.sh scripts/new-project.test.sh
git commit -m "feat: add new-project.sh scaffold script with test"
```

---

### Task 7: `README.md` do template

**Files:**
- Create: `/home/vitor/DEV/project-template/README.md`

**Interfaces:**
- Consumes: nome do preset `nextjs-pnpm` (Task 5) e a CLI de `new-project.sh` (Task 6) — apenas para documentação, sem acoplamento de código.

- [ ] **Step 1: Escrever o arquivo**

```markdown
# project-template

Base reutilizável para novos projetos: tooling de IA (Claude Code) já configurado, mais presets opcionais de stack.

## O que já vem configurado globalmente

Antes mesmo de usar este repositório, os itens abaixo já se aplicam a qualquer projeto que você abrir no Claude Code, porque vivem em `~/.claude/`:

- `~/.claude/CLAUDE.md` — guidelines de comportamento (simplicidade, mudanças cirúrgicas, execução orientada a objetivo) e a diretiva de responder sempre em português do Brasil.
- `~/.claude/skills/no-auto-commits.md` — impede o Claude de rodar `git add/commit/push` em seu nome.
- `~/.claude/agents/simplicity-reviewer.md` — subagent de review focado em escopo e simplicidade.

Este repositório cobre o que **não** dá pra herdar globalmente: config por-projeto e boilerplate de stack.

## Como criar um projeto novo

```bash
~/DEV/project-template/scripts/new-project.sh /caminho/do/novo-projeto
# ou, com um preset de stack:
~/DEV/project-template/scripts/new-project.sh /caminho/do/novo-projeto --preset nextjs-pnpm
```

O script copia `CLAUDE.md`, `AGENTS.md`, `.editorconfig`, `.gitignore` e `.claude/settings.json` para o destino, substituindo `{{PROJECT_NAME}}` pelo nome da pasta. Se um preset for passado, os arquivos dele são copiados por cima. Nada de `git init` ou instalação de dependências é feito automaticamente — o script imprime os próximos passos manuais ao final.

Arquivos já existentes no destino nunca são sobrescritos (o script avisa e pula).

## Presets disponíveis

- **`nextjs-pnpm`** — Next.js + TypeScript + pnpm: lefthook, commitlint, semantic-release, CI de typecheck+testes. Veja `presets/nextjs-pnpm/MANIFEST.md` para os passos manuais depois de gerar o projeto.

## Adicionando um preset novo

Crie `presets/<nome>/` com os arquivos a copiar e um `MANIFEST.md` explicando o que o preset adiciona e quais passos manuais o dev ainda precisa rodar. `MANIFEST.md` nunca é copiado para o projeto gerado — fica como documentação de referência.

## Adicionando uma skill ou agent de projeto

Skills e agents específicos de um projeto (não universais o bastante pra ir em `~/.claude/`) entram em `.claude/skills/` e `.claude/agents/` dentro do próprio projeto gerado. Use a skill `superpowers:writing-skills` para criar skills novas seguindo o formato correto.
```

- [ ] **Step 2: Verificar**

Run: `test -f /home/vitor/DEV/project-template/README.md && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add template README"
```

---

### Task 8: Verificação final ponta a ponta

**Files:**
- Nenhum arquivo novo — apenas execução e checagem manual do que as Tasks 1–7 produziram.

**Interfaces:**
- Consumes: todos os artefatos das Tasks 1–7.

- [ ] **Step 1: Rodar a suíte do script mais uma vez, isolada**

Run: `/home/vitor/DEV/project-template/scripts/new-project.test.sh`
Expected: `PASS`

- [ ] **Step 2: Gerar um projeto de verdade num diretório descartável e inspecionar**

Run:
```bash
rm -rf /tmp/claude-1000/-home-vitor-DEV/27b3d6f3-fba5-4540-80f5-ab72af6bae30/scratchpad/exemplo-nextjs
/home/vitor/DEV/project-template/scripts/new-project.sh /tmp/claude-1000/-home-vitor-DEV/27b3d6f3-fba5-4540-80f5-ab72af6bae30/scratchpad/exemplo-nextjs --preset nextjs-pnpm
find /tmp/claude-1000/-home-vitor-DEV/27b3d6f3-fba5-4540-80f5-ab72af6bae30/scratchpad/exemplo-nextjs -type f | sort
```
Expected: lista incluindo `AGENTS.md`, `CLAUDE.md`, `.editorconfig`, `.gitignore`, `.claude/settings.json`, `.nvmrc`, `.releaserc.json`, `commitlint.config.js`, `lefthook.yml`, `.github/workflows/ci.yml`, `.env.example` — e **sem** `MANIFEST.md`.

- [ ] **Step 3: Confirmar que os arquivos globais estão ativos**

Run: `test -f /home/vitor/.claude/CLAUDE.md && test -f /home/vitor/.claude/skills/no-auto-commits.md && test -f /home/vitor/.claude/agents/simplicity-reviewer.md && echo OK`
Expected: `OK`

- [ ] **Step 4: Confirmar o histórico git do template**

Run: `cd /home/vitor/DEV/project-template && git log --oneline`
Expected: commits das Tasks 4, 5, 6 e 7 presentes, além do commit inicial da spec.

Nenhum commit é feito nesta task — é só verificação.
