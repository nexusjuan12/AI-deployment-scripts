#!/bin/bash

# Sonic Deployment Script for Ubuntu 22.04 with NVIDIA CUDA 12.1
# This script automates the complete setup of Sonic portrait animation system

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SONIC_DIR="$HOME/Sonic"
CONDA_ENV_NAME="sonic"
PYTHON_VERSION="3.10"
MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check NVIDIA GPU and CUDA
check_nvidia_cuda() {
    print_status "Checking NVIDIA GPU and CUDA installation..."
    
    if ! command_exists nvidia-smi; then
        print_error "nvidia-smi not found. Please install NVIDIA drivers first."
        exit 1
    fi
    
    if ! command_exists nvcc; then
        print_error "nvcc not found. Please install CUDA 12.1 first."
        exit 1
    fi
    
    # Check CUDA version
    CUDA_VERSION=$(nvcc --version | grep "release" | sed 's/.*release \([0-9]\+\.[0-9]\+\).*/\1/')
    if [[ "$CUDA_VERSION" != "12.1" ]]; then
        print_warning "CUDA version is $CUDA_VERSION, expected 12.1. Proceeding anyway..."
    fi
    
    # Check GPU memory
    GPU_MEMORY=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n1)
    if [[ $GPU_MEMORY -lt 16000 ]]; then
        print_warning "GPU has ${GPU_MEMORY}MB memory. Sonic recommends at least 32GB for optimal performance."
    fi
    
    print_success "NVIDIA GPU and CUDA check completed"
}

# Function to install Miniconda
install_miniconda() {
    print_status "Installing Miniconda..."
    
    cd /tmp
    wget -q "$MINICONDA_URL" -O miniconda.sh
    bash miniconda.sh -b -p "$HOME/miniconda3"
    rm miniconda.sh
    
    # Initialize conda
    eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
    conda init bash
    
    print_success "Miniconda installed successfully"
}

# Function to check and setup Miniconda
setup_conda() {
    if command_exists conda; then
        print_success "Conda is already installed"
        eval "$(conda shell.bash hook)"
    else
        install_miniconda
        # Source bashrc to get conda in current session
        source ~/.bashrc 2>/dev/null || true
        eval "$($HOME/miniconda3/bin/conda shell.bash hook)" 2>/dev/null || true
    fi
}

# Function to create conda environment
create_conda_env() {
    print_status "Creating conda environment '$CONDA_ENV_NAME'..."
    
    # Remove existing environment if it exists
    if conda env list | grep -q "^$CONDA_ENV_NAME "; then
        print_warning "Environment '$CONDA_ENV_NAME' already exists. Removing it..."
        conda env remove -n "$CONDA_ENV_NAME" -y
    fi
    
    # Create new environment
    conda create -n "$CONDA_ENV_NAME" python="$PYTHON_VERSION" -y
    
    print_success "Conda environment '$CONDA_ENV_NAME' created"
}

# Function to clone Sonic repository
clone_repository() {
    print_status "Cloning Sonic repository..."
    
    if [[ -d "$SONIC_DIR" ]]; then
        print_warning "Sonic directory already exists. Removing it..."
        rm -rf "$SONIC_DIR"
    fi
    
    git clone https://github.com/jixiaozhong/Sonic.git "$SONIC_DIR"
    cd "$SONIC_DIR"
    
    print_success "Sonic repository cloned to $SONIC_DIR"
}

# Function to install Python requirements
install_requirements() {
    print_status "Installing Python requirements..."
    
    conda activate "$CONDA_ENV_NAME"
    
    # Install PyTorch with CUDA 12.1 support
    print_status "Installing PyTorch with CUDA 12.1 support..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
    
    # Install common missing dependencies first
    print_status "Installing common dependencies..."
    pip install opencv-python opencv-python-headless numpy pillow
    
    # Install other requirements
    if [[ -f "requirements.txt" ]]; then
        pip install -r requirements.txt
    else
        print_error "requirements.txt not found in the repository"
        exit 1
    fi
    
    # Install additional dependencies that might be missing
    print_status "Installing additional dependencies..."
    pip install gradio transformers accelerate diffusers
    
    # Install huggingface-cli for model downloads
    pip install "huggingface_hub[cli]"
    
    print_success "Python requirements installed"
}

