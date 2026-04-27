#!/bin/bash

# Copyright 2009-2026 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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

create_workspace_variables() {
  local TARGET_BASE_DIR="$1"
  local ASSET_NAME="$2"

  readonly ADDITIONAL_DIR="$TARGET_BASE_DIR/xx_additional/$ASSET_NAME"
  readonly FETCHED_DIR="$TARGET_BASE_DIR/00_fetched/$ASSET_NAME"
  readonly EXTRACTED_DIR="$TARGET_BASE_DIR/01_extracted/$ASSET_NAME"
  readonly PREPARED_DIR="$TARGET_BASE_DIR/02_prepared/$ASSET_NAME"
  readonly AGGREGATED_DIR="$TARGET_BASE_DIR/03_aggregated/$ASSET_NAME"
  readonly RESOLVED_DIR="$TARGET_BASE_DIR/04_resolved/$ASSET_NAME"
  readonly SCANNED_DIR="$TARGET_BASE_DIR/05_scanned/$ASSET_NAME"
  readonly ADVISED_DIR="$TARGET_BASE_DIR/06_advised/$ASSET_NAME"
  readonly GROUPED_DIR="$TARGET_BASE_DIR/07_grouped/$ASSET_NAME"
  readonly REPORTED_DIR="$TARGET_BASE_DIR/08_reported/$ASSET_NAME"
  readonly SUMMARIZED_DIR="$TARGET_BASE_DIR/09_summarized/$ASSET_NAME"

  readonly GROUPED_CR_DIR="$GROUPED_DIR/cert-report"
  readonly GROUPED_CA_DIR="$GROUPED_DIR/custom-annex"
  readonly GROUPED_ILD_DIR="$GROUPED_DIR/initial-license-documentation"
  readonly GROUPED_LD_DIR="$GROUPED_DIR/license-documentation"
  readonly GROUPED_SDA_DIR="$GROUPED_DIR/software-distribution-annex"
  readonly GROUPED_VR_DIR="$GROUPED_DIR/vulnerability-report"
  readonly GROUPED_VSR_DIR="$GROUPED_DIR/vulnerability-summary-report"
}
