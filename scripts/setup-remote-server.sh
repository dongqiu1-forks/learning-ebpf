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
        echo "Installing BCC and eBPF development tools on Ubuntu/Debian..."
        sudo apt-get update
        sudo apt-get install -y bpfcc-tools python3-bpfcc python3-pip
        sudo apt-get install -y linux-tools-common linux-tools-generic linux-tools-$(uname -r) linux-headers-$(uname -r)
        sudo apt-get install -y clang llvm git build-essential
        sudo apt-get install -y libbpfcc-dev libbpf-dev libpcap-dev libbfd-dev
        ;;
    centos|rhel|fedora)
        echo "Installing BCC and eBPF development tools on CentOS/RHEL/Fedora..."
        if command -v dnf &> /dev/null; then
            sudo dnf install -y bcc-tools python3-bcc libbcc libbcc-devel kernel-devel
            sudo dnf install -y python3-pip git gcc gcc-c++ make
            # Install clang and eBPF development tools
            sudo dnf install -y clang llvm libbpf-devel
            # Install bpftool
            sudo dnf install -y bpftool
        else
            sudo yum install -y bcc-tools python3-bcc libbcc libbcc-devel kernel-devel
            sudo yum install -y python3-pip git gcc gcc-c++ make
            # Install clang and eBPF development tools
            sudo yum install -y clang llvm libbpf-devel
            # Install bpftool
            sudo yum install -y bpftool
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

echo "Verifying clang installation..."
clang --version || {
    echo "Clang installation failed!"
    exit 1
}

echo "Verifying bpftool installation..."
bpftool version || {
    echo "bpftool installation failed!"
    exit 1
}

echo "eBPF development environment setup complete!"
echo "Kernel version: $(uname -r)"
echo "Clang version: $(clang --version | head -n1)"
echo "BCC version: $(python3 -c 'import bcc; print(bcc.__version__)' 2>/dev/null || echo 'Version not available')"
echo "bpftool version: $(bpftool version | head -n1)"
echo ""
echo "Note: Run './scripts/sync-libbpf.sh' from your local machine to copy the libbpf directory."