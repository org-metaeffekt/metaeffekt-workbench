#!/bin/bash

# Exit on any error
set -euo pipefail

readonly SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source_preload() {
    if [ -f "$SELF_DIR/../preload.sh" ];then
      source "$SELF_DIR/../preload.sh"
      echo "Successfully sourced preload.sh file."
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
  logger_init "$LOG_DIR/001-cisco-catalyst-sd-wan-manager-pipeline_en.log"
  create_workspace_directories "$WORKSPACE_DIR/cisco-catalyst-sd-wan-manager-20.12.5.2" "cisco-catalyst-sd-wan-manager-20.12.5.2"

  ENV_REPORT_TEMPLATE_DIR="$WORKBENCH_DIR/templates/report-template"
  PARAM_SECURITY_POLICY_FILE="$WORKBENCH_DIR/policies/security-policy/security-policy.json"

  ENV_VR_DESCRIPTOR_FILE="$WORKBENCH_DIR/descriptors/asset-descriptor_GENERIC-vulnerability-report.yaml"
}

update_mirror() {
  log_info "Running update_mirror process."

  MIRROR_TARGET_DIR="$EXTERNAL_VULNERABILITY_MIRROR_DIR"
  MIRROR_ARCHIVE_URL="$EXTERNAL_VULNERABILITY_MIRROR_URL"
  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/mirror/mirror_download-index.xml" compile)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")

  CMD+=("-Dparam.mirror.archive.url=$MIRROR_ARCHIVE_URL")

  CMD+=("-Denv.vulnerability.mirror.dir=$MIRROR_TARGET_DIR")

  pass_command_info_to_logger "update_mirror"
}


enrich_inventory() {
  log_info "Running enrich_inventory process."

  PREPARED_INVENTORY_FILE="$PREPARED_DIR/cisco-catalyst-inventory.xls"
  ASSESSMENT_DIR="$WORKBENCH_DIR/assessments/assessment-001/cisco-catalyst-sd-wan-manager"
  CONTEXT_DIR="$WORKBENCH_DIR/contexts/example-001"
  CORRELATION_DIR="$WORKBENCH_DIR/correlations/shared"
  ADVISED_INVENTORY_FILE="$ADVISED_DIR/cisco-catalyst-sd-wan-manager-advised-inventory.xlsx"
  PROCESSOR_TMP_DIR="$ADDITIONAL_DIR/processor"
  DASHBOARD_SUBJECT="Cisco Catalyst SD-WAN Manager"
  SECURITY_POLICY_ACTIVE_IDS="assessment_enrichment_configuration"
  ACTIVATE_MSRC="false"

  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_enrich-inventory.xml" process-resources)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  CMD+=("-Dinput.inventory.file=$PREPARED_INVENTORY_FILE")

  CMD+=("-Doutput.inventory.file=$ADVISED_INVENTORY_FILE")
  CMD+=("-Doutput.tmp.dir=$PROCESSOR_TMP_DIR")

  CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
  CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
  CMD+=("-Dparam.security.policy.active.ids=$SECURITY_POLICY_ACTIVE_IDS")
  CMD+=("-Dparam.dashboard.title=Cisco Catalyst SD-WAN Manager 20.12.5.2 Assessment")
  CMD+=("-Dparam.dashboard.subtitle=")
  CMD+=("-Dparam.dashboard.footer=Cisco Catalyst SD-WAN Manager 20.12.5.2")
  CMD+=("-Dparam.assessment.dir=$ASSESSMENT_DIR")
  CMD+=("-Dparam.correlation.dir=$CORRELATION_DIR")
  CMD+=("-Dparam.context.dir=$CONTEXT_DIR")
  CMD+=("-Dparam.activate.msrc=$ACTIVATE_MSRC")


  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")

  pass_command_info_to_logger "enrich_inventory"
}

