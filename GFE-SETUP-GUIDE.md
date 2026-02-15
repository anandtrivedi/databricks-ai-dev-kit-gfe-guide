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

## Download this guide and helper scripts

Download or clone this repo to get the helper scripts used throughout this guide:

```powershell
# Option A: Clone (if git is available)
git clone https://github.com/anandtrivedi/databricks-ai-dev-kit-gfe-guide.git
cd databricks-ai-dev-kit-gfe-guide

# Option B: Download ZIP (if git is not installed yet)
# Go to https://github.com/anandtrivedi/databricks-ai-dev-kit-gfe-guide
# Click "Code" → "Download ZIP", extract it, and open PowerShell in that folder
```

This gives you:
- `scripts/setup-proxy.ps1` - Auto-detect and configure corporate proxy
- `scripts/setup-env.ps1` - Interactive wizard to create your `.env` file
- `scripts/start.ps1` - Launch script for Claude Code
- `.env.example` - Template for environment configuration

## Configure proxy (if applicable)

If your network uses a corporate proxy, configure it **before** installing tools. Skip this if you have direct internet access.

**Option A - Automated (recommended):**

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\setup-proxy.ps1
```

The script auto-detects your Windows proxy settings and configures npm, git, and pip. Re-run it after installing each tool if needed.

> **Note:** If npm/git/pip aren't installed yet, the script will skip those and show a warning. That's fine — re-run after you install them.

**Option B - Manual:**

```powershell
$PROXY = "http://proxy.youragency.gov:8080"

[Environment]::SetEnvironmentVariable("HTTP_PROXY", $PROXY, "User")
[Environment]::SetEnvironmentVariable("HTTPS_PROXY", $PROXY, "User")
```

After installing npm and git, also run:

```powershell
npm config set proxy $PROXY
npm config set https-proxy $PROXY
git config --global http.proxy $PROXY
git config --global https.proxy $PROXY
```

Close and reopen PowerShell after configuring proxy settings.

## Install prerequisites

### Verify Python

Python 3.11+ must be installed. Most GFE machines include Python.

```powershell
python --version
```

If Python is not available, request it through your IT team or download from https://www.python.org/downloads/.

### Locate your tools directory

For convenience, this guide installs developer tools alongside your existing Python installation in the **user scripts directory**. This is the standard location where pip installs command-line tools, and is typically already on your system PATH.

```powershell
# Your Python user scripts directory — where pip installs command-line tools
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
Write-Host "Tools directory: $TOOLS_DIR"

# Ensure it exists
New-Item -ItemType Directory -Force -Path $TOOLS_DIR | Out-Null
```

> **Tip:** On most GFE machines this resolves to something like `C:\Users\<YourName>\AppData\Roaming\Python\Python313\Scripts`.

### Install Node.js

```powershell
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
cd $TOOLS_DIR

# Download portable Node.js (check https://nodejs.org for latest LTS version)
$NODE_VERSION = "20.18.1"
Invoke-WebRequest -Uri "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-win-x64.zip" -OutFile "node.zip"
Expand-Archive node.zip -DestinationPath . -Force

# Rename extracted folder
if (Test-Path "nodejs") { Remove-Item "nodejs" -Recurse -Force }
Rename-Item "node-v$NODE_VERSION-win-x64" "nodejs"
Remove-Item node.zip

# Add to user PATH
$nodePath = "$TOOLS_DIR\nodejs"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$nodePath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$nodePath", "User")
}

Write-Host "Node.js installed to $nodePath" -ForegroundColor Green
```

> **If blocked:** If the download or execution fails due to Group Policy, request Node.js 20 LTS from your IT team through your organization's software provisioning process. See [For IT Teams](#for-it-teams).

### Install Git

```powershell
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
cd $TOOLS_DIR

# Download Git archive (check https://github.com/git-for-windows/git/releases for latest)
# Using .tar.bz2 because .7z.exe self-extractors are blocked by Group Policy on many GFE machines
Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.tar.bz2" -OutFile "git.tar.bz2"

# Extract using Python's tarfile module
python -c "import tarfile; tarfile.open('git.tar.bz2').extractall('git')"
Remove-Item git.tar.bz2

# Add to user PATH
$gitPath = "$TOOLS_DIR\git\bin"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$gitPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$gitPath", "User")
}

Write-Host "Git installed to $gitPath" -ForegroundColor Green
```

> **If blocked:** Request Git for Windows 2.40+ from your IT team. Claude Code requires Git Bash (`bash.exe`), which is included in the full Git distribution. See [For IT Teams](#for-it-teams).

### Install Databricks CLI

```powershell
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
cd $TOOLS_DIR

# Download Databricks CLI (check https://github.com/databricks/cli/releases for latest)
Invoke-WebRequest -Uri "https://github.com/databricks/cli/releases/latest/download/databricks_cli_windows_amd64.zip" -OutFile "databricks.zip"
Expand-Archive databricks.zip -DestinationPath "databricks" -Force
Remove-Item databricks.zip

# Add to user PATH
$databricksPath = "$TOOLS_DIR\databricks"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$databricksPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$databricksPath", "User")
}

