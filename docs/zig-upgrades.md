# Zig toolchain policy and pin record

## Current pin

| Item | Value |
|---|---|
| Zig | 0.17.0 (exact; CI uses the same version). Verified 2026-10-24: builds native plus `x86_64-linux-musl`, `aarch64-linux-musl`, `x86_64-windows`, `x86_64-macos`, `aarch64-macos` with SQLite 3.54.1 compiled from the vendored amalgamation. |
| libvaxis | pinned commit of upstream main (record the SHA here on first build; not yet a dependency) |
| SQLite | 3.54.1 amalgamation, vendored in `vendor/sqlite` (public domain; re-vendor procedure in its README) |

There is no separate translate-c package to pin: C header translation is
`std.Build.addTranslateC`, part of Zig 0.17.0 itself. The generated module is
what `@import("sqlite")` resolves to.

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

## C interop and driver link risks (probed 2026-10-24)

Probed with a throwaway project before any driver work started.

- **SQLite:** cross-compiles cleanly to every target from macOS, because the
  amalgamation is C and vendored. This is the reason SQLite is the built-in
  adapter.
- **libpq:** `addTranslateC` handles `libpq-fe.h` and a native macOS link works.
  Cross-compiling to `x86_64-linux-musl` fails with `error: not an ELF file` —
  the only available `libpq.a` is a Mach-O archive, and a musl build would need
  PostgreSQL plus OpenSSL built for musl first.
- **Conclusion:** drivers are built natively per platform in CI, which is what
  per-platform release assets already allow. Do not plan on cross-compiling
  drivers. DuckDB (C++, needs a C++ ABI) and MariaDB Connector/C (needs TLS)
  are strictly harder than libpq, so treat any driver cross-compile claim as
  unproven work rather than a build flag.

## Re-pin procedure

1. `zig fetch --save git+https://github.com/rockorager/libvaxis.git#<commit>`
2. Run `zig build` and `zig build test` (plus the cross-compile targets in CI).
3. Update the pin table above.
