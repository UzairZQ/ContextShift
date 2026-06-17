// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema.dart';

// ignore_for_file: type=lint
class $ProfileTableTable extends ProfileTable
    with TableInfo<$ProfileTableTable, ProfileTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _focusAreaMeta = const VerificationMeta(
    'focusArea',
  );
  @override
  late final GeneratedColumn<String> focusArea = GeneratedColumn<String>(
    'focus_area',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supportNeedMeta = const VerificationMeta(
    'supportNeed',
  );
  @override
  late final GeneratedColumn<String> supportNeed = GeneratedColumn<String>(
    'support_need',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isGuestMeta = const VerificationMeta(
    'isGuest',
  );
  @override
  late final GeneratedColumn<bool> isGuest = GeneratedColumn<bool>(
    'is_guest',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_guest" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _modelTierMeta = const VerificationMeta(
    'modelTier',
  );
  @override
  late final GeneratedColumn<String> modelTier = GeneratedColumn<String>(
    'model_tier',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    focusArea,
    supportNeed,
    isGuest,
    modelTier,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('focus_area')) {
      context.handle(
        _focusAreaMeta,
        focusArea.isAcceptableOrUnknown(data['focus_area']!, _focusAreaMeta),
      );
    }
    if (data.containsKey('support_need')) {
      context.handle(
        _supportNeedMeta,
        supportNeed.isAcceptableOrUnknown(
          data['support_need']!,
          _supportNeedMeta,
        ),
      );
    }
    if (data.containsKey('is_guest')) {
      context.handle(
        _isGuestMeta,
        isGuest.isAcceptableOrUnknown(data['is_guest']!, _isGuestMeta),
      );
    }
    if (data.containsKey('model_tier')) {
      context.handle(
        _modelTierMeta,
        modelTier.isAcceptableOrUnknown(data['model_tier']!, _modelTierMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      focusArea: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}focus_area'],
      ),
      supportNeed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}support_need'],
      ),
      isGuest: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_guest'],
      )!,
      modelTier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_tier'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProfileTableTable createAlias(String alias) {
    return $ProfileTableTable(attachedDatabase, alias);
  }
}

class ProfileTableData extends DataClass
    implements Insertable<ProfileTableData> {
  final int id;
  final String userId;
  final String name;
  final String? focusArea;
  final String? supportNeed;
  final bool isGuest;
  final String? modelTier;
  final DateTime updatedAt;
  const ProfileTableData({
    required this.id,
    required this.userId,
    required this.name,
    this.focusArea,
    this.supportNeed,
    required this.isGuest,
    this.modelTier,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || focusArea != null) {
      map['focus_area'] = Variable<String>(focusArea);
    }
    if (!nullToAbsent || supportNeed != null) {
      map['support_need'] = Variable<String>(supportNeed);
    }
    map['is_guest'] = Variable<bool>(isGuest);
    if (!nullToAbsent || modelTier != null) {
      map['model_tier'] = Variable<String>(modelTier);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProfileTableCompanion toCompanion(bool nullToAbsent) {
    return ProfileTableCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      focusArea: focusArea == null && nullToAbsent
          ? const Value.absent()
          : Value(focusArea),
      supportNeed: supportNeed == null && nullToAbsent
          ? const Value.absent()
          : Value(supportNeed),
      isGuest: Value(isGuest),
      modelTier: modelTier == null && nullToAbsent
          ? const Value.absent()
          : Value(modelTier),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProfileTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileTableData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      focusArea: serializer.fromJson<String?>(json['focusArea']),
      supportNeed: serializer.fromJson<String?>(json['supportNeed']),
      isGuest: serializer.fromJson<bool>(json['isGuest']),
      modelTier: serializer.fromJson<String?>(json['modelTier']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'focusArea': serializer.toJson<String?>(focusArea),
      'supportNeed': serializer.toJson<String?>(supportNeed),
      'isGuest': serializer.toJson<bool>(isGuest),
      'modelTier': serializer.toJson<String?>(modelTier),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProfileTableData copyWith({
    int? id,
    String? userId,
    String? name,
    Value<String?> focusArea = const Value.absent(),
    Value<String?> supportNeed = const Value.absent(),
    bool? isGuest,
    Value<String?> modelTier = const Value.absent(),
    DateTime? updatedAt,
  }) => ProfileTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    focusArea: focusArea.present ? focusArea.value : this.focusArea,
    supportNeed: supportNeed.present ? supportNeed.value : this.supportNeed,
    isGuest: isGuest ?? this.isGuest,
    modelTier: modelTier.present ? modelTier.value : this.modelTier,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProfileTableData copyWithCompanion(ProfileTableCompanion data) {
    return ProfileTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      focusArea: data.focusArea.present ? data.focusArea.value : this.focusArea,
      supportNeed: data.supportNeed.present
          ? data.supportNeed.value
          : this.supportNeed,
      isGuest: data.isGuest.present ? data.isGuest.value : this.isGuest,
      modelTier: data.modelTier.present ? data.modelTier.value : this.modelTier,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('focusArea: $focusArea, ')
          ..write('supportNeed: $supportNeed, ')
          ..write('isGuest: $isGuest, ')
          ..write('modelTier: $modelTier, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    focusArea,
    supportNeed,
    isGuest,
    modelTier,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.focusArea == this.focusArea &&
          other.supportNeed == this.supportNeed &&
          other.isGuest == this.isGuest &&
          other.modelTier == this.modelTier &&
          other.updatedAt == this.updatedAt);
}

class ProfileTableCompanion extends UpdateCompanion<ProfileTableData> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String?> focusArea;
  final Value<String?> supportNeed;
  final Value<bool> isGuest;
  final Value<String?> modelTier;
  final Value<DateTime> updatedAt;
  const ProfileTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.focusArea = const Value.absent(),
    this.supportNeed = const Value.absent(),
    this.isGuest = const Value.absent(),
    this.modelTier = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProfileTableCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String name,
    this.focusArea = const Value.absent(),
    this.supportNeed = const Value.absent(),
    this.isGuest = const Value.absent(),
    this.modelTier = const Value.absent(),
    required DateTime updatedAt,
  }) : userId = Value(userId),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<ProfileTableData> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? focusArea,
    Expression<String>? supportNeed,
    Expression<bool>? isGuest,
    Expression<String>? modelTier,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (focusArea != null) 'focus_area': focusArea,
      if (supportNeed != null) 'support_need': supportNeed,
      if (isGuest != null) 'is_guest': isGuest,
      if (modelTier != null) 'model_tier': modelTier,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProfileTableCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<String?>? focusArea,
    Value<String?>? supportNeed,
    Value<bool>? isGuest,
    Value<String?>? modelTier,
    Value<DateTime>? updatedAt,
  }) {
    return ProfileTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      focusArea: focusArea ?? this.focusArea,
      supportNeed: supportNeed ?? this.supportNeed,
      isGuest: isGuest ?? this.isGuest,
      modelTier: modelTier ?? this.modelTier,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (focusArea.present) {
      map['focus_area'] = Variable<String>(focusArea.value);
    }
    if (supportNeed.present) {
      map['support_need'] = Variable<String>(supportNeed.value);
    }
    if (isGuest.present) {
      map['is_guest'] = Variable<bool>(isGuest.value);
    }
    if (modelTier.present) {
      map['model_tier'] = Variable<String>(modelTier.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('focusArea: $focusArea, ')
          ..write('supportNeed: $supportNeed, ')
          ..write('isGuest: $isGuest, ')
          ..write('modelTier: $modelTier, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $UserPreferencesTableTable extends UserPreferencesTable
    with TableInfo<$UserPreferencesTableTable, UserPreferencesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPreferencesTableTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _responseStyleMeta = const VerificationMeta(
    'responseStyle',
  );
  @override
  late final GeneratedColumn<String> responseStyle = GeneratedColumn<String>(
    'response_style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('balanced'),
  );
  static const VerificationMeta _premiumPurchasedMeta = const VerificationMeta(
    'premiumPurchased',
  );
  @override
  late final GeneratedColumn<bool> premiumPurchased = GeneratedColumn<bool>(
    'premium_purchased',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("premium_purchased" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _onboardingDoneMeta = const VerificationMeta(
    'onboardingDone',
  );
  @override
  late final GeneratedColumn<bool> onboardingDone = GeneratedColumn<bool>(
    'onboarding_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _modelTierMeta = const VerificationMeta(
    'modelTier',
  );
  @override
  late final GeneratedColumn<String> modelTier = GeneratedColumn<String>(
    'model_tier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('e2b'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deviceId,
    responseStyle,
    premiumPurchased,
    onboardingDone,
    modelTier,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_preferences_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPreferencesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('response_style')) {
      context.handle(
        _responseStyleMeta,
        responseStyle.isAcceptableOrUnknown(
          data['response_style']!,
          _responseStyleMeta,
        ),
      );
    }
    if (data.containsKey('premium_purchased')) {
      context.handle(
        _premiumPurchasedMeta,
        premiumPurchased.isAcceptableOrUnknown(
          data['premium_purchased']!,
          _premiumPurchasedMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_done')) {
      context.handle(
        _onboardingDoneMeta,
        onboardingDone.isAcceptableOrUnknown(
          data['onboarding_done']!,
          _onboardingDoneMeta,
        ),
      );
    }
    if (data.containsKey('model_tier')) {
      context.handle(
        _modelTierMeta,
        modelTier.isAcceptableOrUnknown(data['model_tier']!, _modelTierMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserPreferencesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPreferencesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      responseStyle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_style'],
      )!,
      premiumPurchased: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}premium_purchased'],
      )!,
      onboardingDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_done'],
      )!,
      modelTier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_tier'],
      )!,
    );
  }

  @override
  $UserPreferencesTableTable createAlias(String alias) {
    return $UserPreferencesTableTable(attachedDatabase, alias);
  }
}

class UserPreferencesTableData extends DataClass
    implements Insertable<UserPreferencesTableData> {
  final int id;
  final String deviceId;
  final String responseStyle;
  final bool premiumPurchased;
  final bool onboardingDone;
  final String modelTier;
  const UserPreferencesTableData({
    required this.id,
    required this.deviceId,
    required this.responseStyle,
    required this.premiumPurchased,
    required this.onboardingDone,
    required this.modelTier,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['response_style'] = Variable<String>(responseStyle);
    map['premium_purchased'] = Variable<bool>(premiumPurchased);
    map['onboarding_done'] = Variable<bool>(onboardingDone);
    map['model_tier'] = Variable<String>(modelTier);
    return map;
  }

  UserPreferencesTableCompanion toCompanion(bool nullToAbsent) {
    return UserPreferencesTableCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      responseStyle: Value(responseStyle),
      premiumPurchased: Value(premiumPurchased),
      onboardingDone: Value(onboardingDone),
      modelTier: Value(modelTier),
    );
  }

  factory UserPreferencesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPreferencesTableData(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      responseStyle: serializer.fromJson<String>(json['responseStyle']),
      premiumPurchased: serializer.fromJson<bool>(json['premiumPurchased']),
      onboardingDone: serializer.fromJson<bool>(json['onboardingDone']),
      modelTier: serializer.fromJson<String>(json['modelTier']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'responseStyle': serializer.toJson<String>(responseStyle),
      'premiumPurchased': serializer.toJson<bool>(premiumPurchased),
      'onboardingDone': serializer.toJson<bool>(onboardingDone),
      'modelTier': serializer.toJson<String>(modelTier),
    };
  }

  UserPreferencesTableData copyWith({
    int? id,
    String? deviceId,
    String? responseStyle,
    bool? premiumPurchased,
    bool? onboardingDone,
    String? modelTier,
  }) => UserPreferencesTableData(
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    responseStyle: responseStyle ?? this.responseStyle,
    premiumPurchased: premiumPurchased ?? this.premiumPurchased,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    modelTier: modelTier ?? this.modelTier,
  );
  UserPreferencesTableData copyWithCompanion(
    UserPreferencesTableCompanion data,
  ) {
    return UserPreferencesTableData(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      responseStyle: data.responseStyle.present
          ? data.responseStyle.value
          : this.responseStyle,
      premiumPurchased: data.premiumPurchased.present
          ? data.premiumPurchased.value
          : this.premiumPurchased,
      onboardingDone: data.onboardingDone.present
          ? data.onboardingDone.value
          : this.onboardingDone,
      modelTier: data.modelTier.present ? data.modelTier.value : this.modelTier,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesTableData(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('responseStyle: $responseStyle, ')
          ..write('premiumPurchased: $premiumPurchased, ')
          ..write('onboardingDone: $onboardingDone, ')
          ..write('modelTier: $modelTier')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deviceId,
    responseStyle,
    premiumPurchased,
    onboardingDone,
    modelTier,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPreferencesTableData &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.responseStyle == this.responseStyle &&
          other.premiumPurchased == this.premiumPurchased &&
          other.onboardingDone == this.onboardingDone &&
          other.modelTier == this.modelTier);
}

class UserPreferencesTableCompanion
    extends UpdateCompanion<UserPreferencesTableData> {
  final Value<int> id;
  final Value<String> deviceId;
  final Value<String> responseStyle;
  final Value<bool> premiumPurchased;
  final Value<bool> onboardingDone;
  final Value<String> modelTier;
  const UserPreferencesTableCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.responseStyle = const Value.absent(),
    this.premiumPurchased = const Value.absent(),
    this.onboardingDone = const Value.absent(),
    this.modelTier = const Value.absent(),
  });
  UserPreferencesTableCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    this.responseStyle = const Value.absent(),
    this.premiumPurchased = const Value.absent(),
    this.onboardingDone = const Value.absent(),
    this.modelTier = const Value.absent(),
  }) : deviceId = Value(deviceId);
  static Insertable<UserPreferencesTableData> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<String>? responseStyle,
    Expression<bool>? premiumPurchased,
    Expression<bool>? onboardingDone,
    Expression<String>? modelTier,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (responseStyle != null) 'response_style': responseStyle,
      if (premiumPurchased != null) 'premium_purchased': premiumPurchased,
      if (onboardingDone != null) 'onboarding_done': onboardingDone,
      if (modelTier != null) 'model_tier': modelTier,
    });
  }

  UserPreferencesTableCompanion copyWith({
    Value<int>? id,
    Value<String>? deviceId,
    Value<String>? responseStyle,
    Value<bool>? premiumPurchased,
    Value<bool>? onboardingDone,
    Value<String>? modelTier,
  }) {
    return UserPreferencesTableCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      responseStyle: responseStyle ?? this.responseStyle,
      premiumPurchased: premiumPurchased ?? this.premiumPurchased,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      modelTier: modelTier ?? this.modelTier,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (responseStyle.present) {
      map['response_style'] = Variable<String>(responseStyle.value);
    }
    if (premiumPurchased.present) {
      map['premium_purchased'] = Variable<bool>(premiumPurchased.value);
    }
    if (onboardingDone.present) {
      map['onboarding_done'] = Variable<bool>(onboardingDone.value);
    }
    if (modelTier.present) {
      map['model_tier'] = Variable<String>(modelTier.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesTableCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('responseStyle: $responseStyle, ')
          ..write('premiumPurchased: $premiumPurchased, ')
          ..write('onboardingDone: $onboardingDone, ')
          ..write('modelTier: $modelTier')
          ..write(')'))
        .toString();
  }
}

