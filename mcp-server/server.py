"""
ZEN-OS MCP Server — Build/Test/Release orchestration
FastMCP server for automated ISO building, QEMU testing, and release management.
"""

import os
import json
import subprocess
import tempfile
import time
from pathlib import Path
from typing import Optional

from fastmcp import FastMCP

# Configuration
WORKSPACE = Path(os.environ.get("ZENOS_WORKSPACE", "/mnt/projects-ssd/ZEN-OS"))
BUILD_IMAGE = "zen-os-build:latest"
ISO_NAME = "live-image-amd64.hybrid.iso"
VNC_DISPLAY = os.environ.get("ZENOS_VNC_DISPLAY", ":2")
OVMF_CODE = "/usr/share/edk2/ovmf/OVMF_CODE.fd"
OVMF_VARS_TEMPLATE = "/usr/share/edk2/ovmf/OVMF_VARS.fd"

mcp = FastMCP(
    name="zenos-build",
    version="1.0.0",
    description="ZEN-OS ISO build, test, and release orchestration",
)


# ============================================================
# BUILD TOOLS
# ============================================================

@mcp.tool()
def build_iso(
    clean: bool = True,
    timeout_minutes: int = 60,
) -> dict:
    """Build ZEN-OS ISO using Docker container.
    
    Args:
        clean: Remove build artifacts before building
        timeout_minutes: Maximum build time in minutes
    
    Returns:
        Build result with ISO path, size, duration, and status
    """
    container_name = f"zenos-build-{int(time.time())}"
    iso_path = WORKSPACE / ISO_NAME
    
    # Clean build artifacts
    if clean:
        for d in ["binary", "chroot", "bootstrap", "common", "source", "build", "cache", "local"]:
            p = WORKSPACE / "config" / d
            if p.exists():
                subprocess.run(["rm", "-rf", str(p)], check=False)
        for f in WORKSPACE.glob("build*.log"):
            f.unlink()
    
    # Remove existing container
    subprocess.run(["docker", "rm", "-f", container_name], 
                   capture_output=True, check=False)
    
    # Start build
    start_time = time.time()
    result = subprocess.run(
        [
            "docker", "run", "--name", container_name,
            "--privileged",
            "-v", f"{WORKSPACE}:/build",
            "-w", "/build",
            BUILD_IMAGE,
            "bash", "scripts/build.sh",
        ],
        capture_output=True,
        text=True,
        timeout=timeout_minutes * 60,
    )
    duration = time.time() - start_time
    
    # Get build log
    log_result = subprocess.run(
        ["docker", "logs", container_name],
        capture_output=True, text=True, check=False,
    )
    
    # Parse result
    success = result.returncode == 0
    iso_size_gb = 0
    if iso_path.exists():
        iso_size_gb = round(iso_path.stat().st_size / (1024**3), 2)
    
    # Extract log lines
    log_lines = log_result.stdout.split("\n") + log_result.stderr.split("\n")
    error_lines = [
        l for l in log_lines 
        if "E: " in l or "FAILED" in l or "error" in l.lower()
        and "W: Download" not in l and "W: mdadm" not in l
    ]
    
    # Cleanup container
    subprocess.run(["docker", "rm", container_name], 
                   capture_output=True, check=False)
    
    return {
        "status": "success" if success else "failed",
        "iso_path": str(iso_path) if iso_path.exists() else None,
        "iso_size_gb": iso_size_gb,
        "duration_seconds": round(duration),
        "duration_minutes": round(duration / 60, 1),
        "errors": error_lines[-10:] if error_lines else [],
        "log_tail": log_lines[-5:],
    }


@mcp.tool()
def get_build_status() -> dict:
    """Check if a build is currently running.
    
    Returns:
        Current build status with container info
    """
    result = subprocess.run(
        ["docker", "ps", "--filter", "name=zenos-build", "--format", "{{.Names}}\t{{.Status}}"],
        capture_output=True, text=True, check=False,
    )
    
    containers = []
    for line in result.stdout.strip().split("\n"):
        if line:
            parts = line.split("\t")
            containers.append({
                "name": parts[0] if len(parts) > 0 else "unknown",
                "status": parts[1] if len(parts) > 1 else "unknown",
            })
    
    iso_path = WORKSPACE / ISO_NAME
    iso_info = {}
    if iso_path.exists():
        stat = iso_path.stat()
        iso_info = {
            "path": str(iso_path),
            "size_gb": round(stat.st_size / (1024**3), 2),
            "modified": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(stat.st_mtime)),
        }
    
    return {
        "running_builds": containers,
        "iso": iso_info,
    }


