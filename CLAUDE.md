# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Docker image for [KASM Workspaces](https://kasmweb.com) — a fully equipped containerised development environment built on `kasmweb/ubuntu-jammy-desktop:1.19.0`. The image is published to `ghcr.io/bosund/kasm-dev:latest`.

There is no application code or test suite. The "build" is a Docker image built by GitHub Actions.

## Building locally

```bash
docker build -t kasm-dev:local .
```

To smoke-test the image:

```bash
docker run --rm -it kasm-dev:local bash
```

## CI/CD — GitHub Actions

`.github/workflows/build.yml` builds and pushes the image to GHCR on:
- Push to `main` when `Dockerfile`, `startup/**`, or the workflow file changes
- Weekly schedule — every Monday at 04:00 UTC
- Manual trigger via `workflow_dispatch`

Tags produced per build: `latest`, `YYYY-MM-DD` (date of scheduled build), `sha-<commit>`.

To trigger a rebuild without a code change, use **Actions → Run workflow** in the GitHub UI.

## Architecture

```
Dockerfile              — single-stage image definition; all tools installed as root, final USER 1000
startup/
  custom_startup.sh     — runs at every KASM session start (not at build time)
.github/workflows/
  build.yml             — build & push to ghcr.io via docker/build-push-action
```

### Dockerfile layer order

1. Base OS packages (apt)
2. yq, Node.js 22, Python 3.13, GitHub CLI, VS Code
3. Claude Code CLI, Coolify CLI, Vercel CLI, Supabase CLI, Tailscale, Docker CLI
4. pnpm, lazygit
5. Global npm packages + MCP servers (`@upstash/context7-mcp`, `@masonator/coolify-mcp`, `@modelcontextprotocol/server-sequential-thinking`, `@neondatabase/mcp-server`, `@supabase/mcp-server-supabase`)
6. zsh + oh-my-zsh
7. Copies `startup/custom_startup.sh` → `/dockerstartup/custom_startup.sh`
8. Ownership fixup; switches to UID 1000

### Startup script (`startup/custom_startup.sh`)

Runs as UID 1000 at each session start. It:
- Installs VS Code extensions (GitHub Copilot, Copilot Chat, Claude Code) — idempotent
- Appends `ANTHROPIC_API_KEY` to `.zshrc`/`.bashrc` if set as a KASM env-var and not already present
- Prints a first-time MCP setup guide if `~/.claude/mcp.json` does not exist

MCP configuration is written to `~/.claude/mcp.json` (inside the persistent profile) and survives session restarts.

## Required KASM environment variables

| Variable | Purpose |
|---|---|
| `ANTHROPIC_API_KEY` | Claude Code CLI authentication |
| `COOLIFY_BASE_URL` | Coolify instance URL |
| `COOLIFY_ACCESS_TOKEN` | Coolify API token |

## Image versioning

To pin to a specific build, use the date tag (`ghcr.io/bosund/kasm-dev:2026-06-02`) or the commit SHA tag instead of `latest`.

KASM picks up the new `latest` image on the next session start after you re-save the workspace in the admin panel.
