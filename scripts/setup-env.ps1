# setup-env.ps1 - Interactive .env file generator for Databricks AI Dev Kit
# This script helps you configure Claude Code with your Databricks workspace

$ErrorActionPreference = "Stop"

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Databricks AI Dev Kit - Environment Setup" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if .env already exists
if (Test-Path ".env") {
    Write-Host "⚠️  Warning: .env file already exists" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (yes/no)"
    if ($overwrite -ne "yes") {
        Write-Host "Setup cancelled. Your existing .env file was not modified." -ForegroundColor Green
        exit 0
    }
    Write-Host ""
}

# Function to prompt for input with validation
function Get-ValidatedInput {
    param(
        [string]$Prompt,
        [string]$Description,
        [string]$Example,
        [bool]$Required = $true,
        [bool]$IsSecret = $false
    )

    Write-Host $Description -ForegroundColor Gray
    if ($Example) {
        Write-Host "Example: $Example" -ForegroundColor DarkGray
    }

    do {
        if ($IsSecret) {
            $value = Read-Host -Prompt $Prompt -AsSecureString
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($value)
            $value = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        } else {
            $value = Read-Host -Prompt $Prompt
        }

        if ([string]::IsNullOrWhiteSpace($value) -and $Required) {
            Write-Host "❌ This field is required. Please enter a value." -ForegroundColor Red
        } else {
            return $value.Trim()
        }
    } while ($true)
}

Write-Host "This script will collect your Databricks configuration and create a .env file." -ForegroundColor Cyan
Write-Host "You'll need information from your Databricks administrator." -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Enter to continue..." -ForegroundColor Yellow
Read-Host

Clear-Host

# Collect configuration
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Step 1/4: Databricks Workspace URL" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$workspaceUrl = Get-ValidatedInput `
    -Prompt "Workspace URL" `
    -Description "Enter your Databricks workspace URL (without trailing slash)" `
    -Example "https://your-workspace.cloud.databricks.com"

# Clean up URL (remove trailing slash if present)
$workspaceUrl = $workspaceUrl.TrimEnd('/')

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Step 2/4: Claude Serving Endpoint" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$endpointName = Get-ValidatedInput `
    -Prompt "Endpoint name" `
    -Description "Enter the serving endpoint name (ask your Databricks admin)" `
    -Example "claude-endpoint"

$baseUrl = "$workspaceUrl/serving-endpoints/$endpointName"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Step 3/4: Model Configuration" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Select the Claude model:" -ForegroundColor Gray
Write-Host "  1) databricks-claude-sonnet-4-5 (recommended)" -ForegroundColor White
Write-Host "  2) databricks-claude-opus-4-6 (more capable, slower)" -ForegroundColor White
Write-Host "  3) Custom model name" -ForegroundColor White
Write-Host ""

$modelChoice = Read-Host "Enter choice (1-3)"

