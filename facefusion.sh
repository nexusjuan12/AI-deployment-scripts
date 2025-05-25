apt install git-all
apt install curl
curl -LO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
apt install ffmpeg
source /root/.bashrc


conda init --all
source /root/.bashrc
conda create --name facefusion python=3.12
clsofonda activate facefusion
conda install -c conda-forge cuda-runtime=12.1 cudnn=9.3.0
pip install tensorrt==10.6.0 --extra-index-url https://pypi.nvidia.com

git clone https://github.com/facefusion/facefusion
cd facefusion
python install.py --onnxruntime cuda
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt update
sudo apt install -y cuda-toolkit-12-1


conda deactivate
conda activate facefusion
python facefusion.py run 

MediaCreationTool.exe /Eula Accept /Retail /MediaArch x64 /MediaLangCode en-US /MediaEdition Enterprise