import 'package:petitparser/petitparser.dart';

import '../../core/errors.dart';
import 'ast.dart';

/// Scryfall query grammar. Behavioral reference: scryfall.com/docs/syntax and
/// CubeCobra's cardFilters.ne (Apache-2.0). Structure:
///   query  := or
///   or     := and ('or' and)*         -- OR binds looser than implicit AND
///   and    := unary+
///   unary  := '-' unary | '(' or ')' | term
///   term   := '!'name | field op value | nameWord
class ScryfallQueryParser {
  static final Parser<QueryNode> _parser = _build();

  /// Throws [QuerySyntaxError] on malformed input.
  static QueryNode parse(String input) {
    if (input.trim().isEmpty) {
      throw const QuerySyntaxError('empty query', 0);
    }
    final result = _parser.parse(input);
    if (result is Failure) {
      throw QuerySyntaxError(result.message, result.position);
    }
    return result.value;
  }

  static Parser<QueryNode> _build() {
    final query = undefined<QueryNode>();

    final quoted = (char('"') & pattern('^"').star().flatten() & char('"'))
        .map((v) => v[1] as String);

    final regexBody =
        (string(r'\/').map((_) => '/') | pattern('^/')).star().map((p) => p.join());
    final regexLiteral =
        (char('/') & regexBody & char('/')).map((v) => RegexValue(v[1] as String));

    // Bare tokens stop at whitespace and parens; bare name words additionally
    // exclude ':' so malformed predicates fail loudly instead of silently
    // matching names.
    final bareValue = pattern('^ \t\r\n()').plus().flatten();
    final bareWord = pattern('^ \t\r\n():').plus().flatten();

    final fieldToken = letter().plus().flatten();
    final opToken = (string('!=') |
            string('<=') |
            string('>=') |
            char(':') |
            char('=') |
            char('<') |
            char('>'))
        .flatten();

    final predicate =
        (fieldToken.token() & opToken & (quoted.map((t) => StringValue(t, quoted: true)) | regexLiteral | bareValue.map(StringValue.new)))
            .map((v) {
      final field = v[0] as Token<String>;
      return PredicateNode(field.value.toLowerCase(), v[1] as String,
          v[2] as QueryValue, field.start) as QueryNode;
    });

    final exactName = (char('!') & (quoted | bareValue))
        .map((v) => NameTermNode(v[1] as String, exact: true) as QueryNode);

    final nameWord = (quoted.map((t) => NameTermNode(t)) |
            bareWord
                .where((w) => w.toLowerCase() != 'or')
                .map((w) => NameTermNode(w)))
        .map((n) => n as QueryNode);

    final paren =
        (char('(').trim() & query & char(')').trim()).map((v) => v[1] as QueryNode);

    final unary = undefined<QueryNode>();
    final primary = paren | exactName.trim() | predicate.trim() | nameWord.trim();
    unary.set(((char('-').trim() & unary).map((v) => NotNode(v[1] as QueryNode)) |
            primary)
        .cast<QueryNode>());

    final andGroup = unary.plus().map(
        (terms) => terms.length == 1 ? terms.first : AndNode(terms));

    // 'or' must be a standalone word (not the start of a card name).
    final orSep = (string('or', ignoreCase: true) &
            (whitespace() | char('(') | endOfInput()).and())
        .trim();

    final orGroup = andGroup.plusSeparated(orSep).map((list) =>
        list.elements.length == 1 ? list.elements.first : OrNode(list.elements));

    query.set(orGroup);
    return query.end().map((n) => n);
  }
}