switch ($modelChoice) {
    "1" { $modelName = "databricks-claude-sonnet-4-5" }
    "2" { $modelName = "databricks-claude-opus-4-6" }
    "3" {
        $modelName = Get-ValidatedInput `
            -Prompt "Model name" `
            -Description "Enter the custom model name" `
            -Example "databricks-claude-sonnet-4-5"
    }
    default {
        Write-Host "Invalid choice. Using default: databricks-claude-sonnet-4-5" -ForegroundColor Yellow
        $modelName = "databricks-claude-sonnet-4-5"
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Step 4/4: Authentication Token" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$authToken = Get-ValidatedInput `
    -Prompt "PAT Token" `
    -Description "Enter your Databricks Personal Access Token (input will be hidden)" `
    -Example "dapi1234567890abcdef..." `
    -IsSecret $true

# Validate token format
if (-not $authToken.StartsWith("dapi")) {
    Write-Host "⚠️  Warning: Token doesn't start with 'dapi'. This may be incorrect." -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (yes/no)"
    if ($continue -ne "yes") {
        Write-Host "Setup cancelled." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Configuration Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Workspace URL:  $workspaceUrl" -ForegroundColor White
Write-Host "Endpoint:       $endpointName" -ForegroundColor White
Write-Host "Model:          $modelName" -ForegroundColor White
Write-Host "Token:          $($authToken.Substring(0, [Math]::Min(10, $authToken.Length)))..." -ForegroundColor White
Write-Host ""
Write-Host "Full Base URL:  $baseUrl" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "Create .env file with these settings? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Setup cancelled. No files were created." -ForegroundColor Yellow
    exit 0
}

# Create .env file content
$envContent = @"
# Databricks AI Dev Kit Configuration
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# The model name on your Databricks serving endpoint
ANTHROPIC_MODEL=$modelName

# Your workspace URL + serving endpoint path
ANTHROPIC_BASE_URL=$baseUrl

# PAT token for the Claude serving endpoint
ANTHROPIC_AUTH_TOKEN=$authToken

# Required header for coding agent mode
ANTHROPIC_CUSTOM_HEADERS=x-databricks-use-coding-agent-mode: true

# Disable experimental features for stability
CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1
"@

# Write .env file
try {
    $envContent | Out-File -FilePath ".env" -Encoding UTF8 -NoNewline
    Write-Host ""
    Write-Host "✅ Success! .env file created." -ForegroundColor Green
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Next Steps" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Your .env file has been created in the current directory" -ForegroundColor White
    Write-Host "2. Run the start script to launch Claude Code:" -ForegroundColor White
    Write-Host ""
    Write-Host "   PowerShell -ExecutionPolicy Bypass -File .\scripts\start.ps1" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "⚠️  Security Note: Never commit .env to git (it contains secrets)" -ForegroundColor Yellow
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "❌ Error creating .env file: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please make sure you have write permissions in the current directory." -ForegroundColor Yellow
    exit 1
}

# Optional: Test connection
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Optional: Test Connection" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
$testConnection = Read-Host "Would you like to test the endpoint connection? (yes/no)"

if ($testConnection -eq "yes") {
    Write-Host ""
    Write-Host "Testing connection to $baseUrl..." -ForegroundColor Cyan

    try {
        $headers = @{
            "Authorization" = "Bearer $authToken"
            "Content-Type" = "application/json"
        }

        # Test basic connectivity
        $response = Invoke-WebRequest -Uri $baseUrl -Method GET -Headers $headers -TimeoutSec 10 -ErrorAction Stop

        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Connection successful! Endpoint is reachable." -ForegroundColor Green
        } else {
            Write-Host "⚠️  Received status code: $($response.StatusCode)" -ForegroundColor Yellow
            Write-Host "The endpoint may still work, but returned an unexpected response." -ForegroundColor Yellow
        }
    } catch {
        $errorMessage = $_.Exception.Message

        if ($errorMessage -like "*404*") {
            Write-Host "❌ Endpoint not found (404)" -ForegroundColor Red
            Write-Host "Please verify the endpoint name is correct." -ForegroundColor Yellow
        } elseif ($errorMessage -like "*401*" -or $errorMessage -like "*403*") {
            Write-Host "❌ Authentication failed (401/403)" -ForegroundColor Red
            Write-Host "Please verify your token has permission to access this endpoint." -ForegroundColor Yellow
        } elseif ($errorMessage -like "*proxy*" -or $errorMessage -like "*network*") {
            Write-Host "❌ Network connection failed" -ForegroundColor Red
            Write-Host "You may need to configure proxy settings (see SETUP-GUIDE.md Step 1)" -ForegroundColor Yellow
        } else {
            Write-Host "❌ Connection test failed: $errorMessage" -ForegroundColor Red
        }

        Write-Host ""
        Write-Host "Your .env file was still created. You can try running Claude Code anyway." -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "Setup complete! 🎉" -ForegroundColor Green
Write-Host ""
