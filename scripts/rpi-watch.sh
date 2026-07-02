#!/usr/bin/env bash
# Live Raspberry Pi CPU, temperature, and fan monitor. Press Ctrl+C to stop.

set -uo pipefail

interval=${1:-1}

if ! [[ $interval =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  printf 'Usage: %s [interval_seconds]\n' "${0##*/}" >&2
  exit 2
fi

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

read_cpu_totals() {
  local cpu user nice system idle iowait irq softirq steal guest guest_nice
  read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
  printf '%s %s\n' "$((idle + iowait))" "$((user + nice + system + idle + iowait + irq + softirq + steal))"
}

cpu_usage_percent() {
  local prev_idle=$1 prev_total=$2 next_idle=$3 next_total=$4
  local idle_delta=$((next_idle - prev_idle))
  local total_delta=$((next_total - prev_total))

  if ((total_delta <= 0)); then
    printf '0.0'
    return
  fi

  awk -v idle="$idle_delta" -v total="$total_delta" 'BEGIN { printf "%.1f", 100 * (1 - idle / total) }'
}

cpu_temp_c() {
  if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
    awk '{printf "%.1f", $1 / 1000}' /sys/class/thermal/thermal_zone0/temp
    return
  fi

  if command_exists vcgencmd; then
    vcgencmd measure_temp 2>/dev/null | sed -E "s/temp=([0-9.]+).*/\1/"
    return
  fi

  printf '?'
}

find_pwmfan_hwmon() {
  local hwmon
  for hwmon in /sys/class/hwmon/hwmon*; do
    [[ -r "$hwmon/name" ]] || continue
    [[ $(<"$hwmon/name") == pwmfan ]] && printf '%s\n' "$hwmon" && return 0
  done
  return 1
}

fan_stats() {
  local hwmon=${1:-}
  if [[ -n $hwmon && -r "$hwmon/fan1_input" ]]; then
    printf '%s RPM' "$(<"$hwmon/fan1_input")"
    [[ -r "$hwmon/pwm1" ]] && printf ' / PWM %s' "$(<"$hwmon/pwm1")"
    return
  fi

  printf 'not found'
}

clear_screen() {
  if [[ ! -t 1 ]]; then
    return
  fi

  if [[ -n ${TERM:-} && ${TERM:-} != dumb ]] && command_exists tput; then
    tput clear
  else
    printf '\033c'
  fi
}

main() {
  local fan_hwmon prev_idle prev_total next_idle next_total cpu temp fan

  fan_hwmon=$(find_pwmfan_hwmon || true)
  read -r prev_idle prev_total < <(read_cpu_totals)

  while true; do
    sleep "$interval"
    read -r next_idle next_total < <(read_cpu_totals)

    cpu=$(cpu_usage_percent "$prev_idle" "$prev_total" "$next_idle" "$next_total")
    temp=$(cpu_temp_c)
    fan=$(fan_stats "$fan_hwmon")

    clear_screen
    printf 'Raspberry Pi live stats — %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    printf 'CPU:  %s%% used\n' "$cpu"
    printf 'Temp: %s°C\n' "$temp"
    printf 'Fan:  %s\n' "$fan"
    printf '\nInterval: %ss | Press Ctrl+C to stop\n' "$interval"

    prev_idle=$next_idle
    prev_total=$next_total
  done
}

main "$@"
