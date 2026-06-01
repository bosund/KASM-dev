FROM kasmweb/ubuntu-jammy-desktop:1.18.1
USER root

ENV HOME /home/kasm-default-profile
ENV STARTUPDIR /dockerstartup
ENV INST_SCRIPTS $STARTUPDIR/install
WORKDIR $HOME

######### System packages #########
RUN apt-get update && apt-get install -y \
    curl wget git build-essential unzip zip jq \
    software-properties-common apt-transport-https \
    ca-certificates gnupg lsb-release \
    openssh-client iputils-ping dnsutils netcat-openbsd \
    tmux zsh ripgrep fzf make vim \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

######### yq (YAML processor) #########
RUN wget -qO /usr/local/bin/yq \
      "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" \
    && chmod +x /usr/local/bin/yq

######### Node.js 22 #########
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

######### Python 3.13 #########
RUN add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update \
    && apt-get install -y python3.13 python3.13-venv python3.13-dev python3-pip \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.13 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.13 1 \
    && rm -rf /var/lib/apt/lists/*

######### GitHub CLI #########
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

######### VS Code #########
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor > /etc/apt/trusted.gpg.d/packages.microsoft.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
      > /etc/apt/sources.list.d/vscode.list \
    && apt-get update && apt-get install -y code \
    && rm -rf /var/lib/apt/lists/*

######### Claude Code CLI #########
RUN npm install -g @anthropic-ai/claude-code

######### Coolify CLI #########
RUN curl -fsSL https://cdn.coolify.io/cli/install.sh | bash 2>/dev/null || true

######### Vercel CLI #########
RUN npm install -g vercel

######### Supabase CLI #########
RUN SUPABASE_VERSION=$(curl -s https://api.github.com/repos/supabase/cli/releases/latest | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/') \
    && wget -qO /tmp/supabase.deb \
       "https://github.com/supabase/cli/releases/latest/download/supabase_${SUPABASE_VERSION}_linux_amd64.deb" \
    && dpkg -i /tmp/supabase.deb \
    && rm -f /tmp/supabase.deb

######### Tailscale #########
RUN curl -fsSL https://tailscale.com/install.sh | sh

######### Docker CLI #########
RUN curl -fsSL https://get.docker.com | sh

######### pnpm #########
RUN npm install -g pnpm

######### lazygit #########
RUN LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
      | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/') \
    && curl -Lo /tmp/lazygit.tar.gz \
       "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
    && tar -C /usr/local/bin -xzf /tmp/lazygit.tar.gz lazygit \
    && rm -f /tmp/lazygit.tar.gz

######### Globale npm-pakker & MCP-servere #########
RUN npm install -g yarn npm-check-updates serve typescript ts-node \
    @upstash/context7-mcp @masonator/coolify-mcp gitnexus \
    @modelcontextprotocol/server-sequential-thinking @neondatabase/mcp-server \
    @supabase/mcp-server-supabase

######### zsh + oh-my-zsh i default-profil #########
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

######### Startup-script #########
COPY startup/custom_startup.sh $STARTUPDIR/custom_startup.sh
RUN chmod +x $STARTUPDIR/custom_startup.sh

######### KASM afslutning #########
RUN chown 1000:0 $HOME
RUN $STARTUPDIR/set_user_permission.sh $HOME

ENV HOME /home/kasm-user
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R 1000:0 $HOME

USER 1000
