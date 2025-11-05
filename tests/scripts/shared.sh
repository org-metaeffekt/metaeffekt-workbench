#!/bin/bash

set -euo pipefail

print_usage() {
    cat << EOF
Usage: $0 [options]
    -c <case>   : Which case to select for running the test. Either an absolute
                  path or relative to the CASES_DIR ($CASES_DIR)
    -f          : In which file to log all information
    -h          : Show this help message

Example:
    $0 -c /path/to/case -f ./logs
EOF
}

pass_command_info_to_logger() {
  local processor_name="$1"

  log_info ""
  log_info "Running $processor_name"
  log_maven_params
  log_debug "${CMD[*]}"

  if "${CMD[@]}" 2>&1 | while IFS= read -r line; do log_debug "$line"; done; then
      log_info "Successfully ran $processor_name"
  else
      log_error "Failed to run $processor_name because the underlying maven call failed."
      return 1
  fi
}
