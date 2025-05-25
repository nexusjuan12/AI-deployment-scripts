#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Function for steps that can fail without stopping the script
try_step() {
    set +e  # Temporarily disable exit on error
    "$@"
    local status=$?
    set -e  # Re-enable exit on error
    return $status
}

print_step() {
    echo "======================================================================"
    echo "  $1"
    echo "======================================================================"
}

print_step "UniAnimate-DiT Installation Script for Ubuntu 22.04 with CUDA 12.1"
echo "This script will:"
echo "  1. Check for and install the CUDA toolkit dependencies if needed"
echo "  2. Check for and install Miniconda if needed"
echo "  3. Create a conda environment with Python 3.9 for UniAnimate-DiT"
echo "  4. Install PyTorch and other dependencies"
echo "  5. Attempt to install optimized attention mechanisms (will continue if failed)"
echo "  6. Clone and install UniAnimate-DiT"
echo "  7. Download required pre-trained models"
echo ""
echo "Press Enter to continue or Ctrl+C to abort..."
read

# Check and install CUDA development tools if needed
print_step "Checking CUDA toolkit and build dependencies..."
if ! command -v nvcc &> /dev/null; then
    echo "NVCC (CUDA compiler) not found. Installing CUDA development packages..."
    try_step apt-get update
    try_step apt-get install -y build-essential
    try_step apt-get install -y cuda-toolkit-12-1
    
    # Set up CUDA environment variables
    echo 'export PATH=/usr/local/cuda-12.1/bin:$PATH' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.1/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
    
    # Apply changes for current session
    export PATH=/usr/local/cuda-12.1/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/cuda-12.1/lib64:$LD_LIBRARY_PATH
else
    echo "CUDA toolkit with NVCC found at: $(which nvcc)"
    echo "CUDA version: $(nvcc --version | grep release | awk '{print $6}' | cut -c2-)"
fi

# Check if conda is installed, if not install Miniconda
if ! command -v conda &> /dev/null; then
    print_step "Installing Miniconda..."
    
    # Download Miniconda installer
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
    
    # Install Miniconda
    bash miniconda.sh -b -p $HOME/miniconda
    
    # Add conda to path
    eval "$($HOME/miniconda/bin/conda shell.bash hook)"
    
    # Initialize conda for bash
    conda init bash
    
    echo "Conda has been installed. Please run 'source ~/.bashrc' after this script completes."
else
    print_step "Conda is already installed."
fi

# Make sure conda command is available in this script
source $HOME/.bashrc 2>/dev/null || true
export PATH="$HOME/miniconda/bin:$PATH"

# Create conda environment for UniAnimate-DiT
print_step "Creating conda environment 'UniAnimate-DiT' with Python 3.9..."

# Check if environment already exists
if conda info --envs | grep -q UniAnimate-DiT; then
    echo "Environment 'UniAnimate-DiT' already exists. Removing and recreating..."
    conda remove --name UniAnimate-DiT --all -y
fi

# Create fresh environment
conda create -n UniAnimate-DiT python=3.9 -y
conda activate UniAnimate-DiT

# Install PyTorch with CUDA 12.1
print_step "Installing PyTorch with CUDA 12.1 support..."
pip install torch==2.5.0 torchvision==0.20.0 torchaudio==2.5.0 --index-url https://download.pytorch.org/whl/cu121

# Install required utilities
print_step "Installing basic utilities..."
conda install -y git wget

# Install C++ build tools for compiling extensions
print_step "Installing C++ build tools for extension compilation..."
try_step apt-get install -y g++ gcc cmake
conda install -y -c conda-forge ninja

# Install optimized attention mechanisms (allowing failure)
print_step "Attempting to install optimized attention implementations..."
echo "This step may fail but the script will continue..."

# Try to install Flash Attention 2
echo "Attempting to install Flash Attention 2..."
try_step pip install -v flash-attn
if [ $? -eq 0 ]; then
    echo "Flash Attention installed successfully!"
else
    echo "Flash Attention installation failed. Continuing with PyTorch's built-in attention."
fi

# Try to install Sage Attention (fallback option)
echo "Attempting to install Sage Attention..."
try_step pip install -v sage-attention
if [ $? -eq 0 ]; then
    echo "Sage Attention installed successfully!"
else
    echo "Sage Attention installation failed. Continuing with PyTorch's built-in attention."
fi

# Clone UniAnimate-DiT repository
print_step "Cloning and installing UniAnimate-DiT from GitHub..."
git clone https://github.com/ali-vilab/UniAnimate-DiT.git
cd UniAnimate-DiT
pip install -e .

# Install dependencies for pose alignment
print_step "Installing dependencies for pose alignment..."
pip install onnxruntime-gpu==1.18.1

# Create directories for models and data
print_step "Creating directories for models and data..."
mkdir -p checkpoints
mkdir -p Wan2.1-I2V-14B-720P
mkdir -p data/saved_pose
mkdir -p data/images
mkdir -p data/videos

# Install Hugging Face and ModelScope CLI tools for model downloads
print_step "Installing model download utilities..."
pip install "huggingface_hub[cli]" modelscope

# Download Wan2.1-14B-I2V-720P models using ModelScope
print_step "Downloading Wan2.1-14B-I2V-720P models (this may take a while)..."
modelscope download Wan-AI/Wan2.1-I2V-14B-720P --local_dir ./Wan2.1-I2V-14B-720P

# Download UniAnimate-DiT models using ModelScope
print_step "Downloading UniAnimate-DiT checkpoint models..."
modelscope download xiaolaowx/UniAnimate-DiT --local_dir ./checkpoints

# Download a sample video for testing
print_step "Downloading a sample video for testing..."
wget -O data/videos/source_video.mp4 https://github.com/ali-vilab/UniAnimate/raw/main/assets/source_video.mp4

# Install additional dependencies for training (optional)
print_step "Installing additional packages for training..."
pip install peft lightning pandas -U
try_step pip install -U deepspeed

# Print success message and next steps
print_step "Installation Completed Successfully!"
echo ""
echo "Attention Implementations Available:"
if pip list | grep -q flash-attn; then
    echo "✓ Flash Attention (installed)"
else
    echo "✗ Flash Attention (not installed, using PyTorch's built-in attention)"
fi
if pip list | grep -q sage-attention; then
    echo "✓ Sage Attention (installed)"
else
    echo "✗ Sage Attention (not installed)"
fi
echo "✓ PyTorch SDPA (built-in to PyTorch 2.5.0)"
echo ""
echo "To use UniAnimate-DiT:"
echo "1. Run 'source ~/.bashrc' to update your shell environment"
echo "2. Activate the conda environment with: conda activate UniAnimate-DiT"
echo "3. Follow the README instructions to align poses and generate videos"
echo ""
echo "Example commands:"
echo "  # For pose alignment (first download a reference image to data/images/):"
echo "  python run_align_pose.py --ref_name data/images/your_image.jpg --source_video_paths data/videos/source_video.mp4 --saved_pose_dir data/saved_pose/your_image"
echo ""
echo "  # For 480p video generation:"
echo "  python examples/unianimate_wan/inference_unianimate_wan_480p.py"
echo ""
echo "  # For 720p video generation:"
echo "  python examples/unianimate_wan/inference_unianimate_wan_720p.py"
echo ""
echo "NOTE: You'll need approximately 23GB GPU memory for 480p and 36GB for 720p videos."
echo "      You can reduce memory usage by setting num_persistent_param_in_dit=0 in the inference scripts."
