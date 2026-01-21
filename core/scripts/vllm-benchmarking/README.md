# Benchmark Guide

This guide explains how to benchmark a deployed Enterprise Inference environment using the vLLM Benchmark Suite.

## vLLM Benchmark Suite 

[vLLM Benchmark Suite](https://docs.vllm.ai/en/latest/benchmarking/) is the native vLLM Benchmarking tools for vLLM across CPU, HPU, and XPU.
Every new vLLM commit automatically triggers performance runs on multiple platforms, and the results are published on the [vLLM Performance Dashboard](https://hud.pytorch.org/benchmark/llms?repoName=vllm-project%2Fvllm).
Users can run the same Benchmark Suite in their own environment to:

 - Benchmark a deployed Enterprise Inference service
 - Validate expected performance
 - Compare their numbers directly against those published on the dashboard

## Benchmark Enterprise Inference with vLLM Benchmark Suite

### 1. Run Benchmarks Against Your Remote Enterprise Inference Endpoint

1.0 Setup environment for docker compose
```bash
bash setup-docker-compose.sh
```
1.1 Retrieve the Enterprise Inference Service Endpoint and export vLLM Endpoint IP and Port as REMOTE_HOST and REMOTE_PORT
```bash
source set-env.sh
```
1.2 Run vLLM Benchmark Suite using docker compose with serving-test-cpu.json file

```bash
docker compose up
```

The script automatically runs all benchmark cases defined for CPU and generates output files under results folder including:
 - benchmark_results.md — human-readable summary
 - benchmark_results.json — machine-readable detailed results
 - Individual per-test JSON outputs if enabled

For more details, check [manually trigger vllm benchmark suite](https://docs.vllm.ai/en/latest/benchmarking/dashboard/#manually-trigger-the-benchmark)


### 2. (OPTIONAL) Obtain the latest or the specific version vLLM CI Test Image for benchmarking

To use the specific first of vLLM CI image, users need to get the image url first.
Example: download the vLLM CI CPU image for vLLM 0.11.2
```bash 
bash core/scripts/get_vllm_ci_cpu_image.sh 0.11.2
```

Expected output:

```bash 
Using tag: v0.11.2
==> Resolving tag to commit SHA...
Full SHA: 275de34170654274616082721348b7edd9741d32

✅ vLLM CI CPU image for v0.11.2:
public.ecr.aws/q9t5s3a7/vllm-ci-test-repo:275de34170654274616082721348b7edd9741d32-cpu

==> Optional: checking if image is pullable with docker manifest inspect...
Image exists and is pullable.

```

Users will get the latest CI test image if no version is passed 
```bash 
bash core/scripts/get_vllm_ci_cpu_image.sh
```

After users get the CI image url, change the image item inside the docker-compose.yml file accordingly to use that CI image.