# ============================================================
# TEST TOOLS
# ============================================================

@mcp.tool()
def boot_test_iso(
    ram_mb: int = 2048,
    cpus: int = 2,
    timeout_seconds: int = 120,
) -> dict:
    """Boot the ISO in QEMU and verify desktop loads.
    
    Args:
        ram_mb: RAM allocation in MB
        cpus: Number of CPU cores
        timeout_seconds: Maximum wait time for boot
    
    Returns:
        Boot test results with serial output and screenshot analysis
    """
    iso_path = WORKSPACE / ISO_NAME
    if not iso_path.exists():
        return {"status": "error", "message": f"ISO not found: {iso_path}"}
    
    # Prepare OVMF
    ovmf_vars = Path(tempfile.mktemp(suffix=".fd", prefix="zenos-ovmf-"))
    subprocess.run(["cp", OVMF_VARS_TEMPLATE, str(ovmf_vars)], check=True)
    
    serial_log = Path(tempfile.mktemp(suffix=".log", prefix="zenos-serial-"))
    screenshot_path = Path(tempfile.mktemp(suffix=".png", prefix="zenos-screen-"))
    
    # Kill existing test VM
    subprocess.run(["systemctl", "--user", "stop", "zenos-mcp-test"],
                   capture_output=True, check=False)
    
    # Launch QEMU
    unit_name = "zenos-mcp-test"
    subprocess.run(
        [
            "systemd-run", "--user", f"--unit={unit_name}",
            "/usr/bin/qemu-system-x86_64",
            "-enable-kvm", f"-smp", str(cpus), f"-m", str(ram_mb),
            "-drive", f"if=pflash,format=raw,readonly=on,file={OVMF_CODE}",
            "-drive", f"if=pflash,format=raw,file={ovmf_vars}",
            "-drive", f"file={iso_path},media=cdrom,readonly=on",
            "-boot", "d",
            "-netdev", "user,id=net0", "-device", "virtio-net-pci,netdev=net0",
            "-serial", f"file={serial_log}",
            "-display", "none", "-vga", "virtio", "-vnc", VNC_DISPLAY,
        ],
        capture_output=True, text=True, check=True,
    )
    
    # Wait for boot
    time.sleep(min(timeout_seconds, 90))
    
    # Send Enter to trigger auto-login
    vncdo_result = subprocess.run(
        ["vncdo", "-s", f"localhost{VNC_DISPLAY}", "key", "enter"],
        capture_output=True, text=True, check=False,
    )
    time.sleep(30)
    
    # Capture screenshot
    subprocess.run(
        ["vncdo", "-s", f"localhost{VNC_DISPLAY}", "capture", str(screenshot_path)],
        capture_output=True, text=True, check=False,
    )
    
    # Analyze screenshot
    analysis = _analyze_screenshot(screenshot_path)
    
    # Parse serial log
    serial_content = ""
    if serial_log.exists():
        serial_content = serial_log.read_text(errors="replace")[-2000:]
    
    # Stop VM
    subprocess.run(["systemctl", "--user", "stop", unit_name],
                   capture_output=True, check=False)
    
    # Cleanup
    ovmf_vars.unlink(missing_ok=True)
    serial_log.unlink(missing_ok=True)
    screenshot_path.unlink(missing_ok=True)
    
    return {
        "status": "desktop_detected" if analysis.get("has_desktop") else "boot_incomplete",
        "serial_tail": serial_content[-500:],
        "screenshot_analysis": analysis,
    }


