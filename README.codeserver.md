# Openclaw + Code-Server Docker Image

A browser-based VS Code (code-server) with Openclaw pre-installed, designed for Railway deployment.

## Features

- **code-server**: Full VS Code in your browser
- **Openclaw**: AI coding assistant pre-installed and available via `openclaw` command
- **Mobile-Optimized**: tmux with touch-friendly config, optimized VS Code settings
- **Dev Tools**: Node.js 22, Bun, pnpm, Python 3, build-essential, git, Homebrew
- **Persistence**: All config and workspace files stored in `/data` volume

## Quick Start (Local)

### Using Docker Compose

```bash
docker compose -f docker-compose.codeserver.yml up --build
```

Then open http://localhost:8080 (password: `changeme`)

### Using Docker directly

```bash
# Build
docker build -f Dockerfile.codeserver -t openclaw-codeserver .

# Run
docker run --rm -p 8080:8080 \
  -e PASSWORD=mysecret \
  -v openclaw-data:/data \
  openclaw-codeserver
```

## Railway Deployment

### Option 1: Use the code-server Dockerfile

1. Rename or copy `railway.codeserver.toml` to `railway.toml`
2. Deploy to Railway
3. Add a volume mounted at `/data`
4. Set `PASSWORD` environment variable in Railway Variables

### Option 2: Configure via Railway CLI

```bash
railway link --config railway.codeserver.toml
railway up
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Port for code-server |
| `PASSWORD` | `changeme` | Password for code-server access |
| `CS_AUTH` | `password` | Auth method: `password` or `none` |
| `OPENCLAW_STATE_DIR` | `/data/.openclaw` | Openclaw config directory |
| `OPENCLAW_WORKSPACE_DIR` | `/data/workspace` | Openclaw workspace directory |
| `OPENCLAW_GIT_REF` | `main` | Git ref to build Openclaw from |

## Persistence

All persistent data is stored in `/data`:

```
/data/
├── .openclaw/          # Openclaw configuration and state
├── .config/            # code-server and VS Code config
│   ├── code-server/
│   │   └── config.yaml
│   └── Code/User/
│       └── settings.json
├── .tmux/              # tmux configuration
│   └── .tmux.conf
└── workspace/          # Your projects and files
```

**Railway**: Mount a volume at `/data` to persist across deployments.

## Using Openclaw

Once code-server is running, open a terminal and use the `openclaw` CLI:

```bash
# Check openclaw is installed
openclaw --version

# Run openclaw onboarding
openclaw onboard

# Start openclaw gateway (if using gateway mode)
openclaw gateway run
```

## Mobile Usage & tmux

The image includes tmux with a mobile-friendly configuration. The default terminal profile opens a tmux session automatically.

### tmux Quick Reference

| Action | Keys |
|--------|------|
| Prefix key | `Ctrl+a` (easier than Ctrl+b on mobile) |
| Split horizontal | `Prefix` + `-` |
| Split vertical | `Prefix` + `\|` |
| Navigate panes | `Prefix` + `h/j/k/l` (vim-style) |
| Resize panes | `Prefix` + Arrow keys |
| Switch windows | `Prefix` + number |
| Last window | `Prefix` + `Ctrl+a` (double-tap) |
| New window | `Prefix` + `c` |
| Kill pane | `Prefix` + `x` |
| Session picker | `Prefix` + `S` |
| Reload config | `Prefix` + `r` |

### Mobile-Optimized Settings

- **Mouse/touch support enabled** - scroll, select, resize panes
- **Larger fonts** - 14px default in terminal and editor
- **Minimal UI** - activity bar on top, no minimap, compact menu
- **Word wrap enabled** - no horizontal scrolling needed
- **Persistent sessions** - reconnect to your tmux session

### Customizing tmux

Edit `/data/.tmux/.tmux.conf` to customize. Changes persist across restarts.

## Dev Tools Included

- **Node.js 22** with npm, corepack (pnpm, yarn)
- **Bun** runtime
- **Python 3** with pip and venv
- **Build tools**: gcc, g++, make, pkg-config
- **Homebrew** for additional packages
- **Utilities**: git, curl, wget, vim, nano, htop, jq, rsync, ssh, **tmux**

## Security Notes

- **Always set a strong `PASSWORD`** when deploying publicly
- Set `CS_AUTH=none` only in trusted/private networks
- Railway provides HTTPS automatically on `*.up.railway.app` domains
