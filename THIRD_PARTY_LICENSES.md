# Third-party licenses

Soko is licensed under the Apache License 2.0 (see LICENSE and NOTICE). This file lists the third-party software Soko builds against or distributes.

Licenses below are recorded from each project's upstream. Re-check each one against the exact version pinned for a release, and keep every project's own license text and copyright notice with the release (see "Notices" below).

| Component | License | Where it is used | Phase |
|---|---|---|---|
| Zig toolchain | MIT | build only | all |
| translate-c package | MIT | build only: C header translation for drivers | all |
| libvaxis | MIT | core: terminal UI | all |
| zigimg | MIT | core: libvaxis dependency | all |
| uucode | MIT | core: libvaxis dependency (Unicode tables) | all |
| musl libc | MIT | core: linked into the fully static Linux binary | all |
| SQLite | Public domain | core: built-in adapter | 1 |
| libpq (PostgreSQL client library) | PostgreSQL License | postgres driver | 1 |
| MariaDB Connector/C | LGPL-2.1-or-later | mysql/mariadb driver | 1 |
| DuckDB | MIT | duckdb driver | 1 |
| hiredis | BSD-3-Clause | redis driver | 2 |
| libmongoc / libbson | Apache-2.0 | mongodb driver | 2 |
| OpenSSL 3.x | Apache-2.0 | any driver that links TLS (list per driver once decided) | 1 and later |
| Lua 5.4 | MIT | embedded scripting layer | 3 |

All of these are permissive or public-domain except MariaDB Connector/C, which is covered by the policy below.

## Notices

- Each release ships the license text and copyright notice of every component it contains, in a `licenses/` directory.
- A driver release contains only the notices for the components that driver bundles.
- Where a component's license requires a NOTICE file (Apache-2.0 components), its contents are carried into the release.

## LGPL policy: MariaDB Connector/C

The MySQL/MariaDB driver statically links MariaDB Connector/C, licensed under the LGPL (version 2.1 or later). The LGPL does not change the license of Soko's own code; it imposes obligations on how the driver is distributed. Every release of that driver includes:

1. The complete, exact source code of MariaDB Connector/C used in the build.
2. The complete build scripts and instructions needed to rebuild the driver binary from those sources.
3. The driver's own object files, so any user can relink it against a modified or newer version of the library.
4. The full text of the LGPL version that applies, in `licenses/LGPL-2.1.txt`.
5. A notice, in the release notes and in the driver's `--version` output, stating that the driver uses MariaDB Connector/C under the LGPL.

The driver's license terms must not restrict a user's right to modify the driver for their own use or to reverse engineer it for debugging those modifications. Apache-2.0 permits both, so the driver's own code needs no extra terms.

This policy is in force before the first driver build ships.
