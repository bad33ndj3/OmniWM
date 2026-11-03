---
name: personal-wm-test
description: Test, build, restart, and health-check Personal WM after a feature, or perform authorized macOS interaction checks.
---

# Personal WM feature completion

Use this skill for changes in the Personal WM integration, dashboard, or its validation workflow. Keep automated evidence, activation, and physical interaction acceptance separate.

Casper authorized restarting `OmniWM Dev` after completing a feature. After successful checks and build, perform the restart and health check before reporting completion; do not stop at “ready, restart it yourself.” A newer instruction such as “only check the code” overrides automatic activation for that task. This authorization covers the development app, not replacement of the release app, new macOS permissions, or window-movement experiments.

## Automated checks

1. Read the touched code and its callers. Pick the root WM package, dashboard package, or both based on the change.
2. Use the build and focused WM test commands in [`docs/personal-wm/native-integration.md`](../../../docs/personal-wm/native-integration.md). For dashboard changes, also run `~/.swiftly/bin/swiftly run swift test --package-path dashboard` from the repo root. `Scripts/build-personal-wm-dev.sh` packages the app and refreshes an existing `/Applications` copy; it does not restart the running process. Documentation-only changes need no app build or restart.
3. Report the command and result. A passing build or test proves no live UI behavior.

For read-only dashboard UI checks without switching WM, run `./Scripts/build-dashboard.sh`, then `open "dist/OmniWM Dashboard Dev.app"`. This standalone app cannot validate window moves or the integrated focus lease.

## Restart and health check

1. Read `HANDOFF.md` and the development paths in `docs/personal-wm/native-integration.md`. Confirm the signed `/Applications/OmniWM Dev.app` is the completed build. Use `codesign --verify --deep --strict` and verify `Authority=LocalDevCert`; retain the existing certificate and private key.
2. Inspect all processes named exactly `OmniWM`, including their executable paths. The normal case is one process running `/Applications/OmniWM Dev.app/Contents/MacOS/OmniWM`. If the release app or an unexpected copy is active, resolve that state before using the development restart authorization. Capture the dev settings SHA-256 and verify that `~/.config/omniwm-dev` and `~/.local/state/omniwm-dev` still resolve to the intended isolated data.
3. Send `SIGTERM` to the verified development PID. Wait up to ten seconds for it to exit. Confirm that no `OmniWM` process remains before launching. If shutdown fails, stop and report it; do not force-kill or start a second writer.
4. Launch the installed development app with explicit standard XDG paths and the established socket:

   ```bash
   env -u XDG_CONFIG_HOME -u XDG_STATE_HOME -u OMNIWM_SOCKET \
     /usr/bin/open \
     --env "XDG_CONFIG_HOME=$HOME/.config" \
     --env "XDG_STATE_HOME=$HOME/.local/state" \
     --env "OMNIWM_SOCKET=$HOME/Library/Application Support/com.barut.OmniWM/ipc.sock" \
     "/Applications/OmniWM Dev.app"
   ```

   The standard XDG directories use the verified dev symlinks. Avoid propagating repository-specific XDG paths into terminals launched by the WM. This launch uses the default socket shared with release; the zero-writer check is essential. `Scripts/omniwm-dev.sh use dev` preserves a process already running from the same app path, so that command alone does not restart it.
5. Poll `omniwmctl ping` for up to ten seconds with the same `OMNIWM_SOCKET`. Success requires `pong`, exactly one `OmniWM` process at the expected dev path, a new PID, and the unchanged dev settings hash. A failed health check requires diagnosis, not repeated blind launches or new permission grants.
6. Report activation separately from interaction validation. A healthy IPC socket proves the restart succeeded; it does not prove a click, drag, focus change, or physical monitor transition works.

## Optional live checks

Run interaction experiments only when the user requests or authorizes them. The normal post-feature restart above needs no repeated permission; temporary WM switches and additional macOS permissions still need their own authorization.

1. Read [`docs/personal-wm/native-integration.md`](../../../docs/personal-wm/native-integration.md) before activation. Confirm the dev app, isolated config/state/socket, active release settings, and return route. For repeated permission prompts, use its [stable signing setup](../../../docs/personal-wm/native-integration.md#vaste-ontwikkelrechten); certificate creation and trust changes require the user's authorization.
2. Keep exactly one OmniWM process as the frame writer. Record the target window's PID, window ID, workspace, and exact frame before acting.
3. Keep the user in control of input. Ask them to pause clicks and keys during a measurement; do not inject input to stabilize a result.
4. After each authorized move, read back the actual workspace and frame. If the result is missing or uncertain, stop and inspect state; never repeat the move blindly.
5. Restore the target to its recorded workspace and exact frame. Read both back, return to the originally active WM, and confirm its health and unchanged source settings.
6. Treat hoverfocus outside the panel and resumption from real mouse movement as separate physical checks. Do not infer either from automated tests or other live checks.

Record evidence and remaining gaps in [`docs/personal-wm/validation.md`](../../../docs/personal-wm/validation.md) only when the task asks for that documentation update.
