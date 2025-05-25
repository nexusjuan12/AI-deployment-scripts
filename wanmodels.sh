#!/bin/bash
set -e

# Create directories
mkdir -p models/vae
mkdir -p models/diffusion_models
mkdir -p models/text_encoders
mkdir -p models/clip_vision
mkdir -p models/upscale_models

# Download models
echo "Downloading VAE model..."
wget -O models/vae/Wan2_1_VAE_fp32.safetensors https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_fp32.safetensors

echo "Downloading diffusion model..."
wget -O models/diffusion_models/Wan2_1-I2V-14B-720P_fp8_e4m3fn.safetensors https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1-I2V-14B-720P_fp8_e4m3fn.safetensors

echo "Downloading text encoder..."
wget -O models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors

echo "Downloading CLIP vision model..."
wget -O models/clip_vision/clip_vision_h.safetensors https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors

echo "Downloading upscale models..."
wget -O models/upscale_models/4x-ClearRealityV1.pth https://openmodeldb.info/api/v1/models/4x-ClearRealityV1/download
wget -O models/upscale_models/1x-SkinContrast-High-SuperUltraCompact.pth https://openmodeldb.info/api/v1/models/1x-SkinContrast-High-SuperUltraCompact/download

echo "Model downloads complete!"