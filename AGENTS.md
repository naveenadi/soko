# AGENTS.md

Soko is a terminal database client in Zig. `docs/build-plan.md` is the source of truth for scope and roadmap; the README is the user-facing summary.

## Toolchain

- Zig **0.17.0**, pinned exactly. Never bump it as part of another change; upgrades are their own task.
- **libvaxis**, pinned to a commit (not a tag) until upstream tags a 0.17.0 release. Build on the low-level vaxis API only — **vxfw is off-limits** until issue #371 (deinit segfault on 0.17.0) is resolved. Keep the choice behind the `ui` module so it stays swappable.
- `@cImport` no longer exists in this Zig version; use the translate-c package or hand-written `extern`. `build.zig` must target the reworked build system, not 0.13-era idioms.
- ZLS does not support 0.17.0, so expect no full editor integration. Don't add LSP-specific config.
- Pins, re-pin procedure, and watch items live in `docs/zig-upgrades.md`. Record the SHA there when a pin lands.

## Architecture rules

- One binary named `soko`. Database drivers are **separate executables** downloaded on demand — `soko` never links a database client library. Each driver gets its own directory.
- Every driver wraps a C client library (libpq, libmysqlclient/MariaDB Connector/C, SQLite, DuckDB, hiredis). SQLite is the exception users get for free, so it is the one driver that can be built in.
- The driver protocol is designed from the Redis and pgvector spike, not just from relational needs. It is a frozen versioned interface once Phase 0 lands — changes there are breaking changes.
- No scripting layer in v1. Customization is TOML data (themes, keymaps, connections) over an internal command registry and event bus.
- Read-only mode is enforced in the database session, not by inspecting query text.
- Config files never hold secrets; passwords come from the OS keychain or environment variables.

## Commands

```
zig build
zig build test
```

Cross-compile targets are part of the definition of done: fully static on Linux (musl), only OS libraries on macOS and Windows.

## Working conventions

- Update the status table at the top of `docs/build-plan.md` when work lands; it is the only place that tracks progress.
- License obligations for third-party libraries live in `THIRD_PARTY_LICENSES`. MariaDB Connector/C is LGPL, so its driver's build sources and object files ship with every release.
- Sign off every commit (`git commit -s`) for the DCO. Contributions are Apache 2.0.
- Project is at design stage: no source tree exists yet. Prefer small, runnable increments over scaffolding.

## Agent skills

### Issue tracker

Issues and specs are markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical roles mapped to their default label strings (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: root `GLOSSARY.md` and `docs/adr/`. See `docs/agents/domain.md`.
