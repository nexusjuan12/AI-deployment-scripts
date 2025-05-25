#!/bin/bash

echo "🚀 Setting up Video Background Removal Tool..."

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

# Create conda environment
echo "🔧 Creating conda environment 'vbr' with Python 3.11..."
conda create -y -n vbr python=3.11

# Clone repository
echo "📥 Cloning the VideoBackgroundRemoval repository..."
git clone https://github.com/killian31/VideoBackgroundRemoval.git
cd VideoBackgroundRemoval

# Install requirements (using conda run to ensure it works in the script)
echo "📦 Installing requirements..."
conda run -n vbr pip install -r requirements.txt

# Install cloudflared
echo "📦 Installing cloudflared for public sharing..."
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
else
    echo "⚠️ Unsupported architecture: $ARCH"
    echo "Please install cloudflared manually from: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/local/"
    CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
fi

# Create a bin directory in the project for cloudflared
mkdir -p bin
wget -O bin/cloudflared $CLOUDFLARED_URL
chmod +x bin/cloudflared

# Add a launch script for easy startup with cloudflared
cat > launch_vbr.sh << 'EOF'
#!/bin/bash

# Activate conda environment
eval "$(conda shell.bash hook)"
conda activate vbr

# Start Streamlit on port 7860 in background
echo "Starting Streamlit app on port 7860..."
streamlit run app.py --server.port=7860 --server.headless=true &
STREAMLIT_PID=$!

# Wait a bit for Streamlit to start
sleep 5

# Start cloudflared tunnel
echo "Creating public cloudflared link..."
./bin/cloudflared tunnel --url http://localhost:7860 &
CLOUDFLARED_PID=$!

# Keep script running
echo "Server is running. Press Ctrl+C to stop."
trap "kill $STREAMLIT_PID; kill $CLOUDFLARED_PID; echo 'Server stopped.'" EXIT
wait
EOF

chmod +x launch_vbr.sh

echo "
✨ Setup completed! ✨

To run the Video Background Removal tool with a public link:

1. Run 'source ~/.bashrc' to refresh your environment variables
2. Launch the app with: './launch_vbr.sh'

The launch script will:
- Start Streamlit on port 7860
- Create a public cloudflared link that you can share with anyone
- Show you the public URL in the terminal

Enjoy removing video backgrounds! 🎬
"