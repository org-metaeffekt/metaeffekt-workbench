#!/bin/bash

# === Input / Output ===
export INPUT_ASSET_DESCRIPTOR_DIR="$WORKBENCH_DIR/descriptors"
export INPUT_ASSET_DESCRIPTOR_FILE="asset-descriptor_GENERIC-cert-report.yaml"
export INPUT_INVENTORY_FILE="$RESOURCES_DIR/report/sample-product-advised-inventory.xlsx"

# NOTE: the policy dir depends on the document type (for now)
export INPUT_SECURITY_POLICY_DIR="$WORKBENCH_DIR/policies/cert-report"

export OUTPUT_DOCUMENT_FILE="$REPORTED_DIR/my-doc.pdf"
export OUTPUT_COMPUTED_INVENTORY_DIR="$REPORTED_DIR/computed/"

# FIXME: rename to either ENV_ or PARAM_
export INPUT_REFERENCE_INVENTORY_FILE="$WORKBENCH_DIR/inventories/example-reference-inventory/inventory/artifact-inventory.xls"
export INPUT_REFERENCE_LICENSE_DIR="$WORKBENCH_DIR/inventories/example-reference-inventory/licenses"
export INPUT_REFERENCE_COMPONENT_DIR="$WORKBENCH_DIR/inventories/example-reference-inventory/components"

# === Parameters ===
export PARAM_DOCUMENT_TYPE="CR"
export PARAM_DOCUMENT_LANGUAGE="de"
export PARAM_ASSET_ID="testAssetId"
export PARAM_ASSET_NAME="testAssetName"
export PARAM_ASSET_VERSION="1.0.0"
export PARAM_PRODUCT_NAME="testProductName"
export PARAM_PRODUCT_VERSION="1.0.0"
export PARAM_PRODUCT_WATERMARK=""
export PARAM_OVERVIEW_ADVISORS="CERT_FR"

# === Environment ===
export ENV_WORKBENCH_BASE_DIR=$WORKBENCH_DIR
export ENV_REPORT_TEMPLATE_DIR="$WORKBENCH_DIR/templates/report-template"

# FIXME: reuse the vulnerability mirror on workspace-independent-level; differentiate gen3 and gen4 mirror
export ENV_VULNERABILITY_MIRROR_DIR=$(realpath "$WORKBENCH_DIR/tests/resources/workspace-001/.vulnerability-mirror/.database")
