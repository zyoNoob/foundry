# ==============================================================================
# Foundry Profile: RTX 5090 (32GB)
# ==============================================================================
# Qwen3.5-35B-A3B UD-Q4_K_XL (~20.6GB) fits entirely in VRAM.
# All layers on GPU. No expert offloading needed.
#
# VRAM budget (32,607 MiB total):
#   Model weights:    19,219 MiB (CUDA) + 398 MiB (Host)
#   KV cache (192K):  ~2,040 MiB
#   Recurrent state:     ~93 MiB
#   Compute buffers:   3,944 MiB (CUDA) + 2,112 MiB (Host)
#   Free headroom:    ~5,300 MiB
#
# Benchmarked on RTX 5090 (2026-02-27):
#   Decode:  ~170 tok/s  |  Prompt processing: ~1,163 tok/s
#   GPU util: 92%  |  Mem BW: 49%  |  Power: 337W / 600W
# ==============================================================================

PROFILE_CTX_LENGTH=196608       # 192K context -- uses ~2GB KV, fits with 5GB headroom
PROFILE_THREADS=16              # Physical cores (avoid hyperthreads for decode)
PROFILE_THREADS_BATCH=20        # Higher thread count for prompt processing
PROFILE_FIT="on"                # Auto GPU/CPU split (all-GPU at 32GB)
PROFILE_FLASH_ATTN="on"         # Flash attention for long context perf
PROFILE_KV_TYPE_K="q8_0"        # KV cache key quantization
PROFILE_KV_TYPE_V="q8_0"        # KV cache value quantization
PROFILE_NO_MMAP="true"          # Avoid page faults, load model into RAM
PROFILE_JINJA="true"            # Chat template / tool calling support
PROFILE_PARALLEL=1              # Single slot = maximum single-stream tok/s
PROFILE_PRIO=2                  # High thread priority for reduced scheduling latency
PROFILE_CPU_STRICT=1            # Strict CPU placement for cache locality
PROFILE_CACHE_REUSE=256         # KV cache reuse for multi-turn chat prefix sharing
PROFILE_NO_WEBUI="true"         # Headless: no web UI, reduce attack surface
PROFILE_METRICS="true"          # Prometheus-compatible /metrics endpoint
# --mlock: pin model in RAM; -b/-ub 4096: large batch for fast prompt encode
# --swa-full: full SWA cache for hybrid attention models
# --cache-ram 0: disable prompt cache (Qwen3.5 hybrid arch forces re-processing)
PROFILE_EXTRA_ARGS="--mlock -b 4096 -ub 4096 --swa-full --cache-ram 0"
