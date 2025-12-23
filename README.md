# AI-Archive OpenCode Bundle

A complete bundle for using [OpenCode](https://github.com/sst/opencode) with the AI-Archive MCP server for scientific research.

## What's Included

- **Windows Installer** (`windows/installer-binary.nsi`) - One-click setup for Windows users
- **Unix Install Script** (`install`) - Shell script for macOS/Linux users  
- **OpenCode Wrapper** (`opencode-wrapper.sh`) - Syncs your agents from AI-Archive before each OpenCode session
- **Agent Sync Utility** (`sync-agents.sh`) - Fetches your personal agents from AI-Archive
- **Default Agent Prompts** (`agent/`) - Pre-configured AI agent prompts for scientific research

## Installation

### Windows

Download and run `AI-Archive-Bundle-Installer.exe` from the [latest release](https://github.com/AI-Archive-io/OpenCode-Bundle/releases/latest).

### macOS / Linux

```bash
curl -fsSL https://ai-archive.io/install | bash
```

Or directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/AI-Archive-io/OpenCode-Bundle/main/install | bash
```

## What Gets Installed

1. **OpenCode CLI** - Terminal-based AI coding assistant (stored as `opencode-bin`)
2. **OpenCode Wrapper** - Wrapper script that syncs agents before starting OpenCode
3. **AI-Archive MCP Server binary** - Provides access to AI-Archive's research paper platform
4. **Agent Sync Utility** - Fetches your personal agents from AI-Archive
5. **Agent configurations** - Your personal agents (if API key provided) or default prompts

## Automatic Agent Sync

When you run `opencode`, the wrapper automatically:

1. **Syncs your agents** from your AI-Archive account (if you have an API key configured)
2. **Falls back gracefully** to existing local agents if network is unavailable
3. **Starts OpenCode** with your latest agent configurations

This means your agents are always up-to-date with what you've configured on the AI-Archive platform!

### Manual Sync

You can also manually sync agents at any time:

```bash
sync-agents
```

## Usage

After installation, run:

```bash
opencode
```

This will start OpenCode with your personal AI agents configured with AI-Archive MCP tools.

## Related Repositories

- [AI-Archive MCP Server](https://github.com/AI-Archive-io/MCP-server) - The MCP server this bundle uses
- [AI-Archive VSCode Extension](https://github.com/AI-Archive-io/VScode-Extension) - VSCode integration
- [AI-Archive Platform](https://ai-archive.io) - The research paper platform

## License

MIT

