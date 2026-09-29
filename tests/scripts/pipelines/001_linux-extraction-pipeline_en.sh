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

# Exit on any error
set -euo pipefail

readonly SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source_preload() {
  if [ -f "$SELF_DIR/../preload.sh" ];then
    source "$SELF_DIR/../preload.sh"
  else
    echo "Terminating: preload.sh script not found."
    exit 1
  fi

  if [ -f "$SELF_DIR/../shared.sh" ]; then
    source "$SELF_DIR/../shared.sh"
    echo "Successfully sourced shared.sh file."
  else
    echo "Terminating: shared.sh script not found."
    exit 1
  fi
}

set_global_variables() {
  readonly WORKBENCH_DIR="$(realpath "$SELF_DIR/../../..")"
  readonly WORKSPACE_DIR="$WORKBENCH_DIR/tests/resources/workspace-001"
  readonly PROCESSORS_DIR="$WORKBENCH_DIR/processors"
  readonly KONTINUUM_PROCESSORS_DIR="$EXTERNAL_KONTINUUM_DIR/processors"

  LOG_DIR="$WORKBENCH_DIR/.logs"
  logger_init "$LOG_DIR/linux-extraction-pipeline_en.log"
  create_workspace_variables "$WORKSPACE_DIR/ubuntu-linux-extraction" "ubuntu-linux-extraction"

  ENV_REFERENCE_INVENTORY_DIR="$WORKBENCH_DIR/inventories/example-reference-inventory/inventory"
  ENV_REFERENCE_LICENSES_DIR="$WORKBENCH_DIR/inventories/example-reference-inventory/licenses"
  ENV_REFERENCE_COMPONENTS_DIR="$WORKBENCH_DIR/inventories/example-reference-inventory/components"

  PARAM_SECURITY_POLICY_FILE="$WORKBENCH_DIR/policies/security-policy/security-policy.json"

  SECURITY_POLICY_ACTIVE_IDS="assessment_enrichment_configuration"

  TENANT_ID="metaeffekt"
  ASSET_ID="ubuntu-linux-extraction"
  ASSESSMENT_CONTEXT="local"
}

extract() {
  log_info "Running update_mirror process."

  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/extract/extract_linux-arch-inventory.xml" prepare-package)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  CMD+=("-Dinput.extract.dir=$WORKSPACE_DIR/ubuntu-linux-extraction/00_fetched")
  CMD+=("-Dinput.exclude.patterns.file=$WORKSPACE_DIR/ubuntu-linux-extraction/config/excludes.yaml")
  CMD+=("-Doutput.inventory.file=$WORKSPACE_DIR/ubuntu-linux-extraction/01_extracted/ubuntu-linux-extraction.xlsx")

  pass_command_info_to_logger "extract"
}


main() {
  source_preload
  set_global_variables
  SCRIPT_NAME=$(basename "$(readlink -f "$0")")

  extract

}

main "$@"
