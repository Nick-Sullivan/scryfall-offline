import '../../core/colors.dart';
import '../../core/errors.dart';
import '../../core/legalities.dart';
import '../../core/mana.dart';
import '../parser/ast.dart';
import '../../data/db/tables.dart';
import '../../data/tags/tag_database.dart' show normalizeTag;

/// Compiled WHERE clause over the `cards` table (oracle grain, i.e. Scryfall
/// `unique:cards`). Face- and print-level predicates become correlated
/// EXISTS subqueries, matching Scryfall's per-face OR semantics.
class CompiledQuery {
  final String where;
  final List<Object?> params;
  final String orderBy;

  const CompiledQuery(this.where, this.params, this.orderBy);

  String selectSql({required int limit, required int offset}) =>
      'SELECT * FROM cards WHERE $where ORDER BY $orderBy '
      'LIMIT $limit OFFSET $offset';

  String countSql() => 'SELECT COUNT(*) AS n FROM cards WHERE $where';
}

class SqlCompiler {
  final List<Object?> _params = [];
  String? _orderField;
  bool? _orderAsc;

  /// Whether the optional oracle-tag pack (tags.db, attached as `tagdb`) is
  /// installed; `otag:` predicates throw a directions error without it.
  final bool tagsInstalled;

  SqlCompiler({this.tagsInstalled = true});

  static CompiledQuery compile(QueryNode root, {bool tagsInstalled = true}) =>
      SqlCompiler(tagsInstalled: tagsInstalled)._run(root);

  CompiledQuery _run(QueryNode root) {
    var where = _node(root);
    if (where.isEmpty) where = '1=1';
    return CompiledQuery(where, _params, _orderBy());
  }

  // ---------------------------------------------------------------- nodes

  String _node(QueryNode n) => switch (n) {
        AndNode a => _junction(a.children, 'AND'),
        OrNode o => _junction(o.children, 'OR'),
        NotNode not => switch (_node(not.child)) {
            '' => '',
            final inner => 'NOT ($inner)',
          },
        PredicateNode p => _predicate(p),
        NameTermNode t => _nameTerm(t),
      };

  String _junction(List<QueryNode> children, String op) {
    final parts = children.map(_node).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first;
    return '(${parts.join(' $op ')})';
  }

  // ---------------------------------------------------------------- terms

  String _nameTerm(NameTermNode t) {
    if (t.exact) {
      _params.add(t.text);
      _params.add(t.text);
      return '(cards.name = ? COLLATE NOCASE OR ${_facesExists('f.name = ? COLLATE NOCASE')})';
    }
    return _facesFtsLike('face_name_fts', 'name', t.text);
  }

  // ----------------------------------------------------------- predicates

