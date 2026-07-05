#!/usr/bin/env bash
# ponytail: /proc/stat diffed over a short sleep instead of adding an mpstat dependency

mapfile -t before < <(grep '^cpu' /proc/stat)
sleep 0.3
mapfile -t after < <(grep '^cpu' /proc/stat)

calc_usage() {
  read -r _ u1 n1 s1 i1 w1 x1 y1 _ <<< "$1"
  read -r _ u2 n2 s2 i2 w2 x2 y2 _ <<< "$2"
  local idle1=$((i1 + w1)) idle2=$((i2 + w2))
  local total1=$((u1 + n1 + s1 + i1 + w1 + x1 + y1))
  local total2=$((u2 + n2 + s2 + i2 + w2 + x2 + y2))
  local totald=$((total2 - total1)) idled=$((idle2 - idle1))
  (( totald == 0 )) && { echo 0; return; }
  echo $(( (100 * (totald - idled)) / totald ))
}

usage=$(calc_usage "${before[0]}" "${after[0]}")

percore=()
for ((i = 1; i < ${#before[@]}; i++)); do
  percore+=("$(calc_usage "${before[$i]}" "${after[$i]}")")
done

# ponytail: hwmon numbering can shift after kernel/driver updates,
# re-check `sensors` for k10temp's hwmon path if this goes blank.
# AMD's k10temp only exposes Tctl (overall) and Tccd1 (chiplet) here,
# not true per-core temps -- that granularity isn't available on this CPU.
tctl=$(( $(cat /sys/class/hwmon/hwmon3/temp1_input) / 1000 ))
tccd1=$(( $(cat /sys/class/hwmon/hwmon3/temp3_input 2>/dev/null || echo 0) / 1000 ))

class="normal"
(( tctl >= 85 )) && class="critical"

tooltip="${usage}% total  |  Tctl ${tctl}°C  Tccd1 ${tccd1}°C"
for ((i = 0; i < ${#percore[@]}; i += 4)); do
  line=""
  for ((j = i; j < i + 4 && j < ${#percore[@]}; j++)); do
    line+="C${j}:${percore[$j]}% "
  done
  tooltip+="\n${line% }"
done

printf '{"text":"CPU %s%% %s°C","tooltip":"%s","class":"%s"}\n' "$usage" "$tctl" "$tooltip" "$class"
