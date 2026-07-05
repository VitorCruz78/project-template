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
