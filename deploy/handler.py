import os
import sys
import time
import requests
import runpod

LLAMA_URL = f"http://127.0.0.1:{os.environ.get('FOUNDRY_PORT', '8080')}"

def wait_for_llama():
    """Wait for llama-server to finish warming up and start listening."""
    print("[foundry-handler] Waiting for llama-server to be ready...")
    start_time = time.time()
    while True:
        try:
            response = requests.get(f"{LLAMA_URL}/health", timeout=2)
            if response.status_code == 200:
                print(f"[foundry-handler] llama-server is ready after {time.time() - start_time:.1f}s")
                return True
        except Exception:
            pass
        time.sleep(2)

def handler(job):
    """
    RunPod Serverless Handler.
    Receives an OpenAI-compatible payload inside job["input"] and proxies it to llama-server.
    """
    job_input = job["input"]
    
    # RunPod's OpenAI wrapper injects `openai_route` into the input
    # E.g., "/v1/chat/completions"
    route = job_input.get("openai_route", "/v1/chat/completions")
    
    # The actual payload for the OpenAI endpoint is in `openai_input` (if using wrapper)
    # Or just use the whole input if it's a direct custom call.
    payload = job_input.get("openai_input", job_input)
    
    if not isinstance(payload, dict) or "model" not in payload:
        # Fallback if someone hits the raw /run endpoint without openai wrapper
        payload["model"] = os.environ.get("FOUNDRY_MODEL_NAME", "qwen3.5-35b-a3b")

    try:
        # Forward the request to llama-server
        response = requests.post(
            f"{LLAMA_URL}{route}",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=300 # 5 minute timeout for long generations
        )
        
        # If llama-server returns an error, raise it so RunPod marks job as failed
        response.raise_for_status()
        
        # Return the exact JSON response back to RunPod
        return response.json()
        
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    wait_for_llama()
    runpod.serverless.start({"handler": handler})
