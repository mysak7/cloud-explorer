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

# Copy ~/.azure to a writable location so the Azure CLI credential chain can
# cache tokens (the bind-mount is read-only to protect the host config)
if [ -d "${HOME}/.azure" ]; then
    cp -r "${HOME}/.azure" /tmp/azure-cli-config
    export AZURE_CONFIG_DIR=/tmp/azure-cli-config
fi

exec "$@"
