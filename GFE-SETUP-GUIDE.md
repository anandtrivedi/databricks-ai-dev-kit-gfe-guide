# Databricks AI Dev Kit - GFE Setup Guide

**Complete installation guide for Government Field Engineering machines.**

This guide walks you through installing the [Databricks AI Dev Kit](https://github.com/databricks-solutions/ai-dev-kit) on Windows machines commonly used in government environments. It covers both admin and non-admin scenarios, and handles restricted networks and corporate proxies.

> **Upstream project:** All skills and MCP servers come from [databricks-solutions/ai-dev-kit](https://github.com/databricks-solutions/ai-dev-kit). This guide only covers GFE-specific installation steps.

> **Important:** This guide does not attempt to bypass or circumvent any security controls, network restrictions, or organizational policies. Always follow your organization's software approval and IT procedures before installing any tools. Verify that the software listed here (Node.js, Python, Git, Claude Code) is approved for use on your device, and confirm with your IT team that downloading from the referenced external sites is permitted.

---

## Step 1: Download this guide and helper scripts

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

---

## Step 2: Choose your installation path

| Scenario | Path |
|----------|------|
| You have local admin privileges and unrestricted internet | [Standard Installation (Admin)](#standard-installation-admin) |
| You do NOT have admin privileges but have internet access | [Portable Installation (No Admin)](#portable-installation-no-admin) |
| npm registry or GitHub APIs are blocked by your network | [Restricted Network Installation](#restricted-network-installation) |

**Not sure?** Run this quick test in PowerShell:

```powershell
# Check admin status
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-Host "Admin: $isAdmin"

# Check network access
Test-NetConnection registry.npmjs.org -Port 443
Test-NetConnection raw.githubusercontent.com -Port 443
```

- **Admin = True, both connections succeed** → Standard Installation (Admin)
- **Admin = False, both connections succeed** → Portable Installation (No Admin)
- **Either connection fails** → Restricted Network Installation (works with or without admin)

---

## Step 3: Configure proxy (if applicable)

If your network uses a corporate proxy, configure it **before** installing tools. Skip this step if you have direct internet access.

**Option A - Automated (recommended):**

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\setup-proxy.ps1
```

The script auto-detects your Windows proxy settings and configures npm, git, and pip. Run it again after installing each tool if needed.

> **Note:** If you haven't installed npm/git/pip yet, the script will skip configuring those tools and show a warning. That's fine - just re-run it after you install them.

**Option B - Manual:**

```powershell
# Get your proxy URL from your IT department, then set environment variables:
$PROXY = "http://proxy.youragency.gov:8080"

# These work even before npm/git/pip are installed
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

---

# Standard Installation (Admin)

**Use if you have local admin privileges and unrestricted internet.**

This is the fastest path. Uses standard installers and package managers.

## Install prerequisites

**Option A - Using winget (Windows 10 1809+):**

```powershell
winget install OpenJS.NodeJS.LTS
winget install Python.Python.3.11
winget install Git.Git
```

**Option B - Using standard installers:**

Download and run the installers from:
- **Node.js LTS:** https://nodejs.org/ (use the LTS installer)
- **Python 3.11+:** https://www.python.org/downloads/ (check "Add to PATH" during install)
- **Git:** https://git-scm.com/download/win

Close and reopen PowerShell, then verify:

```powershell
node --version
python --version
git --version
```

## Install Databricks CLI

```powershell
winget install Databricks.DatabricksCLI
```

Or download from [GitHub releases](https://github.com/databricks/cli/releases) and add to your PATH.

Verify:

```powershell
databricks --version
```

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

## Install Claude Code

```powershell
npm install -g @anthropic-ai/claude-code
```

Verify:

```powershell
claude --version
```

## Install AI Dev Kit

Continue to [Install AI Dev Kit](#install-ai-dev-kit) below.

---

# Portable Installation (No Admin)

**Use if you do NOT have admin privileges. All tools install to your user directory.**

## Install portable Node.js

```powershell
# Create tools directory in your user profile
$TOOLS_DIR = "$env:USERPROFILE\.databricks-tools"
New-Item -ItemType Directory -Force -Path $TOOLS_DIR
cd $TOOLS_DIR

# Download portable Node.js (check https://nodejs.org for latest LTS version)
$NODE_VERSION = "20.18.1"
Invoke-WebRequest -Uri "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-win-x64.zip" -OutFile "node.zip"
Expand-Archive node.zip -DestinationPath . -Force

# Rename extracted folder (remove old one if re-running)
if (Test-Path "node") { Remove-Item "node" -Recurse -Force }
Rename-Item "node-v$NODE_VERSION-win-x64" "node"
Remove-Item node.zip

# Add to user PATH
$nodePath = "$TOOLS_DIR\node"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$nodePath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$nodePath", "User")
}

Write-Host "Node.js installed to $nodePath" -ForegroundColor Green
```

**Close and reopen PowerShell**, then verify:

```powershell
node --version
npm --version
```

## Install portable Python

```powershell
cd "$env:USERPROFILE\.databricks-tools"

# Download Python embeddable package (check https://www.python.org for latest 3.11.x)
$PYTHON_VERSION = "3.11.11"
Invoke-WebRequest -Uri "https://www.python.org/ftp/python/$PYTHON_VERSION/python-$PYTHON_VERSION-embed-amd64.zip" -OutFile "python.zip"
Expand-Archive python.zip -DestinationPath "python" -Force
Remove-Item python.zip

# Enable site-packages (required for pip)
cd python
$pthFile = Get-ChildItem "python*._pth" | Select-Object -First 1
(Get-Content $pthFile.FullName) -replace '#import site', 'import site' | Set-Content $pthFile.FullName

# Install pip
Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile "get-pip.py"
.\python.exe get-pip.py
Remove-Item get-pip.py

# Add to user PATH
$pythonPath = "$env:USERPROFILE\.databricks-tools\python"
$scriptsPath = "$pythonPath\Scripts"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$pythonPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$pythonPath;$scriptsPath", "User")
}

Write-Host "Python installed to $pythonPath" -ForegroundColor Green
```

**Close and reopen PowerShell**, then verify:

```powershell
python --version
pip --version
```

## Install portable Git

```powershell
cd "$env:USERPROFILE\.databricks-tools"

# Download PortableGit (check https://github.com/git-for-windows/git/releases for latest)
Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/PortableGit-2.47.1-64-bit.7z.exe" -OutFile "portablegit.exe"

# Self-extracting archive
.\portablegit.exe -o"git" -y
Remove-Item portablegit.exe

# Add to user PATH
$gitPath = "$env:USERPROFILE\.databricks-tools\git\bin"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$gitPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$gitPath", "User")
}

Write-Host "Git installed to $gitPath" -ForegroundColor Green
```

**Close and reopen PowerShell**, then verify:

```powershell
git --version
```

## Install Databricks CLI

```powershell
cd "$env:USERPROFILE\.databricks-tools"

# Download Databricks CLI (check https://github.com/databricks/cli/releases for latest)
Invoke-WebRequest -Uri "https://github.com/databricks/cli/releases/latest/download/databricks_cli_windows_amd64.zip" -OutFile "databricks.zip"
Expand-Archive databricks.zip -DestinationPath "databricks" -Force
Remove-Item databricks.zip

# Add to user PATH
$databricksPath = "$env:USERPROFILE\.databricks-tools\databricks"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$databricksPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$databricksPath", "User")
}

Write-Host "Databricks CLI installed" -ForegroundColor Green
```

**Close and reopen PowerShell**, then verify:

```powershell
databricks --version
```

## Configure Databricks CLI

```powershell
@"
[my-workspace]
host  = https://your-workspace.cloud.databricks.com
token = dapi1234567890abcdef...
"@ | Out-File -FilePath "$env:USERPROFILE\.databrickscfg" -Encoding ASCII
```

Replace with your actual workspace URL and token.

Verify:

```powershell
databricks --profile my-workspace current-user me
```

## Install Claude Code

```powershell
npm install -g @anthropic-ai/claude-code
```

> **If this fails with a network error**, your network may block npm registry. See [Restricted Network Installation](#restricted-network-installation).

Verify:

```powershell
claude --version
```

## Install AI Dev Kit

Continue to [Install AI Dev Kit](#install-ai-dev-kit) below.

---

# Restricted Network Installation

**Use if npm registry (registry.npmjs.org) or GitHub APIs (raw.githubusercontent.com) are blocked.**

Most government networks allow downloads from official websites but block package registry APIs. This path uses direct downloads instead.

## Install prerequisites

**If you have admin privileges:** Follow the prerequisite steps from [Standard Installation (Admin)](#standard-installation-admin) — winget and standard installers download from official sites that are typically allowed.

**If you do NOT have admin privileges:** Follow Steps 1-5 (Node.js through Configure Databricks CLI) from [Portable Installation (No Admin)](#portable-installation-no-admin). Those steps download from official sites (nodejs.org, python.org, github.com/releases) which are typically allowed.

> **If even official sites are blocked**, see [Alternative: Internal hosting](#alternative-host-installation-bundle-internally) at the bottom of this guide.

## Install Claude Code (manual download)

Since npm registry is blocked, download the package directly:

```powershell
# Visit https://www.npmjs.com/package/@anthropic-ai/claude-code
# Find the latest version number, then download:
$VERSION = "1.0.24"  # Replace with latest from npmjs.com
Invoke-WebRequest -Uri "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-$VERSION.tgz" -OutFile "claude-code.tgz"

# Install from local file
npm install -g claude-code.tgz
Remove-Item claude-code.tgz
```

> **Note:** If `registry.npmjs.org` is also blocked, ask your Databricks admin to download the package and provide it via an internal file share.

Verify:

```powershell
claude --version
```

## Install AI Dev Kit (manual download)

Since the standard installer uses `raw.githubusercontent.com` which may be blocked, download the zip instead:

```powershell
$PROJECT_DIR = "$env:USERPROFILE\my-databricks-project"
New-Item -ItemType Directory -Force -Path $PROJECT_DIR
cd $PROJECT_DIR

# Download from GitHub (archive download, not raw content)
Invoke-WebRequest -Uri "https://github.com/databricks-solutions/ai-dev-kit/archive/refs/heads/main.zip" -OutFile "ai-dev-kit.zip"

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
```

> **If pip is also blocked**, download wheel files from https://pypi.org manually, then: `pip install --no-index --find-links=./packages databricks-sdk python-dotenv anthropic`

Create MCP config:

```powershell
@"
{
  "mcpServers": {
    "databricks": {
      "command": "python",
      "args": ["-m", "databricks_mcp"],
      "env": {
        "DATABRICKS_CONFIG_PROFILE": "my-workspace"
      }
    }
  }
}
"@ | Out-File -FilePath ".mcp.json" -Encoding UTF8
```

Then continue to [Configure and Launch](#configure-and-launch) below.

---

# Install AI Dev Kit

This step applies to the **Standard** and **Portable** installation paths. (Restricted network users already completed this in the previous section.)

```powershell
# Create project directory
$PROJECT_DIR = "$env:USERPROFILE\my-databricks-project"
New-Item -ItemType Directory -Force -Path $PROJECT_DIR
cd $PROJECT_DIR

# Download and run the installer (requires bash from Git installation)
bash -c "curl -sL https://raw.githubusercontent.com/databricks-solutions/ai-dev-kit/main/install.sh -o install.sh && bash install.sh"
```

> **Note:** The `bash` command comes from Git (Git Bash). If you installed Git via winget or PortableGit in the previous steps, `bash` should be available. If not, open Git Bash from your start menu and run the curl command there.

When prompted:
1. **Select tools** → `Claude Code`
2. **Select profile** → `my-workspace`
3. **Select scope** → `Project`

> **If this fails**, fall back to the [manual download method](#install-ai-dev-kit-manual-download) in the Restricted Network section.

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

**Cause:** Even nodejs.org, python.org, etc. are blocked.

**Fix:** See [Alternative: Internal hosting](#alternative-host-installation-bundle-internally) below, or ask your IT team to whitelist these official download domains.

## npm install fails with ECONNREFUSED

**Cause:** npm registry (registry.npmjs.org) is blocked.

**Fix:** Use the [Restricted Network Installation](#restricted-network-installation) path - download packages from the npm website directly.

## curl / bash installer fails

**Cause:** GitHub raw content (raw.githubusercontent.com) is blocked, or `bash` is not available.

**Fix:** Use the [manual AI Dev Kit download](#install-ai-dev-kit-manual-download) in the Restricted Network section. If `bash` isn't found, make sure Git is installed and your PATH includes the Git `bin` directory.

## pip install fails

**Cause:** PyPI (pypi.org) is blocked.

**Fix:** Download wheel files from the PyPI website manually, then use `pip install --no-index --find-links=./packages`.

## Tools installed but commands not found

**Fix:** Close and reopen PowerShell. User PATH changes require a new session.

## Proxy-related errors

**Fix:** Run `scripts\setup-proxy.ps1` or configure proxy manually. See [Step 3](#step-3-configure-proxy-if-applicable).

## PowerShell script execution is disabled

**Cause:** Your machine's execution policy blocks `.ps1` scripts.

**Fix:** Run scripts with the bypass flag: `PowerShell -ExecutionPolicy Bypass -File .\scripts\start.ps1`. This does not require admin privileges - it only bypasses the policy for that single script invocation.

---

# NIPRNET / Locked-down Citrix Environments

If you are on a NIPRNET Citrix virtual desktop or similarly locked-down environment, the self-service installation paths above will likely not work due to:

- **Group Policy (AppLocker/SRP):** Executables are only allowed to run from IT-approved directories (e.g., `C:\Program Files`). Downloading an `.exe` to your Desktop or user profile and running it will be blocked.
- **PowerShell download restrictions:** `Invoke-WebRequest` and similar commands are blocked by network policy.
- **No admin privileges:** You cannot install software to `C:\Program Files` or modify system PATH.
- **Package registries blocked:** npm (registry.npmjs.org) and potentially PyPI (pypi.org) may be unreachable.

## What IT needs to provide

The Databricks AI Dev Kit requires the following software installed to a Group Policy-approved path (e.g., `C:\Program Files`) and added to the system PATH:

| Software | Version | Why it's needed | Official source |
|----------|---------|-----------------|-----------------|
| Node.js | 20.x LTS | Required runtime for Claude Code | https://nodejs.org |
| Git for Windows | 2.40+ | Required by Claude Code (Git Bash) | https://git-scm.com |
| Python | 3.11+ | Required for AI Dev Kit MCP server | https://python.org |
| Databricks CLI | Latest | Workspace interaction | https://github.com/databricks/cli |

Submit a request through your organization's approved software provisioning process (Software Center, SCCM, ServiceNow, etc.).

## Network access for AI Dev Kit installation

Even after IT installs the prerequisites, the AI Dev Kit installer itself needs network access. The standard installer downloads from `raw.githubusercontent.com`, which may be blocked. Your IT team should be aware of the following network dependencies:

| Action | URL needed | Alternative if blocked |
|--------|-----------|----------------------|
| AI Dev Kit installer | raw.githubusercontent.com | Download zip from github.com (see Restricted Network section) |
| Claude Code install | registry.npmjs.org | Download `.tgz` manually from npmjs.com |
| AI Dev Kit Python deps | pypi.org | Typically works on NIPRNET (pip uses allowed network path) |
| Databricks CLI config | Your workspace URL | Must be reachable from Citrix |

If `github.com` is accessible from the browser or via Python, the [Restricted Network Installation](#restricted-network-installation) path can be used for the AI Dev Kit itself.

## After IT installs the tools

Once Node.js, Git, and the Databricks CLI are properly installed by IT, follow the [Standard Installation (Admin)](#standard-installation-admin) path starting from **Install Claude Code**, since the prerequisites will already be in place.

You will also need your Databricks administrator to provide:
- Your workspace URL
- A Claude serving endpoint name
- A Personal Access Token (PAT)

See [Configure and Launch](#configure-and-launch) for the environment setup.

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
  .databricks-tools\          # Portable tools (no-admin installs only)
    ├── node\
    ├── python\
    ├── git\
    └── databricks\
  .databrickscfg               # CLI profile configuration
  .ai-dev-kit\                 # MCP server files
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

# What you can build

Once running, ask Claude to build:

- **Data pipelines** - "Create a medallion pipeline from CSV to Delta"
- **Jobs** - "Create a job that runs my notebook daily at 6am"
- **Dashboards** - "Build a dashboard showing sales by region"
- **SQL queries** - "Query top 10 customers by revenue"
- **Apps** - "Build a Databricks App with React frontend"
- **ML models** - "Deploy a model to a serving endpoint"

See the [AI Dev Kit documentation](https://github.com/databricks-solutions/ai-dev-kit) for the full list of available skills.
