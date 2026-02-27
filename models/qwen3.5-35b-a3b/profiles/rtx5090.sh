# ==============================================================================
# Foundry Profile: RTX 5090 (32GB)
# ==============================================================================
# Qwen3.5-35B-A3B Q4_K_M (~20GB) fits entirely in VRAM.
# All layers on GPU. No expert offloading needed.
# Community benchmarks: ~165 tok/s decode with UD-Q4_K_XL quant.
# ==============================================================================

PROFILE_CTX_LENGTH=131072       # 128K context, fits comfortably in 32GB
PROFILE_THREADS=20              # Zen4/5 or equivalent, tune to physical cores
PROFILE_FIT="on"                # Auto GPU/CPU split (all-GPU at 32GB)
PROFILE_FLASH_ATTN="on"         # Flash attention for long context perf
PROFILE_KV_TYPE_K="q8_0"        # KV cache key quantization
PROFILE_KV_TYPE_V="q8_0"        # KV cache value quantization
PROFILE_NO_MMAP="true"          # Avoid page faults, load model into RAM
PROFILE_JINJA="true"            # Chat template / tool calling support
PROFILE_PARALLEL=1              # Single slot = maximum single-stream tok/s
PROFILE_EXTRA_ARGS="--mlock"    # Pin memory to prevent swapping
