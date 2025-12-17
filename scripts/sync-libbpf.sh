#!/bin/bash
# Sync libbpf directory to remote server

# Load environment variables from .env file if it exists
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "Loading configuration from .env file..."
    source "$SCRIPT_DIR/.env"
fi

# Configuration
REMOTE_HOST="${REMOTE_HOST:-your-server.com}"
REMOTE_USER="${REMOTE_USER:-ubuntu}"
REMOTE_PATH="${REMOTE_PATH:-/home/$REMOTE_USER/learning-ebpf}"
LOCAL_PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if libbpf directory exists locally
if [ ! -d "$LOCAL_PROJECT_ROOT/libbpf" ]; then
    echo -e "${RED}Error: libbpf directory not found at $LOCAL_PROJECT_ROOT/libbpf${NC}"
    exit 1
fi

echo "Syncing libbpf directory to remote server..."
echo "  Local:  $LOCAL_PROJECT_ROOT/libbpf/"
echo "  Remote: $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/libbpf/"
echo ""

# Sync libbpf directory using rsync
rsync -avz --progress \
    "$LOCAL_PROJECT_ROOT/libbpf/" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/libbpf/" || {
    echo -e "${RED}Error: Failed to sync libbpf directory${NC}"
    exit 1
}

echo ""
echo -e "${GREEN}Successfully synced libbpf directory to remote server!${NC}"
