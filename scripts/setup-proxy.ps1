# setup-proxy.ps1 - One-click proxy configuration for all dev tools
# Configures npm, git, and Python to work with your corporate proxy

$ErrorActionPreference = "Stop"

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Corporate Proxy Setup" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Function to test if we're behind a proxy
function Test-ProxyRequired {
    Write-Host "Testing internet connectivity..." -ForegroundColor Cyan

    try {
        # Try to reach npm registry directly
        $null = Test-NetConnection registry.npmjs.org -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction Stop
        return $false  # Direct connection works, no proxy needed
    } catch {
        return $true   # Can't connect directly, likely need proxy
    }
}

# Function to detect Windows proxy settings
function Get-WindowsProxy {
    try {
        $proxySettings = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction Stop

        if ($proxySettings.ProxyEnable -eq 1) {
            $proxyServer = $proxySettings.ProxyServer

            # Handle different proxy formats
            if ($proxyServer -like "http=*") {
                # Format: "http=proxy:port;https=proxy:port"
                $httpProxy = ($proxyServer -split ';' | Where-Object { $_ -like "http=*" }) -replace "http=", ""
                return "http://$httpProxy"
            } else {
                # Format: "proxy.company.com:8080"
                if ($proxyServer -notlike "http://*" -and $proxyServer -notlike "https://*") {
                    return "http://$proxyServer"
                }
                return $proxyServer
            }
        }
    } catch {
        return $null
    }

    return $null
}

# Check if proxy is needed
Write-Host "Checking if proxy configuration is needed..." -ForegroundColor Gray
Write-Host ""

$needsProxy = Test-ProxyRequired

if (-not $needsProxy) {
    Write-Host "✅ Direct internet access detected!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You don't appear to be behind a proxy." -ForegroundColor White
    Write-Host "No configuration needed." -ForegroundColor White
    Write-Host ""
    $force = Read-Host "Do you want to configure a proxy anyway? (yes/no)"

    if ($force -ne "yes") {
        Write-Host "Setup skipped." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "Proxy configuration is needed." -ForegroundColor Yellow
Write-Host ""

# Try to auto-detect proxy from Windows settings
$detectedProxy = Get-WindowsProxy

if ($detectedProxy) {
    Write-Host "✅ Detected proxy from Windows settings: $detectedProxy" -ForegroundColor Green
    Write-Host ""
    $useDetected = Read-Host "Use this proxy? (yes/no)"

    if ($useDetected -eq "yes") {
        $proxyUrl = $detectedProxy
    } else {
        $proxyUrl = Read-Host "Enter proxy URL (e.g., http://proxy.company.gov:8080)"
    }
} else {
    Write-Host "Could not auto-detect proxy settings." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please get your proxy URL from your IT department." -ForegroundColor Gray
    Write-Host "Format: http://proxy.company.gov:8080" -ForegroundColor Gray
    Write-Host ""
    $proxyUrl = Read-Host "Enter proxy URL"
}

# Validate proxy URL format
if ([string]::IsNullOrWhiteSpace($proxyUrl)) {
    Write-Host "❌ Error: Proxy URL cannot be empty" -ForegroundColor Red
    exit 1
}

if ($proxyUrl -notlike "http://*" -and $proxyUrl -notlike "https://*") {
    Write-Host "⚠️  Adding http:// prefix to proxy URL" -ForegroundColor Yellow
    $proxyUrl = "http://$proxyUrl"
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Configuring Tools" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$success = $true

# Configure npm
Write-Host "[1/3] Configuring npm..." -ForegroundColor Cyan
try {
    npm config set proxy $proxyUrl
    npm config set https-proxy $proxyUrl
    Write-Host "  ✅ npm configured" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  npm configuration failed (may not be installed yet)" -ForegroundColor Yellow
}

Write-Host ""

# Configure git
Write-Host "[2/3] Configuring git..." -ForegroundColor Cyan
try {
    git config --global http.proxy $proxyUrl
    git config --global https.proxy $proxyUrl
    Write-Host "  ✅ git configured" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  git configuration failed (may not be installed yet)" -ForegroundColor Yellow
}

Write-Host ""

# Configure Python/pip via environment variables
Write-Host "[3/3] Configuring Python/pip..." -ForegroundColor Cyan
try {
    # Set for current session
    $env:HTTP_PROXY = $proxyUrl
    $env:HTTPS_PROXY = $proxyUrl

    # Set permanently for user
    [Environment]::SetEnvironmentVariable("HTTP_PROXY", $proxyUrl, "User")
    [Environment]::SetEnvironmentVariable("HTTPS_PROXY", $proxyUrl, "User")

    Write-Host "  ✅ Python/pip configured" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Python/pip configuration failed: $($_.Exception.Message)" -ForegroundColor Red
    $success = $false
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Testing Configuration" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Test npm
Write-Host "Testing npm connectivity..." -ForegroundColor Cyan
try {
    $npmPing = npm ping 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ npm can reach registry" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  npm test inconclusive" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️  npm not available for testing" -ForegroundColor Yellow
}

Write-Host ""

# Test git
Write-Host "Testing git connectivity..." -ForegroundColor Cyan
try {
    git ls-remote https://github.com/databricks/cli.git HEAD *>$null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ git can reach GitHub" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  git cannot reach GitHub yet" -ForegroundColor Yellow
        Write-Host "     This may resolve after you close and reopen your terminal" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ⚠️  git not available for testing" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if ($success) {
    Write-Host "✅ Proxy configuration complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Configured proxy: $proxyUrl" -ForegroundColor White
    Write-Host ""
    Write-Host "Tools configured:" -ForegroundColor White
    Write-Host "  • npm (Node.js package manager)" -ForegroundColor Gray
    Write-Host "  • git (version control)" -ForegroundColor Gray
    Write-Host "  • Python/pip (package installer)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚠️  Important: Close and reopen PowerShell for changes to take effect" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Close this PowerShell window" -ForegroundColor White
    Write-Host "  2. Open a new PowerShell window" -ForegroundColor White
    Write-Host "  3. Continue with the installation guide" -ForegroundColor White
} else {
    Write-Host "⚠️  Proxy configuration completed with warnings" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Some tools may need manual configuration." -ForegroundColor Yellow
    Write-Host "See SETUP-GUIDE.md for manual proxy setup instructions." -ForegroundColor Yellow
}

Write-Host ""

# Optional: Create a file to indicate proxy is configured
"Proxy configured: $proxyUrl" | Out-File -FilePath ".proxy-configured" -Encoding UTF8
