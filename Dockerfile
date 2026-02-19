FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    xz-utils \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js LTS (detect architecture)
ARG NODE_VERSION=20.18.1
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "arm64" ]; then NODE_ARCH="linux-arm64"; else NODE_ARCH="linux-x64"; fi && \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-${NODE_ARCH}.tar.xz" \
    | tar -xJ -C /usr/local --strip-components=1

# Install Databricks CLI (latest, detect architecture)
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "arm64" ]; then CLI_ARCH="linux_arm64"; else CLI_ARCH="linux_amd64"; fi && \
    TAG=$(curl -s https://api.github.com/repos/databricks/cli/releases/latest | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])") && \
    VERSION=${TAG#v} && \
    curl -fsSL "https://github.com/databricks/cli/releases/download/${TAG}/databricks_cli_${VERSION}_${CLI_ARCH}.zip" -o /tmp/databricks.zip && \
    unzip /tmp/databricks.zip -d /usr/local/bin/ && \
    rm /tmp/databricks.zip

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Install AI Dev Kit and Python dependencies
RUN pip install --no-cache-dir databricks-sdk python-dotenv anthropic openai pydantic && \
    curl -fsSL https://github.com/databricks-solutions/ai-dev-kit/archive/refs/heads/main.zip -o /tmp/ai-dev-kit.zip && \
    unzip /tmp/ai-dev-kit.zip -d /tmp/ai-dev-kit-extract && \
    pip install --no-cache-dir /tmp/ai-dev-kit-extract/ai-dev-kit-main/databricks-tools-core && \
    pip install --no-cache-dir /tmp/ai-dev-kit-extract/ai-dev-kit-main/databricks-mcp-server && \
    mkdir -p /home/dev/.ai-dev-kit && \
    cp -r /tmp/ai-dev-kit-extract/ai-dev-kit-main/. /home/dev/.ai-dev-kit/ && \
    rm -rf /tmp/ai-dev-kit.zip /tmp/ai-dev-kit-extract

# Set up project directory with skills and MCP config
RUN mkdir -p /home/dev/my-databricks-project/.claude/skills && \
    cp -r /home/dev/.ai-dev-kit/.claude/skills/. /home/dev/my-databricks-project/.claude/skills/ && \
    python3 -c "import json; json.dump({'mcpServers': {'databricks': {'command': 'python', 'args': ['-m', 'databricks_mcp_server'], 'env': {'DATABRICKS_CONFIG_PROFILE': 'my-workspace'}}}}, open('/home/dev/my-databricks-project/.mcp.json', 'w'), indent=2)"

WORKDIR /home/dev/my-databricks-project

# Credentials are mounted at runtime, not baked in:
#   -v %USERPROFILE%\.databrickscfg:/home/dev/.databrickscfg
#   -v %USERPROFILE%\.env:/home/dev/my-databricks-project/.env
ENV HOME=/home/dev

CMD ["claude"]
