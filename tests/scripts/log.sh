#!/bin/bash

RED='\033[31m'
GREEN='\033[32m'
CYAN='\033[36m'
RESET='\033[0m'

LOG_FILE=""

logger_init() {
    LOG_FILE="$1"

    if [[ -n "$LOG_FILE" ]]; then
        local dir=$(dirname "$LOG_FILE")
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" || {
                echo "Error: Could not create directory for log file '$LOG_FILE'." >&2
                LOG_FILE=""
            }
        fi
    fi
}

_log_output() {
    local level="$1"
    local message="$2"
    local log_to_console="$3"
    [ "${DUMP_LOGS:-}" = true ] && log_to_console=true

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] $level: $message"

    if [[ -n "$LOG_FILE" ]]; then
        echo "$log_entry" >> "$LOG_FILE" 2>/dev/null || {
            echo "Error: Failed to write to log file '$LOG_FILE'." >&2
        }
    fi

    if [[ "$log_to_console" == "true" ]]; then
        local color=""
        local offset=""
        case "$level" in
            "ERROR")
                color="$RED"
                offset=" "
                ;;
            "INFO")
                color="$GREEN"
                offset="  "
                ;;
            "DEBUG")
                color="$CYAN"
                ;;
            *)
                color="$RESET"
                ;;
        esac
        local console_entry="[$timestamp] ${color} $level $offset${RESET}: $message${RESET}"
        echo -e "$console_entry" >&2
    fi
}

log_debug() {
  local message="$*"
  _log_output "DEBUG" "$message" "false"
}

log_info() {
  local message="$*"
  _log_output "INFO" "$message" "true"
}

log_maven_params() {
  local params=()

  for arg in "${CMD[@]}"; do
    if [[ $arg =~ ^-D(input|output|env)\. ]]; then
      # Remove the -D prefix and add to params array
      params+=("${arg#-D}")
    fi
  done

  if [ ${#params[@]} -gt 0 ]; then
    for param in "${params[@]}"; do
      log_info "$param"
    done
  fi
}

log_error() {
  local message="$*"
  _log_output "ERROR" "$message" "true"
}

export log_debug log_info log_error log_maven_params