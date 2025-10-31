#!/bin/bash

set -euo pipefail

# Define base directories
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export WORKBENCH_DIR=$(realpath "$SELF_DIR/../..")
export PROCESSORS_DIR="$WORKBENCH_DIR/processors"
export KONTINUUM_PROCESSORS_DIR=$(realpath "$EXTERNAL_KONTINUUM_DIR/processors")

export RESOURCES_DIR=$(realpath "$SELF_DIR/../resources")
export CASES_DIR="$SELF_DIR/cases"

# Define target directories
readonly TARGET_BASE_DIR="$SELF_DIR/target"
readonly ANALYZED_DIR="$TARGET_BASE_DIR/analyzed"
readonly RESOLVED_DIR="$TARGET_BASE_DIR/resolved"
readonly ADVISED_DIR="$TARGET_BASE_DIR/advised"
readonly SCANNED_DIR="$TARGET_BASE_DIR/scanned"
readonly REPORTED_DIR="$TARGET_BASE_DIR/reported"
readonly UTIL_DIR="$TARGET_BASE_DIR/util"
readonly CONVERTED_DIR="$TARGET_BASE_DIR/converted"

print_usage() {
    cat << EOF
Usage: $0 [options]
    -c <case>   : Which case to select for running the test. Either an absolute
                  path or relative to the CASES_DIR ($CASES_DIR)
    -l          : Provides the log level, can either be ALL, CONFIG, CMD, INFO or ERROR
    -f          : In which file to log all information
    -h          : Show this help message
    -o          : If set, outputs the logs on the console

Example:
    $0 -c /path/to/case -l CMD -o
EOF
}

source_case_file() {
    local case_file="$1"
    if [[ -f "$CASES_DIR/$case_file" ]]; then
        source "$CASES_DIR/$case_file"
        log_info "Successfully sourced case file $(realpath "$CASES_DIR/$case_file")"
    elif [[ -f "$case_file" ]]; then
        source "$case_file"
        log_info "Successfully sourced case file $(realpath "$case_file")"
    else
        log_error "Case [$case_file] does not exist. Must be either relative to [$CASES_DIR] or an absolute path."
        exit 1
    fi
}
