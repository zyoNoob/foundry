# ==============================================================================
# Foundry Profile: RTX 3090 (24GB)
# ==============================================================================
# Qwen3.5-35B-A3B Q4_K_M (~20GB) fits with partial expert offload.
# PCIe 4.0 bandwidth, lower memory bandwidth than 4090.
# Community benchmarks: ~100 tok/s decode with -np 1 + q8_0 KV cache.
# ==============================================================================

PROFILE_CTX_LENGTH=32768        # 32K context, conservative for 24GB + PCIe 4.0
PROFILE_THREADS=16              # Tune to physical cores
PROFILE_FIT="on"                # Auto GPU/CPU split
PROFILE_FLASH_ATTN="on"         # Flash attention
PROFILE_KV_TYPE_K="q4_0"        # Aggressive KV quantization to free VRAM
PROFILE_KV_TYPE_V="q4_0"        # Keeps more model layers on GPU
PROFILE_NO_MMAP="true"          # Avoid page faults
PROFILE_JINJA="true"            # Chat template support
PROFILE_PARALLEL=1              # Single slot = max throughput (50 -> 100 tok/s)
PROFILE_EXTRA_ARGS="--mlock"
