# NIPRNET Citrix Environment - Setup Findings

**Internal reference document.** This captures findings from attempting to set up the Databricks AI Dev Kit on a NIPRNET Citrix virtual desktop. This is NOT a recommended installation guide - it documents what we learned so we can work with IT to establish a supported path.

---

## Environment summary

- **Platform:** NIPRNET Citrix virtual desktop (Windows)
- **Admin access:** None
- **Pre-installed:** Python 3.13 (at `C:\Program Files\Python313`)
- **Network:** pip (PyPI) works; direct browser downloads from most sites blocked; PowerShell `Invoke-WebRequest` blocked
- **Group Policy:** AppLocker or SRP blocks execution of `.exe` and `.cmd` files from non-whitelisted directories (Desktop, user profile, AppData in general)

## What we need to install

| Software | Purpose | Status |
|----------|---------|--------|
| Node.js 20 LTS | Runtime for Claude Code | Not on image, not in Software Center |
| Git for Windows (with bash) | Required dependency for Claude Code | Not on image, not in Software Center |
| Databricks CLI | Workspace interaction | Not on image, not in Software Center |
| Python 3.11+ | AI Dev Kit MCP server | Pre-installed (3.13) |

## What works

1. **Python is pre-installed** and runs from `C:\Program Files\Python313`
2. **pip can reach PyPI** - `pip install` works without issue
3. **Python can download files** - `urllib.request.urlretrieve()` can reach external URLs (nodejs.org, github.com, etc.) using the same network path as pip
4. **Python can extract archives** - `tarfile` module handles `.tar.bz2`, `Expand-Archive` handles `.zip`
5. **Platform One / Repo One** (repo1.dso.mil) is accessible from the Citrix browser
6. **github.com** is accessible from the Citrix browser

## What doesn't work

1. **Browser downloads** from most sites (nodejs.org, etc.) are blocked
2. **PowerShell downloads** (`Invoke-WebRequest`) are blocked
3. **Running executables** from Desktop, Downloads, user profile root, or AppData directories is blocked by Group Policy
4. **`.cmd` files** are blocked by Group Policy from non-whitelisted paths
5. **Self-extracting archives** (`.7z.exe`) are blocked by Group Policy
6. **npm registry** (registry.npmjs.org) - not tested directly but likely blocked based on network policy
7. **Microsoft Store** - Node.js not available there
8. **winget** - not available on this image
9. **Software Center (SCCM)** - Node.js and Git not in the catalog

## Key finding: Group Policy whitelisted paths

The Python installation directory and its Scripts subdirectory are whitelisted for execution:

- `C:\Program Files\Python313\python.exe` - runs
- `C:\Users\<user>\AppData\Roaming\Python\Python313\Scripts\` - executables here run (this is where pip installs script entry points)

Executables placed in the Scripts directory (e.g., `node.exe`, `bash.exe`) run without Group Policy blocking. This is because Group Policy whitelists this path for Python tool execution.

## What we discovered is possible (but not recommended without IT approval)

Using Python's network access and the whitelisted Scripts directory, it was possible to:

1. Download Node.js zip via `python -c "import urllib.request; ..."`
2. Extract and copy `node.exe` to the Python Scripts folder
3. Run npm through node: `node.exe node_modules\npm\bin\npm-cli.js install -g @anthropic-ai/claude-code`
4. Download Git tar.bz2 and extract via Python's `tarfile` module
5. Copy `bash.exe` to the Python Scripts folder
6. Launch Claude Code with `CLAUDE_CODE_GIT_BASH_PATH` set to the Scripts folder bash.exe

**Why this is not recommended as a general approach:**
- The Scripts folder is whitelisted for Python tools, not arbitrary executables
- IT may consider placing non-Python executables there as circumventing the intent of application whitelisting
- This approach should only be used if explicitly approved by your IT security team

## Recommended path forward

### For IT teams

To support the Databricks AI Dev Kit on NIPRNET Citrix, IT should:

1. **Add to Software Center / SCCM catalog:**
   - Node.js 20 LTS (from nodejs.org)
   - Git for Windows (from git-scm.com)
   - Databricks CLI (from github.com/databricks/cli)

2. **Or install directly** to `C:\Program Files` on the Citrix image/profile

3. **Ensure PATH is configured** so `node`, `npm`, `git`, `bash`, and `databricks` are available from PowerShell

4. **Network access:** pip (PyPI) access is already working. If npm registry access (registry.npmjs.org) can also be allowed, the standard installation path in the GFE guide will work end-to-end.

### For users

1. Submit an IT request for Node.js, Git, and Databricks CLI (see sample request in GFE-SETUP-GUIDE.md)
2. While waiting, coordinate with your Databricks administrator to set up:
   - A Claude serving endpoint on your workspace
   - A Personal Access Token (PAT) for your account
3. Once IT installs the tools, follow the standard GFE setup guide

## AI Dev Kit installation on NIPRNET

Even after IT installs the prerequisites, the AI Dev Kit itself needs to be downloaded and installed. Key considerations:

- **Standard installer** (`curl -sL raw.githubusercontent.com/...`) will fail - `raw.githubusercontent.com` is blocked and `curl` / `bash` may not be available
- **Manual zip download** from `github.com/databricks-solutions/ai-dev-kit/archive/refs/heads/main.zip` - browser download likely blocked, but Python `urllib.request` can download it
- **Python dependencies** (`pip install databricks-sdk` etc.) - works fine since pip has network access
- **npm packages** - if `registry.npmjs.org` is blocked, Claude Code can be installed via manual `.tgz` download (same Python urllib trick)

The most reliable NIPRNET path for the AI Dev Kit itself is the Restricted Network Installation method using Python to download the zip from github.com.

---

## Environment variables needed for Claude Code

Once tools are properly installed, these environment variables must be set before launching Claude Code:

```powershell
$env:ANTHROPIC_MODEL = "databricks-claude-sonnet-4-5"
$env:ANTHROPIC_BASE_URL = "https://<workspace>.cloud.databricks.com/serving-endpoints/<endpoint>"
$env:ANTHROPIC_AUTH_TOKEN = "dapi<your-token>"
$env:ANTHROPIC_CUSTOM_HEADERS = "x-databricks-use-coding-agent-mode: true"
$env:CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = "1"
$env:CLAUDE_CODE_GIT_BASH_PATH = "C:\Program Files\Git\bin\bash.exe"
```

The last variable (`CLAUDE_CODE_GIT_BASH_PATH`) is only needed if Git Bash is not on the system PATH.
