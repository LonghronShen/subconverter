#!/usr/bin/env python3
"""Long-running health-monitor for subconverter.

Automatically uses ``wine`` to launch the executable when the binary is a
Win32 PE (MZ magic) **and** ``wine`` is available in PATH.  This matches the
behaviour of the gcc-for-Windows98 consumer container, which ships wine and
sets WINEPREFIX.  No explicit ``--wine`` flag is required in that environment.
"""

from __future__ import annotations

import argparse
import datetime
import os
import shutil
import signal
import subprocess
import sys
import time
import types
import urllib.request

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def is_win32_pe(path: str) -> bool:
    """Return True when *path* starts with the MZ magic bytes."""
    try:
        with open(path, "rb") as fh:
            return fh.read(2) == b"MZ"
    except OSError:
        return False


def build_launch_cmd(exe: str, wine_exe: str | None) -> list[str]:
    """
    Return the command list used to start *exe*.

    Priority:
    1. Explicit ``--wine`` override.
    2. Auto-detect: Win32 PE + wine in PATH  →  prepend wine.
    3. Run natively.
    """
    if wine_exe:
        return [wine_exe, exe]
    if is_win32_pe(exe):
        found = shutil.which("wine")
        if found:
            print(
                f"Detected Win32 PE with wine available — launching via {found}",
                flush=True,
            )
            return [found, exe]
        else:
            print(
                "Warning: target is a Win32 PE but wine was not found in PATH; "
                "attempting native launch",
                file=sys.stderr,
            )
    return [exe]


# ---------------------------------------------------------------------------
# Signal handling
# ---------------------------------------------------------------------------

running = True
server_process: subprocess.Popen[bytes] | None = None


def _signal_handler(sig: int, frame: types.FrameType | None) -> None:
    global running
    print("\nReceived signal, stopping gracefully...", flush=True)
    running = False


signal.signal(signal.SIGINT, _signal_handler)
signal.signal(signal.SIGTERM, _signal_handler)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Long-running health-monitor for a subconverter process.",
    )
    p.add_argument(
        "exe",
        metavar="EXE",
        help="Path to the subconverter executable (native or Win32 PE).",
    )
    p.add_argument(
        "--port",
        type=int,
        default=int(os.environ.get("PORT", "25500")),
        help="HTTP port the server listens on (default: 25500 or $PORT).",
    )
    p.add_argument(
        "--wine",
        metavar="WINE_EXE",
        default=None,
        help="Explicit path to the wine binary (skips auto-detection).",
    )
    p.add_argument(
        "--wineprefix",
        default=os.environ.get("WINEPREFIX", os.path.expanduser("~/.wine")),
        help="WINEPREFIX directory (default: $WINEPREFIX or ~/.wine).",
    )
    p.add_argument(
        "--winearch",
        default=os.environ.get("WINEARCH", "win64"),
        help="WINEARCH value (default: $WINEARCH or win64).",
    )
    p.add_argument(
        "--interval",
        type=int,
        default=60,
        metavar="SECONDS",
        help="Health-check interval in seconds (default: 60).",
    )
    return p.parse_args()


def start_server(
    cmd: list[str], wineprefix: str, winearch: str
) -> subprocess.Popen[bytes]:
    env = os.environ.copy()
    env["WINEPREFIX"] = wineprefix
    env["WINEARCH"] = winearch
    print(f"Starting server: {' '.join(cmd)}", flush=True)
    return subprocess.Popen(
        cmd, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )


def wait_for_ready(base_url: str, timeout_s: float = 30) -> bool:
    deadline = time.monotonic() + timeout_s
    while time.monotonic() < deadline:
        try:
            with urllib.request.urlopen(f"{base_url}/healthz", timeout=1) as resp:
                if resp.status == 200:
                    return True
        except Exception:
            pass
        time.sleep(1)
    return False


def main() -> None:
    global server_process

    args = parse_args()
    base_url = f"http://127.0.0.1:{args.port}"

    cmd = build_launch_cmd(args.exe, args.wine)
    server_process = start_server(cmd, args.wineprefix, args.winearch)

    print("Waiting for server to become ready...", flush=True)
    if not wait_for_ready(base_url):
        print("Failed to reach server within 30 s", file=sys.stderr)
        server_process.kill()
        sys.exit(1)

    print(
        f"Server is up on {base_url}. "
        f"Health-checking every {args.interval} s (Ctrl-C to stop).",
        flush=True,
    )

    failures = 0
    checks = 0

    try:
        while running:
            time.sleep(args.interval)
            if not running:
                break
            checks += 1
            now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            try:
                with urllib.request.urlopen(f"{base_url}/healthz", timeout=5) as resp:
                    if resp.status != 200:
                        print(f"[{now}] HTTP {resp.status}", flush=True)
                        failures += 1
                    else:
                        print(f"[{now}] OK", flush=True)
            except Exception as exc:
                print(f"[{now}] Error: {exc}", flush=True)
                failures += 1

            # RSS memory snapshot (best-effort)
            try:
                proc_name = os.path.basename(args.exe)
                out = subprocess.check_output(
                    ["ps", "-C", proc_name, "-o", "rss="], text=True
                )
                rss = sum(int(x) for x in out.strip().split() if x)
                if rss > 0:
                    print(f"[{now}] VmRSS: {rss} KB", flush=True)
            except Exception:
                pass

    finally:
        print(
            f"\nStopping server… (checks: {checks}, failures: {failures})", flush=True
        )
        if server_process:
            server_process.terminate()
            server_process.wait()


if __name__ == "__main__":
    main()
