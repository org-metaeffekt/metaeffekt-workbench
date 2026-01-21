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
  logger_init "$LOG_DIR/001_sample-product-pipeline_de.log"
  create_workspace_directories "$WORKSPACE_DIR/sample-product-1.0.0"

  ENV_REFERENCE_INVENTORY_DIR="$WORKBENCH_DIR/inventories/example-reference-inventory/inventory"
  ENV_REFERENCE_LICENSES_DIR="$WORKBENCH_DIR/inventories/example-reference-inventory/licenses"
  ENV_REFERENCE_COMPONENTS_DIR="$WORKBENCH_DIR/inventories/example-reference-inventory/components"

  ENV_REPORT_TEMPLATE_DIR="$WORKBENCH_DIR/templates/report-template"
  PARAM_SECURITY_POLICY_FILE="$WORKBENCH_DIR/policies/security-policy/security-policy.json"

  ENV_DESCRIPTOR_DIR="$WORKBENCH_DIR/descriptors"
  ENV_SDA_DESCRIPTOR_FILE="$ENV_DESCRIPTOR_DIR/asset-descriptor_GENERIC-software-distribution-annex.yaml"
  ENV_ILD_DESCRIPTOR_FILE="$ENV_DESCRIPTOR_DIR/asset-descriptor_GENERIC-initial-license-documentation.yaml"
  ENV_LD_DESCRIPTOR_FILE="$ENV_DESCRIPTOR_DIR/asset-descriptor_GENERIC-license-documentation.yaml"
  ENV_CAD_DESCRIPTOR_FILE="$ENV_DESCRIPTOR_DIR/asset-descriptor_GENERIC-custom-annex.yaml"
  ENV_VR_DESCRIPTOR_FILE="$ENV_DESCRIPTOR_DIR/asset-descriptor_GENERIC-vulnerability-report.yaml"
  ENV_CR_DESCRIPTOR_FILE="$ENV_DESCRIPTOR_DIR/asset-descriptor_GENERIC-cert-report.yaml"
  ENV_VSR_DESCRIPTOR_FILE="$ENV_DESCRIPTOR_DIR/asset-descriptor_GENERIC-vulnerability-summary-report.yaml"
  ENV_LANGUAGE="en"
}

update_mirror() {
  MIRROR_TARGET_DIR="$EXTERNAL_VULNERABILITY_MIRROR_DIR"
  MIRROR_ARCHIVE_URL="$EXTERNAL_VULNERABILITY_MIRROR_URL"

  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/mirror/mirror_download-index.xml" compile)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")

  CMD+=("-Dparam.mirror.archive.url=$MIRROR_ARCHIVE_URL")
  CMD+=("-Denv.vulnerability.mirror.dir=$MIRROR_TARGET_DIR")

  pass_command_info_to_logger "update_mirror"
}

enrich_inventory_with_reference() {
  PREPARED_INVENTORY_FILE="$PREPARED_DIR/sample-asset-1.0/sample-asset-1.0-inventory.xls"
  AGGREGATED_INVENTORY_DIR="$AGGREGATED_DIR/sample-asset-1.0"
  AGGREGATED_INVENTORY_PATH="sample-asset-1.0-inventory.xls"

  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_enrich-with-reference.xml" process-resources)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  CMD+=("-Dinput.inventory.file=$PREPARED_INVENTORY_FILE")

  CMD+=("-Doutput.inventory.dir=$AGGREGATED_INVENTORY_DIR")
  CMD+=("-Doutput.inventory.path=$AGGREGATED_INVENTORY_PATH")

  CMD+=("-Dparam.reference.inventory.dir=$ENV_REFERENCE_INVENTORY_DIR")
  pass_command_info_to_logger "enrich_inventory_with_reference"
}

