#!/bin/bash
# Deploy and run eBPF scripts on remote server

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
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 [OPTIONS] <script_path>"
    echo ""
    echo "Options:"
    echo "  -h, --host HOST      Remote host (default: \$REMOTE_HOST or your-server.com)"
    echo "  -u, --user USER      Remote user (default: \$REMOTE_USER or ubuntu)"
    echo "  -p, --path PATH      Remote path (default: \$REMOTE_PATH or /home/USER/ebpf-dev)"
    echo "  -r, --run           Run the script after deployment"
    echo "  -w, --watch         Watch for local changes and auto-deploy"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 chapter2/hello-buffer.py"
    echo "  $0 -r chapter2/hello-buffer.py"
    echo "  $0 -h myserver.com -u root chapter2/hello-buffer.py"
}

# Parse command line arguments
RUN_AFTER_DEPLOY=false
WATCH_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--host)
            REMOTE_HOST="$2"
            shift 2
            ;;
        -u|--user)
            REMOTE_USER="$2"
            shift 2
            ;;
        -p|--path)
            REMOTE_PATH="$2"
            shift 2
            ;;
        -r|--run)
            RUN_AFTER_DEPLOY=true
            shift
            ;;
        -w|--watch)
            WATCH_MODE=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        -*)
            echo "Unknown option $1"
            usage
            exit 1
            ;;
        *)
            SCRIPT_PATH="$1"
            shift
            ;;
    esac
done

if [ -z "$SCRIPT_PATH" ]; then
    echo -e "${RED}Error: Script path is required${NC}"
    usage
    exit 1
fi

if [ ! -f "$LOCAL_PROJECT_ROOT/$SCRIPT_PATH" ]; then
    echo -e "${RED}Error: Script not found: $LOCAL_PROJECT_ROOT/$SCRIPT_PATH${NC}"
    exit 1
fi

deploy_script() {
    echo -e "${YELLOW}Deploying $SCRIPT_PATH to $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH${NC}"
    
    # Create remote directory
    ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_PATH"
    
    # Copy the script
    scp "$LOCAL_PROJECT_ROOT/$SCRIPT_PATH" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/"
    
    # Make it executable
    SCRIPT_NAME=$(basename "$SCRIPT_PATH")
    ssh "$REMOTE_USER@$REMOTE_HOST" "chmod +x $REMOTE_PATH/$SCRIPT_NAME"
    
    echo -e "${GREEN}Deployment complete!${NC}"
}

run_script() {
    SCRIPT_NAME=$(basename "$SCRIPT_PATH")
    echo -e "${YELLOW}Running $SCRIPT_NAME on remote server...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    
    ssh -t "$REMOTE_USER@$REMOTE_HOST" "cd $REMOTE_PATH && sudo python3 $SCRIPT_NAME"
}

# Deploy the script
deploy_script

# Run if requested
if [ "$RUN_AFTER_DEPLOY" = true ]; then
    run_script
fi

# Watch mode (requires fswatch on macOS)
if [ "$WATCH_MODE" = true ]; then
    if ! command -v fswatch &> /dev/null; then
        echo -e "${YELLOW}Installing fswatch for file watching...${NC}"
        brew install fswatch
    fi
    
    echo -e "${GREEN}Watching for changes in $SCRIPT_PATH...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop watching${NC}"
    
    fswatch -o "$LOCAL_PROJECT_ROOT/$SCRIPT_PATH" | while read f; do
        echo -e "${YELLOW}File changed, redeploying...${NC}"
        deploy_script
        if [ "$RUN_AFTER_DEPLOY" = true ]; then
            echo -e "${YELLOW}Restarting script...${NC}"
            run_script &
        fi
    done
fi