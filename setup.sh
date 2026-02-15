#!/usr/bin/env bash
# Setup script for building PyTorch from source on an EC2 instance (CPU-only).
# Usage: ./setup.sh && python test/dynamo/test_misc.py -k test_boolarg
set -euo pipefail

echo "=== PyTorch source build setup ==="

# System packages
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    git \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    libopenblas-dev \
    libomp-dev \
    protobuf-compiler \
    libprotobuf-dev

# Swap (safety net for linking phase — the linker can spike to 15-20GB)
if [ "$(swapon --show --noheadings | wc -l)" -eq 0 ]; then
    sudo fallocate -l 4G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo "Swap enabled: 4G"
fi

# Use a virtualenv to avoid PEP 668 "externally managed environment" errors
python3 -m venv /tmp/venv
source /tmp/venv/bin/activate

pip install --upgrade pip setuptools wheel

# Install build and dev requirements
pip install -r requirements.txt

# Init submodules
git submodule sync
git submodule update --init --recursive

# Build and install in develop mode (CPU-only, minimal)
MAX_JOBS=$(nproc) \
USE_CUDA=0 \
USE_CUDNN=0 \
USE_ROCM=0 \
USE_XPU=0 \
USE_DISTRIBUTED=0 \
BUILD_TEST=0 \
pip install -e . -v --no-build-isolation

# Make the venv's python available as `python` system-wide so that
# test commands run after setup.sh (in a separate shell) can find it.
ln -sf /tmp/venv/bin/python3 /usr/local/bin/python

echo ""
echo "=== Done ==="
