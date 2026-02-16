# Single-Paste Install

Same steps as the [GFE Setup Guide](GFE-SETUP-GUIDE.md), condensed into one copy-paste block. Paste it all into PowerShell, press **Enter**, and wait ~10 minutes. Git extraction takes several minutes — everything else runs after it automatically.

> **Prerequisite:** Python 3.11+ must already be installed. Run `python --version` to verify.

```powershell
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
Write-Host "Tools directory: $TOOLS_DIR" -ForegroundColor Gray
New-Item -ItemType Directory -Force -Path $TOOLS_DIR | Out-Null
cd $TOOLS_DIR
$NODE_VERSION = "20.18.1"
Write-Host "Installing Node.js..." -ForegroundColor Cyan
python -c "import urllib.request; urllib.request.urlretrieve('https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-win-x64.zip', 'node.zip')"
Expand-Archive node.zip -DestinationPath . -Force
if (Test-Path "nodejs") { Remove-Item "nodejs" -Recurse -Force }
Rename-Item "node-v$NODE_VERSION-win-x64" "nodejs"
Remove-Item node.zip
Write-Host "Node.js installed" -ForegroundColor Green
Write-Host "Downloading Git..." -ForegroundColor Cyan
python -c "import urllib.request; urllib.request.urlretrieve('https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.tar.bz2', 'git.tar.bz2')"
Write-Host "Extracting Git (this takes several minutes)..." -ForegroundColor Cyan
python -c "import tarfile; tarfile.open('git.tar.bz2').extractall('git')"
Remove-Item git.tar.bz2
Write-Host "Git installed" -ForegroundColor Green
Write-Host "Installing Databricks CLI..." -ForegroundColor Cyan
python -c "import urllib.request,json; tag=json.loads(urllib.request.urlopen('https://api.github.com/repos/databricks/cli/releases/latest').read())['tag_name']; v=tag.lstrip('v'); urllib.request.urlretrieve(f'https://github.com/databricks/cli/releases/download/{tag}/databricks_cli_{v}_windows_amd64.zip','databricks.zip')"
Expand-Archive databricks.zip -DestinationPath "databricks" -Force
Remove-Item databricks.zip
Write-Host "Databricks CLI installed" -ForegroundColor Green
$env:PATH += ";$TOOLS_DIR\nodejs;$TOOLS_DIR\git\bin;$TOOLS_DIR\databricks"
$userPath = (Get-ItemProperty "HKCU:\Environment").Path + ";$TOOLS_DIR\nodejs;$TOOLS_DIR\git\bin;$TOOLS_DIR\databricks"
setx PATH "$userPath"
Write-Host "PATH updated" -ForegroundColor Green
Write-Host "node: $(node --version)" -ForegroundColor Gray
Write-Host "npm: $(npm --version)" -ForegroundColor Gray
Write-Host "git: $(git --version)" -ForegroundColor Gray
Write-Host "Installing Claude Code..." -ForegroundColor Cyan
npm install -g @anthropic-ai/claude-code
Write-Host "Claude Code: $(claude --version)" -ForegroundColor Gray
$PROJECT_DIR = "$env:USERPROFILE\my-databricks-project"
New-Item -ItemType Directory -Force -Path $PROJECT_DIR | Out-Null
cd $PROJECT_DIR
Write-Host "Downloading AI Dev Kit..." -ForegroundColor Cyan
python -c "import urllib.request; urllib.request.urlretrieve('https://github.com/databricks-solutions/ai-dev-kit/archive/refs/heads/main.zip', 'ai-dev-kit.zip')"
Expand-Archive ai-dev-kit.zip -DestinationPath "$env:TEMP\ai-dev-kit-extract" -Force
$extracted = Get-ChildItem "$env:TEMP\ai-dev-kit-extract" -Directory | Select-Object -First 1
$targetSkills = "$PROJECT_DIR\.claude\skills"
New-Item -ItemType Directory -Force -Path $targetSkills | Out-Null
Copy-Item "$($extracted.FullName)\.claude\skills\*" -Destination $targetSkills -Recurse -Force
$aiDevKitDir = "$env:USERPROFILE\.ai-dev-kit"
New-Item -ItemType Directory -Force -Path $aiDevKitDir | Out-Null
Copy-Item "$($extracted.FullName)\*" -Destination $aiDevKitDir -Recurse -Force
Remove-Item "$env:TEMP\ai-dev-kit-extract" -Recurse -Force
Remove-Item "ai-dev-kit.zip"
Write-Host "AI Dev Kit files copied" -ForegroundColor Green
Write-Host "Installing Python dependencies..." -ForegroundColor Cyan
pip install databricks-sdk python-dotenv anthropic openai pydantic
pip install "$env:USERPROFILE\.ai-dev-kit\databricks-tools-core"
pip install "$env:USERPROFILE\.ai-dev-kit\databricks-mcp-server"
Write-Host "Python dependencies installed" -ForegroundColor Green
python -c "import json; json.dump({'mcpServers': {'databricks': {'command': 'python', 'args': ['-m', 'databricks_mcp_server'], 'env': {'DATABRICKS_CONFIG_PROFILE': 'my-workspace'}}}}, open('.mcp.json', 'w'), indent=2)"
Write-Host "MCP config created" -ForegroundColor Green
python -c "import databricks_mcp_server; print('MCP server OK')"
Write-Host "Skills: $(Test-Path "$PROJECT_DIR\.claude\skills")" -ForegroundColor Gray
Write-Host "MCP config: $(Test-Path "$PROJECT_DIR\.mcp.json")" -ForegroundColor Gray
Write-Host ""
Write-Host "===== INSTALLATION COMPLETE =====" -ForegroundColor Green
Write-Host "Next: configure .env with your Databricks endpoint details" -ForegroundColor Yellow
```

Once complete, follow [Configure and Launch](GFE-SETUP-GUIDE.md#configure-and-launch) in the main guide to set up your `.env` file and launch script.
