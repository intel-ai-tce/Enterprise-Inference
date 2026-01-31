# CI Benchmark (CPU) – Helm Chart

This chart deploys a **one-shot Kubernetes Job** that runs the Buildkite performance benchmark script in:
`public.ecr.aws/q9t5s3a7/vllm-ci-test-repo:<tag>`.

**Important:** The Job/Pod/container names avoid substring `vllm` so that NRI balloons policy can treat
it as a non-vLLM workload and place it on **reserved CPUs**.

## HostPath persistence

- HF cache directory on node: `/mnt/hf_cache` (mounted to `/mnt/hf_cache`)
- Results directory on node: `hostPaths.results` (default `/mnt/ci_bench_results`) mounted to `/workspace/benchmarks/results`

## Embed `serving-tests-cpu.json` (no /mnt/bench_cfg needed)

The file is embedded into a ConfigMap.

Recommended install pattern (pull JSON from your local repo):

```bash
export REMOTE_HOST=10.233.45.251
export REMOTE_PORT=80

helm install ci-bench ./ci-benchmark-chart \
  --set env.REMOTE_HOST="$REMOTE_HOST" \
  --set env.REMOTE_PORT="$REMOTE_PORT" \
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
