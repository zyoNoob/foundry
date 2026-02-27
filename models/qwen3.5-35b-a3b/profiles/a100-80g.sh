# ==============================================================================
# Foundry Profile: A100 80GB
# ==============================================================================
# Qwen3.5-35B-A3B fits entirely in VRAM even at Q8_0 (~40GB).
# 80GB allows high context, high parallelism, and premium quant.
# ==============================================================================

PROFILE_CTX_LENGTH=131072       # 128K context, plenty of VRAM
PROFILE_THREADS=32              # Datacenter CPU typically has many cores
PROFILE_FIT="on"                # Keep on for safety even with 80GB
PROFILE_FLASH_ATTN="on"         # Flash attention
PROFILE_KV_TYPE_K="q8_0"        # Quality KV cache, VRAM is abundant
PROFILE_KV_TYPE_V="q8_0"        #
PROFILE_NO_MMAP="true"          # Avoid page faults
PROFILE_JINJA="true"            # Chat template support
PROFILE_PARALLEL=4              # A100 can handle concurrent requests
PROFILE_EXTRA_ARGS="--mlock"
