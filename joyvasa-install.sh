#!/bin/bash
set -e

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== JoyVASA Installer for Ubuntu 22.04 ===${NC}"
echo -e "${BLUE}This script will install all required dependencies and set up JoyVASA.${NC}"
echo ""

# Install system dependencies 
echo -e "${BLUE}Installing system dependencies...${NC}"
sudo apt update
sudo apt install -y build-essential gcc g++ make cmake python3 python3-pip python3-venv ffmpeg \
                   libsndfile1 portaudio19-dev python3-dev unrar p7zip-full libgl1-mesa-glx \
                   libasound2-dev git

# Install ninja
sudo apt install -y ninja-build

# Install git-lfs
echo -e "${BLUE}Installing git-lfs...${NC}"
sudo apt install -y git-lfs
git lfs install

# Define installation directories
INSTALL_DIR="$HOME/joyvasa_install"
CONDA_DIR="$HOME/miniconda3"
REPO_DIR="$INSTALL_DIR/JoyVASA"

# Create installation directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Check if Miniconda is installed
if [ ! -d "$CONDA_DIR" ]; then
    echo -e "${BLUE}Miniconda not found. Installing...${NC}"
    # Download Miniconda installer
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
    
    # Install Miniconda silently
    bash miniconda.sh -b -p "$CONDA_DIR"
    
    # Initialize conda for bash
    "$CONDA_DIR/bin/conda" init bash
    
    echo -e "${GREEN}Miniconda installed successfully!${NC}"
else
    echo -e "${GREEN}Miniconda already installed at $CONDA_DIR${NC}"
fi

# Source conda
source "$CONDA_DIR/etc/profile.d/conda.sh"

# Create and activate joyvasa environment
echo -e "${BLUE}Creating conda environment 'joyvasa'...${NC}"
conda create -n joyvasa python=3.10 -y
conda activate joyvasa

# Clone JoyVASA repository if it doesn't exist
if [ ! -d "$REPO_DIR" ]; then
    echo -e "${BLUE}Cloning JoyVASA repository...${NC}"
    git clone https://github.com/nexusjuan12/JoyVASA.git "$REPO_DIR"
    echo -e "${GREEN}Repository cloned successfully!${NC}"
else
    echo -e "${GREEN}JoyVASA repository already exists at $REPO_DIR${NC}"
    # Pull latest changes
    cd "$REPO_DIR"
    git pull
fi

cd "$REPO_DIR"

# Install Python requirements
echo -e "${BLUE}Installing Python requirements...${NC}"
pip install -r requirements.txt

# Build XPose dependencies
echo -e "${BLUE}Building XPose dependencies...${NC}"
cd src/utils/dependencies/XPose/models/UniPose/ops
python setup.py build install
cd - # Return to JoyVASA directory

# Install huggingface_hub
echo -e "${BLUE}Installing Hugging Face Hub...${NC}"
pip install -U "huggingface_hub[cli]"

# Download model weights
echo -e "${BLUE}Downloading model weights from Hugging Face...${NC}"
huggingface-cli download KwaiVGI/LivePortrait --local-dir pretrained_weights --exclude "*.git*" "README.md" "docs"

cd pretrained_weights

# Clone JoyVASA weights
echo -e "${BLUE}Downloading JoyVASA weights...${NC}"
git lfs install
git clone https://huggingface.co/jdh-algo/JoyVASA

# Clone Chinese HuBERT model
echo -e "${BLUE}Downloading Chinese HuBERT model...${NC}"
git lfs install
git clone https://huggingface.co/TencentGameMate/chinese-hubert-base

# Return to JoyVASA directory
cd "$REPO_DIR"

# Create an activation script
cat > "$INSTALL_DIR/activate_joyvasa.sh" << 'EOF'
#!/bin/bash
# Source conda
source "$HOME/miniconda3/etc/profile.d/conda.sh"

# Activate joyvasa environment
conda activate joyvasa

# Change to JoyVASA directory
cd "$HOME/joyvasa_install/JoyVASA"

echo -e "\033[0;32mJoyVASA environment activated!\033[0m"
echo -e "\033[0;34mYou can now run JoyVASA scripts.\033[0m"
EOF

chmod +x "$INSTALL_DIR/activate_joyvasa.sh"

echo -e "${GREEN}Installation completed successfully!${NC}"
echo -e "${GREEN}To activate the JoyVASA environment, run:${NC}"
echo -e "${BLUE}source $INSTALL_DIR/activate_joyvasa.sh${NC}"
