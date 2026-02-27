# ==============================================================================
# Foundry Profile: H100 (80GB)
# ==============================================================================
# Qwen3.5-35B-A3B fits entirely in VRAM at Q8_0 (~40GB).
# Maximum throughput with high parallelism. HBM3 bandwidth dominates.
# ==============================================================================

PROFILE_CTX_LENGTH=131072       # 128K context
PROFILE_THREADS=32              # Datacenter CPU
PROFILE_FIT="on"                # Keep on for safety
PROFILE_FLASH_ATTN="on"         # Flash attention
PROFILE_KV_TYPE_K="q8_0"        # Quality KV cache
PROFILE_KV_TYPE_V="q8_0"        #
PROFILE_NO_MMAP="true"          # Avoid page faults
PROFILE_JINJA="true"            # Chat template support
PROFILE_PARALLEL=4              # H100 can handle concurrent requests
PROFILE_EXTRA_ARGS="--mlock"
