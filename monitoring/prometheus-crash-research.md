# Prometheus v3.9.1 Crash Issues Research

**Research Date:** 2026-02-16
**Issue Focus:** Crashes with "traceback did not unwind completely" and "internal/poll.(*FD).Fstat" panic at startup, plus TSDB corruption issues

---

## Summary of Findings

This research covers known issues with Prometheus v3.9.x causing crashes, including Go runtime errors like "traceback did not unwind completely" and TSDB/storage corruption issues.

---

## 1. Prometheus v3.9.0/v3.9.1 Agent Crash (BUGFIX)

### GitHub Issue: [#17800](https://github.com/prometheus/prometheus/issues/17800)

**Status:** Fixed in v3.9.1

**Description:**
Prometheus Agent crashes shortly after startup when upgrading to v3.9.0. The error:
```
panic: interface conversion: *agent.appenderBase is not storage.Appender: missing method Append
```

**Root Cause:**
Invalid type of object in the Agent code path.

**Solution:**
Upgrade to **Prometheus v3.9.1** which includes the fix from PR [#17802](https://github.com/prometheus/prometheus/pull/17802).

**v3.9.1 Changelog:**
- [BUGFIX] Agent: fix crash shortly after startup from invalid type of object. #17802
- [BUGFIX] Scraping: fix relabel keep/drop not working. #17807

**Source:** https://github.com/prometheus/prometheus/releases/tag/v3.9.1

---

## 2. Go Runtime: "fatal error: traceback did not unwind completely"

This error is a **Go runtime issue**, not specific to Prometheus, but can affect Prometheus since it's written in Go.

### Related Go Issues:

#### Issue [#62326](https://github.com/golang/go/issues/62326) - Go 1.21.0
**Description:** `fatal error: traceback did not unwind completely`
**Root Cause:** Introduced by the unwinder commit in Go 1.21 (CL 458218)
**Status:** Closed (fixed in Go 1.21.2 backport - Issue #62464)

#### Issue [#64781](https://github.com/golang/go/issues/64781) - Go 1.20 and later
**Description:** Rare stack corruption on Go 1.20 and later
**Symptoms:**
- `fatal error: unexpected signal during runtime execution`
- `fatal error: bulkBarrierPreWrite: unaligned arguments`
- `runtime: pointer to unallocated span`
- `fatal error: found bad pointer in Go heap`

**Root Cause:** Stack corruption issues introduced in Go 1.20 that can manifest in various ways including traceback errors. Often related to assembly code functions with large stack allocations.

**Status:** Closed (completed Dec 2025)

#### Other Related Go Issues:
- [#62464](https://github.com/golang/go/issues/62464) - 1.21 backport for traceback issue
- [#69629](https://github.com/golang/go/issues/69629) - fpTracebackPartialExpand SIGSEGV with deep inlining
- [#76614](https://github.com/golang/go/issues/76614) - Windows Server 2025 app crashes with various errors

### Solutions for Go Runtime Issues:
1. **Upgrade Go version** - Many issues were fixed in Go 1.21.2+, 1.22+, and later versions
2. **Check for assembly code** - If using custom assembly, verify stack frame handling
3. **Test on different Go versions** - Try Go 1.19.x if crashes persist on 1.20+
4. **Report to Go team** - If issue is reproducible

---

## 3. TSDB Corruption Issues

### Issue [#16074](https://github.com/prometheus/prometheus/issues/16074) - WAL Truncation Failure

**Description:**
WAL truncation fails with "unexpected non-zero byte in padded page" error, causing corrupt database and data loss.

**Symptoms:**
- WAL compaction starts failing and keeps failing
- WAL folder keeps growing indefinitely
- After restart, Prometheus deletes all segments before the corrupted one

**Prometheus Version Affected:** 3.1.0 (and likely others)

**Workaround:**
Remove corrupted WAL segments, accepting data loss for that time range.

---

### Issue [#7397](https://github.com/prometheus/prometheus/issues/7397) - Invalid Magic Number

**Description:**
`tsdb.Open fails with invalid magic number 0` when running with reverted previously mmaped chunks

**Cause:** Compatibility issue when downgrading Prometheus versions after mmap chunks feature was used

**Symptoms:**
```
level=error msg="failed to open tsdb" err="invalid magic number 0"
```

---

### Issue [#4705](https://github.com/prometheus/prometheus/issues/4705) - WAL Corruption Handling

**Description:**
WAL requires more robust corruption handling

**Symptoms:**
```
err="opening storage failed: read WAL: repair corrupted WAL: cannot handle error: invalid record type 255"
```

**Solution:** Improved WAL corruption handling was implemented in the TSDB.

---

## 4. TSDB Recovery Procedures

### From Official Prometheus Documentation:

> "If your local storage becomes corrupted to the point where Prometheus will not start it is recommended to backup the storage directory and restore the corrupted block directories from your backups. If you do not have backups the last resort is to remove the corrupted files. For example you can try removing individual block directories or the write-ahead-log (WAL) files. Note that this means losing the data for the time range those blocks or WAL covers."

### Recovery Steps:

1. **Backup First:**
   ```bash
   cp -r /prometheus-data /prometheus-data-backup
   ```

2. **Try removing WAL files:**
   ```bash
   rm -rf /prometheus-data/wal/*
   rm -rf /prometheus-data/chunks_head/*
   ```

3. **If still failing, remove corrupted block directories:**
   - Identify corrupted blocks by checking logs for specific block IDs
   - Remove the corrupted block directory

4. **Use promtool for diagnostics:**
   ```bash
   promtool tsdb analyze <data-dir>
   ```

### Important Notes:
- Non-POSIX compliant filesystems (NFS, AWS EFS) are NOT supported and can cause unrecoverable corruption
- Always use local filesystems for Prometheus storage
- Snapshots are recommended for backups

---

## 5. internal/poll.(*FD).Fstat Panic

No direct matches were found for this specific error pattern in Prometheus or Go issue trackers. This error typically indicates:

1. **File descriptor issues** - Could be related to:
   - Running out of file descriptors
   - Race conditions in file access
   - Corrupted storage backend

2. **Potential causes:**
   - Network storage issues (NFS)
   - Disk I/O errors
   - Container/storage driver problems in Kubernetes

3. **Debugging steps:**
   - Check `ulimit -n` for file descriptor limits
   - Review disk health
   - Check dmesg/kernel logs for I/O errors
   - Verify storage class and filesystem type (must be POSIX-compliant)

---

## 6. Recommended Actions

### Immediate Actions:
1. **Upgrade to Prometheus v3.9.1** if using v3.9.0 to fix the Agent crash bug
2. **Check storage backend** - Ensure using local POSIX-compliant filesystem
3. **Backup data** before attempting any recovery

### If Experiencing "traceback did not unwind completely":
1. Check the Go version Prometheus was compiled with (`prometheus --version`)
2. If using Prometheus built with Go 1.20-1.21.1, try upgrading to a version built with Go 1.21.2+
3. Check for memory issues (run memtest, check ECC memory logs)

### If Experiencing TSDB Corruption:
1. Stop Prometheus immediately
2. Backup the data directory
3. Try removing WAL directory
4. If still failing, identify and remove corrupted blocks
5. Consider enabling `--storage.tsdb.wal-compression` for better reliability

### For Kubernetes/k3s Deployments:
1. Ensure PVC uses local-path or similar local storage class
2. Avoid NFS or network-based storage
3. Set appropriate resource limits
4. Check for OOMKill events

---

## Source References

- Prometheus v3.9.1 Release: https://github.com/prometheus/prometheus/releases/tag/v3.9.1
- Issue #17800 (Agent crash): https://github.com/prometheus/prometheus/issues/17800
- Go Issue #62326 (traceback): https://github.com/golang/go/issues/62326
- Go Issue #64781 (stack corruption): https://github.com/golang/go/issues/64781
- Issue #16074 (WAL corruption): https://github.com/prometheus/prometheus/issues/16074
- Issue #7397 (magic number): https://github.com/prometheus/prometheus/issues/7397
- Issue #4705 (WAL handling): https://github.com/prometheus/prometheus/issues/4705
- Prometheus Storage Documentation: https://prometheus.io/docs/prometheus/latest/storage/

---

## Changelog

| Date | Change |
|------|--------|
| 2026-02-16 | Initial research compiled |
