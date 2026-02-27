# ==============================================================================
# Foundry Profile: RTX 4090 (24GB)
# ==============================================================================
# Qwen3.5-35B-A3B Q4_K_M (~20GB) fits with minimal expert offload.
# --fit on auto-manages the GPU/CPU split.
# Community benchmarks: ~122 tok/s decode with -np 1 + q8_0 KV cache.
# ==============================================================================

PROFILE_CTX_LENGTH=65536        # 64K context, balances speed and VRAM
PROFILE_THREADS=16              # Tune to physical cores
PROFILE_FIT="on"                # Auto GPU/CPU split
PROFILE_FLASH_ATTN="on"         # Flash attention
PROFILE_KV_TYPE_K="q4_0"        # Aggressive KV quantization saves VRAM on 24GB
PROFILE_KV_TYPE_V="q4_0"        # Allows more context or more layers in GPU
PROFILE_NO_MMAP="true"          # Avoid page faults
PROFILE_JINJA="true"            # Chat template support
PROFILE_PARALLEL=1              # Single slot = max throughput (70 -> 122 tok/s)
PROFILE_EXTRA_ARGS="--mlock"
