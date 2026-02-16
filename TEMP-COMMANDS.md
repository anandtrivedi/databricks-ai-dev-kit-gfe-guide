# Temp Commands - AI Dev Kit Installer Fix

Start fresh from step 1.

## 1. Set tools dir

```powershell
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
```

## 2. Check where python3.exe is

```powershell
Write-Host "git\bin: $(Test-Path "$TOOLS_DIR\git\bin\python3.exe")"
```

```powershell
Write-Host "git\usr\bin: $(Test-Path "$TOOLS_DIR\git\usr\bin\python3.exe")"
```

## 3. Copy python3.exe to BOTH locations

```powershell
Copy-Item (Get-Command python).Source "$TOOLS_DIR\git\bin\python3.exe" -Force
```

```powershell
Copy-Item (Get-Command python).Source "$TOOLS_DIR\git\usr\bin\python3.exe" -Force
```

```powershell
Write-Host "Copied python3.exe to git\bin and git\usr\bin" -ForegroundColor Green
```

## 4. Verify bash can find it now

```powershell
bash -c "which python3"
```

## 5. If step 4 STILL says not found, check what PATH bash sees

```powershell
bash -c "echo `$PATH"
```

## 6. Try with explicit PATH (note the backtick before $PATH)

```powershell
$bashDir = ($TOOLS_DIR -replace '\\','/') -replace '^([A-Za-z]):','/$1'
```

```powershell
Write-Host "bash path: $bashDir" -ForegroundColor Gray
```

```powershell
bash -c "export PATH='$bashDir/git/bin:$bashDir/git/usr/bin:$bashDir/databricks:$bashDir/nodejs:`$PATH'; which python3 && which databricks && which node && echo 'All tools found'"
```

## 7. Once python3 is found, run the installer

```powershell
cd "$env:USERPROFILE\my-databricks-project"
```

Download install.sh with Python (curl isn't available in portable Git):

```powershell
python -c "import urllib.request; urllib.request.urlretrieve('https://raw.githubusercontent.com/databricks-solutions/ai-dev-kit/main/install.sh', 'install.sh'); print('Done.')"
```

Install uv (Python package manager the installer now requires):

```powershell
pip install uv
```

Run the installer (now includes Scripts dir for uv):

```powershell
bash -c "export PATH='$bashDir:$bashDir/git/bin:$bashDir/git/usr/bin:$bashDir/databricks:$bashDir/nodejs:`$PATH'; bash install.sh"
```

## Cleanup

Delete this file from the repo when done.
