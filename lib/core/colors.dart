/// Color bitmask encoding shared by the schema, ingester, and query compiler.
///
/// W=1 U=2 B=4 R=8 G=16. Bit 32 (C) is only meaningful in `produced_mana`
/// (lands that add colorless), never in `colors`/`color_identity`.
library;

const int maskW = 1;
const int maskU = 2;
const int maskB = 4;
const int maskR = 8;
const int maskG = 16;
const int maskC = 32;
const int maskAllColors = maskW | maskU | maskB | maskR | maskG;

const Map<String, int> _letterMasks = {
  'w': maskW,
  'u': maskU,
  'b': maskB,
  'r': maskR,
  'g': maskG,
  'c': maskC,
};

/// Named color combinations accepted by `c:` and `id:` (Scryfall syntax).
const Map<String, int> namedCombos = {
  'white': maskW,
  'blue': maskU,
  'black': maskB,
  'red': maskR,
  'green': maskG,
  'colorless': 0,
  // Guilds
  'azorius': maskW | maskU,
  'dimir': maskU | maskB,
  'rakdos': maskB | maskR,
  'gruul': maskR | maskG,
  'selesnya': maskG | maskW,
  'orzhov': maskW | maskB,
  'izzet': maskU | maskR,
  'golgari': maskB | maskG,
  'boros': maskR | maskW,
  'simic': maskG | maskU,
  // Strixhaven colleges (same pairs, different names)
  'silverquill': maskW | maskB,
  'prismari': maskU | maskR,
  'witherbloom': maskB | maskG,
  'lorehold': maskR | maskW,
  'quandrix': maskG | maskU,
  // Shards
  'bant': maskG | maskW | maskU,
  'esper': maskW | maskU | maskB,
  'grixis': maskU | maskB | maskR,
  'jund': maskB | maskR | maskG,
  'naya': maskR | maskG | maskW,
  // Wedges
  'abzan': maskW | maskB | maskG,
  'jeskai': maskU | maskR | maskW,
  'sultai': maskB | maskG | maskU,
  'mardu': maskR | maskW | maskB,
  'temur': maskG | maskU | maskR,
  // Alara-block alternative names
  'brokers': maskG | maskW | maskU,
  'obscura': maskW | maskU | maskB,
  'maestros': maskU | maskB | maskR,
  'riveteers': maskB | maskR | maskG,
  'cabaretti': maskR | maskG | maskW,
  // Four-color nicknames
  'chaos': maskU | maskB | maskR | maskG,
  'glint': maskU | maskB | maskR | maskG,
  'aggression': maskW | maskB | maskR | maskG,
  'dune': maskW | maskB | maskR | maskG,
  'altruism': maskW | maskU | maskR | maskG,
  'ink': maskW | maskU | maskR | maskG,
  'growth': maskW | maskU | maskB | maskG,
  'witch': maskW | maskU | maskB | maskG,
  'artifice': maskW | maskU | maskB | maskR,
  'yore': maskW | maskU | maskB | maskR,
  // Five colors
  'rainbow': maskAllColors,
  'fivecolor': maskAllColors,
};

/// Parses a color word from JSON (`["W","U"]`) into a mask.
int maskFromJsonColors(List<dynamic>? colors) {
  if (colors == null) return 0;
  var mask = 0;
  for (final c in colors) {
    mask |= _letterMasks[(c as String).toLowerCase()] ?? 0;
  }
  return mask;
}

/// Parses a query color value: `wubrg` letters (in any order/case) or a
/// named combo. Returns null when the value is not a valid color expression.
/// `c`/`colorless` parse to 0; the caller distinguishes `multicolor`.
int? maskFromQueryValue(String value) {
  final v = value.toLowerCase();
  final named = namedCombos[v];
  if (named != null) return named;
  if (v == 'c') return 0;
  var mask = 0;
  for (final ch in v.split('')) {
    final m = _letterMasks[ch];
    if (m == null || ch == 'c') return null;
    mask |= m;
  }
  return mask == 0 ? null : mask;
}

/// Number of colors set in a mask (ignores the C bit).
int colorCount(int mask) {
  var n = 0;
  for (final m in const [maskW, maskU, maskB, maskR, maskG]) {
    if (mask & m != 0) n++;
  }
  return n;
}
