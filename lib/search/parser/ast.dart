/// Query AST produced by the parser and consumed by the SQL compiler.
library;

sealed class QueryNode {
  const QueryNode();
}

class AndNode extends QueryNode {
  final List<QueryNode> children;
  const AndNode(this.children);
}

class OrNode extends QueryNode {
  final List<QueryNode> children;
  const OrNode(this.children);
}

class NotNode extends QueryNode {
  final QueryNode child;
  const NotNode(this.child);
}

/// `field op value`, e.g. `t:creature`, `mv<=3`, `o:/^{T}:/`.
class PredicateNode extends QueryNode {
  final String field; // lowercased
  final String op; // : = != < <= > >=
  final QueryValue value;
  final int position; // offset of the field token, for error messages
  const PredicateNode(this.field, this.op, this.value, this.position);
}

/// A bare or quoted word matched against card names; `!` = exact name.
class NameTermNode extends QueryNode {
  final String text;
  final bool exact;
  const NameTermNode(this.text, {this.exact = false});
}

sealed class QueryValue {
  const QueryValue();
}

class StringValue extends QueryValue {
  final String text;
  final bool quoted;
  const StringValue(this.text, {this.quoted = false});
}

class RegexValue extends QueryValue {
  final String pattern;
  const RegexValue(this.pattern);
}