def _analyze_screenshot(image_path: Path) -> dict:
    """Analyze a screenshot for desktop indicators."""
    try:
        from PIL import Image
        import numpy as np
        
        img = Image.open(image_path)
        arr = np.array(img)
        h, w = arr.shape[:2]
        
        # Non-black pixels
        nonblack = int((arr.mean(axis=2) > 10).sum())
        total = h * w
        
        # Teal pixels (ZEN-OS wallpaper)
        teal = int(((arr[:,:,1] > 80) & (arr[:,:,2] > 80) & (arr[:,:,0] < 100)).sum())
        
        # Dark panel at bottom (KDE taskbar)
        panel = arr[h-50:h, :]
        panel_dark = int((panel.mean(axis=2) < 80).sum())
        panel_total = panel.shape[0] * panel.shape[1]
        
        has_desktop = (
            nonblack > total * 0.5 and 
            panel_dark / panel_total > 0.5
        )
        has_wallpaper = teal > total * 0.05
        
        return {
            "size": f"{w}x{h}",
            "mean_brightness": round(float(arr.mean()), 1),
            "nonblack_pct": round(100 * nonblack / total, 1),
            "teal_pct": round(100 * teal / total, 1),
            "panel_dark_pct": round(100 * panel_dark / panel_total, 1),
            "has_desktop": has_desktop,
            "has_wallpaper": has_wallpaper,
        }
    except Exception as e:
        return {"error": str(e)}


@mcp.tool()
def verify_iso_packages(package_names: list[str]) -> dict:
    """Verify that specific packages are present in the ISO.
    
    Args:
        package_names: List of package names to verify
    
    Returns:
        Package presence verification results
    """
    iso_path = WORKSPACE / ISO_NAME
    if not iso_path.exists():
        return {"status": "error", "message": "ISO not found"}
    
    # Mount ISO
    mount_point = Path(tempfile.mkdtemp(prefix="zenos-verify-"))
    subprocess.run(
        ["sudo", "mount", "-o", "loop,ro", str(iso_path), str(mount_point)],
        capture_output=True, check=True,
    )
    
    squashfs = mount_point / "live" / "filesystem.squashfs"
    if not squashfs.exists():
        subprocess.run(["sudo", "umount", str(mount_point)], check=False)
        return {"status": "error", "message": "squashfs not found in ISO"}
    
    # Extract dpkg status
    extract_dir = Path(tempfile.mkdtemp(prefix="zenos-dpkg-"))
    subprocess.run(
        ["sudo", "unsquashfs", "-d", str(extract_dir), "-f", 
         str(squashfs), "var/lib/dpkg/status"],
        capture_output=True, check=True,
    )
    
    status_file = extract_dir / "var" / "lib" / "dpkg" / "status"
    status_content = status_file.read_text(errors="replace")
    
    # Parse installed packages
    installed = set()
    for line in status_content.split("\n"):
        if line.startswith("Package: "):
            installed.add(line.split(": ", 1)[1].strip())
    
    # Verify
    results = {}
    for pkg in package_names:
        results[pkg] = {
            "installed": pkg in installed,
            "status": "present" if pkg in installed else "missing",
        }
    
    # Cleanup
    subprocess.run(["sudo", "umount", str(mount_point)], check=False)
    subprocess.run(["sudo", "rm", "-rf", str(extract_dir), str(mount_point)], check=False)
    
    return {
        "status": "complete",
        "total_packages_in_iso": len(installed),
        "verified": results,
        "all_present": all(r["installed"] for r in results.values()),
    }


# ============================================================
# RELEASE TOOLS
# ============================================================

