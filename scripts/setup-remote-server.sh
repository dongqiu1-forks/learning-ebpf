#!/bin/bash
# Remote server setup script for eBPF development

set -e

echo "Setting up eBPF development environment..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release 
    OS=$ID
    VERSION=$VERSION_ID
else
    echo "Cannot detect OS. Please install BCC manually."
    exit 1
fi

# Install BCC based on OS
case $OS in
    ubuntu|debian)
        echo "Installing BCC on Ubuntu/Debian..."
        sudo apt-get update
        sudo apt-get install -y bpfcc-tools python3-bpfcc libbpfcc libbpfcc-dev linux-headers-$(uname -r)
        sudo apt-get install -y python3-pip git build-essential
        ;;
    centos|rhel|fedora)
        echo "Installing BCC on CentOS/RHEL/Fedora..."
        if command -v dnf &> /dev/null; then
            sudo dnf install -y bcc-tools python3-bcc libbcc libbcc-devel kernel-devel
            sudo dnf install -y python3-pip git gcc gcc-c++ make
        else
            sudo yum install -y bcc-tools python3-bcc libbcc libbcc-devel kernel-devel
            sudo yum install -y python3-pip git gcc gcc-c++ make
        fi
        ;;
    *)
        echo "Unsupported OS: $OS"
        echo "Please install BCC manually: https://github.com/iovisor/bcc/blob/master/INSTALL.md"
        exit 1
        ;;
esac

# Verify installation
echo "Verifying BCC installation..."
python3 -c "from bcc import BPF; print('BCC is working!')" || {
    echo "BCC installation failed!"
    exit 1
}

echo "eBPF development environment setup complete!"
echo "Kernel version: $(uname -r)"
echo "BCC version: $(python3 -c 'import bcc; print(bcc.__version__)' 2>/dev/null || echo 'Version not available')"