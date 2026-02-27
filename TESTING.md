# Foundry Testing Guide

## Build Status

### Local Build
- ✅ All Docker configurations validated
- ✅ Makefile targets tested
- ✅ Entrypoint script validated
- ✅ GPU profile configs validated

### RunPod RTX 5090 Testing

**Pod**: `m6aco0tmefz8z4`  
**GPU**: NVIDIA GeForce RTX 5090 (32GB VRAM, CUDA Compute Capability 12.0)

#### Build Verification ✅
```
Binary: /root/llama.cpp/build/bin/llama-server (7.6 MB)
CUDA Support: Yes (sm_120 - Blackwell)
Version: 1 (d903f30)
```

#### CLI Flags Verified ✅
All tuning parameters are present in the binary:
- `--fit [on|off]` — MoE expert-level offloading
- `-fa, --flash-attn [on|off|auto]` — Flash attention optimization
- `-c, --ctx-size N` — Context window configuration
- `-np, --parallel N` — Server slots for concurrency
- `--jinja` — Jinja template engine for chat

#### Model Download Status
- Qwen3.5-35B-A3B Q4_K_M (~20GB): In progress (interrupted due to timeout)
- Alternative: Test with smaller model once available

---

## How to Test Locally

### Option 1: With Docker (Recommended)

```bash
# Build the image
make build

# Run on your GPU (auto-detects)
make run

# In another terminal, test
make test
```

### Option 2: Native Binary on Linux

```bash
# Clone and build
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
cmake -B build -DGGML_CUDA=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build --target llama-server

# Download model
huggingface-cli download unsloth/Qwen3.5-35B-A3B-GGUF \
  Qwen3.5-35B-A3B-Q4_K_M.gguf \
  --local-dir ./models

# Launch server with RTX 5090 profile
./build/bin/llama-server \
  --model ./models/Qwen3.5-35B-A3B-Q4_K_M.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  --ctx-size 131072 \
  --threads 20 \
  --fit on \
  -fa on \
  -ctk q8_0 -ctv q8_0 \
  --no-mmap \
  --jinja \
  --parallel 4

# Test
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3.5-35b-a3b",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 64
  }'
```

### Option 3: On RunPod

```bash
# SSH to pod
ssh -tt -i ~/.ssh/id_ecdsa YOUR_POD_ID@ssh.runpod.io

# Build llama.cpp (one-time)
cd /root && git clone --depth 1 https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES='120' -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j$(nproc) --target llama-server

# Download model (background)
nohup bash -c 'huggingface-cli download unsloth/Qwen3.5-35B-A3B-GGUF \
  Qwen3.5-35B-A3B-Q4_K_M.gguf \
  --local-dir /root/models \
  --local-dir-use-symlinks False' > /tmp/download.log 2>&1 &

# Monitor download
tail -f /tmp/download.log

# Once downloaded, run server
/root/llama.cpp/build/bin/llama-server \
  --model /root/models/Qwen3.5-35B-A3B-Q4_K_M.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  --ctx-size 131072 \
  --threads 20 \
  --fit on \
  -fa on \
  -ctk q8_0 -ctv q8_0 \
  --no-mmap \
  --jinja \
  --parallel 4
```

---

## Expected Performance

### RTX 5090 (32GB)
- **Model**: Qwen3.5-35B-A3B Q4_K_M
- **Context**: 131K tokens
- **Expected tok/s**: ~160 (generation), ~500+ (prompt processing)
- **VRAM Usage**: ~20GB (fully in VRAM, no offloading needed)

### RTX 4090 (24GB)
- **Model**: Qwen3.5-35B-A3B Q4_K_M
- **Context**: 65K tokens
- **Expected tok/s**: ~70 (with `--fit on` expert offloading)
- **VRAM Usage**: ~20GB + CPU offload for inactive experts

### RTX 3090 (24GB)
- **Model**: Qwen3.5-35B-A3B Q4_K_M
- **Context**: 65K tokens
- **Expected tok/s**: ~55 (with `--fit on`)
- **VRAM Usage**: ~20GB + CPU offload

---

## Benchmarking

Once inference is working, run benchmarks:

```bash
# Single prompt latency
time curl http://localhost:8080/v1/chat/completions \
  -d '{"model":"qwen","messages":[{"role":"user","content":"What is 2+2?"}],"max_tokens":10}'

# Throughput with multiple concurrent requests
for i in {1..10}; do
  curl http://localhost:8080/v1/chat/completions \
    -d '{"model":"qwen","messages":[{"role":"user","content":"Count to 10"}],"max_tokens":20}' &
done
wait
```

---

## Debugging

### GPU Not Detected
```bash
nvidia-smi  # Check GPU
lspci | grep NVIDIA  # Check PCIe

# In llama-server output, look for:
# "ggml_cuda_init: found N CUDA devices"
```

### OOM (Out of Memory)
- Reduce `--ctx-size`
- Reduce `--parallel` (concurrent slots)
- Enable `--fit on` to auto-offload
- Use lower quantization (Q3_K_M vs Q4_K_M)

### Slow Performance
- Check `--threads` matches CPU core count
- Verify `--fit on` is enabled for models >24GB params on consumer GPUs
- Check KV cache quantization (`-ctk q8_0 -ctv q8_0`)
- Enable flash attention (`-fa on`)

---

## CI/CD

The GitHub Actions workflow (`.github/workflows/build.yml`) automatically:
1. Builds base image with CUDA 12.8 (RTX 5090 support)
2. Builds base image with CUDA 12.4 (RTX 30/40 support)
3. Builds model image
4. Pushes to GHCR: `ghcr.io/infernet-org/foundry/*`

Trigger: Push to main branch or git tag `v*`

Images available at:
- `ghcr.io/infernet-org/foundry/base-llama-cpp:cu128`
- `ghcr.io/infernet-org/foundry/base-llama-cpp:cu124`
- `ghcr.io/infernet-org/foundry/qwen3.5-35b-a3b:latest`
