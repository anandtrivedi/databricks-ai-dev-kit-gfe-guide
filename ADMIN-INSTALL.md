# Admin Prerequisites Installation

**For Databricks administrators setting up shared machines or users on non-GFE corporate laptops.**

This is a supplementary reference for environments where you have local admin privileges and unrestricted internet access. Most GFE users should follow the main [GFE Setup Guide](GFE-SETUP-GUIDE.md) instead.

## Install prerequisites

Install the prerequisites using standard installers:
- **Node.js LTS:** https://nodejs.org/
- **Python 3.11+:** https://www.python.org/downloads/ (check "Add to PATH")
- **Git:** https://git-scm.com/download/win
- **Databricks CLI:** https://github.com/databricks/cli/releases

Close and reopen PowerShell, then verify: `node --version && python --version && git --version && databricks --version`

## Configure Databricks CLI and install Claude Code

```powershell
# Configure Databricks CLI (replace with your actual workspace URL and token)
@"
[my-workspace]
host  = https://your-workspace.cloud.databricks.com
token = dapi1234567890abcdef...
"@ | Out-File -FilePath "$env:USERPROFILE\.databrickscfg" -Encoding ASCII

# Install Claude Code
npm install -g @anthropic-ai/claude-code
claude --version
```

## Next steps

Continue with the [Install AI Dev Kit](GFE-SETUP-GUIDE.md#install-ai-dev-kit) section in the main guide.
