# CI Benchmark (CPU) – Helm Chart

This chart deploys a **one-shot Kubernetes Job** that runs the Buildkite performance benchmark script in:
`public.ecr.aws/q9t5s3a7/vllm-ci-test-repo:<tag>`.

**Important:** The Job/Pod/container names avoid substring `vllm` so that NRI balloons policy can treat
it as a non-vLLM workload and place it on **reserved CPUs**.
## Prerequisites

### Kubernetes
- Existing Kubernetes cluster
- NRI Resource Policy **balloons** enabled (Enterprise Inference setup)

### Node requirements
The Job uses `hostPath`. The following **must exist on any node where the Job may run**:

| Purpose | Path (default) |
|------|------|
| HF cache | `/mnt/hf_cache` |
| Results output | `/mnt/ci_bench_results` |

Create them if needed:

```bash
sudo mkdir -p /mnt/hf_cache /mnt/ci_bench_results 
sudo chown -R 1000:1000 /mnt/ci_bench_results
```

## HostPath persistence

- HF cache directory on node: `/mnt/hf_cache` (mounted to `/mnt/hf_cache`)
- Results directory on node: `hostPaths.results` (default `/mnt/ci_bench_results`) mounted to `/workspace/benchmarks/results`

## Embed `serving-tests-cpu.json` 
vLLM Benchmark Suite will use the serving-tests-cpu.json in github folder instead of default one in docker instance.  
serving-tests-cpu.json is embedded into a ConfigMap.  
Any modification to the local serving-tests-cpu.json will be used in the benchmarking.

## Run Benchmark 
```bash
cd core/helm-charts/vllm-benchmark
source set-env.sh
helm install ci-bench ./ \
  --set env.REMOTE_HOST="$REMOTE_HOST" \
  --set env.REMOTE_PORT="$REMOTE_PORT" \
  --set env.HF_TOKEN="$HF_TOKEN" \
  --set env.ON_CPU=1 \
  --set hostPaths.results=/mnt/ci_bench_results \
  --set-file servingTestsJson=./serving-tests-cpu.json
```

## Logs

```bash
kubectl logs -l app.kubernetes.io/name=ci-benchmark-cpu --all-containers
```

## Get results

Results persist on the node at:

- `/mnt/ci_bench_results`

List them (on the node):

```bash
ls -lah /mnt/ci_bench_results
```