copy_to_grouped() {
  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/util/util_transform-inventories.xml" process-resources)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  CMD+=("-Dinput.inventory.dir=$WORKSPACE_DIR/cisco-catalyst-sd-wan-manager-20.12.5.2")
  CMD+=("-Doutput.inventory.dir=$WORKSPACE_DIR/cisco-catalyst-sd-wan-manager-20.12.5.2/07_grouped")
  CMD+=("-Dparam.kotlin.script.file=$WORKBENCH_DIR/scripts/group.kts")
  CMD+=("-Dparam.asset.name=cisco-catalyst-sd-wan-manager-20.12.5.2")

  pass_command_info_to_logger "group"
}

generate_vulnerability_assessment_dashboard() {
  log_info "Running generate_vulnerability_assessment_dashboard process."

  OUTPUT_DASHBOARD_FILE="$ADVISED_DIR/dashboards/cisco-catalyst-sd-wan-manager-20.12.5.2-dashboard.html"
  SECURITY_POLICY_ACTIVE_IDS="assessment_enrichment_configuration"

  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_create-dashboard.xml" process-resources)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  CMD+=("-Dinput.inventory.file=$ADVISED_INVENTORY_FILE")

  CMD+=("-Doutput.dashboard.file=$OUTPUT_DASHBOARD_FILE")

  CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
  CMD+=("-Dparam.security.policy.active.ids=$SECURITY_POLICY_ACTIVE_IDS")

  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")

  pass_command_info_to_logger "generate_vulnerability_assessment_dashboard"
}

generate_vulnerability_report() {
  log_info "Running generate_vulnerability_report process."

  OUTPUT_VR_FILE="$REPORTED_DIR/cisco-catalyst-sd-wan-manager-vulnerability-report-de.pdf"
  OUTPUT_COMPUTED_INVENTORY_DIR="$ADDITIONAL_DIR/report"

  PARAM_DOCUMENT_TYPE="VR"
  PARAM_ASSET_ID="Cisco Catalyst SD-WAN Manager"
  PARAM_ASSET_NAME="Cisco Catalyst SD-WAN Manager"
  PARAM_ASSET_VERSION="20.12.5.2"
  PARAM_PRODUCT_NAME="Cisco Catalyst SD-WAN Manager"
  PARAM_PRODUCT_VERSION="20.12.5.2"
  PARAM_PRODUCT_WATERMARK="Cisco Catalyst SD-WAN Manager"
  PARAM_OVERVIEW_ADVISORS="CERT_FR"

  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/report/report_create-document.xml" verify)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  CMD+=("-Dinput.inventory.dir=$GROUPED_VR_DIR")

  CMD+=("-Doutput.document.file=$OUTPUT_VR_FILE")

  CMD+=("-Dparam.asset.descriptor.file=$ENV_VR_DESCRIPTOR_FILE")
  CMD+=("-Dparam.asset.id=$PARAM_ASSET_ID")
  CMD+=("-Dparam.asset.name=$PARAM_ASSET_NAME")
  CMD+=("-Dparam.asset.version=$PARAM_ASSET_VERSION")
  CMD+=("-Dparam.product.version=$PARAM_PRODUCT_VERSION")
  CMD+=("-Dparam.product.name=$PARAM_PRODUCT_NAME")
  CMD+=("-Dparam.product.watermark=$PARAM_PRODUCT_WATERMARK")
  CMD+=("-Dparam.document.type=$PARAM_DOCUMENT_TYPE")
  CMD+=("-Dparam.overview.advisors=$PARAM_OVERVIEW_ADVISORS")
  CMD+=("-Dparam.property.selector.organization=metaeffekt")

  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")
  CMD+=("-Denv.workbench.dir=$WORKBENCH_DIR")
  CMD+=("-Denv.kontinuum.dir=$EXTERNAL_KONTINUUM_DIR")

  pass_command_info_to_logger "generate_vulnerability-report"
}

main() {
  source_preload
  set_global_variables
  SCRIPT_NAME=$(basename "$(readlink -f "$0")")

  update_mirror
  enrich_inventory

  copy_to_grouped

  generate_vulnerability_assessment_dashboard
  generate_vulnerability_report
}

main "$@"