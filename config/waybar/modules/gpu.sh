# Function to get GPU usage as a percentage
get_gpu_usage() {
  # Use nvidia-smi if NVIDIA GPU is present, fallback to 0 if unavailable
  if command -v nvidia-smi >/dev/null; then
    gpu=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{sum += $1} END {print sum}')
  else
    gpu=0 # Set to 0 if no GPU or unsupported GPU
  fi
  echo "$gpu"
}


gpu=$(get_gpu_usage)

echo "${gpu}%"
