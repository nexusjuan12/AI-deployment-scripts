#!/bin/bash

echo "🚀 Setting up LatentSync..."

# Check if system dependencies are installed (mainly for OpenCV)
if command -v apt-get &> /dev/null; then
    echo "📦 Installing system dependencies..."
    apt-get update
    apt-get install -y libgl1-mesa-glx libglib2.0-0 libsm6 libxrender1 libxext6
elif command -v yum &> /dev/null; then
    echo "📦 Installing system dependencies..."
    yum install -y mesa-libGL libXext libSM libXrender
elif command -v pacman &> /dev/null; then
    echo "📦 Installing system dependencies..."
    pacman -S --noconfirm mesa libxext libsm libxrender
else
    echo "⚠️ Unable to automatically install system dependencies."
    echo "Please install the equivalent of libgl1-mesa-glx manually if you encounter OpenCV errors."
fi

# Check if conda is installed
if ! command -v conda &> /dev/null; then
    echo "🔍 Conda not found. Installing Miniconda..."
    
    # Download Miniconda installer
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
    
    # Install Miniconda
    bash miniconda.sh -b -p $HOME/miniconda
    
    # Add conda to path for current session
    export PATH="$HOME/miniconda/bin:$PATH"
    
    # Add conda to path permanently
    echo 'export PATH="$HOME/miniconda/bin:$PATH"' >> ~/.bashrc
    
    # Initialize conda
    $HOME/miniconda/bin/conda init bash
    
    echo "✅ Conda installed successfully!"
else
    echo "✅ Conda is already installed."
fi

# Source bashrc to ensure conda commands work
source ~/.bashrc

# Clone your fork of the repository
echo "📥 Cloning LatentSync repository from your fork..."
git clone https://github.com/nexusjuan12/LatentSync.git
cd LatentSync

# Run the setup script
echo "🔧 Running setup script..."
bash setup_env.sh

echo "
✨ LatentSync setup completed! ✨

To run the Gradio app, use:
python gradio_app.py

Enjoy using LatentSync! 🎬
"
