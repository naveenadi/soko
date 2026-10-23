# Vendored SQLite

Amalgamation **3.54.1** (`sqlite-amalgamation-3540100.zip`), public domain.

Vendored rather than linked from the system: the binary must cross-compile to
Linux musl and Windows from one machine, so every target has to see the same C
source. Only `sqlite3.c` and `sqlite3.h` are kept; `shell.c` and `sqlite3ext.h`
are not needed.

## Re-vendoring

```
curl -sSO https://sqlite.org/2026/sqlite-amalgamation-3540100.zip
unzip -j sqlite-amalgamation-3540100.zip sqlite3.c sqlite3.h -d vendor/sqlite/
```

Then update the version here and the row in `THIRD_PARTY_LICENSES.md`.
