# Foundry

Tuned Docker images for running open LLMs on consumer GPUs. One command, maximum tok/s.

Foundry provides pre-configured Docker images with per-GPU hardware profiles that automatically detect your GPU and apply optimal inference settings. No manual tuning required.

## Quick Start

```bash
docker run --gpus all -p 8080:8080 \
  -v ~/.cache/foundry:/models \
  ghcr.io/infernet-org/foundry/qwen3.5-35b-a3b:latest
```

The first run downloads the model (~20GB). Subsequent starts are instant.

Then use it like any OpenAI-compatible API:

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3.5-35b-a3b",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

Works with any OpenAI-compatible client: Cursor, Continue, OpenCode, Open WebUI, etc.

## Supported Hardware

| GPU | VRAM | Context | Decode (tok/s) | Prompt (tok/s) |
|-----|------|---------|----------------|----------------|
| RTX 5090 | 32 GB | 192K | ~170 | ~1,163 |
| Other NVIDIA (16GB+) | 16+ GB | 16K | varies | varies |

*Benchmarked with `Qwen3.5-35B-A3B` using `UD-Q4_K_XL` quantization (Unsloth Dynamic 2.0).*

## How It Works

Foundry uses [llama.cpp](https://github.com/ggml-org/llama.cpp) as the inference engine, built on the official [`server-cuda12`](https://github.com/ggml-org/llama.cpp/pkgs/container/llama.cpp) image.

Why not SGLang or vLLM? For **consumer GPUs**, llama.cpp's MoE expert offloading (`--fit on`) is the only engine that can run a 35B-parameter MoE model on a single 16-24GB card at full speed. SGLang and vLLM require the entire model to fit in VRAM.

Qwen3.5-35B-A3B is a Mixture-of-Experts model: 35B total parameters but only 3B active per token. llama.cpp keeps attention layers on GPU while spilling inactive experts to CPU, which is why a 35B MoE runs **faster** than a 27B dense model on the same hardware.

### GPU Auto-Detection

On startup, Foundry:
1. Detects your GPU via `nvidia-smi`
2. Loads a tuned hardware profile with optimal settings
3. Downloads the GGUF model if not already cached
4. Launches `llama-server` with the right arguments

### Hardware Profiles

Each profile tunes: context length, KV cache quantization, thread count, batch size, flash attention, thread priority, CPU affinity, and Prometheus metrics.

```bash
# Override auto-detection with a specific profile
docker run --gpus all -p 8080:8080 \
  -v ~/.cache/foundry:/models \
  -e FOUNDRY_PROFILE=rtx5090 \
  ghcr.io/infernet-org/foundry/qwen3.5-35b-a3b:latest
```

Available profiles: `rtx5090`, `default`

## Configuration

All settings can be overridden via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `FOUNDRY_PROFILE` | `auto` | GPU profile (`auto`, `rtx5090`, `default`) |
| `FOUNDRY_PORT` | `8080` | Server port |
| `FOUNDRY_CTX_LENGTH` | Profile default | Context window size |
| `FOUNDRY_THREADS` | Profile default | CPU thread count |
| `FOUNDRY_EXTRA_ARGS` | (empty) | Additional llama-server arguments (highest priority) |
| `HF_TOKEN` | (empty) | Hugging Face token for authenticated downloads |

## Docker Compose

```bash
# Basic
docker compose up

# With explicit profile
FOUNDRY_PROFILE=rtx5090 docker compose up
```

Create a `.env` file for secrets:

```
HF_TOKEN=hf_your_token_here
```

## Host Kernel Tuning (Optional)

For maximum performance, run the host tuning script once on the Docker host:

```bash
sudo ./scripts/host-setup.sh
```

This tunes: `vm.swappiness`, `vm.overcommit_memory`, hugepages, TCP buffers, CPU governor, and NVIDIA persistence mode. Changes are not persistent across reboots -- the script prints instructions for making them permanent.

## Build From Source

```bash
make build    # Build the model image
make run      # Run with auto-detected GPU
make test     # Smoke test: start, wait for health, send one request
make download # Download the GGUF model file to ~/.cache/foundry
```

## Architecture

```
foundry/
├── models/
│   └── qwen3.5-35b-a3b/
│       ├── Dockerfile           # FROM llama.cpp:server-cuda12
│       ├── entrypoint.sh        # GPU detect, model download, launch
│       └── profiles/
│           ├── rtx5090.sh       # 192K ctx, q8_0 KV, 170 tok/s
│           └── default.sh       # 16K ctx, q4_0 KV, conservative
├── scripts/
│   ├── benchmark.py             # Generation speed, prompt processing, throughput
│   ├── optimize_5090.py         # Multi-config A/B testing harness
│   ├── download-model.sh        # Download GGUF outside Docker
│   └── host-setup.sh            # Linux kernel tuning for inference
├── docker-compose.yml
├── Makefile
└── .github/workflows/build.yml  # CI: build and push to GHCR
```

## Benchmark

RTX 5090 profile results (Qwen3.5-35B-A3B UD-Q4_K_XL, 192K context):

```
GENERATION SPEED:     ~170 tok/s (decode)
PROMPT PROCESSING:  ~1,163 tok/s (encode, internal metric)
GPU UTILIZATION:         92%
MEMORY BANDWIDTH:        49% (bottleneck)
POWER DRAW:             337W / 600W TDP
TEMPERATURE:             52C (under sustained load)
VRAM USAGE:           26.9 GB / 32.6 GB
```

Run your own benchmark:

```bash
python3 scripts/benchmark.py --url http://localhost:8080 --mode all
```

## Models

### Qwen3.5-35B-A3B

- **Architecture**: Hybrid Gated DeltaNet + MoE (35B total, 3B active)
- **Quantization**: UD-Q4_K_XL via [Unsloth](https://huggingface.co/unsloth/Qwen3.5-35B-A3B-GGUF) (Dynamic 2.0)
- **Disk size**: ~20.6 GB
- **Min VRAM**: 16 GB (with expert offloading)
- **Max context**: 262K native, 192K default on RTX 5090

## License

Apache-2.0
