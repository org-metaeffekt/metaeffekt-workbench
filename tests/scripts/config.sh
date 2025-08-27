#!/bin/bash

set -euo pipefail

# Define base directories
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export WORKBENCH_DIR=$(realpath "$SELF_DIR/../..")
export PROCESSORS_DIR="$WORKBENCH_DIR/processors"
export KONTINUUM_PROCESSORS_DIR=$(realpath "$WORKBENCH_DIR/../../metaeffekt-kontinuum/processors")

export RESOURCES_DIR=$(realpath "$SELF_DIR/../resources")
export CASES_DIR="$SELF_DIR/cases"

# Define target directories
TARGET_BASE_DIR="$SELF_DIR/target"
ANALYZED_DIR="$TARGET_BASE_DIR/analyzed"
RESOLVED_DIR="$TARGET_BASE_DIR/resolved"
ADVISED_DIR="$TARGET_BASE_DIR/advised"
SCANNED_DIR="$TARGET_BASE_DIR/scanned"
REPORTED_DIR="$TARGET_BASE_DIR/reported"
UTIL_DIR="$TARGET_BASE_DIR/util"
CONVERTED_DIR="$TARGET_BASE_DIR/converted"

# Parse command line options
while getopts "c:" flag; do
    case "$flag" in
        c) CASE="$OPTARG" ;;
        *) cat <<EOF
            Usage: $0 [options]
                -c <case>   : which case to select for running the test. Either an absolute path or relative to the CASES_DIR, defined in the config.sh
                -h          : show this help message

            EXAMPLE:
                ./script.sh -c /path/to/case
EOF
    esac
done

# Check if selected case exists
if [ -f "$CASES_DIR/$CASE" ]; then
   source "$CASES_DIR/$CASE"
elif [ -f "$CASE" ]; then
   source "$CASE"
else
    echo "Error: Case [$CASE] does not exist. Has to be either relative to [$CASES_DIR] or as an absolute path."
    exit 1
fi

# Create all target directories
echo "Creating target directories..."
if ! mkdir -p "$CONVERTED_DIR" "$ANALYZED_DIR" "$RESOLVED_DIR" "$ADVISED_DIR" "$SCANNED_DIR" "$REPORTED_DIR" "$UTIL_DIR"; then
    echo "Error: Failed to create target directories" >&2
    exit 1
fi

echo "Configuration loaded successfully"
