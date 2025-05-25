#!/bin/bash

# FramePack Installation Script for Ubuntu 22.04 - Modified to allow root
# This script will install Miniconda, create a conda environment, and set up FramePack

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Ubuntu
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" != "ubuntu" ]; then
        print_warning "This script is designed for Ubuntu. Your system is $ID."
        read -p "Do you want to continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# Note if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. This is not typically recommended, but allowed in this modified script."
fi

# Step 1: Install system dependencies
print_status "Installing system dependencies..."
apt update
apt install -y wget git curl libgl1-mesa-glx libglib2.0-0

# Step 2: Check for existing Miniconda installation
if [ "$EUID" -eq 0 ]; then
    CONDA_PREFIX="/root/miniconda3"
    BASHRC_FILE="/root/.bashrc"
else
    CONDA_PREFIX="$HOME/miniconda3"
    BASHRC_FILE="$HOME/.bashrc"
fi

# Check if conda command exists or if miniconda directory exists
if command -v conda &> /dev/null || [ -d "$CONDA_PREFIX" ]; then
    print_status "Miniconda installation found at $CONDA_PREFIX"
    if [ -d "$CONDA_PREFIX" ] && ! command -v conda &> /dev/null; then
        print_warning "Miniconda directory exists but conda command not found in PATH"
        print_status "Attempting to fix PATH..."
        export PATH="$CONDA_PREFIX/bin:$PATH"
    fi
else
    print_status "Installing Miniconda..."
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
    bash miniconda.sh -b -p $CONDA_PREFIX
    rm miniconda.sh
fi

# Add conda to PATH for current session
export PATH="$CONDA_PREFIX/bin:$PATH"

# Initialize conda for the shell
eval "$($CONDA_PREFIX/bin/conda shell.bash hook)"

# Add conda initialization to .bashrc if not already present
if ! grep -q "conda initialize" $BASHRC_FILE; then
    echo "# >>> conda initialize >>>" >> $BASHRC_FILE
    echo "# !! Contents within this block are managed by 'conda init' !!" >> $BASHRC_FILE
    echo "__conda_setup=\"\$('$CONDA_PREFIX/bin/conda' 'shell.bash' 'hook' 2> /dev/null)\"" >> $BASHRC_FILE
    echo "if [ \$? -eq 0 ]; then" >> $BASHRC_FILE
    echo "    eval \"\$__conda_setup\"" >> $BASHRC_FILE
    echo "else" >> $BASHRC_FILE
    echo "    if [ -f \"$CONDA_PREFIX/etc/profile.d/conda.sh\" ]; then" >> $BASHRC_FILE
    echo "        . \"$CONDA_PREFIX/etc/profile.d/conda.sh\"" >> $BASHRC_FILE
    echo "    else" >> $BASHRC_FILE
    echo "        export PATH=\"$CONDA_PREFIX/bin:\$PATH\"" >> $BASHRC_FILE
    echo "    fi" >> $BASHRC_FILE
    echo "fi" >> $BASHRC_FILE
    echo "unset __conda_setup" >> $BASHRC_FILE
    echo "# <<< conda initialize <<<" >> $BASHRC_FILE
fi

# Step 3: Create conda environment
print_status "Creating conda environment 'framepack' with Python 3.10..."
conda create -n framepack python=3.10 -y

# Step 4: Activate the environment
print_status "Activating conda environment..."
conda activate framepack

# Step 5: Install PyTorch with CUDA 12.6
print_status "Installing PyTorch with CUDA 12.6..."
# Using pip method as it's more reliable for specific CUDA versions
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126

# Step 6: Clone FramePack repository
print_status "Cloning FramePack repository..."
if [ "$EUID" -eq 0 ]; then
    INSTALL_DIR="/root/FramePack"
else
    INSTALL_DIR="$HOME/FramePack"
fi

if [ -d "$INSTALL_DIR" ]; then
    print_warning "Directory $INSTALL_DIR already exists."
    read -p "Do you want to remove it and clone fresh? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
        git clone https://github.com/lllyasviel/FramePack.git "$INSTALL_DIR"
    else
        print_status "Using existing directory."
    fi
else
    git clone https://github.com/lllyasviel/FramePack.git "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# Step 7: Install requirements
if [ -f "requirements.txt" ]; then
    print_status "Installing Python dependencies..."
    pip install -r requirements.txt
    
    # Handle OpenCV headless installation for server environments
    print_status "Ensuring OpenCV is properly installed for headless environment..."
    pip uninstall -y opencv-python &>/dev/null || true
    pip install opencv-python-headless
else
    print_error "requirements.txt not found in the repository!"
    exit 1
fi

# Step 8: Create run script
print_status "Creating run script..."
cat > run_framepack.sh << EOL
#!/bin/bash
# FramePack run script

# Activate conda environment
eval "\$(conda shell.bash hook)"
conda activate framepack

# Navigate to FramePack directory
cd "$INSTALL_DIR"

# Run the demo
python demo_gradio.py "\$@"
EOL

chmod +x run_framepack.sh

# Step 9: Installation complete
print_status "Installation completed successfully!"
echo
echo -e "${GREEN}FramePack has been installed!${NC}"
echo
echo -e "${YELLOW}IMPORTANT: You need to reload your shell to use conda!${NC}"
echo "Run: source $BASHRC_FILE"
echo
echo "To run FramePack:"
echo "1. Source your bashrc: source $BASHRC_FILE"
echo "2. Navigate to the installation directory: cd $INSTALL_DIR"
echo "3. Run the application: ./run_framepack.sh"
echo
echo "Optional arguments:"
echo "  --share    : Create a public shareable link"
echo "  --port     : Specify port number"
echo "  --server   : Specify server address (e.g., --server 0.0.0.0)"
echo
echo "The first run will automatically download the required models (30GB+)."
echo
echo "For optimal performance, you may want to install additional packages:"
echo "  - For sage-attention: pip install sageattention==1.0.6"
echo "  - For xformers: pip install xformers"
echo "  - For flash-attention: pip install flash-attn"
echo
echo "Note: The software has been tested on NVIDIA RTX 30XX/40XX/50XX series GPUs."
echo "WARNING: Running as root may cause permission issues with created files."