enrich_inventory() {
  ASSESSMENT_DIR="$WORKBENCH_DIR/assessments/assessment-001/sample-product"
  CONTEXT_DIR="$WORKBENCH_DIR/contexts/example-001"
  CORRELATION_DIR="$WORKBENCH_DIR/correlations/shared"
  ADVISED_INVENTORY_FILE="$ADVISED_DIR/sample-product-advised-inventory.xlsx"
  PROCESSOR_TMP_DIR="$ADDITIONAL_DIR/processor"
  SECURITY_POLICY_ACTIVE_IDS="assessment_enrichment_configuration"
  ACTIVATE_MSRC="false"

  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_enrich-inventory.xml" process-resources)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  CMD+=("-Dinput.inventory.file=$AGGREGATED_INVENTORY_DIR/$AGGREGATED_INVENTORY_PATH")

  CMD+=("-Doutput.inventory.file=$ADVISED_INVENTORY_FILE")
  CMD+=("-Doutput.tmp.dir=$PROCESSOR_TMP_DIR")

  CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
  CMD+=("-Dparam.security.policy.active.ids=$SECURITY_POLICY_ACTIVE_IDS")
  CMD+=("-Dparam.assessment.dir=$ASSESSMENT_DIR")
  CMD+=("-Dparam.correlation.dir=$CORRELATION_DIR")
  CMD+=("-Dparam.context.dir=$CONTEXT_DIR")
  CMD+=("-Dparam.activate.msrc=$ACTIVATE_MSRC")

  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")

  pass_command_info_to_logger "enrich_inventory"
}

copy_to_grouped() {
  cp "$AGGREGATED_INVENTORY_DIR/$AGGREGATED_INVENTORY_PATH" "$GROUPED_SDA_DIR"
  cp "$AGGREGATED_INVENTORY_DIR/$AGGREGATED_INVENTORY_PATH" "$GROUPED_CR_DIR"
  cp "$AGGREGATED_INVENTORY_DIR/$AGGREGATED_INVENTORY_PATH" "$GROUPED_CA_DIR"
  cp "$AGGREGATED_INVENTORY_DIR/$AGGREGATED_INVENTORY_PATH" "$GROUPED_ILD_DIR"
  cp "$AGGREGATED_INVENTORY_DIR/$AGGREGATED_INVENTORY_PATH" "$GROUPED_LD_DIR"
  cp "$AGGREGATED_INVENTORY_DIR/$AGGREGATED_INVENTORY_PATH" "$GROUPED_SDA_DIR"
  cp "$ADVISED_INVENTORY_FILE" "$GROUPED_VR_DIR"
  cp "$ADVISED_INVENTORY_FILE" "$GROUPED_VSR_DIR"
}

create_software_distribution_annex() {
  OUTPUT_ANNEX_FILE="$REPORTED_DIR/software-distribution-annex-$ENV_LANGUAGE.pdf"
  OUTPUT_COMPUTED_INVENTORY_DIR="$ADDITIONAL_DIR/report"

  PARAM_DOCUMENT_TYPE="SDA"
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
  CMD+=("-Dinput.inventory.dir=$GROUPED_SDA_DIR")

  CMD+=("-Doutput.document.file=$OUTPUT_ANNEX_FILE")

  CMD+=("-Dparam.asset.descriptor.file=$ENV_SDA_DESCRIPTOR_FILE")
  CMD+=("-Dparam.reference.inventory.dir=$ENV_REFERENCE_INVENTORY_DIR")
  CMD+=("-Dparam.asset.id=$PARAM_ASSET_ID")
  CMD+=("-Dparam.asset.name=$PARAM_ASSET_NAME")
  CMD+=("-Dparam.asset.version=$PARAM_ASSET_VERSION")
  CMD+=("-Dparam.product.version=$PARAM_PRODUCT_VERSION")
  CMD+=("-Dparam.product.name=$PARAM_PRODUCT_NAME")
  CMD+=("-Dparam.product.watermark=$PARAM_PRODUCT_WATERMARK")
  CMD+=("-Dparam.document.type=$PARAM_DOCUMENT_TYPE")
  CMD+=("-Dparam.document.language=$ENV_LANGUAGE")
  CMD+=("-Dparam.overview.advisors=$PARAM_OVERVIEW_ADVISORS")
  CMD+=("-Dparam.property.selector.organization=metaeffekt")

  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")
  CMD+=("-Denv.workbench.dir=$WORKBENCH_DIR")
  CMD+=("-Denv.kontinuum.dir=$EXTERNAL_KONTINUUM_DIR")

  pass_command_info_to_logger "create_software_distribution_annex"
}

