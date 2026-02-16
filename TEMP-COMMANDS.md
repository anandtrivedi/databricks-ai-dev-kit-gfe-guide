# Full Clean Install Test

## Part 1: Clean slate (paste all at once, press Enter)

```powershell
$ErrorActionPreference = "SilentlyContinue"
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
Remove-Item "$TOOLS_DIR\nodejs" -Recurse -Force
Remove-Item "$TOOLS_DIR\git" -Recurse -Force
Remove-Item "$TOOLS_DIR\databricks" -Recurse -Force
Remove-Item "$TOOLS_DIR\bash.exe" -Force
Remove-Item "$TOOLS_DIR\node.exe" -Force
Remove-Item "$TOOLS_DIR\python3.exe" -Force
Remove-Item "$env:USERPROFILE\my-databricks-project" -Recurse -Force
Remove-Item "$env:USERPROFILE\.ai-dev-kit" -Recurse -Force
Remove-Item "$env:USERPROFILE\.databrickscfg" -Force
npm uninstall -g @anthropic-ai/claude-code 2>$null
pip uninstall -y databricks-sdk python-dotenv anthropic openai pydantic uv databricks-tools-core databricks-mcp-server 2>$null
$ErrorActionPreference = "Continue"
Write-Host "Clean slate done. Close and reopen PowerShell, then run Part 2." -ForegroundColor Green
```

Close and reopen PowerShell before Part 2.

---

## Part 2: Full install (paste all at once, press Enter, then wait ~10 min)

Git extraction alone takes several minutes. Everything else runs after it automatically.

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

## Cleanup

Delete this file from the repo when done.
