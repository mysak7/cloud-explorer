#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo " Cloud Explorer Agent — Environment Verify"
echo "============================================"
echo ""

echo "--- [1/3] IAM Identity (aws sts get-caller-identity) ---"
if aws sts get-caller-identity; then
  echo "IAM auth: OK"
else
  echo "IAM auth: FAILED — check AWS_PROFILE and ~/.aws mount"
fi

echo ""
echo "--- [2/3] Netbird WireGuard Interface (wt0) ---"
if ip a | grep wt0; then
  echo "Netbird VPN interface: OK"
else
  echo "Netbird VPN interface: NOT FOUND — check netbird sidecar and NB_SETUP_KEY"
fi

echo ""
echo "--- [3/4] Azure Identity (az account show) ---"
if [ -n "${AZURE_SUBSCRIPTION_ID:-}" ]; then
  if az account show --query id -o tsv 2>/dev/null; then
    echo "Azure auth: OK"
  else
    echo "Azure auth: FAILED — check ~/.azure mount and run: az login"
  fi
else
  echo "Azure auth: SKIPPED — AZURE_SUBSCRIPTION_ID not set"
fi

echo ""
echo "--- [4/4] Container User / UID ---"
id
echo ""
echo "Host UID should match the above uid= value."
echo "If they differ, set updateRemoteUserUID: true in devcontainer.json (already set)."

echo ""
echo "============================================"
echo " Verification complete."
echo "============================================"
