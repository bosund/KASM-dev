# KASM Development Environment

[![Build KASM Image](https://github.com/bosund/KASM-dev/actions/workflows/build.yml/badge.svg)](https://github.com/bosund/KASM-dev/actions/workflows/build.yml)

Et fuldt udstyret containeriseret udviklingsmiljø til [KASM Workspaces](https://kasmweb.com), bygget på Ubuntu Jammy desktop. Imaget genbygges automatisk hver mandag via GitHub Actions og publiceres til GitHub Container Registry.

```
ghcr.io/bosund/kasm-dev:latest
```

## Hvad er inkluderet

| Kategori | Værktøjer |
|----------|-----------|
| **IDE** | VS Code |
| **AI Coding** | Claude Code CLI + VS Code extension, GitHub Copilot + Copilot Chat |
| **Runtime** | Node.js 24, Python 3.14, pnpm |
| **Deployment CLI** | Vercel CLI, Supabase CLI, Coolify CLI, Docker CLI |
| **Versionsstyring** | GitHub CLI (`gh`), lazygit |
| **Database** | PostgreSQL client (`psql`) |
| **Netværk** | Tailscale, OpenSSH client, netcat |
| **Terminal** | zsh + oh-my-zsh, tmux, ripgrep, fzf, vim, yq, make |
| **MCP Servere** | context7, coolify, sequential-thinking, neon, supabase |

MCP server-konfiguration gemmes i persistent storage og overlever session-genstarter.

---

## Forudsætninger

- En kørende [KASM Workspaces](https://kasmweb.com) instans
- Adgang til KASM Admin Panel

---

## Trin 1 — Registrér workspace i KASM Admin

1. Log ind på dit **KASM Admin Panel**
2. Gå til **Workspaces** → **Add Workspace**
3. Udfyld felterne:

| Felt | Værdi |
|------|-------|
| Workspace Type | Desktop |
| Friendly Name | Development Environment |
| Description | Ubuntu + VS Code + Claude Code |
| Docker Image | `ghcr.io/bosund/kasm-dev:latest` |
| Cores | 4 |
| Memory (MB) | 8192 |

4. Under **Advanced** → **Docker Run Config Override**, indsæt:

```json
{
  "network_mode": "host"
}
```

5. Klik **Save**

---

## Trin 2 — Aktiver Persistent Profil

1. Opret profil-mappen på KASM host-maskinen:

```bash
sudo mkdir -p /mnt/kasm_profiles
sudo chmod 777 /mnt/kasm_profiles
```

2. Gå til **Workspaces** → find "Development Environment" → **Edit**
3. Under **Persistent Profile**:

| Felt | Værdi |
|------|-------|
| Persistent Profile Path | `/mnt/kasm_profiles/{username}` |
| Max Profile Size (MB) | 10240 |

4. Klik **Save**

---

## Trin 3 — Sæt miljøvariabler

1. Gå til **Workspaces** → **Edit** → **Environment**
2. Tilføj følgende variabler:

| Variabel | Beskrivelse |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Din Anthropic API-nøgle til Claude Code |
| `COOLIFY_BASE_URL` | Din Coolify instans URL, fx `https://coolify.example.com` |
| `COOLIFY_ACCESS_TOKEN` | Dit Coolify API access token |

3. Klik **Save**

---

## Trin 4 — Første opstart og MCP-opsætning

1. Start en session fra KASM bruger-panelet
2. Ved første opstart vises en opsætningsvejledning i terminalen
3. Kør følgende kommandoer for at konfigurere MCP servere:

```bash
# Context7 — biblioteks- og framework-dokumentation
claude mcp add context7 -- npx -y @upstash/context7-mcp

# Coolify — deployment-styring
claude mcp add coolify -- npx -y @masonator/coolify-mcp \
  -e COOLIFY_BASE_URL=$COOLIFY_BASE_URL \
  -e COOLIFY_ACCESS_TOKEN=<din-token>
```

4. Konfigurationen gemmes i `~/.claude/mcp.json` og overlever sessioner automatisk.

---

## Automatiske ugentlige builds

GitHub Actions workflow'en (`.github/workflows/build.yml`) genbygger imaget hver mandag. Det sikrer:
- Seneste sikkerhedspatches fra Ubuntu
- Opdaterede npm-pakker (Claude Code, Vercel CLI osv.)
- Opdaterede apt-pakker (VS Code, GitHub CLI osv.)

Hvert build tagges med `latest`, byggedatoen (fx `2026-06-02`) og commit SHA — så du kan pinne til en specifik version.

For at opdatere dit kørende KASM workspace til det nyeste image: gå til **Workspaces** → **Edit** → gem uden ændringer. KASM henter det nye `latest` image ved næste session-start.

---

## Docker socket

Docker CLI er installeret, men Docker socket (`/var/run/docker.sock`) skal mountes separat hvis du vil styre containere inde fra workspace'et.
