#!/bin/bash

# Exit on error
set -e

echo "Starting Wan2GP installation setup..."

# Base system setup
sudo apt update && sudo apt install -y \
    build-essential \
    cmake \
    ninja-build \
    libx11-dev \
    libxrandr-dev \
    libxinerama-dev \
    libxcursor-dev \
    libxi-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    freeglut3-dev \
    mesa-common-dev \
    python3.10 \
    python3-pip \
    python3-venv \
    python3-distutils \
    git \
    git-lfs \
    python3-dev \
    g++ \
    ffmpeg \
    curl \
    wget \
    ninja-build

# Detect OS
OS="$(uname -s)"
IS_WINDOWS=false
if [[ "$OS" == *"NT"* ]] || [[ "$OS" == *"MINGW"* ]] || [[ "$OS" == *"MSYS"* ]]; then
    IS_WINDOWS=true
    echo "Windows OS detected"
else
    echo "Linux OS detected"
fi

# Install CUDA 12.4 on Linux
if [ "$IS_WINDOWS" = false ]; then
    echo "Installing CUDA 12.4..."
    wget https://developer.download.nvidia.com/compute/cuda/12.4.0/local_installers/cuda_12.4.0_550.54.14_linux.run
    sudo sh cuda_12.4.0_550.54.14_linux.run --toolkit --silent
    rm cuda_12.4.0_550.54.14_linux.run

    # Install cuDNN for CUDA 12.4
    echo "Installing cuDNN..."
    wget https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-x86_64/cudnn-linux-x86_64-8.9.7.29_cuda12-archive.tar.xz
    tar -xvf cudnn-linux-x86_64-8.9.7.29_cuda12-archive.tar.xz
    sudo cp -P cudnn-linux-x86_64-8.9.7.29_cuda12-archive/lib/* /usr/local/cuda-12.4/lib64/
    sudo cp cudnn-linux-x86_64-8.9.7.29_cuda12-archive/include/* /usr/local/cuda-12.4/include/
    sudo ldconfig
    rm -rf cudnn-linux-x86_64-8.9.7.29_cuda12-archive*

    # Add CUDA to PATH
    if ! grep -q "export PATH=/usr/local/cuda-12.4/bin:\$PATH" ~/.bashrc; then
        echo 'export PATH=/usr/local/cuda-12.4/bin:$PATH' >> ~/.bashrc
    fi
    if ! grep -q "export LD_LIBRARY_PATH=/usr/local/cuda-12.4/lib64:\$LD_LIBRARY_PATH" ~/.bashrc; then
        echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.4/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
    fi
    export PATH=/usr/local/cuda-12.4/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/cuda-12.4/lib64:$LD_LIBRARY_PATH
fi

# Check for existing conda installation and use it if available
if [ -d "$HOME/miniconda3" ]; then
    echo "Using existing Miniconda installation..."
else
    # Install Miniconda (non-interactive)
    echo "Installing Miniconda..."
    if [ "$IS_WINDOWS" = true ]; then
        curl -LO https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe
        start /wait "" Miniconda3-latest-Windows-x86_64.exe /InstallationType=JustMe /RegisterPython=0 /S /D=%UserProfile%\miniconda3
        rm Miniconda3-latest-Windows-x86_64.exe
    else
        curl -LO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
        bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda3
        rm Miniconda3-latest-Linux-x86_64.sh
    fi
fi

# Update conda
echo "Updating conda..."
$HOME/miniconda3/bin/conda update -n base -c defaults conda -y

# Ensure conda initialization
echo "Initializing conda..."
$HOME/miniconda3/bin/conda init bash
source ~/.bashrc || echo "Please run 'source ~/.bashrc' manually if needed"

# Handle the conda environment
if conda env list | grep -q "wan2gp"; then
    echo "Using existing wan2gp environment..."
    $HOME/miniconda3/bin/conda activate wan2gp || source $HOME/miniconda3/bin/activate wan2gp || echo "Using environment activation from shell"
else
    # Create and activate conda environment with Python 3.10.9
    echo "Creating conda environment..."
    $HOME/miniconda3/bin/conda create --name wan2gp python=3.10.9 -y
    $HOME/miniconda3/bin/conda activate wan2gp || source $HOME/miniconda3/bin/activate wan2gp || echo "Please run 'conda activate wan2gp' manually after script completion"
fi

# Setup git-lfs
git lfs install

# Handle Wan2GP directory
if [ -d "Wan2GP" ]; then
    echo "Wan2GP directory already exists. Updating..."
    cd Wan2GP
    git pull
else
    # Clone Wan2GP
    echo "Cloning Wan2GP..."
    git clone https://github.com/deepbeepmeep/Wan2GP.git
    cd Wan2GP
fi

# Install PyTorch 2.6.0 with CUDA 12.4 support
echo "Installing PyTorch 2.6.0..."
pip install torch==2.6.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/test/cu124
pip install xformers==0.0.29.post2
# Install requirements
echo "Installing Python requirements..."
pip install -r requirements.txt

# Install Sage Attention
echo "Installing Sage Attention 1.0.6..."
if [ "$IS_WINDOWS" = true ]; then
    # Windows installation
    echo "Installing Triton for Windows..."
    pip install triton-windows
    pip install sageattention==1.0.6
else
    # Linux installation
    echo "Installing Sage Attention for Linux..."
    pip install sageattention==1.0.6
fi

# Install Sage 2 Attention
echo "Installing Sage 2 Attention..."
if [ "$IS_WINDOWS" = true ]; then
    # Windows installation
    echo "Installing Triton for Windows (if not already installed)..."
    pip install triton-windows
    pip install https://github.com/woct0rdho/SageAttention/releases/download/v2.1.1-windows/sageattention-2.1.1+cu126torch2.6.0-cp310-cp310-win_amd64.whl
else
    # Linux installation - compile from source
    echo "Compiling Sage 2 Attention from source..."
    if [ -d "SageAttention" ]; then
        echo "SageAttention directory already exists. Updating..."
        cd SageAttention
        git pull
        pip install -e .
        cd ..
    else
        echo "Cloning SageAttention..."
        git clone https://github.com/thu-ml/SageAttention
        cd SageAttention
        pip install -e .
        cd ..
    fi
fi

# Install Flash Attention
echo "Installing Flash Attention..."
# Attempt to install flash-attn (note: may fail on Windows)
pip install flash-attn==2.7.2.post1 || echo "Flash Attention installation failed. This is normal on Windows as it requires manual compilation."

# Set CUDA environment variables if on Linux
if [ "$IS_WINDOWS" = false ]; then
    export CUDA_HOME=/usr/local/cuda-12.4
    export PATH=$CUDA_HOME/bin:$PATH
    export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
    
    # Add to bashrc if not already there
    if ! grep -q "export CUDA_HOME=/usr/local/cuda-12.4" ~/.bashrc; then
        echo 'export CUDA_HOME=/usr/local/cuda-12.4' >> ~/.bashrc
    fi
fi

echo "Setup complete! You can now activate the environment with:"
echo "source ~/.bashrc"
echo "conda activate wan2gp"
echo "cd Wan2GP"

# Print success message with additional information
echo ""
echo "Installation Summary:"
echo "---------------------"
echo "Python: 3.10.9"
echo "PyTorch: 2.6.0"
echo "CUDA: 12.4"
echo "Sage Attention: Installed"
echo "Flash Attention: Attempted installation"
echo ""
echo "Note: You can enable Sage Attention for 30% faster performance with a small quality cost."
echo "If Triton is installed correctly, you can turn on PyTorch Compilation for an additional 20% speed boost."
