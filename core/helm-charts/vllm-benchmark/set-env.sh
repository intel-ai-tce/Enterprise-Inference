#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Purpose:
#   Retrieve vLLM Service ClusterIP and port from Kubernetes
#   and export:
#     - REMOTE_HOST
#     - REMOTE_PORT
#     - ON_CPU=1
#
# Intended usage:
#   source ./set_vllm_remote_env.sh
# ------------------------------------------------------------------------------

set -euo pipefail

# ---- Configurable (override via env) ------------------------------------------
NAMESPACE="${NAMESPACE:-default}"
SERVICE_NAME="${SERVICE_NAME:-vllm-llama-8b-cpu-service}"

# ---- Preflight ---------------------------------------------------------------
command -v kubectl >/dev/null 2>&1 || {
  echo "ERROR: kubectl not found in PATH" >&2
  return 1 2>/dev/null || exit 1
}

# ---- Ensure benchmark config exists ------------------------------------------
SRC_CFG="./serving-tests-cpu.json"
DST_DIR="/mnt/bench-cfg"
DST_CFG="${DST_DIR}/serving-tests-cpu.json"

if [[ ! -f "$SRC_CFG" ]]; then
  echo "ERROR: Source config not found: $SRC_CFG" >&2
  return 1 2>/dev/null || exit 1
fi

if [[ -d "$DST_DIR" ]]; then
  # Directory exists: we only need write permission to it
  if [[ ! -w "$DST_DIR" ]]; then
    echo "ERROR: No write permission to existing directory: $DST_DIR" >&2
    ls -ld "$DST_DIR" >&2 || true
    return 1 2>/dev/null || exit 1
  fi
else
  # Directory does not exist: we need permission to create it under parent
  PARENT_DIR="$(dirname "$DST_DIR")"
  if [[ ! -w "$PARENT_DIR" ]]; then
    echo "ERROR: No permission to create $DST_DIR under $PARENT_DIR" >&2
    echo "       Fix (one-time): sudo mkdir -p $DST_DIR && sudo chown \$USER:\$USER $DST_DIR" >&2
    return 1 2>/dev/null || exit 1
  fi
  mkdir -p "$DST_DIR"
fi

if [[ ! -f "$DST_CFG" ]]; then
  cp "$SRC_CFG" "$DST_CFG"
  echo "Copied benchmark config to $DST_CFG"
else
  echo "Benchmark config already exists at $DST_CFG (skipping copy)"
fi


# ---- Query Service ------------------------------------------------------------
REMOTE_HOST="$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" \
  -o jsonpath='{.spec.clusterIP}')"

REMOTE_PORT="$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" \
  -o jsonpath='{.spec.ports[0].port}')"

if [[ -z "$REMOTE_HOST" || "$REMOTE_HOST" == "None" ]]; then
  echo "ERROR: Failed to resolve ClusterIP for service '$SERVICE_NAME' in namespace '$NAMESPACE'" >&2
  return 1 2>/dev/null || exit 1
fi

if [[ -z "$REMOTE_PORT" ]]; then
  echo "ERROR: Failed to resolve port for service '$SERVICE_NAME'" >&2
  return 1 2>/dev/null || exit 1
fi

# ---- Export Environment Variables ---------------------------------------------
export REMOTE_HOST
export REMOTE_PORT
export ON_CPU=1

# ---- User Feedback ------------------------------------------------------------
echo "vLLM remote endpoint environment variables set:"
echo "  REMOTE_HOST=$REMOTE_HOST"
echo "  REMOTE_PORT=$REMOTE_PORT"
echo "  ON_CPU=1"
echo
echo "Note: source this script to persist variables in your current shell."

