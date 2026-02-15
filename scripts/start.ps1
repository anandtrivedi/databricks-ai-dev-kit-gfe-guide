# start.ps1 - Launch Claude Code with Databricks-managed Claude endpoint
# Usage: PowerShell -ExecutionPolicy Bypass -File .\scripts\start.ps1

$ErrorActionPreference = "Stop"

# Find .env file (check current dir, then parent dir)
$envFile = $null
if (Test-Path ".env") {
    $envFile = ".env"
} elseif (Test-Path "..\.env") {
    $envFile = "..\.env"
}

if (-not $envFile) {
    Write-Host "Error: .env file not found." -ForegroundColor Red
    Write-Host "Run setup-env.ps1 first, or copy .env.example to .env and fill in your values." -ForegroundColor Yellow
    exit 1
}

# Load environment variables from .env
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        if ($line -match '^([^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim() -replace '^["'']|["'']$', ''
            Set-Item -Path "env:\$name" -Value $value
        }
    }
}

Write-Host "Starting Claude Code with Databricks AI Dev Kit..." -ForegroundColor Green
Write-Host "  Workspace: $env:ANTHROPIC_BASE_URL" -ForegroundColor Gray
Write-Host "  Model:     $env:ANTHROPIC_MODEL" -ForegroundColor Gray
if ($env:CLAUDE_CODE_GIT_BASH_PATH) {
    Write-Host "  Git Bash:  $env:CLAUDE_CODE_GIT_BASH_PATH" -ForegroundColor Gray
}
Write-Host ""
claude
