import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';

/// On desktop test runs there is no bundled SQLite; point package:sqlite3 at
/// a real library. Windows: tools/sqlite3/sqlite3.dll (checked in via
/// tools/README). Linux CI: the distro libsqlite3 (FTS5 enabled on Ubuntu).
void configureSqliteForTests() {
  if (Platform.isWindows) {
    final dll = File('tools/sqlite3/sqlite3.dll').absolute;
    if (dll.existsSync()) {
      open.overrideFor(
          OperatingSystem.windows, () => DynamicLibrary.open(dll.path));
    }
  } else if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, () {
      for (final name in ['libsqlite3.so', 'libsqlite3.so.0']) {
        try {
          return DynamicLibrary.open(name);
        } on ArgumentError {
          continue;
        }
      }
      throw StateError('libsqlite3 not found — apt install libsqlite3-dev');
    });
  }
}
