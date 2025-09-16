#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_PATH="$SCRIPT_DIR/../config.sh"
CASE="report_create-document-01.sh"

# Check if config.sh exists and source it
if [[ -f "$CONFIG_PATH" ]]; then
    source "$CONFIG_PATH"
else
    echo "Error: config.sh not found at $CONFIG_PATH" >&2
    exit 1
fi

# Run maven command
CMD=(mvn -f "$KONTINUUM_PROCESSORS_DIR/report/report_create-document.xml" verify)
CMD+=("-Dinput.inventory.file=$INPUT_INVENTORY_FILE")
CMD+=("-Dinput.reference.inventory.file=$INPUT_REFERENCE_INVENTORY_FILE")
CMD+=("-Dinput.reference.license.dir=$INPUT_REFERENCE_LICENSE_DIR")
CMD+=("-Dinput.reference.component.dir=$INPUT_REFERENCE_COMPONENT_DIR")
CMD+=("-Dinput.asset.descriptor.dir=$INPUT_ASSET_DESCRIPTOR_DIR")
CMD+=("-Dinput.asset.descriptor.path=$INPUT_ASSET_DESCRIPTOR_FILE")
CMD+=("-Dinput.security.policy.dir=$INPUT_SECURITY_POLICY_DIR")
CMD+=("-Doutput.document.file=$OUTPUT_DOCUMENT_FILE")
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

CMD+=("-Denv.vulnerability.mirror.dir=$ENV_VULNERABILITY_MIRROR_DIR")
CMD+=("-Denv.workbench.processors.dir=$PROCESSORS_DIR")
CMD+=("-Denv.kontinuum.processors.dir=$KONTINUUM_PROCESSORS_DIR")

echo "${CMD[@]}"
"${CMD[@]}"
