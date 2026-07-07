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
  readonly WORKSPACE_DIR="$WORKBENCH_DIR/tests/resources/workspace-003/inventory-index"
  readonly PROCESSORS_DIR="$WORKBENCH_DIR/processors"
  readonly KONTINUUM_PROCESSORS_DIR="$EXTERNAL_KONTINUUM_DIR/processors"

  readonly INVENTORY_INDEX_ID=inventory-index
  readonly INVENTORY_INDEX_NAME=Inventory Index
  readonly INVENTORY_INDEX_VERSION=HEAD-SNAPSHOT

  LOG_DIR="$WORKBENCH_DIR/.logs"
  logger_init "$LOG_DIR/$INVENTORY_INDEX_ID-pipeline_en.log"

  ENV_REFERENCE_INVENTORY_DIR="$WORKBENCH_DIR/inventories/example-reference-inventory/inventory"

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

  TENANT_ID="metaeffekt"
  PROJECT_ID=$INVENTORY_INDEX_ID
}

prepare_workspace() {
  echo Prepare
  # THESE should be created implicitly; trying to life without
  #  create_workspace_variables "$WORKSPACE_DIR/$INVENTORY_INDEX_ID" "setup"
  #  create_workspace_variables "$WORKSPACE_DIR/$INVENTORY_INDEX_ID" "ae-inventory-importer"
  #  create_workspace_variables "$WORKSPACE_DIR/$INVENTORY_INDEX_ID" "ae-inventory-query-service"
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

# $1: input dir
# $2: scan dir
# $3: output inventory
extractInventoryFromAsset() {
  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/prepare/prepare_scan-directory.xml" process-resources)
  [ "${DEBUG:-}" = "true" ] && CMD+=("-X")
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  [ -n "${LOCAL_MAVEN_REPO:-}" ] && CMD+=("-Dmaven.repo.local=$LOCAL_MAVEN_REPO")
  CMD+=("-Dparam.reference.inventory.dir=$ENV_REFERENCE_INVENTORY_DIR")
  CMD+=("-Dinput.extract.dir=$1")
  CMD+=("-Doutput.scan.dir=$2")
  CMD+=("-Doutput.inventory.file=$3")
  CMD+=("-X")

  pass_command_info_to_logger "extract"
}

# $1: input inventory dir
# $2: output inventory dir
# $3: transform script
prepareInventories() {
  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/util/util_transform-inventories.xml" process-resources)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  CMD+=("-Dinput.inventory.dir=$1")
  CMD+=("-Doutput.inventory.dir=$2")
  CMD+=("-Dparam.kotlin.script.file=$3")

  pass_command_info_to_logger "prepare"
}

# $1: input inventory file
# $2: output inventory file
# $3: tmp dir
# $4: asset id (may include major version)
# $5: assessment context (default)
enrichInventory() {
  ASSESSMENT_DIR="$WORKBENCH_DIR/assessments/$TENANT_ID/$PROJECT_ID/$4/$5/assessments"
  CONTEXT_DIR="$WORKBENCH_DIR/assessments/$TENANT_ID/$PROJECT_ID/$4/$5/context"
  CORRELATION_DIR="$WORKBENCH_DIR/correlations/shared"
  SECURITY_POLICY_ACTIVE_IDS="assessment_enrichment_configuration"
  ACTIVATE_MSRC="false"

  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_enrich-inventory.xml" process-resources)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  CMD+=("-Dinput.inventory.file=$1")

  CMD+=("-Doutput.inventory.file=$2")
  CMD+=("-Doutput.tmp.dir=$3")

  CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
  CMD+=("-Dparam.security.policy.active.ids=$SECURITY_POLICY_ACTIVE_IDS")
  CMD+=("-Dparam.assessment.dirs=$ASSESSMENT_DIR")
  CMD+=("-Dparam.correlation.dir=$CORRELATION_DIR")
  CMD+=("-Dparam.context.dirs=$CONTEXT_DIR")
  CMD+=("-Dparam.activate.msrc=$ACTIVATE_MSRC")

  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")

  pass_command_info_to_logger "enrich_inventory"
}

# $1: input inventory file
# $2: output dashboard file
# $3: asset id
# $3: assessment context
createVulnerabilityAssessmentDashboard() {
  SECURITY_POLICY_ACTIVE_IDS="assessment_enrichment_configuration"

  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_create-dashboard.xml" process-resources)
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  CMD+=("-Dinput.inventory.file=$1")

  CMD+=("-Doutput.dashboard.file=$2")

  CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")
  CMD+=("-Dparam.security.policy.active.ids=$SECURITY_POLICY_ACTIVE_IDS")
  CMD+=("-Dparam.tenant.id=$TENANT_ID")
  CMD+=("-Dparam.asset.id=$3")
  CMD+=("-Dparam.assessment.context=$4")

  CMD+=("-Denv.vulnerability.mirror.dir=$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database")

  pass_command_info_to_logger "create_vulnerability_assessment_dashboard"
}

# $1: input inventory
# $2: asset id
# $3: asset name
# $4: asset version
# $5: asset path
# $6: asset type
attachAssetMetadata() {
  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_attach-metadata.xml" process-resources)
  [ "${DEBUG:-}" = "true" ] && CMD+=("-X")
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  [ -n "${LOCAL_MAVEN_REPO:-}" ] && CMD+=("-Dmaven.repo.local=$LOCAL_MAVEN_REPO")
  CMD+=("-Dinput.inventory.file=$1")
  CMD+=("-Doutput.inventory.file=$1")
  CMD+=("-Dparam.metadata.asset.id=$2")
  CMD+=("-Dparam.metadata.asset.name=$3")
  CMD+=("-Dparam.metadata.asset.version=$4")
  CMD+=("-Dparam.metadata.asset.path=$5")
  CMD+=("-Dparam.metadata.asset.type=$6")

  pass_command_info_to_logger "attach-metadata"
}


# $1: inventory dir
# $2: inventory path ???
# $3: advisor dirs
# $4: dashboard dirs
# $5: reports dir
# $6: output html file
createOverview() {
  CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/portfolio/portfolio_create-overview.xml" process-resources -X)
  [ "${DEBUG:-}" = "true" ] && CMD+=("-X")
  [ -n "${AE_CORE_VERSION:-}" ] && CMD+=("-Dae.core.version=$AE_CORE_VERSION")
  [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ] && CMD+=("-Dae.artifact.analysis.version=$AE_ARTIFACT_ANALYSIS_VERSION")
  [ -n "${LOCAL_MAVEN_REPO:-}" ] && CMD+=("-Dmaven.repo.local=$LOCAL_MAVEN_REPO")
  CMD+=("-Dinput.inventory.dir=$1")
  CMD+=("-Dinput.inventory.path=$2")
  CMD+=("-Dinput.advisor.inventories.dir=$3")
  CMD+=("-Dinput.dashboards.dir=$4")
  CMD+=("-Dinput.reports.dir=$5")
  CMD+=("-Doutput.overview.file=$6")
  CMD+=("-Dparam.security.policy.file=$PARAM_SECURITY_POLICY_FILE")

  pass_command_info_to_logger "create_overview"
}

main() {
  source_preload
  set_global_variables

  # setup
  update_mirror

  # fetch
  rm -rf $WORKSPACE_DIR/00_fetched/ae-inventory-index-setup
  mkdir -p $WORKSPACE_DIR/00_fetched/ae-inventory-index-setup
  curl -O -J --output-dir $WORKSPACE_DIR/00_fetched/ae-inventory-index-setup http://ae-scanner/repository/org/metaeffekt/inventory-index/inventory-index-deployment-HEAD-SNAPSHOT.zip

  rm -rf $WORKSPACE_DIR/00_fetched/ae-inventory-importer-service
  mkdir -p $WORKSPACE_DIR/00_fetched/ae-inventory-importer-service
  curl -O -J --output-dir $WORKSPACE_DIR/00_fetched/ae-inventory-importer-service http://ae-scanner/repository/org/metaeffekt/inventory-index/ae-inventory-importer-service-HEAD-SNAPSHOT-exec.jar

  rm -rf $WORKSPACE_DIR/00_fetched/ae-inventory-query-service
  mkdir -p $WORKSPACE_DIR/00_fetched/ae-inventory-query-service
  curl -O -J --output-dir $WORKSPACE_DIR/00_fetched/ae-inventory-query-service http://ae-scanner/repository/org/metaeffekt/inventory-index/ae-inventory-query-service-HEAD-SNAPSHOT-exec.jar


  # extract
  extractInventoryFromAsset $WORKSPACE_DIR/00_fetched/ae-inventory-index-setup $WORKSPACE_DIR/01_extracted/scan_setup $WORKSPACE_DIR/01_extracted/ae-inventory-index-setup-inventory-$INVENTORY_INDEX_VERSION.xlsx
  extractInventoryFromAsset $WORKSPACE_DIR/00_fetched/ae-inventory-importer-service $WORKSPACE_DIR/01_extracted/scan_ae-inventory-importer-service $WORKSPACE_DIR/01_extracted/ae-inventory-importer-service-inventory-$INVENTORY_INDEX_VERSION.xlsx
  extractInventoryFromAsset $WORKSPACE_DIR/00_fetched/ae-inventory-query-service $WORKSPACE_DIR/01_extracted/scan_ae-inventory-query-service $WORKSPACE_DIR/01_extracted/ae-inventory-query-service-inventory-$INVENTORY_INDEX_VERSION.xlsx

  attachAssetMetadata $WORKSPACE_DIR/01_extracted/ae-inventory-index-setup-inventory-$INVENTORY_INDEX_VERSION.xlsx ii-setup "Inventory Index - Setup" "$INVENTORY_INDEX_VERSION" "" ""
  attachAssetMetadata $WORKSPACE_DIR/01_extracted/ae-inventory-importer-service-inventory-$INVENTORY_INDEX_VERSION.xlsx ii-importer "Inventory Index - Importer" "$INVENTORY_INDEX_VERSION" "" ""
  attachAssetMetadata $WORKSPACE_DIR/01_extracted/ae-inventory-query-service-inventory-$INVENTORY_INDEX_VERSION.xlsx ii-query-service "Inventory Index - Query Service" "$INVENTORY_INDEX_VERSION" "" ""

  prepareInventories $WORKSPACE_DIR/01_extracted/ae-inventory-index-setup-inventory-$INVENTORY_INDEX_VERSION.xlsx $WORKSPACE_DIR/02_prepared/ae-inventory-index-setup-inventory-$INVENTORY_INDEX_VERSION.xlsx $WORKBENCH_DIR/scripts/prepare.kts
  prepareInventories $WORKSPACE_DIR/01_extracted/ae-inventory-query-service-inventory-$INVENTORY_INDEX_VERSION.xlsx $WORKSPACE_DIR/02_prepared/ae-inventory-query-service-inventory-$INVENTORY_INDEX_VERSION.xlsx $WORKBENCH_DIR/scripts/prepare.kts
  prepareInventories $WORKSPACE_DIR/01_extracted/ae-inventory-importer-service-inventory-$INVENTORY_INDEX_VERSION.xlsx $WORKSPACE_DIR/02_prepared/ae-inventory-importer-service-inventory-$INVENTORY_INDEX_VERSION.xlsx $WORKBENCH_DIR/scripts/prepare.kts

  enrichInventory \
    $WORKSPACE_DIR/02_prepared/ae-inventory-index-setup-inventory-$INVENTORY_INDEX_VERSION.xlsx \
    $WORKSPACE_DIR/04_advised/ae-inventory-index-setup-advised-inventory-$INVENTORY_INDEX_VERSION.xlsx \
    $WORKSPACE_DIR/04_advised/tmp \
    ii-setup \
    default

  enrichInventory  \
    $WORKSPACE_DIR/02_prepared/ae-inventory-query-service-inventory-$INVENTORY_INDEX_VERSION.xlsx  \
    $WORKSPACE_DIR/04_advised/ae-inventory-query-service-advised-inventory-$INVENTORY_INDEX_VERSION.xlsx \
    $WORKSPACE_DIR/04_advised/tmp \
    ii-query-service \
    default

  enrichInventory  \
    $WORKSPACE_DIR/02_prepared/ae-inventory-importer-service-inventory-$INVENTORY_INDEX_VERSION.xlsx  \
    $WORKSPACE_DIR/04_advised/ae-inventory-importer-service-advised-inventory-$INVENTORY_INDEX_VERSION.xlsx \
    $WORKSPACE_DIR/04_advised/tmp \
    ii-importer-service \
    default

  createVulnerabilityAssessmentDashboard \
    $WORKSPACE_DIR/04_advised/ae-inventory-index-setup-advised-inventory-$INVENTORY_INDEX_VERSION.xlsx \
    $WORKSPACE_DIR/04_advised/ae-inventory-index-setup-advised-inventory-$INVENTORY_INDEX_VERSION.html \
    ii-setup \
    default

  createVulnerabilityAssessmentDashboard \
    $WORKSPACE_DIR/04_advised/ae-inventory-query-service-advised-inventory-$INVENTORY_INDEX_VERSION.xlsx \
    $WORKSPACE_DIR/04_advised/ae-inventory-query-service-advised-inventory-$INVENTORY_INDEX_VERSION.html  \
    ii-query-service \
    default

  createVulnerabilityAssessmentDashboard \
    $WORKSPACE_DIR/04_advised/ae-inventory-importer-service-advised-inventory-$INVENTORY_INDEX_VERSION.xlsx \
    $WORKSPACE_DIR/04_advised/ae-inventory-importer-service-advised-inventory-$INVENTORY_INDEX_VERSION.html \
    ii-importer-service \
    default

  # TODO: consider how this is done in a more aligned fashion; the target folders may be combined from different sources
  rm -rf $WORKSPACE_DIR/08_summarized
  mkdir -p $WORKSPACE_DIR/08_summarized
  mkdir -p $WORKSPACE_DIR/08_summarized/01_input
  mkdir -p $WORKSPACE_DIR/08_summarized/02_advised
  mkdir -p $WORKSPACE_DIR/08_summarized/03_dashboards
  cp $WORKSPACE_DIR/02_prepared/ae-*.xlsx $WORKSPACE_DIR/08_summarized/01_input
  cp $WORKSPACE_DIR/04_advised/ae-*.xlsx $WORKSPACE_DIR/08_summarized/02_advised
  cp $WORKSPACE_DIR/04_advised/ae-*.html $WORKSPACE_DIR/08_summarized/03_dashboards
#  cp $WORKSPACE_DIR/05_reported/ae-*.html $WORKSPACE_DIR/08_summarized/04_reports

  createOverview $WORKSPACE_DIR/08_summarized 01_input 02_advised 03_dashboards 04_reports $WORKSPACE_DIR/08_summarized/overview.html
}

main "$@"
