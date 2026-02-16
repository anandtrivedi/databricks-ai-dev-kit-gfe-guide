# Databricks AI Dev Kit - GFE Setup Guide

A companion guide for installing and running the [Databricks AI Dev Kit](https://github.com/databricks-solutions/ai-dev-kit) on Government Field Engineering (GFE) machines.

## What is this?

The [Databricks AI Dev Kit](https://github.com/databricks-solutions/ai-dev-kit) gives you 26+ Claude Code skills for building on Databricks - pipelines, jobs, dashboards, apps, and more. It's maintained by Databricks and gets regular updates.

**This repo** provides the missing piece: a step-by-step setup guide for GFE environments where you may not have admin privileges, face restricted networks, or need to work behind a corporate proxy.

## What's included

| File | Purpose |
|------|---------|
| [GFE-SETUP-GUIDE.md](GFE-SETUP-GUIDE.md) | Complete installation walkthrough for GFE machines |
| [QUICK-INSTALL.md](QUICK-INSTALL.md) | For machines with full privileges and internet |
| [SINGLE-PASTE-INSTALL.md](SINGLE-PASTE-INSTALL.md) | One copy-paste block for the entire GFE install |
| [setup-env.ps1](scripts/setup-env.ps1) | Interactive wizard to generate your `.env` configuration |
| [setup-proxy.ps1](scripts/setup-proxy.ps1) | Auto-detect and configure corporate proxy for all tools |
| [start.ps1](scripts/start.ps1) | PowerShell launch script for Claude Code |
| [start-demo.sh](scripts/start-demo.sh) | Bash launch script (macOS/Linux) |
| [.env.example](.env.example) | Template for environment configuration |

## Quick start

1. Read the [GFE-SETUP-GUIDE.md](GFE-SETUP-GUIDE.md) and follow the path that matches your environment
2. Install the [AI Dev Kit](https://github.com/databricks-solutions/ai-dev-kit) using the instructions in the guide
3. Run `setup-env.ps1` to configure your Databricks endpoint
4. Launch with `start.ps1`

## Prerequisites

- A Databricks workspace with a Claude serving endpoint
- A Databricks Personal Access Token (PAT)
- Internet access (direct or through a proxy)

## Upstream project

This guide is designed to work with the official AI Dev Kit. Always use the latest version:

**[github.com/databricks-solutions/ai-dev-kit](https://github.com/databricks-solutions/ai-dev-kit)**

The AI Dev Kit is actively maintained and the source of truth for skills, MCP servers, and capabilities. This repo only covers the GFE installation process.

## Compliance disclaimer

This guide is intended to help users install approved tools within the boundaries of their organization's IT policies. It does **not** attempt to bypass, circumvent, or override any security controls, network restrictions, or access policies.

Before proceeding:
- Follow your organization's software approval and installation procedures
- Verify that Node.js, Python, Git, and Claude Code are approved for use on your device
- Confirm with your IT team that downloading from the external sites referenced in this guide is permitted
- Use your organization's approved methods for obtaining Personal Access Tokens

If your organization requires tools to be provisioned through an internal process, work with your IT team to make the necessary packages available through approved channels.

## Contributing

If you find issues with the setup steps or have improvements for GFE-specific configurations, please open an issue or PR.
