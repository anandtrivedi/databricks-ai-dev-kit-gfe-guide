# Container Install

Run the full AI Dev Kit environment in a container — nothing to install except Docker.

## Prerequisites

IT must provision one of the following on the GFE machine:
- **Docker Desktop** (runs Linux containers on Windows by default)
- **Podman Desktop** (rootless alternative)

## Build the image

On a machine with internet access (can be done once by an admin):

```
docker build -t ai-dev-kit .
```

To distribute without a registry, export and copy the image file:

```
docker save ai-dev-kit | gzip > ai-dev-kit.tar.gz
```

On the GFE machine, load it:

```
docker load < ai-dev-kit.tar.gz
```

## Configure credentials

Create your Databricks CLI profile (one time):

```
@"
[my-workspace]
host  = https://your-workspace.cloud.databricks.com
token = dapi...
"@ | Out-File -FilePath "$env:USERPROFILE\.databrickscfg" -Encoding ASCII
```

Create your `.env` file (one time) — see [.env.example](.env.example) for the template.

## Run

```
docker run -it --rm ^
  -v %USERPROFILE%\.databrickscfg:/home/dev/.databrickscfg:ro ^
  -v %USERPROFILE%\.env:/home/dev/my-databricks-project/.env:ro ^
  ai-dev-kit
```

This starts Claude Code in the project directory with skills and MCP server ready.

## What's in the container

| Tool | Version |
|------|---------|
| Python | 3.11 |
| Node.js | 20.18.1 |
| Git | latest (apt) |
| Databricks CLI | latest |
| Claude Code | latest |
| AI Dev Kit | latest (skills + MCP server) |

## Updating

Rebuild the image to pick up the latest Claude Code and AI Dev Kit:

```
docker build --no-cache -t ai-dev-kit .
```
