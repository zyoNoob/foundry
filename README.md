# Foundry

Tuned Docker images for running open LLMs on consumer GPUs. One command, maximum tok/s.

Foundry provides pre-configured Docker images with per-GPU hardware profiles that automatically detect your GPU and apply optimal inference settings. No manual tuning required.

## Quick Start

```bash
# Run Qwen3.5-35B-A3B with auto-detected GPU settings
docker run --gpus all -p 8080:8080 \
  --sysctl net.core.somaxconn=4096 \
  --sysctl net.ipv4.tcp_keepalive_time=60 \
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

| GPU | VRAM | Expected tok/s (Decode) | Expected tok/s (Encode) |
|-----|------|-------------------------|-------------------------|
| RTX 5090 | 32 GB | ~115 | ~3500 |

*Metrics based on `Qwen3.5-35B-A3B` using `UD-Q4_K_XL` (Unsloth Dynamic 2.0 quantization).*

## How It Works

Foundry uses [llama.cpp](https://github.com/ggml-org/llama.cpp) as the inference engine, built on the official [`server-cuda12`](https://github.com/ggml-org/llama.cpp/pkgs/container/llama.cpp) image (CUDA 12, maximizing host compatibility).

Why not SGLang or vLLM? Because for **consumer GPUs**, llama.cpp's expert-level MoE offloading (`--fit on`) is the only way to run a 35B-parameter MoE model on a single 16-24GB card at full speed. SGLang and vLLM require the entire model to fit in VRAM.

Qwen3.5-35B-A3B is a Mixture-of-Experts model: 35B total parameters but only 3B active per token. llama.cpp keeps attention and norms on GPU while spilling inactive experts to CPU. This is why a 35B MoE model runs **3-10x faster** than a 27B dense model on the same hardware.

### GPU Auto-Detection

On startup, Foundry:
1. Detects your GPU via `nvidia-smi`
2. Loads a tuned hardware profile with optimal settings
3. Downloads the GGUF model if not already cached
4. Launches `llama-server` with the right arguments

### Hardware Profiles

Each profile tunes: context length, KV cache quantization, thread count, memory fraction, flash attention, and MoE offloading strategy.

```bash
# Override auto-detection with a specific profile
docker run --gpus all -p 8080:8080 \
  --sysctl net.core.somaxconn=4096 \
  --sysctl net.ipv4.tcp_keepalive_time=60 \
  -v ~/.cache/foundry:/models \
  -e FOUNDRY_PROFILE=rtx4090 \
  ghcr.io/infernet-org/foundry/qwen3.5-35b-a3b:latest
```

Available profiles: `rtx5090`, `default`

## Build From Source

```bash
# Build the model image (pulls official llama.cpp base automatically)
make build

# Run locally
make run
```

## Configuration

All settings can be overridden via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `FOUNDRY_PROFILE` | `auto` | GPU profile (`auto`, `rtx5090`, `rtx4090`, etc.) |
| `FOUNDRY_PORT` | `8080` | Server port |
| `FOUNDRY_CTX_LENGTH` | Profile default | Context window size |
| `FOUNDRY_THREADS` | Profile default | CPU threads for expert offloading |
| `FOUNDRY_EXTRA_ARGS` | `` | Additional llama-server arguments |

## Architecture

```
foundry/
├── models/
│   └── qwen3.5-35b-a3b/        # Model image (FROM llama.cpp:server-cuda12)
│       ├── Dockerfile
│       ├── entrypoint.sh
│       └── profiles/            # RTX 5090 tuned launch configs
├── scripts/                     # Benchmark helpers
└── docker-compose.yml           # Easy local deployment
```

## Models

### Qwen3.5-35B-A3B

- **Architecture**: Hybrid Gated DeltaNet + MoE (35B total, 3B active)
- **Quantization**: UD-Q4_K_XL via [unsloth](https://huggingface.co/unsloth/Qwen3.5-35B-A3B-GGUF) (Dynamic 2.0 format)
- **Disk size**: ~20.6 GB
- **Min VRAM**: 16 GB (with expert offloading)
- **Context**: Up to 262K native, default varies by GPU profile

## License

Apache-2.0
