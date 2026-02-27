#!/bin/bash
# Launch llama-server with RTX 5090 profile and run benchmarks

set -euo pipefail

MODEL_PATH="${1:-/workspace/models/Qwen3.5-35B-A3B-Q4_K_M.gguf}"
PORT="${2:-8080}"
LLAMA_SERVER="${3:-/root/llama.cpp/build/bin/llama-server}"

if [ ! -f "$MODEL_PATH" ]; then
    echo "ERROR: Model not found at $MODEL_PATH"
    echo "Download status:"
    ls -lh /workspace/models/ 2>/dev/null | tail -5 || echo "  No models directory"
    exit 1
fi

MODEL_SIZE=$(du -h "$MODEL_PATH" | cut -f1)
echo "Starting inference server..."
echo "  Model: $(basename $MODEL_PATH) ($MODEL_SIZE)"
echo "  Port: $PORT"
echo ""

# Launch llama-server with RTX 5090 profile
# --fit on: Auto-manage GPU/CPU memory
# -fa on: Flash attention
# -ctk q8_0 -ctv q8_0: Quantize KV cache
# --no-mmap: Don't use memory-mapped IO
# --jinja: Support chat templates
# --parallel 4: 4 concurrent slots
$LLAMA_SERVER \
    --model "$MODEL_PATH" \
    --host 0.0.0.0 \
    --port "$PORT" \
    --ctx-size 131072 \
    --threads 20 \
    --fit on \
    -fa on \
    -ctk q8_0 -ctv q8_0 \
    --no-mmap \
    --jinja \
    --parallel 4 \
    --log-format json 2>&1 | tee /tmp/llama-server.log &

SERVER_PID=$!
echo "Server started (PID: $SERVER_PID)"
echo ""

# Wait for server to be ready
echo "Waiting for server to be ready..."
for i in {1..60}; do
    if curl -sf "http://localhost:$PORT/health" > /dev/null 2>&1; then
        echo "✓ Server is ready"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "✗ Server did not start within 60 seconds"
        kill $SERVER_PID 2>/dev/null || true
        exit 1
    fi
    sleep 1
done

echo ""
echo "Running benchmarks..."
python3 /workspace/benchmark.py --url "http://localhost:$PORT" --mode all --requests 5

echo ""
echo "Server running at http://localhost:$PORT"
echo "Press Ctrl+C to stop"

# Keep server running
wait $SERVER_PID
