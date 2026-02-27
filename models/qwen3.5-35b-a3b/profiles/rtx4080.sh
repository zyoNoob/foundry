# ==============================================================================
# Foundry Profile: RTX 4080 (16GB)
# ==============================================================================
# Qwen3.5-35B-A3B Q4_K_M (~20GB) requires significant expert offloading.
# Similar to RTX 5080 but lower memory bandwidth (PCIe 4.0).
# ==============================================================================

PROFILE_CTX_LENGTH=16384        # 16K context, VRAM-constrained
PROFILE_THREADS=16              # Tune to physical cores
PROFILE_FIT="on"                # Auto GPU/CPU split (critical at 16GB)
PROFILE_FLASH_ATTN="on"         # Flash attention
PROFILE_KV_TYPE_K="q4_0"        # Aggressive: essential at 16GB
PROFILE_KV_TYPE_V="q4_0"        # Saves ~50% KV cache VRAM vs q8_0
PROFILE_NO_MMAP="true"          # Avoid page faults
PROFILE_JINJA="true"            # Chat template support
PROFILE_PARALLEL=1              # Single slot = max throughput
PROFILE_EXTRA_ARGS="--mlock"
