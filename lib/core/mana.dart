/// Mana-cost canonicalization and multiset comparison.
///
/// A mana cost like `{2}{W}{U}{U}` is canonicalized to the pip string
/// `2|U|U|W`: the summed generic component first (omitted when 0 and there
/// are symbols; a cost of exactly `{0}` becomes `0`), followed by the
/// non-generic symbols sorted alphabetically. Hybrid/phyrexian symbols stay
/// compound (`W/U`, `G/P`, `2/W`) and `X`/`S`/`C` are ordinary symbols.
///
/// Comparison follows Scryfall semantics: cost A contains cost B when A's
/// generic total >= B's and A's symbol multiset is a superset of B's.
library;

class ManaPips {
  final int generic;
  final List<String> symbols; // sorted, uppercase, compound tokens intact

  const ManaPips(this.generic, this.symbols);

  bool get isEmpty => generic == 0 && symbols.isEmpty;

  /// Canonical encoding stored in `faces.mana_pips` and used by the custom
  /// SQL functions. Empty cost encodes as ''.
  String encode() {
    if (isEmpty) return '';
    final parts = <String>[
      if (generic > 0 || symbols.isEmpty) '$generic',
      ...symbols,
    ];
    return parts.join('|');
  }

  static ManaPips decode(String encoded) {
    if (encoded.isEmpty) return const ManaPips(0, []);
    final parts = encoded.split('|');
    var generic = 0;
    var start = 0;
    final first = int.tryParse(parts.first);
    if (first != null) {
      generic = first;
      start = 1;
    }
    return ManaPips(generic, parts.sublist(start));
  }

  /// True when this cost contains [other] (>= in Scryfall mana algebra).
  bool contains(ManaPips other) {
    if (generic < other.generic) return false;
    final have = <String, int>{};
    for (final s in symbols) {
      have[s] = (have[s] ?? 0) + 1;
    }
    for (final s in other.symbols) {
      final n = (have[s] ?? 0) - 1;
      if (n < 0) return false;
      have[s] = n;
    }
    return true;
  }

  bool equalsPips(ManaPips other) =>
      generic == other.generic &&
      symbols.length == other.symbols.length &&
      contains(other);
}

final _symbolRe = RegExp(r'\{([^}]+)\}');

/// Parses a Scryfall `mana_cost` string (`{2}{W/U}{W/U}`) or a bare query
/// value (`3WU`, `2ww`, `{R/P}`). Returns null for invalid input.
ManaPips? parseManaCost(String input) {
  final text = input.trim();
  if (text.isEmpty) return const ManaPips(0, []);
  var generic = 0;
  final symbols = <String>[];

  void addSymbol(String raw) {
    final sym = raw.toUpperCase();
    final asInt = int.tryParse(sym);
    if (asInt != null) {
      generic += asInt;
    } else {
      symbols.add(sym);
    }
  }

  if (text.contains('{')) {
    var covered = 0;
    for (final m in _symbolRe.allMatches(text)) {
      // Reject stray characters between symbols.
      if (text.substring(covered, m.start).trim().isNotEmpty) return null;
      covered = m.end;
      addSymbol(m.group(1)!);
    }
    if (covered < text.length && text.substring(covered).trim().isNotEmpty) {
      return null;
    }
  } else {
    // Bare form: digits accumulate into generic, letters are single symbols.
    var i = 0;
    while (i < text.length) {
      final ch = text[i];
      if (RegExp(r'\d').hasMatch(ch)) {
        var j = i;
        while (j < text.length && RegExp(r'\d').hasMatch(text[j])) {
          j++;
        }
        generic += int.parse(text.substring(i, j));
        i = j;
      } else if (RegExp(r'[wubrgcxs]', caseSensitive: false).hasMatch(ch)) {
        symbols.add(ch.toUpperCase());
        i++;
      } else {
        return null;
      }
    }
  }
  symbols.sort();
  return ManaPips(generic, symbols);
}

/// SQL function bodies (registered in database.dart as mana_geq/mana_leq/mana_eq).
bool manaGeq(String pips, String query) =>
    ManaPips.decode(pips).contains(ManaPips.decode(query));

bool manaLeq(String pips, String query) =>
    ManaPips.decode(query).contains(ManaPips.decode(pips));

bool manaEq(String pips, String query) =>
    ManaPips.decode(pips).equalsPips(ManaPips.decode(query));
