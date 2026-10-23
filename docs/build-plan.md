# Soko: build plan

This document is the complete build plan and the source of truth for the roadmap. The README summarizes it for users; contributors should read this. Toolchain pins and watch items live in `docs/zig-upgrades.md`; third-party license obligations live in `THIRD_PARTY_LICENSES`.

## Status

| Item | State |
|---|---|
| Stage 1: repo layout, `build.zig`, CI cross-compile, C interop | **Done** (2026-10-24). `soko` builds native plus `x86_64-linux-musl`, `aarch64-linux-musl`, `x86_64-windows`, `x86_64-macos`, `aarch64-macos`; SQLite 3.54.1 compiled from the vendored amalgamation through `addTranslateC`. libpq link risk probed; drivers are native-per-platform. |
| Phase 0 spike | Not started |
| Phase 1 | Not started |
| Deliverable 7: `docs/zig-upgrades.md` | Drafted, plus verified Zig/SQLite pins and the C-interop probe. The libvaxis commit pin still needs to be verified by a build (Stage 4). |
| Deliverable 9: repo layout, `build.zig`, README | `build.zig`, `build.zig.zon`, CI, and the source tree exist. README build instructions still to write. |
| Deliverable 8: licensing document | Drafted as `THIRD_PARTY_LICENSES`. |
| Everything else | Not started |

Update this table as work lands.

---

## Goal

Soko is a fast, keyboard-driven terminal UI for working with many kinds of databases, in the style of lazygit. Running `soko` opens a saved-connection picker, so a user can start querying within seconds. It is **universal**: relational, document, key-value, time-series, and vector databases all work through one interface. The name is Japanese for "warehouse", and the project lives at `github.com/naveenadi/soko`.

## Language and distribution

