// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TicketCategoriesTable extends TicketCategories
    with TableInfo<$TicketCategoriesTable, TicketCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TicketCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<int> price = GeneratedColumn<int>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quotaMeta = const VerificationMeta('quota');
  @override
  late final GeneratedColumn<int> quota = GeneratedColumn<int>(
    'quota',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, price, quota, isSynced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ticket_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<TicketCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('quota')) {
      context.handle(
        _quotaMeta,
        quota.isAcceptableOrUnknown(data['quota']!, _quotaMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TicketCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TicketCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price'],
      )!,
      quota: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quota'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $TicketCategoriesTable createAlias(String alias) {
    return $TicketCategoriesTable(attachedDatabase, alias);
  }
}

class TicketCategory extends DataClass implements Insertable<TicketCategory> {
  final String id;
  final String name;
  final int price;
  final int? quota;
  final bool isSynced;
  const TicketCategory({
    required this.id,
    required this.name,
    required this.price,
    this.quota,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['price'] = Variable<int>(price);
    if (!nullToAbsent || quota != null) {
      map['quota'] = Variable<int>(quota);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  TicketCategoriesCompanion toCompanion(bool nullToAbsent) {
    return TicketCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      price: Value(price),
      quota: quota == null && nullToAbsent
          ? const Value.absent()
          : Value(quota),
      isSynced: Value(isSynced),
    );
  }

  factory TicketCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TicketCategory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<int>(json['price']),
      quota: serializer.fromJson<int?>(json['quota']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<int>(price),
      'quota': serializer.toJson<int?>(quota),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  TicketCategory copyWith({
    String? id,
    String? name,
    int? price,
    Value<int?> quota = const Value.absent(),
    bool? isSynced,
  }) => TicketCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    price: price ?? this.price,
    quota: quota.present ? quota.value : this.quota,
    isSynced: isSynced ?? this.isSynced,
  );
  TicketCategory copyWithCompanion(TicketCategoriesCompanion data) {
    return TicketCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      quota: data.quota.present ? data.quota.value : this.quota,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TicketCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('quota: $quota, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, price, quota, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TicketCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.price == this.price &&
          other.quota == this.quota &&
          other.isSynced == this.isSynced);
}

class TicketCategoriesCompanion extends UpdateCompanion<TicketCategory> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> price;
  final Value<int?> quota;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const TicketCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.quota = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TicketCategoriesCompanion.insert({
    required String id,
    required String name,
    required int price,
    this.quota = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       price = Value(price);
  static Insertable<TicketCategory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? price,
    Expression<int>? quota,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (quota != null) 'quota': quota,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TicketCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? price,
    Value<int?>? quota,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return TicketCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quota: quota ?? this.quota,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<int>(price.value);
    }
    if (quota.present) {
      map['quota'] = Variable<int>(quota.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TicketCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('quota: $quota, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localNumberMeta = const VerificationMeta(
    'localNumber',
  );
  @override
  late final GeneratedColumn<String> localNumber = GeneratedColumn<String>(
    'local_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isVoidedMeta = const VerificationMeta(
    'isVoided',
  );
  @override
  late final GeneratedColumn<bool> isVoided = GeneratedColumn<bool>(
    'is_voided',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_voided" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _voidReasonMeta = const VerificationMeta(
    'voidReason',
  );
  @override
  late final GeneratedColumn<String> voidReason = GeneratedColumn<String>(
    'void_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voidedAtMeta = const VerificationMeta(
    'voidedAt',
  );
  @override
  late final GeneratedColumn<DateTime> voidedAt = GeneratedColumn<DateTime>(
    'voided_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localNumber,
    deviceId,
    total,
    paymentMethod,
    isSynced,
    createdAt,
    isVoided,
    voidReason,
    voidedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('local_number')) {
      context.handle(
        _localNumberMeta,
        localNumber.isAcceptableOrUnknown(
          data['local_number']!,
          _localNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localNumberMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_voided')) {
      context.handle(
        _isVoidedMeta,
        isVoided.isAcceptableOrUnknown(data['is_voided']!, _isVoidedMeta),
      );
    }
    if (data.containsKey('void_reason')) {
      context.handle(
        _voidReasonMeta,
        voidReason.isAcceptableOrUnknown(data['void_reason']!, _voidReasonMeta),
      );
    }
    if (data.containsKey('voided_at')) {
      context.handle(
        _voidedAtMeta,
        voidedAt.isAcceptableOrUnknown(data['voided_at']!, _voidedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      localNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_number'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isVoided: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_voided'],
      )!,
      voidReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}void_reason'],
      ),
      voidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}voided_at'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final String localNumber;
  final String deviceId;
  final int total;
  final String paymentMethod;
  final bool isSynced;
  final DateTime createdAt;
  final bool isVoided;
  final String? voidReason;
  final DateTime? voidedAt;
  const Transaction({
    required this.id,
    required this.localNumber,
    required this.deviceId,
    required this.total,
    required this.paymentMethod,
    required this.isSynced,
    required this.createdAt,
    required this.isVoided,
    this.voidReason,
    this.voidedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['local_number'] = Variable<String>(localNumber);
    map['device_id'] = Variable<String>(deviceId);
    map['total'] = Variable<int>(total);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_voided'] = Variable<bool>(isVoided);
    if (!nullToAbsent || voidReason != null) {
      map['void_reason'] = Variable<String>(voidReason);
    }
    if (!nullToAbsent || voidedAt != null) {
      map['voided_at'] = Variable<DateTime>(voidedAt);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      localNumber: Value(localNumber),
      deviceId: Value(deviceId),
      total: Value(total),
      paymentMethod: Value(paymentMethod),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
      isVoided: Value(isVoided),
      voidReason: voidReason == null && nullToAbsent
          ? const Value.absent()
          : Value(voidReason),
      voidedAt: voidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedAt),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      localNumber: serializer.fromJson<String>(json['localNumber']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      total: serializer.fromJson<int>(json['total']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isVoided: serializer.fromJson<bool>(json['isVoided']),
      voidReason: serializer.fromJson<String?>(json['voidReason']),
      voidedAt: serializer.fromJson<DateTime?>(json['voidedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'localNumber': serializer.toJson<String>(localNumber),
      'deviceId': serializer.toJson<String>(deviceId),
      'total': serializer.toJson<int>(total),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isVoided': serializer.toJson<bool>(isVoided),
      'voidReason': serializer.toJson<String?>(voidReason),
      'voidedAt': serializer.toJson<DateTime?>(voidedAt),
    };
  }

  Transaction copyWith({
    String? id,
    String? localNumber,
    String? deviceId,
    int? total,
    String? paymentMethod,
    bool? isSynced,
    DateTime? createdAt,
    bool? isVoided,
    Value<String?> voidReason = const Value.absent(),
    Value<DateTime?> voidedAt = const Value.absent(),
  }) => Transaction(
    id: id ?? this.id,
    localNumber: localNumber ?? this.localNumber,
    deviceId: deviceId ?? this.deviceId,
    total: total ?? this.total,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    isSynced: isSynced ?? this.isSynced,
    createdAt: createdAt ?? this.createdAt,
    isVoided: isVoided ?? this.isVoided,
    voidReason: voidReason.present ? voidReason.value : this.voidReason,
    voidedAt: voidedAt.present ? voidedAt.value : this.voidedAt,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      localNumber: data.localNumber.present
          ? data.localNumber.value
          : this.localNumber,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      total: data.total.present ? data.total.value : this.total,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isVoided: data.isVoided.present ? data.isVoided.value : this.isVoided,
      voidReason: data.voidReason.present
          ? data.voidReason.value
          : this.voidReason,
      voidedAt: data.voidedAt.present ? data.voidedAt.value : this.voidedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('localNumber: $localNumber, ')
          ..write('deviceId: $deviceId, ')
          ..write('total: $total, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('isVoided: $isVoided, ')
          ..write('voidReason: $voidReason, ')
          ..write('voidedAt: $voidedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localNumber,
    deviceId,
    total,
    paymentMethod,
    isSynced,
    createdAt,
    isVoided,
    voidReason,
    voidedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.localNumber == this.localNumber &&
          other.deviceId == this.deviceId &&
          other.total == this.total &&
          other.paymentMethod == this.paymentMethod &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt &&
          other.isVoided == this.isVoided &&
          other.voidReason == this.voidReason &&
          other.voidedAt == this.voidedAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> localNumber;
  final Value<String> deviceId;
  final Value<int> total;
  final Value<String> paymentMethod;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<bool> isVoided;
  final Value<String?> voidReason;
  final Value<DateTime?> voidedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.localNumber = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.total = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isVoided = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String localNumber,
    required String deviceId,
    required int total,
    required String paymentMethod,
    this.isSynced = const Value.absent(),
    required DateTime createdAt,
    this.isVoided = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       localNumber = Value(localNumber),
       deviceId = Value(deviceId),
       total = Value(total),
       paymentMethod = Value(paymentMethod),
       createdAt = Value(createdAt);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? localNumber,
    Expression<String>? deviceId,
    Expression<int>? total,
    Expression<String>? paymentMethod,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<bool>? isVoided,
    Expression<String>? voidReason,
    Expression<DateTime>? voidedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localNumber != null) 'local_number': localNumber,
      if (deviceId != null) 'device_id': deviceId,
      if (total != null) 'total': total,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (isVoided != null) 'is_voided': isVoided,
      if (voidReason != null) 'void_reason': voidReason,
      if (voidedAt != null) 'voided_at': voidedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? localNumber,
    Value<String>? deviceId,
    Value<int>? total,
    Value<String>? paymentMethod,
    Value<bool>? isSynced,
    Value<DateTime>? createdAt,
    Value<bool>? isVoided,
    Value<String?>? voidReason,
    Value<DateTime?>? voidedAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      localNumber: localNumber ?? this.localNumber,
      deviceId: deviceId ?? this.deviceId,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      isVoided: isVoided ?? this.isVoided,
      voidReason: voidReason ?? this.voidReason,
      voidedAt: voidedAt ?? this.voidedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (localNumber.present) {
      map['local_number'] = Variable<String>(localNumber.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isVoided.present) {
      map['is_voided'] = Variable<bool>(isVoided.value);
    }
    if (voidReason.present) {
      map['void_reason'] = Variable<String>(voidReason.value);
    }
    if (voidedAt.present) {
      map['voided_at'] = Variable<DateTime>(voidedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('localNumber: $localNumber, ')
          ..write('deviceId: $deviceId, ')
          ..write('total: $total, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('isVoided: $isVoided, ')
          ..write('voidReason: $voidReason, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionItemsTable extends TransactionItems
    with TableInfo<$TransactionItemsTable, TransactionItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<int> qty = GeneratedColumn<int>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<int> subtotal = GeneratedColumn<int>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    categoryId,
    qty,
    subtotal,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $TransactionItemsTable createAlias(String alias) {
    return $TransactionItemsTable(attachedDatabase, alias);
  }
}

class TransactionItem extends DataClass implements Insertable<TransactionItem> {
  final String id;
  final String transactionId;
  final String categoryId;
  final int qty;
  final int subtotal;
  final bool isSynced;
  const TransactionItem({
    required this.id,
    required this.transactionId,
    required this.categoryId,
    required this.qty,
    required this.subtotal,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['category_id'] = Variable<String>(categoryId);
    map['qty'] = Variable<int>(qty);
    map['subtotal'] = Variable<int>(subtotal);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  TransactionItemsCompanion toCompanion(bool nullToAbsent) {
    return TransactionItemsCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      categoryId: Value(categoryId),
      qty: Value(qty),
      subtotal: Value(subtotal),
      isSynced: Value(isSynced),
    );
  }

  factory TransactionItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionItem(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      qty: serializer.fromJson<int>(json['qty']),
      subtotal: serializer.fromJson<int>(json['subtotal']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'categoryId': serializer.toJson<String>(categoryId),
      'qty': serializer.toJson<int>(qty),
      'subtotal': serializer.toJson<int>(subtotal),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  TransactionItem copyWith({
    String? id,
    String? transactionId,
    String? categoryId,
    int? qty,
    int? subtotal,
    bool? isSynced,
  }) => TransactionItem(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    categoryId: categoryId ?? this.categoryId,
    qty: qty ?? this.qty,
    subtotal: subtotal ?? this.subtotal,
    isSynced: isSynced ?? this.isSynced,
  );
  TransactionItem copyWithCompanion(TransactionItemsCompanion data) {
    return TransactionItem(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      qty: data.qty.present ? data.qty.value : this.qty,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionItem(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('categoryId: $categoryId, ')
          ..write('qty: $qty, ')
          ..write('subtotal: $subtotal, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, transactionId, categoryId, qty, subtotal, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionItem &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.categoryId == this.categoryId &&
          other.qty == this.qty &&
          other.subtotal == this.subtotal &&
          other.isSynced == this.isSynced);
}

class TransactionItemsCompanion extends UpdateCompanion<TransactionItem> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<String> categoryId;
  final Value<int> qty;
  final Value<int> subtotal;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const TransactionItemsCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.qty = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionItemsCompanion.insert({
    required String id,
    required String transactionId,
    required String categoryId,
    required int qty,
    required int subtotal,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transactionId = Value(transactionId),
       categoryId = Value(categoryId),
       qty = Value(qty),
       subtotal = Value(subtotal);
  static Insertable<TransactionItem> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<String>? categoryId,
    Expression<int>? qty,
    Expression<int>? subtotal,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (categoryId != null) 'category_id': categoryId,
      if (qty != null) 'qty': qty,
      if (subtotal != null) 'subtotal': subtotal,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? transactionId,
    Value<String>? categoryId,
    Value<int>? qty,
    Value<int>? subtotal,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return TransactionItemsCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      categoryId: categoryId ?? this.categoryId,
      qty: qty ?? this.qty,
      subtotal: subtotal ?? this.subtotal,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<int>(subtotal.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionItemsCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('categoryId: $categoryId, ')
          ..write('qty: $qty, ')
          ..write('subtotal: $subtotal, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShiftReconciliationsTable extends ShiftReconciliations
    with TableInfo<$ShiftReconciliationsTable, ShiftReconciliation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftReconciliationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSistemTunaiMeta = const VerificationMeta(
    'totalSistemTunai',
  );
  @override
  late final GeneratedColumn<int> totalSistemTunai = GeneratedColumn<int>(
    'total_sistem_tunai',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalFisikTunaiMeta = const VerificationMeta(
    'totalFisikTunai',
  );
  @override
  late final GeneratedColumn<int> totalFisikTunai = GeneratedColumn<int>(
    'total_fisik_tunai',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selisihMeta = const VerificationMeta(
    'selisih',
  );
  @override
  late final GeneratedColumn<int> selisih = GeneratedColumn<int>(
    'selisih',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catatanMeta = const VerificationMeta(
    'catatan',
  );
  @override
  late final GeneratedColumn<String> catatan = GeneratedColumn<String>(
    'catatan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deviceId,
    totalSistemTunai,
    totalFisikTunai,
    selisih,
    catatan,
    createdAt,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shift_reconciliations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShiftReconciliation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('total_sistem_tunai')) {
      context.handle(
        _totalSistemTunaiMeta,
        totalSistemTunai.isAcceptableOrUnknown(
          data['total_sistem_tunai']!,
          _totalSistemTunaiMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalSistemTunaiMeta);
    }
    if (data.containsKey('total_fisik_tunai')) {
      context.handle(
        _totalFisikTunaiMeta,
        totalFisikTunai.isAcceptableOrUnknown(
          data['total_fisik_tunai']!,
          _totalFisikTunaiMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalFisikTunaiMeta);
    }
    if (data.containsKey('selisih')) {
      context.handle(
        _selisihMeta,
        selisih.isAcceptableOrUnknown(data['selisih']!, _selisihMeta),
      );
    } else if (isInserting) {
      context.missing(_selisihMeta);
    }
    if (data.containsKey('catatan')) {
      context.handle(
        _catatanMeta,
        catatan.isAcceptableOrUnknown(data['catatan']!, _catatanMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShiftReconciliation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftReconciliation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      totalSistemTunai: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_sistem_tunai'],
      )!,
      totalFisikTunai: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_fisik_tunai'],
      )!,
      selisih: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}selisih'],
      )!,
      catatan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catatan'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $ShiftReconciliationsTable createAlias(String alias) {
    return $ShiftReconciliationsTable(attachedDatabase, alias);
  }
}

class ShiftReconciliation extends DataClass
    implements Insertable<ShiftReconciliation> {
  final String id;
  final String deviceId;
  final int totalSistemTunai;
  final int totalFisikTunai;
  final int selisih;
  final String? catatan;
  final DateTime createdAt;
  final bool isSynced;
  const ShiftReconciliation({
    required this.id,
    required this.deviceId,
    required this.totalSistemTunai,
    required this.totalFisikTunai,
    required this.selisih,
    this.catatan,
    required this.createdAt,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['total_sistem_tunai'] = Variable<int>(totalSistemTunai);
    map['total_fisik_tunai'] = Variable<int>(totalFisikTunai);
    map['selisih'] = Variable<int>(selisih);
    if (!nullToAbsent || catatan != null) {
      map['catatan'] = Variable<String>(catatan);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  ShiftReconciliationsCompanion toCompanion(bool nullToAbsent) {
    return ShiftReconciliationsCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      totalSistemTunai: Value(totalSistemTunai),
      totalFisikTunai: Value(totalFisikTunai),
      selisih: Value(selisih),
      catatan: catatan == null && nullToAbsent
          ? const Value.absent()
          : Value(catatan),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory ShiftReconciliation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftReconciliation(
      id: serializer.fromJson<String>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      totalSistemTunai: serializer.fromJson<int>(json['totalSistemTunai']),
      totalFisikTunai: serializer.fromJson<int>(json['totalFisikTunai']),
      selisih: serializer.fromJson<int>(json['selisih']),
      catatan: serializer.fromJson<String?>(json['catatan']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'totalSistemTunai': serializer.toJson<int>(totalSistemTunai),
      'totalFisikTunai': serializer.toJson<int>(totalFisikTunai),
      'selisih': serializer.toJson<int>(selisih),
      'catatan': serializer.toJson<String?>(catatan),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  ShiftReconciliation copyWith({
    String? id,
    String? deviceId,
    int? totalSistemTunai,
    int? totalFisikTunai,
    int? selisih,
    Value<String?> catatan = const Value.absent(),
    DateTime? createdAt,
    bool? isSynced,
  }) => ShiftReconciliation(
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    totalSistemTunai: totalSistemTunai ?? this.totalSistemTunai,
    totalFisikTunai: totalFisikTunai ?? this.totalFisikTunai,
    selisih: selisih ?? this.selisih,
    catatan: catatan.present ? catatan.value : this.catatan,
    createdAt: createdAt ?? this.createdAt,
    isSynced: isSynced ?? this.isSynced,
  );
  ShiftReconciliation copyWithCompanion(ShiftReconciliationsCompanion data) {
    return ShiftReconciliation(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      totalSistemTunai: data.totalSistemTunai.present
          ? data.totalSistemTunai.value
          : this.totalSistemTunai,
      totalFisikTunai: data.totalFisikTunai.present
          ? data.totalFisikTunai.value
          : this.totalFisikTunai,
      selisih: data.selisih.present ? data.selisih.value : this.selisih,
      catatan: data.catatan.present ? data.catatan.value : this.catatan,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftReconciliation(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('totalSistemTunai: $totalSistemTunai, ')
          ..write('totalFisikTunai: $totalFisikTunai, ')
          ..write('selisih: $selisih, ')
          ..write('catatan: $catatan, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deviceId,
    totalSistemTunai,
    totalFisikTunai,
    selisih,
    catatan,
    createdAt,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftReconciliation &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.totalSistemTunai == this.totalSistemTunai &&
          other.totalFisikTunai == this.totalFisikTunai &&
          other.selisih == this.selisih &&
          other.catatan == this.catatan &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class ShiftReconciliationsCompanion
    extends UpdateCompanion<ShiftReconciliation> {
  final Value<String> id;
  final Value<String> deviceId;
  final Value<int> totalSistemTunai;
  final Value<int> totalFisikTunai;
  final Value<int> selisih;
  final Value<String?> catatan;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const ShiftReconciliationsCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.totalSistemTunai = const Value.absent(),
    this.totalFisikTunai = const Value.absent(),
    this.selisih = const Value.absent(),
    this.catatan = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShiftReconciliationsCompanion.insert({
    required String id,
    required String deviceId,
    required int totalSistemTunai,
    required int totalFisikTunai,
    required int selisih,
    this.catatan = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deviceId = Value(deviceId),
       totalSistemTunai = Value(totalSistemTunai),
       totalFisikTunai = Value(totalFisikTunai),
       selisih = Value(selisih),
       createdAt = Value(createdAt);
  static Insertable<ShiftReconciliation> custom({
    Expression<String>? id,
    Expression<String>? deviceId,
    Expression<int>? totalSistemTunai,
    Expression<int>? totalFisikTunai,
    Expression<int>? selisih,
    Expression<String>? catatan,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (totalSistemTunai != null) 'total_sistem_tunai': totalSistemTunai,
      if (totalFisikTunai != null) 'total_fisik_tunai': totalFisikTunai,
      if (selisih != null) 'selisih': selisih,
      if (catatan != null) 'catatan': catatan,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShiftReconciliationsCompanion copyWith({
    Value<String>? id,
    Value<String>? deviceId,
    Value<int>? totalSistemTunai,
    Value<int>? totalFisikTunai,
    Value<int>? selisih,
    Value<String?>? catatan,
    Value<DateTime>? createdAt,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return ShiftReconciliationsCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      totalSistemTunai: totalSistemTunai ?? this.totalSistemTunai,
      totalFisikTunai: totalFisikTunai ?? this.totalFisikTunai,
      selisih: selisih ?? this.selisih,
      catatan: catatan ?? this.catatan,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (totalSistemTunai.present) {
      map['total_sistem_tunai'] = Variable<int>(totalSistemTunai.value);
    }
    if (totalFisikTunai.present) {
      map['total_fisik_tunai'] = Variable<int>(totalFisikTunai.value);
    }
    if (selisih.present) {
      map['selisih'] = Variable<int>(selisih.value);
    }
    if (catatan.present) {
      map['catatan'] = Variable<String>(catatan.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftReconciliationsCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('totalSistemTunai: $totalSistemTunai, ')
          ..write('totalFisikTunai: $totalFisikTunai, ')
          ..write('selisih: $selisih, ')
          ..write('catatan: $catatan, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TicketCategoriesTable ticketCategories = $TicketCategoriesTable(
    this,
  );
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $TransactionItemsTable transactionItems = $TransactionItemsTable(
    this,
  );
  late final $ShiftReconciliationsTable shiftReconciliations =
      $ShiftReconciliationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    ticketCategories,
    transactions,
    transactionItems,
    shiftReconciliations,
  ];
}

typedef $$TicketCategoriesTableCreateCompanionBuilder =
    TicketCategoriesCompanion Function({
      required String id,
      required String name,
      required int price,
      Value<int?> quota,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$TicketCategoriesTableUpdateCompanionBuilder =
    TicketCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> price,
      Value<int?> quota,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$TicketCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $TicketCategoriesTable> {
  $$TicketCategoriesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quota => $composableBuilder(
    column: $table.quota,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TicketCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TicketCategoriesTable> {
  $$TicketCategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quota => $composableBuilder(
    column: $table.quota,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TicketCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TicketCategoriesTable> {
  $$TicketCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get quota =>
      $composableBuilder(column: $table.quota, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$TicketCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TicketCategoriesTable,
          TicketCategory,
          $$TicketCategoriesTableFilterComposer,
          $$TicketCategoriesTableOrderingComposer,
          $$TicketCategoriesTableAnnotationComposer,
          $$TicketCategoriesTableCreateCompanionBuilder,
          $$TicketCategoriesTableUpdateCompanionBuilder,
          (
            TicketCategory,
            BaseReferences<
              _$AppDatabase,
              $TicketCategoriesTable,
              TicketCategory
            >,
          ),
          TicketCategory,
          PrefetchHooks Function()
        > {
  $$TicketCategoriesTableTableManager(
    _$AppDatabase db,
    $TicketCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TicketCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TicketCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TicketCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> price = const Value.absent(),
                Value<int?> quota = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TicketCategoriesCompanion(
                id: id,
                name: name,
                price: price,
                quota: quota,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int price,
                Value<int?> quota = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TicketCategoriesCompanion.insert(
                id: id,
                name: name,
                price: price,
                quota: quota,
                isSynced: isSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TicketCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TicketCategoriesTable,
      TicketCategory,
      $$TicketCategoriesTableFilterComposer,
      $$TicketCategoriesTableOrderingComposer,
      $$TicketCategoriesTableAnnotationComposer,
      $$TicketCategoriesTableCreateCompanionBuilder,
      $$TicketCategoriesTableUpdateCompanionBuilder,
      (
        TicketCategory,
        BaseReferences<_$AppDatabase, $TicketCategoriesTable, TicketCategory>,
      ),
      TicketCategory,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String localNumber,
      required String deviceId,
      required int total,
      required String paymentMethod,
      Value<bool> isSynced,
      required DateTime createdAt,
      Value<bool> isVoided,
      Value<String?> voidReason,
      Value<DateTime?> voidedAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> localNumber,
      Value<String> deviceId,
      Value<int> total,
      Value<String> paymentMethod,
      Value<bool> isSynced,
      Value<DateTime> createdAt,
      Value<bool> isVoided,
      Value<String?> voidReason,
      Value<DateTime?> voidedAt,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
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

  ColumnFilters<String> get localNumber => $composableBuilder(
    column: $table.localNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVoided => $composableBuilder(
    column: $table.isVoided,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
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

  ColumnOrderings<String> get localNumber => $composableBuilder(
    column: $table.localNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVoided => $composableBuilder(
    column: $table.isVoided,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localNumber => $composableBuilder(
    column: $table.localNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isVoided =>
      $composableBuilder(column: $table.isVoided, builder: (column) => column);

  GeneratedColumn<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get voidedAt =>
      $composableBuilder(column: $table.voidedAt, builder: (column) => column);
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            Transaction,
            BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
          ),
          Transaction,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> localNumber = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isVoided = const Value.absent(),
                Value<String?> voidReason = const Value.absent(),
                Value<DateTime?> voidedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                localNumber: localNumber,
                deviceId: deviceId,
                total: total,
                paymentMethod: paymentMethod,
                isSynced: isSynced,
                createdAt: createdAt,
                isVoided: isVoided,
                voidReason: voidReason,
                voidedAt: voidedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String localNumber,
                required String deviceId,
                required int total,
                required String paymentMethod,
                Value<bool> isSynced = const Value.absent(),
                required DateTime createdAt,
                Value<bool> isVoided = const Value.absent(),
                Value<String?> voidReason = const Value.absent(),
                Value<DateTime?> voidedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                localNumber: localNumber,
                deviceId: deviceId,
                total: total,
                paymentMethod: paymentMethod,
                isSynced: isSynced,
                createdAt: createdAt,
                isVoided: isVoided,
                voidReason: voidReason,
                voidedAt: voidedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        Transaction,
        BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
      ),
      Transaction,
      PrefetchHooks Function()
    >;
typedef $$TransactionItemsTableCreateCompanionBuilder =
    TransactionItemsCompanion Function({
      required String id,
      required String transactionId,
      required String categoryId,
      required int qty,
      required int subtotal,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$TransactionItemsTableUpdateCompanionBuilder =
    TransactionItemsCompanion Function({
      Value<String> id,
      Value<String> transactionId,
      Value<String> categoryId,
      Value<int> qty,
      Value<int> subtotal,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$TransactionItemsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionItemsTable> {
  $$TransactionItemsTableFilterComposer({
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

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionItemsTable> {
  $$TransactionItemsTableOrderingComposer({
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

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionItemsTable> {
  $$TransactionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<int> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$TransactionItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionItemsTable,
          TransactionItem,
          $$TransactionItemsTableFilterComposer,
          $$TransactionItemsTableOrderingComposer,
          $$TransactionItemsTableAnnotationComposer,
          $$TransactionItemsTableCreateCompanionBuilder,
          $$TransactionItemsTableUpdateCompanionBuilder,
          (
            TransactionItem,
            BaseReferences<
              _$AppDatabase,
              $TransactionItemsTable,
              TransactionItem
            >,
          ),
          TransactionItem,
          PrefetchHooks Function()
        > {
  $$TransactionItemsTableTableManager(
    _$AppDatabase db,
    $TransactionItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<int> subtotal = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionItemsCompanion(
                id: id,
                transactionId: transactionId,
                categoryId: categoryId,
                qty: qty,
                subtotal: subtotal,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transactionId,
                required String categoryId,
                required int qty,
                required int subtotal,
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionItemsCompanion.insert(
                id: id,
                transactionId: transactionId,
                categoryId: categoryId,
                qty: qty,
                subtotal: subtotal,
                isSynced: isSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionItemsTable,
      TransactionItem,
      $$TransactionItemsTableFilterComposer,
      $$TransactionItemsTableOrderingComposer,
      $$TransactionItemsTableAnnotationComposer,
      $$TransactionItemsTableCreateCompanionBuilder,
      $$TransactionItemsTableUpdateCompanionBuilder,
      (
        TransactionItem,
        BaseReferences<_$AppDatabase, $TransactionItemsTable, TransactionItem>,
      ),
      TransactionItem,
      PrefetchHooks Function()
    >;
typedef $$ShiftReconciliationsTableCreateCompanionBuilder =
    ShiftReconciliationsCompanion Function({
      required String id,
      required String deviceId,
      required int totalSistemTunai,
      required int totalFisikTunai,
      required int selisih,
      Value<String?> catatan,
      required DateTime createdAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$ShiftReconciliationsTableUpdateCompanionBuilder =
    ShiftReconciliationsCompanion Function({
      Value<String> id,
      Value<String> deviceId,
      Value<int> totalSistemTunai,
      Value<int> totalFisikTunai,
      Value<int> selisih,
      Value<String?> catatan,
      Value<DateTime> createdAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$ShiftReconciliationsTableFilterComposer
    extends Composer<_$AppDatabase, $ShiftReconciliationsTable> {
  $$ShiftReconciliationsTableFilterComposer({
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

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSistemTunai => $composableBuilder(
    column: $table.totalSistemTunai,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalFisikTunai => $composableBuilder(
    column: $table.totalFisikTunai,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get selisih => $composableBuilder(
    column: $table.selisih,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShiftReconciliationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShiftReconciliationsTable> {
  $$ShiftReconciliationsTableOrderingComposer({
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

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSistemTunai => $composableBuilder(
    column: $table.totalSistemTunai,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalFisikTunai => $composableBuilder(
    column: $table.totalFisikTunai,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get selisih => $composableBuilder(
    column: $table.selisih,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShiftReconciliationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShiftReconciliationsTable> {
  $$ShiftReconciliationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get totalSistemTunai => $composableBuilder(
    column: $table.totalSistemTunai,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalFisikTunai => $composableBuilder(
    column: $table.totalFisikTunai,
    builder: (column) => column,
  );

  GeneratedColumn<int> get selisih =>
      $composableBuilder(column: $table.selisih, builder: (column) => column);

  GeneratedColumn<String> get catatan =>
      $composableBuilder(column: $table.catatan, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$ShiftReconciliationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShiftReconciliationsTable,
          ShiftReconciliation,
          $$ShiftReconciliationsTableFilterComposer,
          $$ShiftReconciliationsTableOrderingComposer,
          $$ShiftReconciliationsTableAnnotationComposer,
          $$ShiftReconciliationsTableCreateCompanionBuilder,
          $$ShiftReconciliationsTableUpdateCompanionBuilder,
          (
            ShiftReconciliation,
            BaseReferences<
              _$AppDatabase,
              $ShiftReconciliationsTable,
              ShiftReconciliation
            >,
          ),
          ShiftReconciliation,
          PrefetchHooks Function()
        > {
  $$ShiftReconciliationsTableTableManager(
    _$AppDatabase db,
    $ShiftReconciliationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftReconciliationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftReconciliationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ShiftReconciliationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> totalSistemTunai = const Value.absent(),
                Value<int> totalFisikTunai = const Value.absent(),
                Value<int> selisih = const Value.absent(),
                Value<String?> catatan = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShiftReconciliationsCompanion(
                id: id,
                deviceId: deviceId,
                totalSistemTunai: totalSistemTunai,
                totalFisikTunai: totalFisikTunai,
                selisih: selisih,
                catatan: catatan,
                createdAt: createdAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deviceId,
                required int totalSistemTunai,
                required int totalFisikTunai,
                required int selisih,
                Value<String?> catatan = const Value.absent(),
                required DateTime createdAt,
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShiftReconciliationsCompanion.insert(
                id: id,
                deviceId: deviceId,
                totalSistemTunai: totalSistemTunai,
                totalFisikTunai: totalFisikTunai,
                selisih: selisih,
                catatan: catatan,
                createdAt: createdAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShiftReconciliationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShiftReconciliationsTable,
      ShiftReconciliation,
      $$ShiftReconciliationsTableFilterComposer,
      $$ShiftReconciliationsTableOrderingComposer,
      $$ShiftReconciliationsTableAnnotationComposer,
      $$ShiftReconciliationsTableCreateCompanionBuilder,
      $$ShiftReconciliationsTableUpdateCompanionBuilder,
      (
        ShiftReconciliation,
        BaseReferences<
          _$AppDatabase,
          $ShiftReconciliationsTable,
          ShiftReconciliation
        >,
      ),
      ShiftReconciliation,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TicketCategoriesTableTableManager get ticketCategories =>
      $$TicketCategoriesTableTableManager(_db, _db.ticketCategories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$TransactionItemsTableTableManager get transactionItems =>
      $$TransactionItemsTableTableManager(_db, _db.transactionItems);
  $$ShiftReconciliationsTableTableManager get shiftReconciliations =>
      $$ShiftReconciliationsTableTableManager(_db, _db.shiftReconciliations);
}
