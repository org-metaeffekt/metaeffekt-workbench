#!/bin/bash

# Exit on any error
set -euo pipefail
readonly SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source_preload() {
    if [ -f "$SELF_DIR/../preload.sh" ];then
      source "$SELF_DIR/../preload.sh"
      echo "Successfully sourced preload.sh file"
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

  readonly TARGET_BASE_DIR="$WORKSPACE_DIR/sample-product-1.0.0"
  readonly ANALYZED_DIR="$TARGET_BASE_DIR/02_analyzed"
  readonly CURATED_DIR="$TARGET_BASE_DIR/03_curated"
  readonly ADVISED_DIR="$TARGET_BASE_DIR/04_advised"
  readonly REPORTED_DIR="$TARGET_BASE_DIR/05_reported"
  readonly TMP_DIR="$TARGET_BASE_DIR/99_tmp"

  ENV_REFERENCE_INVENTORY_DIR="$WORKBENCH_DIR/inventories/example-reference-inventory/inventory"
  ENV_REFERENCE_LICENSES_DIR="$WORKBENCH_DIR/inventories/example-reference-inventory/licenses"
  ENV_REFERENCE_COMPONENTS_DIR="$WORKBENCH_DIR/inventories/example-reference-inventory/components"

  ENV_REPORT_TEMPLATE_DIR="$WORKBENCH_DIR/templates/report-template"
  PARAM_SECURITY_POLICY_FILE="$WORKBENCH_DIR/policies/security-policy/security-policy.json"

  ENV_DESCRIPTOR_DIR="$WORKBENCH_DIR/descriptors"
  ENV_SDA_DESCRIPTOR_PATH="asset-descriptor_GENERIC-software-distribution-annex.yaml"
  ENV_VR_DESCRIPTOR_PATH="asset-descriptor_GENERIC-vulnerability-report.yaml"
  ENV_CR_DESCRIPTOR_PATH="asset-descriptor_GENERIC-cert-report.yaml"
}

create_target_directories() {
    if ! mkdir -p "$ANALYZED_DIR" "$ADVISED_DIR" "$REPORTED_DIR" "$TMP_DIR" ; then
        log_error "Failed to create target directories"
        exit 1
    fi
}

update_mirror() {
  log_info "Running update_mirror process."

  MIRROR_TARGET_DIR="$EXTERNAL_VULNERABILITY_MIRROR_DIR"
  MIRROR_ARCHIVE_URL="$EXTERNAL_VULNERABILITY_MIRROR_URL"
  MIRROR_ARCHIVE_NAME="$EXTERNAL_VULNERABILITY_MIRROR_NAME"
  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/mirror/mirror_download-index.xml" compile)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")

  CMD+=("-Dparam.mirror.archive.url=$MIRROR_ARCHIVE_URL")
  CMD+=("-Dparam.mirror.archive.name=$MIRROR_ARCHIVE_NAME")

  CMD+=("-Denv.vulnerability.mirror.dir=$MIRROR_TARGET_DIR")

  pass_command_info_to_logger "update_mirror"
}

enrich_inventory_with_reference() {
  log_info "Running enrich_inventory_with_reference process."

  ANALYZED_INVENTORY_FILE="$ANALYZED_DIR/sample-asset-1.0/sample-asset-1.0-inventory.xls"
  CURATED_INVENTORY_DIR="$CURATED_DIR/sample-asset-1.0"
  CURATED_INVENTORY_PATH="sample-asset-1.0-inventory.xls"

  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_enrich-with-reference.xml" process-resources)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  CMD+=("-Dinput.inventory.file=$ANALYZED_INVENTORY_FILE")
  CMD+=("-Dinput.reference.inventory.dir=$ENV_REFERENCE_INVENTORY_DIR")

  CMD+=("-Doutput.inventory.dir=$CURATED_INVENTORY_DIR")
  CMD+=("-Doutput.inventory.path=$CURATED_INVENTORY_PATH")

  pass_command_info_to_logger "enrich_inventory_with_reference"
}

