Soko: a terminal database client written in Zig

Soko is a keyboard-driven terminal UI for browsing and querying many kinds of databases through one interface, in the style of lazygit. Open it, pick a saved connection, and start querying.

> **Status: early design.** Nothing described under "Install" or "Usage" exists yet. This README states the goals the project is being built toward. See the roadmap for what is planned and in what order.

## Who it is for

Developers who work with more than one kind of database in a normal week, for example PostgreSQL for the main data, Redis for caching, and SQLite for local files, and who today switch between `psql`, `redis-cli`, `sqlite3`, and a GUI client.

If you only ever use one database, a dedicated tool such as `pgcli` or `litecli` is likely the better choice. Soko aims to be worth installing when your work spans several databases and you want one interface, one set of keybindings, and one connection list.

*(Draft: confirm or rewrite this section before publishing. It is the answer to "why not `usql` plus `pgcli`", and it should be specific.)*

## Goals

- **One interface for many databases.** Relational, document, key-value, time-series, and vector stores all appear in the same sidebar, results area, and editor.
- **Keyboard first.** Vim-style editing is optional. Everything is reachable from the command palette.
- **Safe by default.** Per-connection read-only mode that is enforced in the database session, not just by checking the query text. Every write shows the exact statement and asks for confirmation.
- **No secrets in config files.** Passwords come from the OS keychain or environment variables.
- **Stays out of the way.** One self-contained binary with no runtime to install, and a demo mode that needs no database.

## How it works

Soko is a single binary. It does not ship database drivers. Each database is served by a separate **driver**, a small helper program that you install only when you need it:

```
soko driver install postgres
```

SQLite is built in, so first run and demo mode need no download. Drivers run as separate processes and talk to Soko over a documented protocol, which keeps the main binary small, keeps database client libraries out of it, and means a crashing driver cannot take down the UI. Anyone can write a driver for a database Soko doesn't support yet.

Drivers are downloaded over HTTPS, checked against a SHA-256 checksum, and signed. Releases are signed with minisign, and the public key is bundled in the `soko` binary.

## Planned features

- Saved connections with a picker on startup
- Sidebar object browser: schemas, tables, views, procedures, indexes, triggers (and the equivalent for non-relational databases)
- Query editor with syntax highlighting, schema-aware autocomplete, undo and redo, and an optional Vim mode
- Multiple result tabs, with large results paged so very large tables stay responsive
- Sort, filter, fuzzy search over loaded rows, and copy for cells, rows, and columns
- CSV and JSON export
- Query history and saved queries
- Themes, an on-screen help overlay, and a command palette
- SSH tunnels through your system `ssh`
- Script-friendly CLI mode:

```
soko -c <connection> -q "<query>" --format json
```

## Supported databases

| Phase | Databases |
| --- | --- |
| 1 | SQLite (built in), PostgreSQL, MySQL and MariaDB, DuckDB |
| 2 | Redis, MongoDB, and one time-series store (ClickHouse or TimescaleDB) |
| 3 | pgvector, then Qdrant or Chroma; a Lua scripting layer |
| Later | SQL Server, Oracle, CockroachDB, Turso, Snowflake, BigQuery, Neo4j, InfluxDB |

## Install

Not available yet. The plan is a single download per platform for macOS, Linux, and Windows.

The binary has no third-party dynamic dependencies. On Linux it is fully static. On macOS and Windows it links only against the operating system's own libraries.

## Usage

Planned commands:

```
soko                      # open the connection picker
soko --demo               # try the interface with built-in sample data
soko driver list          # show available and installed drivers
soko driver install <name>
soko driver update [name]
soko driver remove <name>
soko -c <connection> -q "<query>" --format json|csv
```

In CLI mode, if the driver for a connection isn't installed, Soko exits with a distinct exit code and prints the install command. It never installs anything automatically.

## Credentials

Passwords are stored through your operating system: the `security` tool on macOS and `secret-tool` on Linux. On Windows, use environment variables. Environment variables also work everywhere as a fallback. Config files never contain secrets.

## Building from source

Soko requires **Zig 0.17.0**, pinned exactly. Other versions are not supported.

```
zig build
```

Build instructions will be expanded as the project takes shape. Toolchain notes, including the pinned libvaxis commit, are kept in `docs/zig-upgrades.md`.

## Roadmap

0. A short spike to design the driver protocol against Redis and pgvector before it is frozen
1. The relational core and demo mode
2. Non-relational drivers
3. Vector databases and Lua scripting

## Contributing

The project is at the design stage. Issues and discussion are welcome at `github.com/naveenadi/soko`.

## License

Soko is licensed under the [Apache License 2.0](LICENSE). See [NOTICE](NOTICE) for attribution.

Third-party libraries keep their own licenses, listed in `THIRD_PARTY_LICENSES`. In particular, the MariaDB driver links an LGPL library, so its release includes the build sources and object files needed to relink it.

Contributions are accepted under the same license. Please sign off each commit (`git commit -s`) to certify the Developer Certificate of Origin.
