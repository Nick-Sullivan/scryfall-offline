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

An emulator is usually already running. Check `adb devices` via that full
path before launching one, and never conclude "no emulator" from a bare `adb`
or from `flutter emulators`.

Install a build with `flutter build apk --debug` then
`adb install -r build/app/outputs/flutter-apk/app-debug.apk`; `-r` keeps app
data, so this is also how to test upgrading from an older build (build the old
commit in a `git worktree`, install it, then install the new APK over it).

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

The tag pack is `files/db/tags.db` (attached as `tagdb`). Build one in the same
throwaway test with `TagIngestor.ingestTags` over `tags_fixture.jsonl` and
`art_tags_fixture.jsonl`, then `finalize()`. A real one comes from Card data →
Download tag data (~20 MB download, ~1 min); real art tags match the fixture
cards' illustration ids, so it pairs fine with the fixture card DB.

Delete the throwaway seed test afterwards.

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
  `run-as <pkg> ls files/db` before overwriting, and back files up first. The
  user also uses it between runs, so re-check prefs/state rather than assuming
  what you left. `run-as` can't write to `/data/local/tmp` (SELinux), so back
  up inside the sandbox (`run-as <pkg> cp -r files/images files/x_backup`) or
  pull to the host with `run-as <pkg> cat … > local`.
- Driving the UI changes the user's saved settings: a stray tap or a swipe
  that registers as a tap on Settings (especially the expanded Default filter)
  rewrites prefs. Before driving, save `FlutterSharedPreferences.xml` to the
  host; afterwards diff it and restore anything you changed. Swipe on labels,
  away from switches and chips.
- Before tapping, confirm the app is in front:
  `adb shell dumpsys activity activities | grep -m1 topResumedActivity`.
  A system picker (e.g. the art-folder chooser) can be on top and swallow taps;
  back out of it without choosing anything.
- `adb shell input text` goes through the device shell: `>`, `<`, `|`, `(`,
  quotes etc. get interpreted (`pow>=2` creates a file named `=2`). Type
  queries without them, or drive the filter panel instead.
- The filter panel is a top sheet: swipes to scroll it must start inside it
  (y < ~1000 px), or they scroll the results grid behind.
- Pref changes need `am force-stop` before editing
  `shared_prefs/FlutterSharedPreferences.xml`, or the app overwrites them.
  List prefs are stored as `VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu!<json>`.
- Live API sanity probe: `https://api.scryfall.com/sets` needs both
  User-Agent and Accept headers or Scryfall returns 400.