create_annex() {
  log_info "Running create_annex process."

  OUTPUT_ANNEX_FILE="$REPORTED_DIR/software-distribution-annex-en.pdf"
  OUTPUT_COMPUTED_INVENTORY_DIR="$TMP_DIR/report"

  PARAM_DOCUMENT_TYPE="SDA"
  PARAM_DOCUMENT_LANGUAGE="en"
  PARAM_ASSET_ID="Sample Product"
  PARAM_ASSET_NAME="SampleProduct"
  PARAM_ASSET_VERSION="1.0.0"
  PARAM_PRODUCT_NAME="Sample Product"
  PARAM_PRODUCT_VERSION="1.0.0"
  PARAM_PRODUCT_WATERMARK="Sample"
  PARAM_OVERVIEW_ADVISORS="CERT_FR"

  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/report/report_create-document.xml" verify)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  CMD+=("-Dinput.inventory.file=$CURATED_INVENTORY_DIR/$CURATED_INVENTORY_PATH")
  CMD+=("-Dinput.reference.inventory.file=$ENV_REFERENCE_INVENTORY_DIR/artifact-inventory.xls")
  CMD+=("-Dinput.reference.license.dir=$ENV_REFERENCE_LICENSES_DIR")
  CMD+=("-Dinput.reference.component.dir=$ENV_REFERENCE_COMPONENTS_DIR")
  CMD+=("-Dinput.asset.descriptor.dir=$ENV_DESCRIPTOR_DIR")
  CMD+=("-Dinput.asset.descriptor.path=$ENV_SDA_DESCRIPTOR_PATH")

  CMD+=("-Doutput.document.file=$OUTPUT_ANNEX_FILE")
  CMD+=("-Doutput.computed.inventory.path=$OUTPUT_COMPUTED_INVENTORY_DIR") # Do not change parameter name, needed by asset descriptor

  CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
  CMD+=("-Dparam.asset.id=$PARAM_ASSET_ID")
  CMD+=("-Dparam.asset.name=$PARAM_ASSET_NAME")
  CMD+=("-Dparam.asset.version=$PARAM_ASSET_VERSION")
  CMD+=("-Dparam.product.version=$PARAM_PRODUCT_VERSION")
  CMD+=("-Dparam.product.name=$PARAM_PRODUCT_NAME")
  CMD+=("-Dparam.product.watermark=$PARAM_PRODUCT_WATERMARK")
  CMD+=("-Dparam.document.type=$PARAM_DOCUMENT_TYPE")
  CMD+=("-Dparam.document.language=$PARAM_DOCUMENT_LANGUAGE")
  CMD+=("-Dparam.overview.advisors=$PARAM_OVERVIEW_ADVISORS")
  CMD+=("-Dparam.template.dir=$ENV_REPORT_TEMPLATE_DIR")
  CMD+=("-Dparam.property.selector.organization=metaeffekt")

  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")
  CMD+=("-Denv.workbench.processors.dir=$PROCESSORS_DIR")
  CMD+=("-Denv.kontinuum.processors.dir=$KONTINUUM_PROCESSORS_DIR")

  pass_command_info_to_logger "create_annex"
}

enrich_inventory() {
  log_info "Running enrich_inventory process."

  ADVISED_INVENTORY_FILE="$ADVISED_DIR/sample-product-asset-inventory.xlsx"
  ASSESSMENT_DIR="$WORKBENCH_DIR/assessments/assessment-001/sample-product"
  CONTEXT_DIR="$WORKBENCH_DIR/contexts/example-001"
  CORRELATION_DIR="$WORKBENCH_DIR/correlations/shared"
  ADVISED_INVENTORY_FILE="$ADVISED_DIR/sample-product-advised-inventory.xlsx"
  PROCESSOR_TMP_DIR="$TMP_DIR/processor"
  SECURITY_POLICY_ACTIVE_IDS="assessment_enrichment_configuration"

  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_enrich-inventory.xml" process-resources)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  CMD+=("-Dinput.inventory.file=$CURATED_INVENTORY_DIR/$CURATED_INVENTORY_PATH")

  CMD+=("-Doutput.inventory.file=$ADVISED_INVENTORY_FILE")
  CMD+=("-Doutput.tmp.dir=$PROCESSOR_TMP_DIR")

  CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
  CMD+=("-Dparam.security.policy.active.ids=$SECURITY_POLICY_ACTIVE_IDS")
  CMD+=("-Dparam.assessment.dir=$ASSESSMENT_DIR")
  CMD+=("-Dparam.correlation.dir=$CORRELATION_DIR")
  CMD+=("-Dparam.context.dir=$CONTEXT_DIR")

  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")

  pass_command_info_to_logger "enrich_inventory"
}