  String _predicate(PredicateNode p) {
    final field = p.field;
    final op = p.op;
    final value = p.value;

    String text() => switch (value) {
          StringValue s => s.text,
          RegexValue _ => throw QuerySemanticError(
              "field '$field' does not accept a regex", p.position),
        };

    switch (field) {
      // ---- display directives (not filters)
      case 'order':
        _orderField = text().toLowerCase();
        return '';
      case 'direction' || 'dir':
        _orderAsc = switch (text().toLowerCase()) {
          'asc' || 'ascending' => true,
          'desc' || 'descending' => false,
          _ => throw QuerySemanticError(
              "direction must be 'asc' or 'desc'", p.position),
        };
        return '';
      case 'unique':
        if (text().toLowerCase() != 'cards') {
          throw QuerySemanticError(
              "only unique:cards is supported offline", p.position);
        }
        return '';

      // ---- colors
      case 'c' || 'color':
        return _color('cards.colors', op, text(), p, identityDefault: false);
      case 'id' || 'identity':
        return _color('cards.color_identity', op, text(), p,
            identityDefault: true);
      case 'produces':
        return _color('cards.produced_mana', op, text(), p,
            identityDefault: false, allowColorlessBit: true);

      // ---- face text
      case 't' || 'type':
        return _faceText('type_line', value, ftsColumn: 'type_line');
      case 'o' || 'oracle' || 'fo':
        return _faceText('oracle_text', value, ftsColumn: 'oracle_text');
      case 'name':
        return switch (value) {
          RegexValue r => _facesExists(_regex('f.name', r.pattern)),
          StringValue s => _facesFtsLike('face_name_fts', 'name', s.text),
        };
      case 'kw' || 'keyword':
        _params.add('%|${_escapeLike(text().toLowerCase())}|%');
        return "cards.keywords_pipe LIKE ? ESCAPE '\\'";

      // ---- numbers
      case 'mv' || 'cmc' || 'manavalue':
        final v = text().toLowerCase();
        if (v == 'even') return 'CAST(cards.cmc AS INTEGER) % 2 = 0';
        if (v == 'odd') return 'CAST(cards.cmc AS INTEGER) % 2 = 1';
        return 'cards.cmc ${_numOp(op, p)} ${_numParam(v, p)}';
      case 'pow' || 'power':
        return _stat('pow_num', op, text(), p);
      case 'tou' || 'toughness':
        return _stat('tou_num', op, text(), p);
      case 'loy' || 'loyalty':
        return _stat('loy_num', op, text(), p);
      case 'pt' || 'powtou':
        return _facesExists(
            'f.pow_num IS NOT NULL AND f.tou_num IS NOT NULL AND '
            'f.pow_num + f.tou_num ${_numOp(op, p)} ${_numParam(text(), p)}');
      case 'edhrec':
        return 'cards.edhrec_rank IS NOT NULL AND '
            'cards.edhrec_rank ${_numOp(op, p)} ${_numParam(text(), p)}';

      // ---- mana cost (custom SQL functions, core/mana.dart)
      case 'm' || 'mana':
        return _mana(op, text(), p);

      // ---- legality
      case 'f' || 'format' || 'legal':
        return _legality(text(), p, 'IN (1, 3)');
      case 'banned':
        return _legality(text(), p, '= $statusBanned');
      case 'restricted':
        return _legality(text(), p, '= $statusRestricted');

      // ---- card-level misc
      case 'layout':
        _params.add(text().toLowerCase());
        return 'cards.layout = ?';
      case 'is':
        return _is(text(), p);
      case 'not':
        return 'NOT (${_is(text(), p)})';

      // ---- print-level
      case 'r' || 'rarity':
        final ord = rarityOrdinal[text().toLowerCase()] ??
            (throw QuerySemanticError(
                "unknown rarity '${text()}'", p.position));
        return _printsExists('p.rarity ${op == ':' ? '=' : _numOp(op, p)} $ord');
      case 's' || 'e' || 'set' || 'edition':
        _params.add(text().toLowerCase());
        return _printsExists('p.set_code = ?');
      case 'cn' || 'number':
        _params.add(text());
        return _printsExists('p.collector_number = ?');
      case 'a' || 'artist':
        return switch (value) {
          RegexValue r => _printsExists(_regex('p.artist', r.pattern)),
          StringValue s => _printsLike('p.artist', s.text),
        };
      case 'ft' || 'flavor':
        return switch (value) {
          RegexValue r => _printsExists(_regex('p.flavor_text', r.pattern)),
          StringValue s => _printsLike('p.flavor_text', s.text),
        };
      case 'wm' || 'watermark':
        _params.add(text().toLowerCase());
        return _printsExists('p.watermark = ?');
      case 'border':
        _params.add(text().toLowerCase());
        return _printsExists('p.border_color = ?');
      case 'frame':
        _params.add(text().toLowerCase());
        return _printsExists('p.frame = ?');
      case 'lang' || 'language':
        _params.add(text().toLowerCase());
        return _printsExists('p.lang = ?');
      case 'game':
        final bit = switch (text().toLowerCase()) {
          'paper' => GameFlag.paper,
          'arena' => GameFlag.arena,
          'mtgo' => GameFlag.mtgo,
          _ => throw QuerySemanticError(
              "game must be paper, arena or mtgo", p.position),
        };
        return _printsExists('p.games & $bit != 0');
      case 'year' || 'date':
        return _date(field, op, text(), p);

      // ---- oracle tags (community Tagger data, optional download)
      case 'otag' || 'oracletag' || 'function':
        if (!tagsInstalled) {
          throw QuerySemanticError(
              "oracle tags aren't downloaded — get 'Tag data' from the "
              'Card data screen',
              p.position);
        }
        if (op != ':' && op != '=') {
          throw QuerySemanticError(
              "operator '$op' is not valid for '$field'", p.position);
        }
        // Matches slug or alias and includes all descendant tags, like
        // Scryfall (tagdb is the attached tag pack).
        final tag = normalizeTag(text());
        _params.add(tag);
        _params.add(tag);
        return 'cards.oracle_id IN ('
            'WITH RECURSIVE tset(id) AS ('
            'SELECT id FROM tagdb.tags WHERE slug = ? '
            'UNION SELECT tag_id FROM tagdb.tag_aliases WHERE alias = ? '
            'UNION SELECT e.child_id FROM tagdb.tag_edges e '
            'JOIN tset ON e.parent_id = tset.id'
            ') SELECT tc.oracle_id FROM tagdb.tag_cards tc '
            'JOIN tset ON tc.tag_id = tset.id)';

      default:
        throw QuerySemanticError.unknownField(field,
            suggestion: _suggestField(field));
    }
  }