@mcp.tool()
def prepare_release(version: str, changelog: str = "") -> dict:
    """Prepare a release: tag, generate checksums, create release notes.
    
    Args:
        version: Release version (e.g., "v1.0.0")
        changelog: Release changelog text
    
    Returns:
        Release preparation results with checksums and file info
    """
    import hashlib
    
    iso_path = WORKSPACE / ISO_NAME
    if not iso_path.exists():
        return {"status": "error", "message": "ISO not found"}
    
    # Generate SHA256 checksum
    sha256 = hashlib.sha256()
    with open(iso_path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            sha256.update(chunk)
    checksum = sha256.hexdigest()
    
    # Write checksum file
    checksum_file = WORKSPACE / f"{ISO_NAME}.sha256"
    checksum_file.write_text(f"{checksum}  {ISO_NAME}\n")
    
    # Generate release notes
    iso_size = iso_path.stat().st_size
    release_notes = f"""# ZEN-OS {version}

## Download
- **ISO**: `{ISO_NAME}` ({round(iso_size / (1024**3), 2)} GB)
- **SHA256**: `{checksum}`

## System Requirements
- UEFI boot (BIOS not supported for 3GB+ ISOs)
- 4 GB RAM minimum (8 GB recommended)
- 64-bit x86 processor (AMD64)
- 20 GB disk space for installation

## What's Included
- Debian Trixie base with Liquorix gaming kernel 7.0.5
- KDE Plasma desktop (X11) with ZEN-OS teal theming
- Full gaming stack: Steam, Wine 10.0, MangoHud, GameMode, DXVK
- Engineering tools: FreeCAD, KiCad, Docker, Rust, Jupyter
- First-boot wizard: NVIDIA driver install, Flatpak app selector
- Security: UFW firewall, AppArmor, automatic security updates

{changelog}
"""
    
    notes_file = WORKSPACE / f"RELEASE_NOTES_{version}.md"
    notes_file.write_text(release_notes)
    
    return {
        "status": "ready",
        "version": version,
        "iso_size_gb": round(iso_size / (1024**3), 2),
        "sha256": checksum,
        "checksum_file": str(checksum_file),
        "release_notes_file": str(notes_file),
    }


# ============================================================
# STATUS TOOLS
# ============================================================

@mcp.tool()
def get_project_status() -> dict:
    """Get comprehensive ZEN-OS project status.
    
    Returns:
        Current project status with phase completion and ISO info
    """
    iso_path = WORKSPACE / ISO_NAME
    
    iso_info = {}
    if iso_path.exists():
        stat = iso_path.stat()
        iso_info = {
            "exists": True,
            "size_gb": round(stat.st_size / (1024**3), 2),
            "modified": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(stat.st_mtime)),
        }
    else:
        iso_info = {"exists": False}
    
    # Phase completion status
    phases = {
        "phase_0_foundation": "complete",
        "phase_1_gaming": "complete",
        "phase_2_engineering": "complete",
        "phase_3_theming": "complete",
        "phase_4_security": "complete",
        "phase_5_first_boot_wizard": "complete",
        "phase_6_handheld": "complete",
        "phase_7_mcp_server": "complete",
    }
    
    # Check for config files
    config_checks = {
        "gaming_packages": (WORKSPACE / "config/package-lists/gaming-platforms.list.chroot").exists(),
        "engineering_packages": (WORKSPACE / "config/package-lists/dev-core.list.chroot").exists(),
        "grub_theme": (WORKSPACE / "config/includes.chroot/boot/grub/themes/zenos/theme.txt").exists(),
        "sddm_theme": (WORKSPACE / "config/includes.chroot/usr/share/sddm/themes/zenos-sddm/Main.qml").exists(),
        "security_sysctl": (WORKSPACE / "config/includes.chroot/etc/sysctl.d/99-security.conf").exists(),
        "first_boot_wizard": (WORKSPACE / "config/includes.chroot/usr/local/bin/zenos-first-boot").exists(),
        "handheld_setup": (WORKSPACE / "config/includes.chroot/usr/local/bin/zenos-handheld-setup").exists(),
        "mcp_server": (WORKSPACE / "mcp-server/server.py").exists(),
    }
    
    return {
        "project": "ZEN-OS",
        "iso": iso_info,
        "phases": phases,
        "config_files": config_checks,
        "workspace": str(WORKSPACE),
    }


# ============================================================
# SNAPSHOT TOOLS
# ============================================================

@mcp.tool()
def create_snapshot(name: str) -> dict:
    """Create a VM disk snapshot for repeatable testing.
    
    Args:
        name: Snapshot identifier
    
    Returns:
        Snapshot creation result
    """
    disk_path = WORKSPACE / "disks" / "zenos-test.qcow2"
    if not disk_path.exists():
        return {"status": "error", "message": "Disk not found"}
    
    result = subprocess.run(
        ["qemu-img", "snapshot", "-c", name, str(disk_path)],
        capture_output=True, text=True,
    )
    
    return {
        "status": "success" if result.returncode == 0 else "failed",
        "snapshot": name,
        "disk": str(disk_path),
    }

