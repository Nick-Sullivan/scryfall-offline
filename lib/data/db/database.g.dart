// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CardsTable extends Cards with TableInfo<$CardsTable, Card> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cmcMeta = const VerificationMeta('cmc');
  @override
  late final GeneratedColumn<double> cmc = GeneratedColumn<double>(
    'cmc',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manaCostMeta = const VerificationMeta(
    'manaCost',
  );
  @override
  late final GeneratedColumn<String> manaCost = GeneratedColumn<String>(
    'mana_cost',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeLineMeta = const VerificationMeta(
    'typeLine',
  );
  @override
  late final GeneratedColumn<String> typeLine = GeneratedColumn<String>(
    'type_line',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorsMeta = const VerificationMeta('colors');
  @override
  late final GeneratedColumn<int> colors = GeneratedColumn<int>(
    'colors',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorIdentityMeta = const VerificationMeta(
    'colorIdentity',
  );
  @override
  late final GeneratedColumn<int> colorIdentity = GeneratedColumn<int>(
    'color_identity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _producedManaMeta = const VerificationMeta(
    'producedMana',
  );
  @override
  late final GeneratedColumn<int> producedMana = GeneratedColumn<int>(
    'produced_mana',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorCountMeta = const VerificationMeta(
    'colorCount',
  );
  @override
  late final GeneratedColumn<int> colorCount = GeneratedColumn<int>(
    'color_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keywordsPipeMeta = const VerificationMeta(
    'keywordsPipe',
  );
  @override
  late final GeneratedColumn<String> keywordsPipe = GeneratedColumn<String>(
    'keywords_pipe',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reservedMeta = const VerificationMeta(
    'reserved',
  );
  @override
  late final GeneratedColumn<bool> reserved = GeneratedColumn<bool>(
    'reserved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reserved" IN (0, 1))',
    ),
  );
  static const VerificationMeta _edhrecRankMeta = const VerificationMeta(
    'edhrecRank',
  );
  @override
  late final GeneratedColumn<int> edhrecRank = GeneratedColumn<int>(
    'edhrec_rank',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _layoutMeta = const VerificationMeta('layout');
  @override
  late final GeneratedColumn<String> layout = GeneratedColumn<String>(
    'layout',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _legalitiesMeta = const VerificationMeta(
    'legalities',
  );
  @override
  late final GeneratedColumn<int> legalities = GeneratedColumn<int>(
    'legalities',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _preferredPrintIdMeta = const VerificationMeta(
    'preferredPrintId',
  );
  @override
  late final GeneratedColumn<String> preferredPrintId = GeneratedColumn<String>(
    'preferred_print_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releasedAtFirstMeta = const VerificationMeta(
    'releasedAtFirst',
  );
  @override
  late final GeneratedColumn<double> releasedAtFirst = GeneratedColumn<double>(
    'released_at_first',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    oracleId,
    name,
    cmc,
    manaCost,
    typeLine,
    colors,
    colorIdentity,
    producedMana,
    colorCount,
    keywordsPipe,
    reserved,
    edhrecRank,
    layout,
    legalities,
    preferredPrintId,
    releasedAtFirst,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<Card> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('oracle_id')) {
      context.handle(
        _oracleIdMeta,
        oracleId.isAcceptableOrUnknown(data['oracle_id']!, _oracleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_oracleIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cmc')) {
      context.handle(
        _cmcMeta,
        cmc.isAcceptableOrUnknown(data['cmc']!, _cmcMeta),
      );
    } else if (isInserting) {
      context.missing(_cmcMeta);
    }
    if (data.containsKey('mana_cost')) {
      context.handle(
        _manaCostMeta,
        manaCost.isAcceptableOrUnknown(data['mana_cost']!, _manaCostMeta),
      );
    }
    if (data.containsKey('type_line')) {
      context.handle(
        _typeLineMeta,
        typeLine.isAcceptableOrUnknown(data['type_line']!, _typeLineMeta),
      );
    } else if (isInserting) {
      context.missing(_typeLineMeta);
    }
    if (data.containsKey('colors')) {
      context.handle(
        _colorsMeta,
        colors.isAcceptableOrUnknown(data['colors']!, _colorsMeta),
      );
    } else if (isInserting) {
      context.missing(_colorsMeta);
    }
    if (data.containsKey('color_identity')) {
      context.handle(
        _colorIdentityMeta,
        colorIdentity.isAcceptableOrUnknown(
          data['color_identity']!,
          _colorIdentityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_colorIdentityMeta);
    }
    if (data.containsKey('produced_mana')) {
      context.handle(
        _producedManaMeta,
        producedMana.isAcceptableOrUnknown(
          data['produced_mana']!,
          _producedManaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_producedManaMeta);
    }
    if (data.containsKey('color_count')) {
      context.handle(
        _colorCountMeta,
        colorCount.isAcceptableOrUnknown(data['color_count']!, _colorCountMeta),
      );
    } else if (isInserting) {
      context.missing(_colorCountMeta);
    }
    if (data.containsKey('keywords_pipe')) {
      context.handle(
        _keywordsPipeMeta,
        keywordsPipe.isAcceptableOrUnknown(
          data['keywords_pipe']!,
          _keywordsPipeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_keywordsPipeMeta);
    }
    if (data.containsKey('reserved')) {
      context.handle(
        _reservedMeta,
        reserved.isAcceptableOrUnknown(data['reserved']!, _reservedMeta),
      );
    } else if (isInserting) {
      context.missing(_reservedMeta);
    }
    if (data.containsKey('edhrec_rank')) {
      context.handle(
        _edhrecRankMeta,
        edhrecRank.isAcceptableOrUnknown(data['edhrec_rank']!, _edhrecRankMeta),
      );
    }
    if (data.containsKey('layout')) {
      context.handle(
        _layoutMeta,
        layout.isAcceptableOrUnknown(data['layout']!, _layoutMeta),
      );
    } else if (isInserting) {
      context.missing(_layoutMeta);
    }
    if (data.containsKey('legalities')) {
      context.handle(
        _legalitiesMeta,
        legalities.isAcceptableOrUnknown(data['legalities']!, _legalitiesMeta),
      );
    } else if (isInserting) {
      context.missing(_legalitiesMeta);
    }
    if (data.containsKey('preferred_print_id')) {
      context.handle(
        _preferredPrintIdMeta,
        preferredPrintId.isAcceptableOrUnknown(
          data['preferred_print_id']!,
          _preferredPrintIdMeta,
        ),
      );
    }
    if (data.containsKey('released_at_first')) {
      context.handle(
        _releasedAtFirstMeta,
        releasedAtFirst.isAcceptableOrUnknown(
          data['released_at_first']!,
          _releasedAtFirstMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_releasedAtFirstMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {oracleId};
  @override
  Card map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Card(
      oracleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}oracle_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      cmc: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cmc'],
      )!,
      manaCost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mana_cost'],
      ),
      typeLine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_line'],
      )!,
      colors: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}colors'],
      )!,
      colorIdentity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_identity'],
      )!,
      producedMana: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}produced_mana'],
      )!,
      colorCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_count'],
      )!,
      keywordsPipe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keywords_pipe'],
      )!,
      reserved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reserved'],
      )!,
      edhrecRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edhrec_rank'],
      ),
      layout: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layout'],
      )!,
      legalities: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}legalities'],
      )!,
      preferredPrintId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_print_id'],
      ),
      releasedAtFirst: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}released_at_first'],
      )!,
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }
}