  // ------------------------------------------------------------- helpers

  String _facesExists(String cond) =>
      'EXISTS (SELECT 1 FROM faces f WHERE f.oracle_id = cards.oracle_id AND ($cond))';

  String _printsExists(String cond) =>
      'EXISTS (SELECT 1 FROM prints p WHERE p.oracle_id = cards.oracle_id AND ($cond))';

  String _printsLike(String column, String text) {
    _params.add(_likePattern(text));
    return _printsExists("$column LIKE ? ESCAPE '\\'");
  }

  String _regex(String column, String pattern) {
    _params.add(pattern);
    return '$column IS NOT NULL AND regexp(?, $column)';
  }

  /// Substring match on a face column, accelerated by the trigram FTS table.
  String _faceText(String column, QueryValue value, {required String ftsColumn}) {
    switch (value) {
      case RegexValue r:
        return _facesExists(_regex('f.$column', r.pattern));
      case StringValue s:
        return _facesFtsLike('face_text_fts', ftsColumn, s.text);
    }
  }

  /// Face-level FTS predicate as an uncorrelated semi-join: both IN lists
  /// materialize once into indexed ephemerals. The obvious alternative — a
  /// correlated EXISTS containing `f.id IN (SELECT rowid FROM fts …)` —
  /// makes SQLite probe every (card × FTS match) pair; t:creature took ~17s
  /// over the full card database that way.
  String _facesFtsLike(String fts, String column, String text) =>
      'cards.oracle_id IN (SELECT f.oracle_id FROM faces f '
      'WHERE f.id IN (SELECT rowid FROM $fts WHERE ${_like(column, text)}))';

  /// LIKE clause for a substring match. ESCAPE is added only when [text]
  /// contains LIKE metacharacters — its mere presence disables the FTS5
  /// trigram LIKE index pushdown, degrading every lookup to a full scan.
  String _like(String column, String text) {
    final escaped = _escapeLike(text);
    if (escaped == text) {
      _params.add('%$text%');
      return '$column LIKE ?';
    }
    _params.add('%$escaped%');
    return "$column LIKE ? ESCAPE '\\'";
  }

  String _likePattern(String text) => '%${_escapeLike(text)}%';

  String _escapeLike(String text) => text
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');

  String _numOp(String op, PredicateNode p) => switch (op) {
        ':' => '=',
        '=' || '!=' || '<' || '<=' || '>' || '>=' => op,
        _ => throw QuerySemanticError(
            "operator '$op' not valid for '${p.field}'", p.position),
      };

  String _numParam(String value, PredicateNode p) {
    final n = num.tryParse(value) ??
        (throw QuerySemanticError(
            "expected a number for '${p.field}', got '$value'", p.position));
    _params.add(n);
    return '?';
  }

  // Popcount of the five color bits.
  String _popcount(String col) =>
      '(($col & 1) + (($col >> 1) & 1) + (($col >> 2) & 1) + '
      '(($col >> 3) & 1) + (($col >> 4) & 1))';

  String _color(String col, String op, String rawValue, PredicateNode p,
      {required bool identityDefault, bool allowColorlessBit = false}) {
    final v = rawValue.toLowerCase();

    // Numeric color counts: c=2, id<=3 ...
    final asNum = int.tryParse(v);
    if (asNum != null) {
      return '${_popcount(col)} ${_numOp(op == ':' ? '=' : op, p)} $asNum';
    }
    if (v == 'm' || v == 'multicolor' || v == 'multi') {
      return '${_popcount(col)} >= 2';
    }

    var mask = maskFromQueryValue(v);
    if (mask == null && allowColorlessBit && v == 'c') mask = 0;
    if (mask == null) {
      throw QuerySemanticError("invalid color value '$rawValue'", p.position);
    }
    if (allowColorlessBit && v == 'c') {
      return '$col & $maskC != 0';
    }
    if (mask == 0) {
      // colorless
      return switch (op) {
        ':' || '=' || '<=' => '$col = 0',
        '!=' || '>' => '$col != 0',
        '>=' => '1=1',
        _ => '$col = 0',
      };
    }

    // Scryfall quirk: bare `id:x` means subset (<=); bare `c:x` means
    // superset (>=).
    final effectiveOp = op == ':' ? (identityDefault ? '<=' : '>=') : op;
    return switch (effectiveOp) {
      '>=' => '($col & $mask) = $mask',
      '<=' => '($col & ~$mask) = 0',
      '=' => '$col = $mask',
      '!=' => '$col != $mask',
      '<' => '(($col & ~$mask) = 0 AND $col != $mask)',
      '>' => '(($col & $mask) = $mask AND $col != $mask)',
      _ => throw QuerySemanticError(
          "operator '$effectiveOp' not valid for colors", p.position),
    };
  }