create_license_documentation() {
  OUTPUT_ANNEX_FILE="$REPORTED_DIR/license-documentation-$ENV_LANGUAGE.pdf"
  OUTPUT_COMPUTED_INVENTORY_DIR="$ADDITIONAL_DIR/report"

  PARAM_DOCUMENT_TYPE="LD"
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
  CMD+=("-Dinput.inventory.dir=$GROUPED_LD_DIR")

  CMD+=("-Doutput.document.file=$OUTPUT_ANNEX_FILE")

  CMD+=("-Dparam.asset.descriptor.file=$ENV_LD_DESCRIPTOR_FILE")
  CMD+=("-Dparam.reference.inventory.dir=$ENV_REFERENCE_INVENTORY_DIR")
  CMD+=("-Dparam.asset.id=$PARAM_ASSET_ID")
  CMD+=("-Dparam.asset.name=$PARAM_ASSET_NAME")
  CMD+=("-Dparam.asset.version=$PARAM_ASSET_VERSION")
  CMD+=("-Dparam.product.version=$PARAM_PRODUCT_VERSION")
  CMD+=("-Dparam.product.name=$PARAM_PRODUCT_NAME")
  CMD+=("-Dparam.product.watermark=$PARAM_PRODUCT_WATERMARK")
  CMD+=("-Dparam.document.type=$PARAM_DOCUMENT_TYPE")
  CMD+=("-Dparam.document.language=$ENV_LANGUAGE")
  CMD+=("-Dparam.overview.advisors=$PARAM_OVERVIEW_ADVISORS")
  CMD+=("-Dparam.property.selector.organization=metaeffekt")

  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")
  CMD+=("-Denv.workbench.dir=$WORKBENCH_DIR")
  CMD+=("-Denv.kontinuum.dir=$EXTERNAL_KONTINUUM_DIR")

  pass_command_info_to_logger "create_license_documentation"
}

create_initial_license_documentation() {
  OUTPUT_ANNEX_FILE="$REPORTED_DIR/initial-license-documentation-$ENV_LANGUAGE.pdf"
  OUTPUT_COMPUTED_INVENTORY_DIR="$ADDITIONAL_DIR/report"

  PARAM_DOCUMENT_TYPE="ILD"
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
  CMD+=("-Dinput.inventory.dir=$GROUPED_ILD_DIR")

  CMD+=("-Doutput.document.file=$OUTPUT_ANNEX_FILE")

  CMD+=("-Dparam.asset.descriptor.file=$ENV_ILD_DESCRIPTOR_FILE")
  CMD+=("-Dparam.reference.inventory.dir=$ENV_REFERENCE_INVENTORY_DIR")
  CMD+=("-Dparam.asset.id=$PARAM_ASSET_ID")
  CMD+=("-Dparam.asset.name=$PARAM_ASSET_NAME")
  CMD+=("-Dparam.asset.version=$PARAM_ASSET_VERSION")
  CMD+=("-Dparam.product.version=$PARAM_PRODUCT_VERSION")
  CMD+=("-Dparam.product.name=$PARAM_PRODUCT_NAME")
  CMD+=("-Dparam.product.watermark=$PARAM_PRODUCT_WATERMARK")
  CMD+=("-Dparam.document.type=$PARAM_DOCUMENT_TYPE")
  CMD+=("-Dparam.document.language=$ENV_LANGUAGE")
  CMD+=("-Dparam.overview.advisors=$PARAM_OVERVIEW_ADVISORS")
  CMD+=("-Dparam.property.selector.organization=metaeffekt")

  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")
  CMD+=("-Denv.workbench.dir=$WORKBENCH_DIR")
  CMD+=("-Denv.kontinuum.dir=$EXTERNAL_KONTINUUM_DIR")

  pass_command_info_to_logger "create_initial_license_documentation"
}

