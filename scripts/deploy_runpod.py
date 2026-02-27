#!/usr/bin/env python3
"""
Foundry RunPod Deployment Script

Creates a serverless endpoint on RunPod for the Foundry inference image.

Usage:
    export RUNPOD_API_KEY="your-api-key"
    python scripts/deploy_runpod.py [--name NAME] [--template-id ID] [--workers-max N]

Requires: pip install requests
"""

import os
import sys
import json
import time
import argparse
import requests

BASE_URL = "https://rest.runpod.io/v1"
HEALTH_URL = "https://api.runpod.ai/v2"

# Default GPU priority: cheapest first, all >=24GB VRAM
DEFAULT_GPU_IDS = [
    "NVIDIA GeForce RTX 3090",
    "NVIDIA GeForce RTX 4090",
    "NVIDIA RTX A6000",
    "NVIDIA A40",
    "NVIDIA L40S",
    "NVIDIA A100 80GB PCIe",
    "NVIDIA A100-SXM4-80GB",
    "NVIDIA H100 80GB HBM3",
]

GHCR_IMAGE = "ghcr.io/infernet-org/foundry/qwen3.5-35b-a3b:latest"


def get_api_key():
    key = os.environ.get("RUNPOD_API_KEY")
    if not key:
        print("Error: RUNPOD_API_KEY environment variable is not set.")
        print("  export RUNPOD_API_KEY='your-api-key'")
        sys.exit(1)
    return key


def api_request(method, path, api_key, json_data=None):
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    url = f"{BASE_URL}{path}"
    resp = requests.request(method, url, headers=headers, json=json_data)
    if resp.status_code >= 400:
        print(f"Error {resp.status_code}: {resp.text}")
        sys.exit(1)
    return resp.json()


def create_template(api_key, name):
    """Create a serverless template for the Foundry image."""
    print(f"Creating template '{name}'...")
    from urllib.parse import quote

    url = f"https://api.runpod.io/graphql?api_key={api_key}"
    query = """
    mutation saveTemplate($input: SaveTemplateInput!) {
      saveTemplate(input: $input) { id name }
    }
    """
    variables = {
        "input": {
            "name": name,
            "imageName": GHCR_IMAGE,
            "containerDiskInGb": 40,
            "volumeInGb": 0,
            "isServerless": True,
            "env": [{"key": "FOUNDRY_PORT", "value": "8080"}],
            "ports": "8080/http",
        }
    }
    resp = requests.post(url, json={"query": query, "variables": variables})
    data = resp.json()
    if "errors" in data:
        # Template name already exists -- try to find it
        if "unique" in str(data["errors"]):
            print(f"  Template '{name}' already exists, looking up ID...")
            return find_template(api_key, name)
        print(f"GraphQL Error: {json.dumps(data['errors'], indent=2)}")
        sys.exit(1)
    template_id = data["data"]["saveTemplate"]["id"]
    print(f"  Template created: {template_id}")
    return template_id


def find_template(api_key, name):
    """Find an existing template by name."""
    url = f"https://api.runpod.io/graphql?api_key={api_key}"
    query = "query { myself { podTemplates { id name } } }"
    resp = requests.post(url, json={"query": query})
    for t in resp.json()["data"]["myself"]["podTemplates"]:
        if t["name"] == name:
            print(f"  Found template: {t['id']}")
            return t["id"]
    print(f"Error: Template '{name}' not found.")
    sys.exit(1)


def create_endpoint(api_key, name, template_id, gpu_ids, workers_max):
    """Create a serverless endpoint via the REST API."""
    print(f"Creating endpoint '{name}'...")
    payload = {
        "name": name,
        "templateId": template_id,
        "gpuTypeIds": gpu_ids,
        "gpuCount": 1,
        "workersMin": 0,
        "workersMax": workers_max,
        "idleTimeout": 5,
        "scalerType": "QUEUE_DELAY",
        "scalerValue": 4,
    }
    data = api_request("POST", "/endpoints", api_key, payload)
    endpoint_id = data["id"]
    print(f"  Endpoint created: {endpoint_id}")
    return endpoint_id


def check_health(api_key, endpoint_id):
    """Check the health of a serverless endpoint."""
    headers = {"Authorization": f"Bearer {api_key}"}
    resp = requests.get(f"{HEALTH_URL}/{endpoint_id}/health", headers=headers)
    return resp.json()


def wait_for_ready(api_key, endpoint_id, timeout=600):
    """Poll endpoint health until a worker is ready."""
    print(f"\nWaiting for endpoint to become ready (timeout: {timeout}s)...")
    start = time.time()
    while time.time() - start < timeout:
        health = check_health(api_key, endpoint_id)
        workers = health.get("workers", {})
        jobs = health.get("jobs", {})
        elapsed = int(time.time() - start)
        print(
            f"  [{elapsed:>3}s] workers: init={workers.get('initializing', 0)} "
            f"ready={workers.get('ready', 0)} idle={workers.get('idle', 0)} "
            f"running={workers.get('running', 0)} | "
            f"jobs: queue={jobs.get('inQueue', 0)} failed={jobs.get('failed', 0)}"
        )
        if workers.get("ready", 0) > 0 or workers.get("idle", 0) > 0:
            print("\n  Worker is ready!")
            return True
        time.sleep(15)
    print("\n  Timed out waiting for worker.")
    return False


def main():
    parser = argparse.ArgumentParser(description="Deploy Foundry to RunPod Serverless")
    parser.add_argument(
        "--name", default="foundry-qwen3-5-35b", help="Endpoint name"
    )
    parser.add_argument(
        "--template-name",
        default="foundry-qwen3.5-35b-a3b-serverless",
        help="Template name",
    )
    parser.add_argument(
        "--template-id", default=None, help="Use existing template ID (skip creation)"
    )
    parser.add_argument(
        "--workers-max", type=int, default=1, help="Max concurrent workers"
    )
    parser.add_argument(
        "--wait", action="store_true", help="Wait for endpoint to become ready"
    )
    args = parser.parse_args()

    api_key = get_api_key()

    # Create or reuse template
    if args.template_id:
        template_id = args.template_id
    else:
        template_id = create_template(api_key, args.template_name)

    # Create endpoint
    endpoint_id = create_endpoint(
        api_key, args.name, template_id, DEFAULT_GPU_IDS, args.workers_max
    )

    print(f"\n{'=' * 60}")
    print("DEPLOYMENT COMPLETE")
    print(f"{'=' * 60}")
    print(f"Endpoint ID:  {endpoint_id}")
    print(f"Endpoint URL: {HEALTH_URL}/{endpoint_id}")
    print(f"OpenAI URL:   {HEALTH_URL}/{endpoint_id}/openai/v1")
    print(f"\nBenchmark:")
    print(f"  python scripts/benchmark.py --url {HEALTH_URL}/{endpoint_id}/openai/v1")

    if args.wait:
        wait_for_ready(api_key, endpoint_id)


if __name__ == "__main__":
    main()