class $TaskTableTable extends TaskTable
    with TableInfo<$TaskTableTable, TaskTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  @override
  late final GeneratedColumn<String> due = GeneratedColumn<String>(
    'due',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Today'),
  );
  static const VerificationMeta _subtasksMeta = const VerificationMeta(
    'subtasks',
  );
  @override
  late final GeneratedColumn<String> subtasks = GeneratedColumn<String>(
    'subtasks',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    title,
    done,
    priority,
    due,
    subtasks,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('due')) {
      context.handle(
        _dueMeta,
        due.isAcceptableOrUnknown(data['due']!, _dueMeta),
      );
    }
    if (data.containsKey('subtasks')) {
      context.handle(
        _subtasksMeta,
        subtasks.isAcceptableOrUnknown(data['subtasks']!, _subtasksMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}done'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      due: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due'],
      )!,
      subtasks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtasks'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $TaskTableTable createAlias(String alias) {
    return $TaskTableTable(attachedDatabase, alias);
  }
}

class TaskTableData extends DataClass implements Insertable<TaskTableData> {
  final int id;
  final String userId;
  final String title;
  final bool done;
  final String priority;
  final String due;
  final String subtasks;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const TaskTableData({
    required this.id,
    required this.userId,
    required this.title,
    required this.done,
    required this.priority,
    required this.due,
    required this.subtasks,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    map['done'] = Variable<bool>(done);
    map['priority'] = Variable<String>(priority);
    map['due'] = Variable<String>(due);
    map['subtasks'] = Variable<String>(subtasks);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  TaskTableCompanion toCompanion(bool nullToAbsent) {
    return TaskTableCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      done: Value(done),
      priority: Value(priority),
      due: Value(due),
      subtasks: Value(subtasks),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory TaskTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTableData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      done: serializer.fromJson<bool>(json['done']),
      priority: serializer.fromJson<String>(json['priority']),
      due: serializer.fromJson<String>(json['due']),
      subtasks: serializer.fromJson<String>(json['subtasks']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'done': serializer.toJson<bool>(done),
      'priority': serializer.toJson<String>(priority),
      'due': serializer.toJson<String>(due),
      'subtasks': serializer.toJson<String>(subtasks),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  TaskTableData copyWith({
    int? id,
    String? userId,
    String? title,
    bool? done,
    String? priority,
    String? due,
    String? subtasks,
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => TaskTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    done: done ?? this.done,
    priority: priority ?? this.priority,
    due: due ?? this.due,
    subtasks: subtasks ?? this.subtasks,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  TaskTableData copyWithCompanion(TaskTableCompanion data) {
    return TaskTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      done: data.done.present ? data.done.value : this.done,
      priority: data.priority.present ? data.priority.value : this.priority,
      due: data.due.present ? data.due.value : this.due,
      subtasks: data.subtasks.present ? data.subtasks.value : this.subtasks,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('done: $done, ')
          ..write('priority: $priority, ')
          ..write('due: $due, ')
          ..write('subtasks: $subtasks, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    title,
    done,
    priority,
    due,
    subtasks,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.done == this.done &&
          other.priority == this.priority &&
          other.due == this.due &&
          other.subtasks == this.subtasks &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TaskTableCompanion extends UpdateCompanion<TaskTableData> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<bool> done;
  final Value<String> priority;
  final Value<String> due;
  final Value<String> subtasks;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  const TaskTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.done = const Value.absent(),
    this.priority = const Value.absent(),
    this.due = const Value.absent(),
    this.subtasks = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TaskTableCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String title,
    this.done = const Value.absent(),
    this.priority = const Value.absent(),
    this.due = const Value.absent(),
    this.subtasks = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
  }) : userId = Value(userId),
       title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<TaskTableData> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<bool>? done,
    Expression<String>? priority,
    Expression<String>? due,
    Expression<String>? subtasks,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (done != null) 'done': done,
      if (priority != null) 'priority': priority,
      if (due != null) 'due': due,
      if (subtasks != null) 'subtasks': subtasks,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TaskTableCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? title,
    Value<bool>? done,
    Value<String>? priority,
    Value<String>? due,
    Value<String>? subtasks,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
  }) {
    return TaskTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      done: done ?? this.done,
      priority: priority ?? this.priority,
      due: due ?? this.due,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (due.present) {
      map['due'] = Variable<String>(due.value);
    }
    if (subtasks.present) {
      map['subtasks'] = Variable<String>(subtasks.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('done: $done, ')
          ..write('priority: $priority, ')
          ..write('due: $due, ')
          ..write('subtasks: $subtasks, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $HabitTableTable extends HabitTable
    with TableInfo<$HabitTableTable, HabitTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
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
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedDatesMeta = const VerificationMeta(
    'completedDates',
  );
  @override
  late final GeneratedColumn<String> completedDates = GeneratedColumn<String>(
    'completed_dates',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    icon,
    completedDates,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('completed_dates')) {
      context.handle(
        _completedDatesMeta,
        completedDates.isAcceptableOrUnknown(
          data['completed_dates']!,
          _completedDatesMeta,
        ),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      completedDates: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_dates'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $HabitTableTable createAlias(String alias) {
    return $HabitTableTable(attachedDatabase, alias);
  }
}

class HabitTableData extends DataClass implements Insertable<HabitTableData> {
  final int id;
  final String userId;
  final String name;
  final String icon;
  final String completedDates;
  final DateTime createdAt;
  const HabitTableData({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.completedDates,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['completed_dates'] = Variable<String>(completedDates);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HabitTableCompanion toCompanion(bool nullToAbsent) {
    return HabitTableCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      icon: Value(icon),
      completedDates: Value(completedDates),
      createdAt: Value(createdAt),
    );
  }

  factory HabitTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitTableData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      completedDates: serializer.fromJson<String>(json['completedDates']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'completedDates': serializer.toJson<String>(completedDates),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  HabitTableData copyWith({
    int? id,
    String? userId,
    String? name,
    String? icon,
    String? completedDates,
    DateTime? createdAt,
  }) => HabitTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    completedDates: completedDates ?? this.completedDates,
    createdAt: createdAt ?? this.createdAt,
  );
  HabitTableData copyWithCompanion(HabitTableCompanion data) {
    return HabitTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      completedDates: data.completedDates.present
          ? data.completedDates.value
          : this.completedDates,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('completedDates: $completedDates, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, name, icon, completedDates, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.completedDates == this.completedDates &&
          other.createdAt == this.createdAt);
}

class HabitTableCompanion extends UpdateCompanion<HabitTableData> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> icon;
  final Value<String> completedDates;
  final Value<DateTime> createdAt;
  const HabitTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.completedDates = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HabitTableCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String name,
    required String icon,
    this.completedDates = const Value.absent(),
    required DateTime createdAt,
  }) : userId = Value(userId),
       name = Value(name),
       icon = Value(icon),
       createdAt = Value(createdAt);
  static Insertable<HabitTableData> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? completedDates,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (completedDates != null) 'completed_dates': completedDates,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HabitTableCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<String>? icon,
    Value<String>? completedDates,
    Value<DateTime>? createdAt,
  }) {
    return HabitTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      completedDates: completedDates ?? this.completedDates,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (completedDates.present) {
      map['completed_dates'] = Variable<String>(completedDates.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('completedDates: $completedDates, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FocusSessionTableTable extends FocusSessionTable
    with TableInfo<$FocusSessionTableTable, FocusSessionTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusSessionTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    durationMinutes,
    startedAt,
    completedAt,
    completed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_session_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<FocusSessionTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FocusSessionTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusSessionTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
    );
  }

  @override
  $FocusSessionTableTable createAlias(String alias) {
    return $FocusSessionTableTable(attachedDatabase, alias);
  }
}

class FocusSessionTableData extends DataClass
    implements Insertable<FocusSessionTableData> {
  final int id;
  final String userId;
  final int durationMinutes;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool completed;
  const FocusSessionTableData({
    required this.id,
    required this.userId,
    required this.durationMinutes,
    required this.startedAt,
    this.completedAt,
    required this.completed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['completed'] = Variable<bool>(completed);
    return map;
  }

  FocusSessionTableCompanion toCompanion(bool nullToAbsent) {
    return FocusSessionTableCompanion(
      id: Value(id),
      userId: Value(userId),
      durationMinutes: Value(durationMinutes),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      completed: Value(completed),
    );
  }

  factory FocusSessionTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusSessionTableData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      completed: serializer.fromJson<bool>(json['completed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'completed': serializer.toJson<bool>(completed),
    };
  }

  FocusSessionTableData copyWith({
    int? id,
    String? userId,
    int? durationMinutes,
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    bool? completed,
  }) => FocusSessionTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    completed: completed ?? this.completed,
  );
  FocusSessionTableData copyWithCompanion(FocusSessionTableCompanion data) {
    return FocusSessionTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      completed: data.completed.present ? data.completed.value : this.completed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    durationMinutes,
    startedAt,
    completedAt,
    completed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusSessionTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.durationMinutes == this.durationMinutes &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.completed == this.completed);
}

class FocusSessionTableCompanion
    extends UpdateCompanion<FocusSessionTableData> {
  final Value<int> id;
  final Value<String> userId;
  final Value<int> durationMinutes;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<bool> completed;
  const FocusSessionTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completed = const Value.absent(),
  });
  FocusSessionTableCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required int durationMinutes,
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.completed = const Value.absent(),
  }) : userId = Value(userId),
       durationMinutes = Value(durationMinutes),
       startedAt = Value(startedAt);
  static Insertable<FocusSessionTableData> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<int>? durationMinutes,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<bool>? completed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (completed != null) 'completed': completed,
    });
  }

  FocusSessionTableCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<int>? durationMinutes,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<bool>? completed,
  }) {
    return FocusSessionTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      completed: completed ?? this.completed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }
}

