# Runbook: Pod CrashLoopBackOff / OOMKilled

## Trigger
- Alert: Pod in CrashLoopBackOff state for > 5 minutes
- Alert: Pod OOMKilled
- Severity: P1 (if affects service availability), P2 (if replicas cover)

## Diagnostic Steps

### Step 1: Identify the failing pod
```bash
kubectl get pods -n cobalt-services | grep -E 'CrashLoopBackOff|Error|OOMKilled'
```

### Step 2: Check pod events
```bash
kubectl describe pod <POD_NAME> -n cobalt-services
```
Look for:
- `OOMKilled` → memory limit exceeded
- `Error` in last state → application crash
- `FailedScheduling` → insufficient resources on node
- `ImagePullBackOff` → ECR image not found

### Step 3: Check previous container logs
```bash
kubectl logs <POD_NAME> -n cobalt-services --previous --tail=200
```
Look for:
- Java stack traces (application bug)
- `java.lang.OutOfMemoryError` (heap exhaustion)
- `Flyway migration failed` (database schema issue)
- `Connection refused` (dependency not ready)
- `Bean creation exception` (Spring context failure)

### Step 4: Check if other pods in same deployment are healthy
```bash
kubectl get pods -n cobalt-services -l app=cobalt-<SERVICE> -o wide
```

## Remediation

### OOMKilled
- The pod exceeded its memory limit
- Check if this is a memory leak or if the limit is too low
```bash
kubectl top pods -n cobalt-services
```
- **Short-term**: If all replicas are affected, edit the deployment to increase memory limit
- **Long-term**: Profile the application for memory leaks

### Application Crash (Stack Trace)
- If caused by a recent deployment: rollback
```bash
kubectl rollout undo deployment/cobalt-<SERVICE> -n cobalt-services
```
- If not deployment-related: check for data-dependent bugs, create GitHub issue

### Flyway Migration Failure
- The service cannot start because a database migration failed
- **DO NOT** roll back the deployment — the migration is already partially applied
- Check the Flyway schema history table:
```sql
SELECT * FROM <schema>.flyway_schema_history ORDER BY installed_rank DESC LIMIT 5;
```
- Fix the migration, apply manually, then restart the pod

### Dependency Not Ready
- Check if the dependent service (database, other services) is healthy
- Pods have startup probes that allow 150 seconds (30 × 5s) for dependencies to become ready
- If the dependency is permanently down, fix the dependency first

## Escalation
- If multiple services are in CrashLoopBackOff: P1 incident
- If only one pod and replicas cover: monitor for 30 minutes, P2
