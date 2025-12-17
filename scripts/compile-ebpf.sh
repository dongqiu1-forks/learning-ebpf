#!/bin/bash
# Compile eBPF C programs on remote server

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
    echo "Usage: $0 [OPTIONS] <file.bpf.c>"
    echo ""
    echo "Options:"
    echo "  -h, --host HOST      Remote host (default: \$REMOTE_HOST or your-server.com)"
    echo "  -u, --user USER      Remote user (default: \$REMOTE_USER or ubuntu)"
    echo "  -p, --path PATH      Remote path (default: \$REMOTE_PATH)"
    echo "  -o, --output NAME    Output filename (default: same as input with .o extension)"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 chapter3/hello.bpf.c"
    echo "  $0 -o my-program.bpf.o chapter3/hello.bpf.c"
    echo "  $0 hello.bpf.c  # If run from chapter directory"
}

# Parse command line arguments
OUTPUT_FILE=""

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
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
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
            BPF_FILE="$1"
            shift
            ;;
    esac
done

if [ -z "$BPF_FILE" ]; then
    echo -e "${RED}Error: eBPF C file is required${NC}"
    usage
    exit 1
fi

# Handle relative and absolute paths
if [ -f "$BPF_FILE" ]; then
    # File exists as given (absolute or relative to current dir)
    FULL_BPF_PATH="$(realpath "$BPF_FILE")"
elif [ -f "$LOCAL_PROJECT_ROOT/$BPF_FILE" ]; then
    # File exists relative to project root
    FULL_BPF_PATH="$(realpath "$LOCAL_PROJECT_ROOT/$BPF_FILE")"
else
    echo -e "${RED}Error: eBPF file not found: $BPF_FILE${NC}"
    exit 1
fi

# Extract file info
BPF_FILENAME="$(basename "$FULL_BPF_PATH")"
BPF_DIR="$(dirname "$FULL_BPF_PATH")"
BPF_BASENAME="${BPF_FILENAME%.bpf.c}"

# Determine output filename
if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="${BPF_BASENAME}.bpf.o"
fi

echo "Input file: $FULL_BPF_PATH"
echo "Output file: $OUTPUT_FILE"

deploy_and_compile() {
    echo -e "${YELLOW}Deploying $BPF_FILENAME to $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH${NC}"
    
    # Create remote directory
    ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_PATH"
    
    # Copy the eBPF source file
    scp "$FULL_BPF_PATH" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/"
    
    echo -e "${GREEN}Deployment complete!${NC}"
    
    # Compile on remote server
    echo -e "${YELLOW}Compiling $BPF_FILENAME on remote server...${NC}"
    echo -e "${YELLOW}Command: clang -target bpf -I/usr/include/\$(uname -m)-linux-gnu -g -O2 -c $BPF_FILENAME -o $OUTPUT_FILE${NC}"
    
    ssh -t "$REMOTE_USER@$REMOTE_HOST" "cd $REMOTE_PATH && clang -target bpf -I/usr/include/\$(uname -m)-linux-gnu -g -O2 -c $BPF_FILENAME -o $OUTPUT_FILE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Compilation successful! Output: $OUTPUT_FILE${NC}"
        echo -e "${YELLOW}Files on remote server:${NC}"
        ssh "$REMOTE_USER@$REMOTE_HOST" "cd $REMOTE_PATH && ls -la *.bpf.*"
    else
        echo -e "${RED}Compilation failed!${NC}"
        exit 1
    fi
}

# Deploy and compile
deploy_and_compile