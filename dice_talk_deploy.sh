#!/bin/bash

# DICE-Talk Deployment Script for Ubuntu 22.04 with NVIDIA CUDA 12.1
# This script automates the complete setup of DICE-Talk emotional talking portrait system

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DICE_TALK_DIR="$HOME/DICE-Talk"
CONDA_ENV_NAME="dice-talk"
PYTHON_VERSION="3.10"
MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
PYTORCH_VERSION="2.2.2"
TORCHVISION_VERSION="0.17.2"
TORCHAUDIO_VERSION="2.2.2"

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
        print_error "nvcc not found. Please install CUDA first."
        exit 1
    fi
    
    # Check CUDA version
    CUDA_VERSION=$(nvcc --version | grep "release" | sed 's/.*release \([0-9]\+\.[0-9]\+\).*/\1/')
    print_status "Detected CUDA version: $CUDA_VERSION"
    
    # Check GPU memory
    GPU_MEMORY=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n1)
    if [[ $GPU_MEMORY -lt 20000 ]]; then
        print_warning "GPU has ${GPU_MEMORY}MB memory. DICE-Talk recommends at least 20GB for optimal performance."
        print_warning "You may experience out-of-memory errors with complex inputs."
    else
        print_success "GPU has sufficient memory: ${GPU_MEMORY}MB"
    fi
    
    print_success "NVIDIA GPU and CUDA check completed"
}

# Function to check and install ffmpeg
check_install_ffmpeg() {
    print_status "Checking ffmpeg installation..."
    
    if command_exists ffmpeg; then
        print_success "ffmpeg is already installed"
        ffmpeg -version | head -n1
    else
        print_status "Installing ffmpeg..."
        sudo apt update
        sudo apt install -y ffmpeg
        print_success "ffmpeg installed successfully"
    fi
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

# Function to clone DICE-Talk repository
clone_repository() {
    print_status "Cloning DICE-Talk repository..."
    
    if [[ -d "$DICE_TALK_DIR" ]]; then
        print_warning "DICE-Talk directory already exists. Removing it..."
        rm -rf "$DICE_TALK_DIR"
    fi
    
    git clone https://github.com/toto222/DICE-Talk.git "$DICE_TALK_DIR"
    cd "$DICE_TALK_DIR"
    
    print_success "DICE-Talk repository cloned to $DICE_TALK_DIR"
}

# Function to determine CUDA version for PyTorch
get_pytorch_cuda_index() {
    local cuda_version=$1
    case $cuda_version in
        "11.8") echo "cu118" ;;
        "12.1") echo "cu121" ;;
        "12.2") echo "cu121" ;;  # Use cu121 for 12.2
        "12.3") echo "cu121" ;;  # Use cu121 for 12.3
        "12.4") echo "cu121" ;;  # Use cu121 for 12.4
        *) echo "cu118" ;;       # Default fallback
    esac
}

# Function to install Python requirements
install_requirements() {
    print_status "Installing Python requirements..."
    
    conda activate "$CONDA_ENV_NAME"
    
    # Detect CUDA version for PyTorch installation
    CUDA_VERSION=$(nvcc --version | grep "release" | sed 's/.*release \([0-9]\+\.[0-9]\+\).*/\1/')
    CUDA_INDEX=$(get_pytorch_cuda_index "$CUDA_VERSION")
    
    # Install PyTorch with appropriate CUDA support
    print_status "Installing PyTorch $PYTORCH_VERSION with CUDA support ($CUDA_INDEX)..."
    pip install torch==$PYTORCH_VERSION torchvision==$TORCHVISION_VERSION torchaudio==$TORCHAUDIO_VERSION --index-url https://download.pytorch.org/whl/$CUDA_INDEX
    
    # Install other requirements
    if [[ -f "requirements.txt" ]]; then
        pip install -r requirements.txt
    else
        print_error "requirements.txt not found in the repository"
        exit 1
    fi
    
    # Install huggingface-cli for model downloads
    pip install "huggingface_hub[cli]"
    
    print_success "Python requirements installed"
}

# Function to create checkpoints directory structure
setup_checkpoints() {
    print_status "Setting up checkpoints directory structure..."
    
    mkdir -p checkpoints/DICE-Talk
    mkdir -p checkpoints/stable-video-diffusion-img2vid-xt
    mkdir -p checkpoints/whisper-tiny
    mkdir -p checkpoints/RIFE
    
    print_success "Checkpoints directory structure created"
}

