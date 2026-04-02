#!/bin/bash
set -e

# Load GCP access token from shared volume (refreshed every 45 min by gcp-token-refresh container)
if [ -f "${GCP_ACCESS_TOKEN_FILE:-/tmp/gcp/token}" ]; then
    export GCP_ACCESS_TOKEN
    GCP_ACCESS_TOKEN=$(cat "${GCP_ACCESS_TOKEN_FILE:-/tmp/gcp/token}")
fi

# Load Azure access token from shared volume (refreshed every 45 min by azure-token-refresh container)
if [ -f "${AZURE_ACCESS_TOKEN_FILE:-/tmp/azure/token}" ]; then
    export AZURE_ACCESS_TOKEN
    AZURE_ACCESS_TOKEN=$(cat "${AZURE_ACCESS_TOKEN_FILE:-/tmp/azure/token}")
fi

exec "$@"
