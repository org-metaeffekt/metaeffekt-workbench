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

PRELOAD_SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKBENCH_ROOT="$(cd "$PRELOAD_SELF_DIR/../.." && pwd)"
HARNESS_ROOT="$(cd "$PRELOAD_SELF_DIR/../../.." && pwd)"

load_properties() {
  local prop_file="$1"
  [ ! -f "$prop_file" ] && return 1

  while IFS= read -r line || [ -n "$line" ]; do
    # Remove carriage return characters
    line="${line//$'\r'/}"
    # Strip leading whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    # Strip trailing whitespace
    line="${line%"${line##*[![:space:]]}"}"

    # Skip comments and empty lines
    [[ -z "$line" || "$line" =~ ^[#!] ]] && continue

    # Parse key=val or key:val
    if [[ "$line" =~ ^([^=:]+)[=:](.*)$ ]]; then
      local key="${BASH_REMATCH[1]}"
      local val="${BASH_REMATCH[2]}"

      # Trim whitespace around key and value
      key="${key#"${key%%[![:space:]]*}"}"
      key="${key%"${key##*[![:space:]]}"}"
      val="${val#"${val%%[![:space:]]*}"}"
      val="${val%"${val##*[![:space:]]}"}"

      # Remove surrounding quotes if present
      if [[ "$val" =~ ^\"(.*)\"$ ]] || [[ "$val" =~ ^\'(.*)\'$ ]]; then
        val="${BASH_REMATCH[1]}"
      fi

      # Convert property key to uppercase variable name (dots and hyphens become underscores)
      local var_name
      var_name=$(echo "$key" | tr '[:lower:]' '[:upper:]' | tr '.-' '__')

      export "$var_name"="$val"
    fi
  done < "$prop_file"
}

# Resolve .project.properties (prefer local workbench file before encompassing harness file)
PROPERTIES_FILE=""
if [ -f "$WORKBENCH_ROOT/.project.properties" ]; then
  PROPERTIES_FILE="$WORKBENCH_ROOT/.project.properties"
elif [ -f "$HARNESS_ROOT/.project.properties" ]; then
  PROPERTIES_FILE="$HARNESS_ROOT/.project.properties"
fi

if [ -n "$PROPERTIES_FILE" ]; then
  load_properties "$PROPERTIES_FILE"
  echo "Successfully loaded .project.properties from $PROPERTIES_FILE"
else
  echo "Terminating: .project.properties file not found in metaeffekt-workbench or encompassing integration harness."
  exit 1
fi

if [ -f "$PRELOAD_SELF_DIR/log.sh" ]; then
  source "$PRELOAD_SELF_DIR/log.sh"
  echo "Successfully sourced log.sh file"
else
  echo "Terminating: log.sh not found in $PRELOAD_SELF_DIR"
  exit 1
fi

# Set aliases for Kontinuum directory
if [ -n "${AE_KONTINUUM_DIR:-}" ] && [ -z "${EXTERNAL_KONTINUUM_DIR:-}" ]; then
  EXTERNAL_KONTINUUM_DIR="$AE_KONTINUUM_DIR"
elif [ -n "${EXTERNAL_KONTINUUM_DIR:-}" ] && [ -z "${AE_KONTINUUM_DIR:-}" ]; then
  AE_KONTINUUM_DIR="$EXTERNAL_KONTINUUM_DIR"
fi
export EXTERNAL_KONTINUUM_DIR AE_KONTINUUM_DIR

# Set aliases for Vulnerability Mirror directory
if [ -n "${VULNERABILITY_MIRROR_DIR:-}" ] && [ -z "${EXTERNAL_VULNERABILITY_MIRROR_DIR:-}" ]; then
  EXTERNAL_VULNERABILITY_MIRROR_DIR="$VULNERABILITY_MIRROR_DIR"
elif [ -n "${EXTERNAL_VULNERABILITY_MIRROR_DIR:-}" ] && [ -z "${VULNERABILITY_MIRROR_DIR:-}" ]; then
  VULNERABILITY_MIRROR_DIR="$EXTERNAL_VULNERABILITY_MIRROR_DIR"
fi
export EXTERNAL_VULNERABILITY_MIRROR_DIR VULNERABILITY_MIRROR_DIR

# Set aliases for Vulnerability Mirror URL
if [ -n "${VULNERABILITY_MIRROR_URL:-}" ] && [ -z "${EXTERNAL_VULNERABILITY_MIRROR_URL:-}" ]; then
  EXTERNAL_VULNERABILITY_MIRROR_URL="$VULNERABILITY_MIRROR_URL"
elif [ -n "${EXTERNAL_VULNERABILITY_MIRROR_URL:-}" ] && [ -z "${VULNERABILITY_MIRROR_URL:-}" ]; then
  VULNERABILITY_MIRROR_URL="$EXTERNAL_VULNERABILITY_MIRROR_URL"
fi
export EXTERNAL_VULNERABILITY_MIRROR_URL VULNERABILITY_MIRROR_URL

# Validate required/recommended properties and log status
if [ -n "${EXTERNAL_KONTINUUM_DIR:-}" ]; then
  log_info "Found external kontinuum at $EXTERNAL_KONTINUUM_DIR"
else
  log_error "Terminating: ae.kontinuum.dir in .project.properties is not set."
  exit 1
fi

if [ -n "${EXTERNAL_VULNERABILITY_MIRROR_DIR:-}" ]; then
  log_info "Found external mirror at $EXTERNAL_VULNERABILITY_MIRROR_DIR"
else
  log_info "No vulnerability.mirror.dir specified in .project.properties, this might result in scripts failing."
fi

if [ -n "${EXTERNAL_VULNERABILITY_MIRROR_URL:-}" ]; then
  log_info "External mirror URL specified: $EXTERNAL_VULNERABILITY_MIRROR_URL"
else
  log_info "No vulnerability.mirror.url specified in .project.properties, this might result in scripts failing."
fi

if [ -n "${AE_CORE_VERSION:-}" ]; then
  log_info "Core version specified: $AE_CORE_VERSION"
else
  log_info "No ae.core.version specified in .project.properties file, using HEAD-SNAPSHOT."
  export AE_CORE_VERSION=HEAD-SNAPSHOT
fi

if [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ]; then
  log_info "Artifact analysis version specified: $AE_ARTIFACT_ANALYSIS_VERSION"
else
  log_info "No ae.artifact.analysis.version specified in .project.properties file, using HEAD-SNAPSHOT"
  export AE_ARTIFACT_ANALYSIS_VERSION=HEAD-SNAPSHOT
fi
