# scryfall_app

## UI copy
Show, don't tell. No subtitles, helper lines or descriptions that restate what
the UI already makes evident. Default to a bare title/control; add text only
when the user can't otherwise know something they need. When asked to trim
copy, delete it — don't reword it into another explanation.

## Editing
- The codebase is `dart format`-clean; run `dart format` on every Dart file you
  touch.
- Use the Edit tool for Dart changes. Shell/JS patch scripts mangle Dart's `$`
  and `${}` interpolation and quote characters.
- Never `git stash` (or `checkout`) a file to try an alternate version — it
  swaps out *all* uncommitted work in that file. Copy the file aside and back.

## SQL / tests
- CI runs `flutter test` on ubuntu-latest against the distro SQLite (older than
  the bundled mobile one and `tools/sqlite3/sqlite3.dll`). Generated SQL must
  work there: e.g. SQLite 3.45 can't resolve an outer-query column inside a
  correlated subquery's `ORDER BY` ("no such column"). When adding non-trivial
  SQL, run the affected tests against an older DLL
  (sqlite.org/2024/sqlite-dll-win-x64-3450100.zip swapped into `tools/sqlite3/`,
  then restored).
- Card DB schema bumps (`schemaVersionValue`) need an `onUpgrade` and make
  `updateCheckProvider` offer a re-download; tests that seed `meta` must set
  `MetaKeys.schemaVersion` or they read as outdated.
