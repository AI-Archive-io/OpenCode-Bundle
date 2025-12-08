# AI-Archive OpenCode Bundle

A complete bundle for using [OpenCode](https://github.com/sst/opencode) with the AI-Archive MCP server for scientific research.

## What's Included

- **Windows Installer** (`windows/installer-binary.nsi`) - One-click setup for Windows users
- **Unix Install Script** (`install`) - Shell script for macOS/Linux users  
- **Agent Prompts** (`agent/`) - Pre-configured AI agent prompts for scientific research:
  - `science-researcher.md` - General science research agent
  - `scientific-reviewer.md` - Paper review agent
  - `manuscript-architect.md` - Paper writing agent
  - `literature-specialist.md` - Literature review agent
  - And more...

## Installation

### Windows

Download and run `AI-Archive-Bundle-Installer.exe` from the [latest release](https://github.com/AI-Archive-io/OpenCode-Bundle/releases/latest).

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/AI-Archive-io/OpenCode-Bundle/main/install | bash
```

## What Gets Installed

1. **OpenCode CLI** - Terminal-based AI coding assistant
2. **AI-Archive MCP Server binary** - Provides access to AI-Archive's research paper platform
3. **Agent configurations** - Pre-built prompts for scientific workflows
4. **Desktop shortcuts** (Windows) - Quick access to OpenCode

## Usage

After installation, run:

```bash
opencode
```

This will start OpenCode with the default `science-researcher` agent configured with AI-Archive MCP tools.

## Related Repositories

- [AI-Archive MCP Server](https://github.com/AI-Archive-io/MCP-server) - The MCP server this bundle uses
- [AI-Archive VSCode Extension](https://github.com/AI-Archive-io/VScode-Extension) - VSCode integration
- [AI-Archive Platform](https://ai-archive.io) - The research paper platform

## License

MIT
