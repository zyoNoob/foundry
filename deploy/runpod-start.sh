#!/bin/bash
# ==============================================================================
# Foundry RunPod Serverless Entrypoint
# ==============================================================================

set -euo pipefail

echo "[foundry] Starting RunPod health check sidecar on port ${PORT_HEALTH:-8081}..."
python3 /opt/foundry/health_check.py &

# Delegate to the main, robust entrypoint that handles GPU detection,
# profile loading, model downloading, and execs llama-server.
exec /opt/foundry/entrypoint.sh
