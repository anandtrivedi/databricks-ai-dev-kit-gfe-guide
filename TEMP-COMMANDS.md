# Full Clean Install Test

## Part 1: Clean slate

```powershell
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
```

```powershell
Remove-Item "$TOOLS_DIR\nodejs" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$TOOLS_DIR\git" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$TOOLS_DIR\databricks" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$TOOLS_DIR\bash.exe" -Force -ErrorAction SilentlyContinue
Remove-Item "$TOOLS_DIR\node.exe" -Force -ErrorAction SilentlyContinue
Remove-Item "$TOOLS_DIR\python3.exe" -Force -ErrorAction SilentlyContinue
Write-Host "Tools removed" -ForegroundColor Green
```

```powershell
Remove-Item "$env:USERPROFILE\my-databricks-project" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:USERPROFILE\.ai-dev-kit" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:USERPROFILE\.databrickscfg" -Force -ErrorAction SilentlyContinue
Write-Host "Project and config removed" -ForegroundColor Green
```

```powershell
npm uninstall -g @anthropic-ai/claude-code 2>$null
pip uninstall -y databricks-sdk python-dotenv anthropic openai pydantic uv 2>$null
pip uninstall -y databricks-tools-core databricks-mcp-server 2>$null
Write-Host "Packages removed" -ForegroundColor Green
```

Verify clean:

```powershell
Write-Host "node: $(Get-Command node -ErrorAction SilentlyContinue)" ; Write-Host "git: $(Get-Command git -ErrorAction SilentlyContinue)" ; Write-Host "claude: $(Get-Command claude -ErrorAction SilentlyContinue)" ; Write-Host "databricks: $(Get-Command databricks -ErrorAction SilentlyContinue)"
```

All should be blank or show errors. If anything still resolves, close and reopen PowerShell.

---

## Part 2: Full install

### Python check

```powershell
python --version
```

### Set tools dir

```powershell
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
Write-Host "Tools directory: $TOOLS_DIR"
New-Item -ItemType Directory -Force -Path $TOOLS_DIR | Out-Null
cd $TOOLS_DIR
```

### Install Node.js

```powershell
$NODE_VERSION = "20.18.1"
python -c "import urllib.request; urllib.request.urlretrieve('https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-win-x64.zip', 'node.zip')"
Expand-Archive node.zip -DestinationPath . -Force
if (Test-Path "nodejs") { Remove-Item "nodejs" -Recurse -Force }
Rename-Item "node-v$NODE_VERSION-win-x64" "nodejs"
Remove-Item node.zip
Write-Host "Node.js installed" -ForegroundColor Green
```

### Install Git — download

```powershell
python -c "import urllib.request; print('Downloading Git...'); urllib.request.urlretrieve('https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.tar.bz2', 'git.tar.bz2'); print('Done.')"
```

### Install Git — extract (takes several minutes)

```powershell
python -c "import tarfile; print('Extracting Git (this takes a few minutes)...'); tarfile.open('git.tar.bz2').extractall('git'); print('Done.')"
Remove-Item git.tar.bz2
Write-Host "Git installed" -ForegroundColor Green
```

### Install Databricks CLI

```powershell
python -c "import urllib.request,json; tag=json.loads(urllib.request.urlopen('https://api.github.com/repos/databricks/cli/releases/latest').read())['tag_name']; v=tag.lstrip('v'); print(f'Downloading Databricks CLI {tag}...'); urllib.request.urlretrieve(f'https://github.com/databricks/cli/releases/download/{tag}/databricks_cli_{v}_windows_amd64.zip','databricks.zip'); print('Done.')"
Expand-Archive databricks.zip -DestinationPath "databricks" -Force
Remove-Item databricks.zip
Write-Host "Databricks CLI installed" -ForegroundColor Green
```

### Update PATH

