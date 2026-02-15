# Databricks AI Dev Kit - GFE Setup Guide

**Complete installation guide for Government Field Engineering machines.**

This guide walks you through installing the [Databricks AI Dev Kit](https://github.com/databricks-solutions/ai-dev-kit) on Windows GFE machines. One linear path — if a step is blocked on your machine, inline fallbacks show you the alternative.

> **Upstream project:** All skills and MCP servers come from [databricks-solutions/ai-dev-kit](https://github.com/databricks-solutions/ai-dev-kit). This guide only covers GFE-specific installation steps.

> **Important:** This guide does not attempt to bypass or circumvent any security controls, network restrictions, or organizational policies. Always follow your organization's software approval and IT procedures before installing any tools. Verify that the software listed here (Node.js, Python, Git, Claude Code) is approved for use on your device, and confirm with your IT team that downloading from the referenced external sites is permitted.

---

# Quick Start

If your IT team has already installed Node.js, Python, Git, and Databricks CLI, verify they work:

```powershell
node --version && python --version && git --version && databricks --version
```

All four work? Skip to [Configure Databricks CLI](#configure-databricks-cli).

Any missing? Continue with [Full Setup](#full-setup) below.

---

# Full Setup

## (Optional) Download helper scripts

This repo includes helper scripts for proxy detection, environment setup, and launching Claude Code. If you can clone or download from GitHub:

```powershell
git clone https://github.com/anandtrivedi/databricks-ai-dev-kit-gfe-guide.git
```

> **Can't download?** That's fine — this guide works entirely from the browser. All commands can be typed or pasted directly into PowerShell. The helper scripts are optional convenience tools.

## Install prerequisites

### Verify Python

Python 3.11+ must be installed. Most GFE machines include Python.

```powershell
python --version
```

If Python is not available, request it through your IT team or download from https://www.python.org/downloads/.

### Locate your tools directory

For convenience, all tools install alongside your existing Python installation in the **user scripts directory** — the standard location where pip installs command-line tools, typically already on your system PATH.

```powershell
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
Write-Host "Tools directory: $TOOLS_DIR"
New-Item -ItemType Directory -Force -Path $TOOLS_DIR | Out-Null
cd $TOOLS_DIR

```

> **Tip:** On most GFE machines `$TOOLS_DIR` resolves to something like `C:\Users\<YourName>\AppData\Roaming\Python\Python313\Scripts`.

### Install Node.js

Check https://nodejs.org for the latest LTS version.

```powershell
$NODE_VERSION = "20.18.1"
python -c "import urllib.request; urllib.request.urlretrieve('https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-win-x64.zip', 'node.zip')"
Expand-Archive node.zip -DestinationPath . -Force
if (Test-Path "nodejs") { Remove-Item "nodejs" -Recurse -Force }
Rename-Item "node-v$NODE_VERSION-win-x64" "nodejs"
Remove-Item node.zip
Write-Host "Node.js installed" -ForegroundColor Green

```

### Install Git

Check https://github.com/git-for-windows/git/releases for the latest version. We use the `.tar.bz2` archive because `.7z.exe` self-extractors are blocked by Group Policy on many GFE machines.

Download Git:

```powershell
python -c "import urllib.request; print('Downloading Git...'); urllib.request.urlretrieve('https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.tar.bz2', 'git.tar.bz2'); print('Done.')"

```

> **If the download fails** with a connection error, wait a few seconds and re-run the command.

Extract (this takes several minutes — be patient):

```powershell
python -c "import tarfile; print('Extracting Git (this takes a few minutes)...'); tarfile.open('git.tar.bz2').extractall('git'); print('Done.')"
Remove-Item git.tar.bz2
Write-Host "Git installed" -ForegroundColor Green

```

### Install Databricks CLI

Check https://github.com/databricks/cli/releases for the latest version.

```powershell
python -c "import urllib.request; r=urllib.request.urlopen('https://github.com/databricks/cli/releases/latest/download/databricks_cli_windows_amd64.zip'); open('databricks.zip','wb').write(r.read()); print('Downloaded',r.url)"
Expand-Archive databricks.zip -DestinationPath "databricks" -Force
Remove-Item databricks.zip
Write-Host "Databricks CLI installed" -ForegroundColor Green

```

> **If any download or execution is blocked by Group Policy**, request the tools from your IT team. See [For IT Teams](#for-it-teams).

### Update PATH

Add all three tools to your user PATH so they are available in new PowerShell sessions:

```powershell
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
$newPaths = @("$TOOLS_DIR\nodejs", "$TOOLS_DIR\git\bin", "$TOOLS_DIR\databricks")
$userPath = (Get-ItemProperty "HKCU:\Environment").Path
foreach ($p in $newPaths) {
    if ($userPath -notlike "*$p*") { $userPath += ";$p" }
}
setx PATH "$userPath"
Write-Host "PATH updated — close and reopen PowerShell to use the new paths" -ForegroundColor Green

```

### Verify all prerequisites

**Close and reopen PowerShell**, then verify:

```powershell
node --version
npm --version
git --version
databricks --version
```

All four should print version numbers. If any fail, see [Troubleshooting](#troubleshooting).

---

## Configure Databricks CLI

```powershell
"[my-workspace]", "host  = https://your-workspace.cloud.databricks.com", "token = dapi1234567890abcdef..." | Out-File "$env:USERPROFILE\.databrickscfg" -Encoding ASCII

```

Replace with your actual workspace URL and token from your Databricks administrator.

Verify:

```powershell
databricks --profile my-workspace current-user me
```

---

## Install Claude Code

```powershell
npm install -g @anthropic-ai/claude-code
```

Verify:

```powershell
claude --version
```

> **If npm is blocked:** Download the package directly and install from the local file:
>
> ```powershell
> # Check https://www.npmjs.com/package/@anthropic-ai/claude-code for latest version
> $VERSION = "1.0.24"
> python -c "import urllib.request; urllib.request.urlretrieve('https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-$VERSION.tgz', 'claude-code.tgz')"
> npm install -g claude-code.tgz
> Remove-Item claude-code.tgz
> claude --version
> ```

---

## Install AI Dev Kit

```powershell
# Create project directory
$PROJECT_DIR = "$env:USERPROFILE\my-databricks-project"
New-Item -ItemType Directory -Force -Path $PROJECT_DIR
cd $PROJECT_DIR

# Download and run the installer (requires bash from Git installation)
bash -c "curl -sL https://raw.githubusercontent.com/databricks-solutions/ai-dev-kit/main/install.sh -o install.sh && bash install.sh"

```

When prompted:
1. **Select tools** → `Claude Code`
2. **Select profile** → `my-workspace`
3. **Select scope** → `Project`

### If the installer fails

If `raw.githubusercontent.com` is blocked or `bash` is not available, install manually:

```powershell
$PROJECT_DIR = "$env:USERPROFILE\my-databricks-project"
New-Item -ItemType Directory -Force -Path $PROJECT_DIR
cd $PROJECT_DIR

# Download AI Dev Kit zip
python -c "import urllib.request; urllib.request.urlretrieve('https://github.com/databricks-solutions/ai-dev-kit/archive/refs/heads/main.zip', 'ai-dev-kit.zip')"

# Extract
Expand-Archive ai-dev-kit.zip -DestinationPath "$env:TEMP\ai-dev-kit-extract" -Force

# Copy skills to project
$extracted = Get-ChildItem "$env:TEMP\ai-dev-kit-extract" -Directory | Select-Object -First 1
$targetSkills = "$PROJECT_DIR\.claude\skills"
New-Item -ItemType Directory -Force -Path $targetSkills
Copy-Item "$($extracted.FullName)\skills\*" -Destination $targetSkills -Recurse -Force

# Copy MCP server files
$aiDevKitDir = "$env:USERPROFILE\.ai-dev-kit"
New-Item -ItemType Directory -Force -Path $aiDevKitDir
Copy-Item "$($extracted.FullName)\*" -Destination $aiDevKitDir -Recurse -Force

# Cleanup
Remove-Item "$env:TEMP\ai-dev-kit-extract" -Recurse -Force
Remove-Item "ai-dev-kit.zip"

Write-Host "AI Dev Kit installed" -ForegroundColor Green

```

Install Python dependencies:

```powershell
pip install databricks-sdk python-dotenv anthropic openai pydantic

# Install the MCP server packages from the extracted AI Dev Kit
pip install "$env:USERPROFILE\.ai-dev-kit\databricks-tools-core"
pip install "$env:USERPROFILE\.ai-dev-kit\databricks-mcp-server"

```

> **If pip is also blocked**, download wheel files from https://pypi.org manually, then: `pip install --no-index --find-links=./packages databricks-sdk python-dotenv anthropic`

Create MCP config:

**If you have Databricks CLI configured with a profile:**

```powershell
python -c "import json; json.dump({'mcpServers': {'databricks': {'command': 'python', 'args': ['-m', 'databricks_mcp_server'], 'env': {'DATABRICKS_CONFIG_PROFILE': 'my-workspace'}}}}, open('.mcp.json', 'w'), indent=2)"

```

**If Databricks CLI is not installed (use direct credentials instead):**

```powershell
python -c "import json; json.dump({'mcpServers': {'databricks': {'command': 'python', 'args': ['-m', 'databricks_mcp_server'], 'env': {'DATABRICKS_HOST': 'https://your-workspace.cloud.databricks.com', 'DATABRICKS_TOKEN': 'dapi1234567890abcdef...'}}}}, open('.mcp.json', 'w'), indent=2)"

```

> **Note:** Replace the host and token with your actual values. The direct credentials approach does not require the Databricks CLI to be installed.

---

# Configure and Launch

## Create your `.env` file

```powershell
cd "$env:USERPROFILE\my-databricks-project"
```

Create a `.env` file with your Databricks endpoint configuration. Replace the workspace URL, endpoint name, and PAT with your actual values from your Databricks administrator:

```powershell
# Auto-detect Git Bash path from the install above
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
$GIT_BASH = "$TOOLS_DIR\git\bin\bash.exe"

@"
# Databricks-managed Claude endpoint configuration
# Replace these three values with your actual workspace details
ANTHROPIC_MODEL=databricks-claude-sonnet-4-5
ANTHROPIC_BASE_URL=https://your-workspace.cloud.databricks.com/serving-endpoints/your-endpoint
ANTHROPIC_AUTH_TOKEN=dapi1234567890abcdef

# Required settings
ANTHROPIC_CUSTOM_HEADERS=x-databricks-use-coding-agent-mode: true
CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1

# Git Bash path (auto-detected from portable install)
CLAUDE_CODE_GIT_BASH_PATH=$GIT_BASH
"@ | Out-File -FilePath ".env" -Encoding UTF8

Write-Host "Created .env file — edit it with your actual workspace values:" -ForegroundColor Green
Write-Host "  notepad .env" -ForegroundColor Gray

```

## Create the launch script

Create `scripts\start.ps1` in your project directory. This script loads your `.env` file and starts Claude Code:

```powershell
$PROJECT_DIR = "$env:USERPROFILE\my-databricks-project"
New-Item -ItemType Directory -Force -Path "$PROJECT_DIR\scripts" | Out-Null

@'
# start.ps1 - Launch Claude Code with Databricks-managed Claude endpoint
$ErrorActionPreference = "Stop"

# Find .env file (check current dir, then parent dir)
$envFile = $null
if (Test-Path ".env") { $envFile = ".env" }
elseif (Test-Path "..\.env") { $envFile = "..\.env" }

if (-not $envFile) {
    Write-Host "Error: .env file not found." -ForegroundColor Red
    exit 1
}

# Load environment variables from .env
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        if ($line -match '^([^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim() -replace '^["'']|["'']$', ''
            Set-Item -Path "env:\$name" -Value $value
        }
    }
}

Write-Host "Starting Claude Code with Databricks AI Dev Kit..." -ForegroundColor Green
Write-Host "  Workspace: $env:ANTHROPIC_BASE_URL" -ForegroundColor Gray
Write-Host "  Model:     $env:ANTHROPIC_MODEL" -ForegroundColor Gray
if ($env:CLAUDE_CODE_GIT_BASH_PATH) {
    Write-Host "  Git Bash:  $env:CLAUDE_CODE_GIT_BASH_PATH" -ForegroundColor Gray
}
Write-Host ""
claude
'@ | Out-File -FilePath "$PROJECT_DIR\scripts\start.ps1" -Encoding UTF8
Write-Host "Launch script created" -ForegroundColor Green

```

> **If you downloaded the helper scripts** from GitHub earlier, you can skip this step — just copy them into your project: `Copy-Item ".\scripts" -Destination "$PROJECT_DIR\scripts" -Recurse -Force`

## Launch Claude Code

```powershell
cd "$env:USERPROFILE\my-databricks-project"
PowerShell -ExecutionPolicy Bypass -File .\scripts\start.ps1
```

Test it by asking:

```
List my SQL warehouses
```

---

# Troubleshooting

## "Access denied" downloading from official sites

**Cause:** Downloads from nodejs.org, git-scm.com, etc. are blocked.

**Fix:** Request the tools from your IT team (see [For IT Teams](#for-it-teams)), or see [Alternative: Internal hosting](#alternative-host-installation-bundle-internally).

## npm install fails with ECONNREFUSED

**Cause:** npm registry (registry.npmjs.org) is blocked.

**Fix:** Use the manual download fallback in [Install Claude Code](#install-claude-code).

## curl / bash installer fails

**Cause:** GitHub raw content (raw.githubusercontent.com) is blocked, or `bash` is not available.

**Fix:** Use the manual method in [If the installer fails](#if-the-installer-fails). If `bash` isn't found, make sure Git is installed and your PATH includes the Git `bin` directory.

## pip install fails

**Cause:** PyPI (pypi.org) is blocked.

**Fix:** Download wheel files from the PyPI website manually, then use `pip install --no-index --find-links=./packages`.

## Tools installed but commands not found

**Fix:** Close and reopen PowerShell. User PATH changes require a new session.

## Proxy-related errors (timeouts, connection refused on downloads)

**Cause:** Your network uses a corporate proxy that isn't being picked up automatically.

**Fix:** Detect your proxy from Windows settings and set it:

```powershell
# Detect proxy from Windows Internet Settings
$proxyServer = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings").ProxyServer
Write-Host "Proxy: $proxyServer"

# If a proxy was found, set it for the current session
if ($proxyServer) {
    $env:HTTP_PROXY = "http://$proxyServer"
    $env:HTTPS_PROXY = "http://$proxyServer"
}
```

> **Note:** Most GFE environments do not require manual proxy configuration — Python's `urllib` and `pip` typically inherit the system proxy automatically.

## PowerShell script execution is disabled

**Cause:** Your machine's execution policy blocks `.ps1` scripts.

**Fix:** Run scripts with the bypass flag: `PowerShell -ExecutionPolicy Bypass -File .\scripts\start.ps1`. This does not require admin privileges — it only bypasses the policy for that single script invocation.

## "Method invocation is supported only on core types in this language mode"

**Cause:** PowerShell is running in Constrained Language Mode (common on locked-down GFE machines). This blocks .NET method calls like `[Environment]::SetEnvironmentVariable()`.

**Fix:** Use these alternatives instead:

```powershell
# Instead of [Environment]::SetEnvironmentVariable("Path", "...", "User"), use:
setx PATH "$env:PATH;C:\new\path"

# For the current session only (no restart needed):
$env:PATH += ";C:\new\path"

# Instead of [Environment]::GetEnvironmentVariable("Path", "User"), use:
$env:PATH
```

> **Note:** `setx` has a 1024-character limit for the value. If your PATH is already long, use the `$env:PATH` approach for the current session or ask IT to add the path permanently.

---

# For IT Teams

If your users are on locked-down environments (NIPRNET Citrix, Group Policy-managed desktops), they will not be able to self-install the prerequisite tools. Here is what needs to be provisioned.

## Software requirements

Install the following to a Group Policy-approved path (e.g., `C:\Program Files`) and add to the system PATH:

| Software | Version | Why it's needed | Official source |
|----------|---------|-----------------|-----------------|
| Node.js | 20.x LTS | Required runtime for Claude Code | https://nodejs.org |
| Git for Windows | 2.40+ | Required by Claude Code (Git Bash) | https://git-scm.com |
| Python | 3.11+ | Required for AI Dev Kit MCP server | https://python.org |
| Databricks CLI | Latest | Workspace interaction | https://github.com/databricks/cli |

Submit through your organization's software provisioning process (Software Center, SCCM, ServiceNow, etc.).

## Network access requirements

Even after the prerequisites are installed, the AI Dev Kit installation needs network access:

| Action | URL needed | Alternative if blocked |
|--------|-----------|----------------------|
| AI Dev Kit installer | raw.githubusercontent.com | Download zip from github.com |
| Claude Code install | registry.npmjs.org | Download `.tgz` manually from npmjs.com |
| AI Dev Kit Python deps | pypi.org | Typically works (pip uses allowed network path) |
| Databricks workspace | Your workspace URL | Must be reachable |

> **Note:** On some environments, Python's built-in `urllib` module may have network access even when PowerShell download commands are blocked. IT teams can leverage this when provisioning packages.

## After IT installs the tools

Once the prerequisites are installed, users should start from [Configure Databricks CLI](#configure-databricks-cli) in this guide.

Users will also need from their Databricks administrator:
- Workspace URL
- A Claude serving endpoint name
- A Personal Access Token (PAT)

---

# Alternative: Host installation bundle internally

If your network is very restrictive (all external sites blocked), ask your Databricks administrator to:

1. Download all required files on an unrestricted machine
2. Host them on your internal network (web server or file share)
3. Modify download URLs in the installation commands to point to the internal server

```powershell
# Instead of:
python -c "import urllib.request; urllib.request.urlretrieve('https://nodejs.org/dist/v20.18.1/node-v20.18.1-win-x64.zip', 'node.zip')"

# Use:
python -c "import urllib.request; urllib.request.urlretrieve('https://internal-server.youragency.gov/tools/node-v20.18.1-win-x64.zip', 'node.zip')"
```

---

# File layout after installation

```
C:\Users\<YourName>\
  AppData\Roaming\Python\Python3XX\Scripts\   # Python user scripts (tools installed here)
    ├── nodejs\                # Node.js distribution
    ├── git\                   # Git distribution (bin\git.exe, bin\bash.exe)
    ├── databricks\            # Databricks CLI
    ├── pip.exe                # pip (pre-existing)
    └── ...                    # Other pip-installed tools
  .databrickscfg               # CLI profile configuration
  .ai-dev-kit\                 # MCP server files (manual install only)
  my-databricks-project\
    ├── .env                   # Your endpoint config (DO NOT commit)
    ├── scripts\
    │   └── start.ps1          # Launch script
    ├── .claude\skills\        # 26+ Databricks skills
    └── .mcp.json              # MCP server config
```

---

For the full list of available skills and what you can build, see the [AI Dev Kit documentation](https://github.com/databricks-solutions/ai-dev-kit).
