#!/usr/bin/env bash
# AI-Archive Agent Sync Utility
# Fetches the user's agents from AI-Archive and writes them to the OpenCode config directory.
# Called by the opencode wrapper before starting OpenCode.

set -uo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[AI-Archive] $*${NC}"; }
warn() { echo -e "${YELLOW}[AI-Archive] $*${NC}"; }
error() { echo -e "${RED}[AI-Archive] $*${NC}" >&2; }

# Configuration
CFG_DIR="$HOME/.config/opencode"
AGENT_CFG_DIR="$CFG_DIR/agent"
API_BASE_URL="${AI_ARCHIVE_API_URL:-https://ai-archive.io}"

# Get API key from environment or config file
get_api_key() {
  # First check environment
  if [ -n "${MCP_API_KEY:-}" ]; then
    echo "$MCP_API_KEY"
    return 0
  fi
  
  # Try to extract from opencode config
  if [ -f "$CFG_DIR/opencode.json" ] && command -v jq &> /dev/null; then
    key=$(jq -r '.mcp."ai-archive-mcp".environment.MCP_API_KEY // empty' "$CFG_DIR/opencode.json" 2>/dev/null)
    if [ -n "$key" ]; then
      echo "$key"
      return 0
    fi
  fi
  
  # Fallback to grep if jq not available
  if [ -f "$CFG_DIR/opencode.json" ]; then
    key=$(grep -oP '"MCP_API_KEY"\s*:\s*"\K[^"]+' "$CFG_DIR/opencode.json" 2>/dev/null || echo "")
    if [ -n "$key" ]; then
      echo "$key"
      return 0
    fi
  fi
  
  return 1
}

# Sync agents from API
sync_agents() {
  local api_key="$1"
  
  mkdir -p "$AGENT_CFG_DIR"
  
  # Fetch agent bundle from API
  local response
  response=$(curl -fsSL \
    --connect-timeout 5 \
    --max-time 10 \
    -H "x-api-key: $api_key" \
    -H "Content-Type: application/json" \
    "${API_BASE_URL}/api/v1/agents/bundle" 2>/dev/null) || {
    return 1
  }
  
  # Check if response indicates success
  if ! echo "$response" | grep -q '"success":\s*true'; then
    return 1
  fi
  
  # Parse and save each agent's markdown file
  if command -v jq &> /dev/null; then
    local agent_count
    agent_count=$(echo "$response" | jq -r '.data.agents | length' 2>/dev/null || echo "0")
    
    if [ "$agent_count" -eq 0 ]; then
      warn "No agents returned from API"
      return 0
    fi
    
    # Clear existing agent files before writing new ones
    rm -f "$AGENT_CFG_DIR"/*.md 2>/dev/null || true
    
    local synced=0
    for i in $(seq 0 $((agent_count - 1))); do
      local filename markdown
      filename=$(echo "$response" | jq -r ".data.agents[$i].filename" 2>/dev/null)
      markdown=$(echo "$response" | jq -r ".data.agents[$i].markdown" 2>/dev/null)
      
      if [ -n "$filename" ] && [ -n "$markdown" ] && [ "$filename" != "null" ] && [ "$markdown" != "null" ]; then
        echo "$markdown" > "$AGENT_CFG_DIR/$filename"
        ((synced++))
      fi
    done
    
    info "Synced $synced agent(s) to $AGENT_CFG_DIR"
    return 0
  else
    warn "jq not installed - cannot parse agent bundle"
    return 1
  fi
}

# Main
main() {
  local api_key
  api_key=$(get_api_key) || {
    warn "No API key configured - using existing agents"
    exit 0
  }
  
  if [ -z "$api_key" ]; then
    warn "No API key configured - using existing agents"
    exit 0
  fi
  
  sync_agents "$api_key" || {
    warn "Agent sync failed (network error?) - using existing agents"
    exit 0
  }
}

main "$@"
