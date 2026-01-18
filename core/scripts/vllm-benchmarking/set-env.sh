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