generate_vulnerability_report() {
  log_info "Running generate_vulnerability_report process."

  OUTPUT_VR_FILE="$REPORTED_DIR/vulnerability-report-en.pdf"
  OUTPUT_COMPUTED_INVENTORY_DIR="$TMP_DIR/report"

  PARAM_DOCUMENT_TYPE="VR"
  PARAM_DOCUMENT_LANGUAGE="en"
  PARAM_ASSET_ID="Sample Product"
  PARAM_ASSET_NAME="SampleProduct"
  PARAM_ASSET_VERSION="1.0.0"
  PARAM_PRODUCT_NAME="Sample Product"
  PARAM_PRODUCT_VERSION="1.0.0"
  PARAM_PRODUCT_WATERMARK="Sample"
  PARAM_OVERVIEW_ADVISORS="CERT_FR"

  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/report/report_create-document.xml" verify)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  CMD+=("-Dinput.inventory.file=$ADVISED_INVENTORY_FILE")
  CMD+=("-Dinput.reference.inventory.file=$ENV_REFERENCE_INVENTORY_DIR/artifact-inventory.xls")
  CMD+=("-Dinput.reference.license.dir=$ENV_REFERENCE_LICENSES_DIR")
  CMD+=("-Dinput.reference.component.dir=$ENV_REFERENCE_COMPONENTS_DIR")
  CMD+=("-Dinput.asset.descriptor.dir=$ENV_DESCRIPTOR_DIR")
  CMD+=("-Dinput.asset.descriptor.path=$ENV_VR_DESCRIPTOR_PATH")

  CMD+=("-Doutput.document.file=$OUTPUT_VR_FILE")
  CMD+=("-Doutput.computed.inventory.path=$OUTPUT_COMPUTED_INVENTORY_DIR") # Do not change parameter name, needed by asset descriptor

  CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
  CMD+=("-Dparam.asset.id=$PARAM_ASSET_ID")
  CMD+=("-Dparam.asset.name=$PARAM_ASSET_NAME")
  CMD+=("-Dparam.asset.version=$PARAM_ASSET_VERSION")
  CMD+=("-Dparam.product.version=$PARAM_PRODUCT_VERSION")
  CMD+=("-Dparam.product.name=$PARAM_PRODUCT_NAME")
  CMD+=("-Dparam.product.watermark=$PARAM_PRODUCT_WATERMARK")
  CMD+=("-Dparam.document.type=$PARAM_DOCUMENT_TYPE")
  CMD+=("-Dparam.document.language=$PARAM_DOCUMENT_LANGUAGE")
  CMD+=("-Dparam.overview.advisors=$PARAM_OVERVIEW_ADVISORS")
  CMD+=("-Dparam.template.dir=$ENV_REPORT_TEMPLATE_DIR")
  CMD+=("-Dparam.property.selector.organization=metaeffekt")

  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")
  CMD+=("-Denv.workbench.processors.dir=$PROCESSORS_DIR")
  CMD+=("-Denv.kontinuum.processors.dir=$KONTINUUM_PROCESSORS_DIR")

  pass_command_info_to_logger "generate_vulnerability-report"
}

