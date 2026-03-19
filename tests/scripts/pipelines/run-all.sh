#!/bin/bash

set -euo pipefail

readonly SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SELF_DIR/cisco-catalyst-sd-wan-manager-pipeline_en.sh"
bash "$SELF_DIR/keycloak-pipeline_en.sh"
bash "$SELF_DIR/mongodb-pipeline_en.sh"
bash "$SELF_DIR/openssl-pipeline_en.sh"
bash "$SELF_DIR/react-pipeline_en.sh"
bash "$SELF_DIR/sample-product-pipeline_de.sh"
bash "$SELF_DIR/sample-product-pipeline_en.sh"
bash "$SELF_DIR/windows11-pipeline_en.sh"