  String _stat(String column, String op, String value, PredicateNode p) {
    // Field-vs-field: pow>tou
    const statColumns = {
      'pow': 'pow_num',
      'power': 'pow_num',
      'tou': 'tou_num',
      'toughness': 'tou_num',
      'loy': 'loy_num',
      'loyalty': 'loy_num',
    };
    final otherCol = statColumns[value.toLowerCase()];
    if (otherCol != null) {
      return _facesExists(
          'f.$column IS NOT NULL AND f.$otherCol IS NOT NULL AND '
          'f.$column ${_numOp(op, p)} f.$otherCol');
    }
    if (value == '*') {
      final textCol = column.replaceFirst('_num', '_text');
      return _facesExists("f.$textCol LIKE '%*%'");
    }
    return _facesExists('f.$column IS NOT NULL AND '
        'f.$column ${_numOp(op, p)} ${_numParam(value, p)}');
  }

  String _mana(String op, String value, PredicateNode p) {
    final pips = parseManaCost(value) ??
        (throw QuerySemanticError("invalid mana cost '$value'", p.position));
    final encoded = pips.encode();
    _params.add(encoded);
    final base = switch (op) {
      ':' || '>=' => "mana_geq(f.mana_pips, ?)",
      '<=' => "mana_leq(f.mana_pips, ?)",
      '=' => "mana_eq(f.mana_pips, ?)",
      '!=' => "NOT mana_eq(f.mana_pips, ?)",
      '>' => "mana_geq(f.mana_pips, ?) AND NOT mana_eq(f.mana_pips, ?)",
      '<' => "mana_leq(f.mana_pips, ?) AND NOT mana_eq(f.mana_pips, ?)",
      _ => throw QuerySemanticError(
          "operator '$op' not valid for mana", p.position),
    };
    if (op == '>' || op == '<') _params.add(encoded);
    return _facesExists("f.mana_pips != '' AND $base");
  }

  String _legality(String format, PredicateNode p, String statusTest) {
    final shift = formatShift(format.toLowerCase()) ??
        (throw QuerySemanticError("unknown format '$format'", p.position));
    return '((cards.legalities >> $shift) & 3) $statusTest';
  }

  String _date(String field, String op, String value, PredicateNode p) {
    DateTime? lo, hi; // [lo, hi) covered by the value
    if (field == 'year' || RegExp(r'^\d{4}$').hasMatch(value)) {
      final year = int.tryParse(value);
      if (year == null) {
        throw QuerySemanticError("expected a year, got '$value'", p.position);
      }
      lo = DateTime.utc(year);
      hi = DateTime.utc(year + 1);
    } else {
      final d = DateTime.tryParse(value);
      if (d == null) {
        throw QuerySemanticError(
            "expected a date (yyyy-mm-dd), got '$value'", p.position);
      }
      lo = d;
      hi = d.add(const Duration(days: 1));
    }
    double jd(DateTime d) =>
        d.millisecondsSinceEpoch / Duration.millisecondsPerDay + 2440587.5;
    final loJd = jd(lo), hiJd = jd(hi);
    return _printsExists(switch (op) {
      ':' || '=' => 'p.released_at >= $loJd AND p.released_at < $hiJd',
      '!=' => '(p.released_at < $loJd OR p.released_at >= $hiJd)',
      '>=' => 'p.released_at >= $loJd',
      '>' => 'p.released_at >= $hiJd',
      '<=' => 'p.released_at < $hiJd',
      '<' => 'p.released_at < $loJd',
      _ => throw QuerySemanticError(
          "operator '$op' not valid for dates", p.position),
    });
  }

