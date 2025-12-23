#!/usr/bin/env bash
# OpenCode Wrapper with AI-Archive Agent Sync
# This wrapper syncs the user's agents from AI-Archive before starting OpenCode.
# The actual OpenCode binary is stored as opencode-bin in the same directory.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC_SCRIPT="$HOME/.ai-archive/bin/sync-agents"

# Sync agents before starting (silent on success, shows warning on failure)
if [ -x "$SYNC_SCRIPT" ]; then
  "$SYNC_SCRIPT"
fi

# Run the actual OpenCode binary with all arguments
exec "$SCRIPT_DIR/opencode-bin" "$@"
