#!/bin/bash

PRELOAD_SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$PRELOAD_SELF_DIR/../../external.rc" ];then
  source "$PRELOAD_SELF_DIR/../../external.rc"
  echo "Successfully sourced external.rc file"
else
  echo "Terminating: external.rc file not found in root of repository."
  exit 1
fi

if [ -n "${EXTERNAL_KONTINUUM_DIR:-}" ]; then
    if [ -f "$EXTERNAL_KONTINUUM_DIR/tests/scripts/processors/log.sh" ]; then
      source "$EXTERNAL_KONTINUUM_DIR/tests/scripts/processors/log.sh"
      echo "Successfully sourced log.sh file"
    else
      echo "Terminating: log.sh not found in $EXTERNAL_KONTINUUM_DIR/tests/scripts/processors/"
      exit 1
    fi
else
  echo "Terminating: EXTERNAL_KONTINUUM_DIR in external.rc is not set."
  exit 1
fi

if [ -n "${EXTERNAL_VULNERABILITY_MIRROR_DIR:-}" ]; then
  log_info "Found external mirror at $EXTERNAL_VULNERABILITY_MIRROR_DIR"
else
  log_info "No EXTERNAL_VULNERABILITY_MIRROR_DIR specified in external.rc, this might result in scripts failing."
fi


if [ -n "${EXTERNAL_VULNERABILITY_MIRROR_URL:-}" ]; then
  log_info "External mirror URL specified: $EXTERNAL_VULNERABILITY_MIRROR_URL"
else
  log_info "No EXTERNAL_VULNERABILITY_MIRROR_URL specified in external.rc, this might result in scripts failing."
fi

if [ -n "${AE_CORE_VERSION:-}" ]; then
  log_info "Core version specified: $AE_CORE_VERSION"
else
  log_info "No AE_CORE_VERSION specified in external.rc file, using HEAD-SNAPSHOT."
fi

if [ -n "${AE_ARTIFACT_ANALYSIS_VERSION:-}" ]; then
  log_info "Artifact analysis version specified: $AE_ARTIFACT_ANALYSIS_VERSION"
else
  log_info "No AE_ARTIFACT_ANALYSIS_VERSION specified in external.rc file, using HEAD-SNAPSHOT"
fi


