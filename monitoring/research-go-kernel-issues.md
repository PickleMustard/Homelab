# Research: Go Runtime and Linux Kernel Compatibility Issues

**Date:** February 16, 2026
**Topic:** Known issues between Linux kernel 6.x series and Go runtime causing stack corruption/traceback errors

---

## Summary

This research documents known issues between Go runtime and Linux kernels (particularly the 6.x series) that can cause "fatal error: traceback did not unwind completely" and similar stack corruption issues. It also covers RHEL 10 container workload issues and k3s compatibility concerns.

---

## 1. Go Runtime "traceback did not unwind completely" Issues

### Primary Issues Identified

#### Issue #62326: "traceback did not unwind completely"
- **URL:** https://github.com/golang/go/issues/62326
- **Status:** Closed (Fixed in Go 1.21.2)
- **Affected Versions:** Go 1.21.0
- **Root Cause:** Bug introduced by the new unwinder implementation (commit: https://go-review.googlesource.com/c/go/+/458218)
- **Trigger:** Assembly functions that modify SP when growing the stack or being preempted for GC
- **Fix:** Backported to Go 1.21.2 via issue #62464

#### Issue #64781: "rare stack corruption on Go 1.20 and later"
- **URL:** https://github.com/golang/go/issues/64781
- **Status:** Closed (completed December 2025)
- **Affected Versions:** Go 1.20.x and later
- **Reporter:** MinIO team (klauspost)
- **Symptoms:**
  - `fatal error: unexpected signal during runtime execution`
  - `fatal error: bulkBarrierPreWrite: unaligned arguments`
  - `fatal error: index out of range`
  - `fatal: bad g in signal handler`
  - `runtime: pointer to unallocated span`
  - `fatal error: found bad pointer in Go heap`
- **Workaround:** Using Go 1.19.x compiled binary resolved issues
- **Related Project:** Thanos (issue #6942)
- **Trigger:** Compression operations in `github.com/klauspost/compress/s2` library

#### Issue #69389: "traceback did not unwind completely" during preempt
- **URL:** https://github.com/golang/go/issues/69389
- **Status:** Open (as of research date)
- **Platform:** NetBSD/arm64
- **Context:** Occurs during strings_test init with GC preemption

#### Issue #71144: "traceback did not unwind completely" in debugCall
- **URL:** https://github.com/golang/go/issues/71144
- **Status:** Closed (not planned)
- **Affected:** Go 1.23.0+ on macOS/amd64
- **Trigger:** Debugger Evaluate Expression functionality
- **Note:** This is a debugger-specific issue, not production runtime

### Key Technical Details

The "traceback did not unwind completely" error occurs when:

1. **Assembly Functions with Large Stack Usage:** Functions that use significant stack space (e.g., compression libraries using lookup tables on stack)
2. **Stack Growth During Preemption:** When a goroutine is preempted during GC while its stack is being grown
3. **SP Modification:** Assembly code that modifies the stack pointer (SP) in ways the runtime doesn't expect

### Recommended Fixes/Workarounds

1. **Upgrade Go:** Use Go 1.21.2+ which includes the traceback unwinder fix
2. **Reduce Stack Usage in Assembly:** Avoid large stack allocations in assembly functions
3. **Use Go 1.19.x:** For critical systems, sticking with Go 1.19.x avoids these issues entirely
4. **Avoid Compression in Hot Paths:** The klauspost/compress library's assembly implementations have been known triggers

---

## 2. Thanos/MinIO Related Issues (Real-World Impact)

### Thanos Issue #6942: Receive Panic
- **URL:** https://github.com/thanos-io/thanos/issues/6942
- **Environment:**
  - Thanos 0.32.4/0.32.5
  - Go 1.21.3
  - Alpine Linux 3.18.4
  - Kernel: 5.4.0-1113-aws-fips
- **Component:** Thanos Receive (RouteOnly mode)
- **Error Pattern:**
  ```
  runtime: g17389085: frame.sp=0xc0055cbe58 top=0xc0055cbfe0
      stack=[0xc00554c000-0xc0055cc000
  fatal error: traceback did not unwind completely
  ```
- **Trigger:** Created by `github.com/klauspost/compress/s2.(*Writer).write`
- **Resolution:** Upgrading Go version to 1.21.2+ recommended

---

## 3. RHEL 10 and Container Workload Issues

### K3s Requirements for RHEL 10
- **Source:** https://docs.k3s.io/installation/requirements
- **Requirement:** Install `kernel-modules-extra` package:
  ```bash
  sudo dnf install -y kernel-modules-extra
  ```
- **Note:** This is required for proper networking functionality

### Known RHEL/CentOS Issues (Historical)

1. **NetworkManager Bug (Pre-RHEL 8.4):**
   - Interferes with K3s networking
   - Fix: Disable nm-cloud-setup and reboot:
     ```bash
     systemctl disable nm-cloud-setup.service nm-cloud-setup.timer
     reboot
     ```

2. **Firewalld:** Recommended to disable or properly configure rules

---

## 4. Container Runtime Issues with Newer Kernels (6.x series)

### containerd Issues

#### Issue #12726: AppArmor policy disallows unix domain sockets on kernel 6.17
- **Status:** Closed (fixed)
- **Fix:** Added explicit Unix socket permissions to AppArmor profile

#### Issue #12886: AppArmor signal rule does not match stacked profile peer on kernel 6.17
- **Status:** Open
- **Impact:** Signal rules may not work correctly with stacked AppArmor profiles

#### Issue #12864: AppArmor abi/3.0 compatibility
- **Status:** Merged
- **Fix:** Explicitly set abi/3.0 in AppArmor profiles

### runc Issues

#### Issue #4968: CVE-2025-52881 - fd reopening causes AppArmor issues
- **Error:** `open sysctl net.ipv4.ip_unprivileged_port_start file: reopen fd 8: permission denied`
- **Impact:** Containers fail to start on certain configurations

#### Issue #5089: cgroup directory not found
- **Error:** `can't open cgroup: openat2 /sys/fs/cgroup/...: no such file or directory`
- **Status:** Fixed in runc 1.4.1
- **Cause:** Changes in cgroup handling with newer kernels

#### Issue #5113: RFC - Explicit kernel version requirements
- **Status:** Open
- **Context:** Discussion about documenting minimum kernel version requirements

---

## 5. K3s v1.34 and Newer Kernel Compatibility

### Current Status
- No specific issues found for k3s v1.34 with kernel 6.12
- K3s documentation doesn't list kernel 6.12 as having known issues

### Kernel Requirements
- K3s works on most modern Linux systems
- Minimum kernel versions are not explicitly documented
- Some features require newer kernels (e.g., cgroup v2, certain network features)

### Known K3s Issues with Kernels

1. **Issue #6708:** k3s-root binaries cause segmentation fault on aarch64 with 64k page size
   - Fixed in v1.26.3+k3s1

2. **Issue #7335:** 16k kernel page builds for Apple Silicon (ARM64)
   - Fixed in v1.27.2+k3s1

---

## 6. Recommendations

### For Go Applications in Containers

1. **Use Go 1.21.2 or later** - Contains critical fixes for traceback issues
2. **Test thoroughly on target kernel version** - Especially if using compression libraries or assembly code
3. **Monitor for "traceback did not unwind completely" errors** - Indicates potential Go runtime issues
4. **Consider CGO_ENABLED=0** for statically linked binaries in containers

### For K3s Deployments

1. **Install kernel-modules-extra on RHEL 10**
2. **Disable firewalld or configure proper rules**
3. **Use SSD storage for etcd** - Especially on ARM devices
4. **Ensure cgroups v2 support** if using newer kernels

### For Newer Kernel Compatibility

1. **Update containerd to latest version** - Contains AppArmor fixes for kernel 6.17+
2. **Update runc to 1.4.1+** - Contains cgroup fixes
3. **Test AppArmor profiles** - Newer kernels have stricter enforcement
4. **Monitor for permission denied errors** - May indicate AppArmor/cgroup compatibility issues

---

## 7. References

### Go Runtime Issues
- https://github.com/golang/go/issues/62326 (traceback unwinding)
- https://github.com/golang/go/issues/62464 (1.21 backport)
- https://github.com/golang/go/issues/64781 (stack corruption)
- https://github.com/golang/go/issues/69389 (preempt during strings_test)
- https://github.com/golang/go/issues/71144 (debugCall traceback)

### Container Runtime Issues
- https://github.com/containerd/containerd/issues/12726 (AppArmor unix sockets)
- https://github.com/containerd/containerd/issues/12886 (AppArmor signal rules)
- https://github.com/opencontainers/runc/issues/4968 (CVE-2025-52881)
- https://github.com/opencontainers/runc/issues/5089 (cgroup directory)
- https://github.com/opencontainers/runc/issues/5113 (kernel version requirements)

### K3s Documentation
- https://docs.k3s.io/installation/requirements

### Related Project Issues
- https://github.com/thanos-io/thanos/issues/6942 (Thanos Receive panic)
- https://github.com/klauspost/compress (Compression library triggering issues)

---

## 8. Conclusion

The "fatal error: traceback did not unwind completely" issue is primarily a Go runtime bug that was introduced in Go 1.20 and fixed in Go 1.21.2. It's triggered by assembly code that modifies the stack pointer in certain ways, particularly during GC preemption or stack growth.

For Linux kernel 6.12 specifically, no direct incompatibility issues were found with Go runtime. However, newer kernels (6.17+) have stricter AppArmor enforcement that affects containerd and runc, requiring profile updates.

For RHEL 10, the main requirement is installing the `kernel-modules-extra` package for proper K3s networking functionality.

**Primary Recommendation:** Ensure Go 1.21.2+ is used for any containerized Go applications to avoid the traceback unwinding issues.
