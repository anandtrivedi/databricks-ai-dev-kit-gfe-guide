# Temp Commands - AI Dev Kit Installer Fix

Start fresh from step 1.

## 1. Set tools dir

```powershell
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
```

## 2. Copy python3.exe to git\bin

```powershell
Copy-Item (Get-Command python).Source "$TOOLS_DIR\git\bin\python3.exe" -Force
```

```powershell
Write-Host "python3 ready: $(Test-Path "$TOOLS_DIR\git\bin\python3.exe")" -ForegroundColor Green
```

## 3. Install uv

```powershell
pip install uv
```

## 4. Set bash-style path

```powershell
$bashDir = ($TOOLS_DIR -replace '\\','/') -replace '^([A-Za-z]):','/$1'
```

```powershell
Write-Host "bash path: $bashDir" -ForegroundColor Gray
```

## 5. Verify bash can find all tools

```powershell
bash -c "export PATH='${bashDir}:${bashDir}/git/bin:${bashDir}/databricks:${bashDir}/nodejs:`$PATH'; which python3 && which databricks && which node && which uv && echo 'All tools found'"
```

## 6. Download install.sh

```powershell
cd "$env:USERPROFILE\my-databricks-project"
```

```powershell
python -c "import urllib.request; urllib.request.urlretrieve('https://raw.githubusercontent.com/databricks-solutions/ai-dev-kit/main/install.sh', 'install.sh'); print('Done.')"
```

## 7. Run the installer

```powershell
bash -c "export PATH='${bashDir}:${bashDir}/git/bin:${bashDir}/databricks:${bashDir}/nodejs:`$PATH'; bash install.sh"
```

## Cleanup

Delete this file from the repo when done.
