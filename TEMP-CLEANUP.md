# Cleanup

Removes everything installed by the single-paste install. Paste into PowerShell and press **Enter**.

> This only removes tools and directories created by the install script. It does **not** touch Python itself, your `.databrickscfg`, or anything else.

```powershell
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
Write-Host "Tools directory: $TOOLS_DIR" -ForegroundColor Gray
Write-Host ""
Write-Host "Removing installed tools..." -ForegroundColor Cyan
if (Test-Path "$TOOLS_DIR\nodejs") { Remove-Item "$TOOLS_DIR\nodejs" -Recurse -Force; Write-Host "  Removed nodejs" -ForegroundColor Yellow }
if (Test-Path "$TOOLS_DIR\git") { Remove-Item "$TOOLS_DIR\git" -Recurse -Force; Write-Host "  Removed git" -ForegroundColor Yellow }
if (Test-Path "$TOOLS_DIR\databricks") { Remove-Item "$TOOLS_DIR\databricks" -Recurse -Force; Write-Host "  Removed databricks" -ForegroundColor Yellow }
if (Test-Path "$TOOLS_DIR\bash.exe") { Remove-Item "$TOOLS_DIR\bash.exe" -Force; Write-Host "  Removed stale bash.exe" -ForegroundColor Yellow }
if (Test-Path "$TOOLS_DIR\node.exe") { Remove-Item "$TOOLS_DIR\node.exe" -Force; Write-Host "  Removed stale node.exe" -ForegroundColor Yellow }
Write-Host "Removing project directory..." -ForegroundColor Cyan
if (Test-Path "$env:USERPROFILE\my-databricks-project") { Remove-Item "$env:USERPROFILE\my-databricks-project" -Recurse -Force; Write-Host "  Removed my-databricks-project" -ForegroundColor Yellow }
Write-Host "Removing AI Dev Kit..." -ForegroundColor Cyan
if (Test-Path "$env:USERPROFILE\.ai-dev-kit") { Remove-Item "$env:USERPROFILE\.ai-dev-kit" -Recurse -Force; Write-Host "  Removed .ai-dev-kit" -ForegroundColor Yellow }
Write-Host "Uninstalling Python packages..." -ForegroundColor Cyan
pip uninstall -y databricks-mcp-server databricks-tools-core databricks-sdk python-dotenv anthropic openai pydantic 2>$null
Write-Host "Cleaning PATH..." -ForegroundColor Cyan
$currentPath = (Get-ItemProperty "HKCU:\Environment").Path
$cleanPath = ($currentPath -split ";" | Where-Object { $_ -notmatch "nodejs|git\\bin|\\databricks" }) -join ";"
setx PATH "$cleanPath"
Write-Host ""
Write-Host "===== CLEANUP COMPLETE =====" -ForegroundColor Green
Write-Host "Close and reopen PowerShell for PATH changes to take effect." -ForegroundColor Yellow
```
