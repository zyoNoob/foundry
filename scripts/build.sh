#!/bin/bash
# ==============================================================================
# Foundry: Build Docker image
# ==============================================================================
# Usage:
#   ./scripts/build.sh                    # Build model image
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

REGISTRY="${REGISTRY:-ghcr.io/infernet-org/foundry}"

echo "Building model image (qwen3.5-35b-a3b)..."
echo "  Base: ghcr.io/ggml-org/llama.cpp:server-cuda13"
echo ""

docker build \
    -t "${REGISTRY}/qwen3.5-35b-a3b:latest" \
    "${PROJECT_DIR}/models/qwen3.5-35b-a3b/"

echo ""
echo "Build complete:"
echo "  Image: ${REGISTRY}/qwen3.5-35b-a3b:latest"
echo ""
echo "Run with:"
echo "  docker run --gpus all -p 8080:8080 -v ~/.cache/foundry:/models ${REGISTRY}/qwen3.5-35b-a3b:latest"
