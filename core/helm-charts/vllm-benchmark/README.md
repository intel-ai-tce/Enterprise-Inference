# CI Benchmark (CPU) – Helm Chart

This Helm chart deploys a **one-shot Kubernetes Job** that runs the Buildkite
performance benchmark script inside the container image:

```
public.ecr.aws/q9t5s3a7/vllm-ci-test-repo:<tag>
```

The Job is intentionally **not named with `vllm`** so that, when using the
**NRI balloons policy**, it is treated as a **non-vLLM workload** and scheduled
onto **reserved CPUs** rather than dedicated vLLM CPU balloons.

---

## What this chart does

- Runs a **single benchmark execution** (Job, not Deployment)
- Uses **hostPath volumes** to:
  - reuse HuggingFace cache
  - persist benchmark results on the node
- Allocates **large shared memory** (`/dev/shm = 128Gi`)
- Exits when the benchmark finishes
- Leaves results on the host for post-processing

---

## Folder structure

```
ci-benchmark/
├── Chart.yaml
├── values.yaml
├── README.md
└── templates/
    └── job.yaml
```

> The chart or folder name may include `vllm`.  
> **Only runtime Kubernetes object names matter** for the balloons policy.

---

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
| Serving JSON | `/mnt/bench_cfg/serving-tests-cpu.json` |

Create them if needed:

```bash
sudo mkdir -p /mnt/hf_cache /mnt/ci_bench_results /mnt/bench_cfg
sudo chown -R 1000:1000 /mnt/ci_bench_results
```

---

## Configuration

Edit `values.yaml` or override via `--set`.

### Important values

```yaml
nameOverride: ci-benchmark-cpu   # MUST NOT include "vllm"

env:
  REMOTE_HOST: <vllm-service-ip>
  REMOTE_PORT: <vllm-service-port>
  ON_CPU: "1"

hostPaths:
  results: /mnt/ci_bench_results
```

---

## Deploy the benchmark Job

```bash
helm install ci-bench ./ci-benchmark \
  --set env.REMOTE_HOST=10.233.45.251 \
  --set env.REMOTE_PORT=80 \
  --set env.ON_CPU=1
```

---

## Monitor execution

### Check Job / Pod status

```bash
kubectl get jobs
kubectl get pods
```

### View logs

```bash
kubectl logs -l app.kubernetes.io/name=ci-benchmark-cpu --all-containers
```

---

## Verify CPU placement (optional but recommended)

To confirm the pod is using **reserved CPUs** (balloons policy):

```bash
POD=$(kubectl get pod \
  -l app.kubernetes.io/name=ci-benchmark-cpu \
  -o jsonpath='{.items[0].metadata.name}')

kubectl exec -it "$POD" -- cat /proc/self/status | grep Cpus_allowed_list
```

You should **not** see CPUs from vLLM dedicated balloons.

---

## Retrieve benchmark results

### Where results are written

Inside the container:
```
/workspace/benchmarks/results
```

On the Kubernetes node:
```
/mnt/ci_bench_results
```

### Access results on the node

```bash
ls -lh /mnt/ci_bench_results
```

You can archive them:

```bash
tar czf ci-benchmark-results.tar.gz /mnt/ci_bench_results
```

---

## Cleanup

Remove the Job after completion:

```bash
helm uninstall ci-bench
```

Results remain on the node (hostPath is not deleted).

---

## Design notes

- **Job, not Deployment**: benchmark is one-shot
- **hostPath**: mirrors docker-compose behavior
- **No `vllm` in names**: ensures reserved-CPU placement
- **emptyDir shm**: replaces `shm_size: 128g`