  String _is(String rawValue, PredicateNode p) {
    final v = rawValue.toLowerCase();

    String printFlag(int flag) => _printsExists('p.flags & $flag != 0');

    switch (v) {
      case 'reserved':
        return 'cards.reserved = 1';
      case 'promo':
        return printFlag(PrintFlag.promo);
      case 'digital':
        return printFlag(PrintFlag.digital);
      case 'fullart' || 'full':
        return printFlag(PrintFlag.fullArt);
      case 'foil':
        return printFlag(PrintFlag.foil);
      case 'nonfoil':
        return printFlag(PrintFlag.nonfoil);
      case 'etched':
        return printFlag(PrintFlag.etched);
      case 'oversized':
        return printFlag(PrintFlag.oversized);
      case 'textless':
        return printFlag(PrintFlag.textless);
      case 'booster':
        return printFlag(PrintFlag.booster);
      case 'hires' || 'highres':
        return printFlag(PrintFlag.highres);
      case 'reprint':
        return printFlag(PrintFlag.reprint);
      case 'spell':
        return "cards.type_line NOT LIKE '%Land%'";
      case 'permanent':
        return _facesExists([
          for (final t in ['Artifact', 'Creature', 'Enchantment', 'Land',
              'Planeswalker', 'Battle'])
            "f.type_line LIKE '%$t%'"
        ].join(' OR '));
      case 'vanilla':
        return _facesExists(
            "f.oracle_text = '' AND f.type_line LIKE '%Creature%'");
      case 'transform' ||
            'flip' ||
            'split' ||
            'meld' ||
            'leveler' ||
            'adventure' ||
            'saga':
        return "cards.layout = '$v'";
      case 'mdfc' || 'modal':
        return "cards.layout = 'modal_dfc'";
      case 'dfc':
        return "cards.layout IN ('transform', 'modal_dfc', 'reversible_card')";
      case 'commander':
        return _facesExists(
            "(f.type_line LIKE '%Legendary%' AND f.type_line LIKE '%Creature%')"
            " OR f.oracle_text LIKE '%can be your commander%'");
      default:
        throw QuerySemanticError(
            "is:$rawValue is not supported (yet)", p.position);
    }
  }

  static const _knownFields = [
    'color', 'identity', 'type', 'oracle', 'name', 'keyword', 'mana',
    'manavalue', 'cmc', 'power', 'toughness', 'loyalty', 'rarity', 'set',
    'artist', 'flavor', 'watermark', 'border', 'frame', 'format', 'banned',
    'restricted', 'layout', 'game', 'lang', 'year', 'date', 'produces',
    'edhrec', 'order', 'direction', 'is', 'not', 'otag', 'oracletag',
    'function',
  ];

  String? _suggestField(String field) {
    String? best;
    var bestScore = 3; // max edit distance 2
    for (final k in _knownFields) {
      final d = _editDistance(field, k);
      if (d < bestScore) {
        bestScore = d;
        best = k;
      }
    }
    return best;
  }

  static int _editDistance(String a, String b) {
    final m = List.generate(
        a.length + 1, (i) => List.filled(b.length + 1, 0));
    for (var i = 0; i <= a.length; i++) {
      m[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      m[0][j] = j;
    }
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        m[i][j] = [
          m[i - 1][j] + 1,
          m[i][j - 1] + 1,
          m[i - 1][j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
    }
    return m[a.length][b.length];
  }

  String _orderBy() {
    final asc = _orderAsc;
    String dir(bool defaultAsc) =>
        (asc ?? defaultAsc) ? 'ASC' : 'DESC';
    return switch (_orderField ?? 'name') {
      'name' => 'cards.name COLLATE NOCASE ${dir(true)}',
      'cmc' || 'mv' => 'cards.cmc ${dir(true)}, cards.name COLLATE NOCASE ASC',
      'released' || 'date' =>
        'cards.released_at_first ${dir(false)}, cards.name COLLATE NOCASE ASC',
      'edhrec' =>
        'cards.edhrec_rank IS NULL, cards.edhrec_rank ${dir(true)}, '
            'cards.name COLLATE NOCASE ASC',
      'rarity' =>
        '(SELECT p.rarity FROM prints p WHERE p.id = cards.preferred_print_id) '
            '${dir(false)}, cards.name COLLATE NOCASE ASC',
      'power' =>
        '(SELECT MAX(f.pow_num) FROM faces f WHERE f.oracle_id = cards.oracle_id) '
            '${dir(false)}, cards.name COLLATE NOCASE ASC',
      'toughness' =>
        '(SELECT MAX(f.tou_num) FROM faces f WHERE f.oracle_id = cards.oracle_id) '
            '${dir(false)}, cards.name COLLATE NOCASE ASC',
      final other =>
        throw QuerySemanticError("order:$other is not supported (yet)"),
    };
  }
}