create_custom_annex_document() {
  OUTPUT_ANNEX_FILE="$REPORTED_DIR/custom-annex-document_$ENV_LANGUAGE.pdf"
  OUTPUT_COMPUTED_INVENTORY_DIR="$ADDITIONAL_DIR/report"

  PARAM_DOCUMENT_TYPE="CAD"
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
  CMD+=("-Dinput.inventory.dir=$GROUPED_CA_DIR")

  CMD+=("-Doutput.document.file=$OUTPUT_ANNEX_FILE")

  CMD+=("-Dparam.asset.descriptor.file=$ENV_CAD_DESCRIPTOR_FILE")
  CMD+=("-Dparam.reference.inventory.dir=$ENV_REFERENCE_INVENTORY_DIR")
  CMD+=("-Dparam.asset.id=$PARAM_ASSET_ID")
  CMD+=("-Dparam.asset.name=$PARAM_ASSET_NAME")
  CMD+=("-Dparam.asset.version=$PARAM_ASSET_VERSION")
  CMD+=("-Dparam.product.version=$PARAM_PRODUCT_VERSION")
  CMD+=("-Dparam.product.name=$PARAM_PRODUCT_NAME")
  CMD+=("-Dparam.product.watermark=$PARAM_PRODUCT_WATERMARK")
  CMD+=("-Dparam.document.type=$PARAM_DOCUMENT_TYPE")
  CMD+=("-Dparam.document.language=$ENV_LANGUAGE")
  CMD+=("-Dparam.overview.advisors=$PARAM_OVERVIEW_ADVISORS")
  CMD+=("-Dparam.property.selector.organization=metaeffekt")

  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")
  CMD+=("-Denv.workbench.dir=$WORKBENCH_DIR")
  CMD+=("-Denv.kontinuum.dir=$EXTERNAL_KONTINUUM_DIR")

  pass_command_info_to_logger "create_custom_annex"
}

create_vulnerability_summary_report() {
  OUTPUT_VSR_FILE="$REPORTED_DIR/vulnerability-summary-report-$ENV_LANGUAGE.pdf"
  OUTPUT_COMPUTED_INVENTORY_DIR="$ADDITIONAL_DIR/report"

  PARAM_DOCUMENT_TYPE="VSR"
  PARAM_ASSET_ID="Sample Product"
  PARAM_ASSET_NAME="SampleProduct"
  PARAM_ASSET_VERSION="1.0.0"
  PARAM_PRODUCT_NAME="Sample Product"
  PARAM_PRODUCT_VERSION="1.0.0"
  PARAM_PRODUCT_WATERMARK="Sample"

  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/report/report_create-document.xml" verify)
  CMD+=("-Dinput.inventory.dir=$GROUPED_VSR_DIR")

  CMD+=("-Doutput.document.file=$OUTPUT_VSR_FILE")

  CMD+=("-Dparam.asset.descriptor.file=$ENV_VSR_DESCRIPTOR_FILE")
  CMD+=("-Dparam.asset.id=$PARAM_ASSET_ID")
  CMD+=("-Dparam.asset.name=$PARAM_ASSET_NAME")
  CMD+=("-Dparam.asset.version=$PARAM_ASSET_VERSION")
  CMD+=("-Dparam.product.version=$PARAM_PRODUCT_VERSION")
  CMD+=("-Dparam.product.name=$PARAM_PRODUCT_NAME")
  CMD+=("-Dparam.product.watermark=$PARAM_PRODUCT_WATERMARK")
  CMD+=("-Dparam.document.type=$PARAM_DOCUMENT_TYPE")
  CMD+=("-Dparam.document.language=$ENV_LANGUAGE")
  CMD+=("-Dparam.property.selector.organization=metaeffekt")

  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")
  CMD+=("-Denv.workbench.dir=$WORKBENCH_DIR")
  CMD+=("-Denv.kontinuum.dir=$EXTERNAL_KONTINUUM_DIR")

  pass_command_info_to_logger "create_vulnerability-summary-report"
}