- Core application in **Zig 0.17.0**, pinned exactly in `build.zig.zon` and CI. Upgrading to a newer release is a deliberate task, never automatic. Watch for 0.17.1 and decide then whether the pin moves. ZLS does not yet support 0.17.0, so expect early development without full editor integration.
- TUI via **libvaxis**, pinned to a specific commit of upstream main. Its `build.zig.zon` declares `minimum_zig_version = "0.17.0"` (version 0.6.0), with upstream zigimg and uucode dependencies, so no fork or vendored patch is needed. Prefer a tagged release once one supports 0.17.0, and record the pinned commit and the re-pin procedure in `docs/zig-upgrades.md`. Until the vxfw runtime-crash report (issue #371) is understood, build on the low-level API rather than vxfw. Keep the choice behind a small `ui` module so it stays swappable.
- Ships as **one self-contained binary** named `soko` for macOS, Linux, and Windows via Zig cross-compilation, with no third-party dynamic dependencies: fully static on Linux (musl), and linked only against the operating system's own libraries on macOS (`libSystem`) and Windows. There is a single release artifact, with no "full" variant. A build script and release instructions are provided.
- **Database drivers are not shipped with the binary.** Each is a separate helper executable that users download and install on demand (see *Drivers: download and install*).
- Drivers wrap C client libraries (libpq, libmysqlclient or MariaDB Connector/C, SQLite, DuckDB, hiredis) through Zig's built-in `std.Build.addTranslateC` or hand-written `extern` declarations, isolated in one directory per driver. `@cImport` no longer exists in this Zig version, there is no separate translate-c package to pin, and `build.zig` must be written for the reworked build system.
- Drivers are **built natively per platform**, not cross-compiled. The libpq probe (2026-10-24) showed a cross-musl link fails for want of a musl `libpq`, and DuckDB and MariaDB Connector/C are harder still. Per-platform release assets already make this fine; see `docs/zig-upgrades.md`.
- **LGPL policy** for MariaDB Connector/C, in force before the first driver build: the driver's full build sources and object files are published with each release so users can relink (see `THIRD_PARTY_LICENSES`).
- **No scripting in v1.** Customization is a TOML config for themes, keymaps, and connections. The core exposes an internal command registry and event bus, with keymaps and themes stored as data.

## Drivers: download and install

- **Commands:** `soko driver list`, `install <name>`, `update [name]`, and `remove <name>`. When a user connects to a database whose driver is missing, Soko offers to install it right there.
- **Driver protocol:** versioned and documented, carrying capabilities, connect, schema listing, query, paged row streaming, cancel, and close. It *is* the adapter interface, designed from the Redis and pgvector spike, not just from relational databases.
- **Framing:** optimized for the third-party driver author as well as the core. The spike decides between length-prefixed binary frames for everything, or a simple text format (such as JSON lines) for control messages with binary frames only for row pages. A small helper library ships so a first driver takes an afternoon.
- **Logging:** drivers inherit stderr, so logs and panics reach the console with no logging protocol.
- **Compatibility:** each driver reports its protocol version and the minimum `soko` version it needs. `soko` refuses to start one it can't talk to and says what to update.
- **Install security:** HTTPS-only downloads, SHA-256 verification, and **signed releases**. Releases are signed with minisign (ed25519), and the public key is bundled in the `soko` binary. A new signing key is signed by the old one, and if a key is lost, the new key is announced through a separate documented channel. The trust model is documented. The install flow is a security surface.
- **Distribution:** drivers are built per platform in CI and published as release assets, one per driver per platform. Each build uses the toolchain that provably works on its platform, so a hard-to-cross-compile C library doesn't affect the core build.
- **Storage:** a per-user directory (for example `~/.local/share/soko/drivers/<name>/<version>/` on Linux), never a system path.
- **Why separate processes:** the core keeps no third-party dynamic dependencies, C client libraries and OpenSSL stay out of the core build, a crashing driver can't take down the UI, and a driver can be written in any language.
- **SQLite is built into `soko`** behind an internal adapter interface. The built-in SQLite adapter and the driver-protocol client both implement that interface, so the UI sees one seam. First run, demo mode, and the day-one proof need no download.

## Architecture: capability-based adapters

Every database is served by an adapter, either built-in SQLite or a driver speaking the protocol. Each declares its **capabilities**: query language, namespaces, transactions, cancel, explain, pagination, and its **read-only guarantee** (what is enforced, how, and the gaps). SQLite's is a layered recipe: open with `mode=ro`, set `PRAGMA query_only`, and gate statements so `ATTACH` and `PRAGMA query_only = OFF` are blocked. PostgreSQL uses a read-only transaction, with any DDL gaps documented.

The sidebar is normalized to *connection → namespace → entity → fields*:

- Relational: schema → table/view/procedure/index/trigger → columns
- Document: database → collection → inferred fields
- Key-value: keyspace → key prefix → key
- Time-series: database → measurement/metric → tags and fields
- Vector: collection/index → vector field (dimension, distance metric)
- Graph (later): labels and relationship types

Adapters return one of these **result shapes**, each with its own renderer: table, document tree, key-value, series, or vector hits (with score). All renderers share filter, fuzzy search, copy, and export. The editor switches **query mode** per connection: SQL, MongoDB queries, Redis commands, PromQL/InfluxQL, or a vector "nearest neighbors" form.

## Extensibility foundations (v1)

- **Command registry:** every user action is a named command; keybindings and the command palette map to names.
- **Event bus:** internal events such as `connect`, `query_run`, and `query_done`.
- **Data-driven keymaps and themes:** loaded from the TOML config, never hardcoded.

## Concurrency, streaming, and cancellation

- The UI thread never blocks. Each driver connection is served by a driver process, and a reader thread in `soko` turns its output into events.
- Cancellation is a protocol message to the driver, which uses the database's own mechanism. If it doesn't respond in time, `soko` kills the process and shows a clear "cancelled" state.
- Drivers stream rows in pages with backpressure. Sorting and filtering are pushed to the database where the driver supports it.
- Per-tab and overall row caps apply, with older pages dropped and re-fetched on scroll.
- Fuzzy search runs only over loaded rows, and the UI says so.

## Phased database support

- **Phase 0 (week one):** tracer spike. Redis and pgvector through a draft driver protocol, plus a trivial third-party driver in a scripting language.
- **Phase 1:** SQLite (built in), PostgreSQL, MySQL/MariaDB, DuckDB, plus demo mode.
- **Phase 2:** Redis and MongoDB in full, and one time-series store (ClickHouse or TimescaleDB).
- **Phase 3:** pgvector in full, then Qdrant or Chroma over HTTP; then the Lua scripting layer.
- **Later:** SQL Server, Oracle, CockroachDB, Turso/libSQL, Snowflake, BigQuery, Neo4j, InfluxDB.

## Interface

- Full-screen layout: sidebar object tree, query editor, and results area with **multiple result tabs**.
- Editor: syntax highlighting, schema-aware autocomplete, undo/redo, search, and a **Vim mode** that can be turned on or off. Run the current statement, the selection, or all statements.
- Results: **virtualized rendering and server-side pagination**. Sort, row filter, fuzzy search, and copy cell/row/column. Export to CSV and JSON.
- Table inspector: columns, indexes, foreign keys, triggers, and DDL, where supported.
- Query history that can be browsed, filtered, and re-run, plus saved favorite queries.
- On-screen help overlay, command palette, and theme switching (dark and light at minimum).

## Lua scripting layer (Phase 3)

- Embeds **Lua 5.4** (not LuaJIT), as thin bindings over the v1 registry and event bus. Re-verify ziglua's Zig 0.17 compatibility when this phase starts, or compile Lua's C sources directly.
- Loads `~/.config/soko/init.lua` at startup. A broken script never stops Soko from starting.
- API: `soko.keymap.set`, `soko.theme.set`, `soko.command.register`, `soko.on`, `soko.query`.
- Sandboxed by default. Plugins live in `~/.config/soko/plugins/`. One example script each for keymaps, themes, and commands ships with it.

## Connections and safety

- Connection manager: add, edit, delete, and test connections, with a picker on startup. Connect from a URL or from fields.
- Passwords go through a **keyring interface**: the `security` CLI on macOS, `secret-tool` on Linux, and **environment variables as the primary path on Windows**. Env vars are the fallback everywhere. Secrets go to these tools on stdin, never as command-line arguments. macOS service names containing periods break `find-generic-password`. Config files never contain secrets.
- **SSH tunnels** by spawning the system `ssh -L` process, documented. No libssh2 in v1.
- **Read-only mode**, per connection, enforced at the session level using each adapter's documented guarantee.
- Any write must show the exact statement and a clear confirmation before running.
- **Docker discovery** is deferred past v1.

## CLI and demo modes

- `soko --demo` ships in Phase 1 and runs the full UI against bundled mock data, with no database or drivers needed. It grows to cover every result shape as drivers arrive.
- `soko driver list|install|update|remove` manages drivers.
- `soko -c <connection> -q "<query>" --format json|csv` for scripts and agents, with exit codes, `--read-only`, and `--timeout`. If the needed driver isn't installed, it exits with a distinct exit code and prints the `soko driver install <name>` command. It never installs anything automatically.

## Out of scope for v1

Here v1 means Phases 0 and 1. Out of scope: scripting of any kind (the Lua layer arrives in Phase 3), Docker discovery, libssh2 or other bundled SSH libraries, ER diagrams, schema compare, charts, AI features, JSON field editing, wire-protocol drivers written from scratch, and any Neovim, Vim, desktop, or web front end.

## Deliverables and acceptance criteria

1. **Day-one proof:** a program on Zig 0.17.0 with the pinned libvaxis that runs a SQLite query end to end through the adapter layer and renders it in the TUI, cross-compiled for all three platforms in CI.
2. **Tracer spike:** Redis and pgvector through a draft driver protocol, plus a trivial scripting-language driver. The framing question is settled and the protocol revised before it is frozen.
3. **Driver protocol spec**, entity model, and result-shape types documented before UI work, including each adapter's read-only guarantee (SQLite's as the layered recipe), compatibility rules, and the internal adapter interface that both built-in SQLite and the driver client implement.
4. Command registry, event bus, and TOML config loading before the UI features that depend on them.
5. Design doc for threading, streaming, and cancellation.
6. Driver install flow with per-platform assets, HTTPS-only downloads, SHA-256 verification, minisign-signed releases with the public key bundled in the binary, a documented trust model, and per-user storage.
7. `docs/zig-upgrades.md` recording the Zig pin, the pinned libvaxis commit and re-pin procedure, and the status of vxfw (issue #371).
8. A licensing document with the LGPL policy for MariaDB Connector/C (`THIRD_PARTY_LICENSES`).
9. Repository layout, `build.zig`, build instructions, and a README that opens with "Soko: a terminal database client written in Zig", states who it is for and what they use today, and describes the binary as self-contained with no third-party dynamic dependencies.
10. Phase 1 adapters with integration tests (SQLite and DuckDB in CI, Postgres and MySQL via Docker), plus demo mode. The DuckDB driver's CI recipe states its extension list (likely json and parquet).
11. Demo of a 1M-row table scrolling, sorting, and filtering without noticeable lag.
12. Design doc: how to write a driver, how capabilities drive the UI, and how the registry and event bus back the Lua layer.

## Process

1. Look up current docs for Zig 0.17.0, translate-c, libvaxis (confirm the pinned commit still declares `minimum_zig_version = "0.17.0"`), and each C client library. Check whether 0.17.1 or a ZLS release has arrived.
2. Build the day-one proof: a SQLite query through the internal adapter interface, rendered in the TUI, cross-compiled in CI.
3. Run the Redis and pgvector spike, then revise and document the driver protocol.
4. Write the concurrency and registry/event-bus designs, and present them with the plan for review.
5. Build vertically: SQLite end to end (including demo mode), then Postgres and DuckDB drivers.
6. Add the Redis driver in full. If it fits the protocol without hacks, continue to Phase 2; if not, revise the protocol first.
7. Add the driver install flow, CLI mode, the keyring interface, and documented `ssh -L` tunnels.
8. In Phase 3, add the vector drivers, then the Lua layer.
