
#!/bin/bash

# Create the directory structure if it doesn't exist
#https://huggingface.co/Kijai/WanVideo_comfy/tree/main
mkdir -p models/text_encoders
mkdir -p models/vae
mkdir -p models/diffusion_models

# Download text encoders
cd models/text_encoders
echo "Downloading text encoders..."
wget https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors
#wget https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors
cd ../..

# Download VAE
cd models/vae
echo "Downloading VAE model..."
#wget https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors
#wget https://huggingface.co/Kijai/WanVideo_comfy/blob/main/Wan2_1_VAE_fp32.safetensors
#wget https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_fp32.safetensors
wget https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors

cd ../..

# Download diffusion models
cd models/diffusion_models
echo "Downloading diffusion models..."
# Uncomment the line below if you want this model as well
#wget https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_t2v_14B_fp8_scaled.safetensors
#wget https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_SkyreelsA2_fp8_e4m3fn.safetensors
wget https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1-T2V-14B_fp8_e5m2.safetensors
#wget https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1-I2V-14B-720P_fp8_e5m2.safetensors
#wget https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1-I2V-14B-480P_fp8_e5m2.safetensors
#wget https://huggingface.co/calcuis/wan-gguf/resolve/main/wan2.1-i2v-14b-480p-q6_k.gguf
cd ../..
cd ../..

cd models/clip_vision
#wget https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/open-clip-xlm-roberta-large-vit-huge-14_visual_fp16.safetensors
wget https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/open-clip-xlm-roberta-large-vit-huge-14_visual_fp32.safetensors
wget https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors
cd ../..

echo "Download complete. Models saved in the models directory."