create_vulnerability_report() {
  OUTPUT_VR_FILE="$REPORTED_DIR/vulnerability-report-$ENV_LANGUAGE.pdf"
  OUTPUT_COMPUTED_INVENTORY_DIR="$ADDITIONAL_DIR/report"

  PARAM_DOCUMENT_TYPE="VR"
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
  CMD+=("-Dparam.document.language=$ENV_LANGUAGE")
  CMD+=("-Dparam.overview.advisors=$PARAM_OVERVIEW_ADVISORS")
  CMD+=("-Dparam.property.selector.organization=metaeffekt")

  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")
  CMD+=("-Denv.workbench.dir=$WORKBENCH_DIR")
  CMD+=("-Denv.kontinuum.dir=$EXTERNAL_KONTINUUM_DIR")

  pass_command_info_to_logger "create_vulnerability-report"
}

create_cert_report() {
  OUTPUT_CR_FILE="$REPORTED_DIR/cert-report-$ENV_LANGUAGE.pdf"
  OUTPUT_COMPUTED_INVENTORY_DIR="$ADDITIONAL_DIR/report"

  PARAM_DOCUMENT_TYPE="CR"
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
  CMD+=("-Dinput.inventory.dir=$GROUPED_CR_DIR")

  CMD+=("-Doutput.document.file=$OUTPUT_CR_FILE")

  CMD+=("-Dparam.asset.descriptor.file=$ENV_CR_DESCRIPTOR_FILE")
  CMD+=("-Dparam.asset.id=$PARAM_ASSET_ID")
  CMD+=("-Dparam.asset.name=$PARAM_ASSET_NAME")
  CMD+=("-Dparam.asset.version=$PARAM_ASSET_VERSION")
  CMD+=("-Dparam.product.version=$PARAM_PRODUCT_VERSION")
  CMD+=("-Dparam.product.name=$PARAM_PRODUCT_NAME")
  CMD+=("-Dparam.product.watermark=$PARAM_PRODUCT_WATERMARK")
  CMD+=("-Dparam.document.type=$PARAM_DOCUMENT_TYPE")
  CMD+=("-Dparam.document.language=$ENV_LANGUAGE")
  CMD+=("-Dparam.overview.advisors=$PARAM_OVERVIEW_ADVISORS")
  CMD+=("-Dparam.property.selector.organization=metaeffekt")

  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")
  CMD+=("-Denv.workbench.dir=$WORKBENCH_DIR")
  CMD+=("-Denv.kontinuum.dir=$EXTERNAL_KONTINUUM_DIR")

  pass_command_info_to_logger "create_cert_report"
}

create_vulnerability_assessment_dashboard() {
  OUTPUT_DASHBOARD_FILE="$ADVISED_DIR/dashboards/sample-product-dashboard.html"
  SECURITY_POLICY_ACTIVE_IDS="assessment_enrichment_configuration"

  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_create-dashboard.xml" process-resources)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  CMD+=("-Dinput.inventory.file=$ADVISED_INVENTORY_FILE")

  CMD+=("-Doutput.dashboard.file=$OUTPUT_DASHBOARD_FILE")

  CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
  CMD+=("-Dparam.security.policy.active.ids=$SECURITY_POLICY_ACTIVE_IDS")

  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")

  pass_command_info_to_logger "create_vulnerability_assessment_dashboard"
}

main() {
  source_preload
  set_global_variables

  # setup
  update_mirror

  # enrichment
  enrich_inventory_with_reference
  enrich_inventory

  # copy inventories to grouped
  copy_to_grouped

  # create annex documents
  create_software_distribution_annex
  create_license_documentation
  create_initial_license_documentation
  create_custom_annex_document

  # create vulnerability documents
  create_vulnerability_report
  create_vulnerability_summary_report
  create_cert_report

  # create dashboards
  create_vulnerability_assessment_dashboard
}

main "$@"