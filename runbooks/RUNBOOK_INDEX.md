# Cobalt Platform — Operational Runbooks

These runbooks are used by both human operators and the Claude AI incident response agent.
Each runbook follows a decision-tree format with exact commands and verification steps.

## Alert → Runbook Mapping

| Alert | Severity | Runbook | Auto-Remediation |
|-------|----------|---------|------------------|
| API 5xx rate > 5% | P1 | [high-error-rate.md](high-error-rate.md) | No |
| Pod CrashLoopBackOff | P1 | [pod-crash.md](pod-crash.md) | No |
| RDS CPU > 80% | P2 | [database-pressure.md](database-pressure.md) | No |
| RDS connections > 80% | P2 | [database-pressure.md](database-pressure.md) | No |
| OOMKilled pod | P2 | [pod-crash.md](pod-crash.md) | No |
| Node NotReady | P1 | [node-issues.md](node-issues.md) | No |
| Certificate expiry < 30d | P3 | [certificate-expiry.md](certificate-expiry.md) | No |
| Deployment failed | P2 | [deployment-failure.md](deployment-failure.md) | Rollback |

## Investigation Protocol

When investigating any incident, follow this order:
1. **Scope**: Which services/tenants are affected?
2. **Timeline**: When did it start? Was there a recent deployment?
3. **Logs**: Check structured logs for errors (filter by service, tenant, time)
4. **Pods**: Check pod status, restarts, events
5. **Metrics**: Check CPU, memory, connections, latency
6. **Correlate**: Match timeline with deployments, config changes, traffic spikes
7. **Diagnose**: Identify root cause from evidence
8. **Remediate**: Propose fix (never auto-execute destructive actions)
9. **Verify**: Confirm fix resolved the issue

## Common Axiom Queries

```apl
# All errors in last hour
['cobalt-prod'] | where level == 'ERROR' | sort by _time desc | take 100

# Errors for a specific service
['cobalt-prod'] | where kubernetes.labels.app == 'cobalt-core-service' and level == 'ERROR' | sort by _time desc

# Errors for a specific tenant
['cobalt-prod'] | where tenantId == '<TENANT_ID>' and level == 'ERROR' | sort by _time desc

# Trace a request
['cobalt-prod'] | where requestId == '<REQUEST_ID>' | sort by _time asc

# Error rate over time
['cobalt-prod'] | where level == 'ERROR' | summarize count() by bin(_time, 5m)

# Slow requests (if response time is logged)
['cobalt-prod'] | where duration > 2000 | sort by duration desc | take 50
```

## Common kubectl Commands

```bash
# Pod status
kubectl get pods -n cobalt-services -o wide

# Recent events (sorted)
kubectl get events -n cobalt-services --sort-by=.lastTimestamp | tail -30

# Pod logs (last 100 lines)
kubectl logs deployment/cobalt-core-service -n cobalt-services --tail=100

# Previous crashed container logs
kubectl logs <pod-name> -n cobalt-services --previous

# Describe failing pod
kubectl describe pod <pod-name> -n cobalt-services

# Resource usage
kubectl top pods -n cobalt-services

# Recent deployments
kubectl get deployments -n cobalt-services -o wide
```
