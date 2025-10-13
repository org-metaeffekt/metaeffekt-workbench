#!/bin/bash

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_PATH="$SELF_DIR/../config.sh"
LOG_DIR="$SELF_DIR/../../../.logs"
CASE="report_create-document-01.sh"

check_shared_config() {
  if [[ -f "$CONFIG_PATH" ]]; then
      source "$CONFIG_PATH"
      log_info  "Successfully sourced config.sh script."
  else
      log_error "Config file not found at $CONFIG_PATH"
      exit 1
  fi
}

source_preload() {
    if [ -f "$SELF_DIR/../preload.sh" ];then
      source "$SELF_DIR/../preload.sh"
      echo "Successfully sourced preload.sh file"
    else
      echo "Terminating: preload.sh script not found."
      exit 1
    fi
}

run_maven_command() {
  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/report/report_create-document.xml" verify)
  CMD+=("-Dinput.asset.descriptor.dir=$INPUT_ASSET_DESCRIPTOR_DIR")
  CMD+=("-Dinput.asset.descriptor.path=$INPUT_ASSET_DESCRIPTOR_PATH")
  CMD+=("-Dinput.inventory.file=$INPUT_INVENTORY_FILE")
  CMD+=("-Dinput.reference.inventory.file=$INPUT_REFERENCE_INVENTORY_FILE")
  CMD+=("-Dinput.reference.license.dir=$INPUT_REFERENCE_LICENSE_DIR")
  CMD+=("-Dinput.reference.component.dir=$INPUT_REFERENCE_COMPONENT_DIR")
  CMD+=("-Dparam.security.policydir=$INPUT_SECURITY_POLICY_DIR")
  CMD+=("-Doutput.document.file=$OUTPUT_DOCUMENT_FILE")
  CMD+=("-Doutput.computed.inventory.path=$OUTPUT_COMPUTED_INVENTORY_DIR")
  CMD+=("-Dparam.document.type=$PARAM_DOCUMENT_TYPE")
  CMD+=("-Dparam.document.language=$PARAM_DOCUMENT_LANGUAGE")
  CMD+=("-Dparam.asset.id=$PARAM_ASSET_ID")
  CMD+=("-Dparam.asset.name=$PARAM_ASSET_NAME")
  CMD+=("-Dparam.asset.version=$PARAM_ASSET_VERSION")
  CMD+=("-Dparam.product.name=$PARAM_PRODUCT_NAME")
  CMD+=("-Dparam.product.version=$PARAM_PRODUCT_VERSION")
  CMD+=("-Dparam.product.watermark=$PARAM_PRODUCT_WATERMARK")
  CMD+=("-Dparam.overview.advisors=$PARAM_OVERVIEW_ADVISORS")
  CMD+=("-Dparam.property.selector.organization=$PARAM_PROPERTY_SELECTOR_ORGANIZATION")
  CMD+=("-Dparam.template.dir=$ENV_REPORT_TEMPLATE_DIR")
  CMD+=("-Denv.kontinuum.processors.dir=$KONTINUUM_PROCESSORS_DIR")
  CMD+=("-Denv.workbench.processors.dir=$PROCESSORS_DIR")
  CMD+=("-Denv.vulnerability.mirror.dir=$ENV_VULNERABILITY_MIRROR_DIR")

  log_info "Running processor $KONTINUUM_PROCESSORS_DIR/report/report_create-document.xml"

  log_config "input.asset.descriptor.dir=$INPUT_ASSET_DESCRIPTOR_DIR
              input.asset.descriptor.path=$INPUT_ASSET_DESCRIPTOR_PATH
              input.inventory.file=$INPUT_INVENTORY_FILE
              input.reference.inventory.file=$INPUT_REFERENCE_INVENTORY_FILE
              input.reference.license.dir=$INPUT_REFERENCE_LICENSE_DIR
              input.reference.component.dir=$INPUT_REFERENCE_COMPONENT_DIR
              param.security.policydir=$INPUT_SECURITY_POLICY_DIR" "
              output.document.file=$OUTPUT_DOCUMENT_FILE
              output.computed.inventory.path=$OUTPUT_COMPUTED_INVENTORY_DIR"

  log_mvn "${CMD[*]}"

  if "${CMD[@]}" 2>&1 | while IFS= read -r line; do log_mvn "$line"; done; then
      log_info "Successfully ran $KONTINUUM_PROCESSORS_DIR/report/report_create-document.xml"
  else
      log_error "Failed to run $KONTINUUM_PROCESSORS_DIR/report/report_create-document.xml because the maven execution was unsuccessful"
      return 1
  fi
}


main() {
  source_preload

  local case_file="$CASE"
  local log_level="CONFIG"
  local script_name=$(basename "$(readlink -f "$0")")
  local log_file="${LOG_DIR}/${script_name%.sh}.log"
  local console_output_enabled=true

  while getopts "c:l:f:ho" flag; do
            case "$flag" in
                c) case_file="$OPTARG" ;;
                h) print_usage; exit 0 ;;
                l) log_level="$OPTARG" ;;
                f) log_file="$OPTARG" ;;
                o) console_output_enabled=false ;;
                *) print_usage; exit 1 ;;
            esac
      done

  logger_init "$log_level" "$log_file" "$console_output_enabled"
  check_shared_config
  source_case_file "$case_file"

  run_maven_command
}

main "$@"