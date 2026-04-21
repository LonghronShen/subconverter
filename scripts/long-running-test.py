#!/usr/bin/env python3
import os
import sys
import time
import subprocess
import urllib.request
import signal
import datetime

WINEPREFIX = os.environ.get("WINEPREFIX", "/opt/osxcross/target/wine")
WINEARCH = os.environ.get("WINEARCH", "win64")
EXE_PATH = "/root/.openclaw/workspace/subconverter-kleinshttp-phase-a/build-phase-a-revalidate/bin/subconverter.exe"
PORT = 25500
BASE_URL = f"http://127.0.0.1:{PORT}"

running = True
server_process = None

def signal_handler(sig, frame):
    global running
    print("\nReceived SIGINT, stopping gracefully...")
    running = False

signal.signal(signal.SIGINT, signal_handler)

def start_server():
    env = os.environ.copy()
    env["WINEPREFIX"] = WINEPREFIX
    env["WINEARCH"] = WINEARCH
    env["WINEPATH"] = "Z:\\root\\.openclaw\\workspace\\subconverter-kleinshttp-phase-a\\build-phase-a-revalidate\\bin"
    
    cmd = ["wine", EXE_PATH]
    print(f"Starting server: {' '.join(cmd)}")
    process = subprocess.Popen(
        cmd, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    return process

def main():
    global server_process
    server_process = start_server()
    
    print("Waiting for server to start...")
    started = False
    for _ in range(30):
        try:
            with urllib.request.urlopen(f"{BASE_URL}/healthz", timeout=1) as response:
                if response.status == 200:
                    started = True
                    break
        except Exception:
            time.sleep(1)
            
    if not started:
        print("Failed to start server")
        server_process.kill()
        sys.exit(1)
        
    print("Server is up! Starting long-running monitor (press Ctrl+C to stop)...")
    
    failures = 0
    checks = 0
    
    try:
        while running:
            time.sleep(60)  # check every minute
            checks += 1
            now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            try:
                with urllib.request.urlopen(f"{BASE_URL}/healthz", timeout=5) as response:
                    if response.status != 200:
                        print(f"[{now}] HTTP {response.status}")
                        failures += 1
                    else:
                        print(f"[{now}] OK")
            except Exception as e:
                print(f"[{now}] Error: {e}")
                failures += 1
                
            # Check memory
            try:
                output = subprocess.check_output(["ps", "-C", "subconverter.exe", "-o", "rss="], text=True)
                rss = sum(int(x) for x in output.strip().split())
                if rss > 0:
                    print(f"[{now}] VmRSS: {rss} KB")
            except Exception:
                pass
                
    finally:
        print(f"\nStopping server... (Total checks: {checks}, Failures: {failures})")
        server_process.terminate()
        server_process.wait()

if __name__ == "__main__":
    main()