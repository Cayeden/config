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

# hwmon numbers change between boots. Match CPU drivers and sensor labels.
# CPU_HWMON_ROOT allows checking discovery against a fixture directory.
tctl= tccd1=
for sensor in "${CPU_HWMON_ROOT:-/sys/class/hwmon}"/hwmon*; do
  [[ -r "$sensor/name" ]] || continue
  read -r driver < "$sensor/name"
  case "$driver" in k10temp|zenpower|coretemp) ;; *) continue ;; esac
  fallback= package= die= control= chiplet=
  for input in "$sensor"/temp*_input; do
    [[ -r "$input" ]] || continue
    read -r value < "$input" || continue
    [[ "$value" =~ ^[0-9]+$ ]] || continue
    value=$((10#$value / 1000))
    label=
    [[ ! -r "${input%_input}_label" ]] || read -r label < "${input%_input}_label"
    case "$label" in
      Tctl) control=$value ;;
      Tdie) die=$value ;;
      'Package id 0') package=$value ;;
      Tccd1) chiplet=$value ;;
    esac
    [[ "$input" != "$sensor/temp1_input" ]] || fallback=$value
  done
  tctl=${control:-${die:-${package:-$fallback}}}
  tccd1=$chiplet
  [[ -z "$tctl" ]] || break
done

class="normal"
[[ -z "$tctl" ]] || { (( tctl < 85 )) || class="critical"; }

if [[ -n "$tctl" ]]; then
  text="CPU ${usage}% ${tctl}°C"
  tooltip="${usage}% total  |  CPU ${tctl}°C"
  [[ -z "$tccd1" ]] || tooltip+="  Tccd1 ${tccd1}°C"
else
  text="CPU ${usage}%"
  tooltip="${usage}% total  |  CPU temperature unavailable"
fi
for ((i = 0; i < ${#percore[@]}; i += 4)); do
  line=""
  for ((j = i; j < i + 4 && j < ${#percore[@]}; j++)); do
    line+="C${j}:${percore[$j]}% "
  done
  tooltip+="\n${line% }"
done

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"
