# Zig toolchain policy and pin record

## Current pin

| Item | Value |
|---|---|
| Zig | 0.17.0 (exact; CI uses the same version) |
| libvaxis | pinned commit of upstream main (record the SHA here on first build) |
| translate-c package | record the exact version or commit on first build |

Upgrades are deliberate tasks, never automatic.

## libvaxis status (recorded October 18, 2026)

- libvaxis main builds on Zig 0.17.0 (the 0.17 port landed on main October 12, 2026).
- Its `build.zig.zon` declares `minimum_zig_version = "0.17.0"` and `.version = "0.6.0"`, with upstream zigimg and uucode dependencies. No fork or vendored patch is needed.
- Latest observed commit on main: `d4c3b36` (2026-10-12). This is a candidate pin. Verify it with a build and test run before recording it in the table above.
- No tagged release supports 0.17.0 yet (the latest tag, v0.5.1, predates it). When a tag appears, prefer it over the commit pin.
- **vxfw is not used.** Issue #371 reports a runtime crash in the vxfw App deinit path on Zig 0.17.0. The issue is closed on GitHub, but the reporter says the segfault persists against merged main as of 2026-10-13. Until that is understood, the `ui` module builds on the low-level vaxis API only.

## Watch items

- **Zig 0.17.1:** if released, decide deliberately whether the pin moves.
- **ZLS:** does not yet support 0.17.0 (blocked on the maker/configurer process split). Expect development without full editor integration until it does.
- **libvaxis tagged release** for 0.17.0.
- **translate-c package releases:** it has its own release cadence, separate from Zig, and can break drivers independently. Pin it and upgrade it on its own schedule.

## Re-pin procedure

1. `zig fetch --save git+https://github.com/rockorager/libvaxis.git#<commit>`
2. Run `zig build` and `zig build test` (plus the cross-compile targets in CI).
3. Update the pin table above.
