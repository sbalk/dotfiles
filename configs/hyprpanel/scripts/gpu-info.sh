#!/usr/bin/env bash
# ~/.config/hyprpanel/scripts/gpu-info.sh

gpu_info=$(nvidia-smi --query-gpu=gpu_name,temperature.gpu,memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits)
gpu_name=$(echo "$gpu_info" | cut -d ',' -f 1 | xargs)
gpu_temp=$(echo "$gpu_info" | cut -d ',' -f 2 | xargs)
gpu_mem_used=$(echo "$gpu_info" | cut -d ',' -f 3 | xargs)
gpu_mem_total=$(echo "$gpu_info" | cut -d ',' -f 4 | xargs)
gpu_usage=$(echo "$gpu_info" | cut -d ',' -f 5 | xargs)

# Calculate memory percentage
gpu_mem_percentage=$(awk "BEGIN {printf \"%.0f\", ($gpu_mem_used / $gpu_mem_total) * 100}")

# Output JSON for HyprPanel
cat << EOF
{
    "percentage": $gpu_usage,
    "usage": $gpu_usage,
    "mem_used": $gpu_mem_used,
    "mem_total": $gpu_mem_total,
    "mem_percentage": $gpu_mem_percentage,
    "temperature": $gpu_temp,
    "name": "$gpu_name"
}
EOF