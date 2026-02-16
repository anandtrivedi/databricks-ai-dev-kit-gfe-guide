# Temp Commands - AI Dev Kit Installer Fix

## 1. Check what bash sees

```powershell
bash -c "echo $PATH"
```

## 2. Set tools dir

```powershell
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
```

## 3. Copy python3 (with confirmation)

```powershell
Copy-Item (Get-Command python).Source "$TOOLS_DIR\git\bin\python3.exe" -Force
Write-Host "python3 ready: $TOOLS_DIR\git\bin\python3.exe" -ForegroundColor Green
```

## 4. Verify bash can find python3

```powershell
bash -c "which python3"
```

## 5. If step 4 says "not found", run the installer with explicit PATH

```powershell
$bashDir = ($TOOLS_DIR -replace '\\','/') -replace '^([A-Za-z]):','/$1'
```

```powershell
bash -c "export PATH='$bashDir/git/bin:$PATH'; which python3 && echo 'python3 found' || echo 'python3 NOT found'"
```

## 6. Run the installer with explicit PATH

```powershell
cd "$env:USERPROFILE\my-databricks-project"
```

```powershell
bash -c "export PATH='$bashDir/git/bin:$PATH'; curl -sL https://raw.githubusercontent.com/databricks-solutions/ai-dev-kit/main/install.sh -o install.sh && bash install.sh"
```

## Cleanup

Delete this file from the repo when done.
