export PYTORCH_CUDA_ALLOC_CONF=cudaMallocAsync
export CUDA_MODULE_LOADING=LAZY  # optional, can improve Triton perf
python main.py --listen 0.0.0.0 --port 8081