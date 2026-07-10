# Implementation Plan

[Overview]
Fix `start_auth_monitor()` in `scripts/hytale/hytale_auth.sh` to handle ARM64/QEMU timing issues by adding a readiness check that waits for the FIFO pipe and log files before attempting authentication. On ARM64 Macs, QEMU emulation overhead delays server boot beyond the current 5-second initial wait + 60-second retry window, causing auth commands to never be sent.

[Types]
No type changes needed. Shell script variables only.

[Files]
- Modify `scripts/hytale/hytale_auth.sh` — add readiness check in `start_auth_monitor()` function: increase initial sleep, extend log file search timeout, and verify FIFO pipe exists before entering the monitoring loop.

[Functions]
- **Modified:** `start_auth_monitor()` in `scripts/hytale/hytale_auth.sh` (line 89–132)
  - Increase initial sleep from 5s to 10s
  - Extend log file retry window from 30 iterations × 2s = 60s to 60 iterations × 2s = 120s
  - Add FIFO pipe readiness check: verify `/tmp/hytale-console.in` exists before entering tail loop
  - Add fallback: if no log found after retries, keep polling in background until FIFO is ready

[Classes]
None. Shell script only — no classes.

[Dependencies]
No new dependencies. Uses only `sleep`, `seq`, `tail`, and shell builtins already available.

[Testing]
- Build image on ARM64 Mac: `docker buildx build --platform linux/arm64 -t hytale-arm64 -f Dockerfile.ubuntu .`
- Run container and verify auth monitor starts without errors
- Check that `/tmp/hytale-console.in` FIFO is created
- Verify log files appear in `/home/container/Server/logs/`
- Confirm authentication commands are sent when expected patterns match

[Implementation Order]
1. Read `scripts/hytale/hytale_auth.sh` current state for exact context
2. Modify `start_auth_monitor()` function: increase initial sleep to 10s, extend retry loop to 60 iterations, add FIFO readiness check before tail loop
3. Verify syntax with `sh -n scripts/hytale/hytale_auth.sh`
