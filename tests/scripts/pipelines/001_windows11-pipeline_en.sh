#!/bin/bash

# Exit on any error
set -euo pipefail

readonly SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

readonly WORKBENCH_DIR="$(realpath "$SELF_DIR/../../..")"
readonly WORKSPACE_DIR="$WORKBENCH_DIR/tests/resources/workspace-001"
readonly PROCESSORS_DIR="$WORKBENCH_DIR/processors"
readonly KONTINUUM_PROCESSORS_DIR="$EXTERNAL_KONTINUUM_DIR/processors"

LOG_DIR="$WORKBENCH_DIR/.logs"
logger_init "$LOG_DIR/001_windows11-pipeline_en.sh"

readonly TARGET_BASE_DIR="$WORKSPACE_DIR/windows11"
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

log_info "Running update_mirror process."

MIRROR_TARGET_DIR="$EXTERNAL_VULNERABILITY_MIRROR_DIR"
MIRROR_ARCHIVE_URL="$EXTERNAL_VULNERABILITY_MIRROR_URL"
MIRROR_ARCHIVE_NAME="$EXTERNAL_VULNERABILITY_MIRROR_NAME"
CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/mirror/mirror_download-index.xml" compile)
[ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
[ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
CMD+=("-Denv.vulnerability.mirror.dir=$MIRROR_TARGET_DIR")
CMD+=("-Dparam.mirror.archive.url=$MIRROR_ARCHIVE_URL")
CMD+=("-Dparam.mirror.archive.name=$MIRROR_ARCHIVE_NAME")

pass_command_info_to_logger "update_mirror"


# PATCHED

log_info "Running enrich_inventory process."
ANALYZED_INVENTORY_FILE="$ANALYZED_DIR/windows11-inventory_patched.xlsx"
ASSESSMENT_DIR="$WORKBENCH_DIR/assessments/assessment-001/windows11"
CONTEXT_DIR="$WORKBENCH_DIR/contexts/example-001"
CORRELATION_DIR="$WORKBENCH_DIR/correlations/shared"
ADVISED_INVENTORY_FILE="$ADVISED_DIR/windows11-advised-inventory_patched.xlsx"
PROCESSOR_TMP_DIR="$TMP_DIR/processor"
DASHBOARD_SUBJECT="Windows 11"

## FIXME: consider template commands with ability to overwrite

CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_enrich-inventory.xml" process-resources)
[ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
[ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
CMD+=("-Dinput.inventory.file=$ANALYZED_INVENTORY_FILE")
CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
# FIXME-RTU: consider where to set these active Ids
CMD+=("-Doutput.inventory.file=$ADVISED_INVENTORY_FILE")
CMD+=("-Doutput.tmp.dir=$PROCESSOR_TMP_DIR")

CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
CMD+=("-Dparam.security.policy.active.ids=assessment_enrichment_configuration")
CMD+=("-Dparam.dashboard.title=Windows 11 Assessment")
CMD+=("-Dparam.dashboard.subtitle=")
CMD+=("-Dparam.dashboard.footer=Windows 11")

# these are params
CMD+=("-Dparam.assessment.dir=$ASSESSMENT_DIR")
CMD+=("-Dparam.correlation.dir=$CORRELATION_DIR")
CMD+=("-Dparam.context.dir=$CONTEXT_DIR")

CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")

pass_command_info_to_logger "advise_enrich-inventory"

log_info "Running generate_vulnerability_assessment_dashboard process."

OUTPUT_DASHBOARD_FILE="$ADVISED_DIR/dashboards/windows11-dashboard_patched.html"
CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_create-dashboard.xml" process-resources)
[ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
[ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
CMD+=("-Dinput.inventory.file=$ADVISED_INVENTORY_FILE")
CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
# FIXME-RTU: consider where to set these active Ids
CMD+=("-Dparam.security.policy.active.ids=assessment_enrichment_configuration")
CMD+=("-Doutput.dashboard.file=$OUTPUT_DASHBOARD_FILE")
CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")

pass_command_info_to_logger "generate_vulnerability_assessment_dashboard"


# UNPATCHED

log_info "Running enrich_inventory process."
ANALYZED_INVENTORY_FILE="$ANALYZED_DIR/windows11-inventory_unpatched.xlsx"
ASSESSMENT_DIR="$WORKBENCH_DIR/assessments/assessment-001/windows11"
CONTEXT_DIR="$WORKBENCH_DIR/contexts/example-001"
CORRELATION_DIR="$WORKBENCH_DIR/correlations/shared"
ADVISED_INVENTORY_FILE="$ADVISED_DIR/windows11-advised-inventory_unpatched.xlsx"
PROCESSOR_TMP_DIR="$TMP_DIR/processor"
DASHBOARD_SUBJECT="Windows 11"

## FIXME: consider template commands with ability to overwrite

CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_enrich-inventory.xml" process-resources)
[ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
[ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
CMD+=("-Dinput.inventory.file=$ANALYZED_INVENTORY_FILE")
CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
# FIXME-RTU: consider where to set these active Ids
CMD+=("-Doutput.inventory.file=$ADVISED_INVENTORY_FILE")
CMD+=("-Doutput.tmp.dir=$PROCESSOR_TMP_DIR")

CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
CMD+=("-Dparam.security.policy.active.ids=assessment_enrichment_configuration")
CMD+=("-Dparam.dashboard.title=Windows 11 Assessment")
CMD+=("-Dparam.dashboard.subtitle=")
CMD+=("-Dparam.dashboard.footer=Windows 11")

# these are params
CMD+=("-Dparam.assessment.dir=$ASSESSMENT_DIR")
CMD+=("-Dparam.correlation.dir=$CORRELATION_DIR")
CMD+=("-Dparam.context.dir=$CONTEXT_DIR")

CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")

pass_command_info_to_logger "advise_enrich-inventory"

log_info "Running generate_vulnerability_assessment_dashboard process."

OUTPUT_DASHBOARD_FILE="$ADVISED_DIR/dashboards/windows11-dashboard_unpatched.html"
CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_create-dashboard.xml" process-resources)
[ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
[ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
CMD+=("-Dinput.inventory.file=$ADVISED_INVENTORY_FILE")
CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
# FIXME-RTU: consider where to set these active Ids
CMD+=("-Dparam.security.policy.active.ids=assessment_enrichment_configuration")
CMD+=("-Doutput.dashboard.file=$OUTPUT_DASHBOARD_FILE")
CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")

pass_command_info_to_logger "windows11-dashboard_unpatched"
