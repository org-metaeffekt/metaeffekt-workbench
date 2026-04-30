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

set -euo pipefail

readonly SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SELF_DIR/001_cisco-catalyst-sd-wan-manager-pipeline_en.sh"
bash "$SELF_DIR/001_crypto-bom-pipeline_en.sh"
bash "$SELF_DIR/001_keycloak-pipeline_en.sh"
bash "$SELF_DIR/001_mongodb-pipeline_en.sh"
bash "$SELF_DIR/001_openssl-pipeline_en.sh"
bash "$SELF_DIR/001_react-pipeline_en.sh"
bash "$SELF_DIR/002_sample-product-pipeline_de.sh"
bash "$SELF_DIR/002_sample-product-pipeline_en.sh"
bash "$SELF_DIR/001_windows11-pipeline_en.sh"
