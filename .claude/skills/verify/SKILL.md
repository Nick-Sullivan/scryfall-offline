---
name: verify
description: How to smoke-test this app end-to-end on the Android emulator — build/launch/drive recipe, DB seeding, and gotchas.
---

# Verifying scryfall_app on a device

Android-only app (no windows/ or web/ targets). Real surface = Android emulator.

## Launch

```
flutter emulators --launch Pixel_3a_API_34_extension_level_7_x86_64
# wait for: adb shell getprop sys.boot_completed -> 1
flutter run -d emulator-5554 --debug     # debug build enables run-as
```

adb lives at `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe` (not on PATH).
Package id: `com.nicksullivan.scryfall_app`.

## Seed a small database (skip the ~250MB onboarding sync)

Build a 16-card DB from test fixtures with a throwaway env-guarded test
(pattern: `test/tool/render_icon_test.dart`) that runs
`Ingestor.ingestCards/ingestRulings/finalize` against
`AppDatabase.local(file:)` using `test/fixtures/*.jsonl` and
`configureSqliteForTests()`. Then:

```
adb push out.db /data/local/tmp/x.db
adb shell "run-as com.nicksullivan.scryfall_app sh -c 'rm -f files/db/scryfall.db-shm files/db/scryfall.db-wal; cp /data/local/tmp/x.db files/db/scryfall.db'"
adb shell am force-stop com.nicksullivan.scryfall_app && adb shell am start -n com.nicksullivan.scryfall_app/.MainActivity
```

Always delete `-wal`/`-shm` when swapping the DB file, and copy them back
out *together* when inspecting — fresh writes live in the WAL, so a bare
`cat scryfall.db` misses them.

## Drive & observe

- Screenshot: `adb exec-out screencap -p > shot.png`
- Tap: `adb shell input tap X Y` (Pixel 3a: 1080x2220)
- Prefs: `adb shell run-as <pkg> cat shared_prefs/FlutterSharedPreferences.xml`
  (keys prefixed `flutter.`)
- DB: copy db+wal to /data/local/tmp via run-as cat, query with the
  emulator's own `sqlite3` (host has no python/sqlite3 CLI).

## Gotchas

- PowerShell tool transport sometimes strips double quotes in multi-line
  commands — use the Bash tool for adb work.
- Git Bash mangles `/data/...` into `C:/Program Files/Git/data/...`;
  `export MSYS_NO_PATHCONV=1` first.
- The emulator may hold real test data from earlier sessions — check
  `run-as <pkg> ls files/db` before overwriting.
- Live API sanity probe: `https://api.scryfall.com/sets` needs both
  User-Agent and Accept headers or Scryfall returns 400.