@mcp.tool()
def load_snapshot(name: str) -> dict:
    """Restore VM to a previous snapshot.
    
    Args:
        name: Snapshot identifier to restore
    
    Returns:
        Restore result
    """
    disk_path = WORKSPACE / "disks" / "zenos-test.qcow2"
    if not disk_path.exists():
        return {"status": "error", "message": "Disk not found"}
    
    # Stop VM first
    subprocess.run(["systemctl", "--user", "stop", "zenos-smoke"],
                   capture_output=True, check=False)
    subprocess.run(["pkill", "-f", "qemu-system.*zenos-smoke"],
                   capture_output=True, check=False)
    time.sleep(2)
    
    result = subprocess.run(
        ["qemu-img", "snapshot", "-a", name, str(disk_path)],
        capture_output=True, text=True,
    )
    
    return {
        "status": "success" if result.returncode == 0 else "failed",
        "snapshot": name,
        "disk": str(disk_path),
    }

@mcp.tool()
def list_snapshots() -> dict:
    """List all VM disk snapshots.
    
    Returns:
        Snapshot list with names and sizes
    """
    disk_path = WORKSPACE / "disks" / "zenos-test.qcow2"
    if not disk_path.exists():
        return {"status": "error", "message": "Disk not found", "snapshots": []}
    
    result = subprocess.run(
        ["qemu-img", "snapshot", "-l", str(disk_path)],
        capture_output=True, text=True,
    )
    
    snapshots = []
    for line in result.stdout.split("\n")[2:]:  # Skip header
        parts = line.split()
        if len(parts) >= 4:
            snapshots.append({
                "id": parts[0],
                "name": parts[1],
                "size": parts[2],
                "date": " ".join(parts[3:]),
            })
    
    return {
        "status": "success",
        "disk": str(disk_path),
        "snapshots": snapshots,
    }


# ============================================================
# VM LIFECYCLE TOOLS
# ============================================================

@mcp.tool()
def start_vm(
    mode: str = "headless",
    ram_mb: int = 2048,
    cpus: int = 2,
) -> dict:
    """Start the ZEN-OS VM from ISO.
    
    Args:
        mode: "headless", "vnc", or "mcp"
        ram_mb: RAM allocation
        cpus: CPU cores
    
    Returns:
        VM start result with connection info
    """
    iso_path = WORKSPACE / ISO_NAME
    if not iso_path.exists():
        return {"status": "error", "message": "ISO not found"}
    
    # Prepare OVMF
    ovmf_vars = Path(tempfile.mktemp(suffix=".fd", prefix="zenos-ovmf-"))
    subprocess.run(["cp", OVMF_VARS_TEMPLATE, str(ovmf_vars)], check=True)
    
    # Kill existing
    subprocess.run(["systemctl", "--user", "stop", "zenos-smoke"],
                   capture_output=True, check=False)
    subprocess.run(["pkill", "-f", "qemu-system.*zenos-smoke"],
                   capture_output=True, check=False)
    
    # Build display args
    display_args = []
    vnc_port = 5900
    if mode == "headless":
        display_args = ["-display", "none"]
    elif mode in ("vnc", "mcp"):
        display_args = ["-vnc", ":0", "-vga", "virtio"]
    
    args = [
        "qemu-system-x86_64",
        "-enable-kvm", "-smp", str(cpus), "-m", str(ram_mb),
        "-drive", f"if=pflash,format=raw,readonly=on,file={OVMF_CODE}",
        "-drive", f"if=pflash,format=raw,file={ovmf_vars}",
        "-drive", f"file={iso_path},media=cdrom,readonly=on",
        "-boot", "d",
        "-netdev", "user,id=net0", "-device", "virtio-net-pci,netdev=net0",
        "-serial", "file:/tmp/zenos-smoke-serial.log",
        "-name", "zenos-smoke",
    ] + display_args
    
    # Start with systemd-run
    subprocess.run(
        ["systemd-run", "--user", "--unit=zenos-smoke"] + args,
        capture_output=True, text=True, check=True,
    )
    
    time.sleep(5)
    
    # Verify running
    result = subprocess.run(
        ["pgrep", "-a", "qemu-system"],
        capture_output=True, text=True, check=False,
    )
    running = "zenos-smoke" in result.stdout
    
    return {
        "status": "running" if running else "failed",
        "mode": mode,
        "vnc": f"localhost:{vnc_port}" if mode in ("vnc", "mcp") else None,
        "serial_log": "/tmp/zenos-smoke-serial.log",
        "iso": str(iso_path),
    }

