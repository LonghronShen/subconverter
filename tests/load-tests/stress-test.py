#!/usr/bin/env python3
import os
import sys
import time
import subprocess
import urllib.request
import urllib.error
import threading
import signal
import statistics

# Configuration
WINEPREFIX = os.environ.get("WINEPREFIX", "/opt/osxcross/target/wine")
WINEARCH = os.environ.get("WINEARCH", "win64")
EXE_PATH = "/root/.openclaw/workspace/subconverter-kleinshttp-phase-a/build-phase-a-revalidate/bin/subconverter.exe"
PORT = 25500
BASE_URL = f"http://127.0.0.1:{PORT}"
CONCURRENCY = 10
DURATION = 300  # 5 minutes by default

def start_server():
    env = os.environ.copy()
    env["WINEPREFIX"] = WINEPREFIX
    env["WINEARCH"] = WINEARCH
    env["WINEPATH"] = "Z:\\root\\.openclaw\\workspace\\subconverter-kleinshttp-phase-a\\build-phase-a-revalidate\\bin"
    # Launch in background
    cmd = ["wine", EXE_PATH]
    print(f"Starting server: {' '.join(cmd)}")
    process = subprocess.Popen(
        cmd, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    return process

def wait_for_server():
    print("Waiting for server to start...")
    for _ in range(30):
        try:
            with urllib.request.urlopen(f"{BASE_URL}/healthz", timeout=1) as response:
                if response.status == 200:
                    print("Server is up!")
                    return True
        except Exception:
            time.sleep(1)
    return False

stats = {
    "success": 0,
    "error": 0,
    "latencies": []
}
running = True

def worker():
    global stats, running
    while running:
        start_time = time.time()
        try:
            with urllib.request.urlopen(f"{BASE_URL}/version", timeout=2) as response:
                if response.status == 200:
                    stats["success"] += 1
                else:
                    stats["error"] += 1
        except Exception:
            stats["error"] += 1
        
        latency = (time.time() - start_time) * 1000
        stats["latencies"].append(latency)
        time.sleep(0.01)  # small delay to prevent overwhelming the client

def monitor_memory(pid, duration):
    mem_usage = []
    end_time = time.time() + duration
    while time.time() < end_time and running:
        try:
            output = subprocess.check_output(["ps", "-C", "subconverter.exe", "-o", "rss="], text=True)
            rss = sum(int(x) for x in output.strip().split())
            if rss > 0:
                mem_usage.append(rss)
        except Exception:
            pass
        time.sleep(5)
    return mem_usage

def main():
    global running
    duration = DURATION
    if len(sys.argv) > 1:
        duration = int(sys.argv[1])
        
    print(f"Starting stress test for {duration} seconds with concurrency {CONCURRENCY}")
    
    server_process = start_server()
    if not wait_for_server():
        print("Failed to start server")
        server_process.kill()
        sys.exit(1)
        
    threads = []
    for _ in range(CONCURRENCY):
        t = threading.Thread(target=worker)
        t.start()
        threads.append(t)
        
    print("Monitoring memory usage...")
    mem_usage = monitor_memory(server_process.pid, duration)
    running = False
    
    for t in threads:
        t.join()
        
    print("\nStopping server...")
    server_process.terminate()
    server_process.wait()
    
    total_requests = stats["success"] + stats["error"]
    success_rate = (stats["success"] / total_requests * 100) if total_requests > 0 else 0
    
    avg_latency = statistics.mean(stats["latencies"]) if stats["latencies"] else 0
    
    print("\n--- Stress Test Results ---")
    print(f"Total Requests: {total_requests}")
    print(f"Successful: {stats['success']}")
    print(f"Failed: {stats['error']}")
    print(f"Success Rate: {success_rate:.2f}%")
    print(f"Average Latency: {avg_latency:.2f} ms")
    
    if mem_usage:
        print(f"Memory RSS (Start): {mem_usage[0]} KB")
        print(f"Memory RSS (End): {mem_usage[-1]} KB")
        print(f"Memory RSS (Max): {max(mem_usage)} KB")
        
    if success_rate < 99.0:
        print("\nTest FAILED: Success rate < 99%")
        sys.exit(1)
    else:
        print("\nTest PASSED")
        sys.exit(0)

if __name__ == "__main__":
    main()