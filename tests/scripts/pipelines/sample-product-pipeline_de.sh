#!/bin/bash

# Exit on any error
set -euo pipefail

WORKBENCH_DIR="$(pwd)"
WORKSPACE_DIR="$WORKBENCH_DIR/tests/resources/workspace-001"
PROCESSORS_DIR="$WORKBENCH_DIR/processors"

if [ -f "$WORKBENCH_DIR/external-template.rc" ]; then
    source "$WORKBENCH_DIR/external-template.rc"
else
    echo "Missing external-template.rc file in root of repository."
    exit 1
fi

if [ -n "$EXTERNAL_KONTINUUM_DIR" ]; then
    KONTINUUM_PROCESSORS_DIR="$EXTERNAL_KONTINUUM_DIR/processors"
    echo "Found kontinuum repository at $EXTERNAL_KONTINUUM_DIR"
else
    echo "Could not find kontinuum repository at path specified in the external-template.rc file"
fi

# Define target directories
TARGET_BASE_DIR="$WORKSPACE_DIR/sample-product-1.0.0"
ANALYZED_DIR="$TARGET_BASE_DIR/02_analyzed"
CURATED_DIR="$TARGET_BASE_DIR/03_curated"
ADVISED_DIR="$TARGET_BASE_DIR/04_advised"
REPORTED_DIR="$TARGET_BASE_DIR/05_reported"
TMP_DIR="$TARGET_BASE_DIR/99_tmp"

ENV_REFERENCE_INVENTORY_DIR="$WORKBENCH_DIR/inventories/example-reference-inventory/inventory"
ENV_REFERENCE_LICENSES_DIR="$WORKBENCH_DIR/inventories/example-reference-inventory/licenses"
ENV_REFERENCE_COMPONENTS_DIR="$WORKBENCH_DIR/inventories/example-reference-inventory/components"
ENV_VULNERABILITY_MIRROR_BASE_DIR="$WORKBENCH_DIR/.vulnerability-mirror"
ENV_VULNERABILITY_MIRROR_DIR="$ENV_VULNERABILITY_MIRROR_BASE_DIR/.database"

ENV_REPORT_TEMPLATE_DIR="$WORKBENCH_DIR/templates/report-template"
ENV_SECURITY_POLICY_DIR="$WORKBENCH_DIR/policies"
ENV_SECURITY_POLICY_FILE="$WORKBENCH_DIR/policies/security-policy.json"

ENV_DESCRIPTOR_DIR="$WORKBENCH_DIR/descriptors"
ENV_SDA_DESCRIPTOR_PATH="asset-descriptor_GENERIC-software-distribution-annex.yaml"
ENV_VR_DESCRIPTOR_PATH="asset-descriptor_GENERIC-vulnerability-report.yaml"
ENV_CR_DESCRIPTOR_PATH="asset-descriptor_GENERIC-cert-report.yaml"

# Create all target directories
if ! mkdir -p "$ANALYZED_DIR" "$ADVISED_DIR" "$REPORTED_DIR" "$TMP_DIR" ; then
    echo "Error: Failed to create target directories" >&2
    exit 1
fi

###################################
# Ensure mirror is up-to-date     #
###################################
MIRROR_TARGET_DIR="$ENV_VULNERABILITY_MIRROR_BASE_DIR"
# NOTE: on 0.135 we need to use the legacy mirror
MIRROR_ARCHIVE_URL="http://ae-scanner/mirror/index/index-database_legacy.zip"
MIRROR_ARCHIVE_NAME="index-database_legacy.zip"
CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/util/util_update-mirror.xml" compile -P withoutProxy)
CMD+=("-Doutput.vulnerability.mirror.dir=$MIRROR_TARGET_DIR")
CMD+=("-Dparam.mirror.archive.url=$MIRROR_ARCHIVE_URL")
CMD+=("-Dparam.mirror.archive.name=$MIRROR_ARCHIVE_NAME")
echo "${CMD[@]}"
"${CMD[@]}"

###################################
# Enrich with reference inventory #
###################################
ANALYZED_INVENTORY_FILE="$ANALYZED_DIR/sample-asset-1.0/sample-asset-1.0-inventory.xls"
CURATED_INVENTORY_DIR="$CURATED_DIR/sample-asset-1.0"
CURATED_INVENTORY_PATH="sample-asset-1.0-inventory.xls"

CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_enrich-with-reference.xml" process-resources)
CMD+=("-Dinput.inventory.file=$ANALYZED_INVENTORY_FILE")
CMD+=("-Dinput.reference.inventory.dir=$ENV_REFERENCE_INVENTORY_DIR")
CMD+=("-Doutput.inventory.dir=$CURATED_INVENTORY_DIR")
CMD+=("-Doutput.inventory.path=$CURATED_INVENTORY_PATH")
echo "${CMD[@]}"
"${CMD[@]}"

#########################
# Create annex document #
#########################
OUTPUT_ANNEX_FILE="$REPORTED_DIR/software-distribution-annex.pdf"
OUTPUT_COMPUTED_INVENTORY_DIR="$TMP_DIR/report"

PARAM_DOCUMENT_TYPE="SDA"
PARAM_DOCUMENT_LANGUAGE="de"
PARAM_ASSET_ID="Sample Product"
PARAM_ASSET_NAME="SampleProduct"
PARAM_ASSET_VERSION="1.0.0"
PARAM_PRODUCT_NAME="Sample Product"
PARAM_PRODUCT_VERSION="1.0.0"
PARAM_PRODUCT_WATERMARK="Sample"
PARAM_OVERVIEW_ADVISORS="CERT_FR"

CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/report/report_create-document.xml" verify)
CMD+=("-Dinput.inventory.file=$CURATED_INVENTORY_DIR/$CURATED_INVENTORY_PATH")

CMD+=("-Dinput.reference.inventory.file=$ENV_REFERENCE_INVENTORY_DIR/artifact-inventory.xls")
CMD+=("-Dinput.reference.license.dir=$ENV_REFERENCE_LICENSES_DIR")
CMD+=("-Dinput.reference.component.dir=$ENV_REFERENCE_COMPONENTS_DIR")

CMD+=("-Dinput.asset.descriptor.dir=$ENV_DESCRIPTOR_DIR")
CMD+=("-Dinput.asset.descriptor.path=$ENV_SDA_DESCRIPTOR_PATH")

CMD+=("-Doutput.document.file=$OUTPUT_ANNEX_FILE")

CMD+=("-Dcomputed.inventory.path=$OUTPUT_COMPUTED_INVENTORY_DIR") # Do not change parameter name, needed by asset descriptor

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

CMD+=("-Denv.vulnerability.mirror.dir=$ENV_VULNERABILITY_MIRROR_DIR")
CMD+=("-Denv.workbench.processors.dir=$PROCESSORS_DIR")
CMD+=("-Denv.kontinuum.processors.dir=$KONTINUUM_PROCESSORS_DIR")

echo "${CMD[@]}"
"${CMD[@]}"

##########
# Advise #
##########
ADVISED_INVENTORY_FILE="$ADVISED_DIR/sample-product-asset-inventory.xlsx"
ASSESSMENT_DIR="$WORKBENCH_DIR/assessments/example-001"
CONTEXT_DIR="$WORKBENCH_DIR/contexts/example-001"
CORRELATION_DIR="$WORKBENCH_DIR/correlations/shared"
ADVISED_INVENTORY_FILE="$ADVISED_DIR/sample-product-advised-inventory.xlsx"
PROCESSOR_TMP_DIR="$TMP_DIR/processor"

CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_enrich-inventory.xml" process-resources)
CMD+=("-Dinput.inventory.file=$CURATED_INVENTORY_DIR/$CURATED_INVENTORY_PATH")
CMD+=("-Dinput.security.policy.file=$ENV_SECURITY_POLICY_FILE")

# these are params
CMD+=("-Dinput.assessment.dir=$ASSESSMENT_DIR")
CMD+=("-Dinput.correlation.dir=$CORRELATION_DIR")
CMD+=("-Dinput.context.dir=$CONTEXT_DIR")

# these are envs

CMD+=("-Doutput.inventory.file=$ADVISED_INVENTORY_FILE")
CMD+=("-Doutput.tmp.dir=$PROCESSOR_TMP_DIR")

CMD+=("-Denv.vulnerability.mirror.dir=$ENV_VULNERABILITY_MIRROR_DIR")

echo "${CMD[@]}"
"${CMD[@]}"


#################################
# Generate Vulnerability Report #
#################################
OUTPUT_VR_FILE="$REPORTED_DIR/vulnerability-report.pdf"
OUTPUT_COMPUTED_INVENTORY_DIR="$TMP_DIR/report"

PARAM_DOCUMENT_TYPE="VR"
PARAM_DOCUMENT_LANGUAGE="de"
PARAM_ASSET_ID="Sample Product"
PARAM_ASSET_NAME="SampleProduct"
PARAM_ASSET_VERSION="1.0.0"
PARAM_PRODUCT_NAME="Sample Product"
PARAM_PRODUCT_VERSION="1.0.0"
PARAM_PRODUCT_WATERMARK="Sample"
PARAM_OVERVIEW_ADVISORS="CERT_FR"

CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/report/report_create-document.xml" verify)
CMD+=("-Dinput.inventory.file=$ADVISED_INVENTORY_FILE")

CMD+=("-Dinput.reference.inventory.file=$ENV_REFERENCE_INVENTORY_DIR/artifact-inventory.xls")
CMD+=("-Dinput.reference.license.dir=$ENV_REFERENCE_LICENSES_DIR")
CMD+=("-Dinput.reference.component.dir=$ENV_REFERENCE_COMPONENTS_DIR")

CMD+=("-Dinput.asset.descriptor.dir=$ENV_DESCRIPTOR_DIR")
CMD+=("-Dinput.asset.descriptor.path=$ENV_VR_DESCRIPTOR_PATH")
CMD+=("-Dinput.security.policy.dir=$ENV_SECURITY_POLICY_DIR/vulnerability-report")

CMD+=("-Doutput.document.file=$OUTPUT_VR_FILE")

CMD+=("-Dcomputed.inventory.path=$OUTPUT_COMPUTED_INVENTORY_DIR") # Do not change parameter name, needed by asset descriptor

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

CMD+=("-Denv.vulnerability.mirror.dir=$ENV_VULNERABILITY_MIRROR_DIR")
CMD+=("-Denv.workbench.processors.dir=$PROCESSORS_DIR")
CMD+=("-Denv.kontinuum.processors.dir=$KONTINUUM_PROCESSORS_DIR")

echo "${CMD[@]}"
"${CMD[@]}"


#################################
# Generate Cert Report #
#################################
OUTPUT_CR_FILE="$REPORTED_DIR/cert-report.pdf"
OUTPUT_COMPUTED_INVENTORY_DIR="$TMP_DIR/report"

PARAM_DOCUMENT_TYPE="CR"
PARAM_DOCUMENT_LANGUAGE="de"
PARAM_ASSET_ID="Sample Product"
PARAM_ASSET_NAME="SampleProduct"
PARAM_ASSET_VERSION="1.0.0"
PARAM_PRODUCT_NAME="Sample Product"
PARAM_PRODUCT_VERSION="1.0.0"
PARAM_PRODUCT_WATERMARK="Sample"
PARAM_OVERVIEW_ADVISORS="CERT_FR"

CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/report/report_create-document.xml" verify)
CMD+=("-Dinput.inventory.file=$ADVISED_INVENTORY_FILE")

CMD+=("-Dinput.reference.inventory.file=$ENV_REFERENCE_INVENTORY_DIR/artifact-inventory.xls")
CMD+=("-Dinput.reference.license.dir=$ENV_REFERENCE_LICENSES_DIR")
CMD+=("-Dinput.reference.component.dir=$ENV_REFERENCE_COMPONENTS_DIR")

CMD+=("-Dinput.asset.descriptor.dir=$ENV_DESCRIPTOR_DIR")
CMD+=("-Dinput.asset.descriptor.path=$ENV_CR_DESCRIPTOR_PATH")
CMD+=("-Dinput.security.policy.dir=$ENV_SECURITY_POLICY_DIR/cert-report")

CMD+=("-Doutput.document.file=$OUTPUT_CR_FILE")

CMD+=("-Dcomputed.inventory.path=$OUTPUT_COMPUTED_INVENTORY_DIR") # Do not change parameter name, needed by asset descriptor

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

CMD+=("-Denv.vulnerability.mirror.dir=$ENV_VULNERABILITY_MIRROR_DIR")
CMD+=("-Denv.workbench.processors.dir=$PROCESSORS_DIR")
CMD+=("-Denv.kontinuum.processors.dir=$KONTINUUM_PROCESSORS_DIR")

echo "${CMD[@]}"
"${CMD[@]}"


################
# Generate VAD #
################
OUTPUT_DASHBOARD_FILE="$ADVISED_DIR/dashboards/sample-product-dashboard.html"
CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/advise/advise_create-dashboard.xml" process-resources)
CMD+=("-Dinput.inventory.file=$ADVISED_INVENTORY_FILE")
CMD+=("-Dinput.security.policy.file=$ENV_SECURITY_POLICY_FILE")
CMD+=("-Doutput.dashboard.file=$OUTPUT_DASHBOARD_FILE")
CMD+=("-Denv.vulnerability.mirror.dir=$ENV_VULNERABILITY_MIRROR_DIR")
echo "${CMD[@]}"
"${CMD[@]}"
