# Scryfall Offline Search

Flutter app (Android + iOS) that stores the full Scryfall Magic: The Gathering
card database on-device and answers real Scryfall-syntax searches
(`t:creature c:rg mv<=3 o:"draw a card"`, `pow>tou`, regex, OR/parens/negation)
completely offline. Card images load from Scryfall's CDN and stay cached.

## Architecture

- **Storage**: SQLite via [drift], one DB (~500 MB) built on-device from the
  Scryfall `default_cards` bulk file (72 MB gzipped JSONL download).
  - `cards` (one row per oracle id — the default `unique:cards` search grain),
    `faces` (per face; uniform shape makes per-face predicates one SQL
    pattern), `prints` (per printing incl. pruned raw JSON for the detail
    view), `rulings`, `meta`.
  - Legalities pack into one integer (2 bits/format, `lib/core/legalities.dart`);
    colors are bitmasks (`lib/core/colors.dart`).
  - FTS5 **trigram** tables accelerate substring matches (Scryfall `o:`/`t:`
    semantics) via SQLite's LIKE-on-trigram optimization.
- **Query engine** (`lib/search/`): petitparser grammar → AST → SQL compiler.
  Exotic operators run as custom SQL functions registered per connection
  (`regexp`, `mana_geq/leq/eq` multiset algebra) so pagination and counts stay
  in one statement. Behavioral spec: scryfall.com/docs/syntax and CubeCobra's
  Apache-2.0 grammar.
- **Sync** (`lib/data/sync/`): resolve bulk URLs → streamed download → ingest
  isolate builds a *staging* DB (journal off) → verify counts → atomic file
  swap under the live handle. First sync ≈ 5 min; updates run while search
  stays usable.
- **App** (`lib/app/`, `lib/search/ui`, `lib/card_detail`, `lib/sync_ui`):
  Riverpod + go_router. Onboarding gate until the first sync completes.

## Development

```sh
flutter pub get
dart run build_runner build   # after changing lib/data/db/tables.dart
flutter test                  # pure-VM tests: ingest, parser, compiler, sync
flutter run                   # needs a device/emulator
```

Desktop `flutter test` needs a SQLite library with FTS5:

- **Windows**: download the x64 DLL zip from sqlite.org/download.html and
  unzip to `tools/sqlite3/sqlite3.dll` (gitignored).
- **Linux/CI**: `apt install libsqlite3-dev`.

`tool/fetch_fixtures.dart` regenerates `test/fixtures/` from the live
Scryfall API (rarely needed; assertions pin to the fetched cards).

## Releasing to Google Play

Tag → GitHub Actions builds a signed bundle → Play **internal testing** track
(`.github/workflows/release.yml`). Promote to production manually in Play
Console.

One-time setup:

1. **Upload keystore**:
   `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. **GitHub secrets**: `ANDROID_KEYSTORE_BASE64` (base64 of the .jks),
   `KEYSTORE_PASSWORD`, `KEY_ALIAS` (`upload`), `KEY_PASSWORD`,
   `PLAY_SERVICE_ACCOUNT_JSON` (Google Cloud service account with release
   access granted in Play Console → API access).
3. **Play Console**: create the app (package
   `com.nicksullivan.scryfall_app`), enroll in Play App Signing, complete the
   store listing / data-safety / content-rating forms, and upload the **first**
   AAB manually through the Console UI (Play requires it; build one locally
   with `flutter build appbundle` + a local `android/key.properties`).
4. Thereafter: `git tag v0.1.0 && git push --tags`.

Local release builds: create `android/key.properties` (gitignored):

```
storeFile=upload-keystore.jks   # place the .jks in android/
storePassword=...
keyAlias=upload
keyPassword=...
```

Listing images screenshotted with an emulator, then given a border with mockuphone.com

## Compliance

Card data and images © Wizards of the Coast, provided by Scryfall. This is
unofficial Fan Content under the WotC Fan Content Policy — the app must never
paywall card data, and card images keep the artist/© line visible. All
Scryfall API calls send a proper `User-Agent` (see `lib/data/sync/bulk_api.dart`).

[drift]: https://drift.simonbinder.eu
