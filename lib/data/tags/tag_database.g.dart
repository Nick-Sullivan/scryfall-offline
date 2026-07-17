// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_database.dart';

// ignore_for_file: type=lint
class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, slug, label, description];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final String slug;
  final String label;
  final String? description;
  const Tag({
    required this.id,
    required this.slug,
    required this.label,
    this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['slug'] = Variable<String>(slug);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      slug: Value(slug),
      label: Value(label),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      slug: serializer.fromJson<String>(json['slug']),
      label: serializer.fromJson<String>(json['label']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'slug': serializer.toJson<String>(slug),
      'label': serializer.toJson<String>(label),
      'description': serializer.toJson<String?>(description),
    };
  }

  Tag copyWith({
    String? id,
    String? slug,
    String? label,
    Value<String?> description = const Value.absent(),
  }) => Tag(
    id: id ?? this.id,
    slug: slug ?? this.slug,
    label: label ?? this.label,
    description: description.present ? description.value : this.description,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      slug: data.slug.present ? data.slug.value : this.slug,
      label: data.label.present ? data.label.value : this.label,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('label: $label, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, slug, label, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.slug == this.slug &&
          other.label == this.label &&
          other.description == this.description);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> slug;
  final Value<String> label;
  final Value<String?> description;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.slug = const Value.absent(),
    this.label = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String slug,
    required String label,
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       slug = Value(slug),
       label = Value(label);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? slug,
    Expression<String>? label,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slug != null) 'slug': slug,
      if (label != null) 'label': label,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? slug,
    Value<String>? label,
    Value<String?>? description,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      label: label ?? this.label,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('label: $label, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagAliasesTable extends TagAliases
    with TableInfo<$TagAliasesTable, TagAliase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagAliasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _aliasMeta = const VerificationMeta('alias');
  @override
  late final GeneratedColumn<String> alias = GeneratedColumn<String>(
    'alias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [alias, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tag_aliases';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagAliase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('alias')) {
      context.handle(
        _aliasMeta,
        alias.isAcceptableOrUnknown(data['alias']!, _aliasMeta),
      );
    } else if (isInserting) {
      context.missing(_aliasMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {alias, tagId};
  @override
  TagAliase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagAliase(
      alias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $TagAliasesTable createAlias(String alias) {
    return $TagAliasesTable(attachedDatabase, alias);
  }
}

class TagAliase extends DataClass implements Insertable<TagAliase> {
  final String alias;
  final String tagId;
  const TagAliase({required this.alias, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['alias'] = Variable<String>(alias);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  TagAliasesCompanion toCompanion(bool nullToAbsent) {
    return TagAliasesCompanion(alias: Value(alias), tagId: Value(tagId));
  }

  factory TagAliase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagAliase(
      alias: serializer.fromJson<String>(json['alias']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'alias': serializer.toJson<String>(alias),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  TagAliase copyWith({String? alias, String? tagId}) =>
      TagAliase(alias: alias ?? this.alias, tagId: tagId ?? this.tagId);
  TagAliase copyWithCompanion(TagAliasesCompanion data) {
    return TagAliase(
      alias: data.alias.present ? data.alias.value : this.alias,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagAliase(')
          ..write('alias: $alias, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(alias, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagAliase &&
          other.alias == this.alias &&
          other.tagId == this.tagId);
}

class TagAliasesCompanion extends UpdateCompanion<TagAliase> {
  final Value<String> alias;
  final Value<String> tagId;
  final Value<int> rowid;
  const TagAliasesCompanion({
    this.alias = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagAliasesCompanion.insert({
    required String alias,
    required String tagId,
    this.rowid = const Value.absent(),
  }) : alias = Value(alias),
       tagId = Value(tagId);
  static Insertable<TagAliase> custom({
    Expression<String>? alias,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (alias != null) 'alias': alias,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagAliasesCompanion copyWith({
    Value<String>? alias,
    Value<String>? tagId,
    Value<int>? rowid,
  }) {
    return TagAliasesCompanion(
      alias: alias ?? this.alias,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (alias.present) {
      map['alias'] = Variable<String>(alias.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagAliasesCompanion(')
          ..write('alias: $alias, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagEdgesTable extends TagEdges with TableInfo<$TagEdgesTable, TagEdge> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagEdgesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [parentId, childId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tag_edges';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagEdge> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_parentIdMeta);
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {parentId, childId};
  @override
  TagEdge map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagEdge(
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
    );
  }

  @override
  $TagEdgesTable createAlias(String alias) {
    return $TagEdgesTable(attachedDatabase, alias);
  }
}

class TagEdge extends DataClass implements Insertable<TagEdge> {
  final String parentId;
  final String childId;
  const TagEdge({required this.parentId, required this.childId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['parent_id'] = Variable<String>(parentId);
    map['child_id'] = Variable<String>(childId);
    return map;
  }

  TagEdgesCompanion toCompanion(bool nullToAbsent) {
    return TagEdgesCompanion(
      parentId: Value(parentId),
      childId: Value(childId),
    );
  }

  factory TagEdge.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagEdge(
      parentId: serializer.fromJson<String>(json['parentId']),
      childId: serializer.fromJson<String>(json['childId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'parentId': serializer.toJson<String>(parentId),
      'childId': serializer.toJson<String>(childId),
    };
  }

  TagEdge copyWith({String? parentId, String? childId}) => TagEdge(
    parentId: parentId ?? this.parentId,
    childId: childId ?? this.childId,
  );
  TagEdge copyWithCompanion(TagEdgesCompanion data) {
    return TagEdge(
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      childId: data.childId.present ? data.childId.value : this.childId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagEdge(')
          ..write('parentId: $parentId, ')
          ..write('childId: $childId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(parentId, childId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagEdge &&
          other.parentId == this.parentId &&
          other.childId == this.childId);
}

class TagEdgesCompanion extends UpdateCompanion<TagEdge> {
  final Value<String> parentId;
  final Value<String> childId;
  final Value<int> rowid;
  const TagEdgesCompanion({
    this.parentId = const Value.absent(),
    this.childId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagEdgesCompanion.insert({
    required String parentId,
    required String childId,
    this.rowid = const Value.absent(),
  }) : parentId = Value(parentId),
       childId = Value(childId);
  static Insertable<TagEdge> custom({
    Expression<String>? parentId,
    Expression<String>? childId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (parentId != null) 'parent_id': parentId,
      if (childId != null) 'child_id': childId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagEdgesCompanion copyWith({
    Value<String>? parentId,
    Value<String>? childId,
    Value<int>? rowid,
  }) {
    return TagEdgesCompanion(
      parentId: parentId ?? this.parentId,
      childId: childId ?? this.childId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagEdgesCompanion(')
          ..write('parentId: $parentId, ')
          ..write('childId: $childId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagCardsTable extends TagCards with TableInfo<$TagCardsTable, TagCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _oracleIdMeta = const VerificationMeta(
    'oracleId',
  );
  @override
  late final GeneratedColumn<String> oracleId = GeneratedColumn<String>(
    'oracle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [tagId, oracleId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tag_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('oracle_id')) {
      context.handle(
        _oracleIdMeta,
        oracleId.isAcceptableOrUnknown(data['oracle_id']!, _oracleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_oracleIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tagId, oracleId};
  @override
  TagCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagCard(
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
      oracleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}oracle_id'],
      )!,
    );
  }

  @override
  $TagCardsTable createAlias(String alias) {
    return $TagCardsTable(attachedDatabase, alias);
  }
}

class TagCard extends DataClass implements Insertable<TagCard> {
  final String tagId;
  final String oracleId;
  const TagCard({required this.tagId, required this.oracleId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tag_id'] = Variable<String>(tagId);
    map['oracle_id'] = Variable<String>(oracleId);
    return map;
  }

  TagCardsCompanion toCompanion(bool nullToAbsent) {
    return TagCardsCompanion(tagId: Value(tagId), oracleId: Value(oracleId));
  }

  factory TagCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagCard(
      tagId: serializer.fromJson<String>(json['tagId']),
      oracleId: serializer.fromJson<String>(json['oracleId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tagId': serializer.toJson<String>(tagId),
      'oracleId': serializer.toJson<String>(oracleId),
    };
  }

  TagCard copyWith({String? tagId, String? oracleId}) =>
      TagCard(tagId: tagId ?? this.tagId, oracleId: oracleId ?? this.oracleId);
  TagCard copyWithCompanion(TagCardsCompanion data) {
    return TagCard(
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      oracleId: data.oracleId.present ? data.oracleId.value : this.oracleId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagCard(')
          ..write('tagId: $tagId, ')
          ..write('oracleId: $oracleId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tagId, oracleId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagCard &&
          other.tagId == this.tagId &&
          other.oracleId == this.oracleId);
}

class TagCardsCompanion extends UpdateCompanion<TagCard> {
  final Value<String> tagId;
  final Value<String> oracleId;
  final Value<int> rowid;
  const TagCardsCompanion({
    this.tagId = const Value.absent(),
    this.oracleId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagCardsCompanion.insert({
    required String tagId,
    required String oracleId,
    this.rowid = const Value.absent(),
  }) : tagId = Value(tagId),
       oracleId = Value(oracleId);
  static Insertable<TagCard> custom({
    Expression<String>? tagId,
    Expression<String>? oracleId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tagId != null) 'tag_id': tagId,
      if (oracleId != null) 'oracle_id': oracleId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagCardsCompanion copyWith({
    Value<String>? tagId,
    Value<String>? oracleId,
    Value<int>? rowid,
  }) {
    return TagCardsCompanion(
      tagId: tagId ?? this.tagId,
      oracleId: oracleId ?? this.oracleId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (oracleId.present) {
      map['oracle_id'] = Variable<String>(oracleId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagCardsCompanion(')
          ..write('tagId: $tagId, ')
          ..write('oracleId: $oracleId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagPackMetaTable extends TagPackMeta
    with TableInfo<$TagPackMetaTable, TagPackMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagPackMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tag_pack_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagPackMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  TagPackMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagPackMetaData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $TagPackMetaTable createAlias(String alias) {
    return $TagPackMetaTable(attachedDatabase, alias);
  }
}

class TagPackMetaData extends DataClass implements Insertable<TagPackMetaData> {
  final String key;
  final String value;
  const TagPackMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  TagPackMetaCompanion toCompanion(bool nullToAbsent) {
    return TagPackMetaCompanion(key: Value(key), value: Value(value));
  }

  factory TagPackMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagPackMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  TagPackMetaData copyWith({String? key, String? value}) =>
      TagPackMetaData(key: key ?? this.key, value: value ?? this.value);
  TagPackMetaData copyWithCompanion(TagPackMetaCompanion data) {
    return TagPackMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagPackMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagPackMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class TagPackMetaCompanion extends UpdateCompanion<TagPackMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const TagPackMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagPackMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<TagPackMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagPackMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return TagPackMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagPackMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$TagDatabase extends GeneratedDatabase {
  _$TagDatabase(QueryExecutor e) : super(e);
  $TagDatabaseManager get managers => $TagDatabaseManager(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $TagAliasesTable tagAliases = $TagAliasesTable(this);
  late final $TagEdgesTable tagEdges = $TagEdgesTable(this);
  late final $TagCardsTable tagCards = $TagCardsTable(this);
  late final $TagPackMetaTable tagPackMeta = $TagPackMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tags,
    tagAliases,
    tagEdges,
    tagCards,
    tagPackMeta,
  ];
}

typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      required String id,
      required String slug,
      required String label,
      Value<String?> description,
      Value<int> rowid,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String> slug,
      Value<String> label,
      Value<String?> description,
      Value<int> rowid,
    });

class $$TagsTableFilterComposer extends Composer<_$TagDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagsTableOrderingComposer extends Composer<_$TagDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$TagDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$TagDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, BaseReferences<_$TagDatabase, $TagsTable, Tag>),
          Tag,
          PrefetchHooks Function()
        > {
  $$TagsTableTableManager(_$TagDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                slug: slug,
                label: label,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String slug,
                required String label,
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                slug: slug,
                label: label,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$TagDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, BaseReferences<_$TagDatabase, $TagsTable, Tag>),
      Tag,
      PrefetchHooks Function()
    >;
typedef $$TagAliasesTableCreateCompanionBuilder =
    TagAliasesCompanion Function({
      required String alias,
      required String tagId,
      Value<int> rowid,
    });
typedef $$TagAliasesTableUpdateCompanionBuilder =
    TagAliasesCompanion Function({
      Value<String> alias,
      Value<String> tagId,
      Value<int> rowid,
    });

class $$TagAliasesTableFilterComposer
    extends Composer<_$TagDatabase, $TagAliasesTable> {
  $$TagAliasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagAliasesTableOrderingComposer
    extends Composer<_$TagDatabase, $TagAliasesTable> {
  $$TagAliasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagAliasesTableAnnotationComposer
    extends Composer<_$TagDatabase, $TagAliasesTable> {
  $$TagAliasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => column);

  GeneratedColumn<String> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);
}

class $$TagAliasesTableTableManager
    extends
        RootTableManager<
          _$TagDatabase,
          $TagAliasesTable,
          TagAliase,
          $$TagAliasesTableFilterComposer,
          $$TagAliasesTableOrderingComposer,
          $$TagAliasesTableAnnotationComposer,
          $$TagAliasesTableCreateCompanionBuilder,
          $$TagAliasesTableUpdateCompanionBuilder,
          (
            TagAliase,
            BaseReferences<_$TagDatabase, $TagAliasesTable, TagAliase>,
          ),
          TagAliase,
          PrefetchHooks Function()
        > {
  $$TagAliasesTableTableManager(_$TagDatabase db, $TagAliasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagAliasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagAliasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagAliasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> alias = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  TagAliasesCompanion(alias: alias, tagId: tagId, rowid: rowid),
          createCompanionCallback:
              ({
                required String alias,
                required String tagId,
                Value<int> rowid = const Value.absent(),
              }) => TagAliasesCompanion.insert(
                alias: alias,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagAliasesTableProcessedTableManager =
    ProcessedTableManager<
      _$TagDatabase,
      $TagAliasesTable,
      TagAliase,
      $$TagAliasesTableFilterComposer,
      $$TagAliasesTableOrderingComposer,
      $$TagAliasesTableAnnotationComposer,
      $$TagAliasesTableCreateCompanionBuilder,
      $$TagAliasesTableUpdateCompanionBuilder,
      (TagAliase, BaseReferences<_$TagDatabase, $TagAliasesTable, TagAliase>),
      TagAliase,
      PrefetchHooks Function()
    >;
typedef $$TagEdgesTableCreateCompanionBuilder =
    TagEdgesCompanion Function({
      required String parentId,
      required String childId,
      Value<int> rowid,
    });
typedef $$TagEdgesTableUpdateCompanionBuilder =
    TagEdgesCompanion Function({
      Value<String> parentId,
      Value<String> childId,
      Value<int> rowid,
    });

class $$TagEdgesTableFilterComposer
    extends Composer<_$TagDatabase, $TagEdgesTable> {
  $$TagEdgesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagEdgesTableOrderingComposer
    extends Composer<_$TagDatabase, $TagEdgesTable> {
  $$TagEdgesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagEdgesTableAnnotationComposer
    extends Composer<_$TagDatabase, $TagEdgesTable> {
  $$TagEdgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get childId =>
      $composableBuilder(column: $table.childId, builder: (column) => column);
}

class $$TagEdgesTableTableManager
    extends
        RootTableManager<
          _$TagDatabase,
          $TagEdgesTable,
          TagEdge,
          $$TagEdgesTableFilterComposer,
          $$TagEdgesTableOrderingComposer,
          $$TagEdgesTableAnnotationComposer,
          $$TagEdgesTableCreateCompanionBuilder,
          $$TagEdgesTableUpdateCompanionBuilder,
          (TagEdge, BaseReferences<_$TagDatabase, $TagEdgesTable, TagEdge>),
          TagEdge,
          PrefetchHooks Function()
        > {
  $$TagEdgesTableTableManager(_$TagDatabase db, $TagEdgesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagEdgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagEdgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagEdgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> parentId = const Value.absent(),
                Value<String> childId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagEdgesCompanion(
                parentId: parentId,
                childId: childId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String parentId,
                required String childId,
                Value<int> rowid = const Value.absent(),
              }) => TagEdgesCompanion.insert(
                parentId: parentId,
                childId: childId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagEdgesTableProcessedTableManager =
    ProcessedTableManager<
      _$TagDatabase,
      $TagEdgesTable,
      TagEdge,
      $$TagEdgesTableFilterComposer,
      $$TagEdgesTableOrderingComposer,
      $$TagEdgesTableAnnotationComposer,
      $$TagEdgesTableCreateCompanionBuilder,
      $$TagEdgesTableUpdateCompanionBuilder,
      (TagEdge, BaseReferences<_$TagDatabase, $TagEdgesTable, TagEdge>),
      TagEdge,
      PrefetchHooks Function()
    >;
typedef $$TagCardsTableCreateCompanionBuilder =
    TagCardsCompanion Function({
      required String tagId,
      required String oracleId,
      Value<int> rowid,
    });
typedef $$TagCardsTableUpdateCompanionBuilder =
    TagCardsCompanion Function({
      Value<String> tagId,
      Value<String> oracleId,
      Value<int> rowid,
    });

class $$TagCardsTableFilterComposer
    extends Composer<_$TagDatabase, $TagCardsTable> {
  $$TagCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oracleId => $composableBuilder(
    column: $table.oracleId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagCardsTableOrderingComposer
    extends Composer<_$TagDatabase, $TagCardsTable> {
  $$TagCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oracleId => $composableBuilder(
    column: $table.oracleId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagCardsTableAnnotationComposer
    extends Composer<_$TagDatabase, $TagCardsTable> {
  $$TagCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);

  GeneratedColumn<String> get oracleId =>
      $composableBuilder(column: $table.oracleId, builder: (column) => column);
}

class $$TagCardsTableTableManager
    extends
        RootTableManager<
          _$TagDatabase,
          $TagCardsTable,
          TagCard,
          $$TagCardsTableFilterComposer,
          $$TagCardsTableOrderingComposer,
          $$TagCardsTableAnnotationComposer,
          $$TagCardsTableCreateCompanionBuilder,
          $$TagCardsTableUpdateCompanionBuilder,
          (TagCard, BaseReferences<_$TagDatabase, $TagCardsTable, TagCard>),
          TagCard,
          PrefetchHooks Function()
        > {
  $$TagCardsTableTableManager(_$TagDatabase db, $TagCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tagId = const Value.absent(),
                Value<String> oracleId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagCardsCompanion(
                tagId: tagId,
                oracleId: oracleId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tagId,
                required String oracleId,
                Value<int> rowid = const Value.absent(),
              }) => TagCardsCompanion.insert(
                tagId: tagId,
                oracleId: oracleId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$TagDatabase,
      $TagCardsTable,
      TagCard,
      $$TagCardsTableFilterComposer,
      $$TagCardsTableOrderingComposer,
      $$TagCardsTableAnnotationComposer,
      $$TagCardsTableCreateCompanionBuilder,
      $$TagCardsTableUpdateCompanionBuilder,
      (TagCard, BaseReferences<_$TagDatabase, $TagCardsTable, TagCard>),
      TagCard,
      PrefetchHooks Function()
    >;
typedef $$TagPackMetaTableCreateCompanionBuilder =
    TagPackMetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$TagPackMetaTableUpdateCompanionBuilder =
    TagPackMetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$TagPackMetaTableFilterComposer
    extends Composer<_$TagDatabase, $TagPackMetaTable> {
  $$TagPackMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagPackMetaTableOrderingComposer
    extends Composer<_$TagDatabase, $TagPackMetaTable> {
  $$TagPackMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagPackMetaTableAnnotationComposer
    extends Composer<_$TagDatabase, $TagPackMetaTable> {
  $$TagPackMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$TagPackMetaTableTableManager
    extends
        RootTableManager<
          _$TagDatabase,
          $TagPackMetaTable,
          TagPackMetaData,
          $$TagPackMetaTableFilterComposer,
          $$TagPackMetaTableOrderingComposer,
          $$TagPackMetaTableAnnotationComposer,
          $$TagPackMetaTableCreateCompanionBuilder,
          $$TagPackMetaTableUpdateCompanionBuilder,
          (
            TagPackMetaData,
            BaseReferences<_$TagDatabase, $TagPackMetaTable, TagPackMetaData>,
          ),
          TagPackMetaData,
          PrefetchHooks Function()
        > {
  $$TagPackMetaTableTableManager(_$TagDatabase db, $TagPackMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagPackMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagPackMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagPackMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagPackMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => TagPackMetaCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagPackMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$TagDatabase,
      $TagPackMetaTable,
      TagPackMetaData,
      $$TagPackMetaTableFilterComposer,
      $$TagPackMetaTableOrderingComposer,
      $$TagPackMetaTableAnnotationComposer,
      $$TagPackMetaTableCreateCompanionBuilder,
      $$TagPackMetaTableUpdateCompanionBuilder,
      (
        TagPackMetaData,
        BaseReferences<_$TagDatabase, $TagPackMetaTable, TagPackMetaData>,
      ),
      TagPackMetaData,
      PrefetchHooks Function()
    >;

class $TagDatabaseManager {
  final _$TagDatabase _db;
  $TagDatabaseManager(this._db);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$TagAliasesTableTableManager get tagAliases =>
      $$TagAliasesTableTableManager(_db, _db.tagAliases);
  $$TagEdgesTableTableManager get tagEdges =>
      $$TagEdgesTableTableManager(_db, _db.tagEdges);
  $$TagCardsTableTableManager get tagCards =>
      $$TagCardsTableTableManager(_db, _db.tagCards);
  $$TagPackMetaTableTableManager get tagPackMeta =>
      $$TagPackMetaTableTableManager(_db, _db.tagPackMeta);
}
