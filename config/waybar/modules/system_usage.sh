#!/bin/bash

# Function to get CPU usage as a percentage
get_cpu_usage() {
  # Use /proc/stat to calculate CPU usage
  prev_idle=$(awk '/^cpu / {print $5}' /proc/stat)
  prev_total=$(awk '/^cpu / {sum = 0; for (i=2; i<=NF; i++) sum += $i; print sum}' /proc/stat)
  sleep 1
  idle=$(awk '/^cpu / {print $5}' /proc/stat)
  total=$(awk '/^cpu / {sum = 0; for (i=2; i<=NF; i++) sum += $i; print sum}' /proc/stat)

  diff_idle=$((idle - prev_idle))
  diff_total=$((total - prev_total))
  diff_usage=$((100 * (diff_total - diff_idle) / diff_total))

  echo "$diff_usage"
}

# Function to get RAM usage as a percentage
get_ram_usage() {
  # Use free to get total and used memory
  total=$(free | awk '/^Mem:/ {print $2}')
  used=$(free | awk '/^Mem:/ {print $3}')
  ram=$((used * 100 / total))
  echo "$ram"
}

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

# Get the CPU, RAM, and GPU usage
cpu=$(get_cpu_usage)
ram=$(get_ram_usage)
gpu=$(get_gpu_usage)

# Output the results in formatted text
echo " ${cpu}%  ${ram}%  ${gpu}%"
