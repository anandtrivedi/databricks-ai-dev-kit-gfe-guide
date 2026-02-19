# Container Install

Run the full AI Dev Kit environment in a container — nothing to install on the GFE machine except Docker.

> **Status:** The container image builds and has been tested on macOS. The Linux container runs identically on Windows Docker Desktop (via WSL2). The Windows commands below have not yet been validated on GFE.

## Prerequisites

IT must provision one of the following on the GFE machine:
- **Docker Desktop** (runs Linux containers on Windows via WSL2)
- **Podman Desktop** (rootless alternative)

You will need from your Databricks admin:
- Workspace URL (e.g., `https://your-workspace.cloud.databricks.com`)
- Claude serving endpoint name (e.g., `anthropic`)
- Personal Access Token (PAT)

## Build the image

On a machine with internet access (done once by an admin or on a build machine):

```
docker build -t ai-dev-kit .
```

### Air-gapped transfer

To move the image to a GFE machine without internet:

```
docker save ai-dev-kit | gzip > ai-dev-kit.tar.gz
```

Copy `ai-dev-kit.tar.gz` to the GFE machine, then load it:

```
docker load < ai-dev-kit.tar.gz
```

## Configure

### 1. Create Databricks CLI profile

Open PowerShell and run (replace with your actual values):

```powershell
@"
[my-workspace]
host  = https://your-workspace.cloud.databricks.com
token = dapi...
"@ | Out-File -FilePath "$env:USERPROFILE\.databrickscfg" -Encoding ASCII
```

### 2. Create environment file

```powershell
@"
ANTHROPIC_MODEL=databricks-claude-sonnet-4-5
ANTHROPIC_BASE_URL=https://your-workspace.cloud.databricks.com/serving-endpoints/anthropic
ANTHROPIC_AUTH_TOKEN=dapi...
CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1
"@ | Out-File -FilePath "$env:USERPROFILE\.claude-env" -Encoding ASCII
```

Replace `your-workspace.cloud.databricks.com` with your workspace URL, `anthropic` with your endpoint name, and `dapi...` with your PAT.

## Run

### From PowerShell

```powershell
docker run -it --rm `
  --env-file "$env:USERPROFILE\.claude-env" `
  -v "$env:USERPROFILE\.databrickscfg:/home/dev/.databrickscfg:ro" `
  ai-dev-kit
```

### From Command Prompt (cmd.exe)

```
docker run -it --rm ^
  --env-file %USERPROFILE%\.claude-env ^
  -v %USERPROFILE%\.databrickscfg:/home/dev/.databrickscfg:ro ^
  ai-dev-kit
```

This starts Claude Code in an interactive terminal with:
- All AI Dev Kit skills loaded
- Databricks MCP server configured
- Python, Node.js, Git, and Databricks CLI available

### Non-interactive mode

Run a single prompt without entering the interactive session:

```powershell
docker run --rm `
  --env-file "$env:USERPROFILE\.claude-env" `
  -v "$env:USERPROFILE\.databrickscfg:/home/dev/.databrickscfg:ro" `
  ai-dev-kit `
  claude -p "list my Databricks clusters"
```

## What's in the container

| Tool | Details |
|------|---------|
| Python | 3.11 |
| Node.js | 20.18.1 |
| Git | latest |
| Databricks CLI | latest |
| Claude Code | latest |
| AI Dev Kit | Skills + MCP server |
| Image size | ~1.3 GB |

No internet access is needed at runtime — everything is baked into the image.

## Updating

Rebuild the image to pick up the latest Claude Code and AI Dev Kit:

```
docker build --no-cache -t ai-dev-kit .
```

Then re-export with `docker save` if distributing to air-gapped machines.

## Troubleshooting

### `x-anthropic-billing-header` error

This is a known Claude Code bug where a billing header is injected into the system prompt. The Dockerfile includes a workaround (`CLAUDE_CODE_ATTRIBUTION_HEADER=0`). If you see this error, rebuild the image to get the fix.

### Container can't reach Databricks

If running behind a proxy, pass proxy settings to the container:

```powershell
docker run -it --rm `
  --env-file "$env:USERPROFILE\.claude-env" `
  -e HTTPS_PROXY=http://proxy.example.com:8080 `
  -v "$env:USERPROFILE\.databrickscfg:/home/dev/.databrickscfg:ro" `
  ai-dev-kit
```

### Encoding issues with env file

If Claude Code fails to read the environment file, verify it's ASCII/UTF-8 (not UTF-16):

```powershell
Get-Content "$env:USERPROFILE\.claude-env" -Encoding Byte | Select-Object -First 4
```

If the first two bytes are `255 254` (BOM), recreate the file with `-Encoding ASCII`.
