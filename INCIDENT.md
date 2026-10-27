# Incident Investigation and Remediation

## Issue 1: Redis cache memory limit too small
- **Symptom:** Cache writes risk failure when Redis memory is exhausted.
- **How I found it:** Inspected `redis/redis.conf` and Redis memory/policy settings.
- **Root cause:** The original 1 MB limit and `noeviction` policy were unsuitable for a WordPress object cache.
- **Fix:** Increased the limit to 128 MB and set `allkeys-lru`. Verified effective settings. Commit: `b17cb0c`.
- **Prevention:** Monitor memory, evictions and rejected writes; tune from measured usage.

## Issue 2: SaaS app2 upstream port mismatch
- **Symptom:** Requests routed to app2 could fail.
- **How I found it:** Compared Compose application ports with `edge/nginx.conf`.
- **Root cause:** app2 listens on 3001, while the original upstream targeted 3000.
- **Fix:** Changed the upstream to `app2:3001`; Nginx config test passed and `/app` returned HTTP 200. Commit: `355d098`.
- **Prevention:** Health-check both upstreams and test each instance during deployment.

## Issue 3: WordPress HTTP 502 / FastCGI upstream mismatch
- **Symptom:** WordPress HTTPS endpoint returned HTTP 502.
- **How I found it:** Inspected `web/default.conf`, effective Nginx config and PHP-FPM listener settings.
- **Root cause:** The original Nginx FastCGI target used port 9001, while PHP-FPM was configured for port 9000.
- **Fix:** Changed `fastcgi_pass` to `wordpress:9000` and added an explicit pool listener. Nginx syntax validation passed, but the end-to-end 502 is not yet confirmed resolved. Commit: `695a8f9`.
- **Prevention:** Test the complete request path after deployment and alert on upstream errors.

## Issue 4: PHP-FPM worker capacity is constrained
- **Symptom:** Concurrent PHP requests may queue or time out under load.
- **How I found it:** Inspected `php/zz-bsf-pool.conf`.
- **Root cause:** `pm.max_children = 1` allows only one active PHP worker.
- **Fix:** Identified for remediation; no capacity change claimed. Choose the pool size using available RAM and measured concurrency.
- **Prevention:** Monitor FPM active/idle workers, queue depth, slow requests and memory.

## Issue 5: PHP memory limit may be insufficient
- **Symptom:** Large exports or memory-intensive requests may fail.
- **How I found it:** Inspected the configured PHP memory limit.
- **Root cause:** `memory_limit = 48M` may be too low for heavy operations; no specific memory-exhaustion event has yet been captured.
- **Fix:** Further evidence is needed before changing the limit. Inspect PHP errors and measure peak memory.
- **Prevention:** Monitor memory exhaustion and test exports with representative data.

## Issue 6: Redis network exposure
- **Symptom:** Redis may be reachable by hosts that should not access the cache.
- **How I found it:** Inspected `redis/redis.conf` and the Redis port mapping in Compose.
- **Root cause:** Redis uses `bind 0.0.0.0`, `protected-mode no`, and publishes port 6379 on the host.
- **Fix:** Risk identified; network exposure has not yet been remediated. Remove unnecessary host port publication and restrict Redis to the private application network; configure authentication as appropriate.
- **Prevention:** Audit exposed ports and enforce network access controls.

## Additional investigation notes
- MariaDB slow-query logging is enabled. Inspect actual slow queries and query plans before claiming a database performance root cause.
- The 256 MB InnoDB buffer pool requires workload evidence before tuning.
- The edge proxy does not explicitly pass `X-Forwarded-Proto`; verify HTTPS detection through the full proxy chain before changing WordPress URL settings.
- Suspected risks are distinguished from confirmed, fixed incidents.
