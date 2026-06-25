#!/usr/bin/env bash
# switch-to-fork.sh — Point a standard hermes install at the botsquad fork
# (with Vertex AI Claude support cherry-picked onto main).
#
# Usage:
#   1. Install hermes normally:
#      curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
#   2. Run this script:
#      bash <(curl -sL https://raw.githubusercontent.com/devguyio-bot-squad/hermes-agent/vertex-claude/switch-to-fork.sh)
#
# What it does:
#   - Repoints origin to devguyio-bot-squad/hermes-agent
#   - Saves upstream as a remote named "upstream"
#   - Checks out the vertex-claude branch
#   - Reinstalls into the existing venv
#
# Safe to re-run — idempotent.

set -euo pipefail

FORK_REPO="https://github.com/devguyio-bot-squad/hermes-agent.git"
UPSTREAM_REPO="https://github.com/NousResearch/hermes-agent.git"
BRANCH="vertex-claude"

# Locate the install dir
if [ -n "${HERMES_INSTALL_DIR:-}" ]; then
    INSTALL_DIR="$HERMES_INSTALL_DIR"
elif [ -d "${HERMES_HOME:-$HOME/.hermes}/hermes-agent/.git" ]; then
    INSTALL_DIR="${HERMES_HOME:-$HOME/.hermes}/hermes-agent"
elif [ -d "/usr/local/lib/hermes-agent/.git" ]; then
    INSTALL_DIR="/usr/local/lib/hermes-agent"
else
    echo "Error: Could not find hermes-agent install directory."
    echo "Set HERMES_INSTALL_DIR or install hermes first."
    exit 1
fi

echo "Found hermes at: $INSTALL_DIR"
cd "$INSTALL_DIR"

# Save upstream if not already saved
if ! git remote get-url upstream &>/dev/null; then
    current_origin=$(git remote get-url origin 2>/dev/null || true)
    if [ -n "$current_origin" ]; then
        echo "Saving current origin as 'upstream'..."
        git remote add upstream "$current_origin"
    fi
fi

# Repoint origin to fork
echo "Setting origin to $FORK_REPO..."
git remote set-url origin "$FORK_REPO"

# Fetch and checkout
echo "Fetching $BRANCH..."
git fetch origin "$BRANCH"
git checkout "$BRANCH"

# Reinstall into existing venv
if [ -d "$INSTALL_DIR/venv" ]; then
    echo "Reinstalling into existing venv..."
    "$INSTALL_DIR/venv/bin/pip" install -e "." --quiet 2>/dev/null \
        || "$INSTALL_DIR/venv/bin/uv" pip install -e "." --quiet 2>/dev/null
    # Inject anthropic[vertex] for Claude on Vertex
    "$INSTALL_DIR/venv/bin/pip" install "anthropic[vertex]" --quiet 2>/dev/null \
        || "$INSTALL_DIR/venv/bin/uv" pip install "anthropic[vertex]" --quiet 2>/dev/null
fi

echo ""
echo "Done. hermes is now tracking devguyio-bot-squad/hermes-agent@$BRANCH"
echo ""
echo "Remotes:"
git remote -v | grep -E "^(origin|upstream)" | head -4
echo ""
echo "To pull future updates:  git -C $INSTALL_DIR pull origin $BRANCH"
echo "To sync from upstream:   git -C $INSTALL_DIR fetch upstream main"
