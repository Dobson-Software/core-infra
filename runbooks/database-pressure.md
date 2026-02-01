# Runbook: Database Pressure (High CPU / Connection Exhaustion)

## Trigger
- Alert: RDS CPU > 80% for 15 minutes
- Alert: RDS connections > 80% of max
- Severity: P2

## Diagnostic Steps

### Step 1: Check current database metrics
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=cobalt-prod \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 --statistics Average

aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=cobalt-prod \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 --statistics Average
```

### Step 2: Check for long-running queries
- Connect to RDS via kubectl port-forward or bastion
```sql
SELECT pid, now() - pg_stat_activity.query_start AS duration, query, state
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC
LIMIT 20;
```

### Step 3: Check connection pool usage
```apl
['cobalt-prod'] | search 'HikariPool' | sort by _time desc | take 20
```

### Step 4: Check for traffic spikes
```apl
['cobalt-prod'] | summarize count() by bin(_time, 1m) | sort by _time desc | take 30
```

## Remediation

### High CPU from slow queries
- Identify and kill the long-running query:
```sql
SELECT pg_cancel_backend(<pid>);
```
- **Follow-up**: Add missing indexes, optimize the query

### Connection exhaustion
- Rolling restart to reset connection pools:
```bash
kubectl rollout restart deployment/cobalt-core-service -n cobalt-services
```
- Check HikariCP max pool size (default 10 per pod, review if adequate)
- **Follow-up**: Look for connection leaks (transactions not committed/rolled back)

### Traffic spike
- Scale up application pods:
```bash
kubectl scale deployment/cobalt-core-service --replicas=3 -n cobalt-services
```
- Monitor if the spike is legitimate or an attack (check WAF logs)

## Escalation
- If CPU sustained > 95%: consider RDS instance resize (requires downtime for single-AZ)
- If connections maxed and restart doesn't help: check for connection leak in code
