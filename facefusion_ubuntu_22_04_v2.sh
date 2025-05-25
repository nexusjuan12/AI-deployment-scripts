#!/bin/bash

# FaceFusion Installation Script for Ubuntu 22.04 with CUDA 12.4
# This script must be run from where you want FaceFusion cloned

# Store the current working directory
INSTALL_DIR=$(pwd)
echo "Installation will be in: $INSTALL_DIR"

# Update system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required system packages
echo "Installing required system packages..."
sudo apt install -y git curl ffmpeg build-essential

# Check if conda is already installed
if ! command -v conda &> /dev/null; then
    echo "Conda not found. Installing Miniconda..."
    # Download and install Miniconda to a temporary location
    cd /tmp
    curl -LO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda3
    
    # Initialize conda for this shell session
    source $HOME/miniconda3/etc/profile.d/conda.sh
    conda init --all
    
    # Return to install directory
    cd "$INSTALL_DIR"
else
    echo "Conda is already installed"
    # Make sure conda is available in the current shell
    source $HOME/miniconda3/etc/profile.d/conda.sh
fi

# Install CUDA 12.4 if not already installed
echo "Checking CUDA installation..."
if ! command -v nvcc &> /dev/null; then
    echo "CUDA not found. Installing CUDA 12.4..."
    # Save current directory
    CURRENT_DIR=$(pwd)
    cd /tmp
    
    # Add NVIDIA CUDA repository
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
    sudo dpkg -i cuda-keyring_1.1-1_all.deb
    sudo apt update
    
    # Install CUDA 12.4
    sudo apt install -y cuda-toolkit-12-4
    
    # Add CUDA to PATH for next sessions
    echo 'export PATH=/usr/local/cuda-12.4/bin:$PATH' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.4/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
    
    # Add CUDA to PATH for current session
    export PATH=/usr/local/cuda-12.4/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/cuda-12.4/lib64:$LD_LIBRARY_PATH
    
    # Return to install directory
    cd "$CURRENT_DIR"
else
    echo "CUDA is already installed"
    nvcc --version
fi

# Create FaceFusion conda environment
echo "Creating FaceFusion conda environment..."
conda create --name facefusion python=3.12 -y

# Activate the environment
echo "Activating FaceFusion environment..."
conda activate facefusion

# Verify activation worked
echo "Active environment: $CONDA_DEFAULT_ENV"
echo "Python location: $(which python)"

# Install CUDA runtime and cuDNN in conda environment
echo "Installing CUDA runtime and cuDNN in conda environment..."
conda install -c conda-forge cuda-runtime=12.4 cudnn=9.3.0 -y

# Install TensorRT
echo "Installing TensorRT..."
pip install tensorrt==10.6.0 --extra-index-url https://pypi.nvidia.com

# Make sure we're in the installation directory
echo "Changing to installation directory: $INSTALL_DIR"
cd "$INSTALL_DIR"

# Clone FaceFusion repository
echo "Cloning FaceFusion repository to: $INSTALL_DIR/facefusion"
git clone https://github.com/nexusjuan12/facefusion-unlock
cd facefusion

# List files to confirm clone worked
echo "Files in facefusion directory:"
ls -la

# Install FaceFusion with CUDA support
echo "Installing FaceFusion with CUDA support..."
python install.py --onnxruntime cuda

# Verify installation
echo "Verifying FaceFusion installation..."
python -c "import onnxruntime as ort; print('CUDA devices available:', ort.get_available_providers())"

# Final check
echo "Installation complete!"
echo "FaceFusion has been cloned to: $INSTALL_DIR/facefusion"
echo ""
echo "To use FaceFusion in the future:"
echo "1. Source the conda environment:"
echo "   source \$HOME/miniconda3/etc/profile.d/conda.sh"
echo "2. Activate the environment:"
echo "   conda activate facefusion"
echo "3. Navigate to the directory:"
echo "   cd $INSTALL_DIR/facefusion"
echo "4. Run FaceFusion:"
echo "   python facefusion.py run"
echo ""
echo "You can now check if the directory exists with: ls -la