# ==============================================================================
# Foundry Profile: RTX 5080 (16GB)
# ==============================================================================
# Qwen3.5-35B-A3B Q4_K_M (~20GB) requires significant expert offloading.
# --fit on auto-manages GPU/CPU split. 16GB means most experts on CPU.
# KV cache q4_0 is essential to maximize layers on GPU.
# ==============================================================================

PROFILE_CTX_LENGTH=16384        # 16K context, VRAM-constrained
PROFILE_THREADS=20              # Zen4/5 or equivalent
PROFILE_FIT="on"                # Auto GPU/CPU split (critical at 16GB)
PROFILE_FLASH_ATTN="on"         # Flash attention
PROFILE_KV_TYPE_K="q4_0"        # Aggressive: saves ~50% KV cache VRAM vs q8_0
PROFILE_KV_TYPE_V="q4_0"        # Essential at 16GB
PROFILE_NO_MMAP="true"          # Avoid page faults
PROFILE_JINJA="true"            # Chat template support
PROFILE_PARALLEL=1              # Single slot = max throughput
PROFILE_EXTRA_ARGS="--mlock"
