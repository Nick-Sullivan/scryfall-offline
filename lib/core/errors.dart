/// Typed errors surfaced by the query parser/compiler and rendered inline
/// under the search field (never a silent fallback to name search).
library;

sealed class QueryError implements Exception {
  final String message;

  /// 0-based offset into the query string, when known.
  final int? position;

  const QueryError(this.message, [this.position]);

  @override
  String toString() => 'QueryError: $message';
}

class QuerySyntaxError extends QueryError {
  const QuerySyntaxError(super.message, [super.position]);
}

class QuerySemanticError extends QueryError {
  const QuerySemanticError(super.message, [super.position]);

  /// Optional "did you mean" suggestion (e.g. nearest field name).
  static QuerySemanticError unknownField(String field, {String? suggestion}) =>
      QuerySemanticError(suggestion == null
          ? "unknown field '$field'"
          : "unknown field '$field' — did you mean '$suggestion'?");
}
