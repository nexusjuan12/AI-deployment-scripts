#!/bin/bash
# Download models from Hugging Face
sudo apt-get update
sudo apt-get install git-lfs

# Verify installation
git lfs install
huggingface-cli download KwaiVGI/LivePortrait --local-dir pretrained_weights --exclude "*.git*" "README.md" "docs"

# Move to the pretrained_weights directory
cd pretrained_weights

# Download JoyVASA repository
git lfs install
git clone https://huggingface.co/jdh-algo/JoyVASA

# Download Chinese Hubert base model
git lfs install
git clone https://huggingface.co/TencentGameMate/chinese-hubert-base

# Download wav2vec2 model
git lfs install
git clone https://huggingface.co/facebook/wav2vec2-base-960h