# Function to download models
download_models() {
    print_status "Downloading required models (this may take a while)..."
    
    conda activate "$CONDA_ENV_NAME"
    
    # Download DICE-Talk models
    print_status "Downloading DICE-Talk models..."
    huggingface-cli download EEEELY/DICE-Talk --local-dir checkpoints/
    
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
    python -c "import torch; print(f'CUDA device count: {torch.cuda.device_count()}')" 2>/dev/null || true
    
    # Check if model files exist
    REQUIRED_FILES=(
        "checkpoints/DICE-Talk/audio_linear.pth"
        "checkpoints/DICE-Talk/emo_model.pth"
        "checkpoints/DICE-Talk/pose_guider.pth"
        "checkpoints/DICE-Talk/unet.pth"
        "checkpoints/yoloface_v5m.pt"
        "checkpoints/RIFE/flownet.pkl"
    )
    
    print_status "Checking required model files..."
    for file in "${REQUIRED_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            print_success "✓ $file"
        else
            print_warning "✗ $file (may be downloaded as part of model package)"
        fi
    done
    
    # Test basic imports
    print_status "Testing Python imports..."
    python -c "
import torch
import torchvision
import gradio as gr
print('✓ All basic imports successful')
" 2>/dev/null && print_success "Python imports test passed" || print_warning "Some imports may have issues"
    
    print_success "Installation verification completed"
}

# Function to create activation script
create_activation_script() {
    print_status "Creating activation script..."
    
    cat > activate_dice_talk.sh << EOF
#!/bin/bash
# DICE-Talk Activation Script
echo "Activating DICE-Talk environment..."
eval "\$(conda shell.bash hook)"
conda activate $CONDA_ENV_NAME
cd $DICE_TALK_DIR
echo "DICE-Talk environment activated. Current directory: \$(pwd)"
echo ""
echo "Available commands:"
echo "1. Command line demo:"
echo "   python3 demo.py --image_path '/path/to/input_image' --audio_path '/path/to/input_audio' --emotion_path '/path/to/input_emotion' --output_path '/path/to/output_video'"
echo ""
echo "2. Web GUI (recommended):"
echo "   python3 gradio_app.py"
echo ""
echo "Supported emotions: neutral, happy, angry, surprised"
EOF
    
    chmod +x activate_dice_talk.sh
    
    print_success "Activation script created: $PWD/activate_dice_talk.sh"
}

# Function to create example usage script
create_example_script() {
    print_status "Creating example usage script..."
    
    cat > run_example.sh << EOF
#!/bin/bash
# DICE-Talk Example Script
source activate_dice_talk.sh

echo "Running DICE-Talk example..."
echo "Make sure you have placed your test image and audio files in the examples/ directory"

# Example command (modify paths as needed)
# python3 demo.py \\
#   --image_path 'examples/img/female.png' \\
#   --audio_path 'examples/audio/sample.wav' \\
#   --emotion_path 'happy' \\
#   --output_path 'output_example.mp4'

echo "To run the web interface:"
echo "python3 gradio_app.py"
EOF
    
    chmod +x run_example.sh
    
    print_success "Example script created: $PWD/run_example.sh"
}

# Function to display usage instructions
show_usage() {
    print_success "DICE-Talk deployment completed successfully!"
    echo
    echo -e "${BLUE}🎭 DICE-Talk Features:${NC}"
    echo "  • Emotional talking portrait generation"
    echo "  • Identity preservation with emotion control"
    echo "  • Support for: neutral, happy, angry, surprised emotions"
    echo "  • Web-based GUI interface"
    echo
    echo -e "${BLUE}📋 To use DICE-Talk:${NC}"
    echo "1. Activate the environment:"
    echo "   source $DICE_TALK_DIR/activate_dice_talk.sh"
    echo
    echo "2a. Run Web GUI (Recommended):"
    echo "    python3 gradio_app.py"
    echo "    Then open the URL shown in your browser"
    echo
    echo "2b. Run Command Line:"
    echo "    python3 demo.py \\"
    echo "      --image_path '/path/to/input_image' \\"
    echo "      --audio_path '/path/to/input_audio' \\"
    echo "      --emotion_path 'happy' \\"
    echo "      --output_path '/path/to/output_video'"
    echo
    echo -e "${BLUE}📝 Example:${NC}"
    echo "   python3 demo.py \\"
    echo "     --image_path 'examples/img/female.png' \\"
    echo "     --audio_path 'examples/audio/sample.wav' \\"
    echo "     --emotion_path 'surprised' \\"
    echo "     --output_path 'my_output.mp4'"
    echo
    echo -e "${BLUE}🌐 Project Resources:${NC}"
    echo "  • Project Page: https://toto222.github.io/DICE-Talk/"
    echo "  • Paper: https://arxiv.org/abs/2504.18087"
    echo
    echo -e "${YELLOW}⚠️  System Requirements:${NC}"
    echo "  • GPU: 20GB+ VRAM recommended"
    echo "  • OS: Linux (tested)"
    echo "  • License: CC BY-NC-SA-4.0 (Non-commercial)"
    echo
    echo -e "${GREEN}🚀 Ready to generate emotional talking portraits!${NC}"
}

# Main deployment function
main() {
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}  DICE-Talk Deployment Script${NC}"
    echo -e "${GREEN}  Ubuntu 22.04 + NVIDIA CUDA${NC}"
    echo -e "${GREEN}================================${NC}"
    echo
    
    # Check system requirements
    check_nvidia_cuda
    
    # Check and install ffmpeg
    check_install_ffmpeg
    
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
    
    # Create example script
    create_example_script
    
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

print_success "DICE-Talk is ready to generate emotional talking portraits! 🎭✨"