#!/bin/bash
# Quick script to just run an already deployed eBPF script

REMOTE_HOST="${REMOTE_HOST:-your-server.com}"
REMOTE_USER="${REMOTE_USER:-ubuntu}"
REMOTE_PATH="${REMOTE_PATH:-/home/$REMOTE_USER/ebpf-dev}"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <script_name>"
    echo "Example: $0 hello-buffer.py"
    exit 1
fi

SCRIPT_NAME="$1"

echo "Running $SCRIPT_NAME on $REMOTE_USER@$REMOTE_HOST..."
echo "Press Ctrl+C to stop"

ssh -t "$REMOTE_USER@$REMOTE_HOST" "cd $REMOTE_PATH && sudo python3 $SCRIPT_NAME"