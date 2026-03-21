#!/bin/bash
set -e

# Load GCP access token from shared volume (refreshed every 45 min by gcp-token-refresh container)
if [ -f "${GCP_ACCESS_TOKEN_FILE:-/tmp/gcp/token}" ]; then
    export GCP_ACCESS_TOKEN
    GCP_ACCESS_TOKEN=$(cat "${GCP_ACCESS_TOKEN_FILE:-/tmp/gcp/token}")
fi

exec "$@"