generate_cert_report() {
  log_info "Running generate_cert_report process."

  OUTPUT_CR_FILE="$REPORTED_DIR/cert-report-en.pdf"
  OUTPUT_COMPUTED_INVENTORY_DIR="$TMP_DIR/report"

  PARAM_DOCUMENT_TYPE="CR"
  PARAM_DOCUMENT_LANGUAGE="en"
  PARAM_ASSET_ID="Sample Product"
  PARAM_ASSET_NAME="SampleProduct"
  PARAM_ASSET_VERSION="1.0.0"
  PARAM_PRODUCT_NAME="Sample Product"
  PARAM_PRODUCT_VERSION="1.0.0"
  PARAM_PRODUCT_WATERMARK="Sample"
  PARAM_OVERVIEW_ADVISORS="CERT_FR"

  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/report/report_create-document.xml" verify)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  CMD+=("-Dinput.inventory.file=$ADVISED_INVENTORY_FILE")
  CMD+=("-Dinput.reference.inventory.file=$ENV_REFERENCE_INVENTORY_DIR/artifact-inventory.xls")
  CMD+=("-Dinput.reference.license.dir=$ENV_REFERENCE_LICENSES_DIR")
  CMD+=("-Dinput.reference.component.dir=$ENV_REFERENCE_COMPONENTS_DIR")
  CMD+=("-Dinput.asset.descriptor.dir=$ENV_DESCRIPTOR_DIR")
  CMD+=("-Dinput.asset.descriptor.path=$ENV_CR_DESCRIPTOR_PATH")

  CMD+=("-Doutput.document.file=$OUTPUT_CR_FILE")
  CMD+=("-Doutput.computed.inventory.path=$OUTPUT_COMPUTED_INVENTORY_DIR") # Do not change parameter name, needed by asset descriptor

  CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
  CMD+=("-Dparam.asset.id=$PARAM_ASSET_ID")
  CMD+=("-Dparam.asset.name=$PARAM_ASSET_NAME")
  CMD+=("-Dparam.asset.version=$PARAM_ASSET_VERSION")
  CMD+=("-Dparam.product.version=$PARAM_PRODUCT_VERSION")
  CMD+=("-Dparam.product.name=$PARAM_PRODUCT_NAME")
  CMD+=("-Dparam.product.watermark=$PARAM_PRODUCT_WATERMARK")
  CMD+=("-Dparam.document.type=$PARAM_DOCUMENT_TYPE")
  CMD+=("-Dparam.document.language=$PARAM_DOCUMENT_LANGUAGE")
  CMD+=("-Dparam.overview.advisors=$PARAM_OVERVIEW_ADVISORS")
  CMD+=("-Dparam.template.dir=$ENV_REPORT_TEMPLATE_DIR")
  CMD+=("-Dparam.property.selector.organization=metaeffekt")

  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")
  CMD+=("-Denv.workbench.processors.dir=$PROCESSORS_DIR")
  CMD+=("-Denv.kontinuum.processors.dir=$KONTINUUM_PROCESSORS_DIR")

  pass_command_info_to_logger "generate_cert_report"
}

generate_vulnerability_assessment_dashboard() {
  log_info "Running generate_vulnerability_assessment_dashboard process."

  OUTPUT_DASHBOARD_FILE="$ADVISED_DIR/dashboards/sample-product-dashboard.html"
  SECURITY_POLICY_ACTIVE_IDS="assessment_enrichment_configuration"

  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_create-dashboard.xml" process-resources)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  CMD+=("-Dinput.inventory.file=$ADVISED_INVENTORY_FILE")

  CMD+=("-Doutput.dashboard.file=$OUTPUT_DASHBOARD_FILE")

  CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
  CMD+=("-Dparam.security.policy.active.ids=$SECURITY_POLICY_ACTIVE_IDS")
  CMD+=("-Doutput.dashboard.file=$OUTPUT_DASHBOARD_FILE")
  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")

  pass_command_info_to_logger "generate_vulnerability_assessment_dashboard"
}

main() {
  source_preload
  set_global_variables
  SCRIPT_NAME=$(basename "$(readlink -f "$0")")
  create_target_directories

  update_mirror
  enrich_inventory_with_reference
  create_annex
  enrich_inventory
  generate_vulnerability_report
  generate_cert_report
  generate_vulnerability_assessment_dashboard
}

main "$@"