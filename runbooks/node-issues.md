# Runbook: EKS Node Issues (NotReady / Insufficient Resources)

## Trigger
- Alert: Node in NotReady state
- Alert: Pods in Pending state due to insufficient resources
- Severity: P1

## Diagnostic Steps

### Step 1: Check node status
```bash
kubectl get nodes -o wide
kubectl describe node <NODE_NAME>
```
Look for:
- `NotReady` condition
- `MemoryPressure`, `DiskPressure`, `PIDPressure` conditions
- Taints that prevent scheduling

### Step 2: Check node resource usage
```bash
kubectl top nodes
kubectl describe node <NODE_NAME> | grep -A 20 "Allocated resources"
```

### Step 3: Check for Spot interruptions (if using SPOT instances)
```bash
kubectl get events --all-namespaces --field-selector reason=SpotInterruption
```

### Step 4: Check ASG activity
```bash
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name <EKS_NODE_GROUP_ASG> \
  --max-items 10
```

## Remediation

### Spot interruption
- EKS Managed Node Groups handle Spot replacement automatically
- New node should launch within 2-5 minutes
- **Verify**: `kubectl get nodes` shows a new node joining

### Node out of resources
- Pods are pending because the node cannot fit them
```bash
kubectl scale deployment/cobalt-core-service --replicas=1 -n cobalt-services
```
- If running on single t4g.medium (4GB RAM), services may be too large
- Consider increasing node count or instance size

### Node NotReady (unknown cause)
- If node is in NotReady for > 10 minutes:
```bash
# Cordon the node to prevent new scheduling
kubectl cordon <NODE_NAME>
# Drain workloads to other nodes
kubectl drain <NODE_NAME> --ignore-daemonsets --delete-emptydir-data
```
- The ASG should replace the node

## Escalation
- If all nodes are NotReady: cluster-wide outage, P1
- If single node and pods rescheduled: monitor, P3
