#!/usr/bin/env bash
read -r util temp used total <<< "$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits | tr -d ',')"

class="normal"
[ "$temp" -ge 80 ] && class="critical"

printf '{"text":"GPU %s%% %s°C","tooltip":"VRAM: %s / %s MiB","class":"%s"}\n' "$util" "$temp" "$used" "$total" "$class"
