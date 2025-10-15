#!/bin/bash

# Exit on any error
set -euo pipefail

readonly SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SELF_DIR/../preload.sh" ];then
  source "$SELF_DIR/../preload.sh"
  echo "Successfully sourced preload.sh file"
else
  echo "Terminating: preload.sh script not found."
  exit 1
fi

readonly WORKBENCH_DIR="$(realpath "$SELF_DIR/../../..")"
readonly WORKSPACE_DIR="$WORKBENCH_DIR/tests/resources/workspace-001"
readonly PROCESSORS_DIR="$WORKBENCH_DIR/processors"
readonly KONTINUUM_PROCESSORS_DIR="$EXTERNAL_KONTINUUM_DIR/processors"

LOG_DIR="$WORKBENCH_DIR/.logs"
LOG_LEVEL="ALL"

readonly TARGET_BASE_DIR="$WORKSPACE_DIR/openssl-3.3.1"
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

if ! mkdir -p "$ANALYZED_DIR" "$ADVISED_DIR" "$REPORTED_DIR" "$TMP_DIR" ; then
    log_error "Failed to create target directories"
    exit 1
fi

log_info "Running enrich_inventory process."

ANALYZED_INVENTORY_FILE="$ANALYZED_DIR/openssl-inventory.xls"
ASSESSMENT_DIR="$WORKBENCH_DIR/assessments/assessment-001/openssl"
CONTEXT_DIR="$WORKBENCH_DIR/contexts/example-001"
CORRELATION_DIR="$WORKBENCH_DIR/correlations/shared"
ADVISED_INVENTORY_FILE="$ADVISED_DIR/openssl-advised-inventory.xlsx"
PROCESSOR_TMP_DIR="$TMP_DIR/processor"
DASHBOARD_SUBJECT="OpenSSL 3.3.1"

CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_enrich-inventory.xml" process-resources)
CMD+=("-Dinput.inventory.file=$ANALYZED_INVENTORY_FILE")
CMD+=("-Doutput.inventory.file=$ADVISED_INVENTORY_FILE")
CMD+=("-Doutput.tmp.dir=$PROCESSOR_TMP_DIR")

CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
CMD+=("-Dparam.security.policy.active.ids=assessment_enrichment_configuration")
CMD+=("-Dparam.dashboard.title=OpenSSL 3.3.1 Assessment")
CMD+=("-Dparam.dashboard.subtitle=")
CMD+=("-Dparam.dashboard.footer=OpenSSL 3.3.1")
CMD+=("-Dparam.assessment.dir=$ASSESSMENT_DIR")
CMD+=("-Dparam.correlation.dir=$CORRELATION_DIR")
CMD+=("-Dparam.context.dir=$CONTEXT_DIR")

CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")

log_mvn "${CMD[*]}"

if "${CMD[@]}" 2>&1 | while IFS= read -r line; do log_mvn "$line"; done; then
    log_info "Successfully ran enrich_inventory"
else
    log_error "Failed to run enrich_inventory because the maven execution was unsuccessful"
fi

log_info "Running generate_vulnerability_assessment_dashboard process."

OUTPUT_DASHBOARD_FILE="$ADVISED_DIR/dashboards/openssl-3.3.1-dashboard.html"
CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_create-dashboard.xml" process-resources)
CMD+=("-Dinput.inventory.file=$ADVISED_INVENTORY_FILE")
CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
# FIXME-RTU: consider where to set these active Ids
CMD+=("-Dparam.security.policy.active.ids=assessment_enrichment_configuration")
CMD+=("-Doutput.dashboard.file=$OUTPUT_DASHBOARD_FILE")
CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")

log_config "input.inventory.file=$ADVISED_INVENTORY_FILE
            param.security.policy.file=$PARAM_SECURITY_POLICY_FILE" "
            output.dashboard.file=$OUTPUT_DASHBOARD_FILE"

log_mvn "${CMD[*]}"

if "${CMD[@]}" 2>&1 | while IFS= read -r line; do log_mvn "$line"; done; then
    log_info "Successfully ran generate_vulnerability_assessment_dashboard"
else
    log_error "Failed to run generate_vulnerability_assessment_dashboard because the maven execution was unsuccessful"
    exit 1
fi


# produce vulnerability report
OUTPUT_VR_FILE="$REPORTED_DIR/openssl-vulnerability-report-de.pdf"
OUTPUT_COMPUTED_INVENTORY_DIR="$TMP_DIR/report"

PARAM_DOCUMENT_TYPE="VR"
PARAM_DOCUMENT_LANGUAGE="en"
PARAM_ASSET_ID="OpenSSL"
PARAM_ASSET_NAME="OpenSSL"
PARAM_ASSET_VERSION="3.3.1"
PARAM_PRODUCT_NAME="OpenSSL"
PARAM_PRODUCT_VERSION="3.3.1"
PARAM_PRODUCT_WATERMARK="OpenSSL"
PARAM_OVERVIEW_ADVISORS="CERT_FR"

CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/report/report_create-document.xml" verify)
CMD+=("-Dinput.inventory.file=$ADVISED_INVENTORY_FILE")

CMD+=("-Dinput.reference.inventory.file=$ENV_REFERENCE_INVENTORY_DIR/artifact-inventory.xls")
CMD+=("-Dinput.reference.license.dir=$ENV_REFERENCE_LICENSES_DIR")
CMD+=("-Dinput.reference.component.dir=$ENV_REFERENCE_COMPONENTS_DIR")

CMD+=("-Dinput.asset.descriptor.dir=$ENV_DESCRIPTOR_DIR")
CMD+=("-Dinput.asset.descriptor.path=$ENV_VR_DESCRIPTOR_PATH")
CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")

CMD+=("-Doutput.document.file=$OUTPUT_VR_FILE")

CMD+=("-Doutput.computed.inventory.path=$OUTPUT_COMPUTED_INVENTORY_DIR") # Do not change parameter name, needed by asset descriptor

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

CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")

CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")
CMD+=("-Denv.workbench.processors.dir=$PROCESSORS_DIR")
CMD+=("-Denv.kontinuum.processors.dir=$KONTINUUM_PROCESSORS_DIR")

log_config "input.inventory.file=$ADVISED_INVENTORY_FILE
            input.reference.inventory.file=$ENV_REFERENCE_INVENTORY_DIR/artifact-inventory.xls
            input.reference.license.dir=$ENV_REFERENCE_LICENSES_DIR
            input.reference.component.dir=$ENV_REFERENCE_COMPONENTS_DIR
            input.asset.descriptor.dir=$ENV_DESCRIPTOR_DIR
            input.asset.descriptor.path=$ENV_VR_DESCRIPTOR_PATH" "
            output.document.file=$OUTPUT_VR_FILE
            output.computed.inventory.path=$OUTPUT_COMPUTED_INVENTORY_DIR"

log_mvn "${CMD[*]}"

if "${CMD[@]}" 2>&1 | while IFS= read -r line; do log_mvn "$line"; done; then
    log_info "Successfully ran generate_vulnerability_report"
else
    log_error "Failed to run generate_vulnerability_report"
    exit 1
fi
