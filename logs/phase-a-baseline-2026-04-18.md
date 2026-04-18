# Phase A baseline freeze (2026-04-18)

## Chosen execution baseline
- Primary worktree: `/root/.openclaw/workspace/subconverter-kleinshttp-phase-a`
- Do not use `/root/.openclaw/workspace/subconverter-stress` as the active execution baseline for current Phase A follow-up.

## Why this baseline
1. It already contains the Phase A webserver split work:
   - backend selection plumbing
   - `src/lib/server/webserver_common.cpp`
   - `src/lib/server/webserver_kleinshttp.cpp`
   - `scripts/verify-kleinshttp-phase-a.sh`
2. It already contains the validated `mingw_bundle_dll` compatibility fix:
   - use `cmake -E env ... "${Python3_EXECUTABLE}" ...`
   - do **not** include the unsupported `--` separator after `cmake -E env`
3. Prior evidence says the front blocker moved past bundling and into runtime startup.

## Mandatory execution rules for follow-up
- Treat `mingw_bundle_dll` as a solved compatibility issue on this baseline unless fresh evidence disproves it.
- Reuse the same path perspective that produced the current cache/artifacts; do not mix `/workspace/...` and `/root/.openclaw/workspace/...` against the same cache.
- Current priority is startup/runtime root-cause investigation, not re-opening the backend-selection or bundling branch.

## Current suspected blocker
- Early startup/runtime crash before normal server startup completes.
- Existing evidence first pointed to the startup path around `main()` / `setcd(...)`, not to route registration or socket listening.
- The current stronger anchor is the already-known libstdc++ / iostream runtime line: prior PoC work (`subconverter-stress/minirepro/iostream_bug.cpp`) and earlier investigation had already identified `iostream` / `fstream` behavior on the old MSVCRT target surface as a high-risk area, with `ios` inheritance / vtable-thunk style ABI issues as the top suspicion.
- New Phase A probes do not replace that conclusion; they refine it. The current `subconverter` startup path now re-anchors the same runtime issue to a concrete business path: `fileCopy("pref.example.toml", "pref.toml")`, where the crash occurs before copy completion and has been narrowed to the `fstream` construction path rather than to path switching, route setup, or socket listening.