# Function to create checkpoints directory structure
setup_checkpoints() {
    print_status "Setting up checkpoints directory structure..."
    
    mkdir -p checkpoints/Sonic
    mkdir -p checkpoints/stable-video-diffusion-img2vid-xt
    mkdir -p checkpoints/whisper-tiny
    mkdir -p checkpoints/RIFE
    
    print_success "Checkpoints directory structure created"
}

# Function to download models
download_models() {
    print_status "Downloading required models..."
    
    conda activate "$CONDA_ENV_NAME"
    
    # Download Sonic models
    print_status "Downloading Sonic models..."
    huggingface-cli download LeonJoe13/Sonic --local-dir checkpoints/
    
    # Download Stable Video Diffusion model
    print_status "Downloading Stable Video Diffusion model..."
    huggingface-cli download stabilityai/stable-video-diffusion-img2vid-xt --local-dir checkpoints/stable-video-diffusion-img2vid-xt
    
    # Download Whisper model
    print_status "Downloading Whisper model..."
    huggingface-cli download openai/whisper-tiny --local-dir checkpoints/whisper-tiny
    
    print_success "All models downloaded successfully"
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    conda activate "$CONDA_ENV_NAME"
    
    # Check if Python can import required packages
    python -c "import torch; print(f'PyTorch version: {torch.__version__}')"
    python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
    
    # Check if model files exist
    REQUIRED_FILES=(
        "checkpoints/Sonic/audio2bucket.pth"
        "checkpoints/Sonic/audio2token.pth"
        "checkpoints/Sonic/unet.pth"
        "checkpoints/yoloface_v5m.pt"
        "checkpoints/RIFE/flownet.pkl"
    )
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            print_success "✓ $file"
        else
            print_warning "✗ $file (may be downloaded as part of model package)"
        fi
    done
    
    print_success "Installation verification completed"
}

# Function to create activation script
create_activation_script() {
    print_status "Creating activation script..."
    
    cat > activate_sonic.sh << EOF
#!/bin/bash
# Sonic Activation Script
echo "Activating Sonic environment..."
eval "\$(conda shell.bash hook)"
conda activate $CONDA_ENV_NAME
cd $SONIC_DIR
echo "Sonic environment activated. Current directory: \$(pwd)"
echo "Usage: python3 demo.py '/path/to/input_image' '/path/to/input_audio' '/path/to/output_video'"
EOF
    
    chmod +x activate_sonic.sh
    
    print_success "Activation script created: $PWD/activate_sonic.sh"
}

# Function to display usage instructions
show_usage() {
    print_success "Sonic deployment completed successfully!"
    echo
    echo -e "${BLUE}To use Sonic:${NC}"
    echo "1. Activate the environment:"
    echo "   source $SONIC_DIR/activate_sonic.sh"
    echo
    echo "2. Run Sonic with your inputs:"
    echo "   python3 demo.py '/path/to/input_image' '/path/to/input_audio' '/path/to/output_video'"
    echo
    echo -e "${BLUE}Example:${NC}"
    echo "   python3 demo.py examples/image/anime1.png examples/audio/sample.wav output_video.mp4"
    echo
    echo -e "${BLUE}Online Demo:${NC} http://demo.sonic.jixiaozhong.online/"
    echo -e "${BLUE}HuggingFace Demo:${NC} https://huggingface.co/spaces/xiaozhongji/Sonic/"
    echo
    echo -e "${YELLOW}Note:${NC} This is a non-commercial license. For commercial use, check Tencent Cloud Video Creation Large Model."
}

# Main deployment function
main() {
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}  Sonic Deployment Script${NC}"
    echo -e "${GREEN}  Ubuntu 22.04 + CUDA 12.1${NC}"
    echo -e "${GREEN}================================${NC}"
    echo
    
    # Check system requirements
    check_nvidia_cuda
    
    # Setup conda
    setup_conda
    
    # Create conda environment
    create_conda_env
    
    # Clone repository
    clone_repository
    
    # Setup checkpoints directory
    setup_checkpoints
    
    # Install requirements
    install_requirements
    
    # Download models (this may take a while)
    download_models
    
    # Create activation script
    create_activation_script
    
    # Verify installation
    verify_installation
    
    # Show usage instructions
    show_usage
}

# Error handling
trap 'print_error "Deployment failed at line $LINENO. Check the error above."' ERR

# Check if running as root (not recommended)
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root is not recommended. Consider running as a regular user."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Run main deployment
main

print_success "Sonic is ready to use! 🎵🎭"