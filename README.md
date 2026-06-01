# KASM Development Environment

A full-featured containerized development environment for [KASM Workspaces](https://kasmweb.com), built on Ubuntu Jammy desktop. The image is automatically rebuilt every Monday via GitHub Actions and published to GitHub Container Registry.

## What's Included

| Category | Tools |
|----------|-------|
| **IDE** | VS Code, Antigravity 2.0 (Google's VS Code fork) |
| **AI Coding** | Claude Code CLI + VS Code extension, GitHub Copilot + Copilot Chat, Antigravity CLI |
| **Runtime** | Node.js 22, Python 3.13, pnpm |
| **Deployment CLI** | Vercel CLI, Supabase CLI, Coolify CLI, Docker CLI |
| **Version Control** | GitHub CLI (`gh`), lazygit |
| **Database** | PostgreSQL client (`psql`) |
| **Networking** | Tailscale, OpenSSH client, netcat |
| **Terminal** | zsh + oh-my-zsh, tmux, ripgrep, fzf, vim, yq, make |
| **MCP Servers** | context7, coolify (pre-installed npm packages) |

MCP server configuration is saved to persistent storage and survives session restarts.

---

## Prerequisites

- A running [KASM Workspaces](https://kasmweb.com) instance
- Access to the KASM Admin Panel
- A GitHub account (to fork this repo and use the automatic builds)

---

## Step 1 — Fork and configure the repository on GitHub

### 1a. Fork this repository

Click **Fork** in the top-right corner of this page. This creates your own copy of the repo under your GitHub account.

### 1b. Configure the Coolify domain (optional)

If you use [Coolify](https://coolify.io) for deployments, set your Coolify base URL as a GitHub Actions variable so it can be referenced in documentation:

1. Go to your forked repo → **Settings** → **Secrets and variables** → **Actions** → **Variables** tab
2. Click **New repository variable**
3. Name: `COOLIFY_BASE_URL`, Value: `https://your-coolify-domain.com`

> This is optional and only affects documentation. The actual value is set later in KASM's environment variables.

### 1c. Wait for the first build to complete

After forking, GitHub Actions automatically triggers the first build. You can monitor it under the **Actions** tab. The build takes approximately 20–30 minutes.

Once the build is green, your image is available at:
```
ghcr.io/<your-github-username>/kasm-dev:latest
```

The image is automatically rebuilt **every Monday at 04:00 UTC** to pick up package updates. You can also trigger a manual build anytime under **Actions → Build KASM Image → Run workflow**.

---

## Step 2 — Register the workspace in KASM Admin

1. Log in to your **KASM Admin Panel**
2. Go to **Workspaces** → **Add Workspace**
3. Fill in the fields:

| Field | Value |
|-------|-------|
| Workspace Type | Desktop |
| Friendly Name | Development Environment |
| Description | Ubuntu + VS Code + Antigravity + Claude Code |
| Docker Image | `ghcr.io/<your-github-username>/kasm-dev:latest` |
| Cores | 4 |
| Memory (MB) | 8192 |

4. Under **Advanced** → **Docker Run Config Override**, paste:

```json
{
  "network_mode": "host"
}
```

> This gives **only this workspace** full host network access — enabling SSH to other containers, connections to local databases, Tailscale, etc. All other KASM workspaces remain on the default network.

5. Click **Save**

---

## Step 3 — Enable Persistent Profile

Persistent profiles ensure your Claude Code configuration, MCP servers, VS Code extensions, and shell settings survive session restarts.

1. Create the profile directory on the KASM host machine:

```bash
sudo mkdir -p /mnt/kasm_profiles
sudo chmod 777 /mnt/kasm_profiles
```

2. Go to **Workspaces** → find "Development Environment" → **Edit**
3. Under **Persistent Profile**:

| Field | Value |
|-------|-------|
| Persistent Profile Path | `/mnt/kasm_profiles/{username}` |
| Max Profile Size (MB) | 10240 |

4. Click **Save**

---

## Step 4 — Set environment variables

1. Go to **Workspaces** → **Edit** → **Environment**
2. Add the following variables:

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Your Anthropic API key for Claude Code |
| `COOLIFY_BASE_URL` | Your Coolify instance URL, e.g. `https://coolify.example.com` |
| `COOLIFY_ACCESS_TOKEN` | Your Coolify API access token |

3. Click **Save**

---

## Step 5 — First launch and MCP setup

1. Launch a session from the KASM user panel
2. On first launch, the terminal displays a setup guide:

```
╔══════════════════════════════════════════════════════════════════╗
║           FIRST TIME — CONFIGURE MCP SERVERS                    ║
╚══════════════════════════════════════════════════════════════════╝
```

3. Run the following commands in the terminal to configure MCP servers:

```bash
# Context7 — library and framework documentation
claude mcp add context7 -- npx -y @upstash/context7-mcp

# Coolify — deployment management
claude mcp add coolify -- npx -y @masonator/coolify-mcp \
  -e COOLIFY_BASE_URL=$COOLIFY_BASE_URL \
  -e COOLIFY_ACCESS_TOKEN=<your-token>

# CVR MCP — Danish business register (adjust command to your setup)
claude mcp add cvr -- <command>
```

4. The configuration is saved to `~/.claude/mcp.json` and persists across sessions automatically.

---

## Verification

After setup, verify everything is working:

```bash
# Check installed versions
node -v              # v22.x.x
python3 --version    # Python 3.13.x
gh --version
claude --version
antigravity --version
vercel --version
supabase --version
docker --version

# Test network access (host network mode)
ping <container-ip>
ssh user@<container-hostname>
psql postgresql://localhost:5433/<database>

# Test Claude Code MCP connections
claude
# Then run: /mcp — all configured servers should show "connected"
```

---

## Automatic Weekly Builds

The GitHub Actions workflow (`.github/workflows/build.yml`) rebuilds the image every Monday. This ensures you always get:
- Latest security patches from Ubuntu
- Updated npm packages (Claude Code, Vercel CLI, etc.)
- Updated apt packages (VS Code, GitHub CLI, etc.)

Each build is tagged with `latest`, the build date (e.g. `2025-06-02`), and the commit SHA, so you can pin to a specific version if needed.

To update your running KASM workspace to the latest image, go to **Workspaces** → **Edit** → save without changes. KASM will pull the new `latest` image on the next session start.

---

## Notes

- **Antigravity IDE**: The Dockerfile downloads the Antigravity `.deb` from `https://antigravity.google/download`. If a build fails on that step, verify the current Linux download URL and update `Dockerfile` accordingly.
- **VS Code extensions** (GitHub Copilot, Claude Code) are installed on first session start via `startup/custom_startup.sh`. They are stored in the persistent profile and do not reinstall on subsequent sessions.
- **Docker socket**: The Docker CLI is installed but the Docker socket (`/var/run/docker.sock`) must be mounted separately if you need to manage containers from within the workspace.
