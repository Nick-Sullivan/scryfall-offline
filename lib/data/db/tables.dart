import 'package:drift/drift.dart';

/// One row per oracle_id — the grain of default search results
/// (Scryfall `unique:cards`).
class Cards extends Table {
  TextColumn get oracleId => text()();
  TextColumn get name => text()(); // "Fire // Ice" for multiface
  RealColumn get cmc => real()();
  TextColumn get manaCost => text().nullable()();
  TextColumn get typeLine => text()();
  IntColumn get colors => integer()(); // union of faces, core/colors.dart masks
  IntColumn get colorIdentity => integer()();
  IntColumn get producedMana => integer()();
  IntColumn get colorCount => integer()(); // popcount of colors, for c:m / c=N
  TextColumn get keywordsPipe => text()(); // "|flying|haste|" lowercase
  BoolColumn get reserved => boolean()();
  IntColumn get edhrecRank => integer().nullable()();
  TextColumn get layout => text()();
  IntColumn get legalities => integer()(); // packed, core/legalities.dart
  TextColumn get preferredPrintId => text().nullable()();
  RealColumn get releasedAtFirst => real()(); // julian day of earliest print

  @override
  Set<Column> get primaryKey => {oracleId};
}

/// One row per face; single-faced cards get exactly one row copied from the
/// top-level object. rowid anchors the external-content FTS tables.
class Faces extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get oracleId => text()();
  IntColumn get faceIndex => integer()();
  TextColumn get name => text()();
  TextColumn get manaCost => text().nullable()();
  TextColumn get manaPips => text()(); // canonical, core/mana.dart ('' = none)
  TextColumn get typeLine => text()();
  TextColumn get oracleText => text()();
  IntColumn get colors => integer()();
  TextColumn get powText => text().nullable()(); // literal: "2", "*", "1+*"
  RealColumn get powNum => real().nullable()(); // '*' folds to 0
  TextColumn get touText => text().nullable()();
  RealColumn get touNum => real().nullable()();
  TextColumn get loyText => text().nullable()();
  RealColumn get loyNum => real().nullable()();
}

/// One row per printing (default_cards: ~105k).
class Prints extends Table {
  TextColumn get id => text()(); // Scryfall print UUID
  TextColumn get oracleId => text()();
  TextColumn get setCode => text()();
  TextColumn get setName => text()();
  TextColumn get collectorNumber => text()();
  IntColumn get rarity => integer()(); // rarityOrdinal below
  RealColumn get releasedAt => real()(); // julian day
  TextColumn get lang => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get watermark => text().nullable()();
  TextColumn get flavorText => text().nullable()();
  TextColumn get frame => text()();
  TextColumn get borderColor => text()();
  IntColumn get flags => integer()(); // PrintFlag bitmask
  IntColumn get games => integer()(); // GameFlag bitmask
  TextColumn get imageUriSmall => text().nullable()();
  TextColumn get imageUriNormal => text().nullable()();
  TextColumn get rawJson => text()(); // pruned card object for detail view

  @override
  Set<Column> get primaryKey => {id};
}

class Rulings extends Table {
  TextColumn get oracleId => text()();
  TextColumn get publishedAt => text()();
  TextColumn get comment => text()();
}

class Meta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

const Map<String, int> rarityOrdinal = {
  'common': 0,
  'uncommon': 1,
  'rare': 2,
  'special': 3,
  'mythic': 4,
  'bonus': 5,
};

/// Bit flags on Prints.flags.
class PrintFlag {
  static const promo = 1;
  static const fullArt = 2;
  static const digital = 4;
  static const reprint = 8;
  static const foil = 16; // finishes contains foil
  static const nonfoil = 32;
  static const etched = 64;
  static const oversized = 128;
  static const textless = 256;
  static const booster = 512;
  static const highres = 1024;
}

/// Bit flags on Prints.games.
class GameFlag {
  static const paper = 1;
  static const arena = 2;
  static const mtgo = 4;
}

/// Meta table keys.
class MetaKeys {
  static const bulkUpdatedAt = 'bulkUpdatedAt';
  static const rulingsUpdatedAt = 'rulingsUpdatedAt';
  static const cardCount = 'cardCount';
  static const printCount = 'printCount';
  static const lastCheckAt = 'lastCheckAt';
  static const setsCardTotal = 'setsCardTotal';
  static const schemaVersion = 'schemaVersion';
}
