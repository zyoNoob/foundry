# ==============================================================================
# Foundry Profile: RTX 5090 (32GB)
# ==============================================================================
# Qwen3.5-35B-A3B UD-Q4_K_XL (~20.6GB) fits entirely in VRAM.
# All layers on GPU. No expert offloading needed.
# ==============================================================================

PROFILE_CTX_LENGTH=131072       # 128K context, fits comfortably in 32GB
PROFILE_THREADS=20              # Tune to physical cores
PROFILE_FIT="on"                # Auto GPU/CPU split (all-GPU at 32GB)
PROFILE_FLASH_ATTN="on"         # Flash attention for long context perf
PROFILE_KV_TYPE_K="q8_0"        # KV cache key quantization
PROFILE_KV_TYPE_V="q8_0"        # KV cache value quantization
PROFILE_NO_MMAP="true"          # Avoid page faults, load model into RAM
PROFILE_JINJA="true"            # Chat template / tool calling support
PROFILE_PARALLEL=1              # Single slot = maximum single-stream tok/s
PROFILE_EXTRA_ARGS="--mlock -b 4096 -ub 4096" # Pin memory, large batch for fast encode