```powershell
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
$env:PATH += ";$TOOLS_DIR\nodejs;$TOOLS_DIR\git\bin;$TOOLS_DIR\databricks"
$userPath = (Get-ItemProperty "HKCU:\Environment").Path + ";$TOOLS_DIR\nodejs;$TOOLS_DIR\git\bin;$TOOLS_DIR\databricks"
setx PATH "$userPath"
Write-Host "PATH updated" -ForegroundColor Green
```

### Verify prerequisites

```powershell
node --version
```

```powershell
npm --version
```

```powershell
git --version
```

```powershell
databricks --version
```

### Configure Databricks CLI (replace placeholders with your values)

```powershell
"[my-workspace]", "host  = https://REPLACE-WITH-YOUR-WORKSPACE-URL", "token = REPLACE-WITH-YOUR-PAT" | Out-File "$env:USERPROFILE\.databrickscfg" -Encoding ASCII
```

### Install Claude Code

```powershell
npm install -g @anthropic-ai/claude-code
```

```powershell
claude --version
```

### Install AI Dev Kit — create project

```powershell
$PROJECT_DIR = "$env:USERPROFILE\my-databricks-project"
New-Item -ItemType Directory -Force -Path $PROJECT_DIR
cd $PROJECT_DIR
```

### Install AI Dev Kit — download

```powershell
python -c "import urllib.request; print('Downloading AI Dev Kit...'); urllib.request.urlretrieve('https://github.com/databricks-solutions/ai-dev-kit/archive/refs/heads/main.zip', 'ai-dev-kit.zip'); print('Done.')"
```

### Install AI Dev Kit — extract

```powershell
Expand-Archive ai-dev-kit.zip -DestinationPath "$env:TEMP\ai-dev-kit-extract" -Force
$extracted = Get-ChildItem "$env:TEMP\ai-dev-kit-extract" -Directory | Select-Object -First 1
```

### Install AI Dev Kit — copy skills

```powershell
$targetSkills = "$PROJECT_DIR\.claude\skills"
New-Item -ItemType Directory -Force -Path $targetSkills
Copy-Item "$($extracted.FullName)\.claude\skills\*" -Destination $targetSkills -Recurse -Force
Write-Host "Skills copied" -ForegroundColor Green
```

### Install AI Dev Kit — copy MCP server files

```powershell
$aiDevKitDir = "$env:USERPROFILE\.ai-dev-kit"
New-Item -ItemType Directory -Force -Path $aiDevKitDir
Copy-Item "$($extracted.FullName)\*" -Destination $aiDevKitDir -Recurse -Force
Write-Host "MCP server files copied" -ForegroundColor Green
```

### Install AI Dev Kit — cleanup

```powershell
Remove-Item "$env:TEMP\ai-dev-kit-extract" -Recurse -Force
Remove-Item "ai-dev-kit.zip"
```

### Install AI Dev Kit — Python dependencies

```powershell
pip install databricks-sdk python-dotenv anthropic openai pydantic
```

```powershell
pip install "$env:USERPROFILE\.ai-dev-kit\databricks-tools-core"
```

```powershell
pip install "$env:USERPROFILE\.ai-dev-kit\databricks-mcp-server"
```

### Create MCP config

```powershell
cd "$env:USERPROFILE\my-databricks-project"
```

```powershell
python -c "import json; json.dump({'mcpServers': {'databricks': {'command': 'python', 'args': ['-m', 'databricks_mcp_server'], 'env': {'DATABRICKS_CONFIG_PROFILE': 'my-workspace'}}}}, open('.mcp.json', 'w'), indent=2)"
Write-Host "MCP config created" -ForegroundColor Green
```

### Verify AI Dev Kit

```powershell
python -c "import databricks_mcp_server; print('MCP server OK')"
```

```powershell
Test-Path "$env:USERPROFILE\my-databricks-project\.claude\skills"
```

```powershell
Test-Path "$env:USERPROFILE\my-databricks-project\.mcp.json"
```

All three should show OK/True. Installation complete.

To finish setup, create `.env` and `start.ps1` from the "Configure and Launch" section in the main guide once you have your Databricks endpoint details.

## Cleanup

Delete this file from the repo when done.
