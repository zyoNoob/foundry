#!/bin/bash
# ==============================================================================
# Foundry RunPod Serverless Entrypoint
# ==============================================================================

set -euo pipefail

# 1. Start the RunPod Serverless Handler in the background.
# It will poll `localhost:8080/health` until llama-server is ready,
# then it will connect to RunPod's queue and start accepting jobs.
echo "[foundry] Starting RunPod Python Handler..."
python3 /opt/foundry/handler.py &

# 2. Delegate to the main, robust entrypoint that handles GPU detection,
# profile loading, model downloading, and execs llama-server.
# (This blocks and keeps the container alive)
exec /opt/foundry/entrypoint.sh
