# Temp Commands - Manual AI Dev Kit Installation

The bash installer doesn't work with portable Git on Windows. Use these PowerShell commands instead.

## 1. Create project directory

```powershell
$PROJECT_DIR = "$env:USERPROFILE\my-databricks-project"
New-Item -ItemType Directory -Force -Path $PROJECT_DIR
cd $PROJECT_DIR
```

## 2. Download AI Dev Kit

```powershell
python -c "import urllib.request; print('Downloading...'); urllib.request.urlretrieve('https://github.com/databricks-solutions/ai-dev-kit/archive/refs/heads/main.zip', 'ai-dev-kit.zip'); print('Done.')"
```

## 3. Extract and copy files

```powershell
Expand-Archive ai-dev-kit.zip -DestinationPath "$env:TEMP\ai-dev-kit-extract" -Force
```

```powershell
$extracted = Get-ChildItem "$env:TEMP\ai-dev-kit-extract" -Directory | Select-Object -First 1
```

Copy skills to project:

```powershell
$targetSkills = "$PROJECT_DIR\.claude\skills"
New-Item -ItemType Directory -Force -Path $targetSkills
Copy-Item "$($extracted.FullName)\.claude\skills\*" -Destination $targetSkills -Recurse -Force
Write-Host "Skills copied" -ForegroundColor Green
```

Copy MCP server files:

```powershell
$aiDevKitDir = "$env:USERPROFILE\.ai-dev-kit"
New-Item -ItemType Directory -Force -Path $aiDevKitDir
Copy-Item "$($extracted.FullName)\*" -Destination $aiDevKitDir -Recurse -Force
Write-Host "MCP server files copied" -ForegroundColor Green
```

Cleanup:

```powershell
Remove-Item "$env:TEMP\ai-dev-kit-extract" -Recurse -Force
Remove-Item "ai-dev-kit.zip"
```

## 4. Install Python dependencies

```powershell
pip install databricks-sdk python-dotenv anthropic openai pydantic
```

```powershell
pip install "$env:USERPROFILE\.ai-dev-kit\databricks-tools-core"
```

```powershell
pip install "$env:USERPROFILE\.ai-dev-kit\databricks-mcp-server"
```

## 5. Create MCP config

```powershell
cd "$env:USERPROFILE\my-databricks-project"
```

```powershell
python -c "import json; json.dump({'mcpServers': {'databricks': {'command': 'python', 'args': ['-m', 'databricks_mcp_server'], 'env': {'DATABRICKS_CONFIG_PROFILE': 'my-workspace'}}}}, open('.mcp.json', 'w'), indent=2)"
```

```powershell
Write-Host "MCP config created" -ForegroundColor Green
```

## 6. Verify

```powershell
python -c "import databricks_mcp_server; print('MCP server OK')"
```

```powershell
Test-Path "$env:USERPROFILE\my-databricks-project\.claude\skills"
```

```powershell
Test-Path "$env:USERPROFILE\my-databricks-project\.mcp.json"
```

All three should print True/OK. Done — continue with "Configure and Launch" in the main guide.

## Cleanup

Delete this file from the repo when done.
