# Databricks AI Dev Kit - GFE Setup Guide

**Complete installation guide for Government Field Engineering machines.**

This guide walks you through installing the [Databricks AI Dev Kit](https://github.com/databricks-solutions/ai-dev-kit) on Windows machines commonly used in government environments. It covers restricted networks, locked-down desktops, and portable (no-admin) scenarios.

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
| NIPRNET Citrix or locked-down environment with Group Policy | [NIPRNET / Locked-down Environments](#niprnet--locked-down-citrix-environments) (start here) |
| npm registry or GitHub APIs are blocked by your network | [Restricted Network Installation](#restricted-network-installation) |
| You do NOT have admin privileges but have internet access | [Portable Installation (No Admin)](#portable-installation-no-admin) |

**Not sure?** Run this quick test in PowerShell:

```powershell
# Check network access
Test-NetConnection registry.npmjs.org -Port 443
Test-NetConnection raw.githubusercontent.com -Port 443
```

- **Commands above fail or are blocked by Group Policy** → NIPRNET / Locked-down Environments
- **Either connection fails** → Restricted Network Installation
- **Both connections succeed** → Portable Installation (No Admin)

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

# NIPRNET / Locked-down Citrix Environments

If you are on a NIPRNET Citrix virtual desktop or similarly locked-down environment, the self-service installation paths below will likely not work due to:

- **Group Policy (AppLocker/SRP):** Executables are only allowed to run from IT-approved directories (e.g., `C:\Program Files`). Downloading an `.exe` to your Desktop or user profile and running it will be blocked.
- **PowerShell download restrictions:** `Invoke-WebRequest` and similar commands are blocked by network policy.
- **No admin privileges:** You cannot install software to `C:\Program Files` or modify system PATH.
- **Package registries blocked:** npm (registry.npmjs.org) may be unreachable. (Note: pip/PyPI typically works on NIPRNET.)

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

If `github.com` is accessible from the browser, the [Restricted Network Installation](#restricted-network-installation) path can be used for the AI Dev Kit itself. Note: On some environments, Python's built-in `urllib` module may have network access even when other download tools are blocked — IT teams can leverage this when provisioning the required packages.

## After IT installs the tools

Once Node.js, Git, and the Databricks CLI are properly installed by IT, follow the [Portable Installation (No Admin)](#portable-installation-no-admin) path starting from **Install Claude Code** (Step 6), since the prerequisites will already be in place.

You will also need your Databricks administrator to provide:
- Your workspace URL
- A Claude serving endpoint name
- A Personal Access Token (PAT)

See [Configure and Launch](#configure-and-launch) for the environment setup.

---

# Restricted Network Installation

**Use if npm registry (registry.npmjs.org) or GitHub APIs (raw.githubusercontent.com) are blocked.**

This path uses direct downloads from official websites instead of package registry APIs. If even direct downloads are blocked on your network, see [Alternative: Internal hosting](#alternative-host-installation-bundle-internally) or work with your IT team.

## Install prerequisites

Follow Steps 1-5 (Node.js through Configure Databricks CLI) from [Portable Installation (No Admin)](#portable-installation-no-admin). Those steps download portable packages from official sites (nodejs.org, git-scm.com, github.com) and don't require admin privileges.

> **If even official sites are blocked**, see [Alternative: Internal hosting](#alternative-host-installation-bundle-internally) at the bottom of this guide.

## Install Claude Code (manual download)

Since npm registry is blocked, download the package directly:

```powershell
$VERSION = "1.0.24"  # Replace with latest from https://www.npmjs.com/package/@anthropic-ai/claude-code
Invoke-WebRequest -Uri "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-$VERSION.tgz" -OutFile "claude-code.tgz"
```

> **If `Invoke-WebRequest` is also blocked**, see [Alternative: Internal hosting](#alternative-host-installation-bundle-internally) or ask your IT team to download the file and make it available on an internal share.

Then install from the local file:

```powershell
npm install -g claude-code.tgz
Remove-Item claude-code.tgz
```

Verify:

```powershell
claude --version
```

## Install AI Dev Kit (manual download)

Since the standard installer uses `raw.githubusercontent.com` which may be blocked, download the zip instead:

```powershell
Invoke-WebRequest -Uri "https://github.com/databricks-solutions/ai-dev-kit/archive/refs/heads/main.zip" -OutFile "ai-dev-kit.zip"
```

> **If `Invoke-WebRequest` is also blocked**, download the zip through your browser from `https://github.com/databricks-solutions/ai-dev-kit` (Code -> Download ZIP), or ask your IT team to make it available internally.

Then extract and install:

```powershell
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

> **Note:** pip may install scripts to a folder not on your PATH (e.g., `AppData\Roaming\Python\Python313\Scripts`). Add it with:
> `$env:PATH += ";$env:APPDATA\Python\Python313\Scripts"`

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

Then continue to [Configure and Launch](#configure-and-launch) below.

---

# Portable Installation (No Admin)

**Use if you do NOT have admin privileges. All tools install to your user directory.**

> **Prerequisite:** Python 3.11+ must already be installed. Most GFE machines include Python. Verify with `python --version`. If Python is not available, request it through your IT team or download from https://www.python.org/downloads/.

For convenience, this guide installs developer tools alongside your existing Python installation in the **user scripts directory**. This is the standard location where pip installs command-line tools, and is typically already on your system PATH.

> **Note:** If you encounter "blocked by Group Policy" errors when running downloaded executables, work with your IT team to provision these tools through approved channels (see [NIPRNET section](#niprnet--locked-down-citrix-environments)).

## Step 1: Locate your tools directory

```powershell
# Your Python user scripts directory — where pip installs command-line tools
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
Write-Host "Tools directory: $TOOLS_DIR"

# Ensure it exists
New-Item -ItemType Directory -Force -Path $TOOLS_DIR | Out-Null
```

> **Tip:** On most GFE machines this resolves to something like `C:\Users\<YourName>\AppData\Roaming\Python\Python313\Scripts`. This directory is already on your PATH if you've used `pip install --user` before.

## Step 2: Install Node.js

```powershell
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

**Close and reopen PowerShell**, then verify:

```powershell
node --version
npm --version
```

## Step 3: Install Git

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

**Close and reopen PowerShell**, then verify:

```powershell
git --version
```

## Step 4: Install Databricks CLI

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

**Close and reopen PowerShell**, then verify:

```powershell
databricks --version
```

## Step 5: Configure Databricks CLI

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

## Step 6: Install Claude Code

```powershell
npm install -g @anthropic-ai/claude-code
```

> **If this fails with a network error**, your network may block npm registry. See [Restricted Network Installation](#restricted-network-installation).

Verify:

```powershell
claude --version
```

## Next

Continue to [Install AI Dev Kit](#install-ai-dev-kit) below.

---

# Install AI Dev Kit

This step applies to the **Portable** installation path. (Restricted network users already completed this in the previous section.)

```powershell
# Create project directory
$PROJECT_DIR = "$env:USERPROFILE\my-databricks-project"
New-Item -ItemType Directory -Force -Path $PROJECT_DIR
cd $PROJECT_DIR

# Download and run the installer (requires bash from Git installation)
bash -c "curl -sL https://raw.githubusercontent.com/databricks-solutions/ai-dev-kit/main/install.sh -o install.sh && bash install.sh"
```

> **Note:** The `bash` command comes from Git (Git Bash). If you installed Git via PortableGit in the previous steps, `bash` should be available. If not, open Git Bash from your start menu and run the curl command there.

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

## "Method invocation is supported only on core types in this language mode"

**Cause:** PowerShell is running in Constrained Language Mode (common on locked-down GFE/NIPRNET machines). This blocks .NET method calls like `[Environment]::SetEnvironmentVariable()` and `[Environment]::GetEnvironmentVariable()` used in the Portable Installation path.

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

For the full list of available skills and what you can build, see the [AI Dev Kit documentation](https://github.com/databricks-solutions/ai-dev-kit).
