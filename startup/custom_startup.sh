#!/bin/bash
# Kører ved hver KASM session-start som bruger 1000

# VS Code extensions (idempotent — springer over hvis allerede installeret)
code --install-extension GitHub.copilot --force 2>/dev/null &
code --install-extension GitHub.copilot-chat --force 2>/dev/null &
code --install-extension anthropics.claude-code --force 2>/dev/null &

# Sæt ANTHROPIC_API_KEY i shell hvis sat som KASM env-var
if [ -n "$ANTHROPIC_API_KEY" ] && ! grep -q "ANTHROPIC_API_KEY" "$HOME/.zshrc" 2>/dev/null; then
    echo "export ANTHROPIC_API_KEY=\"$ANTHROPIC_API_KEY\"" >> "$HOME/.zshrc"
    echo "export ANTHROPIC_API_KEY=\"$ANTHROPIC_API_KEY\"" >> "$HOME/.bashrc"
fi

# Vis første-gangs vejledning hvis MCP endnu ikke er konfigureret
if [ ! -f "$HOME/.claude/mcp.json" ]; then
    mkdir -p "$HOME/.claude"
    cat << 'EOF'

╔══════════════════════════════════════════════════════════════════╗
║           FØRSTE GANG — KONFIGURÉR MCP SERVERE                  ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  Kør følgende kommandoer i terminalen:                           ║
║                                                                  ║
║  1. Context7 (dokumentation):                                    ║
║     claude mcp add context7 -- npx -y @upstash/context7-mcp     ║
║                                                                  ║
║  2. Coolify (deployment):                                        ║
║     claude mcp add coolify -- npx -y @masonator/coolify-mcp \   ║
║       -e COOLIFY_BASE_URL=$COOLIFY_BASE_URL \                    ║
║       -e COOLIFY_ACCESS_TOKEN=<din-token>                        ║
║                                                                  ║
║  3. CVR-MCP (virksomhedsregister):                               ║
║     claude mcp add cvr -- <kommando til cvr-mcp>                 ║
║                                                                  ║
║  Konfigurationen gemmes i ~/.claude/mcp.json                     ║
║  og overlever fremtidige sessioner automatisk.                   ║
║                                                                  ║
║  Se INSTALL.md for fuld vejledning.                              ║
╚══════════════════════════════════════════════════════════════════╝

EOF
fi

wait
