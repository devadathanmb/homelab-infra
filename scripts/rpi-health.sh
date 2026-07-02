#!/usr/bin/env bash
# Print a compact Raspberry Pi health report without requiring root.

set -uo pipefail

if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
  bold=$(tput bold)
  dim=$(tput dim)
  red=$(tput setaf 1)
  green=$(tput setaf 2)
  yellow=$(tput setaf 3)
  blue=$(tput setaf 4)
  reset=$(tput sgr0)
else
  bold=""
  dim=""
  red=""
  green=""
  yellow=""
  blue=""
  reset=""
fi

section() {
  printf '\n%s%s== %s ==%s\n' "$bold" "$blue" "$1" "$reset"
}

ok() {
  printf '%sOK%s' "$green" "$reset"
}

warn() {
  printf '%sWARN%s' "$yellow" "$reset"
}

bad() {
  printf '%sBAD%s' "$red" "$reset"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

read_first() {
  local path=$1
  if [[ -r "$path" ]]; then
    cat "$path" 2>/dev/null
  else
    printf '?'
  fi
}

cpu_temp_c() {
  if command_exists vcgencmd; then
    vcgencmd measure_temp 2>/dev/null | sed -E "s/temp=([0-9.]+).*/\1/" && return
  fi

  if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
    awk '{printf "%.1f\n", $1 / 1000}' /sys/class/thermal/thermal_zone0/temp
    return
  fi

  printf '?\n'
}

find_hwmon_by_name() {
  local wanted=$1
  local hwmon name
  for hwmon in /sys/class/hwmon/hwmon*; do
    [[ -r "$hwmon/name" ]] || continue
    name=$(<"$hwmon/name")
    [[ "$name" == "$wanted" ]] && printf '%s\n' "$hwmon" && return 0
  done
  return 1
}

decode_throttle_flags() {
  local raw=${1#throttled=}
  local value labels=()

  [[ -n "$raw" ]] || return 0
  value=$((raw))

  ((value & (1 << 0))) && labels+=("under-voltage now")
  ((value & (1 << 1))) && labels+=("frequency capped now")
  ((value & (1 << 2))) && labels+=("throttled now")
  ((value & (1 << 3))) && labels+=("soft temperature limit now")
  ((value & (1 << 16))) && labels+=("under-voltage occurred")
  ((value & (1 << 17))) && labels+=("frequency cap occurred")
  ((value & (1 << 18))) && labels+=("throttling occurred")
  ((value & (1 << 19))) && labels+=("soft temperature limit occurred")

  if ((${#labels[@]} == 0)); then
    printf 'none'
  else
    local IFS=', '
    printf '%s' "${labels[*]}"
  fi
}

health_for_temp() {
  local temp=${1%.*}
  if [[ ! "$temp" =~ ^[0-9]+$ ]]; then
    warn
  elif ((temp >= 75)); then
    bad
  elif ((temp >= 65)); then
    warn
  else
    ok
  fi
}

health_for_load() {
  local load=$1
  local cores
  cores=$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '1')
  awk -v load="$load" -v cores="$cores" 'BEGIN { exit !(load > cores) }'
  if [[ $? -eq 0 ]]; then
    warn
  else
    ok
  fi
}

print_header() {
  printf '%sRaspberry Pi health report%s\n' "$bold" "$reset"
  printf '%sGenerated:%s %s\n' "$dim" "$reset" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
}

print_system() {
  section "System"
  printf '%-18s %s\n' "Hostname:" "$(hostname 2>/dev/null || printf '?')"
  printf '%-18s %s\n' "Kernel:" "$(uname -r 2>/dev/null || printf '?')"
  if command_exists hostnamectl; then
    hostnamectl 2>/dev/null | awk -F': ' '/Operating System|Architecture/ { printf "%-18s %s\n", $1 ":", $2 }'
  fi
  printf '%-18s %s\n' "Uptime:" "$(uptime -p 2>/dev/null || uptime)"

  local load1 load5 load15
  read -r load1 load5 load15 _ < /proc/loadavg
  printf '%-18s %s %s %s [%s]\n' "Load avg:" "$load1" "$load5" "$load15" "$(health_for_load "$load1")"
}

print_thermal() {
  section "Thermal and power"

  local temp throttle raw_throttle fan_hwmon fan_rpm fan_pwm cooling_state
  temp=$(cpu_temp_c)
  printf '%-18s %s°C [%s]\n' "CPU temp:" "$temp" "$(health_for_temp "$temp")"

  if command_exists vcgencmd; then
    raw_throttle=$(vcgencmd get_throttled 2>/dev/null || true)
    throttle=${raw_throttle#throttled=}
    printf '%-18s %s (%s)\n' "Throttle flags:" "${throttle:-?}" "$(decode_throttle_flags "$raw_throttle")"
  fi

  cooling_state=$(read_first /sys/class/thermal/cooling_device0/cur_state)
  printf '%-18s %s\n' "Cooling state:" "$cooling_state"

  if fan_hwmon=$(find_hwmon_by_name pwmfan); then
    fan_rpm=$(read_first "$fan_hwmon/fan1_input")
    fan_pwm=$(read_first "$fan_hwmon/pwm1")
    printf '%-18s %s RPM\n' "Fan speed:" "$fan_rpm"
    printf '%-18s %s\n' "Fan PWM:" "$fan_pwm"
  else
    printf '%-18s %s\n' "Fan:" "pwmfan hwmon not found"
  fi
}

print_resources() {
  section "CPU and memory"
  if command_exists top; then
    LC_ALL=C top -bn1 | head -n 5
  fi

  printf '\n%sTop CPU processes%s\n' "$bold" "$reset"
  ps -eo pid,ppid,stat,pcpu,pmem,comm --sort=-pcpu | head -n 12

  printf '\n%sTop memory processes%s\n' "$bold" "$reset"
  ps -eo pid,ppid,stat,pcpu,pmem,comm --sort=-pmem | head -n 12
}

print_services() {
  section "Systemd"
  if command_exists systemctl; then
    local failed_count
    failed_count=$(systemctl --failed --no-legend 2>/dev/null | wc -l | tr -d ' ')
    printf '%-18s %s [%s]\n' "Failed units:" "$failed_count" "$([[ "$failed_count" == "0" ]] && ok || bad)"
    systemctl --failed --no-pager 2>/dev/null || true
  else
    printf 'systemctl not found\n'
  fi
}

print_docker() {
  section "Docker"
  if ! command_exists docker; then
    printf 'docker not found\n'
    return
  fi

  local unhealthy_count
  unhealthy_count=$(docker ps --filter health=unhealthy --format '{{.Names}}' 2>/dev/null | wc -l | tr -d ' ')
  printf '%-18s %s [%s]\n' "Unhealthy:" "$unhealthy_count" "$([[ "$unhealthy_count" == "0" ]] && ok || bad)"

  printf '\n%sContainers%s\n' "$bold" "$reset"
  docker ps --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null || true

  printf '\n%sLive usage%s\n' "$bold" "$reset"
  docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}' 2>/dev/null || true
}

print_disk() {
  section "Disk"
  df -hT --exclude-type=tmpfs --exclude-type=devtmpfs 2>/dev/null || df -hT
}

print_kernel_warnings() {
  section "Recent kernel warnings/errors since boot"
  if command_exists journalctl; then
    journalctl -k -p warning..alert -b --no-pager -n 40 2>/dev/null || true
  else
    printf 'journalctl not found\n'
  fi
}

main() {
  print_header
  print_system
  print_thermal
  print_resources
  print_services
  print_docker
  print_disk
  print_kernel_warnings
}

main "$@"
