#!/bin/bash

# === Input / Output ===
INPUT_ASSET_DESCRIPTOR_DIR="$WORKBENCH_DIR/descriptors"
INPUT_ASSET_DESCRIPTOR_PATH="asset-descriptor_GENERIC-cert-report.yaml"
INPUT_INVENTORY_FILE="$RESOURCES_DIR/report/sample-product-advised-inventory.xlsx"

# NOTE: the policy dir depends on the document type (for now)
INPUT_SECURITY_POLICY_DIR="$WORKBENCH_DIR/policies/cert-report"

OUTPUT_DOCUMENT_FILE="$REPORTED_DIR/my-doc.pdf"
OUTPUT_COMPUTED_INVENTORY_DIR="$REPORTED_DIR/computed"

# FIXME: rename to either ENV_ or PARAM_
INPUT_REFERENCE_INVENTORY_FILE="$WORKBENCH_DIR/inventories/example-reference-inventory/inventory/artifact-inventory.xls"
INPUT_REFERENCE_LICENSE_DIR="$WORKBENCH_DIR/inventories/example-reference-inventory/licenses"
INPUT_REFERENCE_COMPONENT_DIR="$WORKBENCH_DIR/inventories/example-reference-inventory/components"

# === Parameters ===
PARAM_DOCUMENT_TYPE="CR"
PARAM_DOCUMENT_LANGUAGE="de"
PARAM_ASSET_ID="testAssetId"
PARAM_ASSET_NAME="testAssetName"
PARAM_ASSET_VERSION="1.0.0"
PARAM_PRODUCT_NAME="testProductName"
PARAM_PRODUCT_VERSION="1.0.0"
PARAM_PRODUCT_WATERMARK=""
PARAM_OVERVIEW_ADVISORS="CERT_FR"
PARAM_PROPERTY_SELECTOR_ORGANIZATION="metaeffekt"

# === Environment ===
ENV_WORKBENCH_BASE_DIR=$WORKBENCH_DIR
ENV_REPORT_TEMPLATE_DIR="$WORKBENCH_DIR/templates/report-template"

# FIXME: reuse the vulnerability mirror on workspace-independent-level; differentiate gen3 and gen4 mirror
ENV_VULNERABILITY_MIRROR_DIR="$EXTERNAL_VULNERABILITY_MIRROR_DIR/.database"
