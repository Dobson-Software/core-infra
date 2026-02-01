# Runbook: Deployment Failure

## Trigger
- Alert: GitHub Actions deploy workflow failed
- Alert: Kubernetes rollout not progressing
- Severity: P2

## Diagnostic Steps

### Step 1: Check deployment status
```bash
kubectl rollout status deployment/cobalt-<SERVICE> -n cobalt-services
kubectl get deployment cobalt-<SERVICE> -n cobalt-services -o yaml
```

### Step 2: Check for failed pods
```bash
kubectl get pods -n cobalt-services -l app=cobalt-<SERVICE> --sort-by=.metadata.creationTimestamp
kubectl describe pod <NEWEST_POD> -n cobalt-services
```

### Step 3: Check new pod logs
```bash
kubectl logs <NEWEST_POD> -n cobalt-services --tail=200
```

Common failure causes:
- `ImagePullBackOff` → ECR image doesn't exist or IAM permissions
- Flyway migration error → SQL syntax or conflicting migration
- `ApplicationContextException` → Spring config error, missing env vars
- Health check timeout → startup too slow, increase startup probe thresholds

### Step 4: Check if blue/green deployment
```bash
kubectl get deployments -n cobalt-services | grep green
```
If green deployments exist, the promotion pipeline was in progress.

## Remediation

### Rollback
```bash
kubectl rollout undo deployment/cobalt-<SERVICE> -n cobalt-services
kubectl rollout status deployment/cobalt-<SERVICE> -n cobalt-services --timeout=120s
```

### Clean up stuck green deployments
```bash
for svc in core-service notification-service violations-service frontend; do
  kubectl delete deployment "cobalt-${svc}-green" -n cobalt-services --ignore-not-found
done
```

### Image not found
- Check ECR repository for the expected tag
- Verify the build workflow completed successfully
- Check IRSA permissions for ECR pull

### Migration failure
- Check Flyway schema history for the failed migration
- Fix the SQL, apply manually, mark as resolved in Flyway
- DO NOT rollback the deployment until the migration is fixed

## Verification
```bash
kubectl rollout status deployment/cobalt-<SERVICE> -n cobalt-services
kubectl get pods -n cobalt-services -l app=cobalt-<SERVICE>
```
All pods should be Running with 0 restarts.
