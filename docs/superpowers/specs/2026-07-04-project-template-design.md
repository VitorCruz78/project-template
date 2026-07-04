# Design: base de projetos (config de IA global + repositório-template)

**Data:** 2026-07-04
**Status:** Aprovado

## Problema

Todo projeto novo do Vitor precisa da mesma configuração de tooling de IA (CLAUDE.md, skills, agents, settings do Claude Code) sendo montada do zero. O projeto `central` já evoluiu um bom conjunto de práticas (guidelines comportamentais, skill de não fazer commits automáticos, lefthook, commitlint, semantic-release, CI), mas isso nunca foi extraído para ser reaproveitado.

## Objetivo

Criar uma base reutilizável em duas camadas:

1. **Camada global** (`~/.claude/`) — o que deve valer em *todo* projeto automaticamente, sem copiar nada, porque o Claude Code já lê `~/.claude/CLAUDE.md`, `~/.claude/skills/` e `~/.claude/agents/` em qualquer diretório.
2. **Repositório-template** (`~/DEV/project-template`) — o que só faz sentido existir dentro de cada projeto individualmente (permissões do Claude Code do projeto, CI, git hooks, config de release), materializado via um script de scaffold.

Fora de escopo por agora: múltiplos presets de stack (só `nextjs-pnpm` nesta v1), publicação no GitHub como template repository (fica a critério do usuário depois), automação de `git init`/instalação de dependências pelo script.

## Camada global (`~/.claude/`)

### `~/.claude/CLAUDE.md`

Guidelines comportamentais herdadas do `central` (pensar antes de codar, simplicidade first, mudanças cirúrgicas, execução orientada a objetivo/critério de sucesso verificável), mais a diretiva de idioma: responder sempre em português do Brasil, exceto quando o prompt pedir explicitamente outro idioma. Aplica-se a toda sessão do Claude Code, em qualquer diretório.

### `~/.claude/skills/no-auto-commits.md`

Cópia integral da skill homônima do `central`. Garante que nenhum comando de escrita em git (`add`, `commit`, `push`, `commit --amend`, `push --force`, `reset` para reescrever histórico, `rebase`, criação de `tag`, `stash` de escrita) seja executado em nome do desenvolvedor — o Claude sempre imprime os comandos para o dev rodar.

### `~/.claude/agents/code-reviewer.md`

Subagent novo. Revisa diffs pela ótica das guidelines de simplicidade/escopo do CLAUDE.md global — não duplica o que a skill `code-review` de terceiros já cobre (bugs, segurança); foca em over-engineering, abstrações prematuras, mudanças fora de escopo e código que poderia ser mais simples.

## Repositório-template (`~/DEV/project-template`)

```
project-template/
├── README.md
├── CLAUDE.md                        # @AGENTS.md
├── AGENTS.md                        # esqueleto: Stack / Comandos / Arquitetura / Docs
├── .editorconfig
├── .gitignore
├── .claude/
│   └── settings.json                # allowlist só de comandos de leitura
├── scripts/
│   └── new-project.sh
└── presets/
    └── nextjs-pnpm/
        ├── MANIFEST.md
        ├── .nvmrc
        ├── .releaserc.json
        ├── commitlint.config.js
        ├── lefthook.yml
        ├── .github/workflows/ci.yml
        └── .env.example
```

### Core (sempre copiado)

- **`AGENTS.md`**: esqueleto com seções `## Stack`, `## Comandos`, `## Arquitetura`, `## Documentação adicional`, todas com placeholders a preencher pelo dev ao iniciar o projeto. Não repete as guidelines comportamentais (isso já vem da camada global) — só contexto específico do projeto.
- **`CLAUDE.md`**: uma linha, `@AGENTS.md`, mesmo padrão já usado no `chatbase`. Mantém `AGENTS.md` como fonte única, legível também por Codex/Cursor.
- **`.claude/settings.json`**: allowlist de permissões cobrindo apenas comandos de leitura comuns (`git status`, `git diff`, `git log`, `git show`, `ls`, `find`, `grep`/`rg`, rodar suite de testes). Nada de escrita liberada por padrão — o dev libera o resto conforme o uso real do projeto.
- **`.editorconfig`**, **`.gitignore`**: genéricos (indentação, `node_modules/`, `.env`, `coverage/`, `.DS_Store`, etc.).
- **`README.md`**: explica como rodar `scripts/new-project.sh`, o que a camada global já cobre, e como adicionar presets novos no futuro.

### Preset `nextjs-pnpm` (opcional, via `--preset`)

Espelha o setup do `central`, mas genérico (sem serviços específicos como Postgres/pgvector/Redis do CI do `central` — isso fica a cargo de cada projeto estender):

- `.nvmrc` (Node LTS mais recente disponível no momento da criação do preset)
- `.releaserc.json` — semantic-release com changelog + git + github plugins, `npmPublish: false`
- `commitlint.config.js` — `@commitlint/config-conventional`
- `lefthook.yml` — pre-commit com typecheck (`tsc --noEmit`) e testes; commit-msg com commitlint
- `.github/workflows/ci.yml` — checkout, setup pnpm/node via `.nvmrc`, install `--frozen-lockfile`, typecheck, testes
- `.env.example` — vazio/esqueleto com comentário explicando o padrão
- `MANIFEST.md` — lista o que este preset adiciona/sobrescreve em relação ao core, e os passos manuais que o dev ainda precisa fazer (ex: `pnpm add -D lefthook commitlint ... && pnpm exec lefthook install`)

### `scripts/new-project.sh`

Uso: `./scripts/new-project.sh /caminho/do/novo-projeto [--preset nextjs-pnpm]`

Comportamento:
1. Valida que o diretório destino existe (ou cria, se não existir) e não sobrescreve arquivos já presentes sem avisar.
2. Copia todos os arquivos do core para o destino.
3. Se `--preset <nome>` for passado, copia por cima os arquivos de `presets/<nome>/`.
4. Substitui o placeholder `{{PROJECT_NAME}}` (usado em `AGENTS.md` e possivelmente em `package.json` do preset) pelo nome da pasta destino.
5. **Não** roda `git init`, não instala dependências, não executa nenhum comando de escrita em git — apenas materializa arquivos. Ao final, imprime um resumo dos próximos passos manuais (git init, instalar deps do preset, rodar `lefthook install` se aplicável).

Essa restrição segue a mesma filosofia da skill `no-auto-commits`: a ferramenta prepara o terreno, o dev decide e executa as ações que afetam git/dependências.

## Fora de escopo (decisões explícitas)

- Múltiplos presets (Vite, Python etc.) — adicionar depois seguindo o mesmo padrão de pasta em `presets/`.
- Publicação do repositório no GitHub como template repository — decisão e ação do usuário, não automatizada aqui.
- `.claude/settings.json` do template com permissões de escrita/instalação — fica só leitura nesta v1.
