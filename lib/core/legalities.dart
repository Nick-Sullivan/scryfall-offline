/// Format legalities are packed into a single 64-bit integer: 2 bits per
/// format, ordered by [formatOrder]. Values per slot:
///   0 = not_legal, 1 = legal, 2 = banned, 3 = restricted
/// `f:x` compiles to `((legalities >> shift) & 3) IN (1, 3)`.
///
/// Appending a new format to the end of [formatOrder] keeps old shifts valid;
/// the new format's bits populate on the next data sync.
library;

const List<String> formatOrder = [
  'standard',
  'future',
  'historic',
  'timeless',
  'gladiator',
  'pioneer',
  'explorer',
  'modern',
  'legacy',
  'pauper',
  'vintage',
  'penny',
  'commander',
  'oathbreaker',
  'standardbrawl',
  'brawl',
  'alchemy',
  'paupercommander',
  'duel',
  'oldschool',
  'premodern',
  'predh',
];

/// Aliases users type -> canonical format key.
const Map<String, String> formatAliases = {
  'edh': 'commander',
  'historicbrawl': 'brawl',
  'pdh': 'paupercommander',
  'os': 'oldschool',
};

const int statusNotLegal = 0;
const int statusLegal = 1;
const int statusBanned = 2;
const int statusRestricted = 3;

int? formatShift(String format) {
  final key = formatAliases[format] ?? format;
  final idx = formatOrder.indexOf(key);
  return idx < 0 ? null : idx * 2;
}

/// Packs a Scryfall `legalities` JSON object into the integer encoding.
int packLegalities(Map<String, dynamic>? legalities) {
  if (legalities == null) return 0;
  var packed = 0;
  for (var i = 0; i < formatOrder.length; i++) {
    final status = switch (legalities[formatOrder[i]]) {
      'legal' => statusLegal,
      'banned' => statusBanned,
      'restricted' => statusRestricted,
      _ => statusNotLegal,
    };
    packed |= status << (i * 2);
  }
  return packed;
}

int legalityStatus(int packed, String format) {
  final shift = formatShift(format);
  return shift == null ? statusNotLegal : (packed >> shift) & 3;
}