Write-Host "Databricks CLI installed" -ForegroundColor Green
```

> **If blocked:** Request Databricks CLI from your IT team. See [For IT Teams](#for-it-teams).

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
@"
[my-workspace]
host  = https://your-workspace.cloud.databricks.com
token = dapi1234567890abcdef...
"@ | Out-File -FilePath "$env:USERPROFILE\.databrickscfg" -Encoding ASCII
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
> $VERSION = "1.0.24"  # Check https://www.npmjs.com/package/@anthropic-ai/claude-code for latest
> Invoke-WebRequest -Uri "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-$VERSION.tgz" -OutFile "claude-code.tgz"
> npm install -g claude-code.tgz
> Remove-Item claude-code.tgz
> claude --version
> ```
>
> If `Invoke-WebRequest` is also blocked, see [Alternative: Internal hosting](#alternative-host-installation-bundle-internally).

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
# Download AI Dev Kit zip (or download via browser from github.com/databricks-solutions/ai-dev-kit)
Invoke-WebRequest -Uri "https://github.com/databricks-solutions/ai-dev-kit/archive/refs/heads/main.zip" -OutFile "ai-dev-kit.zip"

$PROJECT_DIR = "$env:USERPROFILE\my-databricks-project"
New-Item -ItemType Directory -Force -Path $PROJECT_DIR
cd $PROJECT_DIR

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
@"
{
  "mcpServers": {
    "databricks": {
      "command": "python",
      "args": ["-m", "databricks_mcp_server"],
      "env": {
        "DATABRICKS_CONFIG_PROFILE": "my-workspace"
      }
    }
  }
}
"@ | Out-File -FilePath ".mcp.json" -Encoding UTF8
```

**If Databricks CLI is not installed (use direct credentials instead):**

```powershell
@"
{
  "mcpServers": {
    "databricks": {
      "command": "python",
      "args": ["-m", "databricks_mcp_server"],
      "env": {
        "DATABRICKS_HOST": "https://your-workspace.cloud.databricks.com",
        "DATABRICKS_TOKEN": "dapi1234567890abcdef..."
      }
    }
  }
}
"@ | Out-File -FilePath ".mcp.json" -Encoding UTF8
```

> **Note:** Replace the host and token with your actual values. The direct credentials approach does not require the Databricks CLI to be installed.

---

# Configure and Launch

## Copy helper scripts to your project

Copy the helper scripts from this repo into your project directory:

```powershell
$PROJECT_DIR = "$env:USERPROFILE\my-databricks-project"

# Copy scripts and config template
Copy-Item ".\scripts" -Destination "$PROJECT_DIR\scripts" -Recurse -Force
Copy-Item ".\.env.example" -Destination "$PROJECT_DIR\.env.example" -Force
```

## Configure your environment

```powershell
cd "$env:USERPROFILE\my-databricks-project"
```

**Option A - Interactive setup (recommended):**

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\setup-env.ps1
```

This walks you through entering your workspace URL, endpoint name, model, and token.

**Option B - Manual `.env` file:**

Copy `.env.example` to `.env` and fill in your values:

```powershell
Copy-Item .env.example .env
notepad .env
```

Required values (get these from your Databricks administrator):

| Variable | Description | Example |
|----------|-------------|---------|
| `ANTHROPIC_MODEL` | Model name on your serving endpoint | `databricks-claude-sonnet-4-5` |
| `ANTHROPIC_BASE_URL` | Workspace URL + endpoint path | `https://workspace.cloud.databricks.com/serving-endpoints/claude-endpoint` |
| `ANTHROPIC_AUTH_TOKEN` | Your Databricks PAT | `dapi1234567890abcdef...` |

Optional (only if Git Bash is not on your system PATH):

| Variable | Description | Example |
|----------|-------------|---------|
| `CLAUDE_CODE_GIT_BASH_PATH` | Full path to `bash.exe` from Git | `C:\Program Files\Git\bin\bash.exe` |

> **When do you need this?** Claude Code on Windows requires Git Bash. If `bash` is already on your PATH (typical when Git is installed to `C:\Program Files\Git`), you can skip this. If Claude Code shows "requires git-bash" or "set CLAUDE_CODE_GIT_BASH_PATH", add this variable to your `.env` file pointing to where bash.exe is located.

## Launch Claude Code

**PowerShell (Windows):**

```powershell
cd "$env:USERPROFILE\my-databricks-project"
PowerShell -ExecutionPolicy Bypass -File .\scripts\start.ps1
```

**Bash (macOS/Linux):**

```bash
cd ~/my-databricks-project
chmod +x ./scripts/start-demo.sh
./scripts/start-demo.sh
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

## Proxy-related errors

**Fix:** Run `scripts\setup-proxy.ps1` or configure proxy manually. See [Configure proxy](#configure-proxy-if-applicable).

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
Invoke-WebRequest -Uri "https://nodejs.org/dist/v20.18.1/node-v20.18.1-win-x64.zip"

# Use:
Invoke-WebRequest -Uri "https://internal-server.youragency.gov/tools/node-v20.18.1-win-x64.zip"
```

---

# File layout after installation

```
C:\Users\<YourName>\
  AppData\Roaming\Python\Python3XX\Scripts\   # Python user scripts (tools installed here)
    ├── nodejs\                # Node.js distribution
    ├── git\                   # Git distribution (includes bash.exe)
    ├── databricks\            # Databricks CLI
    ├── pip.exe                # pip (pre-existing)
    └── ...                    # Other pip-installed tools
  .databrickscfg               # CLI profile configuration
  .ai-dev-kit\                 # MCP server files (manual install only)
  my-databricks-project\
    ├── .env                   # Your endpoint config (DO NOT commit)
    ├── .env.example           # Config template
    ├── scripts\
    │   ├── start.ps1          # Launch script
    │   ├── setup-env.ps1      # Environment configurator
    │   └── setup-proxy.ps1    # Proxy configurator
    ├── .claude\skills\        # 26+ Databricks skills
    └── .mcp.json              # MCP server config
```

---

For the full list of available skills and what you can build, see the [AI Dev Kit documentation](https://github.com/databricks-solutions/ai-dev-kit).
