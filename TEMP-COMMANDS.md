# Temp Commands - Fix bash and run AI Dev Kit installer

## 1. Set tools dir

```powershell
$TOOLS_DIR = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
```

## 2. Remove stale bash.exe from Scripts root

```powershell
Remove-Item "$TOOLS_DIR\bash.exe" -Force
Write-Host "Removed stale bash.exe" -ForegroundColor Green
```

## 3. Verify bash now resolves to git\bin

```powershell
(Get-Command bash).Source
```

Should show `...\Scripts\git\bin\bash.exe`, NOT `...\Scripts\bash.exe`.

## 4. Make sure python3 and uv are available

```powershell
Copy-Item (Get-Command python).Source "$TOOLS_DIR\git\usr\bin\python3.exe" -Force
Write-Host "python3 ready" -ForegroundColor Green
```

```powershell
pip install uv
```

## 5. Run the official installer

```powershell
cd "$env:USERPROFILE\my-databricks-project"
```

```powershell
bash -c "curl -sL https://raw.githubusercontent.com/databricks-solutions/ai-dev-kit/main/install.sh -o install.sh && bash install.sh"
```

When prompted:
1. Select tools → Claude Code
2. Select profile → my-workspace
3. Select scope → Project

## Cleanup

Delete this file from the repo when done.