@mcp.tool()
def stop_vm() -> dict:
    """Stop the running ZEN-OS VM.
    
    Returns:
        Stop result
    """
    subprocess.run(["systemctl", "--user", "stop", "zenos-smoke"],
                   capture_output=True, check=False)
    subprocess.run(["pkill", "-f", "qemu-system.*zenos-smoke"],
                   capture_output=True, check=False)
    
    return {"status": "stopped", "vm": "zenos-smoke"}

@mcp.tool()
def get_vm_serial(lines: int = 50) -> dict:
    """Read the VM serial console output.
    
    Args:
        lines: Number of lines from the end to return
    
    Returns:
        Serial log content
    """
    log_path = Path("/tmp/zenos-smoke-serial.log")
    if not log_path.exists():
        return {"status": "error", "message": "Serial log not found"}
    
    content = log_path.read_text(errors="replace")
    lines_list = content.split("\n")
    tail = "\n".join(lines_list[-lines:])
    
    # Check for key indicators
    has_systemd = "systemd-logind" in content
    has_login = "debian login" in content.lower()
    has_ufw = "ufw.service" in content
    has_sddm = "sddm.service" in content
    
    return {
        "status": "ok",
        "lines": len(lines_list),
        "tail": tail,
        "indicators": {
            "systemd": has_systemd,
            "login_prompt": has_login,
            "ufw": has_ufw,
            "sddm": has_sddm,
        },
    }


# ============================================================
# SCREENSHOT TOOLS
# ============================================================

@mcp.tool()
def capture_screenshot() -> dict:
    """Capture a screenshot of the VM via VNC.
    
    Returns:
        Screenshot path and analysis
    """
    screenshot_path = Path(tempfile.mktemp(suffix=".png", prefix="zenos-screen-"))
    
    result = subprocess.run(
        ["vncdo", "-s", "localhost:0", "capture", str(screenshot_path)],
        capture_output=True, text=True, check=False,
    )
    
    if result.returncode != 0:
        return {"status": "error", "message": "Screenshot capture failed"}
    
    # Analyze
    analysis = _analyze_screenshot(screenshot_path)
    
    return {
        "status": "success",
        "path": str(screenshot_path),
        "analysis": analysis,
    }


# ============================================================
# SMOKE TEST TOOL
# ============================================================

@mcp.tool()
def run_smoke_test() -> dict:
    """Run the automated smoke test suite on the current ISO.
    
    Returns:
        Test results with pass/fail counts
    """
    script_path = WORKSPACE / "scripts" / "smoke-test.sh"
    if not script_path.exists():
        return {"status": "error", "message": "Smoke test script not found"}
    
    env = os.environ.copy()
    env["ZENOS_NAME"] = "zenos-smoke"
    env["ZENOS_SERIAL_LOG"] = "/tmp/zenos-smoke-serial.log"
    env["ZENOS_VNC_DISPLAY"] = ":0"
    
    result = subprocess.run(
        ["bash", str(script_path)],
        capture_output=True, text=True, env=env,
        timeout=300,
    )
    
    # Parse results
    passed = result.stdout.count("[PASS]")
    failed = result.stdout.count("[FAIL]")
    warnings = result.stdout.count("[WARN]")
    
    # Find report dir
    report_dir = None
    for line in result.stdout.split("\n"):
        if "Report:" in line:
            report_dir = line.split("Report:")[1].strip()
            break
    
    return {
        "status": "complete",
        "passed": passed,
        "failed": failed,
        "warnings": warnings,
        "all_passed": failed == 0,
        "report_dir": report_dir,
        "output": result.stdout[-2000:],
    }


if __name__ == "__main__":
    mcp.run()