class Card extends DataClass implements Insertable<Card> {
  final String oracleId;
  final String name;
  final double cmc;
  final String? manaCost;
  final String typeLine;
  final int colors;
  final int colorIdentity;
  final int producedMana;
  final int colorCount;
  final String keywordsPipe;
  final bool reserved;
  final int? edhrecRank;
  final String layout;
  final int legalities;
  final String? preferredPrintId;
  final double releasedAtFirst;
  const Card({
    required this.oracleId,
    required this.name,
    required this.cmc,
    this.manaCost,
    required this.typeLine,
    required this.colors,
    required this.colorIdentity,
    required this.producedMana,
    required this.colorCount,
    required this.keywordsPipe,
    required this.reserved,
    this.edhrecRank,
    required this.layout,
    required this.legalities,
    this.preferredPrintId,
    required this.releasedAtFirst,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['oracle_id'] = Variable<String>(oracleId);
    map['name'] = Variable<String>(name);
    map['cmc'] = Variable<double>(cmc);
    if (!nullToAbsent || manaCost != null) {
      map['mana_cost'] = Variable<String>(manaCost);
    }
    map['type_line'] = Variable<String>(typeLine);
    map['colors'] = Variable<int>(colors);
    map['color_identity'] = Variable<int>(colorIdentity);
    map['produced_mana'] = Variable<int>(producedMana);
    map['color_count'] = Variable<int>(colorCount);
    map['keywords_pipe'] = Variable<String>(keywordsPipe);
    map['reserved'] = Variable<bool>(reserved);
    if (!nullToAbsent || edhrecRank != null) {
      map['edhrec_rank'] = Variable<int>(edhrecRank);
    }
    map['layout'] = Variable<String>(layout);
    map['legalities'] = Variable<int>(legalities);
    if (!nullToAbsent || preferredPrintId != null) {
      map['preferred_print_id'] = Variable<String>(preferredPrintId);
    }
    map['released_at_first'] = Variable<double>(releasedAtFirst);
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      oracleId: Value(oracleId),
      name: Value(name),
      cmc: Value(cmc),
      manaCost: manaCost == null && nullToAbsent
          ? const Value.absent()
          : Value(manaCost),
      typeLine: Value(typeLine),
      colors: Value(colors),
      colorIdentity: Value(colorIdentity),
      producedMana: Value(producedMana),
      colorCount: Value(colorCount),
      keywordsPipe: Value(keywordsPipe),
      reserved: Value(reserved),
      edhrecRank: edhrecRank == null && nullToAbsent
          ? const Value.absent()
          : Value(edhrecRank),
      layout: Value(layout),
      legalities: Value(legalities),
      preferredPrintId: preferredPrintId == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredPrintId),
      releasedAtFirst: Value(releasedAtFirst),
    );
  }

  factory Card.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Card(
      oracleId: serializer.fromJson<String>(json['oracleId']),
      name: serializer.fromJson<String>(json['name']),
      cmc: serializer.fromJson<double>(json['cmc']),
      manaCost: serializer.fromJson<String?>(json['manaCost']),
      typeLine: serializer.fromJson<String>(json['typeLine']),
      colors: serializer.fromJson<int>(json['colors']),
      colorIdentity: serializer.fromJson<int>(json['colorIdentity']),
      producedMana: serializer.fromJson<int>(json['producedMana']),
      colorCount: serializer.fromJson<int>(json['colorCount']),
      keywordsPipe: serializer.fromJson<String>(json['keywordsPipe']),
      reserved: serializer.fromJson<bool>(json['reserved']),
      edhrecRank: serializer.fromJson<int?>(json['edhrecRank']),
      layout: serializer.fromJson<String>(json['layout']),
      legalities: serializer.fromJson<int>(json['legalities']),
      preferredPrintId: serializer.fromJson<String?>(json['preferredPrintId']),
      releasedAtFirst: serializer.fromJson<double>(json['releasedAtFirst']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'oracleId': serializer.toJson<String>(oracleId),
      'name': serializer.toJson<String>(name),
      'cmc': serializer.toJson<double>(cmc),
      'manaCost': serializer.toJson<String?>(manaCost),
      'typeLine': serializer.toJson<String>(typeLine),
      'colors': serializer.toJson<int>(colors),
      'colorIdentity': serializer.toJson<int>(colorIdentity),
      'producedMana': serializer.toJson<int>(producedMana),
      'colorCount': serializer.toJson<int>(colorCount),
      'keywordsPipe': serializer.toJson<String>(keywordsPipe),
      'reserved': serializer.toJson<bool>(reserved),
      'edhrecRank': serializer.toJson<int?>(edhrecRank),
      'layout': serializer.toJson<String>(layout),
      'legalities': serializer.toJson<int>(legalities),
      'preferredPrintId': serializer.toJson<String?>(preferredPrintId),
      'releasedAtFirst': serializer.toJson<double>(releasedAtFirst),
    };
  }

  Card copyWith({
    String? oracleId,
    String? name,
    double? cmc,
    Value<String?> manaCost = const Value.absent(),
    String? typeLine,
    int? colors,
    int? colorIdentity,
    int? producedMana,
    int? colorCount,
    String? keywordsPipe,
    bool? reserved,
    Value<int?> edhrecRank = const Value.absent(),
    String? layout,
    int? legalities,
    Value<String?> preferredPrintId = const Value.absent(),
    double? releasedAtFirst,
  }) => Card(
    oracleId: oracleId ?? this.oracleId,
    name: name ?? this.name,
    cmc: cmc ?? this.cmc,
    manaCost: manaCost.present ? manaCost.value : this.manaCost,
    typeLine: typeLine ?? this.typeLine,
    colors: colors ?? this.colors,
    colorIdentity: colorIdentity ?? this.colorIdentity,
    producedMana: producedMana ?? this.producedMana,
    colorCount: colorCount ?? this.colorCount,
    keywordsPipe: keywordsPipe ?? this.keywordsPipe,
    reserved: reserved ?? this.reserved,
    edhrecRank: edhrecRank.present ? edhrecRank.value : this.edhrecRank,
    layout: layout ?? this.layout,
    legalities: legalities ?? this.legalities,
    preferredPrintId: preferredPrintId.present
        ? preferredPrintId.value
        : this.preferredPrintId,
    releasedAtFirst: releasedAtFirst ?? this.releasedAtFirst,
  );
  Card copyWithCompanion(CardsCompanion data) {
    return Card(
      oracleId: data.oracleId.present ? data.oracleId.value : this.oracleId,
      name: data.name.present ? data.name.value : this.name,
      cmc: data.cmc.present ? data.cmc.value : this.cmc,
      manaCost: data.manaCost.present ? data.manaCost.value : this.manaCost,
      typeLine: data.typeLine.present ? data.typeLine.value : this.typeLine,
      colors: data.colors.present ? data.colors.value : this.colors,
      colorIdentity: data.colorIdentity.present
          ? data.colorIdentity.value
          : this.colorIdentity,
      producedMana: data.producedMana.present
          ? data.producedMana.value
          : this.producedMana,
      colorCount: data.colorCount.present
          ? data.colorCount.value
          : this.colorCount,
      keywordsPipe: data.keywordsPipe.present
          ? data.keywordsPipe.value
          : this.keywordsPipe,
      reserved: data.reserved.present ? data.reserved.value : this.reserved,
      edhrecRank: data.edhrecRank.present
          ? data.edhrecRank.value
          : this.edhrecRank,
      layout: data.layout.present ? data.layout.value : this.layout,
      legalities: data.legalities.present
          ? data.legalities.value
          : this.legalities,
      preferredPrintId: data.preferredPrintId.present
          ? data.preferredPrintId.value
          : this.preferredPrintId,
      releasedAtFirst: data.releasedAtFirst.present
          ? data.releasedAtFirst.value
          : this.releasedAtFirst,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Card(')
          ..write('oracleId: $oracleId, ')
          ..write('name: $name, ')
          ..write('cmc: $cmc, ')
          ..write('manaCost: $manaCost, ')
          ..write('typeLine: $typeLine, ')
          ..write('colors: $colors, ')
          ..write('colorIdentity: $colorIdentity, ')
          ..write('producedMana: $producedMana, ')
          ..write('colorCount: $colorCount, ')
          ..write('keywordsPipe: $keywordsPipe, ')
          ..write('reserved: $reserved, ')
          ..write('edhrecRank: $edhrecRank, ')
          ..write('layout: $layout, ')
          ..write('legalities: $legalities, ')
          ..write('preferredPrintId: $preferredPrintId, ')
          ..write('releasedAtFirst: $releasedAtFirst')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    oracleId,
    name,
    cmc,
    manaCost,
    typeLine,
    colors,
    colorIdentity,
    producedMana,
    colorCount,
    keywordsPipe,
    reserved,
    edhrecRank,
    layout,
    legalities,
    preferredPrintId,
    releasedAtFirst,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Card &&
          other.oracleId == this.oracleId &&
          other.name == this.name &&
          other.cmc == this.cmc &&
          other.manaCost == this.manaCost &&
          other.typeLine == this.typeLine &&
          other.colors == this.colors &&
          other.colorIdentity == this.colorIdentity &&
          other.producedMana == this.producedMana &&
          other.colorCount == this.colorCount &&
          other.keywordsPipe == this.keywordsPipe &&
          other.reserved == this.reserved &&
          other.edhrecRank == this.edhrecRank &&
          other.layout == this.layout &&
          other.legalities == this.legalities &&
          other.preferredPrintId == this.preferredPrintId &&
          other.releasedAtFirst == this.releasedAtFirst);
}

class CardsCompanion extends UpdateCompanion<Card> {
  final Value<String> oracleId;
  final Value<String> name;
  final Value<double> cmc;
  final Value<String?> manaCost;
  final Value<String> typeLine;
  final Value<int> colors;
  final Value<int> colorIdentity;
  final Value<int> producedMana;
  final Value<int> colorCount;
  final Value<String> keywordsPipe;
  final Value<bool> reserved;
  final Value<int?> edhrecRank;
  final Value<String> layout;
  final Value<int> legalities;
  final Value<String?> preferredPrintId;
  final Value<double> releasedAtFirst;
  final Value<int> rowid;
  const CardsCompanion({
    this.oracleId = const Value.absent(),
    this.name = const Value.absent(),
    this.cmc = const Value.absent(),
    this.manaCost = const Value.absent(),
    this.typeLine = const Value.absent(),
    this.colors = const Value.absent(),
    this.colorIdentity = const Value.absent(),
    this.producedMana = const Value.absent(),
    this.colorCount = const Value.absent(),
    this.keywordsPipe = const Value.absent(),
    this.reserved = const Value.absent(),
    this.edhrecRank = const Value.absent(),
    this.layout = const Value.absent(),
    this.legalities = const Value.absent(),
    this.preferredPrintId = const Value.absent(),
    this.releasedAtFirst = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardsCompanion.insert({
    required String oracleId,
    required String name,
    required double cmc,
    this.manaCost = const Value.absent(),
    required String typeLine,
    required int colors,
    required int colorIdentity,
    required int producedMana,
    required int colorCount,
    required String keywordsPipe,
    required bool reserved,
    this.edhrecRank = const Value.absent(),
    required String layout,
    required int legalities,
    this.preferredPrintId = const Value.absent(),
    required double releasedAtFirst,
    this.rowid = const Value.absent(),
  }) : oracleId = Value(oracleId),
       name = Value(name),
       cmc = Value(cmc),
       typeLine = Value(typeLine),
       colors = Value(colors),
       colorIdentity = Value(colorIdentity),
       producedMana = Value(producedMana),
       colorCount = Value(colorCount),
       keywordsPipe = Value(keywordsPipe),
       reserved = Value(reserved),
       layout = Value(layout),
       legalities = Value(legalities),
       releasedAtFirst = Value(releasedAtFirst);
  static Insertable<Card> custom({
    Expression<String>? oracleId,
    Expression<String>? name,
    Expression<double>? cmc,
    Expression<String>? manaCost,
    Expression<String>? typeLine,
    Expression<int>? colors,
    Expression<int>? colorIdentity,
    Expression<int>? producedMana,
    Expression<int>? colorCount,
    Expression<String>? keywordsPipe,
    Expression<bool>? reserved,
    Expression<int>? edhrecRank,
    Expression<String>? layout,
    Expression<int>? legalities,
    Expression<String>? preferredPrintId,
    Expression<double>? releasedAtFirst,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (oracleId != null) 'oracle_id': oracleId,
      if (name != null) 'name': name,
      if (cmc != null) 'cmc': cmc,
      if (manaCost != null) 'mana_cost': manaCost,
      if (typeLine != null) 'type_line': typeLine,
      if (colors != null) 'colors': colors,
      if (colorIdentity != null) 'color_identity': colorIdentity,
      if (producedMana != null) 'produced_mana': producedMana,
      if (colorCount != null) 'color_count': colorCount,
      if (keywordsPipe != null) 'keywords_pipe': keywordsPipe,
      if (reserved != null) 'reserved': reserved,
      if (edhrecRank != null) 'edhrec_rank': edhrecRank,
      if (layout != null) 'layout': layout,
      if (legalities != null) 'legalities': legalities,
      if (preferredPrintId != null) 'preferred_print_id': preferredPrintId,
      if (releasedAtFirst != null) 'released_at_first': releasedAtFirst,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardsCompanion copyWith({
    Value<String>? oracleId,
    Value<String>? name,
    Value<double>? cmc,
    Value<String?>? manaCost,
    Value<String>? typeLine,
    Value<int>? colors,
    Value<int>? colorIdentity,
    Value<int>? producedMana,
    Value<int>? colorCount,
    Value<String>? keywordsPipe,
    Value<bool>? reserved,
    Value<int?>? edhrecRank,
    Value<String>? layout,
    Value<int>? legalities,
    Value<String?>? preferredPrintId,
    Value<double>? releasedAtFirst,
    Value<int>? rowid,
  }) {
    return CardsCompanion(
      oracleId: oracleId ?? this.oracleId,
      name: name ?? this.name,
      cmc: cmc ?? this.cmc,
      manaCost: manaCost ?? this.manaCost,
      typeLine: typeLine ?? this.typeLine,
      colors: colors ?? this.colors,
      colorIdentity: colorIdentity ?? this.colorIdentity,
      producedMana: producedMana ?? this.producedMana,
      colorCount: colorCount ?? this.colorCount,
      keywordsPipe: keywordsPipe ?? this.keywordsPipe,
      reserved: reserved ?? this.reserved,
      edhrecRank: edhrecRank ?? this.edhrecRank,
      layout: layout ?? this.layout,
      legalities: legalities ?? this.legalities,
      preferredPrintId: preferredPrintId ?? this.preferredPrintId,
      releasedAtFirst: releasedAtFirst ?? this.releasedAtFirst,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (oracleId.present) {
      map['oracle_id'] = Variable<String>(oracleId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (cmc.present) {
      map['cmc'] = Variable<double>(cmc.value);
    }
    if (manaCost.present) {
      map['mana_cost'] = Variable<String>(manaCost.value);
    }
    if (typeLine.present) {
      map['type_line'] = Variable<String>(typeLine.value);
    }
    if (colors.present) {
      map['colors'] = Variable<int>(colors.value);
    }
    if (colorIdentity.present) {
      map['color_identity'] = Variable<int>(colorIdentity.value);
    }
    if (producedMana.present) {
      map['produced_mana'] = Variable<int>(producedMana.value);
    }
    if (colorCount.present) {
      map['color_count'] = Variable<int>(colorCount.value);
    }
    if (keywordsPipe.present) {
      map['keywords_pipe'] = Variable<String>(keywordsPipe.value);
    }
    if (reserved.present) {
      map['reserved'] = Variable<bool>(reserved.value);
    }
    if (edhrecRank.present) {
      map['edhrec_rank'] = Variable<int>(edhrecRank.value);
    }
    if (layout.present) {
      map['layout'] = Variable<String>(layout.value);
    }
    if (legalities.present) {
      map['legalities'] = Variable<int>(legalities.value);
    }
    if (preferredPrintId.present) {
      map['preferred_print_id'] = Variable<String>(preferredPrintId.value);
    }
    if (releasedAtFirst.present) {
      map['released_at_first'] = Variable<double>(releasedAtFirst.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('oracleId: $oracleId, ')
          ..write('name: $name, ')
          ..write('cmc: $cmc, ')
          ..write('manaCost: $manaCost, ')
          ..write('typeLine: $typeLine, ')
          ..write('colors: $colors, ')
          ..write('colorIdentity: $colorIdentity, ')
          ..write('producedMana: $producedMana, ')
          ..write('colorCount: $colorCount, ')
          ..write('keywordsPipe: $keywordsPipe, ')
          ..write('reserved: $reserved, ')
          ..write('edhrecRank: $edhrecRank, ')
          ..write('layout: $layout, ')
          ..write('legalities: $legalities, ')
          ..write('preferredPrintId: $preferredPrintId, ')
          ..write('releasedAtFirst: $releasedAtFirst, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FacesTable extends Faces with TableInfo<$FacesTable, Face> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _faceIndexMeta = const VerificationMeta(
    'faceIndex',
  );
  @override
  late final GeneratedColumn<int> faceIndex = GeneratedColumn<int>(
    'face_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manaCostMeta = const VerificationMeta(
    'manaCost',
  );
  @override
  late final GeneratedColumn<String> manaCost = GeneratedColumn<String>(
    'mana_cost',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _manaPipsMeta = const VerificationMeta(
    'manaPips',
  );
  @override
  late final GeneratedColumn<String> manaPips = GeneratedColumn<String>(
    'mana_pips',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeLineMeta = const VerificationMeta(
    'typeLine',
  );
  @override
  late final GeneratedColumn<String> typeLine = GeneratedColumn<String>(
    'type_line',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _oracleTextMeta = const VerificationMeta(
    'oracleText',
  );
  @override
  late final GeneratedColumn<String> oracleText = GeneratedColumn<String>(
    'oracle_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorsMeta = const VerificationMeta('colors');
  @override
  late final GeneratedColumn<int> colors = GeneratedColumn<int>(
    'colors',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _powTextMeta = const VerificationMeta(
    'powText',
  );
  @override
  late final GeneratedColumn<String> powText = GeneratedColumn<String>(
    'pow_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _powNumMeta = const VerificationMeta('powNum');
  @override
  late final GeneratedColumn<double> powNum = GeneratedColumn<double>(
    'pow_num',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _touTextMeta = const VerificationMeta(
    'touText',
  );
  @override
  late final GeneratedColumn<String> touText = GeneratedColumn<String>(
    'tou_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _touNumMeta = const VerificationMeta('touNum');
  @override
  late final GeneratedColumn<double> touNum = GeneratedColumn<double>(
    'tou_num',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loyTextMeta = const VerificationMeta(
    'loyText',
  );
  @override
  late final GeneratedColumn<String> loyText = GeneratedColumn<String>(
    'loy_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loyNumMeta = const VerificationMeta('loyNum');
  @override
  late final GeneratedColumn<double> loyNum = GeneratedColumn<double>(
    'loy_num',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    oracleId,
    faceIndex,
    name,
    manaCost,
    manaPips,
    typeLine,
    oracleText,
    colors,
    powText,
    powNum,
    touText,
    touNum,
    loyText,
    loyNum,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'faces';
  @override
  VerificationContext validateIntegrity(
    Insertable<Face> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('oracle_id')) {
      context.handle(
        _oracleIdMeta,
        oracleId.isAcceptableOrUnknown(data['oracle_id']!, _oracleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_oracleIdMeta);
    }
    if (data.containsKey('face_index')) {
      context.handle(
        _faceIndexMeta,
        faceIndex.isAcceptableOrUnknown(data['face_index']!, _faceIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_faceIndexMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('mana_cost')) {
      context.handle(
        _manaCostMeta,
        manaCost.isAcceptableOrUnknown(data['mana_cost']!, _manaCostMeta),
      );
    }
    if (data.containsKey('mana_pips')) {
      context.handle(
        _manaPipsMeta,
        manaPips.isAcceptableOrUnknown(data['mana_pips']!, _manaPipsMeta),
      );
    } else if (isInserting) {
      context.missing(_manaPipsMeta);
    }
    if (data.containsKey('type_line')) {
      context.handle(
        _typeLineMeta,
        typeLine.isAcceptableOrUnknown(data['type_line']!, _typeLineMeta),
      );
    } else if (isInserting) {
      context.missing(_typeLineMeta);
    }
    if (data.containsKey('oracle_text')) {
      context.handle(
        _oracleTextMeta,
        oracleText.isAcceptableOrUnknown(data['oracle_text']!, _oracleTextMeta),
      );
    } else if (isInserting) {
      context.missing(_oracleTextMeta);
    }
    if (data.containsKey('colors')) {
      context.handle(
        _colorsMeta,
        colors.isAcceptableOrUnknown(data['colors']!, _colorsMeta),
      );
    } else if (isInserting) {
      context.missing(_colorsMeta);
    }
    if (data.containsKey('pow_text')) {
      context.handle(
        _powTextMeta,
        powText.isAcceptableOrUnknown(data['pow_text']!, _powTextMeta),
      );
    }
    if (data.containsKey('pow_num')) {
      context.handle(
        _powNumMeta,
        powNum.isAcceptableOrUnknown(data['pow_num']!, _powNumMeta),
      );
    }
    if (data.containsKey('tou_text')) {
      context.handle(
        _touTextMeta,
        touText.isAcceptableOrUnknown(data['tou_text']!, _touTextMeta),
      );
    }
    if (data.containsKey('tou_num')) {
      context.handle(
        _touNumMeta,
        touNum.isAcceptableOrUnknown(data['tou_num']!, _touNumMeta),
      );
    }
    if (data.containsKey('loy_text')) {
      context.handle(
        _loyTextMeta,
        loyText.isAcceptableOrUnknown(data['loy_text']!, _loyTextMeta),
      );
    }
    if (data.containsKey('loy_num')) {
      context.handle(
        _loyNumMeta,
        loyNum.isAcceptableOrUnknown(data['loy_num']!, _loyNumMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Face map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Face(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      oracleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}oracle_id'],
      )!,
      faceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}face_index'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      manaCost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mana_cost'],
      ),
      manaPips: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mana_pips'],
      )!,
      typeLine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_line'],
      )!,
      oracleText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}oracle_text'],
      )!,
      colors: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}colors'],
      )!,
      powText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pow_text'],
      ),
      powNum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pow_num'],
      ),
      touText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tou_text'],
      ),
      touNum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tou_num'],
      ),
      loyText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loy_text'],
      ),
      loyNum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}loy_num'],
      ),
    );
  }

  @override
  $FacesTable createAlias(String alias) {
    return $FacesTable(attachedDatabase, alias);
  }
}

class Face extends DataClass implements Insertable<Face> {
  final int id;
  final String oracleId;
  final int faceIndex;
  final String name;
  final String? manaCost;
  final String manaPips;
  final String typeLine;
  final String oracleText;
  final int colors;
  final String? powText;
  final double? powNum;
  final String? touText;
  final double? touNum;
  final String? loyText;
  final double? loyNum;
  const Face({
    required this.id,
    required this.oracleId,
    required this.faceIndex,
    required this.name,
    this.manaCost,
    required this.manaPips,
    required this.typeLine,
    required this.oracleText,
    required this.colors,
    this.powText,
    this.powNum,
    this.touText,
    this.touNum,
    this.loyText,
    this.loyNum,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['oracle_id'] = Variable<String>(oracleId);
    map['face_index'] = Variable<int>(faceIndex);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || manaCost != null) {
      map['mana_cost'] = Variable<String>(manaCost);
    }
    map['mana_pips'] = Variable<String>(manaPips);
    map['type_line'] = Variable<String>(typeLine);
    map['oracle_text'] = Variable<String>(oracleText);
    map['colors'] = Variable<int>(colors);
    if (!nullToAbsent || powText != null) {
      map['pow_text'] = Variable<String>(powText);
    }
    if (!nullToAbsent || powNum != null) {
      map['pow_num'] = Variable<double>(powNum);
    }
    if (!nullToAbsent || touText != null) {
      map['tou_text'] = Variable<String>(touText);
    }
    if (!nullToAbsent || touNum != null) {
      map['tou_num'] = Variable<double>(touNum);
    }
    if (!nullToAbsent || loyText != null) {
      map['loy_text'] = Variable<String>(loyText);
    }
    if (!nullToAbsent || loyNum != null) {
      map['loy_num'] = Variable<double>(loyNum);
    }
    return map;
  }

  FacesCompanion toCompanion(bool nullToAbsent) {
    return FacesCompanion(
      id: Value(id),
      oracleId: Value(oracleId),
      faceIndex: Value(faceIndex),
      name: Value(name),
      manaCost: manaCost == null && nullToAbsent
          ? const Value.absent()
          : Value(manaCost),
      manaPips: Value(manaPips),
      typeLine: Value(typeLine),
      oracleText: Value(oracleText),
      colors: Value(colors),
      powText: powText == null && nullToAbsent
          ? const Value.absent()
          : Value(powText),
      powNum: powNum == null && nullToAbsent
          ? const Value.absent()
          : Value(powNum),
      touText: touText == null && nullToAbsent
          ? const Value.absent()
          : Value(touText),
      touNum: touNum == null && nullToAbsent
          ? const Value.absent()
          : Value(touNum),
      loyText: loyText == null && nullToAbsent
          ? const Value.absent()
          : Value(loyText),
      loyNum: loyNum == null && nullToAbsent
          ? const Value.absent()
          : Value(loyNum),
    );
  }

  factory Face.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Face(
      id: serializer.fromJson<int>(json['id']),
      oracleId: serializer.fromJson<String>(json['oracleId']),
      faceIndex: serializer.fromJson<int>(json['faceIndex']),
      name: serializer.fromJson<String>(json['name']),
      manaCost: serializer.fromJson<String?>(json['manaCost']),
      manaPips: serializer.fromJson<String>(json['manaPips']),
      typeLine: serializer.fromJson<String>(json['typeLine']),
      oracleText: serializer.fromJson<String>(json['oracleText']),
      colors: serializer.fromJson<int>(json['colors']),
      powText: serializer.fromJson<String?>(json['powText']),
      powNum: serializer.fromJson<double?>(json['powNum']),
      touText: serializer.fromJson<String?>(json['touText']),
      touNum: serializer.fromJson<double?>(json['touNum']),
      loyText: serializer.fromJson<String?>(json['loyText']),
      loyNum: serializer.fromJson<double?>(json['loyNum']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'oracleId': serializer.toJson<String>(oracleId),
      'faceIndex': serializer.toJson<int>(faceIndex),
      'name': serializer.toJson<String>(name),
      'manaCost': serializer.toJson<String?>(manaCost),
      'manaPips': serializer.toJson<String>(manaPips),
      'typeLine': serializer.toJson<String>(typeLine),
      'oracleText': serializer.toJson<String>(oracleText),
      'colors': serializer.toJson<int>(colors),
      'powText': serializer.toJson<String?>(powText),
      'powNum': serializer.toJson<double?>(powNum),
      'touText': serializer.toJson<String?>(touText),
      'touNum': serializer.toJson<double?>(touNum),
      'loyText': serializer.toJson<String?>(loyText),
      'loyNum': serializer.toJson<double?>(loyNum),
    };
  }

  Face copyWith({
    int? id,
    String? oracleId,
    int? faceIndex,
    String? name,
    Value<String?> manaCost = const Value.absent(),
    String? manaPips,
    String? typeLine,
    String? oracleText,
    int? colors,
    Value<String?> powText = const Value.absent(),
    Value<double?> powNum = const Value.absent(),
    Value<String?> touText = const Value.absent(),
    Value<double?> touNum = const Value.absent(),
    Value<String?> loyText = const Value.absent(),
    Value<double?> loyNum = const Value.absent(),
  }) => Face(
    id: id ?? this.id,
    oracleId: oracleId ?? this.oracleId,
    faceIndex: faceIndex ?? this.faceIndex,
    name: name ?? this.name,
    manaCost: manaCost.present ? manaCost.value : this.manaCost,
    manaPips: manaPips ?? this.manaPips,
    typeLine: typeLine ?? this.typeLine,
    oracleText: oracleText ?? this.oracleText,
    colors: colors ?? this.colors,
    powText: powText.present ? powText.value : this.powText,
    powNum: powNum.present ? powNum.value : this.powNum,
    touText: touText.present ? touText.value : this.touText,
    touNum: touNum.present ? touNum.value : this.touNum,
    loyText: loyText.present ? loyText.value : this.loyText,
    loyNum: loyNum.present ? loyNum.value : this.loyNum,
  );
  Face copyWithCompanion(FacesCompanion data) {
    return Face(
      id: data.id.present ? data.id.value : this.id,
      oracleId: data.oracleId.present ? data.oracleId.value : this.oracleId,
      faceIndex: data.faceIndex.present ? data.faceIndex.value : this.faceIndex,
      name: data.name.present ? data.name.value : this.name,
      manaCost: data.manaCost.present ? data.manaCost.value : this.manaCost,
      manaPips: data.manaPips.present ? data.manaPips.value : this.manaPips,
      typeLine: data.typeLine.present ? data.typeLine.value : this.typeLine,
      oracleText: data.oracleText.present
          ? data.oracleText.value
          : this.oracleText,
      colors: data.colors.present ? data.colors.value : this.colors,
      powText: data.powText.present ? data.powText.value : this.powText,
      powNum: data.powNum.present ? data.powNum.value : this.powNum,
      touText: data.touText.present ? data.touText.value : this.touText,
      touNum: data.touNum.present ? data.touNum.value : this.touNum,
      loyText: data.loyText.present ? data.loyText.value : this.loyText,
      loyNum: data.loyNum.present ? data.loyNum.value : this.loyNum,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Face(')
          ..write('id: $id, ')
          ..write('oracleId: $oracleId, ')
          ..write('faceIndex: $faceIndex, ')
          ..write('name: $name, ')
          ..write('manaCost: $manaCost, ')
          ..write('manaPips: $manaPips, ')
          ..write('typeLine: $typeLine, ')
          ..write('oracleText: $oracleText, ')
          ..write('colors: $colors, ')
          ..write('powText: $powText, ')
          ..write('powNum: $powNum, ')
          ..write('touText: $touText, ')
          ..write('touNum: $touNum, ')
          ..write('loyText: $loyText, ')
          ..write('loyNum: $loyNum')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    oracleId,
    faceIndex,
    name,
    manaCost,
    manaPips,
    typeLine,
    oracleText,
    colors,
    powText,
    powNum,
    touText,
    touNum,
    loyText,
    loyNum,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Face &&
          other.id == this.id &&
          other.oracleId == this.oracleId &&
          other.faceIndex == this.faceIndex &&
          other.name == this.name &&
          other.manaCost == this.manaCost &&
          other.manaPips == this.manaPips &&
          other.typeLine == this.typeLine &&
          other.oracleText == this.oracleText &&
          other.colors == this.colors &&
          other.powText == this.powText &&
          other.powNum == this.powNum &&
          other.touText == this.touText &&
          other.touNum == this.touNum &&
          other.loyText == this.loyText &&
          other.loyNum == this.loyNum);
}

class FacesCompanion extends UpdateCompanion<Face> {
  final Value<int> id;
  final Value<String> oracleId;
  final Value<int> faceIndex;
  final Value<String> name;
  final Value<String?> manaCost;
  final Value<String> manaPips;
  final Value<String> typeLine;
  final Value<String> oracleText;
  final Value<int> colors;
  final Value<String?> powText;
  final Value<double?> powNum;
  final Value<String?> touText;
  final Value<double?> touNum;
  final Value<String?> loyText;
  final Value<double?> loyNum;
  const FacesCompanion({
    this.id = const Value.absent(),
    this.oracleId = const Value.absent(),
    this.faceIndex = const Value.absent(),
    this.name = const Value.absent(),
    this.manaCost = const Value.absent(),
    this.manaPips = const Value.absent(),
    this.typeLine = const Value.absent(),
    this.oracleText = const Value.absent(),
    this.colors = const Value.absent(),
    this.powText = const Value.absent(),
    this.powNum = const Value.absent(),
    this.touText = const Value.absent(),
    this.touNum = const Value.absent(),
    this.loyText = const Value.absent(),
    this.loyNum = const Value.absent(),
  });
  FacesCompanion.insert({
    this.id = const Value.absent(),
    required String oracleId,
    required int faceIndex,
    required String name,
    this.manaCost = const Value.absent(),
    required String manaPips,
    required String typeLine,
    required String oracleText,
    required int colors,
    this.powText = const Value.absent(),
    this.powNum = const Value.absent(),
    this.touText = const Value.absent(),
    this.touNum = const Value.absent(),
    this.loyText = const Value.absent(),
    this.loyNum = const Value.absent(),
  }) : oracleId = Value(oracleId),
       faceIndex = Value(faceIndex),
       name = Value(name),
       manaPips = Value(manaPips),
       typeLine = Value(typeLine),
       oracleText = Value(oracleText),
       colors = Value(colors);
  static Insertable<Face> custom({
    Expression<int>? id,
    Expression<String>? oracleId,
    Expression<int>? faceIndex,
    Expression<String>? name,
    Expression<String>? manaCost,
    Expression<String>? manaPips,
    Expression<String>? typeLine,
    Expression<String>? oracleText,
    Expression<int>? colors,
    Expression<String>? powText,
    Expression<double>? powNum,
    Expression<String>? touText,
    Expression<double>? touNum,
    Expression<String>? loyText,
    Expression<double>? loyNum,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (oracleId != null) 'oracle_id': oracleId,
      if (faceIndex != null) 'face_index': faceIndex,
      if (name != null) 'name': name,
      if (manaCost != null) 'mana_cost': manaCost,
      if (manaPips != null) 'mana_pips': manaPips,
      if (typeLine != null) 'type_line': typeLine,
      if (oracleText != null) 'oracle_text': oracleText,
      if (colors != null) 'colors': colors,
      if (powText != null) 'pow_text': powText,
      if (powNum != null) 'pow_num': powNum,
      if (touText != null) 'tou_text': touText,
      if (touNum != null) 'tou_num': touNum,
      if (loyText != null) 'loy_text': loyText,
      if (loyNum != null) 'loy_num': loyNum,
    });
  }

  FacesCompanion copyWith({
    Value<int>? id,
    Value<String>? oracleId,
    Value<int>? faceIndex,
    Value<String>? name,
    Value<String?>? manaCost,
    Value<String>? manaPips,
    Value<String>? typeLine,
    Value<String>? oracleText,
    Value<int>? colors,
    Value<String?>? powText,
    Value<double?>? powNum,
    Value<String?>? touText,
    Value<double?>? touNum,
    Value<String?>? loyText,
    Value<double?>? loyNum,
  }) {
    return FacesCompanion(
      id: id ?? this.id,
      oracleId: oracleId ?? this.oracleId,
      faceIndex: faceIndex ?? this.faceIndex,
      name: name ?? this.name,
      manaCost: manaCost ?? this.manaCost,
      manaPips: manaPips ?? this.manaPips,
      typeLine: typeLine ?? this.typeLine,
      oracleText: oracleText ?? this.oracleText,
      colors: colors ?? this.colors,
      powText: powText ?? this.powText,
      powNum: powNum ?? this.powNum,
      touText: touText ?? this.touText,
      touNum: touNum ?? this.touNum,
      loyText: loyText ?? this.loyText,
      loyNum: loyNum ?? this.loyNum,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (oracleId.present) {
      map['oracle_id'] = Variable<String>(oracleId.value);
    }
    if (faceIndex.present) {
      map['face_index'] = Variable<int>(faceIndex.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (manaCost.present) {
      map['mana_cost'] = Variable<String>(manaCost.value);
    }
    if (manaPips.present) {
      map['mana_pips'] = Variable<String>(manaPips.value);
    }
    if (typeLine.present) {
      map['type_line'] = Variable<String>(typeLine.value);
    }
    if (oracleText.present) {
      map['oracle_text'] = Variable<String>(oracleText.value);
    }
    if (colors.present) {
      map['colors'] = Variable<int>(colors.value);
    }
    if (powText.present) {
      map['pow_text'] = Variable<String>(powText.value);
    }
    if (powNum.present) {
      map['pow_num'] = Variable<double>(powNum.value);
    }
    if (touText.present) {
      map['tou_text'] = Variable<String>(touText.value);
    }
    if (touNum.present) {
      map['tou_num'] = Variable<double>(touNum.value);
    }
    if (loyText.present) {
      map['loy_text'] = Variable<String>(loyText.value);
    }
    if (loyNum.present) {
      map['loy_num'] = Variable<double>(loyNum.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FacesCompanion(')
          ..write('id: $id, ')
          ..write('oracleId: $oracleId, ')
          ..write('faceIndex: $faceIndex, ')
          ..write('name: $name, ')
          ..write('manaCost: $manaCost, ')
          ..write('manaPips: $manaPips, ')
          ..write('typeLine: $typeLine, ')
          ..write('oracleText: $oracleText, ')
          ..write('colors: $colors, ')
          ..write('powText: $powText, ')
          ..write('powNum: $powNum, ')
          ..write('touText: $touText, ')
          ..write('touNum: $touNum, ')
          ..write('loyText: $loyText, ')
          ..write('loyNum: $loyNum')
          ..write(')'))
        .toString();
  }
}

class $PrintsTable extends Prints with TableInfo<$PrintsTable, Print> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrintsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _setCodeMeta = const VerificationMeta(
    'setCode',
  );
  @override
  late final GeneratedColumn<String> setCode = GeneratedColumn<String>(
    'set_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setNameMeta = const VerificationMeta(
    'setName',
  );
  @override
  late final GeneratedColumn<String> setName = GeneratedColumn<String>(
    'set_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectorNumberMeta = const VerificationMeta(
    'collectorNumber',
  );
  @override
  late final GeneratedColumn<String> collectorNumber = GeneratedColumn<String>(
    'collector_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rarityMeta = const VerificationMeta('rarity');
  @override
  late final GeneratedColumn<int> rarity = GeneratedColumn<int>(
    'rarity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _releasedAtMeta = const VerificationMeta(
    'releasedAt',
  );
  @override
  late final GeneratedColumn<double> releasedAt = GeneratedColumn<double>(
    'released_at',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _watermarkMeta = const VerificationMeta(
    'watermark',
  );
  @override
  late final GeneratedColumn<String> watermark = GeneratedColumn<String>(
    'watermark',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _flavorTextMeta = const VerificationMeta(
    'flavorText',
  );
  @override
  late final GeneratedColumn<String> flavorText = GeneratedColumn<String>(
    'flavor_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frameMeta = const VerificationMeta('frame');
  @override
  late final GeneratedColumn<String> frame = GeneratedColumn<String>(
    'frame',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _borderColorMeta = const VerificationMeta(
    'borderColor',
  );
  @override
  late final GeneratedColumn<String> borderColor = GeneratedColumn<String>(
    'border_color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _flagsMeta = const VerificationMeta('flags');
  @override
  late final GeneratedColumn<int> flags = GeneratedColumn<int>(
    'flags',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gamesMeta = const VerificationMeta('games');
  @override
  late final GeneratedColumn<int> games = GeneratedColumn<int>(
    'games',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUriSmallMeta = const VerificationMeta(
    'imageUriSmall',
  );
  @override
  late final GeneratedColumn<String> imageUriSmall = GeneratedColumn<String>(
    'image_uri_small',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUriNormalMeta = const VerificationMeta(
    'imageUriNormal',
  );
  @override
  late final GeneratedColumn<String> imageUriNormal = GeneratedColumn<String>(
    'image_uri_normal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    oracleId,
    setCode,
    setName,
    collectorNumber,
    rarity,
    releasedAt,
    lang,
    artist,
    watermark,
    flavorText,
    frame,
    borderColor,
    flags,
    games,
    imageUriSmall,
    imageUriNormal,
    rawJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prints';
  @override
  VerificationContext validateIntegrity(
    Insertable<Print> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('oracle_id')) {
      context.handle(
        _oracleIdMeta,
        oracleId.isAcceptableOrUnknown(data['oracle_id']!, _oracleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_oracleIdMeta);
    }
    if (data.containsKey('set_code')) {
      context.handle(
        _setCodeMeta,
        setCode.isAcceptableOrUnknown(data['set_code']!, _setCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_setCodeMeta);
    }
    if (data.containsKey('set_name')) {
      context.handle(
        _setNameMeta,
        setName.isAcceptableOrUnknown(data['set_name']!, _setNameMeta),
      );
    } else if (isInserting) {
      context.missing(_setNameMeta);
    }
    if (data.containsKey('collector_number')) {
      context.handle(
        _collectorNumberMeta,
        collectorNumber.isAcceptableOrUnknown(
          data['collector_number']!,
          _collectorNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectorNumberMeta);
    }
    if (data.containsKey('rarity')) {
      context.handle(
        _rarityMeta,
        rarity.isAcceptableOrUnknown(data['rarity']!, _rarityMeta),
      );
    } else if (isInserting) {
      context.missing(_rarityMeta);
    }
    if (data.containsKey('released_at')) {
      context.handle(
        _releasedAtMeta,
        releasedAt.isAcceptableOrUnknown(data['released_at']!, _releasedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_releasedAtMeta);
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('watermark')) {
      context.handle(
        _watermarkMeta,
        watermark.isAcceptableOrUnknown(data['watermark']!, _watermarkMeta),
      );
    }
    if (data.containsKey('flavor_text')) {
      context.handle(
        _flavorTextMeta,
        flavorText.isAcceptableOrUnknown(data['flavor_text']!, _flavorTextMeta),
      );
    }
    if (data.containsKey('frame')) {
      context.handle(
        _frameMeta,
        frame.isAcceptableOrUnknown(data['frame']!, _frameMeta),
      );
    } else if (isInserting) {
      context.missing(_frameMeta);
    }
    if (data.containsKey('border_color')) {
      context.handle(
        _borderColorMeta,
        borderColor.isAcceptableOrUnknown(
          data['border_color']!,
          _borderColorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_borderColorMeta);
    }
    if (data.containsKey('flags')) {
      context.handle(
        _flagsMeta,
        flags.isAcceptableOrUnknown(data['flags']!, _flagsMeta),
      );
    } else if (isInserting) {
      context.missing(_flagsMeta);
    }
    if (data.containsKey('games')) {
      context.handle(
        _gamesMeta,
        games.isAcceptableOrUnknown(data['games']!, _gamesMeta),
      );
    } else if (isInserting) {
      context.missing(_gamesMeta);
    }
    if (data.containsKey('image_uri_small')) {
      context.handle(
        _imageUriSmallMeta,
        imageUriSmall.isAcceptableOrUnknown(
          data['image_uri_small']!,
          _imageUriSmallMeta,
        ),
      );
    }
    if (data.containsKey('image_uri_normal')) {
      context.handle(
        _imageUriNormalMeta,
        imageUriNormal.isAcceptableOrUnknown(
          data['image_uri_normal']!,
          _imageUriNormalMeta,
        ),
      );
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Print map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Print(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      oracleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}oracle_id'],
      )!,
      setCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_code'],
      )!,
      setName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_name'],
      )!,
      collectorNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collector_number'],
      )!,
      rarity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rarity'],
      )!,
      releasedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}released_at'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      ),
      watermark: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}watermark'],
      ),
      flavorText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flavor_text'],
      ),
      frame: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frame'],
      )!,
      borderColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}border_color'],
      )!,
      flags: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flags'],
      )!,
      games: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}games'],
      )!,
      imageUriSmall: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_uri_small'],
      ),
      imageUriNormal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_uri_normal'],
      ),
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      )!,
    );
  }

  @override
  $PrintsTable createAlias(String alias) {
    return $PrintsTable(attachedDatabase, alias);
  }
}

class Print extends DataClass implements Insertable<Print> {
  final String id;
  final String oracleId;
  final String setCode;
  final String setName;
  final String collectorNumber;
  final int rarity;
  final double releasedAt;
  final String lang;
  final String? artist;
  final String? watermark;
  final String? flavorText;
  final String frame;
  final String borderColor;
  final int flags;
  final int games;
  final String? imageUriSmall;
  final String? imageUriNormal;
  final String rawJson;
  const Print({
    required this.id,
    required this.oracleId,
    required this.setCode,
    required this.setName,
    required this.collectorNumber,
    required this.rarity,
    required this.releasedAt,
    required this.lang,
    this.artist,
    this.watermark,
    this.flavorText,
    required this.frame,
    required this.borderColor,
    required this.flags,
    required this.games,
    this.imageUriSmall,
    this.imageUriNormal,
    required this.rawJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['oracle_id'] = Variable<String>(oracleId);
    map['set_code'] = Variable<String>(setCode);
    map['set_name'] = Variable<String>(setName);
    map['collector_number'] = Variable<String>(collectorNumber);
    map['rarity'] = Variable<int>(rarity);
    map['released_at'] = Variable<double>(releasedAt);
    map['lang'] = Variable<String>(lang);
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || watermark != null) {
      map['watermark'] = Variable<String>(watermark);
    }
    if (!nullToAbsent || flavorText != null) {
      map['flavor_text'] = Variable<String>(flavorText);
    }
    map['frame'] = Variable<String>(frame);
    map['border_color'] = Variable<String>(borderColor);
    map['flags'] = Variable<int>(flags);
    map['games'] = Variable<int>(games);
    if (!nullToAbsent || imageUriSmall != null) {
      map['image_uri_small'] = Variable<String>(imageUriSmall);
    }
    if (!nullToAbsent || imageUriNormal != null) {
      map['image_uri_normal'] = Variable<String>(imageUriNormal);
    }
    map['raw_json'] = Variable<String>(rawJson);
    return map;
  }

  PrintsCompanion toCompanion(bool nullToAbsent) {
    return PrintsCompanion(
      id: Value(id),
      oracleId: Value(oracleId),
      setCode: Value(setCode),
      setName: Value(setName),
      collectorNumber: Value(collectorNumber),
      rarity: Value(rarity),
      releasedAt: Value(releasedAt),
      lang: Value(lang),
      artist: artist == null && nullToAbsent
          ? const Value.absent()
          : Value(artist),
      watermark: watermark == null && nullToAbsent
          ? const Value.absent()
          : Value(watermark),
      flavorText: flavorText == null && nullToAbsent
          ? const Value.absent()
          : Value(flavorText),
      frame: Value(frame),
      borderColor: Value(borderColor),
      flags: Value(flags),
      games: Value(games),
      imageUriSmall: imageUriSmall == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUriSmall),
      imageUriNormal: imageUriNormal == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUriNormal),
      rawJson: Value(rawJson),
    );
  }

  factory Print.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Print(
      id: serializer.fromJson<String>(json['id']),
      oracleId: serializer.fromJson<String>(json['oracleId']),
      setCode: serializer.fromJson<String>(json['setCode']),
      setName: serializer.fromJson<String>(json['setName']),
      collectorNumber: serializer.fromJson<String>(json['collectorNumber']),
      rarity: serializer.fromJson<int>(json['rarity']),
      releasedAt: serializer.fromJson<double>(json['releasedAt']),
      lang: serializer.fromJson<String>(json['lang']),
      artist: serializer.fromJson<String?>(json['artist']),
      watermark: serializer.fromJson<String?>(json['watermark']),
      flavorText: serializer.fromJson<String?>(json['flavorText']),
      frame: serializer.fromJson<String>(json['frame']),
      borderColor: serializer.fromJson<String>(json['borderColor']),
      flags: serializer.fromJson<int>(json['flags']),
      games: serializer.fromJson<int>(json['games']),
      imageUriSmall: serializer.fromJson<String?>(json['imageUriSmall']),
      imageUriNormal: serializer.fromJson<String?>(json['imageUriNormal']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'oracleId': serializer.toJson<String>(oracleId),
      'setCode': serializer.toJson<String>(setCode),
      'setName': serializer.toJson<String>(setName),
      'collectorNumber': serializer.toJson<String>(collectorNumber),
      'rarity': serializer.toJson<int>(rarity),
      'releasedAt': serializer.toJson<double>(releasedAt),
      'lang': serializer.toJson<String>(lang),
      'artist': serializer.toJson<String?>(artist),
      'watermark': serializer.toJson<String?>(watermark),
      'flavorText': serializer.toJson<String?>(flavorText),
      'frame': serializer.toJson<String>(frame),
      'borderColor': serializer.toJson<String>(borderColor),
      'flags': serializer.toJson<int>(flags),
      'games': serializer.toJson<int>(games),
      'imageUriSmall': serializer.toJson<String?>(imageUriSmall),
      'imageUriNormal': serializer.toJson<String?>(imageUriNormal),
      'rawJson': serializer.toJson<String>(rawJson),
    };
  }

  Print copyWith({
    String? id,
    String? oracleId,
    String? setCode,
    String? setName,
    String? collectorNumber,
    int? rarity,
    double? releasedAt,
    String? lang,
    Value<String?> artist = const Value.absent(),
    Value<String?> watermark = const Value.absent(),
    Value<String?> flavorText = const Value.absent(),
    String? frame,
    String? borderColor,
    int? flags,
    int? games,
    Value<String?> imageUriSmall = const Value.absent(),
    Value<String?> imageUriNormal = const Value.absent(),
    String? rawJson,
  }) => Print(
    id: id ?? this.id,
    oracleId: oracleId ?? this.oracleId,
    setCode: setCode ?? this.setCode,
    setName: setName ?? this.setName,
    collectorNumber: collectorNumber ?? this.collectorNumber,
    rarity: rarity ?? this.rarity,
    releasedAt: releasedAt ?? this.releasedAt,
    lang: lang ?? this.lang,
    artist: artist.present ? artist.value : this.artist,
    watermark: watermark.present ? watermark.value : this.watermark,
    flavorText: flavorText.present ? flavorText.value : this.flavorText,
    frame: frame ?? this.frame,
    borderColor: borderColor ?? this.borderColor,
    flags: flags ?? this.flags,
    games: games ?? this.games,
    imageUriSmall: imageUriSmall.present
        ? imageUriSmall.value
        : this.imageUriSmall,
    imageUriNormal: imageUriNormal.present
        ? imageUriNormal.value
        : this.imageUriNormal,
    rawJson: rawJson ?? this.rawJson,
  );
  Print copyWithCompanion(PrintsCompanion data) {
    return Print(
      id: data.id.present ? data.id.value : this.id,
      oracleId: data.oracleId.present ? data.oracleId.value : this.oracleId,
      setCode: data.setCode.present ? data.setCode.value : this.setCode,
      setName: data.setName.present ? data.setName.value : this.setName,
      collectorNumber: data.collectorNumber.present
          ? data.collectorNumber.value
          : this.collectorNumber,
      rarity: data.rarity.present ? data.rarity.value : this.rarity,
      releasedAt: data.releasedAt.present
          ? data.releasedAt.value
          : this.releasedAt,
      lang: data.lang.present ? data.lang.value : this.lang,
      artist: data.artist.present ? data.artist.value : this.artist,
      watermark: data.watermark.present ? data.watermark.value : this.watermark,
      flavorText: data.flavorText.present
          ? data.flavorText.value
          : this.flavorText,
      frame: data.frame.present ? data.frame.value : this.frame,
      borderColor: data.borderColor.present
          ? data.borderColor.value
          : this.borderColor,
      flags: data.flags.present ? data.flags.value : this.flags,
      games: data.games.present ? data.games.value : this.games,
      imageUriSmall: data.imageUriSmall.present
          ? data.imageUriSmall.value
          : this.imageUriSmall,
      imageUriNormal: data.imageUriNormal.present
          ? data.imageUriNormal.value
          : this.imageUriNormal,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Print(')
          ..write('id: $id, ')
          ..write('oracleId: $oracleId, ')
          ..write('setCode: $setCode, ')
          ..write('setName: $setName, ')
          ..write('collectorNumber: $collectorNumber, ')
          ..write('rarity: $rarity, ')
          ..write('releasedAt: $releasedAt, ')
          ..write('lang: $lang, ')
          ..write('artist: $artist, ')
          ..write('watermark: $watermark, ')
          ..write('flavorText: $flavorText, ')
          ..write('frame: $frame, ')
          ..write('borderColor: $borderColor, ')
          ..write('flags: $flags, ')
          ..write('games: $games, ')
          ..write('imageUriSmall: $imageUriSmall, ')
          ..write('imageUriNormal: $imageUriNormal, ')
          ..write('rawJson: $rawJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    oracleId,
    setCode,
    setName,
    collectorNumber,
    rarity,
    releasedAt,
    lang,
    artist,
    watermark,
    flavorText,
    frame,
    borderColor,
    flags,
    games,
    imageUriSmall,
    imageUriNormal,
    rawJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Print &&
          other.id == this.id &&
          other.oracleId == this.oracleId &&
          other.setCode == this.setCode &&
          other.setName == this.setName &&
          other.collectorNumber == this.collectorNumber &&
          other.rarity == this.rarity &&
          other.releasedAt == this.releasedAt &&
          other.lang == this.lang &&
          other.artist == this.artist &&
          other.watermark == this.watermark &&
          other.flavorText == this.flavorText &&
          other.frame == this.frame &&
          other.borderColor == this.borderColor &&
          other.flags == this.flags &&
          other.games == this.games &&
          other.imageUriSmall == this.imageUriSmall &&
          other.imageUriNormal == this.imageUriNormal &&
          other.rawJson == this.rawJson);
}

class PrintsCompanion extends UpdateCompanion<Print> {
  final Value<String> id;
  final Value<String> oracleId;
  final Value<String> setCode;
  final Value<String> setName;
  final Value<String> collectorNumber;
  final Value<int> rarity;
  final Value<double> releasedAt;
  final Value<String> lang;
  final Value<String?> artist;
  final Value<String?> watermark;
  final Value<String?> flavorText;
  final Value<String> frame;
  final Value<String> borderColor;
  final Value<int> flags;
  final Value<int> games;
  final Value<String?> imageUriSmall;
  final Value<String?> imageUriNormal;
  final Value<String> rawJson;
  final Value<int> rowid;
  const PrintsCompanion({
    this.id = const Value.absent(),
    this.oracleId = const Value.absent(),
    this.setCode = const Value.absent(),
    this.setName = const Value.absent(),
    this.collectorNumber = const Value.absent(),
    this.rarity = const Value.absent(),
    this.releasedAt = const Value.absent(),
    this.lang = const Value.absent(),
    this.artist = const Value.absent(),
    this.watermark = const Value.absent(),
    this.flavorText = const Value.absent(),
    this.frame = const Value.absent(),
    this.borderColor = const Value.absent(),
    this.flags = const Value.absent(),
    this.games = const Value.absent(),
    this.imageUriSmall = const Value.absent(),
    this.imageUriNormal = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrintsCompanion.insert({
    required String id,
    required String oracleId,
    required String setCode,
    required String setName,
    required String collectorNumber,
    required int rarity,
    required double releasedAt,
    required String lang,
    this.artist = const Value.absent(),
    this.watermark = const Value.absent(),
    this.flavorText = const Value.absent(),
    required String frame,
    required String borderColor,
    required int flags,
    required int games,
    this.imageUriSmall = const Value.absent(),
    this.imageUriNormal = const Value.absent(),
    required String rawJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       oracleId = Value(oracleId),
       setCode = Value(setCode),
       setName = Value(setName),
       collectorNumber = Value(collectorNumber),
       rarity = Value(rarity),
       releasedAt = Value(releasedAt),
       lang = Value(lang),
       frame = Value(frame),
       borderColor = Value(borderColor),
       flags = Value(flags),
       games = Value(games),
       rawJson = Value(rawJson);
  static Insertable<Print> custom({
    Expression<String>? id,
    Expression<String>? oracleId,
    Expression<String>? setCode,
    Expression<String>? setName,
    Expression<String>? collectorNumber,
    Expression<int>? rarity,
    Expression<double>? releasedAt,
    Expression<String>? lang,
    Expression<String>? artist,
    Expression<String>? watermark,
    Expression<String>? flavorText,
    Expression<String>? frame,
    Expression<String>? borderColor,
    Expression<int>? flags,
    Expression<int>? games,
    Expression<String>? imageUriSmall,
    Expression<String>? imageUriNormal,
    Expression<String>? rawJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (oracleId != null) 'oracle_id': oracleId,
      if (setCode != null) 'set_code': setCode,
      if (setName != null) 'set_name': setName,
      if (collectorNumber != null) 'collector_number': collectorNumber,
      if (rarity != null) 'rarity': rarity,
      if (releasedAt != null) 'released_at': releasedAt,
      if (lang != null) 'lang': lang,
      if (artist != null) 'artist': artist,
      if (watermark != null) 'watermark': watermark,
      if (flavorText != null) 'flavor_text': flavorText,
      if (frame != null) 'frame': frame,
      if (borderColor != null) 'border_color': borderColor,
      if (flags != null) 'flags': flags,
      if (games != null) 'games': games,
      if (imageUriSmall != null) 'image_uri_small': imageUriSmall,
      if (imageUriNormal != null) 'image_uri_normal': imageUriNormal,
      if (rawJson != null) 'raw_json': rawJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrintsCompanion copyWith({
    Value<String>? id,
    Value<String>? oracleId,
    Value<String>? setCode,
    Value<String>? setName,
    Value<String>? collectorNumber,
    Value<int>? rarity,
    Value<double>? releasedAt,
    Value<String>? lang,
    Value<String?>? artist,
    Value<String?>? watermark,
    Value<String?>? flavorText,
    Value<String>? frame,
    Value<String>? borderColor,
    Value<int>? flags,
    Value<int>? games,
    Value<String?>? imageUriSmall,
    Value<String?>? imageUriNormal,
    Value<String>? rawJson,
    Value<int>? rowid,
  }) {
    return PrintsCompanion(
      id: id ?? this.id,
      oracleId: oracleId ?? this.oracleId,
      setCode: setCode ?? this.setCode,
      setName: setName ?? this.setName,
      collectorNumber: collectorNumber ?? this.collectorNumber,
      rarity: rarity ?? this.rarity,
      releasedAt: releasedAt ?? this.releasedAt,
      lang: lang ?? this.lang,
      artist: artist ?? this.artist,
      watermark: watermark ?? this.watermark,
      flavorText: flavorText ?? this.flavorText,
      frame: frame ?? this.frame,
      borderColor: borderColor ?? this.borderColor,
      flags: flags ?? this.flags,
      games: games ?? this.games,
      imageUriSmall: imageUriSmall ?? this.imageUriSmall,
      imageUriNormal: imageUriNormal ?? this.imageUriNormal,
      rawJson: rawJson ?? this.rawJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (oracleId.present) {
      map['oracle_id'] = Variable<String>(oracleId.value);
    }
    if (setCode.present) {
      map['set_code'] = Variable<String>(setCode.value);
    }
    if (setName.present) {
      map['set_name'] = Variable<String>(setName.value);
    }
    if (collectorNumber.present) {
      map['collector_number'] = Variable<String>(collectorNumber.value);
    }
    if (rarity.present) {
      map['rarity'] = Variable<int>(rarity.value);
    }
    if (releasedAt.present) {
      map['released_at'] = Variable<double>(releasedAt.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (watermark.present) {
      map['watermark'] = Variable<String>(watermark.value);
    }
    if (flavorText.present) {
      map['flavor_text'] = Variable<String>(flavorText.value);
    }
    if (frame.present) {
      map['frame'] = Variable<String>(frame.value);
    }
    if (borderColor.present) {
      map['border_color'] = Variable<String>(borderColor.value);
    }
    if (flags.present) {
      map['flags'] = Variable<int>(flags.value);
    }
    if (games.present) {
      map['games'] = Variable<int>(games.value);
    }
    if (imageUriSmall.present) {
      map['image_uri_small'] = Variable<String>(imageUriSmall.value);
    }
    if (imageUriNormal.present) {
      map['image_uri_normal'] = Variable<String>(imageUriNormal.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrintsCompanion(')
          ..write('id: $id, ')
          ..write('oracleId: $oracleId, ')
          ..write('setCode: $setCode, ')
          ..write('setName: $setName, ')
          ..write('collectorNumber: $collectorNumber, ')
          ..write('rarity: $rarity, ')
          ..write('releasedAt: $releasedAt, ')
          ..write('lang: $lang, ')
          ..write('artist: $artist, ')
          ..write('watermark: $watermark, ')
          ..write('flavorText: $flavorText, ')
          ..write('frame: $frame, ')
          ..write('borderColor: $borderColor, ')
          ..write('flags: $flags, ')
          ..write('games: $games, ')
          ..write('imageUriSmall: $imageUriSmall, ')
          ..write('imageUriNormal: $imageUriNormal, ')
          ..write('rawJson: $rawJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RulingsTable extends Rulings with TableInfo<$RulingsTable, Ruling> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RulingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<String> publishedAt = GeneratedColumn<String>(
    'published_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [oracleId, publishedAt, comment];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rulings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ruling> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('oracle_id')) {
      context.handle(
        _oracleIdMeta,
        oracleId.isAcceptableOrUnknown(data['oracle_id']!, _oracleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_oracleIdMeta);
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publishedAtMeta);
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    } else if (isInserting) {
      context.missing(_commentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Ruling map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ruling(
      oracleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}oracle_id'],
      )!,
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}published_at'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      )!,
    );
  }

  @override
  $RulingsTable createAlias(String alias) {
    return $RulingsTable(attachedDatabase, alias);
  }
}

class Ruling extends DataClass implements Insertable<Ruling> {
  final String oracleId;
  final String publishedAt;
  final String comment;
  const Ruling({
    required this.oracleId,
    required this.publishedAt,
    required this.comment,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['oracle_id'] = Variable<String>(oracleId);
    map['published_at'] = Variable<String>(publishedAt);
    map['comment'] = Variable<String>(comment);
    return map;
  }

  RulingsCompanion toCompanion(bool nullToAbsent) {
    return RulingsCompanion(
      oracleId: Value(oracleId),
      publishedAt: Value(publishedAt),
      comment: Value(comment),
    );
  }

  factory Ruling.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ruling(
      oracleId: serializer.fromJson<String>(json['oracleId']),
      publishedAt: serializer.fromJson<String>(json['publishedAt']),
      comment: serializer.fromJson<String>(json['comment']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'oracleId': serializer.toJson<String>(oracleId),
      'publishedAt': serializer.toJson<String>(publishedAt),
      'comment': serializer.toJson<String>(comment),
    };
  }

  Ruling copyWith({String? oracleId, String? publishedAt, String? comment}) =>
      Ruling(
        oracleId: oracleId ?? this.oracleId,
        publishedAt: publishedAt ?? this.publishedAt,
        comment: comment ?? this.comment,
      );
  Ruling copyWithCompanion(RulingsCompanion data) {
    return Ruling(
      oracleId: data.oracleId.present ? data.oracleId.value : this.oracleId,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      comment: data.comment.present ? data.comment.value : this.comment,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ruling(')
          ..write('oracleId: $oracleId, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('comment: $comment')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(oracleId, publishedAt, comment);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ruling &&
          other.oracleId == this.oracleId &&
          other.publishedAt == this.publishedAt &&
          other.comment == this.comment);
}

class RulingsCompanion extends UpdateCompanion<Ruling> {
  final Value<String> oracleId;
  final Value<String> publishedAt;
  final Value<String> comment;
  final Value<int> rowid;
  const RulingsCompanion({
    this.oracleId = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.comment = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RulingsCompanion.insert({
    required String oracleId,
    required String publishedAt,
    required String comment,
    this.rowid = const Value.absent(),
  }) : oracleId = Value(oracleId),
       publishedAt = Value(publishedAt),
       comment = Value(comment);
  static Insertable<Ruling> custom({
    Expression<String>? oracleId,
    Expression<String>? publishedAt,
    Expression<String>? comment,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (oracleId != null) 'oracle_id': oracleId,
      if (publishedAt != null) 'published_at': publishedAt,
      if (comment != null) 'comment': comment,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RulingsCompanion copyWith({
    Value<String>? oracleId,
    Value<String>? publishedAt,
    Value<String>? comment,
    Value<int>? rowid,
  }) {
    return RulingsCompanion(
      oracleId: oracleId ?? this.oracleId,
      publishedAt: publishedAt ?? this.publishedAt,
      comment: comment ?? this.comment,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (oracleId.present) {
      map['oracle_id'] = Variable<String>(oracleId.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<String>(publishedAt.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RulingsCompanion(')
          ..write('oracleId: $oracleId, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('comment: $comment, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetaTable extends Meta with TableInfo<$MetaTable, MetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetaTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaData> instance, {
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
  MetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaData(
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
  $MetaTable createAlias(String alias) {
    return $MetaTable(attachedDatabase, alias);
  }
}

class MetaData extends DataClass implements Insertable<MetaData> {
  final String key;
  final String value;
  const MetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetaCompanion toCompanion(bool nullToAbsent) {
    return MetaCompanion(key: Value(key), value: Value(value));
  }

  factory MetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaData(
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

  MetaData copyWith({String? key, String? value}) =>
      MetaData(key: key ?? this.key, value: value ?? this.value);
  MetaData copyWithCompanion(MetaCompanion data) {
    return MetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaData(')
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
      (other is MetaData && other.key == this.key && other.value == this.value);
}

class MetaCompanion extends UpdateCompanion<MetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetaData> custom({
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

  MetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MetaCompanion(
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
    return (StringBuffer('MetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CardsTable cards = $CardsTable(this);
  late final $FacesTable faces = $FacesTable(this);
  late final $PrintsTable prints = $PrintsTable(this);
  late final $RulingsTable rulings = $RulingsTable(this);
  late final $MetaTable meta = $MetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cards,
    faces,
    prints,
    rulings,
    meta,
  ];
}

typedef $$CardsTableCreateCompanionBuilder =
    CardsCompanion Function({
      required String oracleId,
      required String name,
      required double cmc,
      Value<String?> manaCost,
      required String typeLine,
      required int colors,
      required int colorIdentity,
      required int producedMana,
      required int colorCount,
      required String keywordsPipe,
      required bool reserved,
      Value<int?> edhrecRank,
      required String layout,
      required int legalities,
      Value<String?> preferredPrintId,
      required double releasedAtFirst,
      Value<int> rowid,
    });
typedef $$CardsTableUpdateCompanionBuilder =
    CardsCompanion Function({
      Value<String> oracleId,
      Value<String> name,
      Value<double> cmc,
      Value<String?> manaCost,
      Value<String> typeLine,
      Value<int> colors,
      Value<int> colorIdentity,
      Value<int> producedMana,
      Value<int> colorCount,
      Value<String> keywordsPipe,
      Value<bool> reserved,
      Value<int?> edhrecRank,
      Value<String> layout,
      Value<int> legalities,
      Value<String?> preferredPrintId,
      Value<double> releasedAtFirst,
      Value<int> rowid,
    });

class $$CardsTableFilterComposer extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get oracleId => $composableBuilder(
    column: $table.oracleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cmc => $composableBuilder(
    column: $table.cmc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manaCost => $composableBuilder(
    column: $table.manaCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get typeLine => $composableBuilder(
    column: $table.typeLine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colors => $composableBuilder(
    column: $table.colors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorIdentity => $composableBuilder(
    column: $table.colorIdentity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get producedMana => $composableBuilder(
    column: $table.producedMana,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorCount => $composableBuilder(
    column: $table.colorCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keywordsPipe => $composableBuilder(
    column: $table.keywordsPipe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reserved => $composableBuilder(
    column: $table.reserved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get edhrecRank => $composableBuilder(
    column: $table.edhrecRank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get layout => $composableBuilder(
    column: $table.layout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get legalities => $composableBuilder(
    column: $table.legalities,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredPrintId => $composableBuilder(
    column: $table.preferredPrintId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get releasedAtFirst => $composableBuilder(
    column: $table.releasedAtFirst,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CardsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get oracleId => $composableBuilder(
    column: $table.oracleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cmc => $composableBuilder(
    column: $table.cmc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manaCost => $composableBuilder(
    column: $table.manaCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typeLine => $composableBuilder(
    column: $table.typeLine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colors => $composableBuilder(
    column: $table.colors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorIdentity => $composableBuilder(
    column: $table.colorIdentity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get producedMana => $composableBuilder(
    column: $table.producedMana,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorCount => $composableBuilder(
    column: $table.colorCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keywordsPipe => $composableBuilder(
    column: $table.keywordsPipe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reserved => $composableBuilder(
    column: $table.reserved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get edhrecRank => $composableBuilder(
    column: $table.edhrecRank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get layout => $composableBuilder(
    column: $table.layout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get legalities => $composableBuilder(
    column: $table.legalities,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredPrintId => $composableBuilder(
    column: $table.preferredPrintId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get releasedAtFirst => $composableBuilder(
    column: $table.releasedAtFirst,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get oracleId =>
      $composableBuilder(column: $table.oracleId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get cmc =>
      $composableBuilder(column: $table.cmc, builder: (column) => column);

  GeneratedColumn<String> get manaCost =>
      $composableBuilder(column: $table.manaCost, builder: (column) => column);

  GeneratedColumn<String> get typeLine =>
      $composableBuilder(column: $table.typeLine, builder: (column) => column);

  GeneratedColumn<int> get colors =>
      $composableBuilder(column: $table.colors, builder: (column) => column);

  GeneratedColumn<int> get colorIdentity => $composableBuilder(
    column: $table.colorIdentity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get producedMana => $composableBuilder(
    column: $table.producedMana,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorCount => $composableBuilder(
    column: $table.colorCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keywordsPipe => $composableBuilder(
    column: $table.keywordsPipe,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reserved =>
      $composableBuilder(column: $table.reserved, builder: (column) => column);

  GeneratedColumn<int> get edhrecRank => $composableBuilder(
    column: $table.edhrecRank,
    builder: (column) => column,
  );

  GeneratedColumn<String> get layout =>
      $composableBuilder(column: $table.layout, builder: (column) => column);

  GeneratedColumn<int> get legalities => $composableBuilder(
    column: $table.legalities,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredPrintId => $composableBuilder(
    column: $table.preferredPrintId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get releasedAtFirst => $composableBuilder(
    column: $table.releasedAtFirst,
    builder: (column) => column,
  );
}

class $$CardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardsTable,
          Card,
          $$CardsTableFilterComposer,
          $$CardsTableOrderingComposer,
          $$CardsTableAnnotationComposer,
          $$CardsTableCreateCompanionBuilder,
          $$CardsTableUpdateCompanionBuilder,
          (Card, BaseReferences<_$AppDatabase, $CardsTable, Card>),
          Card,
          PrefetchHooks Function()
        > {
  $$CardsTableTableManager(_$AppDatabase db, $CardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> oracleId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> cmc = const Value.absent(),
                Value<String?> manaCost = const Value.absent(),
                Value<String> typeLine = const Value.absent(),
                Value<int> colors = const Value.absent(),
                Value<int> colorIdentity = const Value.absent(),
                Value<int> producedMana = const Value.absent(),
                Value<int> colorCount = const Value.absent(),
                Value<String> keywordsPipe = const Value.absent(),
                Value<bool> reserved = const Value.absent(),
                Value<int?> edhrecRank = const Value.absent(),
                Value<String> layout = const Value.absent(),
                Value<int> legalities = const Value.absent(),
                Value<String?> preferredPrintId = const Value.absent(),
                Value<double> releasedAtFirst = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion(
                oracleId: oracleId,
                name: name,
                cmc: cmc,
                manaCost: manaCost,
                typeLine: typeLine,
                colors: colors,
                colorIdentity: colorIdentity,
                producedMana: producedMana,
                colorCount: colorCount,
                keywordsPipe: keywordsPipe,
                reserved: reserved,
                edhrecRank: edhrecRank,
                layout: layout,
                legalities: legalities,
                preferredPrintId: preferredPrintId,
                releasedAtFirst: releasedAtFirst,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String oracleId,
                required String name,
                required double cmc,
                Value<String?> manaCost = const Value.absent(),
                required String typeLine,
                required int colors,
                required int colorIdentity,
                required int producedMana,
                required int colorCount,
                required String keywordsPipe,
                required bool reserved,
                Value<int?> edhrecRank = const Value.absent(),
                required String layout,
                required int legalities,
                Value<String?> preferredPrintId = const Value.absent(),
                required double releasedAtFirst,
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion.insert(
                oracleId: oracleId,
                name: name,
                cmc: cmc,
                manaCost: manaCost,
                typeLine: typeLine,
                colors: colors,
                colorIdentity: colorIdentity,
                producedMana: producedMana,
                colorCount: colorCount,
                keywordsPipe: keywordsPipe,
                reserved: reserved,
                edhrecRank: edhrecRank,
                layout: layout,
                legalities: legalities,
                preferredPrintId: preferredPrintId,
                releasedAtFirst: releasedAtFirst,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardsTable,
      Card,
      $$CardsTableFilterComposer,
      $$CardsTableOrderingComposer,
      $$CardsTableAnnotationComposer,
      $$CardsTableCreateCompanionBuilder,
      $$CardsTableUpdateCompanionBuilder,
      (Card, BaseReferences<_$AppDatabase, $CardsTable, Card>),
      Card,
      PrefetchHooks Function()
    >;
typedef $$FacesTableCreateCompanionBuilder =
    FacesCompanion Function({
      Value<int> id,
      required String oracleId,
      required int faceIndex,
      required String name,
      Value<String?> manaCost,
      required String manaPips,
      required String typeLine,
      required String oracleText,
      required int colors,
      Value<String?> powText,
      Value<double?> powNum,
      Value<String?> touText,
      Value<double?> touNum,
      Value<String?> loyText,
      Value<double?> loyNum,
    });
typedef $$FacesTableUpdateCompanionBuilder =
    FacesCompanion Function({
      Value<int> id,
      Value<String> oracleId,
      Value<int> faceIndex,
      Value<String> name,
      Value<String?> manaCost,
      Value<String> manaPips,
      Value<String> typeLine,
      Value<String> oracleText,
      Value<int> colors,
      Value<String?> powText,
      Value<double?> powNum,
      Value<String?> touText,
      Value<double?> touNum,
      Value<String?> loyText,
      Value<double?> loyNum,
    });

class $$FacesTableFilterComposer extends Composer<_$AppDatabase, $FacesTable> {
  $$FacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oracleId => $composableBuilder(
    column: $table.oracleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get faceIndex => $composableBuilder(
    column: $table.faceIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manaCost => $composableBuilder(
    column: $table.manaCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manaPips => $composableBuilder(
    column: $table.manaPips,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get typeLine => $composableBuilder(
    column: $table.typeLine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oracleText => $composableBuilder(
    column: $table.oracleText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colors => $composableBuilder(
    column: $table.colors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get powText => $composableBuilder(
    column: $table.powText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get powNum => $composableBuilder(
    column: $table.powNum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get touText => $composableBuilder(
    column: $table.touText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get touNum => $composableBuilder(
    column: $table.touNum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loyText => $composableBuilder(
    column: $table.loyText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get loyNum => $composableBuilder(
    column: $table.loyNum,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FacesTableOrderingComposer
    extends Composer<_$AppDatabase, $FacesTable> {
  $$FacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oracleId => $composableBuilder(
    column: $table.oracleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get faceIndex => $composableBuilder(
    column: $table.faceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manaCost => $composableBuilder(
    column: $table.manaCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manaPips => $composableBuilder(
    column: $table.manaPips,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typeLine => $composableBuilder(
    column: $table.typeLine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oracleText => $composableBuilder(
    column: $table.oracleText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colors => $composableBuilder(
    column: $table.colors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get powText => $composableBuilder(
    column: $table.powText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get powNum => $composableBuilder(
    column: $table.powNum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get touText => $composableBuilder(
    column: $table.touText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get touNum => $composableBuilder(
    column: $table.touNum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loyText => $composableBuilder(
    column: $table.loyText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get loyNum => $composableBuilder(
    column: $table.loyNum,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FacesTable> {
  $$FacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get oracleId =>
      $composableBuilder(column: $table.oracleId, builder: (column) => column);

  GeneratedColumn<int> get faceIndex =>
      $composableBuilder(column: $table.faceIndex, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get manaCost =>
      $composableBuilder(column: $table.manaCost, builder: (column) => column);

  GeneratedColumn<String> get manaPips =>
      $composableBuilder(column: $table.manaPips, builder: (column) => column);

  GeneratedColumn<String> get typeLine =>
      $composableBuilder(column: $table.typeLine, builder: (column) => column);

  GeneratedColumn<String> get oracleText => $composableBuilder(
    column: $table.oracleText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colors =>
      $composableBuilder(column: $table.colors, builder: (column) => column);

  GeneratedColumn<String> get powText =>
      $composableBuilder(column: $table.powText, builder: (column) => column);

  GeneratedColumn<double> get powNum =>
      $composableBuilder(column: $table.powNum, builder: (column) => column);

  GeneratedColumn<String> get touText =>
      $composableBuilder(column: $table.touText, builder: (column) => column);

  GeneratedColumn<double> get touNum =>
      $composableBuilder(column: $table.touNum, builder: (column) => column);

  GeneratedColumn<String> get loyText =>
      $composableBuilder(column: $table.loyText, builder: (column) => column);

  GeneratedColumn<double> get loyNum =>
      $composableBuilder(column: $table.loyNum, builder: (column) => column);
}

class $$FacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FacesTable,
          Face,
          $$FacesTableFilterComposer,
          $$FacesTableOrderingComposer,
          $$FacesTableAnnotationComposer,
          $$FacesTableCreateCompanionBuilder,
          $$FacesTableUpdateCompanionBuilder,
          (Face, BaseReferences<_$AppDatabase, $FacesTable, Face>),
          Face,
          PrefetchHooks Function()
        > {
  $$FacesTableTableManager(_$AppDatabase db, $FacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> oracleId = const Value.absent(),
                Value<int> faceIndex = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> manaCost = const Value.absent(),
                Value<String> manaPips = const Value.absent(),
                Value<String> typeLine = const Value.absent(),
                Value<String> oracleText = const Value.absent(),
                Value<int> colors = const Value.absent(),
                Value<String?> powText = const Value.absent(),
                Value<double?> powNum = const Value.absent(),
                Value<String?> touText = const Value.absent(),
                Value<double?> touNum = const Value.absent(),
                Value<String?> loyText = const Value.absent(),
                Value<double?> loyNum = const Value.absent(),
              }) => FacesCompanion(
                id: id,
                oracleId: oracleId,
                faceIndex: faceIndex,
                name: name,
                manaCost: manaCost,
                manaPips: manaPips,
                typeLine: typeLine,
                oracleText: oracleText,
                colors: colors,
                powText: powText,
                powNum: powNum,
                touText: touText,
                touNum: touNum,
                loyText: loyText,
                loyNum: loyNum,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String oracleId,
                required int faceIndex,
                required String name,
                Value<String?> manaCost = const Value.absent(),
                required String manaPips,
                required String typeLine,
                required String oracleText,
                required int colors,
                Value<String?> powText = const Value.absent(),
                Value<double?> powNum = const Value.absent(),
                Value<String?> touText = const Value.absent(),
                Value<double?> touNum = const Value.absent(),
                Value<String?> loyText = const Value.absent(),
                Value<double?> loyNum = const Value.absent(),
              }) => FacesCompanion.insert(
                id: id,
                oracleId: oracleId,
                faceIndex: faceIndex,
                name: name,
                manaCost: manaCost,
                manaPips: manaPips,
                typeLine: typeLine,
                oracleText: oracleText,
                colors: colors,
                powText: powText,
                powNum: powNum,
                touText: touText,
                touNum: touNum,
                loyText: loyText,
                loyNum: loyNum,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FacesTable,
      Face,
      $$FacesTableFilterComposer,
      $$FacesTableOrderingComposer,
      $$FacesTableAnnotationComposer,
      $$FacesTableCreateCompanionBuilder,
      $$FacesTableUpdateCompanionBuilder,
      (Face, BaseReferences<_$AppDatabase, $FacesTable, Face>),
      Face,
      PrefetchHooks Function()
    >;
typedef $$PrintsTableCreateCompanionBuilder =
    PrintsCompanion Function({
      required String id,
      required String oracleId,
      required String setCode,
      required String setName,
      required String collectorNumber,
      required int rarity,
      required double releasedAt,
      required String lang,
      Value<String?> artist,
      Value<String?> watermark,
      Value<String?> flavorText,
      required String frame,
      required String borderColor,
      required int flags,
      required int games,
      Value<String?> imageUriSmall,
      Value<String?> imageUriNormal,
      required String rawJson,
      Value<int> rowid,
    });
typedef $$PrintsTableUpdateCompanionBuilder =
    PrintsCompanion Function({
      Value<String> id,
      Value<String> oracleId,
      Value<String> setCode,
      Value<String> setName,
      Value<String> collectorNumber,
      Value<int> rarity,
      Value<double> releasedAt,
      Value<String> lang,
      Value<String?> artist,
      Value<String?> watermark,
      Value<String?> flavorText,
      Value<String> frame,
      Value<String> borderColor,
      Value<int> flags,
      Value<int> games,
      Value<String?> imageUriSmall,
      Value<String?> imageUriNormal,
      Value<String> rawJson,
      Value<int> rowid,
    });

class $$PrintsTableFilterComposer
    extends Composer<_$AppDatabase, $PrintsTable> {
  $$PrintsTableFilterComposer({
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

  ColumnFilters<String> get oracleId => $composableBuilder(
    column: $table.oracleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setCode => $composableBuilder(
    column: $table.setCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setName => $composableBuilder(
    column: $table.setName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collectorNumber => $composableBuilder(
    column: $table.collectorNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rarity => $composableBuilder(
    column: $table.rarity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get releasedAt => $composableBuilder(
    column: $table.releasedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get watermark => $composableBuilder(
    column: $table.watermark,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flavorText => $composableBuilder(
    column: $table.flavorText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frame => $composableBuilder(
    column: $table.frame,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get borderColor => $composableBuilder(
    column: $table.borderColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get flags => $composableBuilder(
    column: $table.flags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get games => $composableBuilder(
    column: $table.games,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUriSmall => $composableBuilder(
    column: $table.imageUriSmall,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUriNormal => $composableBuilder(
    column: $table.imageUriNormal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrintsTableOrderingComposer
    extends Composer<_$AppDatabase, $PrintsTable> {
  $$PrintsTableOrderingComposer({
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

  ColumnOrderings<String> get oracleId => $composableBuilder(
    column: $table.oracleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setCode => $composableBuilder(
    column: $table.setCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setName => $composableBuilder(
    column: $table.setName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectorNumber => $composableBuilder(
    column: $table.collectorNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rarity => $composableBuilder(
    column: $table.rarity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get releasedAt => $composableBuilder(
    column: $table.releasedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get watermark => $composableBuilder(
    column: $table.watermark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flavorText => $composableBuilder(
    column: $table.flavorText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frame => $composableBuilder(
    column: $table.frame,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get borderColor => $composableBuilder(
    column: $table.borderColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get flags => $composableBuilder(
    column: $table.flags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get games => $composableBuilder(
    column: $table.games,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUriSmall => $composableBuilder(
    column: $table.imageUriSmall,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUriNormal => $composableBuilder(
    column: $table.imageUriNormal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrintsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrintsTable> {
  $$PrintsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get oracleId =>
      $composableBuilder(column: $table.oracleId, builder: (column) => column);

  GeneratedColumn<String> get setCode =>
      $composableBuilder(column: $table.setCode, builder: (column) => column);

  GeneratedColumn<String> get setName =>
      $composableBuilder(column: $table.setName, builder: (column) => column);

  GeneratedColumn<String> get collectorNumber => $composableBuilder(
    column: $table.collectorNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rarity =>
      $composableBuilder(column: $table.rarity, builder: (column) => column);

  GeneratedColumn<double> get releasedAt => $composableBuilder(
    column: $table.releasedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get watermark =>
      $composableBuilder(column: $table.watermark, builder: (column) => column);

  GeneratedColumn<String> get flavorText => $composableBuilder(
    column: $table.flavorText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get frame =>
      $composableBuilder(column: $table.frame, builder: (column) => column);

  GeneratedColumn<String> get borderColor => $composableBuilder(
    column: $table.borderColor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get flags =>
      $composableBuilder(column: $table.flags, builder: (column) => column);

  GeneratedColumn<int> get games =>
      $composableBuilder(column: $table.games, builder: (column) => column);

  GeneratedColumn<String> get imageUriSmall => $composableBuilder(
    column: $table.imageUriSmall,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUriNormal => $composableBuilder(
    column: $table.imageUriNormal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);
}

class $$PrintsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrintsTable,
          Print,
          $$PrintsTableFilterComposer,
          $$PrintsTableOrderingComposer,
          $$PrintsTableAnnotationComposer,
          $$PrintsTableCreateCompanionBuilder,
          $$PrintsTableUpdateCompanionBuilder,
          (Print, BaseReferences<_$AppDatabase, $PrintsTable, Print>),
          Print,
          PrefetchHooks Function()
        > {
  $$PrintsTableTableManager(_$AppDatabase db, $PrintsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrintsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrintsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrintsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> oracleId = const Value.absent(),
                Value<String> setCode = const Value.absent(),
                Value<String> setName = const Value.absent(),
                Value<String> collectorNumber = const Value.absent(),
                Value<int> rarity = const Value.absent(),
                Value<double> releasedAt = const Value.absent(),
                Value<String> lang = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String?> watermark = const Value.absent(),
                Value<String?> flavorText = const Value.absent(),
                Value<String> frame = const Value.absent(),
                Value<String> borderColor = const Value.absent(),
                Value<int> flags = const Value.absent(),
                Value<int> games = const Value.absent(),
                Value<String?> imageUriSmall = const Value.absent(),
                Value<String?> imageUriNormal = const Value.absent(),
                Value<String> rawJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrintsCompanion(
                id: id,
                oracleId: oracleId,
                setCode: setCode,
                setName: setName,
                collectorNumber: collectorNumber,
                rarity: rarity,
                releasedAt: releasedAt,
                lang: lang,
                artist: artist,
                watermark: watermark,
                flavorText: flavorText,
                frame: frame,
                borderColor: borderColor,
                flags: flags,
                games: games,
                imageUriSmall: imageUriSmall,
                imageUriNormal: imageUriNormal,
                rawJson: rawJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String oracleId,
                required String setCode,
                required String setName,
                required String collectorNumber,
                required int rarity,
                required double releasedAt,
                required String lang,
                Value<String?> artist = const Value.absent(),
                Value<String?> watermark = const Value.absent(),
                Value<String?> flavorText = const Value.absent(),
                required String frame,
                required String borderColor,
                required int flags,
                required int games,
                Value<String?> imageUriSmall = const Value.absent(),
                Value<String?> imageUriNormal = const Value.absent(),
                required String rawJson,
                Value<int> rowid = const Value.absent(),
              }) => PrintsCompanion.insert(
                id: id,
                oracleId: oracleId,
                setCode: setCode,
                setName: setName,
                collectorNumber: collectorNumber,
                rarity: rarity,
                releasedAt: releasedAt,
                lang: lang,
                artist: artist,
                watermark: watermark,
                flavorText: flavorText,
                frame: frame,
                borderColor: borderColor,
                flags: flags,
                games: games,
                imageUriSmall: imageUriSmall,
                imageUriNormal: imageUriNormal,
                rawJson: rawJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrintsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrintsTable,
      Print,
      $$PrintsTableFilterComposer,
      $$PrintsTableOrderingComposer,
      $$PrintsTableAnnotationComposer,
      $$PrintsTableCreateCompanionBuilder,
      $$PrintsTableUpdateCompanionBuilder,
      (Print, BaseReferences<_$AppDatabase, $PrintsTable, Print>),
      Print,
      PrefetchHooks Function()
    >;
typedef $$RulingsTableCreateCompanionBuilder =
    RulingsCompanion Function({
      required String oracleId,
      required String publishedAt,
      required String comment,
      Value<int> rowid,
    });
typedef $$RulingsTableUpdateCompanionBuilder =
    RulingsCompanion Function({
      Value<String> oracleId,
      Value<String> publishedAt,
      Value<String> comment,
      Value<int> rowid,
    });

class $$RulingsTableFilterComposer
    extends Composer<_$AppDatabase, $RulingsTable> {
  $$RulingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get oracleId => $composableBuilder(
    column: $table.oracleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RulingsTableOrderingComposer
    extends Composer<_$AppDatabase, $RulingsTable> {
  $$RulingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get oracleId => $composableBuilder(
    column: $table.oracleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RulingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RulingsTable> {
  $$RulingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get oracleId =>
      $composableBuilder(column: $table.oracleId, builder: (column) => column);

  GeneratedColumn<String> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);
}

class $$RulingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RulingsTable,
          Ruling,
          $$RulingsTableFilterComposer,
          $$RulingsTableOrderingComposer,
          $$RulingsTableAnnotationComposer,
          $$RulingsTableCreateCompanionBuilder,
          $$RulingsTableUpdateCompanionBuilder,
          (Ruling, BaseReferences<_$AppDatabase, $RulingsTable, Ruling>),
          Ruling,
          PrefetchHooks Function()
        > {
  $$RulingsTableTableManager(_$AppDatabase db, $RulingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RulingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RulingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RulingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> oracleId = const Value.absent(),
                Value<String> publishedAt = const Value.absent(),
                Value<String> comment = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RulingsCompanion(
                oracleId: oracleId,
                publishedAt: publishedAt,
                comment: comment,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String oracleId,
                required String publishedAt,
                required String comment,
                Value<int> rowid = const Value.absent(),
              }) => RulingsCompanion.insert(
                oracleId: oracleId,
                publishedAt: publishedAt,
                comment: comment,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RulingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RulingsTable,
      Ruling,
      $$RulingsTableFilterComposer,
      $$RulingsTableOrderingComposer,
      $$RulingsTableAnnotationComposer,
      $$RulingsTableCreateCompanionBuilder,
      $$RulingsTableUpdateCompanionBuilder,
      (Ruling, BaseReferences<_$AppDatabase, $RulingsTable, Ruling>),
      Ruling,
      PrefetchHooks Function()
    >;
typedef $$MetaTableCreateCompanionBuilder =
    MetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$MetaTableUpdateCompanionBuilder =
    MetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$MetaTableFilterComposer extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableFilterComposer({
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

class $$MetaTableOrderingComposer extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableOrderingComposer({
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

class $$MetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableAnnotationComposer({
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

class $$MetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetaTable,
          MetaData,
          $$MetaTableFilterComposer,
          $$MetaTableOrderingComposer,
          $$MetaTableAnnotationComposer,
          $$MetaTableCreateCompanionBuilder,
          $$MetaTableUpdateCompanionBuilder,
          (MetaData, BaseReferences<_$AppDatabase, $MetaTable, MetaData>),
          MetaData,
          PrefetchHooks Function()
        > {
  $$MetaTableTableManager(_$AppDatabase db, $MetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => MetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetaTable,
      MetaData,
      $$MetaTableFilterComposer,
      $$MetaTableOrderingComposer,
      $$MetaTableAnnotationComposer,
      $$MetaTableCreateCompanionBuilder,
      $$MetaTableUpdateCompanionBuilder,
      (MetaData, BaseReferences<_$AppDatabase, $MetaTable, MetaData>),
      MetaData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
  $$FacesTableTableManager get faces =>
      $$FacesTableTableManager(_db, _db.faces);
  $$PrintsTableTableManager get prints =>
      $$PrintsTableTableManager(_db, _db.prints);
  $$RulingsTableTableManager get rulings =>
      $$RulingsTableTableManager(_db, _db.rulings);
  $$MetaTableTableManager get meta => $$MetaTableTableManager(_db, _db.meta);
}