class $NoteTableTable extends NoteTable
    with TableInfo<$NoteTableTable, NoteTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    content,
    tags,
    summary,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NoteTableTable createAlias(String alias) {
    return $NoteTableTable(attachedDatabase, alias);
  }
}

class NoteTableData extends DataClass implements Insertable<NoteTableData> {
  final int id;
  final String userId;
  final String content;
  final String tags;
  final String? summary;
  final DateTime createdAt;
  final DateTime updatedAt;
  const NoteTableData({
    required this.id,
    required this.userId,
    required this.content,
    required this.tags,
    this.summary,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['content'] = Variable<String>(content);
    map['tags'] = Variable<String>(tags);
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NoteTableCompanion toCompanion(bool nullToAbsent) {
    return NoteTableCompanion(
      id: Value(id),
      userId: Value(userId),
      content: Value(content),
      tags: Value(tags),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory NoteTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteTableData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      content: serializer.fromJson<String>(json['content']),
      tags: serializer.fromJson<String>(json['tags']),
      summary: serializer.fromJson<String?>(json['summary']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'content': serializer.toJson<String>(content),
      'tags': serializer.toJson<String>(tags),
      'summary': serializer.toJson<String?>(summary),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  NoteTableData copyWith({
    int? id,
    String? userId,
    String? content,
    String? tags,
    Value<String?> summary = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => NoteTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    content: content ?? this.content,
    tags: tags ?? this.tags,
    summary: summary.present ? summary.value : this.summary,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  NoteTableData copyWithCompanion(NoteTableCompanion data) {
    return NoteTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      content: data.content.present ? data.content.value : this.content,
      tags: data.tags.present ? data.tags.value : this.tags,
      summary: data.summary.present ? data.summary.value : this.summary,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('content: $content, ')
          ..write('tags: $tags, ')
          ..write('summary: $summary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, content, tags, summary, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.content == this.content &&
          other.tags == this.tags &&
          other.summary == this.summary &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NoteTableCompanion extends UpdateCompanion<NoteTableData> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> content;
  final Value<String> tags;
  final Value<String?> summary;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const NoteTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.content = const Value.absent(),
    this.tags = const Value.absent(),
    this.summary = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NoteTableCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String content,
    this.tags = const Value.absent(),
    this.summary = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : userId = Value(userId),
       content = Value(content),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<NoteTableData> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? content,
    Expression<String>? tags,
    Expression<String>? summary,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (content != null) 'content': content,
      if (tags != null) 'tags': tags,
      if (summary != null) 'summary': summary,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NoteTableCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? content,
    Value<String>? tags,
    Value<String?>? summary,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return NoteTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('content: $content, ')
          ..write('tags: $tags, ')
          ..write('summary: $summary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MoodEntryTableTable extends MoodEntryTable
    with TableInfo<$MoodEntryTableTable, MoodEntryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoodEntryTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
    'mood',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    mood,
    score,
    date,
    note,
    tags,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mood_entry_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<MoodEntryTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MoodEntryTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoodEntryTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood'],
      ),
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $MoodEntryTableTable createAlias(String alias) {
    return $MoodEntryTableTable(attachedDatabase, alias);
  }
}

class MoodEntryTableData extends DataClass
    implements Insertable<MoodEntryTableData> {
  final int id;
  final String userId;
  final String? mood;
  final int? score;
  final String date;
  final String? note;
  final String? tags;
  final DateTime timestamp;
  const MoodEntryTableData({
    required this.id,
    required this.userId,
    this.mood,
    this.score,
    required this.date,
    this.note,
    this.tags,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<String>(mood);
    }
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<int>(score);
    }
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  MoodEntryTableCompanion toCompanion(bool nullToAbsent) {
    return MoodEntryTableCompanion(
      id: Value(id),
      userId: Value(userId),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
      date: Value(date),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      timestamp: Value(timestamp),
    );
  }

  factory MoodEntryTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoodEntryTableData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      mood: serializer.fromJson<String?>(json['mood']),
      score: serializer.fromJson<int?>(json['score']),
      date: serializer.fromJson<String>(json['date']),
      note: serializer.fromJson<String?>(json['note']),
      tags: serializer.fromJson<String?>(json['tags']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'mood': serializer.toJson<String?>(mood),
      'score': serializer.toJson<int?>(score),
      'date': serializer.toJson<String>(date),
      'note': serializer.toJson<String?>(note),
      'tags': serializer.toJson<String?>(tags),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  MoodEntryTableData copyWith({
    int? id,
    String? userId,
    Value<String?> mood = const Value.absent(),
    Value<int?> score = const Value.absent(),
    String? date,
    Value<String?> note = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    DateTime? timestamp,
  }) => MoodEntryTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    mood: mood.present ? mood.value : this.mood,
    score: score.present ? score.value : this.score,
    date: date ?? this.date,
    note: note.present ? note.value : this.note,
    tags: tags.present ? tags.value : this.tags,
    timestamp: timestamp ?? this.timestamp,
  );
  MoodEntryTableData copyWithCompanion(MoodEntryTableCompanion data) {
    return MoodEntryTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      mood: data.mood.present ? data.mood.value : this.mood,
      score: data.score.present ? data.score.value : this.score,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
      tags: data.tags.present ? data.tags.value : this.tags,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MoodEntryTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('mood: $mood, ')
          ..write('score: $score, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('tags: $tags, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, mood, score, date, note, tags, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoodEntryTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.mood == this.mood &&
          other.score == this.score &&
          other.date == this.date &&
          other.note == this.note &&
          other.tags == this.tags &&
          other.timestamp == this.timestamp);
}

class MoodEntryTableCompanion extends UpdateCompanion<MoodEntryTableData> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String?> mood;
  final Value<int?> score;
  final Value<String> date;
  final Value<String?> note;
  final Value<String?> tags;
  final Value<DateTime> timestamp;
  const MoodEntryTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.mood = const Value.absent(),
    this.score = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.tags = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  MoodEntryTableCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    this.mood = const Value.absent(),
    this.score = const Value.absent(),
    required String date,
    this.note = const Value.absent(),
    this.tags = const Value.absent(),
    required DateTime timestamp,
  }) : userId = Value(userId),
       date = Value(date),
       timestamp = Value(timestamp);
  static Insertable<MoodEntryTableData> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? mood,
    Expression<int>? score,
    Expression<String>? date,
    Expression<String>? note,
    Expression<String>? tags,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (mood != null) 'mood': mood,
      if (score != null) 'score': score,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
      if (tags != null) 'tags': tags,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  MoodEntryTableCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String?>? mood,
    Value<int?>? score,
    Value<String>? date,
    Value<String?>? note,
    Value<String?>? tags,
    Value<DateTime>? timestamp,
  }) {
    return MoodEntryTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mood: mood ?? this.mood,
      score: score ?? this.score,
      date: date ?? this.date,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoodEntryTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('mood: $mood, ')
          ..write('score: $score, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('tags: $tags, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $AiCommandTableTable extends AiCommandTable
    with TableInfo<$AiCommandTableTable, AiCommandTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiCommandTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commandMeta = const VerificationMeta(
    'command',
  );
  @override
  late final GeneratedColumn<String> command = GeneratedColumn<String>(
    'command',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseMeta = const VerificationMeta(
    'response',
  );
  @override
  late final GeneratedColumn<String> response = GeneratedColumn<String>(
    'response',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionsMeta = const VerificationMeta(
    'actions',
  );
  @override
  late final GeneratedColumn<String> actions = GeneratedColumn<String>(
    'actions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    command,
    response,
    actions,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_command_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiCommandTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('command')) {
      context.handle(
        _commandMeta,
        command.isAcceptableOrUnknown(data['command']!, _commandMeta),
      );
    } else if (isInserting) {
      context.missing(_commandMeta);
    }
    if (data.containsKey('response')) {
      context.handle(
        _responseMeta,
        response.isAcceptableOrUnknown(data['response']!, _responseMeta),
      );
    } else if (isInserting) {
      context.missing(_responseMeta);
    }
    if (data.containsKey('actions')) {
      context.handle(
        _actionsMeta,
        actions.isAcceptableOrUnknown(data['actions']!, _actionsMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiCommandTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiCommandTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      command: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}command'],
      )!,
      response: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response'],
      )!,
      actions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actions'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $AiCommandTableTable createAlias(String alias) {
    return $AiCommandTableTable(attachedDatabase, alias);
  }
}

class AiCommandTableData extends DataClass
    implements Insertable<AiCommandTableData> {
  final int id;
  final String userId;
  final String command;
  final String response;
  final String actions;
  final DateTime timestamp;
  const AiCommandTableData({
    required this.id,
    required this.userId,
    required this.command,
    required this.response,
    required this.actions,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['command'] = Variable<String>(command);
    map['response'] = Variable<String>(response);
    map['actions'] = Variable<String>(actions);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  AiCommandTableCompanion toCompanion(bool nullToAbsent) {
    return AiCommandTableCompanion(
      id: Value(id),
      userId: Value(userId),
      command: Value(command),
      response: Value(response),
      actions: Value(actions),
      timestamp: Value(timestamp),
    );
  }

  factory AiCommandTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiCommandTableData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      command: serializer.fromJson<String>(json['command']),
      response: serializer.fromJson<String>(json['response']),
      actions: serializer.fromJson<String>(json['actions']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'command': serializer.toJson<String>(command),
      'response': serializer.toJson<String>(response),
      'actions': serializer.toJson<String>(actions),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  AiCommandTableData copyWith({
    int? id,
    String? userId,
    String? command,
    String? response,
    String? actions,
    DateTime? timestamp,
  }) => AiCommandTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    command: command ?? this.command,
    response: response ?? this.response,
    actions: actions ?? this.actions,
    timestamp: timestamp ?? this.timestamp,
  );
  AiCommandTableData copyWithCompanion(AiCommandTableCompanion data) {
    return AiCommandTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      command: data.command.present ? data.command.value : this.command,
      response: data.response.present ? data.response.value : this.response,
      actions: data.actions.present ? data.actions.value : this.actions,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiCommandTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('command: $command, ')
          ..write('response: $response, ')
          ..write('actions: $actions, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, command, response, actions, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiCommandTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.command == this.command &&
          other.response == this.response &&
          other.actions == this.actions &&
          other.timestamp == this.timestamp);
}

class AiCommandTableCompanion extends UpdateCompanion<AiCommandTableData> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> command;
  final Value<String> response;
  final Value<String> actions;
  final Value<DateTime> timestamp;
  const AiCommandTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.command = const Value.absent(),
    this.response = const Value.absent(),
    this.actions = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  AiCommandTableCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String command,
    required String response,
    this.actions = const Value.absent(),
    required DateTime timestamp,
  }) : userId = Value(userId),
       command = Value(command),
       response = Value(response),
       timestamp = Value(timestamp);
  static Insertable<AiCommandTableData> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? command,
    Expression<String>? response,
    Expression<String>? actions,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (command != null) 'command': command,
      if (response != null) 'response': response,
      if (actions != null) 'actions': actions,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  AiCommandTableCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? command,
    Value<String>? response,
    Value<String>? actions,
    Value<DateTime>? timestamp,
  }) {
    return AiCommandTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      command: command ?? this.command,
      response: response ?? this.response,
      actions: actions ?? this.actions,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (command.present) {
      map['command'] = Variable<String>(command.value);
    }
    if (response.present) {
      map['response'] = Variable<String>(response.value);
    }
    if (actions.present) {
      map['actions'] = Variable<String>(actions.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiCommandTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('command: $command, ')
          ..write('response: $response, ')
          ..write('actions: $actions, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $BehaviorEventTableTable extends BehaviorEventTable
    with TableInfo<$BehaviorEventTableTable, BehaviorEventTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BehaviorEventTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moduleMeta = const VerificationMeta('module');
  @override
  late final GeneratedColumn<String> module = GeneratedColumn<String>(
    'module',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    eventType,
    module,
    metadata,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'behavior_event_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<BehaviorEventTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('module')) {
      context.handle(
        _moduleMeta,
        module.isAcceptableOrUnknown(data['module']!, _moduleMeta),
      );
    } else if (isInserting) {
      context.missing(_moduleMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BehaviorEventTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BehaviorEventTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      module: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $BehaviorEventTableTable createAlias(String alias) {
    return $BehaviorEventTableTable(attachedDatabase, alias);
  }
}

class BehaviorEventTableData extends DataClass
    implements Insertable<BehaviorEventTableData> {
  final int id;
  final String userId;
  final String eventType;
  final String module;
  final String metadata;
  final DateTime timestamp;
  const BehaviorEventTableData({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.module,
    required this.metadata,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['event_type'] = Variable<String>(eventType);
    map['module'] = Variable<String>(module);
    map['metadata'] = Variable<String>(metadata);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  BehaviorEventTableCompanion toCompanion(bool nullToAbsent) {
    return BehaviorEventTableCompanion(
      id: Value(id),
      userId: Value(userId),
      eventType: Value(eventType),
      module: Value(module),
      metadata: Value(metadata),
      timestamp: Value(timestamp),
    );
  }

  factory BehaviorEventTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BehaviorEventTableData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      module: serializer.fromJson<String>(json['module']),
      metadata: serializer.fromJson<String>(json['metadata']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'eventType': serializer.toJson<String>(eventType),
      'module': serializer.toJson<String>(module),
      'metadata': serializer.toJson<String>(metadata),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  BehaviorEventTableData copyWith({
    int? id,
    String? userId,
    String? eventType,
    String? module,
    String? metadata,
    DateTime? timestamp,
  }) => BehaviorEventTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    eventType: eventType ?? this.eventType,
    module: module ?? this.module,
    metadata: metadata ?? this.metadata,
    timestamp: timestamp ?? this.timestamp,
  );
  BehaviorEventTableData copyWithCompanion(BehaviorEventTableCompanion data) {
    return BehaviorEventTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      module: data.module.present ? data.module.value : this.module,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BehaviorEventTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('eventType: $eventType, ')
          ..write('module: $module, ')
          ..write('metadata: $metadata, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, eventType, module, metadata, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BehaviorEventTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.eventType == this.eventType &&
          other.module == this.module &&
          other.metadata == this.metadata &&
          other.timestamp == this.timestamp);
}

class BehaviorEventTableCompanion
    extends UpdateCompanion<BehaviorEventTableData> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> eventType;
  final Value<String> module;
  final Value<String> metadata;
  final Value<DateTime> timestamp;
  const BehaviorEventTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.module = const Value.absent(),
    this.metadata = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  BehaviorEventTableCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String eventType,
    required String module,
    this.metadata = const Value.absent(),
    required DateTime timestamp,
  }) : userId = Value(userId),
       eventType = Value(eventType),
       module = Value(module),
       timestamp = Value(timestamp);
  static Insertable<BehaviorEventTableData> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? eventType,
    Expression<String>? module,
    Expression<String>? metadata,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (eventType != null) 'event_type': eventType,
      if (module != null) 'module': module,
      if (metadata != null) 'metadata': metadata,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  BehaviorEventTableCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? eventType,
    Value<String>? module,
    Value<String>? metadata,
    Value<DateTime>? timestamp,
  }) {
    return BehaviorEventTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventType: eventType ?? this.eventType,
      module: module ?? this.module,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (module.present) {
      map['module'] = Variable<String>(module.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BehaviorEventTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('eventType: $eventType, ')
          ..write('module: $module, ')
          ..write('metadata: $metadata, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $ConversationTableTable extends ConversationTable
    with TableInfo<$ConversationTableTable, ConversationTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelTierMeta = const VerificationMeta(
    'modelTier',
  );
  @override
  late final GeneratedColumn<String> modelTier = GeneratedColumn<String>(
    'model_tier',
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    title,
    modelTier,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversation_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('model_tier')) {
      context.handle(
        _modelTierMeta,
        modelTier.isAcceptableOrUnknown(data['model_tier']!, _modelTierMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConversationTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      modelTier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_tier'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ConversationTableTable createAlias(String alias) {
    return $ConversationTableTable(attachedDatabase, alias);
  }
}

class ConversationTableData extends DataClass
    implements Insertable<ConversationTableData> {
  final int id;
  final String userId;
  final String title;
  final String? modelTier;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ConversationTableData({
    required this.id,
    required this.userId,
    required this.title,
    this.modelTier,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || modelTier != null) {
      map['model_tier'] = Variable<String>(modelTier);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ConversationTableCompanion toCompanion(bool nullToAbsent) {
    return ConversationTableCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      modelTier: modelTier == null && nullToAbsent
          ? const Value.absent()
          : Value(modelTier),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ConversationTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationTableData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      modelTier: serializer.fromJson<String?>(json['modelTier']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'modelTier': serializer.toJson<String?>(modelTier),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ConversationTableData copyWith({
    int? id,
    String? userId,
    String? title,
    Value<String?> modelTier = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ConversationTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    modelTier: modelTier.present ? modelTier.value : this.modelTier,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ConversationTableData copyWithCompanion(ConversationTableCompanion data) {
    return ConversationTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      modelTier: data.modelTier.present ? data.modelTier.value : this.modelTier,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('modelTier: $modelTier, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, title, modelTier, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.modelTier == this.modelTier &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ConversationTableCompanion
    extends UpdateCompanion<ConversationTableData> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<String?> modelTier;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ConversationTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.modelTier = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ConversationTableCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String title,
    this.modelTier = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : userId = Value(userId),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ConversationTableData> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? modelTier,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (modelTier != null) 'model_tier': modelTier,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ConversationTableCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? title,
    Value<String?>? modelTier,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ConversationTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      modelTier: modelTier ?? this.modelTier,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (modelTier.present) {
      map['model_tier'] = Variable<String>(modelTier.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('modelTier: $modelTier, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MessageTableTable extends MessageTable
    with TableInfo<$MessageTableTable, MessageTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<int> conversationId = GeneratedColumn<int>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widgetJsonMeta = const VerificationMeta(
    'widgetJson',
  );
  @override
  late final GeneratedColumn<String> widgetJson = GeneratedColumn<String>(
    'widget_json',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    role,
    content,
    widgetJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('widget_json')) {
      context.handle(
        _widgetJsonMeta,
        widgetJson.isAcceptableOrUnknown(data['widget_json']!, _widgetJsonMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}conversation_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      widgetJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}widget_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MessageTableTable createAlias(String alias) {
    return $MessageTableTable(attachedDatabase, alias);
  }
}

class MessageTableData extends DataClass
    implements Insertable<MessageTableData> {
  final int id;
  final int conversationId;
  final String role;
  final String content;
  final String? widgetJson;
  final DateTime createdAt;
  const MessageTableData({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.widgetJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['conversation_id'] = Variable<int>(conversationId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || widgetJson != null) {
      map['widget_json'] = Variable<String>(widgetJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MessageTableCompanion toCompanion(bool nullToAbsent) {
    return MessageTableCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      role: Value(role),
      content: Value(content),
      widgetJson: widgetJson == null && nullToAbsent
          ? const Value.absent()
          : Value(widgetJson),
      createdAt: Value(createdAt),
    );
  }

  factory MessageTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageTableData(
      id: serializer.fromJson<int>(json['id']),
      conversationId: serializer.fromJson<int>(json['conversationId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      widgetJson: serializer.fromJson<String?>(json['widgetJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'conversationId': serializer.toJson<int>(conversationId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'widgetJson': serializer.toJson<String?>(widgetJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MessageTableData copyWith({
    int? id,
    int? conversationId,
    String? role,
    String? content,
    Value<String?> widgetJson = const Value.absent(),
    DateTime? createdAt,
  }) => MessageTableData(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    role: role ?? this.role,
    content: content ?? this.content,
    widgetJson: widgetJson.present ? widgetJson.value : this.widgetJson,
    createdAt: createdAt ?? this.createdAt,
  );
  MessageTableData copyWithCompanion(MessageTableCompanion data) {
    return MessageTableData(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      widgetJson: data.widgetJson.present
          ? data.widgetJson.value
          : this.widgetJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageTableData(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('widgetJson: $widgetJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, conversationId, role, content, widgetJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageTableData &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.role == this.role &&
          other.content == this.content &&
          other.widgetJson == this.widgetJson &&
          other.createdAt == this.createdAt);
}

class MessageTableCompanion extends UpdateCompanion<MessageTableData> {
  final Value<int> id;
  final Value<int> conversationId;
  final Value<String> role;
  final Value<String> content;
  final Value<String?> widgetJson;
  final Value<DateTime> createdAt;
  const MessageTableCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.widgetJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MessageTableCompanion.insert({
    this.id = const Value.absent(),
    required int conversationId,
    required String role,
    required String content,
    this.widgetJson = const Value.absent(),
    required DateTime createdAt,
  }) : conversationId = Value(conversationId),
       role = Value(role),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<MessageTableData> custom({
    Expression<int>? id,
    Expression<int>? conversationId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? widgetJson,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (widgetJson != null) 'widget_json': widgetJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MessageTableCompanion copyWith({
    Value<int>? id,
    Value<int>? conversationId,
    Value<String>? role,
    Value<String>? content,
    Value<String?>? widgetJson,
    Value<DateTime>? createdAt,
  }) {
    return MessageTableCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      widgetJson: widgetJson ?? this.widgetJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<int>(conversationId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (widgetJson.present) {
      map['widget_json'] = Variable<String>(widgetJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageTableCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('widgetJson: $widgetJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfileTableTable profileTable = $ProfileTableTable(this);
  late final $UserPreferencesTableTable userPreferencesTable =
      $UserPreferencesTableTable(this);
  late final $TaskTableTable taskTable = $TaskTableTable(this);
  late final $HabitTableTable habitTable = $HabitTableTable(this);
  late final $FocusSessionTableTable focusSessionTable =
      $FocusSessionTableTable(this);
  late final $NoteTableTable noteTable = $NoteTableTable(this);
  late final $MoodEntryTableTable moodEntryTable = $MoodEntryTableTable(this);
  late final $AiCommandTableTable aiCommandTable = $AiCommandTableTable(this);
  late final $BehaviorEventTableTable behaviorEventTable =
      $BehaviorEventTableTable(this);
  late final $ConversationTableTable conversationTable =
      $ConversationTableTable(this);
  late final $MessageTableTable messageTable = $MessageTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profileTable,
    userPreferencesTable,
    taskTable,
    habitTable,
    focusSessionTable,
    noteTable,
    moodEntryTable,
    aiCommandTable,
    behaviorEventTable,
    conversationTable,
    messageTable,
  ];
}

typedef $$ProfileTableTableCreateCompanionBuilder =
    ProfileTableCompanion Function({
      Value<int> id,
      required String userId,
      required String name,
      Value<String?> focusArea,
      Value<String?> supportNeed,
      Value<bool> isGuest,
      Value<String?> modelTier,
      required DateTime updatedAt,
    });
typedef $$ProfileTableTableUpdateCompanionBuilder =
    ProfileTableCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> name,
      Value<String?> focusArea,
      Value<String?> supportNeed,
      Value<bool> isGuest,
      Value<String?> modelTier,
      Value<DateTime> updatedAt,
    });

class $$ProfileTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProfileTableTable> {
  $$ProfileTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get focusArea => $composableBuilder(
    column: $table.focusArea,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supportNeed => $composableBuilder(
    column: $table.supportNeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGuest => $composableBuilder(
    column: $table.isGuest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelTier => $composableBuilder(
    column: $table.modelTier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfileTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfileTableTable> {
  $$ProfileTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get focusArea => $composableBuilder(
    column: $table.focusArea,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supportNeed => $composableBuilder(
    column: $table.supportNeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGuest => $composableBuilder(
    column: $table.isGuest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelTier => $composableBuilder(
    column: $table.modelTier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfileTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfileTableTable> {
  $$ProfileTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get focusArea =>
      $composableBuilder(column: $table.focusArea, builder: (column) => column);

  GeneratedColumn<String> get supportNeed => $composableBuilder(
    column: $table.supportNeed,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isGuest =>
      $composableBuilder(column: $table.isGuest, builder: (column) => column);

  GeneratedColumn<String> get modelTier =>
      $composableBuilder(column: $table.modelTier, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProfileTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfileTableTable,
          ProfileTableData,
          $$ProfileTableTableFilterComposer,
          $$ProfileTableTableOrderingComposer,
          $$ProfileTableTableAnnotationComposer,
          $$ProfileTableTableCreateCompanionBuilder,
          $$ProfileTableTableUpdateCompanionBuilder,
          (
            ProfileTableData,
            BaseReferences<_$AppDatabase, $ProfileTableTable, ProfileTableData>,
          ),
          ProfileTableData,
          PrefetchHooks Function()
        > {
  $$ProfileTableTableTableManager(_$AppDatabase db, $ProfileTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> focusArea = const Value.absent(),
                Value<String?> supportNeed = const Value.absent(),
                Value<bool> isGuest = const Value.absent(),
                Value<String?> modelTier = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProfileTableCompanion(
                id: id,
                userId: userId,
                name: name,
                focusArea: focusArea,
                supportNeed: supportNeed,
                isGuest: isGuest,
                modelTier: modelTier,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String name,
                Value<String?> focusArea = const Value.absent(),
                Value<String?> supportNeed = const Value.absent(),
                Value<bool> isGuest = const Value.absent(),
                Value<String?> modelTier = const Value.absent(),
                required DateTime updatedAt,
              }) => ProfileTableCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                focusArea: focusArea,
                supportNeed: supportNeed,
                isGuest: isGuest,
                modelTier: modelTier,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfileTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfileTableTable,
      ProfileTableData,
      $$ProfileTableTableFilterComposer,
      $$ProfileTableTableOrderingComposer,
      $$ProfileTableTableAnnotationComposer,
      $$ProfileTableTableCreateCompanionBuilder,
      $$ProfileTableTableUpdateCompanionBuilder,
      (
        ProfileTableData,
        BaseReferences<_$AppDatabase, $ProfileTableTable, ProfileTableData>,
      ),
      ProfileTableData,
      PrefetchHooks Function()
    >;
typedef $$UserPreferencesTableTableCreateCompanionBuilder =
    UserPreferencesTableCompanion Function({
      Value<int> id,
      required String deviceId,
      Value<String> responseStyle,
      Value<bool> premiumPurchased,
      Value<bool> onboardingDone,
      Value<String> modelTier,
    });
typedef $$UserPreferencesTableTableUpdateCompanionBuilder =
    UserPreferencesTableCompanion Function({
      Value<int> id,
      Value<String> deviceId,
      Value<String> responseStyle,
      Value<bool> premiumPurchased,
      Value<bool> onboardingDone,
      Value<String> modelTier,
    });

class $$UserPreferencesTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableFilterComposer({
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

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseStyle => $composableBuilder(
    column: $table.responseStyle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get premiumPurchased => $composableBuilder(
    column: $table.premiumPurchased,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelTier => $composableBuilder(
    column: $table.modelTier,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserPreferencesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableOrderingComposer({
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

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseStyle => $composableBuilder(
    column: $table.responseStyle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get premiumPurchased => $composableBuilder(
    column: $table.premiumPurchased,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelTier => $composableBuilder(
    column: $table.modelTier,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserPreferencesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get responseStyle => $composableBuilder(
    column: $table.responseStyle,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get premiumPurchased => $composableBuilder(
    column: $table.premiumPurchased,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelTier =>
      $composableBuilder(column: $table.modelTier, builder: (column) => column);
}

class $$UserPreferencesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserPreferencesTableTable,
          UserPreferencesTableData,
          $$UserPreferencesTableTableFilterComposer,
          $$UserPreferencesTableTableOrderingComposer,
          $$UserPreferencesTableTableAnnotationComposer,
          $$UserPreferencesTableTableCreateCompanionBuilder,
          $$UserPreferencesTableTableUpdateCompanionBuilder,
          (
            UserPreferencesTableData,
            BaseReferences<
              _$AppDatabase,
              $UserPreferencesTableTable,
              UserPreferencesTableData
            >,
          ),
          UserPreferencesTableData,
          PrefetchHooks Function()
        > {
  $$UserPreferencesTableTableTableManager(
    _$AppDatabase db,
    $UserPreferencesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPreferencesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPreferencesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserPreferencesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> responseStyle = const Value.absent(),
                Value<bool> premiumPurchased = const Value.absent(),
                Value<bool> onboardingDone = const Value.absent(),
                Value<String> modelTier = const Value.absent(),
              }) => UserPreferencesTableCompanion(
                id: id,
                deviceId: deviceId,
                responseStyle: responseStyle,
                premiumPurchased: premiumPurchased,
                onboardingDone: onboardingDone,
                modelTier: modelTier,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String deviceId,
                Value<String> responseStyle = const Value.absent(),
                Value<bool> premiumPurchased = const Value.absent(),
                Value<bool> onboardingDone = const Value.absent(),
                Value<String> modelTier = const Value.absent(),
              }) => UserPreferencesTableCompanion.insert(
                id: id,
                deviceId: deviceId,
                responseStyle: responseStyle,
                premiumPurchased: premiumPurchased,
                onboardingDone: onboardingDone,
                modelTier: modelTier,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserPreferencesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserPreferencesTableTable,
      UserPreferencesTableData,
      $$UserPreferencesTableTableFilterComposer,
      $$UserPreferencesTableTableOrderingComposer,
      $$UserPreferencesTableTableAnnotationComposer,
      $$UserPreferencesTableTableCreateCompanionBuilder,
      $$UserPreferencesTableTableUpdateCompanionBuilder,
      (
        UserPreferencesTableData,
        BaseReferences<
          _$AppDatabase,
          $UserPreferencesTableTable,
          UserPreferencesTableData
        >,
      ),
      UserPreferencesTableData,
      PrefetchHooks Function()
    >;
typedef $$TaskTableTableCreateCompanionBuilder =
    TaskTableCompanion Function({
      Value<int> id,
      required String userId,
      required String title,
      Value<bool> done,
      Value<String> priority,
      Value<String> due,
      Value<String> subtasks,
      required DateTime createdAt,
      Value<DateTime?> updatedAt,
    });
typedef $$TaskTableTableUpdateCompanionBuilder =
    TaskTableCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> title,
      Value<bool> done,
      Value<String> priority,
      Value<String> due,
      Value<String> subtasks,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
    });

class $$TaskTableTableFilterComposer
    extends Composer<_$AppDatabase, $TaskTableTable> {
  $$TaskTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtasks => $composableBuilder(
    column: $table.subtasks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskTableTable> {
  $$TaskTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtasks => $composableBuilder(
    column: $table.subtasks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskTableTable> {
  $$TaskTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  GeneratedColumn<String> get subtasks =>
      $composableBuilder(column: $table.subtasks, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TaskTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskTableTable,
          TaskTableData,
          $$TaskTableTableFilterComposer,
          $$TaskTableTableOrderingComposer,
          $$TaskTableTableAnnotationComposer,
          $$TaskTableTableCreateCompanionBuilder,
          $$TaskTableTableUpdateCompanionBuilder,
          (
            TaskTableData,
            BaseReferences<_$AppDatabase, $TaskTableTable, TaskTableData>,
          ),
          TaskTableData,
          PrefetchHooks Function()
        > {
  $$TaskTableTableTableManager(_$AppDatabase db, $TaskTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> done = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> due = const Value.absent(),
                Value<String> subtasks = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => TaskTableCompanion(
                id: id,
                userId: userId,
                title: title,
                done: done,
                priority: priority,
                due: due,
                subtasks: subtasks,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String title,
                Value<bool> done = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> due = const Value.absent(),
                Value<String> subtasks = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => TaskTableCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                done: done,
                priority: priority,
                due: due,
                subtasks: subtasks,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskTableTable,
      TaskTableData,
      $$TaskTableTableFilterComposer,
      $$TaskTableTableOrderingComposer,
      $$TaskTableTableAnnotationComposer,
      $$TaskTableTableCreateCompanionBuilder,
      $$TaskTableTableUpdateCompanionBuilder,
      (
        TaskTableData,
        BaseReferences<_$AppDatabase, $TaskTableTable, TaskTableData>,
      ),
      TaskTableData,
      PrefetchHooks Function()
    >;
typedef $$HabitTableTableCreateCompanionBuilder =
    HabitTableCompanion Function({
      Value<int> id,
      required String userId,
      required String name,
      required String icon,
      Value<String> completedDates,
      required DateTime createdAt,
    });
typedef $$HabitTableTableUpdateCompanionBuilder =
    HabitTableCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> name,
      Value<String> icon,
      Value<String> completedDates,
      Value<DateTime> createdAt,
    });

class $$HabitTableTableFilterComposer
    extends Composer<_$AppDatabase, $HabitTableTable> {
  $$HabitTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedDates => $composableBuilder(
    column: $table.completedDates,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HabitTableTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitTableTable> {
  $$HabitTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedDates => $composableBuilder(
    column: $table.completedDates,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitTableTable> {
  $$HabitTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get completedDates => $composableBuilder(
    column: $table.completedDates,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$HabitTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitTableTable,
          HabitTableData,
          $$HabitTableTableFilterComposer,
          $$HabitTableTableOrderingComposer,
          $$HabitTableTableAnnotationComposer,
          $$HabitTableTableCreateCompanionBuilder,
          $$HabitTableTableUpdateCompanionBuilder,
          (
            HabitTableData,
            BaseReferences<_$AppDatabase, $HabitTableTable, HabitTableData>,
          ),
          HabitTableData,
          PrefetchHooks Function()
        > {
  $$HabitTableTableTableManager(_$AppDatabase db, $HabitTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String> completedDates = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => HabitTableCompanion(
                id: id,
                userId: userId,
                name: name,
                icon: icon,
                completedDates: completedDates,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String name,
                required String icon,
                Value<String> completedDates = const Value.absent(),
                required DateTime createdAt,
              }) => HabitTableCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                icon: icon,
                completedDates: completedDates,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HabitTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitTableTable,
      HabitTableData,
      $$HabitTableTableFilterComposer,
      $$HabitTableTableOrderingComposer,
      $$HabitTableTableAnnotationComposer,
      $$HabitTableTableCreateCompanionBuilder,
      $$HabitTableTableUpdateCompanionBuilder,
      (
        HabitTableData,
        BaseReferences<_$AppDatabase, $HabitTableTable, HabitTableData>,
      ),
      HabitTableData,
      PrefetchHooks Function()
    >;
typedef $$FocusSessionTableTableCreateCompanionBuilder =
    FocusSessionTableCompanion Function({
      Value<int> id,
      required String userId,
      required int durationMinutes,
      required DateTime startedAt,
      Value<DateTime?> completedAt,
      Value<bool> completed,
    });
typedef $$FocusSessionTableTableUpdateCompanionBuilder =
    FocusSessionTableCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<int> durationMinutes,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<bool> completed,
    });

class $$FocusSessionTableTableFilterComposer
    extends Composer<_$AppDatabase, $FocusSessionTableTable> {
  $$FocusSessionTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FocusSessionTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FocusSessionTableTable> {
  $$FocusSessionTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FocusSessionTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FocusSessionTableTable> {
  $$FocusSessionTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);
}

class $$FocusSessionTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FocusSessionTableTable,
          FocusSessionTableData,
          $$FocusSessionTableTableFilterComposer,
          $$FocusSessionTableTableOrderingComposer,
          $$FocusSessionTableTableAnnotationComposer,
          $$FocusSessionTableTableCreateCompanionBuilder,
          $$FocusSessionTableTableUpdateCompanionBuilder,
          (
            FocusSessionTableData,
            BaseReferences<
              _$AppDatabase,
              $FocusSessionTableTable,
              FocusSessionTableData
            >,
          ),
          FocusSessionTableData,
          PrefetchHooks Function()
        > {
  $$FocusSessionTableTableTableManager(
    _$AppDatabase db,
    $FocusSessionTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FocusSessionTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FocusSessionTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FocusSessionTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<bool> completed = const Value.absent(),
              }) => FocusSessionTableCompanion(
                id: id,
                userId: userId,
                durationMinutes: durationMinutes,
                startedAt: startedAt,
                completedAt: completedAt,
                completed: completed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required int durationMinutes,
                required DateTime startedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<bool> completed = const Value.absent(),
              }) => FocusSessionTableCompanion.insert(
                id: id,
                userId: userId,
                durationMinutes: durationMinutes,
                startedAt: startedAt,
                completedAt: completedAt,
                completed: completed,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FocusSessionTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FocusSessionTableTable,
      FocusSessionTableData,
      $$FocusSessionTableTableFilterComposer,
      $$FocusSessionTableTableOrderingComposer,
      $$FocusSessionTableTableAnnotationComposer,
      $$FocusSessionTableTableCreateCompanionBuilder,
      $$FocusSessionTableTableUpdateCompanionBuilder,
      (
        FocusSessionTableData,
        BaseReferences<
          _$AppDatabase,
          $FocusSessionTableTable,
          FocusSessionTableData
        >,
      ),
      FocusSessionTableData,
      PrefetchHooks Function()
    >;
typedef $$NoteTableTableCreateCompanionBuilder =
    NoteTableCompanion Function({
      Value<int> id,
      required String userId,
      required String content,
      Value<String> tags,
      Value<String?> summary,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$NoteTableTableUpdateCompanionBuilder =
    NoteTableCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> content,
      Value<String> tags,
      Value<String?> summary,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$NoteTableTableFilterComposer
    extends Composer<_$AppDatabase, $NoteTableTable> {
  $$NoteTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NoteTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NoteTableTable> {
  $$NoteTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NoteTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NoteTableTable> {
  $$NoteTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NoteTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NoteTableTable,
          NoteTableData,
          $$NoteTableTableFilterComposer,
          $$NoteTableTableOrderingComposer,
          $$NoteTableTableAnnotationComposer,
          $$NoteTableTableCreateCompanionBuilder,
          $$NoteTableTableUpdateCompanionBuilder,
          (
            NoteTableData,
            BaseReferences<_$AppDatabase, $NoteTableTable, NoteTableData>,
          ),
          NoteTableData,
          PrefetchHooks Function()
        > {
  $$NoteTableTableTableManager(_$AppDatabase db, $NoteTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => NoteTableCompanion(
                id: id,
                userId: userId,
                content: content,
                tags: tags,
                summary: summary,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String content,
                Value<String> tags = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => NoteTableCompanion.insert(
                id: id,
                userId: userId,
                content: content,
                tags: tags,
                summary: summary,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NoteTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NoteTableTable,
      NoteTableData,
      $$NoteTableTableFilterComposer,
      $$NoteTableTableOrderingComposer,
      $$NoteTableTableAnnotationComposer,
      $$NoteTableTableCreateCompanionBuilder,
      $$NoteTableTableUpdateCompanionBuilder,
      (
        NoteTableData,
        BaseReferences<_$AppDatabase, $NoteTableTable, NoteTableData>,
      ),
      NoteTableData,
      PrefetchHooks Function()
    >;
typedef $$MoodEntryTableTableCreateCompanionBuilder =
    MoodEntryTableCompanion Function({
      Value<int> id,
      required String userId,
      Value<String?> mood,
      Value<int?> score,
      required String date,
      Value<String?> note,
      Value<String?> tags,
      required DateTime timestamp,
    });
typedef $$MoodEntryTableTableUpdateCompanionBuilder =
    MoodEntryTableCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String?> mood,
      Value<int?> score,
      Value<String> date,
      Value<String?> note,
      Value<String?> tags,
      Value<DateTime> timestamp,
    });

class $$MoodEntryTableTableFilterComposer
    extends Composer<_$AppDatabase, $MoodEntryTableTable> {
  $$MoodEntryTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MoodEntryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MoodEntryTableTable> {
  $$MoodEntryTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MoodEntryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoodEntryTableTable> {
  $$MoodEntryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$MoodEntryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoodEntryTableTable,
          MoodEntryTableData,
          $$MoodEntryTableTableFilterComposer,
          $$MoodEntryTableTableOrderingComposer,
          $$MoodEntryTableTableAnnotationComposer,
          $$MoodEntryTableTableCreateCompanionBuilder,
          $$MoodEntryTableTableUpdateCompanionBuilder,
          (
            MoodEntryTableData,
            BaseReferences<
              _$AppDatabase,
              $MoodEntryTableTable,
              MoodEntryTableData
            >,
          ),
          MoodEntryTableData,
          PrefetchHooks Function()
        > {
  $$MoodEntryTableTableTableManager(
    _$AppDatabase db,
    $MoodEntryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoodEntryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoodEntryTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoodEntryTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> mood = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => MoodEntryTableCompanion(
                id: id,
                userId: userId,
                mood: mood,
                score: score,
                date: date,
                note: note,
                tags: tags,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                Value<String?> mood = const Value.absent(),
                Value<int?> score = const Value.absent(),
                required String date,
                Value<String?> note = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                required DateTime timestamp,
              }) => MoodEntryTableCompanion.insert(
                id: id,
                userId: userId,
                mood: mood,
                score: score,
                date: date,
                note: note,
                tags: tags,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MoodEntryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoodEntryTableTable,
      MoodEntryTableData,
      $$MoodEntryTableTableFilterComposer,
      $$MoodEntryTableTableOrderingComposer,
      $$MoodEntryTableTableAnnotationComposer,
      $$MoodEntryTableTableCreateCompanionBuilder,
      $$MoodEntryTableTableUpdateCompanionBuilder,
      (
        MoodEntryTableData,
        BaseReferences<_$AppDatabase, $MoodEntryTableTable, MoodEntryTableData>,
      ),
      MoodEntryTableData,
      PrefetchHooks Function()
    >;
typedef $$AiCommandTableTableCreateCompanionBuilder =
    AiCommandTableCompanion Function({
      Value<int> id,
      required String userId,
      required String command,
      required String response,
      Value<String> actions,
      required DateTime timestamp,
    });
typedef $$AiCommandTableTableUpdateCompanionBuilder =
    AiCommandTableCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> command,
      Value<String> response,
      Value<String> actions,
      Value<DateTime> timestamp,
    });

class $$AiCommandTableTableFilterComposer
    extends Composer<_$AppDatabase, $AiCommandTableTable> {
  $$AiCommandTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get command => $composableBuilder(
    column: $table.command,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get response => $composableBuilder(
    column: $table.response,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actions => $composableBuilder(
    column: $table.actions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AiCommandTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AiCommandTableTable> {
  $$AiCommandTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get command => $composableBuilder(
    column: $table.command,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get response => $composableBuilder(
    column: $table.response,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actions => $composableBuilder(
    column: $table.actions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiCommandTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiCommandTableTable> {
  $$AiCommandTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get command =>
      $composableBuilder(column: $table.command, builder: (column) => column);

  GeneratedColumn<String> get response =>
      $composableBuilder(column: $table.response, builder: (column) => column);

  GeneratedColumn<String> get actions =>
      $composableBuilder(column: $table.actions, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$AiCommandTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiCommandTableTable,
          AiCommandTableData,
          $$AiCommandTableTableFilterComposer,
          $$AiCommandTableTableOrderingComposer,
          $$AiCommandTableTableAnnotationComposer,
          $$AiCommandTableTableCreateCompanionBuilder,
          $$AiCommandTableTableUpdateCompanionBuilder,
          (
            AiCommandTableData,
            BaseReferences<
              _$AppDatabase,
              $AiCommandTableTable,
              AiCommandTableData
            >,
          ),
          AiCommandTableData,
          PrefetchHooks Function()
        > {
  $$AiCommandTableTableTableManager(
    _$AppDatabase db,
    $AiCommandTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiCommandTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiCommandTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiCommandTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> command = const Value.absent(),
                Value<String> response = const Value.absent(),
                Value<String> actions = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => AiCommandTableCompanion(
                id: id,
                userId: userId,
                command: command,
                response: response,
                actions: actions,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String command,
                required String response,
                Value<String> actions = const Value.absent(),
                required DateTime timestamp,
              }) => AiCommandTableCompanion.insert(
                id: id,
                userId: userId,
                command: command,
                response: response,
                actions: actions,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AiCommandTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiCommandTableTable,
      AiCommandTableData,
      $$AiCommandTableTableFilterComposer,
      $$AiCommandTableTableOrderingComposer,
      $$AiCommandTableTableAnnotationComposer,
      $$AiCommandTableTableCreateCompanionBuilder,
      $$AiCommandTableTableUpdateCompanionBuilder,
      (
        AiCommandTableData,
        BaseReferences<_$AppDatabase, $AiCommandTableTable, AiCommandTableData>,
      ),
      AiCommandTableData,
      PrefetchHooks Function()
    >;
typedef $$BehaviorEventTableTableCreateCompanionBuilder =
    BehaviorEventTableCompanion Function({
      Value<int> id,
      required String userId,
      required String eventType,
      required String module,
      Value<String> metadata,
      required DateTime timestamp,
    });
typedef $$BehaviorEventTableTableUpdateCompanionBuilder =
    BehaviorEventTableCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> eventType,
      Value<String> module,
      Value<String> metadata,
      Value<DateTime> timestamp,
    });

class $$BehaviorEventTableTableFilterComposer
    extends Composer<_$AppDatabase, $BehaviorEventTableTable> {
  $$BehaviorEventTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BehaviorEventTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BehaviorEventTableTable> {
  $$BehaviorEventTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BehaviorEventTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BehaviorEventTableTable> {
  $$BehaviorEventTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get module =>
      $composableBuilder(column: $table.module, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$BehaviorEventTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BehaviorEventTableTable,
          BehaviorEventTableData,
          $$BehaviorEventTableTableFilterComposer,
          $$BehaviorEventTableTableOrderingComposer,
          $$BehaviorEventTableTableAnnotationComposer,
          $$BehaviorEventTableTableCreateCompanionBuilder,
          $$BehaviorEventTableTableUpdateCompanionBuilder,
          (
            BehaviorEventTableData,
            BaseReferences<
              _$AppDatabase,
              $BehaviorEventTableTable,
              BehaviorEventTableData
            >,
          ),
          BehaviorEventTableData,
          PrefetchHooks Function()
        > {
  $$BehaviorEventTableTableTableManager(
    _$AppDatabase db,
    $BehaviorEventTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BehaviorEventTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BehaviorEventTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BehaviorEventTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String> module = const Value.absent(),
                Value<String> metadata = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => BehaviorEventTableCompanion(
                id: id,
                userId: userId,
                eventType: eventType,
                module: module,
                metadata: metadata,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String eventType,
                required String module,
                Value<String> metadata = const Value.absent(),
                required DateTime timestamp,
              }) => BehaviorEventTableCompanion.insert(
                id: id,
                userId: userId,
                eventType: eventType,
                module: module,
                metadata: metadata,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BehaviorEventTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BehaviorEventTableTable,
      BehaviorEventTableData,
      $$BehaviorEventTableTableFilterComposer,
      $$BehaviorEventTableTableOrderingComposer,
      $$BehaviorEventTableTableAnnotationComposer,
      $$BehaviorEventTableTableCreateCompanionBuilder,
      $$BehaviorEventTableTableUpdateCompanionBuilder,
      (
        BehaviorEventTableData,
        BaseReferences<
          _$AppDatabase,
          $BehaviorEventTableTable,
          BehaviorEventTableData
        >,
      ),
      BehaviorEventTableData,
      PrefetchHooks Function()
    >;
typedef $$ConversationTableTableCreateCompanionBuilder =
    ConversationTableCompanion Function({
      Value<int> id,
      required String userId,
      required String title,
      Value<String?> modelTier,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$ConversationTableTableUpdateCompanionBuilder =
    ConversationTableCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> title,
      Value<String?> modelTier,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$ConversationTableTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationTableTable> {
  $$ConversationTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelTier => $composableBuilder(
    column: $table.modelTier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConversationTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationTableTable> {
  $$ConversationTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelTier => $composableBuilder(
    column: $table.modelTier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationTableTable> {
  $$ConversationTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get modelTier =>
      $composableBuilder(column: $table.modelTier, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ConversationTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationTableTable,
          ConversationTableData,
          $$ConversationTableTableFilterComposer,
          $$ConversationTableTableOrderingComposer,
          $$ConversationTableTableAnnotationComposer,
          $$ConversationTableTableCreateCompanionBuilder,
          $$ConversationTableTableUpdateCompanionBuilder,
          (
            ConversationTableData,
            BaseReferences<
              _$AppDatabase,
              $ConversationTableTable,
              ConversationTableData
            >,
          ),
          ConversationTableData,
          PrefetchHooks Function()
        > {
  $$ConversationTableTableTableManager(
    _$AppDatabase db,
    $ConversationTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> modelTier = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ConversationTableCompanion(
                id: id,
                userId: userId,
                title: title,
                modelTier: modelTier,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String title,
                Value<String?> modelTier = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ConversationTableCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                modelTier: modelTier,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConversationTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationTableTable,
      ConversationTableData,
      $$ConversationTableTableFilterComposer,
      $$ConversationTableTableOrderingComposer,
      $$ConversationTableTableAnnotationComposer,
      $$ConversationTableTableCreateCompanionBuilder,
      $$ConversationTableTableUpdateCompanionBuilder,
      (
        ConversationTableData,
        BaseReferences<
          _$AppDatabase,
          $ConversationTableTable,
          ConversationTableData
        >,
      ),
      ConversationTableData,
      PrefetchHooks Function()
    >;
typedef $$MessageTableTableCreateCompanionBuilder =
    MessageTableCompanion Function({
      Value<int> id,
      required int conversationId,
      required String role,
      required String content,
      Value<String?> widgetJson,
      required DateTime createdAt,
    });
typedef $$MessageTableTableUpdateCompanionBuilder =
    MessageTableCompanion Function({
      Value<int> id,
      Value<int> conversationId,
      Value<String> role,
      Value<String> content,
      Value<String?> widgetJson,
      Value<DateTime> createdAt,
    });

class $$MessageTableTableFilterComposer
    extends Composer<_$AppDatabase, $MessageTableTable> {
  $$MessageTableTableFilterComposer({
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

  ColumnFilters<int> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get widgetJson => $composableBuilder(
    column: $table.widgetJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessageTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MessageTableTable> {
  $$MessageTableTableOrderingComposer({
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

  ColumnOrderings<int> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get widgetJson => $composableBuilder(
    column: $table.widgetJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessageTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessageTableTable> {
  $$MessageTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get widgetJson => $composableBuilder(
    column: $table.widgetJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MessageTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessageTableTable,
          MessageTableData,
          $$MessageTableTableFilterComposer,
          $$MessageTableTableOrderingComposer,
          $$MessageTableTableAnnotationComposer,
          $$MessageTableTableCreateCompanionBuilder,
          $$MessageTableTableUpdateCompanionBuilder,
          (
            MessageTableData,
            BaseReferences<_$AppDatabase, $MessageTableTable, MessageTableData>,
          ),
          MessageTableData,
          PrefetchHooks Function()
        > {
  $$MessageTableTableTableManager(_$AppDatabase db, $MessageTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> conversationId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> widgetJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MessageTableCompanion(
                id: id,
                conversationId: conversationId,
                role: role,
                content: content,
                widgetJson: widgetJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int conversationId,
                required String role,
                required String content,
                Value<String?> widgetJson = const Value.absent(),
                required DateTime createdAt,
              }) => MessageTableCompanion.insert(
                id: id,
                conversationId: conversationId,
                role: role,
                content: content,
                widgetJson: widgetJson,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessageTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessageTableTable,
      MessageTableData,
      $$MessageTableTableFilterComposer,
      $$MessageTableTableOrderingComposer,
      $$MessageTableTableAnnotationComposer,
      $$MessageTableTableCreateCompanionBuilder,
      $$MessageTableTableUpdateCompanionBuilder,
      (
        MessageTableData,
        BaseReferences<_$AppDatabase, $MessageTableTable, MessageTableData>,
      ),
      MessageTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfileTableTableTableManager get profileTable =>
      $$ProfileTableTableTableManager(_db, _db.profileTable);
  $$UserPreferencesTableTableTableManager get userPreferencesTable =>
      $$UserPreferencesTableTableTableManager(_db, _db.userPreferencesTable);
  $$TaskTableTableTableManager get taskTable =>
      $$TaskTableTableTableManager(_db, _db.taskTable);
  $$HabitTableTableTableManager get habitTable =>
      $$HabitTableTableTableManager(_db, _db.habitTable);
  $$FocusSessionTableTableTableManager get focusSessionTable =>
      $$FocusSessionTableTableTableManager(_db, _db.focusSessionTable);
  $$NoteTableTableTableManager get noteTable =>
      $$NoteTableTableTableManager(_db, _db.noteTable);
  $$MoodEntryTableTableTableManager get moodEntryTable =>
      $$MoodEntryTableTableTableManager(_db, _db.moodEntryTable);
  $$AiCommandTableTableTableManager get aiCommandTable =>
      $$AiCommandTableTableTableManager(_db, _db.aiCommandTable);
  $$BehaviorEventTableTableTableManager get behaviorEventTable =>
      $$BehaviorEventTableTableTableManager(_db, _db.behaviorEventTable);
  $$ConversationTableTableTableManager get conversationTable =>
      $$ConversationTableTableTableManager(_db, _db.conversationTable);
  $$MessageTableTableTableManager get messageTable =>
      $$MessageTableTableTableManager(_db, _db.messageTable);
}
