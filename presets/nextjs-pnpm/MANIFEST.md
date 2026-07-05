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
