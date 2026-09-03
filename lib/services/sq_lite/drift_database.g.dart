// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_database.dart';

// ignore_for_file: type=lint
class $InitialSetupTable extends InitialSetup
    with TableInfo<$InitialSetupTable, InitialSetupData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InitialSetupTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  List<GeneratedColumn> get $columns => [id, key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'initial_setup';
  @override
  VerificationContext validateIntegrity(
    Insertable<InitialSetupData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InitialSetupData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InitialSetupData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
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
  $InitialSetupTable createAlias(String alias) {
    return $InitialSetupTable(attachedDatabase, alias);
  }
}

class InitialSetupData extends DataClass
    implements Insertable<InitialSetupData> {
  final int id;
  final String key;
  final String value;
  const InitialSetupData({
    required this.id,
    required this.key,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  InitialSetupCompanion toCompanion(bool nullToAbsent) {
    return InitialSetupCompanion(
      id: Value(id),
      key: Value(key),
      value: Value(value),
    );
  }

  factory InitialSetupData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InitialSetupData(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  InitialSetupData copyWith({int? id, String? key, String? value}) =>
      InitialSetupData(
        id: id ?? this.id,
        key: key ?? this.key,
        value: value ?? this.value,
      );
  InitialSetupData copyWithCompanion(InitialSetupCompanion data) {
    return InitialSetupData(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InitialSetupData(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InitialSetupData &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value);
}

class InitialSetupCompanion extends UpdateCompanion<InitialSetupData> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> value;
  const InitialSetupCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
  });
  InitialSetupCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String value,
  }) : key = Value(key),
       value = Value(value);
  static Insertable<InitialSetupData> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
    });
  }

  InitialSetupCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? value,
  }) {
    return InitialSetupCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InitialSetupCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneVerifiedMeta = const VerificationMeta(
    'phoneVerified',
  );
  @override
  late final GeneratedColumn<DateTime> phoneVerified =
      GeneratedColumn<DateTime>(
        'phone_verified',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _countryCodeMeta = const VerificationMeta(
    'countryCode',
  );
  @override
  late final GeneratedColumn<String> countryCode = GeneratedColumn<String>(
    'country_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passwordMeta = const VerificationMeta(
    'password',
  );
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
    'password',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailVerifiedMeta = const VerificationMeta(
    'emailVerified',
  );
  @override
  late final GeneratedColumn<DateTime> emailVerified =
      GeneratedColumn<DateTime>(
        'email_verified',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dobMeta = const VerificationMeta('dob');
  @override
  late final GeneratedColumn<DateTime> dob = GeneratedColumn<DateTime>(
    'dob',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageMeta = const VerificationMeta('image');
  @override
  late final GeneratedColumn<String> image = GeneratedColumn<String>(
    'image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleIdMeta = const VerificationMeta('roleId');
  @override
  late final GeneratedColumn<String> roleId = GeneratedColumn<String>(
    'role_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userTypeMeta = const VerificationMeta(
    'userType',
  );
  @override
  late final GeneratedColumn<String> userType = GeneratedColumn<String>(
    'user_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('User'),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _adline1Meta = const VerificationMeta(
    'adline1',
  );
  @override
  late final GeneratedColumn<String> adline1 = GeneratedColumn<String>(
    'adline1',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _adline2Meta = const VerificationMeta(
    'adline2',
  );
  @override
  late final GeneratedColumn<String> adline2 = GeneratedColumn<String>(
    'adline2',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pincodeMeta = const VerificationMeta(
    'pincode',
  );
  @override
  late final GeneratedColumn<String> pincode = GeneratedColumn<String>(
    'pincode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userNameMeta = const VerificationMeta(
    'userName',
  );
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
    'user_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverPicMeta = const VerificationMeta(
    'coverPic',
  );
  @override
  late final GeneratedColumn<String> coverPic = GeneratedColumn<String>(
    'cover_pic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bioMeta = const VerificationMeta('bio');
  @override
  late final GeneratedColumn<String> bio = GeneratedColumn<String>(
    'bio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _familyIDMeta = const VerificationMeta(
    'familyID',
  );
  @override
  late final GeneratedColumn<String> familyID = GeneratedColumn<String>(
    'family_i_d',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _healthDataIDMeta = const VerificationMeta(
    'healthDataID',
  );
  @override
  late final GeneratedColumn<String> healthDataID = GeneratedColumn<String>(
    'HealthDataID',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allowearMacAddressMeta =
      const VerificationMeta('allowearMacAddress');
  @override
  late final GeneratedColumn<String> allowearMacAddress =
      GeneratedColumn<String>(
        'allowear_mac_address',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastActiveAtMeta = const VerificationMeta(
    'lastActiveAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastActiveAt = GeneratedColumn<DateTime>(
    'last_active_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    email,
    phone,
    phoneVerified,
    countryCode,
    password,
    emailVerified,
    gender,
    dob,
    image,
    roleId,
    userType,
    createdAt,
    updatedAt,
    adline1,
    adline2,
    city,
    pincode,
    active,
    lat,
    lng,
    entity,
    userName,
    coverPic,
    bio,
    familyID,
    isDeleted,
    healthDataID,
    allowearMacAddress,
    lastActiveAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
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
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('phone_verified')) {
      context.handle(
        _phoneVerifiedMeta,
        phoneVerified.isAcceptableOrUnknown(
          data['phone_verified']!,
          _phoneVerifiedMeta,
        ),
      );
    }
    if (data.containsKey('country_code')) {
      context.handle(
        _countryCodeMeta,
        countryCode.isAcceptableOrUnknown(
          data['country_code']!,
          _countryCodeMeta,
        ),
      );
    }
    if (data.containsKey('password')) {
      context.handle(
        _passwordMeta,
        password.isAcceptableOrUnknown(data['password']!, _passwordMeta),
      );
    }
    if (data.containsKey('email_verified')) {
      context.handle(
        _emailVerifiedMeta,
        emailVerified.isAcceptableOrUnknown(
          data['email_verified']!,
          _emailVerifiedMeta,
        ),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('dob')) {
      context.handle(
        _dobMeta,
        dob.isAcceptableOrUnknown(data['dob']!, _dobMeta),
      );
    }
    if (data.containsKey('image')) {
      context.handle(
        _imageMeta,
        image.isAcceptableOrUnknown(data['image']!, _imageMeta),
      );
    }
    if (data.containsKey('role_id')) {
      context.handle(
        _roleIdMeta,
        roleId.isAcceptableOrUnknown(data['role_id']!, _roleIdMeta),
      );
    }
    if (data.containsKey('user_type')) {
      context.handle(
        _userTypeMeta,
        userType.isAcceptableOrUnknown(data['user_type']!, _userTypeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('adline1')) {
      context.handle(
        _adline1Meta,
        adline1.isAcceptableOrUnknown(data['adline1']!, _adline1Meta),
      );
    }
    if (data.containsKey('adline2')) {
      context.handle(
        _adline2Meta,
        adline2.isAcceptableOrUnknown(data['adline2']!, _adline2Meta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('pincode')) {
      context.handle(
        _pincodeMeta,
        pincode.isAcceptableOrUnknown(data['pincode']!, _pincodeMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    }
    if (data.containsKey('user_name')) {
      context.handle(
        _userNameMeta,
        userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta),
      );
    }
    if (data.containsKey('cover_pic')) {
      context.handle(
        _coverPicMeta,
        coverPic.isAcceptableOrUnknown(data['cover_pic']!, _coverPicMeta),
      );
    }
    if (data.containsKey('bio')) {
      context.handle(
        _bioMeta,
        bio.isAcceptableOrUnknown(data['bio']!, _bioMeta),
      );
    }
    if (data.containsKey('family_i_d')) {
      context.handle(
        _familyIDMeta,
        familyID.isAcceptableOrUnknown(data['family_i_d']!, _familyIDMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('HealthDataID')) {
      context.handle(
        _healthDataIDMeta,
        healthDataID.isAcceptableOrUnknown(
          data['HealthDataID']!,
          _healthDataIDMeta,
        ),
      );
    }
    if (data.containsKey('allowear_mac_address')) {
      context.handle(
        _allowearMacAddressMeta,
        allowearMacAddress.isAcceptableOrUnknown(
          data['allowear_mac_address']!,
          _allowearMacAddressMeta,
        ),
      );
    }
    if (data.containsKey('last_active_at')) {
      context.handle(
        _lastActiveAtMeta,
        lastActiveAt.isAcceptableOrUnknown(
          data['last_active_at']!,
          _lastActiveAtMeta,
        ),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      phoneVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}phone_verified'],
      ),
      countryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_code'],
      ),
      password: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password'],
      ),
      emailVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}email_verified'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      ),
      dob: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dob'],
      ),
      image: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image'],
      ),
      roleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_id'],
      ),
      userType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      adline1: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adline1'],
      ),
      adline2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adline2'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      pincode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pincode'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      ),
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      ),
      userName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_name'],
      ),
      coverPic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_pic'],
      ),
      bio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bio'],
      ),
      familyID: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family_i_d'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      healthDataID: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}HealthDataID'],
      ),
      allowearMacAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allowear_mac_address'],
      ),
      lastActiveAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_active_at'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final DateTime? phoneVerified;
  final String? countryCode;
  final String? password;
  final DateTime? emailVerified;
  final String? gender;
  final DateTime? dob;
  final String? image;
  final String? roleId;
  final String userType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? adline1;
  final String? adline2;
  final String? city;
  final String? pincode;
  final bool active;
  final double? lat;
  final double? lng;
  final String? entity;
  final String? userName;
  final String? coverPic;
  final String? bio;
  final String? familyID;
  final bool isDeleted;
  final String? healthDataID;
  final String? allowearMacAddress;
  final DateTime? lastActiveAt;
  final int synced;
  const User({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.phoneVerified,
    this.countryCode,
    this.password,
    this.emailVerified,
    this.gender,
    this.dob,
    this.image,
    this.roleId,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
    this.adline1,
    this.adline2,
    this.city,
    this.pincode,
    required this.active,
    this.lat,
    this.lng,
    this.entity,
    this.userName,
    this.coverPic,
    this.bio,
    this.familyID,
    required this.isDeleted,
    this.healthDataID,
    this.allowearMacAddress,
    this.lastActiveAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || phoneVerified != null) {
      map['phone_verified'] = Variable<DateTime>(phoneVerified);
    }
    if (!nullToAbsent || countryCode != null) {
      map['country_code'] = Variable<String>(countryCode);
    }
    if (!nullToAbsent || password != null) {
      map['password'] = Variable<String>(password);
    }
    if (!nullToAbsent || emailVerified != null) {
      map['email_verified'] = Variable<DateTime>(emailVerified);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || dob != null) {
      map['dob'] = Variable<DateTime>(dob);
    }
    if (!nullToAbsent || image != null) {
      map['image'] = Variable<String>(image);
    }
    if (!nullToAbsent || roleId != null) {
      map['role_id'] = Variable<String>(roleId);
    }
    map['user_type'] = Variable<String>(userType);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || adline1 != null) {
      map['adline1'] = Variable<String>(adline1);
    }
    if (!nullToAbsent || adline2 != null) {
      map['adline2'] = Variable<String>(adline2);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || pincode != null) {
      map['pincode'] = Variable<String>(pincode);
    }
    map['active'] = Variable<bool>(active);
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    if (!nullToAbsent || entity != null) {
      map['entity'] = Variable<String>(entity);
    }
    if (!nullToAbsent || userName != null) {
      map['user_name'] = Variable<String>(userName);
    }
    if (!nullToAbsent || coverPic != null) {
      map['cover_pic'] = Variable<String>(coverPic);
    }
    if (!nullToAbsent || bio != null) {
      map['bio'] = Variable<String>(bio);
    }
    if (!nullToAbsent || familyID != null) {
      map['family_i_d'] = Variable<String>(familyID);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || healthDataID != null) {
      map['HealthDataID'] = Variable<String>(healthDataID);
    }
    if (!nullToAbsent || allowearMacAddress != null) {
      map['allowear_mac_address'] = Variable<String>(allowearMacAddress);
    }
    if (!nullToAbsent || lastActiveAt != null) {
      map['last_active_at'] = Variable<DateTime>(lastActiveAt);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      phoneVerified: phoneVerified == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneVerified),
      countryCode: countryCode == null && nullToAbsent
          ? const Value.absent()
          : Value(countryCode),
      password: password == null && nullToAbsent
          ? const Value.absent()
          : Value(password),
      emailVerified: emailVerified == null && nullToAbsent
          ? const Value.absent()
          : Value(emailVerified),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
      dob: dob == null && nullToAbsent ? const Value.absent() : Value(dob),
      image: image == null && nullToAbsent
          ? const Value.absent()
          : Value(image),
      roleId: roleId == null && nullToAbsent
          ? const Value.absent()
          : Value(roleId),
      userType: Value(userType),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      adline1: adline1 == null && nullToAbsent
          ? const Value.absent()
          : Value(adline1),
      adline2: adline2 == null && nullToAbsent
          ? const Value.absent()
          : Value(adline2),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      pincode: pincode == null && nullToAbsent
          ? const Value.absent()
          : Value(pincode),
      active: Value(active),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      entity: entity == null && nullToAbsent
          ? const Value.absent()
          : Value(entity),
      userName: userName == null && nullToAbsent
          ? const Value.absent()
          : Value(userName),
      coverPic: coverPic == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPic),
      bio: bio == null && nullToAbsent ? const Value.absent() : Value(bio),
      familyID: familyID == null && nullToAbsent
          ? const Value.absent()
          : Value(familyID),
      isDeleted: Value(isDeleted),
      healthDataID: healthDataID == null && nullToAbsent
          ? const Value.absent()
          : Value(healthDataID),
      allowearMacAddress: allowearMacAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(allowearMacAddress),
      lastActiveAt: lastActiveAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActiveAt),
      synced: Value(synced),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      email: serializer.fromJson<String?>(json['email']),
      phone: serializer.fromJson<String?>(json['phone']),
      phoneVerified: serializer.fromJson<DateTime?>(json['phoneVerified']),
      countryCode: serializer.fromJson<String?>(json['countryCode']),
      password: serializer.fromJson<String?>(json['password']),
      emailVerified: serializer.fromJson<DateTime?>(json['emailVerified']),
      gender: serializer.fromJson<String?>(json['gender']),
      dob: serializer.fromJson<DateTime?>(json['dob']),
      image: serializer.fromJson<String?>(json['image']),
      roleId: serializer.fromJson<String?>(json['roleId']),
      userType: serializer.fromJson<String>(json['userType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      adline1: serializer.fromJson<String?>(json['adline1']),
      adline2: serializer.fromJson<String?>(json['adline2']),
      city: serializer.fromJson<String?>(json['city']),
      pincode: serializer.fromJson<String?>(json['pincode']),
      active: serializer.fromJson<bool>(json['active']),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      entity: serializer.fromJson<String?>(json['entity']),
      userName: serializer.fromJson<String?>(json['userName']),
      coverPic: serializer.fromJson<String?>(json['coverPic']),
      bio: serializer.fromJson<String?>(json['bio']),
      familyID: serializer.fromJson<String?>(json['familyID']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      healthDataID: serializer.fromJson<String?>(json['healthDataID']),
      allowearMacAddress: serializer.fromJson<String?>(
        json['allowearMacAddress'],
      ),
      lastActiveAt: serializer.fromJson<DateTime?>(json['lastActiveAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'email': serializer.toJson<String?>(email),
      'phone': serializer.toJson<String?>(phone),
      'phoneVerified': serializer.toJson<DateTime?>(phoneVerified),
      'countryCode': serializer.toJson<String?>(countryCode),
      'password': serializer.toJson<String?>(password),
      'emailVerified': serializer.toJson<DateTime?>(emailVerified),
      'gender': serializer.toJson<String?>(gender),
      'dob': serializer.toJson<DateTime?>(dob),
      'image': serializer.toJson<String?>(image),
      'roleId': serializer.toJson<String?>(roleId),
      'userType': serializer.toJson<String>(userType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'adline1': serializer.toJson<String?>(adline1),
      'adline2': serializer.toJson<String?>(adline2),
      'city': serializer.toJson<String?>(city),
      'pincode': serializer.toJson<String?>(pincode),
      'active': serializer.toJson<bool>(active),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'entity': serializer.toJson<String?>(entity),
      'userName': serializer.toJson<String?>(userName),
      'coverPic': serializer.toJson<String?>(coverPic),
      'bio': serializer.toJson<String?>(bio),
      'familyID': serializer.toJson<String?>(familyID),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'healthDataID': serializer.toJson<String?>(healthDataID),
      'allowearMacAddress': serializer.toJson<String?>(allowearMacAddress),
      'lastActiveAt': serializer.toJson<DateTime?>(lastActiveAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  User copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<DateTime?> phoneVerified = const Value.absent(),
    Value<String?> countryCode = const Value.absent(),
    Value<String?> password = const Value.absent(),
    Value<DateTime?> emailVerified = const Value.absent(),
    Value<String?> gender = const Value.absent(),
    Value<DateTime?> dob = const Value.absent(),
    Value<String?> image = const Value.absent(),
    Value<String?> roleId = const Value.absent(),
    String? userType,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> adline1 = const Value.absent(),
    Value<String?> adline2 = const Value.absent(),
    Value<String?> city = const Value.absent(),
    Value<String?> pincode = const Value.absent(),
    bool? active,
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    Value<String?> entity = const Value.absent(),
    Value<String?> userName = const Value.absent(),
    Value<String?> coverPic = const Value.absent(),
    Value<String?> bio = const Value.absent(),
    Value<String?> familyID = const Value.absent(),
    bool? isDeleted,
    Value<String?> healthDataID = const Value.absent(),
    Value<String?> allowearMacAddress = const Value.absent(),
    Value<DateTime?> lastActiveAt = const Value.absent(),
    int? synced,
  }) => User(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    email: email.present ? email.value : this.email,
    phone: phone.present ? phone.value : this.phone,
    phoneVerified: phoneVerified.present
        ? phoneVerified.value
        : this.phoneVerified,
    countryCode: countryCode.present ? countryCode.value : this.countryCode,
    password: password.present ? password.value : this.password,
    emailVerified: emailVerified.present
        ? emailVerified.value
        : this.emailVerified,
    gender: gender.present ? gender.value : this.gender,
    dob: dob.present ? dob.value : this.dob,
    image: image.present ? image.value : this.image,
    roleId: roleId.present ? roleId.value : this.roleId,
    userType: userType ?? this.userType,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    adline1: adline1.present ? adline1.value : this.adline1,
    adline2: adline2.present ? adline2.value : this.adline2,
    city: city.present ? city.value : this.city,
    pincode: pincode.present ? pincode.value : this.pincode,
    active: active ?? this.active,
    lat: lat.present ? lat.value : this.lat,
    lng: lng.present ? lng.value : this.lng,
    entity: entity.present ? entity.value : this.entity,
    userName: userName.present ? userName.value : this.userName,
    coverPic: coverPic.present ? coverPic.value : this.coverPic,
    bio: bio.present ? bio.value : this.bio,
    familyID: familyID.present ? familyID.value : this.familyID,
    isDeleted: isDeleted ?? this.isDeleted,
    healthDataID: healthDataID.present ? healthDataID.value : this.healthDataID,
    allowearMacAddress: allowearMacAddress.present
        ? allowearMacAddress.value
        : this.allowearMacAddress,
    lastActiveAt: lastActiveAt.present ? lastActiveAt.value : this.lastActiveAt,
    synced: synced ?? this.synced,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      phoneVerified: data.phoneVerified.present
          ? data.phoneVerified.value
          : this.phoneVerified,
      countryCode: data.countryCode.present
          ? data.countryCode.value
          : this.countryCode,
      password: data.password.present ? data.password.value : this.password,
      emailVerified: data.emailVerified.present
          ? data.emailVerified.value
          : this.emailVerified,
      gender: data.gender.present ? data.gender.value : this.gender,
      dob: data.dob.present ? data.dob.value : this.dob,
      image: data.image.present ? data.image.value : this.image,
      roleId: data.roleId.present ? data.roleId.value : this.roleId,
      userType: data.userType.present ? data.userType.value : this.userType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      adline1: data.adline1.present ? data.adline1.value : this.adline1,
      adline2: data.adline2.present ? data.adline2.value : this.adline2,
      city: data.city.present ? data.city.value : this.city,
      pincode: data.pincode.present ? data.pincode.value : this.pincode,
      active: data.active.present ? data.active.value : this.active,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      entity: data.entity.present ? data.entity.value : this.entity,
      userName: data.userName.present ? data.userName.value : this.userName,
      coverPic: data.coverPic.present ? data.coverPic.value : this.coverPic,
      bio: data.bio.present ? data.bio.value : this.bio,
      familyID: data.familyID.present ? data.familyID.value : this.familyID,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      healthDataID: data.healthDataID.present
          ? data.healthDataID.value
          : this.healthDataID,
      allowearMacAddress: data.allowearMacAddress.present
          ? data.allowearMacAddress.value
          : this.allowearMacAddress,
      lastActiveAt: data.lastActiveAt.present
          ? data.lastActiveAt.value
          : this.lastActiveAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('phoneVerified: $phoneVerified, ')
          ..write('countryCode: $countryCode, ')
          ..write('password: $password, ')
          ..write('emailVerified: $emailVerified, ')
          ..write('gender: $gender, ')
          ..write('dob: $dob, ')
          ..write('image: $image, ')
          ..write('roleId: $roleId, ')
          ..write('userType: $userType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('adline1: $adline1, ')
          ..write('adline2: $adline2, ')
          ..write('city: $city, ')
          ..write('pincode: $pincode, ')
          ..write('active: $active, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('entity: $entity, ')
          ..write('userName: $userName, ')
          ..write('coverPic: $coverPic, ')
          ..write('bio: $bio, ')
          ..write('familyID: $familyID, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('healthDataID: $healthDataID, ')
          ..write('allowearMacAddress: $allowearMacAddress, ')
          ..write('lastActiveAt: $lastActiveAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    email,
    phone,
    phoneVerified,
    countryCode,
    password,
    emailVerified,
    gender,
    dob,
    image,
    roleId,
    userType,
    createdAt,
    updatedAt,
    adline1,
    adline2,
    city,
    pincode,
    active,
    lat,
    lng,
    entity,
    userName,
    coverPic,
    bio,
    familyID,
    isDeleted,
    healthDataID,
    allowearMacAddress,
    lastActiveAt,
    synced,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.phoneVerified == this.phoneVerified &&
          other.countryCode == this.countryCode &&
          other.password == this.password &&
          other.emailVerified == this.emailVerified &&
          other.gender == this.gender &&
          other.dob == this.dob &&
          other.image == this.image &&
          other.roleId == this.roleId &&
          other.userType == this.userType &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.adline1 == this.adline1 &&
          other.adline2 == this.adline2 &&
          other.city == this.city &&
          other.pincode == this.pincode &&
          other.active == this.active &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.entity == this.entity &&
          other.userName == this.userName &&
          other.coverPic == this.coverPic &&
          other.bio == this.bio &&
          other.familyID == this.familyID &&
          other.isDeleted == this.isDeleted &&
          other.healthDataID == this.healthDataID &&
          other.allowearMacAddress == this.allowearMacAddress &&
          other.lastActiveAt == this.lastActiveAt &&
          other.synced == this.synced);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> email;
  final Value<String?> phone;
  final Value<DateTime?> phoneVerified;
  final Value<String?> countryCode;
  final Value<String?> password;
  final Value<DateTime?> emailVerified;
  final Value<String?> gender;
  final Value<DateTime?> dob;
  final Value<String?> image;
  final Value<String?> roleId;
  final Value<String> userType;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> adline1;
  final Value<String?> adline2;
  final Value<String?> city;
  final Value<String?> pincode;
  final Value<bool> active;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<String?> entity;
  final Value<String?> userName;
  final Value<String?> coverPic;
  final Value<String?> bio;
  final Value<String?> familyID;
  final Value<bool> isDeleted;
  final Value<String?> healthDataID;
  final Value<String?> allowearMacAddress;
  final Value<DateTime?> lastActiveAt;
  final Value<int> synced;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.phoneVerified = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.password = const Value.absent(),
    this.emailVerified = const Value.absent(),
    this.gender = const Value.absent(),
    this.dob = const Value.absent(),
    this.image = const Value.absent(),
    this.roleId = const Value.absent(),
    this.userType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.adline1 = const Value.absent(),
    this.adline2 = const Value.absent(),
    this.city = const Value.absent(),
    this.pincode = const Value.absent(),
    this.active = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.entity = const Value.absent(),
    this.userName = const Value.absent(),
    this.coverPic = const Value.absent(),
    this.bio = const Value.absent(),
    this.familyID = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.healthDataID = const Value.absent(),
    this.allowearMacAddress = const Value.absent(),
    this.lastActiveAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.phoneVerified = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.password = const Value.absent(),
    this.emailVerified = const Value.absent(),
    this.gender = const Value.absent(),
    this.dob = const Value.absent(),
    this.image = const Value.absent(),
    this.roleId = const Value.absent(),
    this.userType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.adline1 = const Value.absent(),
    this.adline2 = const Value.absent(),
    this.city = const Value.absent(),
    this.pincode = const Value.absent(),
    this.active = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.entity = const Value.absent(),
    this.userName = const Value.absent(),
    this.coverPic = const Value.absent(),
    this.bio = const Value.absent(),
    this.familyID = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.healthDataID = const Value.absent(),
    this.allowearMacAddress = const Value.absent(),
    this.lastActiveAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<DateTime>? phoneVerified,
    Expression<String>? countryCode,
    Expression<String>? password,
    Expression<DateTime>? emailVerified,
    Expression<String>? gender,
    Expression<DateTime>? dob,
    Expression<String>? image,
    Expression<String>? roleId,
    Expression<String>? userType,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? adline1,
    Expression<String>? adline2,
    Expression<String>? city,
    Expression<String>? pincode,
    Expression<bool>? active,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? entity,
    Expression<String>? userName,
    Expression<String>? coverPic,
    Expression<String>? bio,
    Expression<String>? familyID,
    Expression<bool>? isDeleted,
    Expression<String>? healthDataID,
    Expression<String>? allowearMacAddress,
    Expression<DateTime>? lastActiveAt,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (phoneVerified != null) 'phone_verified': phoneVerified,
      if (countryCode != null) 'country_code': countryCode,
      if (password != null) 'password': password,
      if (emailVerified != null) 'email_verified': emailVerified,
      if (gender != null) 'gender': gender,
      if (dob != null) 'dob': dob,
      if (image != null) 'image': image,
      if (roleId != null) 'role_id': roleId,
      if (userType != null) 'user_type': userType,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (adline1 != null) 'adline1': adline1,
      if (adline2 != null) 'adline2': adline2,
      if (city != null) 'city': city,
      if (pincode != null) 'pincode': pincode,
      if (active != null) 'active': active,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (entity != null) 'entity': entity,
      if (userName != null) 'user_name': userName,
      if (coverPic != null) 'cover_pic': coverPic,
      if (bio != null) 'bio': bio,
      if (familyID != null) 'family_i_d': familyID,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (healthDataID != null) 'HealthDataID': healthDataID,
      if (allowearMacAddress != null)
        'allowear_mac_address': allowearMacAddress,
      if (lastActiveAt != null) 'last_active_at': lastActiveAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String?>? email,
    Value<String?>? phone,
    Value<DateTime?>? phoneVerified,
    Value<String?>? countryCode,
    Value<String?>? password,
    Value<DateTime?>? emailVerified,
    Value<String?>? gender,
    Value<DateTime?>? dob,
    Value<String?>? image,
    Value<String?>? roleId,
    Value<String>? userType,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? adline1,
    Value<String?>? adline2,
    Value<String?>? city,
    Value<String?>? pincode,
    Value<bool>? active,
    Value<double?>? lat,
    Value<double?>? lng,
    Value<String?>? entity,
    Value<String?>? userName,
    Value<String?>? coverPic,
    Value<String?>? bio,
    Value<String?>? familyID,
    Value<bool>? isDeleted,
    Value<String?>? healthDataID,
    Value<String?>? allowearMacAddress,
    Value<DateTime?>? lastActiveAt,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      countryCode: countryCode ?? this.countryCode,
      password: password ?? this.password,
      emailVerified: emailVerified ?? this.emailVerified,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      image: image ?? this.image,
      roleId: roleId ?? this.roleId,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adline1: adline1 ?? this.adline1,
      adline2: adline2 ?? this.adline2,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      active: active ?? this.active,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      entity: entity ?? this.entity,
      userName: userName ?? this.userName,
      coverPic: coverPic ?? this.coverPic,
      bio: bio ?? this.bio,
      familyID: familyID ?? this.familyID,
      isDeleted: isDeleted ?? this.isDeleted,
      healthDataID: healthDataID ?? this.healthDataID,
      allowearMacAddress: allowearMacAddress ?? this.allowearMacAddress,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      synced: synced ?? this.synced,
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
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (phoneVerified.present) {
      map['phone_verified'] = Variable<DateTime>(phoneVerified.value);
    }
    if (countryCode.present) {
      map['country_code'] = Variable<String>(countryCode.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (emailVerified.present) {
      map['email_verified'] = Variable<DateTime>(emailVerified.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (dob.present) {
      map['dob'] = Variable<DateTime>(dob.value);
    }
    if (image.present) {
      map['image'] = Variable<String>(image.value);
    }
    if (roleId.present) {
      map['role_id'] = Variable<String>(roleId.value);
    }
    if (userType.present) {
      map['user_type'] = Variable<String>(userType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (adline1.present) {
      map['adline1'] = Variable<String>(adline1.value);
    }
    if (adline2.present) {
      map['adline2'] = Variable<String>(adline2.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (pincode.present) {
      map['pincode'] = Variable<String>(pincode.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (coverPic.present) {
      map['cover_pic'] = Variable<String>(coverPic.value);
    }
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (familyID.present) {
      map['family_i_d'] = Variable<String>(familyID.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (healthDataID.present) {
      map['HealthDataID'] = Variable<String>(healthDataID.value);
    }
    if (allowearMacAddress.present) {
      map['allowear_mac_address'] = Variable<String>(allowearMacAddress.value);
    }
    if (lastActiveAt.present) {
      map['last_active_at'] = Variable<DateTime>(lastActiveAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('phoneVerified: $phoneVerified, ')
          ..write('countryCode: $countryCode, ')
          ..write('password: $password, ')
          ..write('emailVerified: $emailVerified, ')
          ..write('gender: $gender, ')
          ..write('dob: $dob, ')
          ..write('image: $image, ')
          ..write('roleId: $roleId, ')
          ..write('userType: $userType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('adline1: $adline1, ')
          ..write('adline2: $adline2, ')
          ..write('city: $city, ')
          ..write('pincode: $pincode, ')
          ..write('active: $active, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('entity: $entity, ')
          ..write('userName: $userName, ')
          ..write('coverPic: $coverPic, ')
          ..write('bio: $bio, ')
          ..write('familyID: $familyID, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('healthDataID: $healthDataID, ')
          ..write('allowearMacAddress: $allowearMacAddress, ')
          ..write('lastActiveAt: $lastActiveAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserEntitiesTable extends UserEntities
    with TableInfo<$UserEntitiesTable, UserEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserEntitiesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _leftAtMeta = const VerificationMeta('leftAt');
  @override
  late final GeneratedColumn<DateTime> leftAt = GeneratedColumn<DateTime>(
    'left_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    entityId,
    type,
    leftAt,
    createdAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_entities';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserEntity> instance, {
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
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('left_at')) {
      context.handle(
        _leftAtMeta,
        leftAt.isAcceptableOrUnknown(data['left_at']!, _leftAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      leftAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}left_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $UserEntitiesTable createAlias(String alias) {
    return $UserEntitiesTable(attachedDatabase, alias);
  }
}

class UserEntity extends DataClass implements Insertable<UserEntity> {
  final int id;
  final String userId;
  final String entityId;
  final String type;
  final DateTime? leftAt;
  final DateTime createdAt;
  final int synced;
  const UserEntity({
    required this.id,
    required this.userId,
    required this.entityId,
    required this.type,
    this.leftAt,
    required this.createdAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['entity_id'] = Variable<String>(entityId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || leftAt != null) {
      map['left_at'] = Variable<DateTime>(leftAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  UserEntitiesCompanion toCompanion(bool nullToAbsent) {
    return UserEntitiesCompanion(
      id: Value(id),
      userId: Value(userId),
      entityId: Value(entityId),
      type: Value(type),
      leftAt: leftAt == null && nullToAbsent
          ? const Value.absent()
          : Value(leftAt),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory UserEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserEntity(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      entityId: serializer.fromJson<String>(json['entityId']),
      type: serializer.fromJson<String>(json['type']),
      leftAt: serializer.fromJson<DateTime?>(json['leftAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'entityId': serializer.toJson<String>(entityId),
      'type': serializer.toJson<String>(type),
      'leftAt': serializer.toJson<DateTime?>(leftAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  UserEntity copyWith({
    int? id,
    String? userId,
    String? entityId,
    String? type,
    Value<DateTime?> leftAt = const Value.absent(),
    DateTime? createdAt,
    int? synced,
  }) => UserEntity(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    entityId: entityId ?? this.entityId,
    type: type ?? this.type,
    leftAt: leftAt.present ? leftAt.value : this.leftAt,
    createdAt: createdAt ?? this.createdAt,
    synced: synced ?? this.synced,
  );
  UserEntity copyWithCompanion(UserEntitiesCompanion data) {
    return UserEntity(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      type: data.type.present ? data.type.value : this.type,
      leftAt: data.leftAt.present ? data.leftAt.value : this.leftAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserEntity(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('entityId: $entityId, ')
          ..write('type: $type, ')
          ..write('leftAt: $leftAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, entityId, type, leftAt, createdAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserEntity &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.entityId == this.entityId &&
          other.type == this.type &&
          other.leftAt == this.leftAt &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class UserEntitiesCompanion extends UpdateCompanion<UserEntity> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> entityId;
  final Value<String> type;
  final Value<DateTime?> leftAt;
  final Value<DateTime> createdAt;
  final Value<int> synced;
  const UserEntitiesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.entityId = const Value.absent(),
    this.type = const Value.absent(),
    this.leftAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  UserEntitiesCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String entityId,
    required String type,
    this.leftAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  }) : userId = Value(userId),
       entityId = Value(entityId),
       type = Value(type);
  static Insertable<UserEntity> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? entityId,
    Expression<String>? type,
    Expression<DateTime>? leftAt,
    Expression<DateTime>? createdAt,
    Expression<int>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (entityId != null) 'entity_id': entityId,
      if (type != null) 'type': type,
      if (leftAt != null) 'left_at': leftAt,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
    });
  }

  UserEntitiesCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? entityId,
    Value<String>? type,
    Value<DateTime?>? leftAt,
    Value<DateTime>? createdAt,
    Value<int>? synced,
  }) {
    return UserEntitiesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entityId: entityId ?? this.entityId,
      type: type ?? this.type,
      leftAt: leftAt ?? this.leftAt,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
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
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (leftAt.present) {
      map['left_at'] = Variable<DateTime>(leftAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserEntitiesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('entityId: $entityId, ')
          ..write('type: $type, ')
          ..write('leftAt: $leftAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $UserRelationsTable extends UserRelations
    with TableInfo<$UserRelationsTable, UserRelation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserRelationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _relatedUserIdMeta = const VerificationMeta(
    'relatedUserId',
  );
  @override
  late final GeneratedColumn<String> relatedUserId = GeneratedColumn<String>(
    'related_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relationTypeMeta = const VerificationMeta(
    'relationType',
  );
  @override
  late final GeneratedColumn<String> relationType = GeneratedColumn<String>(
    'relation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    relatedUserId,
    relationType,
    createdAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_relations';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserRelation> instance, {
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
    if (data.containsKey('related_user_id')) {
      context.handle(
        _relatedUserIdMeta,
        relatedUserId.isAcceptableOrUnknown(
          data['related_user_id']!,
          _relatedUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relatedUserIdMeta);
    }
    if (data.containsKey('relation_type')) {
      context.handle(
        _relationTypeMeta,
        relationType.isAcceptableOrUnknown(
          data['relation_type']!,
          _relationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relationTypeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserRelation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRelation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      relatedUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_user_id'],
      )!,
      relationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relation_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $UserRelationsTable createAlias(String alias) {
    return $UserRelationsTable(attachedDatabase, alias);
  }
}

class UserRelation extends DataClass implements Insertable<UserRelation> {
  final int id;
  final String userId;
  final String relatedUserId;
  final String relationType;
  final DateTime createdAt;
  final int synced;
  const UserRelation({
    required this.id,
    required this.userId,
    required this.relatedUserId,
    required this.relationType,
    required this.createdAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['related_user_id'] = Variable<String>(relatedUserId);
    map['relation_type'] = Variable<String>(relationType);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  UserRelationsCompanion toCompanion(bool nullToAbsent) {
    return UserRelationsCompanion(
      id: Value(id),
      userId: Value(userId),
      relatedUserId: Value(relatedUserId),
      relationType: Value(relationType),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory UserRelation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRelation(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      relatedUserId: serializer.fromJson<String>(json['relatedUserId']),
      relationType: serializer.fromJson<String>(json['relationType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'relatedUserId': serializer.toJson<String>(relatedUserId),
      'relationType': serializer.toJson<String>(relationType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  UserRelation copyWith({
    int? id,
    String? userId,
    String? relatedUserId,
    String? relationType,
    DateTime? createdAt,
    int? synced,
  }) => UserRelation(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    relatedUserId: relatedUserId ?? this.relatedUserId,
    relationType: relationType ?? this.relationType,
    createdAt: createdAt ?? this.createdAt,
    synced: synced ?? this.synced,
  );
  UserRelation copyWithCompanion(UserRelationsCompanion data) {
    return UserRelation(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      relatedUserId: data.relatedUserId.present
          ? data.relatedUserId.value
          : this.relatedUserId,
      relationType: data.relationType.present
          ? data.relationType.value
          : this.relationType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRelation(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('relatedUserId: $relatedUserId, ')
          ..write('relationType: $relationType, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, relatedUserId, relationType, createdAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRelation &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.relatedUserId == this.relatedUserId &&
          other.relationType == this.relationType &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class UserRelationsCompanion extends UpdateCompanion<UserRelation> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> relatedUserId;
  final Value<String> relationType;
  final Value<DateTime> createdAt;
  final Value<int> synced;
  const UserRelationsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.relatedUserId = const Value.absent(),
    this.relationType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  UserRelationsCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String relatedUserId,
    required String relationType,
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  }) : userId = Value(userId),
       relatedUserId = Value(relatedUserId),
       relationType = Value(relationType);
  static Insertable<UserRelation> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? relatedUserId,
    Expression<String>? relationType,
    Expression<DateTime>? createdAt,
    Expression<int>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (relatedUserId != null) 'related_user_id': relatedUserId,
      if (relationType != null) 'relation_type': relationType,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
    });
  }

  UserRelationsCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? relatedUserId,
    Value<String>? relationType,
    Value<DateTime>? createdAt,
    Value<int>? synced,
  }) {
    return UserRelationsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      relationType: relationType ?? this.relationType,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
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
    if (relatedUserId.present) {
      map['related_user_id'] = Variable<String>(relatedUserId.value);
    }
    if (relationType.present) {
      map['relation_type'] = Variable<String>(relationType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserRelationsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('relatedUserId: $relatedUserId, ')
          ..write('relationType: $relationType, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $FamiliesTable extends Families with TableInfo<$FamiliesTable, Family> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamiliesTable(this.attachedDatabase, [this._alias]);
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _motherIdMeta = const VerificationMeta(
    'motherId',
  );
  @override
  late final GeneratedColumn<String> motherId = GeneratedColumn<String>(
    'mother_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatherIdMeta = const VerificationMeta(
    'fatherId',
  );
  @override
  late final GeneratedColumn<String> fatherId = GeneratedColumn<String>(
    'father_id',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profileImageMeta = const VerificationMeta(
    'profileImage',
  );
  @override
  late final GeneratedColumn<String> profileImage = GeneratedColumn<String>(
    'profile_image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bannerImageMeta = const VerificationMeta(
    'bannerImage',
  );
  @override
  late final GeneratedColumn<String> bannerImage = GeneratedColumn<String>(
    'banner_image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    code,
    motherId,
    fatherId,
    createdAt,
    createdBy,
    profileImage,
    bannerImage,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'families';
  @override
  VerificationContext validateIntegrity(
    Insertable<Family> instance, {
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
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('mother_id')) {
      context.handle(
        _motherIdMeta,
        motherId.isAcceptableOrUnknown(data['mother_id']!, _motherIdMeta),
      );
    }
    if (data.containsKey('father_id')) {
      context.handle(
        _fatherIdMeta,
        fatherId.isAcceptableOrUnknown(data['father_id']!, _fatherIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('profile_image')) {
      context.handle(
        _profileImageMeta,
        profileImage.isAcceptableOrUnknown(
          data['profile_image']!,
          _profileImageMeta,
        ),
      );
    }
    if (data.containsKey('banner_image')) {
      context.handle(
        _bannerImageMeta,
        bannerImage.isAcceptableOrUnknown(
          data['banner_image']!,
          _bannerImageMeta,
        ),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Family map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Family(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      ),
      motherId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mother_id'],
      ),
      fatherId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}father_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      profileImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_image'],
      ),
      bannerImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}banner_image'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $FamiliesTable createAlias(String alias) {
    return $FamiliesTable(attachedDatabase, alias);
  }
}

class Family extends DataClass implements Insertable<Family> {
  final String id;
  final String? name;
  final String? code;
  final String? motherId;
  final String? fatherId;
  final DateTime createdAt;
  final String? createdBy;
  final String? profileImage;
  final String? bannerImage;
  final int synced;
  const Family({
    required this.id,
    this.name,
    this.code,
    this.motherId,
    this.fatherId,
    required this.createdAt,
    this.createdBy,
    this.profileImage,
    this.bannerImage,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    if (!nullToAbsent || motherId != null) {
      map['mother_id'] = Variable<String>(motherId);
    }
    if (!nullToAbsent || fatherId != null) {
      map['father_id'] = Variable<String>(fatherId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || profileImage != null) {
      map['profile_image'] = Variable<String>(profileImage);
    }
    if (!nullToAbsent || bannerImage != null) {
      map['banner_image'] = Variable<String>(bannerImage);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  FamiliesCompanion toCompanion(bool nullToAbsent) {
    return FamiliesCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      motherId: motherId == null && nullToAbsent
          ? const Value.absent()
          : Value(motherId),
      fatherId: fatherId == null && nullToAbsent
          ? const Value.absent()
          : Value(fatherId),
      createdAt: Value(createdAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      profileImage: profileImage == null && nullToAbsent
          ? const Value.absent()
          : Value(profileImage),
      bannerImage: bannerImage == null && nullToAbsent
          ? const Value.absent()
          : Value(bannerImage),
      synced: Value(synced),
    );
  }

  factory Family.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Family(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      code: serializer.fromJson<String?>(json['code']),
      motherId: serializer.fromJson<String?>(json['motherId']),
      fatherId: serializer.fromJson<String?>(json['fatherId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      profileImage: serializer.fromJson<String?>(json['profileImage']),
      bannerImage: serializer.fromJson<String?>(json['bannerImage']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'code': serializer.toJson<String?>(code),
      'motherId': serializer.toJson<String?>(motherId),
      'fatherId': serializer.toJson<String?>(fatherId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'profileImage': serializer.toJson<String?>(profileImage),
      'bannerImage': serializer.toJson<String?>(bannerImage),
      'synced': serializer.toJson<int>(synced),
    };
  }

  Family copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    Value<String?> code = const Value.absent(),
    Value<String?> motherId = const Value.absent(),
    Value<String?> fatherId = const Value.absent(),
    DateTime? createdAt,
    Value<String?> createdBy = const Value.absent(),
    Value<String?> profileImage = const Value.absent(),
    Value<String?> bannerImage = const Value.absent(),
    int? synced,
  }) => Family(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    code: code.present ? code.value : this.code,
    motherId: motherId.present ? motherId.value : this.motherId,
    fatherId: fatherId.present ? fatherId.value : this.fatherId,
    createdAt: createdAt ?? this.createdAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    profileImage: profileImage.present ? profileImage.value : this.profileImage,
    bannerImage: bannerImage.present ? bannerImage.value : this.bannerImage,
    synced: synced ?? this.synced,
  );
  Family copyWithCompanion(FamiliesCompanion data) {
    return Family(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      motherId: data.motherId.present ? data.motherId.value : this.motherId,
      fatherId: data.fatherId.present ? data.fatherId.value : this.fatherId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      profileImage: data.profileImage.present
          ? data.profileImage.value
          : this.profileImage,
      bannerImage: data.bannerImage.present
          ? data.bannerImage.value
          : this.bannerImage,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Family(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('motherId: $motherId, ')
          ..write('fatherId: $fatherId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('profileImage: $profileImage, ')
          ..write('bannerImage: $bannerImage, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    code,
    motherId,
    fatherId,
    createdAt,
    createdBy,
    profileImage,
    bannerImage,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Family &&
          other.id == this.id &&
          other.name == this.name &&
          other.code == this.code &&
          other.motherId == this.motherId &&
          other.fatherId == this.fatherId &&
          other.createdAt == this.createdAt &&
          other.createdBy == this.createdBy &&
          other.profileImage == this.profileImage &&
          other.bannerImage == this.bannerImage &&
          other.synced == this.synced);
}

class FamiliesCompanion extends UpdateCompanion<Family> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> code;
  final Value<String?> motherId;
  final Value<String?> fatherId;
  final Value<DateTime> createdAt;
  final Value<String?> createdBy;
  final Value<String?> profileImage;
  final Value<String?> bannerImage;
  final Value<int> synced;
  final Value<int> rowid;
  const FamiliesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.motherId = const Value.absent(),
    this.fatherId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.profileImage = const Value.absent(),
    this.bannerImage = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FamiliesCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.motherId = const Value.absent(),
    this.fatherId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.profileImage = const Value.absent(),
    this.bannerImage = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Family> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? code,
    Expression<String>? motherId,
    Expression<String>? fatherId,
    Expression<DateTime>? createdAt,
    Expression<String>? createdBy,
    Expression<String>? profileImage,
    Expression<String>? bannerImage,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (motherId != null) 'mother_id': motherId,
      if (fatherId != null) 'father_id': fatherId,
      if (createdAt != null) 'created_at': createdAt,
      if (createdBy != null) 'created_by': createdBy,
      if (profileImage != null) 'profile_image': profileImage,
      if (bannerImage != null) 'banner_image': bannerImage,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FamiliesCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String?>? code,
    Value<String?>? motherId,
    Value<String?>? fatherId,
    Value<DateTime>? createdAt,
    Value<String?>? createdBy,
    Value<String?>? profileImage,
    Value<String?>? bannerImage,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return FamiliesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      motherId: motherId ?? this.motherId,
      fatherId: fatherId ?? this.fatherId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      profileImage: profileImage ?? this.profileImage,
      bannerImage: bannerImage ?? this.bannerImage,
      synced: synced ?? this.synced,
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
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (motherId.present) {
      map['mother_id'] = Variable<String>(motherId.value);
    }
    if (fatherId.present) {
      map['father_id'] = Variable<String>(fatherId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (profileImage.present) {
      map['profile_image'] = Variable<String>(profileImage.value);
    }
    if (bannerImage.present) {
      map['banner_image'] = Variable<String>(bannerImage.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamiliesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('motherId: $motherId, ')
          ..write('fatherId: $fatherId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('profileImage: $profileImage, ')
          ..write('bannerImage: $bannerImage, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FamilyRequestsTableTable extends FamilyRequestsTable
    with TableInfo<$FamilyRequestsTableTable, FamilyRequestsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamilyRequestsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'userId',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _familyIdMeta = const VerificationMeta(
    'familyId',
  );
  @override
  late final GeneratedColumn<String> familyId = GeneratedColumn<String>(
    'familyId',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    familyId,
    createdAt,
    expiresAt,
    status,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_requests_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyRequestsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('userId')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['userId']!, _userIdMeta),
      );
    }
    if (data.containsKey('familyId')) {
      context.handle(
        _familyIdMeta,
        familyId.isAcceptableOrUnknown(data['familyId']!, _familyIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyRequestsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyRequestsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}userId'],
      ),
      familyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}familyId'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $FamilyRequestsTableTable createAlias(String alias) {
    return $FamilyRequestsTableTable(attachedDatabase, alias);
  }
}

class FamilyRequestsTableData extends DataClass
    implements Insertable<FamilyRequestsTableData> {
  final String id;
  final String? userId;
  final String? familyId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? status;
  final int synced;
  const FamilyRequestsTableData({
    required this.id,
    this.userId,
    this.familyId,
    required this.createdAt,
    this.expiresAt,
    this.status,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['userId'] = Variable<String>(userId);
    }
    if (!nullToAbsent || familyId != null) {
      map['familyId'] = Variable<String>(familyId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  FamilyRequestsTableCompanion toCompanion(bool nullToAbsent) {
    return FamilyRequestsTableCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      familyId: familyId == null && nullToAbsent
          ? const Value.absent()
          : Value(familyId),
      createdAt: Value(createdAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      synced: Value(synced),
    );
  }

  factory FamilyRequestsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyRequestsTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      familyId: serializer.fromJson<String?>(json['familyId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      status: serializer.fromJson<String?>(json['status']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'familyId': serializer.toJson<String?>(familyId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'status': serializer.toJson<String?>(status),
      'synced': serializer.toJson<int>(synced),
    };
  }

  FamilyRequestsTableData copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    Value<String?> familyId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> expiresAt = const Value.absent(),
    Value<String?> status = const Value.absent(),
    int? synced,
  }) => FamilyRequestsTableData(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    familyId: familyId.present ? familyId.value : this.familyId,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    status: status.present ? status.value : this.status,
    synced: synced ?? this.synced,
  );
  FamilyRequestsTableData copyWithCompanion(FamilyRequestsTableCompanion data) {
    return FamilyRequestsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      familyId: data.familyId.present ? data.familyId.value : this.familyId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      status: data.status.present ? data.status.value : this.status,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyRequestsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('familyId: $familyId, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('status: $status, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, familyId, createdAt, expiresAt, status, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyRequestsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.familyId == this.familyId &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt &&
          other.status == this.status &&
          other.synced == this.synced);
}

class FamilyRequestsTableCompanion
    extends UpdateCompanion<FamilyRequestsTableData> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String?> familyId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> expiresAt;
  final Value<String?> status;
  final Value<int> synced;
  final Value<int> rowid;
  const FamilyRequestsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.familyId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.status = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FamilyRequestsTableCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    this.familyId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.status = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<FamilyRequestsTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? familyId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? expiresAt,
    Expression<String>? status,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      if (familyId != null) 'familyId': familyId,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (status != null) 'status': status,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FamilyRequestsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String?>? familyId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? expiresAt,
    Value<String?>? status,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return FamilyRequestsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['userId'] = Variable<String>(userId.value);
    }
    if (familyId.present) {
      map['familyId'] = Variable<String>(familyId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamilyRequestsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('familyId: $familyId, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('status: $status, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FamilyMembersTableTable extends FamilyMembersTable
    with TableInfo<$FamilyMembersTableTable, FamilyMembersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamilyMembersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _useridMeta = const VerificationMeta('userid');
  @override
  late final GeneratedColumn<String> userid = GeneratedColumn<String>(
    'userid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _familyidMeta = const VerificationMeta(
    'familyid',
  );
  @override
  late final GeneratedColumn<String> familyid = GeneratedColumn<String>(
    'familyid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relationMeta = const VerificationMeta(
    'relation',
  );
  @override
  late final GeneratedColumn<String> relation = GeneratedColumn<String>(
    'relation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accessLevelMeta = const VerificationMeta(
    'accessLevel',
  );
  @override
  late final GeneratedColumn<String> accessLevel = GeneratedColumn<String>(
    'access_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userid,
    familyid,
    relation,
    accessLevel,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_members_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyMembersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('userid')) {
      context.handle(
        _useridMeta,
        userid.isAcceptableOrUnknown(data['userid']!, _useridMeta),
      );
    }
    if (data.containsKey('familyid')) {
      context.handle(
        _familyidMeta,
        familyid.isAcceptableOrUnknown(data['familyid']!, _familyidMeta),
      );
    }
    if (data.containsKey('relation')) {
      context.handle(
        _relationMeta,
        relation.isAcceptableOrUnknown(data['relation']!, _relationMeta),
      );
    }
    if (data.containsKey('access_level')) {
      context.handle(
        _accessLevelMeta,
        accessLevel.isAcceptableOrUnknown(
          data['access_level']!,
          _accessLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accessLevelMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyMembersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyMembersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}userid'],
      ),
      familyid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}familyid'],
      ),
      relation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relation'],
      ),
      accessLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_level'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $FamilyMembersTableTable createAlias(String alias) {
    return $FamilyMembersTableTable(attachedDatabase, alias);
  }
}

class FamilyMembersTableData extends DataClass
    implements Insertable<FamilyMembersTableData> {
  final String id;
  final String? userid;
  final String? familyid;
  final String? relation;
  final String accessLevel;
  final int synced;
  const FamilyMembersTableData({
    required this.id,
    this.userid,
    this.familyid,
    this.relation,
    required this.accessLevel,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userid != null) {
      map['userid'] = Variable<String>(userid);
    }
    if (!nullToAbsent || familyid != null) {
      map['familyid'] = Variable<String>(familyid);
    }
    if (!nullToAbsent || relation != null) {
      map['relation'] = Variable<String>(relation);
    }
    map['access_level'] = Variable<String>(accessLevel);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  FamilyMembersTableCompanion toCompanion(bool nullToAbsent) {
    return FamilyMembersTableCompanion(
      id: Value(id),
      userid: userid == null && nullToAbsent
          ? const Value.absent()
          : Value(userid),
      familyid: familyid == null && nullToAbsent
          ? const Value.absent()
          : Value(familyid),
      relation: relation == null && nullToAbsent
          ? const Value.absent()
          : Value(relation),
      accessLevel: Value(accessLevel),
      synced: Value(synced),
    );
  }

  factory FamilyMembersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyMembersTableData(
      id: serializer.fromJson<String>(json['id']),
      userid: serializer.fromJson<String?>(json['userid']),
      familyid: serializer.fromJson<String?>(json['familyid']),
      relation: serializer.fromJson<String?>(json['relation']),
      accessLevel: serializer.fromJson<String>(json['accessLevel']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userid': serializer.toJson<String?>(userid),
      'familyid': serializer.toJson<String?>(familyid),
      'relation': serializer.toJson<String?>(relation),
      'accessLevel': serializer.toJson<String>(accessLevel),
      'synced': serializer.toJson<int>(synced),
    };
  }

  FamilyMembersTableData copyWith({
    String? id,
    Value<String?> userid = const Value.absent(),
    Value<String?> familyid = const Value.absent(),
    Value<String?> relation = const Value.absent(),
    String? accessLevel,
    int? synced,
  }) => FamilyMembersTableData(
    id: id ?? this.id,
    userid: userid.present ? userid.value : this.userid,
    familyid: familyid.present ? familyid.value : this.familyid,
    relation: relation.present ? relation.value : this.relation,
    accessLevel: accessLevel ?? this.accessLevel,
    synced: synced ?? this.synced,
  );
  FamilyMembersTableData copyWithCompanion(FamilyMembersTableCompanion data) {
    return FamilyMembersTableData(
      id: data.id.present ? data.id.value : this.id,
      userid: data.userid.present ? data.userid.value : this.userid,
      familyid: data.familyid.present ? data.familyid.value : this.familyid,
      relation: data.relation.present ? data.relation.value : this.relation,
      accessLevel: data.accessLevel.present
          ? data.accessLevel.value
          : this.accessLevel,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyMembersTableData(')
          ..write('id: $id, ')
          ..write('userid: $userid, ')
          ..write('familyid: $familyid, ')
          ..write('relation: $relation, ')
          ..write('accessLevel: $accessLevel, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userid, familyid, relation, accessLevel, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyMembersTableData &&
          other.id == this.id &&
          other.userid == this.userid &&
          other.familyid == this.familyid &&
          other.relation == this.relation &&
          other.accessLevel == this.accessLevel &&
          other.synced == this.synced);
}

class FamilyMembersTableCompanion
    extends UpdateCompanion<FamilyMembersTableData> {
  final Value<String> id;
  final Value<String?> userid;
  final Value<String?> familyid;
  final Value<String?> relation;
  final Value<String> accessLevel;
  final Value<int> synced;
  final Value<int> rowid;
  const FamilyMembersTableCompanion({
    this.id = const Value.absent(),
    this.userid = const Value.absent(),
    this.familyid = const Value.absent(),
    this.relation = const Value.absent(),
    this.accessLevel = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FamilyMembersTableCompanion.insert({
    required String id,
    this.userid = const Value.absent(),
    this.familyid = const Value.absent(),
    this.relation = const Value.absent(),
    required String accessLevel,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accessLevel = Value(accessLevel);
  static Insertable<FamilyMembersTableData> custom({
    Expression<String>? id,
    Expression<String>? userid,
    Expression<String>? familyid,
    Expression<String>? relation,
    Expression<String>? accessLevel,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userid != null) 'userid': userid,
      if (familyid != null) 'familyid': familyid,
      if (relation != null) 'relation': relation,
      if (accessLevel != null) 'access_level': accessLevel,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FamilyMembersTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? userid,
    Value<String?>? familyid,
    Value<String?>? relation,
    Value<String>? accessLevel,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return FamilyMembersTableCompanion(
      id: id ?? this.id,
      userid: userid ?? this.userid,
      familyid: familyid ?? this.familyid,
      relation: relation ?? this.relation,
      accessLevel: accessLevel ?? this.accessLevel,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userid.present) {
      map['userid'] = Variable<String>(userid.value);
    }
    if (familyid.present) {
      map['familyid'] = Variable<String>(familyid.value);
    }
    if (relation.present) {
      map['relation'] = Variable<String>(relation.value);
    }
    if (accessLevel.present) {
      map['access_level'] = Variable<String>(accessLevel.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamilyMembersTableCompanion(')
          ..write('id: $id, ')
          ..write('userid: $userid, ')
          ..write('familyid: $familyid, ')
          ..write('relation: $relation, ')
          ..write('accessLevel: $accessLevel, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HealthDataTableTable extends HealthDataTable
    with TableInfo<$HealthDataTableTable, HealthDataTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthDataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bloodGroupMeta = const VerificationMeta(
    'bloodGroup',
  );
  @override
  late final GeneratedColumn<String> bloodGroup = GeneratedColumn<String>(
    'blood_group',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allergiesMeta = const VerificationMeta(
    'allergies',
  );
  @override
  late final GeneratedColumn<String> allergies = GeneratedColumn<String>(
    'allergies',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _medicalConditionsMeta = const VerificationMeta(
    'medicalConditions',
  );
  @override
  late final GeneratedColumn<String> medicalConditions =
      GeneratedColumn<String>(
        'medical_conditions',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rchIdMeta = const VerificationMeta('rchId');
  @override
  late final GeneratedColumn<String> rchId = GeneratedColumn<String>(
    'rch_id',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _recoveryPhoneMeta = const VerificationMeta(
    'recoveryPhone',
  );
  @override
  late final GeneratedColumn<String> recoveryPhone = GeneratedColumn<String>(
    'recovery_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recoveryEmailMeta = const VerificationMeta(
    'recoveryEmail',
  );
  @override
  late final GeneratedColumn<String> recoveryEmail = GeneratedColumn<String>(
    'recovery_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lmpDateMeta = const VerificationMeta(
    'lmpDate',
  );
  @override
  late final GeneratedColumn<DateTime> lmpDate = GeneratedColumn<DateTime>(
    'lmp_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _averagePeriodDurationMeta =
      const VerificationMeta('averagePeriodDuration');
  @override
  late final GeneratedColumn<double> averagePeriodDuration =
      GeneratedColumn<double>(
        'average_period_duration',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _averageCycleMeta = const VerificationMeta(
    'averageCycle',
  );
  @override
  late final GeneratedColumn<double> averageCycle = GeneratedColumn<double>(
    'average_cycle',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cycleTypeMeta = const VerificationMeta(
    'cycleType',
  );
  @override
  late final GeneratedColumn<String> cycleType = GeneratedColumn<String>(
    'cycle_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _edDateMeta = const VerificationMeta('edDate');
  @override
  late final GeneratedColumn<DateTime> edDate = GeneratedColumn<DateTime>(
    'ed_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pregnancyStatusMeta = const VerificationMeta(
    'pregnancyStatus',
  );
  @override
  late final GeneratedColumn<String> pregnancyStatus = GeneratedColumn<String>(
    'pregnancy_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastDeliveryDateMeta = const VerificationMeta(
    'lastDeliveryDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastDeliveryDate =
      GeneratedColumn<DateTime>(
        'last_delivery_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _healthStatusMeta = const VerificationMeta(
    'healthStatus',
  );
  @override
  late final GeneratedColumn<String> healthStatus = GeneratedColumn<String>(
    'health_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allowFamilyAccessMeta = const VerificationMeta(
    'allowFamilyAccess',
  );
  @override
  late final GeneratedColumn<bool> allowFamilyAccess = GeneratedColumn<bool>(
    'allow_family_access',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_family_access" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    height,
    weight,
    bloodGroup,
    allergies,
    medicalConditions,
    rchId,
    createdAt,
    recoveryPhone,
    recoveryEmail,
    lmpDate,
    averagePeriodDuration,
    averageCycle,
    cycleType,
    edDate,
    pregnancyStatus,
    lastDeliveryDate,
    healthStatus,
    allowFamilyAccess,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_data_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<HealthDataTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('blood_group')) {
      context.handle(
        _bloodGroupMeta,
        bloodGroup.isAcceptableOrUnknown(data['blood_group']!, _bloodGroupMeta),
      );
    }
    if (data.containsKey('allergies')) {
      context.handle(
        _allergiesMeta,
        allergies.isAcceptableOrUnknown(data['allergies']!, _allergiesMeta),
      );
    }
    if (data.containsKey('medical_conditions')) {
      context.handle(
        _medicalConditionsMeta,
        medicalConditions.isAcceptableOrUnknown(
          data['medical_conditions']!,
          _medicalConditionsMeta,
        ),
      );
    }
    if (data.containsKey('rch_id')) {
      context.handle(
        _rchIdMeta,
        rchId.isAcceptableOrUnknown(data['rch_id']!, _rchIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('recovery_phone')) {
      context.handle(
        _recoveryPhoneMeta,
        recoveryPhone.isAcceptableOrUnknown(
          data['recovery_phone']!,
          _recoveryPhoneMeta,
        ),
      );
    }
    if (data.containsKey('recovery_email')) {
      context.handle(
        _recoveryEmailMeta,
        recoveryEmail.isAcceptableOrUnknown(
          data['recovery_email']!,
          _recoveryEmailMeta,
        ),
      );
    }
    if (data.containsKey('lmp_date')) {
      context.handle(
        _lmpDateMeta,
        lmpDate.isAcceptableOrUnknown(data['lmp_date']!, _lmpDateMeta),
      );
    }
    if (data.containsKey('average_period_duration')) {
      context.handle(
        _averagePeriodDurationMeta,
        averagePeriodDuration.isAcceptableOrUnknown(
          data['average_period_duration']!,
          _averagePeriodDurationMeta,
        ),
      );
    }
    if (data.containsKey('average_cycle')) {
      context.handle(
        _averageCycleMeta,
        averageCycle.isAcceptableOrUnknown(
          data['average_cycle']!,
          _averageCycleMeta,
        ),
      );
    }
    if (data.containsKey('cycle_type')) {
      context.handle(
        _cycleTypeMeta,
        cycleType.isAcceptableOrUnknown(data['cycle_type']!, _cycleTypeMeta),
      );
    }
    if (data.containsKey('ed_date')) {
      context.handle(
        _edDateMeta,
        edDate.isAcceptableOrUnknown(data['ed_date']!, _edDateMeta),
      );
    }
    if (data.containsKey('pregnancy_status')) {
      context.handle(
        _pregnancyStatusMeta,
        pregnancyStatus.isAcceptableOrUnknown(
          data['pregnancy_status']!,
          _pregnancyStatusMeta,
        ),
      );
    }
    if (data.containsKey('last_delivery_date')) {
      context.handle(
        _lastDeliveryDateMeta,
        lastDeliveryDate.isAcceptableOrUnknown(
          data['last_delivery_date']!,
          _lastDeliveryDateMeta,
        ),
      );
    }
    if (data.containsKey('health_status')) {
      context.handle(
        _healthStatusMeta,
        healthStatus.isAcceptableOrUnknown(
          data['health_status']!,
          _healthStatusMeta,
        ),
      );
    }
    if (data.containsKey('allow_family_access')) {
      context.handle(
        _allowFamilyAccessMeta,
        allowFamilyAccess.isAcceptableOrUnknown(
          data['allow_family_access']!,
          _allowFamilyAccessMeta,
        ),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HealthDataTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthDataTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height'],
      ),
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      ),
      bloodGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blood_group'],
      ),
      allergies: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allergies'],
      ),
      medicalConditions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medical_conditions'],
      ),
      rchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rch_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      recoveryPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recovery_phone'],
      ),
      recoveryEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recovery_email'],
      ),
      lmpDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}lmp_date'],
      ),
      averagePeriodDuration: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_period_duration'],
      ),
      averageCycle: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_cycle'],
      ),
      cycleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_type'],
      ),
      edDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ed_date'],
      ),
      pregnancyStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pregnancy_status'],
      ),
      lastDeliveryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_delivery_date'],
      ),
      healthStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_status'],
      ),
      allowFamilyAccess: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_family_access'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $HealthDataTableTable createAlias(String alias) {
    return $HealthDataTableTable(attachedDatabase, alias);
  }
}

class HealthDataTableData extends DataClass
    implements Insertable<HealthDataTableData> {
  final String id;
  final String? userId;
  final double? height;
  final double? weight;
  final String? bloodGroup;
  final String? allergies;
  final String? medicalConditions;
  final String? rchId;
  final DateTime createdAt;
  final String? recoveryPhone;
  final String? recoveryEmail;
  final DateTime? lmpDate;
  final double? averagePeriodDuration;
  final double? averageCycle;
  final String? cycleType;
  final DateTime? edDate;
  final String? pregnancyStatus;
  final DateTime? lastDeliveryDate;
  final String? healthStatus;
  final bool allowFamilyAccess;
  final int synced;
  const HealthDataTableData({
    required this.id,
    this.userId,
    this.height,
    this.weight,
    this.bloodGroup,
    this.allergies,
    this.medicalConditions,
    this.rchId,
    required this.createdAt,
    this.recoveryPhone,
    this.recoveryEmail,
    this.lmpDate,
    this.averagePeriodDuration,
    this.averageCycle,
    this.cycleType,
    this.edDate,
    this.pregnancyStatus,
    this.lastDeliveryDate,
    this.healthStatus,
    required this.allowFamilyAccess,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['UserID'] = Variable<String>(userId);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<double>(height);
    }
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || bloodGroup != null) {
      map['blood_group'] = Variable<String>(bloodGroup);
    }
    if (!nullToAbsent || allergies != null) {
      map['allergies'] = Variable<String>(allergies);
    }
    if (!nullToAbsent || medicalConditions != null) {
      map['medical_conditions'] = Variable<String>(medicalConditions);
    }
    if (!nullToAbsent || rchId != null) {
      map['rch_id'] = Variable<String>(rchId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || recoveryPhone != null) {
      map['recovery_phone'] = Variable<String>(recoveryPhone);
    }
    if (!nullToAbsent || recoveryEmail != null) {
      map['recovery_email'] = Variable<String>(recoveryEmail);
    }
    if (!nullToAbsent || lmpDate != null) {
      map['lmp_date'] = Variable<DateTime>(lmpDate);
    }
    if (!nullToAbsent || averagePeriodDuration != null) {
      map['average_period_duration'] = Variable<double>(averagePeriodDuration);
    }
    if (!nullToAbsent || averageCycle != null) {
      map['average_cycle'] = Variable<double>(averageCycle);
    }
    if (!nullToAbsent || cycleType != null) {
      map['cycle_type'] = Variable<String>(cycleType);
    }
    if (!nullToAbsent || edDate != null) {
      map['ed_date'] = Variable<DateTime>(edDate);
    }
    if (!nullToAbsent || pregnancyStatus != null) {
      map['pregnancy_status'] = Variable<String>(pregnancyStatus);
    }
    if (!nullToAbsent || lastDeliveryDate != null) {
      map['last_delivery_date'] = Variable<DateTime>(lastDeliveryDate);
    }
    if (!nullToAbsent || healthStatus != null) {
      map['health_status'] = Variable<String>(healthStatus);
    }
    map['allow_family_access'] = Variable<bool>(allowFamilyAccess);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  HealthDataTableCompanion toCompanion(bool nullToAbsent) {
    return HealthDataTableCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      weight: weight == null && nullToAbsent
          ? const Value.absent()
          : Value(weight),
      bloodGroup: bloodGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(bloodGroup),
      allergies: allergies == null && nullToAbsent
          ? const Value.absent()
          : Value(allergies),
      medicalConditions: medicalConditions == null && nullToAbsent
          ? const Value.absent()
          : Value(medicalConditions),
      rchId: rchId == null && nullToAbsent
          ? const Value.absent()
          : Value(rchId),
      createdAt: Value(createdAt),
      recoveryPhone: recoveryPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(recoveryPhone),
      recoveryEmail: recoveryEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(recoveryEmail),
      lmpDate: lmpDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lmpDate),
      averagePeriodDuration: averagePeriodDuration == null && nullToAbsent
          ? const Value.absent()
          : Value(averagePeriodDuration),
      averageCycle: averageCycle == null && nullToAbsent
          ? const Value.absent()
          : Value(averageCycle),
      cycleType: cycleType == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleType),
      edDate: edDate == null && nullToAbsent
          ? const Value.absent()
          : Value(edDate),
      pregnancyStatus: pregnancyStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(pregnancyStatus),
      lastDeliveryDate: lastDeliveryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDeliveryDate),
      healthStatus: healthStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(healthStatus),
      allowFamilyAccess: Value(allowFamilyAccess),
      synced: Value(synced),
    );
  }

  factory HealthDataTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthDataTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      height: serializer.fromJson<double?>(json['height']),
      weight: serializer.fromJson<double?>(json['weight']),
      bloodGroup: serializer.fromJson<String?>(json['bloodGroup']),
      allergies: serializer.fromJson<String?>(json['allergies']),
      medicalConditions: serializer.fromJson<String?>(
        json['medicalConditions'],
      ),
      rchId: serializer.fromJson<String?>(json['rchId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      recoveryPhone: serializer.fromJson<String?>(json['recoveryPhone']),
      recoveryEmail: serializer.fromJson<String?>(json['recoveryEmail']),
      lmpDate: serializer.fromJson<DateTime?>(json['lmpDate']),
      averagePeriodDuration: serializer.fromJson<double?>(
        json['averagePeriodDuration'],
      ),
      averageCycle: serializer.fromJson<double?>(json['averageCycle']),
      cycleType: serializer.fromJson<String?>(json['cycleType']),
      edDate: serializer.fromJson<DateTime?>(json['edDate']),
      pregnancyStatus: serializer.fromJson<String?>(json['pregnancyStatus']),
      lastDeliveryDate: serializer.fromJson<DateTime?>(
        json['lastDeliveryDate'],
      ),
      healthStatus: serializer.fromJson<String?>(json['healthStatus']),
      allowFamilyAccess: serializer.fromJson<bool>(json['allowFamilyAccess']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'height': serializer.toJson<double?>(height),
      'weight': serializer.toJson<double?>(weight),
      'bloodGroup': serializer.toJson<String?>(bloodGroup),
      'allergies': serializer.toJson<String?>(allergies),
      'medicalConditions': serializer.toJson<String?>(medicalConditions),
      'rchId': serializer.toJson<String?>(rchId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'recoveryPhone': serializer.toJson<String?>(recoveryPhone),
      'recoveryEmail': serializer.toJson<String?>(recoveryEmail),
      'lmpDate': serializer.toJson<DateTime?>(lmpDate),
      'averagePeriodDuration': serializer.toJson<double?>(
        averagePeriodDuration,
      ),
      'averageCycle': serializer.toJson<double?>(averageCycle),
      'cycleType': serializer.toJson<String?>(cycleType),
      'edDate': serializer.toJson<DateTime?>(edDate),
      'pregnancyStatus': serializer.toJson<String?>(pregnancyStatus),
      'lastDeliveryDate': serializer.toJson<DateTime?>(lastDeliveryDate),
      'healthStatus': serializer.toJson<String?>(healthStatus),
      'allowFamilyAccess': serializer.toJson<bool>(allowFamilyAccess),
      'synced': serializer.toJson<int>(synced),
    };
  }

  HealthDataTableData copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    Value<double?> height = const Value.absent(),
    Value<double?> weight = const Value.absent(),
    Value<String?> bloodGroup = const Value.absent(),
    Value<String?> allergies = const Value.absent(),
    Value<String?> medicalConditions = const Value.absent(),
    Value<String?> rchId = const Value.absent(),
    DateTime? createdAt,
    Value<String?> recoveryPhone = const Value.absent(),
    Value<String?> recoveryEmail = const Value.absent(),
    Value<DateTime?> lmpDate = const Value.absent(),
    Value<double?> averagePeriodDuration = const Value.absent(),
    Value<double?> averageCycle = const Value.absent(),
    Value<String?> cycleType = const Value.absent(),
    Value<DateTime?> edDate = const Value.absent(),
    Value<String?> pregnancyStatus = const Value.absent(),
    Value<DateTime?> lastDeliveryDate = const Value.absent(),
    Value<String?> healthStatus = const Value.absent(),
    bool? allowFamilyAccess,
    int? synced,
  }) => HealthDataTableData(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    height: height.present ? height.value : this.height,
    weight: weight.present ? weight.value : this.weight,
    bloodGroup: bloodGroup.present ? bloodGroup.value : this.bloodGroup,
    allergies: allergies.present ? allergies.value : this.allergies,
    medicalConditions: medicalConditions.present
        ? medicalConditions.value
        : this.medicalConditions,
    rchId: rchId.present ? rchId.value : this.rchId,
    createdAt: createdAt ?? this.createdAt,
    recoveryPhone: recoveryPhone.present
        ? recoveryPhone.value
        : this.recoveryPhone,
    recoveryEmail: recoveryEmail.present
        ? recoveryEmail.value
        : this.recoveryEmail,
    lmpDate: lmpDate.present ? lmpDate.value : this.lmpDate,
    averagePeriodDuration: averagePeriodDuration.present
        ? averagePeriodDuration.value
        : this.averagePeriodDuration,
    averageCycle: averageCycle.present ? averageCycle.value : this.averageCycle,
    cycleType: cycleType.present ? cycleType.value : this.cycleType,
    edDate: edDate.present ? edDate.value : this.edDate,
    pregnancyStatus: pregnancyStatus.present
        ? pregnancyStatus.value
        : this.pregnancyStatus,
    lastDeliveryDate: lastDeliveryDate.present
        ? lastDeliveryDate.value
        : this.lastDeliveryDate,
    healthStatus: healthStatus.present ? healthStatus.value : this.healthStatus,
    allowFamilyAccess: allowFamilyAccess ?? this.allowFamilyAccess,
    synced: synced ?? this.synced,
  );
  HealthDataTableData copyWithCompanion(HealthDataTableCompanion data) {
    return HealthDataTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      height: data.height.present ? data.height.value : this.height,
      weight: data.weight.present ? data.weight.value : this.weight,
      bloodGroup: data.bloodGroup.present
          ? data.bloodGroup.value
          : this.bloodGroup,
      allergies: data.allergies.present ? data.allergies.value : this.allergies,
      medicalConditions: data.medicalConditions.present
          ? data.medicalConditions.value
          : this.medicalConditions,
      rchId: data.rchId.present ? data.rchId.value : this.rchId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      recoveryPhone: data.recoveryPhone.present
          ? data.recoveryPhone.value
          : this.recoveryPhone,
      recoveryEmail: data.recoveryEmail.present
          ? data.recoveryEmail.value
          : this.recoveryEmail,
      lmpDate: data.lmpDate.present ? data.lmpDate.value : this.lmpDate,
      averagePeriodDuration: data.averagePeriodDuration.present
          ? data.averagePeriodDuration.value
          : this.averagePeriodDuration,
      averageCycle: data.averageCycle.present
          ? data.averageCycle.value
          : this.averageCycle,
      cycleType: data.cycleType.present ? data.cycleType.value : this.cycleType,
      edDate: data.edDate.present ? data.edDate.value : this.edDate,
      pregnancyStatus: data.pregnancyStatus.present
          ? data.pregnancyStatus.value
          : this.pregnancyStatus,
      lastDeliveryDate: data.lastDeliveryDate.present
          ? data.lastDeliveryDate.value
          : this.lastDeliveryDate,
      healthStatus: data.healthStatus.present
          ? data.healthStatus.value
          : this.healthStatus,
      allowFamilyAccess: data.allowFamilyAccess.present
          ? data.allowFamilyAccess.value
          : this.allowFamilyAccess,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthDataTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('height: $height, ')
          ..write('weight: $weight, ')
          ..write('bloodGroup: $bloodGroup, ')
          ..write('allergies: $allergies, ')
          ..write('medicalConditions: $medicalConditions, ')
          ..write('rchId: $rchId, ')
          ..write('createdAt: $createdAt, ')
          ..write('recoveryPhone: $recoveryPhone, ')
          ..write('recoveryEmail: $recoveryEmail, ')
          ..write('lmpDate: $lmpDate, ')
          ..write('averagePeriodDuration: $averagePeriodDuration, ')
          ..write('averageCycle: $averageCycle, ')
          ..write('cycleType: $cycleType, ')
          ..write('edDate: $edDate, ')
          ..write('pregnancyStatus: $pregnancyStatus, ')
          ..write('lastDeliveryDate: $lastDeliveryDate, ')
          ..write('healthStatus: $healthStatus, ')
          ..write('allowFamilyAccess: $allowFamilyAccess, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    height,
    weight,
    bloodGroup,
    allergies,
    medicalConditions,
    rchId,
    createdAt,
    recoveryPhone,
    recoveryEmail,
    lmpDate,
    averagePeriodDuration,
    averageCycle,
    cycleType,
    edDate,
    pregnancyStatus,
    lastDeliveryDate,
    healthStatus,
    allowFamilyAccess,
    synced,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthDataTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.height == this.height &&
          other.weight == this.weight &&
          other.bloodGroup == this.bloodGroup &&
          other.allergies == this.allergies &&
          other.medicalConditions == this.medicalConditions &&
          other.rchId == this.rchId &&
          other.createdAt == this.createdAt &&
          other.recoveryPhone == this.recoveryPhone &&
          other.recoveryEmail == this.recoveryEmail &&
          other.lmpDate == this.lmpDate &&
          other.averagePeriodDuration == this.averagePeriodDuration &&
          other.averageCycle == this.averageCycle &&
          other.cycleType == this.cycleType &&
          other.edDate == this.edDate &&
          other.pregnancyStatus == this.pregnancyStatus &&
          other.lastDeliveryDate == this.lastDeliveryDate &&
          other.healthStatus == this.healthStatus &&
          other.allowFamilyAccess == this.allowFamilyAccess &&
          other.synced == this.synced);
}

class HealthDataTableCompanion extends UpdateCompanion<HealthDataTableData> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<double?> height;
  final Value<double?> weight;
  final Value<String?> bloodGroup;
  final Value<String?> allergies;
  final Value<String?> medicalConditions;
  final Value<String?> rchId;
  final Value<DateTime> createdAt;
  final Value<String?> recoveryPhone;
  final Value<String?> recoveryEmail;
  final Value<DateTime?> lmpDate;
  final Value<double?> averagePeriodDuration;
  final Value<double?> averageCycle;
  final Value<String?> cycleType;
  final Value<DateTime?> edDate;
  final Value<String?> pregnancyStatus;
  final Value<DateTime?> lastDeliveryDate;
  final Value<String?> healthStatus;
  final Value<bool> allowFamilyAccess;
  final Value<int> synced;
  final Value<int> rowid;
  const HealthDataTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.height = const Value.absent(),
    this.weight = const Value.absent(),
    this.bloodGroup = const Value.absent(),
    this.allergies = const Value.absent(),
    this.medicalConditions = const Value.absent(),
    this.rchId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.recoveryPhone = const Value.absent(),
    this.recoveryEmail = const Value.absent(),
    this.lmpDate = const Value.absent(),
    this.averagePeriodDuration = const Value.absent(),
    this.averageCycle = const Value.absent(),
    this.cycleType = const Value.absent(),
    this.edDate = const Value.absent(),
    this.pregnancyStatus = const Value.absent(),
    this.lastDeliveryDate = const Value.absent(),
    this.healthStatus = const Value.absent(),
    this.allowFamilyAccess = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HealthDataTableCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    this.height = const Value.absent(),
    this.weight = const Value.absent(),
    this.bloodGroup = const Value.absent(),
    this.allergies = const Value.absent(),
    this.medicalConditions = const Value.absent(),
    this.rchId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.recoveryPhone = const Value.absent(),
    this.recoveryEmail = const Value.absent(),
    this.lmpDate = const Value.absent(),
    this.averagePeriodDuration = const Value.absent(),
    this.averageCycle = const Value.absent(),
    this.cycleType = const Value.absent(),
    this.edDate = const Value.absent(),
    this.pregnancyStatus = const Value.absent(),
    this.lastDeliveryDate = const Value.absent(),
    this.healthStatus = const Value.absent(),
    this.allowFamilyAccess = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<HealthDataTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<double>? height,
    Expression<double>? weight,
    Expression<String>? bloodGroup,
    Expression<String>? allergies,
    Expression<String>? medicalConditions,
    Expression<String>? rchId,
    Expression<DateTime>? createdAt,
    Expression<String>? recoveryPhone,
    Expression<String>? recoveryEmail,
    Expression<DateTime>? lmpDate,
    Expression<double>? averagePeriodDuration,
    Expression<double>? averageCycle,
    Expression<String>? cycleType,
    Expression<DateTime>? edDate,
    Expression<String>? pregnancyStatus,
    Expression<DateTime>? lastDeliveryDate,
    Expression<String>? healthStatus,
    Expression<bool>? allowFamilyAccess,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'UserID': userId,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (bloodGroup != null) 'blood_group': bloodGroup,
      if (allergies != null) 'allergies': allergies,
      if (medicalConditions != null) 'medical_conditions': medicalConditions,
      if (rchId != null) 'rch_id': rchId,
      if (createdAt != null) 'created_at': createdAt,
      if (recoveryPhone != null) 'recovery_phone': recoveryPhone,
      if (recoveryEmail != null) 'recovery_email': recoveryEmail,
      if (lmpDate != null) 'lmp_date': lmpDate,
      if (averagePeriodDuration != null)
        'average_period_duration': averagePeriodDuration,
      if (averageCycle != null) 'average_cycle': averageCycle,
      if (cycleType != null) 'cycle_type': cycleType,
      if (edDate != null) 'ed_date': edDate,
      if (pregnancyStatus != null) 'pregnancy_status': pregnancyStatus,
      if (lastDeliveryDate != null) 'last_delivery_date': lastDeliveryDate,
      if (healthStatus != null) 'health_status': healthStatus,
      if (allowFamilyAccess != null) 'allow_family_access': allowFamilyAccess,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HealthDataTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<double?>? height,
    Value<double?>? weight,
    Value<String?>? bloodGroup,
    Value<String?>? allergies,
    Value<String?>? medicalConditions,
    Value<String?>? rchId,
    Value<DateTime>? createdAt,
    Value<String?>? recoveryPhone,
    Value<String?>? recoveryEmail,
    Value<DateTime?>? lmpDate,
    Value<double?>? averagePeriodDuration,
    Value<double?>? averageCycle,
    Value<String?>? cycleType,
    Value<DateTime?>? edDate,
    Value<String?>? pregnancyStatus,
    Value<DateTime?>? lastDeliveryDate,
    Value<String?>? healthStatus,
    Value<bool>? allowFamilyAccess,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return HealthDataTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      rchId: rchId ?? this.rchId,
      createdAt: createdAt ?? this.createdAt,
      recoveryPhone: recoveryPhone ?? this.recoveryPhone,
      recoveryEmail: recoveryEmail ?? this.recoveryEmail,
      lmpDate: lmpDate ?? this.lmpDate,
      averagePeriodDuration:
          averagePeriodDuration ?? this.averagePeriodDuration,
      averageCycle: averageCycle ?? this.averageCycle,
      cycleType: cycleType ?? this.cycleType,
      edDate: edDate ?? this.edDate,
      pregnancyStatus: pregnancyStatus ?? this.pregnancyStatus,
      lastDeliveryDate: lastDeliveryDate ?? this.lastDeliveryDate,
      healthStatus: healthStatus ?? this.healthStatus,
      allowFamilyAccess: allowFamilyAccess ?? this.allowFamilyAccess,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (bloodGroup.present) {
      map['blood_group'] = Variable<String>(bloodGroup.value);
    }
    if (allergies.present) {
      map['allergies'] = Variable<String>(allergies.value);
    }
    if (medicalConditions.present) {
      map['medical_conditions'] = Variable<String>(medicalConditions.value);
    }
    if (rchId.present) {
      map['rch_id'] = Variable<String>(rchId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (recoveryPhone.present) {
      map['recovery_phone'] = Variable<String>(recoveryPhone.value);
    }
    if (recoveryEmail.present) {
      map['recovery_email'] = Variable<String>(recoveryEmail.value);
    }
    if (lmpDate.present) {
      map['lmp_date'] = Variable<DateTime>(lmpDate.value);
    }
    if (averagePeriodDuration.present) {
      map['average_period_duration'] = Variable<double>(
        averagePeriodDuration.value,
      );
    }
    if (averageCycle.present) {
      map['average_cycle'] = Variable<double>(averageCycle.value);
    }
    if (cycleType.present) {
      map['cycle_type'] = Variable<String>(cycleType.value);
    }
    if (edDate.present) {
      map['ed_date'] = Variable<DateTime>(edDate.value);
    }
    if (pregnancyStatus.present) {
      map['pregnancy_status'] = Variable<String>(pregnancyStatus.value);
    }
    if (lastDeliveryDate.present) {
      map['last_delivery_date'] = Variable<DateTime>(lastDeliveryDate.value);
    }
    if (healthStatus.present) {
      map['health_status'] = Variable<String>(healthStatus.value);
    }
    if (allowFamilyAccess.present) {
      map['allow_family_access'] = Variable<bool>(allowFamilyAccess.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthDataTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('height: $height, ')
          ..write('weight: $weight, ')
          ..write('bloodGroup: $bloodGroup, ')
          ..write('allergies: $allergies, ')
          ..write('medicalConditions: $medicalConditions, ')
          ..write('rchId: $rchId, ')
          ..write('createdAt: $createdAt, ')
          ..write('recoveryPhone: $recoveryPhone, ')
          ..write('recoveryEmail: $recoveryEmail, ')
          ..write('lmpDate: $lmpDate, ')
          ..write('averagePeriodDuration: $averagePeriodDuration, ')
          ..write('averageCycle: $averageCycle, ')
          ..write('cycleType: $cycleType, ')
          ..write('edDate: $edDate, ')
          ..write('pregnancyStatus: $pregnancyStatus, ')
          ..write('lastDeliveryDate: $lastDeliveryDate, ')
          ..write('healthStatus: $healthStatus, ')
          ..write('allowFamilyAccess: $allowFamilyAccess, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CycleHistoriesTable extends CycleHistories
    with TableInfo<$CycleHistoriesTable, CycleHistory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CycleHistoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _healthIdMeta = const VerificationMeta(
    'healthId',
  );
  @override
  late final GeneratedColumn<String> healthId = GeneratedColumn<String>(
    'health_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cycleStartDateMeta = const VerificationMeta(
    'cycleStartDate',
  );
  @override
  late final GeneratedColumn<DateTime> cycleStartDate =
      GeneratedColumn<DateTime>(
        'cycle_start_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _cycleEndDateMeta = const VerificationMeta(
    'cycleEndDate',
  );
  @override
  late final GeneratedColumn<DateTime> cycleEndDate = GeneratedColumn<DateTime>(
    'cycle_end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cycleTypeMeta = const VerificationMeta(
    'cycleType',
  );
  @override
  late final GeneratedColumn<String> cycleType = GeneratedColumn<String>(
    'cycle_type',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    healthId,
    cycleStartDate,
    cycleEndDate,
    cycleType,
    createdAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cycle_histories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CycleHistory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('health_id')) {
      context.handle(
        _healthIdMeta,
        healthId.isAcceptableOrUnknown(data['health_id']!, _healthIdMeta),
      );
    }
    if (data.containsKey('cycle_start_date')) {
      context.handle(
        _cycleStartDateMeta,
        cycleStartDate.isAcceptableOrUnknown(
          data['cycle_start_date']!,
          _cycleStartDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cycleStartDateMeta);
    }
    if (data.containsKey('cycle_end_date')) {
      context.handle(
        _cycleEndDateMeta,
        cycleEndDate.isAcceptableOrUnknown(
          data['cycle_end_date']!,
          _cycleEndDateMeta,
        ),
      );
    }
    if (data.containsKey('cycle_type')) {
      context.handle(
        _cycleTypeMeta,
        cycleType.isAcceptableOrUnknown(data['cycle_type']!, _cycleTypeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CycleHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CycleHistory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      healthId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_id'],
      ),
      cycleStartDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cycle_start_date'],
      )!,
      cycleEndDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cycle_end_date'],
      ),
      cycleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_type'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $CycleHistoriesTable createAlias(String alias) {
    return $CycleHistoriesTable(attachedDatabase, alias);
  }
}

class CycleHistory extends DataClass implements Insertable<CycleHistory> {
  final String id;
  final String? healthId;
  final DateTime cycleStartDate;
  final DateTime? cycleEndDate;
  final String? cycleType;
  final DateTime createdAt;
  final int synced;
  const CycleHistory({
    required this.id,
    this.healthId,
    required this.cycleStartDate,
    this.cycleEndDate,
    this.cycleType,
    required this.createdAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || healthId != null) {
      map['health_id'] = Variable<String>(healthId);
    }
    map['cycle_start_date'] = Variable<DateTime>(cycleStartDate);
    if (!nullToAbsent || cycleEndDate != null) {
      map['cycle_end_date'] = Variable<DateTime>(cycleEndDate);
    }
    if (!nullToAbsent || cycleType != null) {
      map['cycle_type'] = Variable<String>(cycleType);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  CycleHistoriesCompanion toCompanion(bool nullToAbsent) {
    return CycleHistoriesCompanion(
      id: Value(id),
      healthId: healthId == null && nullToAbsent
          ? const Value.absent()
          : Value(healthId),
      cycleStartDate: Value(cycleStartDate),
      cycleEndDate: cycleEndDate == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleEndDate),
      cycleType: cycleType == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleType),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory CycleHistory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CycleHistory(
      id: serializer.fromJson<String>(json['id']),
      healthId: serializer.fromJson<String?>(json['healthId']),
      cycleStartDate: serializer.fromJson<DateTime>(json['cycleStartDate']),
      cycleEndDate: serializer.fromJson<DateTime?>(json['cycleEndDate']),
      cycleType: serializer.fromJson<String?>(json['cycleType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'healthId': serializer.toJson<String?>(healthId),
      'cycleStartDate': serializer.toJson<DateTime>(cycleStartDate),
      'cycleEndDate': serializer.toJson<DateTime?>(cycleEndDate),
      'cycleType': serializer.toJson<String?>(cycleType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  CycleHistory copyWith({
    String? id,
    Value<String?> healthId = const Value.absent(),
    DateTime? cycleStartDate,
    Value<DateTime?> cycleEndDate = const Value.absent(),
    Value<String?> cycleType = const Value.absent(),
    DateTime? createdAt,
    int? synced,
  }) => CycleHistory(
    id: id ?? this.id,
    healthId: healthId.present ? healthId.value : this.healthId,
    cycleStartDate: cycleStartDate ?? this.cycleStartDate,
    cycleEndDate: cycleEndDate.present ? cycleEndDate.value : this.cycleEndDate,
    cycleType: cycleType.present ? cycleType.value : this.cycleType,
    createdAt: createdAt ?? this.createdAt,
    synced: synced ?? this.synced,
  );
  CycleHistory copyWithCompanion(CycleHistoriesCompanion data) {
    return CycleHistory(
      id: data.id.present ? data.id.value : this.id,
      healthId: data.healthId.present ? data.healthId.value : this.healthId,
      cycleStartDate: data.cycleStartDate.present
          ? data.cycleStartDate.value
          : this.cycleStartDate,
      cycleEndDate: data.cycleEndDate.present
          ? data.cycleEndDate.value
          : this.cycleEndDate,
      cycleType: data.cycleType.present ? data.cycleType.value : this.cycleType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CycleHistory(')
          ..write('id: $id, ')
          ..write('healthId: $healthId, ')
          ..write('cycleStartDate: $cycleStartDate, ')
          ..write('cycleEndDate: $cycleEndDate, ')
          ..write('cycleType: $cycleType, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    healthId,
    cycleStartDate,
    cycleEndDate,
    cycleType,
    createdAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CycleHistory &&
          other.id == this.id &&
          other.healthId == this.healthId &&
          other.cycleStartDate == this.cycleStartDate &&
          other.cycleEndDate == this.cycleEndDate &&
          other.cycleType == this.cycleType &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class CycleHistoriesCompanion extends UpdateCompanion<CycleHistory> {
  final Value<String> id;
  final Value<String?> healthId;
  final Value<DateTime> cycleStartDate;
  final Value<DateTime?> cycleEndDate;
  final Value<String?> cycleType;
  final Value<DateTime> createdAt;
  final Value<int> synced;
  final Value<int> rowid;
  const CycleHistoriesCompanion({
    this.id = const Value.absent(),
    this.healthId = const Value.absent(),
    this.cycleStartDate = const Value.absent(),
    this.cycleEndDate = const Value.absent(),
    this.cycleType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CycleHistoriesCompanion.insert({
    required String id,
    this.healthId = const Value.absent(),
    required DateTime cycleStartDate,
    this.cycleEndDate = const Value.absent(),
    this.cycleType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cycleStartDate = Value(cycleStartDate);
  static Insertable<CycleHistory> custom({
    Expression<String>? id,
    Expression<String>? healthId,
    Expression<DateTime>? cycleStartDate,
    Expression<DateTime>? cycleEndDate,
    Expression<String>? cycleType,
    Expression<DateTime>? createdAt,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (healthId != null) 'health_id': healthId,
      if (cycleStartDate != null) 'cycle_start_date': cycleStartDate,
      if (cycleEndDate != null) 'cycle_end_date': cycleEndDate,
      if (cycleType != null) 'cycle_type': cycleType,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CycleHistoriesCompanion copyWith({
    Value<String>? id,
    Value<String?>? healthId,
    Value<DateTime>? cycleStartDate,
    Value<DateTime?>? cycleEndDate,
    Value<String?>? cycleType,
    Value<DateTime>? createdAt,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return CycleHistoriesCompanion(
      id: id ?? this.id,
      healthId: healthId ?? this.healthId,
      cycleStartDate: cycleStartDate ?? this.cycleStartDate,
      cycleEndDate: cycleEndDate ?? this.cycleEndDate,
      cycleType: cycleType ?? this.cycleType,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (healthId.present) {
      map['health_id'] = Variable<String>(healthId.value);
    }
    if (cycleStartDate.present) {
      map['cycle_start_date'] = Variable<DateTime>(cycleStartDate.value);
    }
    if (cycleEndDate.present) {
      map['cycle_end_date'] = Variable<DateTime>(cycleEndDate.value);
    }
    if (cycleType.present) {
      map['cycle_type'] = Variable<String>(cycleType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CycleHistoriesCompanion(')
          ..write('id: $id, ')
          ..write('healthId: $healthId, ')
          ..write('cycleStartDate: $cycleStartDate, ')
          ..write('cycleEndDate: $cycleEndDate, ')
          ..write('cycleType: $cycleType, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PregnanciesTable extends Pregnancies
    with TableInfo<$PregnanciesTable, Pregnancy> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PregnanciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lmpDateMeta = const VerificationMeta(
    'lmpDate',
  );
  @override
  late final GeneratedColumn<DateTime> lmpDate = GeneratedColumn<DateTime>(
    'lmp_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _edDateMeta = const VerificationMeta('edDate');
  @override
  late final GeneratedColumn<DateTime> edDate = GeneratedColumn<DateTime>(
    'ed_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _healthIdMeta = const VerificationMeta(
    'healthId',
  );
  @override
  late final GeneratedColumn<String> healthId = GeneratedColumn<String>(
    'health_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deliveryDateMeta = const VerificationMeta(
    'deliveryDate',
  );
  @override
  late final GeneratedColumn<DateTime> deliveryDate = GeneratedColumn<DateTime>(
    'delivery_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rchIdMeta = const VerificationMeta('rchId');
  @override
  late final GeneratedColumn<String> rchId = GeneratedColumn<String>(
    'rch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _registerWithin12WeeksMeta =
      const VerificationMeta('registerWithin12Weeks');
  @override
  late final GeneratedColumn<bool> registerWithin12Weeks =
      GeneratedColumn<bool>(
        'register_within12_weeks',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("register_within12_weeks" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _highestRiskStatusMeta = const VerificationMeta(
    'highestRiskStatus',
  );
  @override
  late final GeneratedColumn<String> highestRiskStatus =
      GeneratedColumn<String>(
        'highest_risk_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _allFlaggedComplicationsMeta =
      const VerificationMeta('allFlaggedComplications');
  @override
  late final GeneratedColumn<String> allFlaggedComplications =
      GeneratedColumn<String>(
        'all_flagged_complications',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _riskStatusMeta = const VerificationMeta(
    'riskStatus',
  );
  @override
  late final GeneratedColumn<String> riskStatus = GeneratedColumn<String>(
    'risk_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _flaggedComplicationsMeta =
      const VerificationMeta('flaggedComplications');
  @override
  late final GeneratedColumn<String> flaggedComplications =
      GeneratedColumn<String>(
        'flagged_complications',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _overallHealthMeta = const VerificationMeta(
    'overallHealth',
  );
  @override
  late final GeneratedColumn<String> overallHealth = GeneratedColumn<String>(
    'overall_health',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _methodOfConceptionMeta =
      const VerificationMeta('methodOfConception');
  @override
  late final GeneratedColumn<String> methodOfConception =
      GeneratedColumn<String>(
        'method_of_conception',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _gravidityMeta = const VerificationMeta(
    'gravidity',
  );
  @override
  late final GeneratedColumn<int> gravidity = GeneratedColumn<int>(
    'gravidity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _parityMeta = const VerificationMeta('parity');
  @override
  late final GeneratedColumn<int> parity = GeneratedColumn<int>(
    'parity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _livingChildrenMeta = const VerificationMeta(
    'livingChildren',
  );
  @override
  late final GeneratedColumn<int> livingChildren = GeneratedColumn<int>(
    'living_children',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _abortionsMeta = const VerificationMeta(
    'abortions',
  );
  @override
  late final GeneratedColumn<int> abortions = GeneratedColumn<int>(
    'abortions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stillBirthsMeta = const VerificationMeta(
    'stillBirths',
  );
  @override
  late final GeneratedColumn<int> stillBirths = GeneratedColumn<int>(
    'still_births',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _miscarriagesMeta = const VerificationMeta(
    'miscarriages',
  );
  @override
  late final GeneratedColumn<int> miscarriages = GeneratedColumn<int>(
    'miscarriages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _csectionDeliveriesMeta =
      const VerificationMeta('csectionDeliveries');
  @override
  late final GeneratedColumn<int> csectionDeliveries = GeneratedColumn<int>(
    'csection_deliveries',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _obstetricCodeMeta = const VerificationMeta(
    'obstetricCode',
  );
  @override
  late final GeneratedColumn<String> obstetricCode = GeneratedColumn<String>(
    'obstetric_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mrmbsEligibleMeta = const VerificationMeta(
    'mrmbsEligible',
  );
  @override
  late final GeneratedColumn<bool> mrmbsEligible = GeneratedColumn<bool>(
    'mrmbs_eligible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("mrmbs_eligible" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _motherAgeMeta = const VerificationMeta(
    'motherAge',
  );
  @override
  late final GeneratedColumn<int> motherAge = GeneratedColumn<int>(
    'mother_age',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatherAgeMeta = const VerificationMeta(
    'fatherAge',
  );
  @override
  late final GeneratedColumn<int> fatherAge = GeneratedColumn<int>(
    'father_age',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
  static const VerificationMeta _deliveryConductedAtMeta =
      const VerificationMeta('deliveryConductedAt');
  @override
  late final GeneratedColumn<String> deliveryConductedAt =
      GeneratedColumn<String>(
        'delivery_conducted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _admittedAtMeta = const VerificationMeta(
    'admittedAt',
  );
  @override
  late final GeneratedColumn<DateTime> admittedAt = GeneratedColumn<DateTime>(
    'admitted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dischargedAtMeta = const VerificationMeta(
    'dischargedAt',
  );
  @override
  late final GeneratedColumn<DateTime> dischargedAt = GeneratedColumn<DateTime>(
    'discharged_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deceasedAtMeta = const VerificationMeta(
    'deceasedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deceasedAt = GeneratedColumn<DateTime>(
    'deceased_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _causeOfDeathMeta = const VerificationMeta(
    'causeOfDeath',
  );
  @override
  late final GeneratedColumn<String> causeOfDeath = GeneratedColumn<String>(
    'cause_of_death',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lmpDate,
    edDate,
    healthId,
    deliveryDate,
    rchId,
    status,
    createdBy,
    registerWithin12Weeks,
    highestRiskStatus,
    allFlaggedComplications,
    riskStatus,
    flaggedComplications,
    overallHealth,
    methodOfConception,
    gravidity,
    parity,
    livingChildren,
    abortions,
    stillBirths,
    miscarriages,
    csectionDeliveries,
    obstetricCode,
    mrmbsEligible,
    motherAge,
    fatherAge,
    createdAt,
    completedAt,
    deliveryConductedAt,
    admittedAt,
    dischargedAt,
    deceasedAt,
    causeOfDeath,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pregnancies';
  @override
  VerificationContext validateIntegrity(
    Insertable<Pregnancy> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lmp_date')) {
      context.handle(
        _lmpDateMeta,
        lmpDate.isAcceptableOrUnknown(data['lmp_date']!, _lmpDateMeta),
      );
    }
    if (data.containsKey('ed_date')) {
      context.handle(
        _edDateMeta,
        edDate.isAcceptableOrUnknown(data['ed_date']!, _edDateMeta),
      );
    }
    if (data.containsKey('health_id')) {
      context.handle(
        _healthIdMeta,
        healthId.isAcceptableOrUnknown(data['health_id']!, _healthIdMeta),
      );
    }
    if (data.containsKey('delivery_date')) {
      context.handle(
        _deliveryDateMeta,
        deliveryDate.isAcceptableOrUnknown(
          data['delivery_date']!,
          _deliveryDateMeta,
        ),
      );
    }
    if (data.containsKey('rch_id')) {
      context.handle(
        _rchIdMeta,
        rchId.isAcceptableOrUnknown(data['rch_id']!, _rchIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('register_within12_weeks')) {
      context.handle(
        _registerWithin12WeeksMeta,
        registerWithin12Weeks.isAcceptableOrUnknown(
          data['register_within12_weeks']!,
          _registerWithin12WeeksMeta,
        ),
      );
    }
    if (data.containsKey('highest_risk_status')) {
      context.handle(
        _highestRiskStatusMeta,
        highestRiskStatus.isAcceptableOrUnknown(
          data['highest_risk_status']!,
          _highestRiskStatusMeta,
        ),
      );
    }
    if (data.containsKey('all_flagged_complications')) {
      context.handle(
        _allFlaggedComplicationsMeta,
        allFlaggedComplications.isAcceptableOrUnknown(
          data['all_flagged_complications']!,
          _allFlaggedComplicationsMeta,
        ),
      );
    }
    if (data.containsKey('risk_status')) {
      context.handle(
        _riskStatusMeta,
        riskStatus.isAcceptableOrUnknown(data['risk_status']!, _riskStatusMeta),
      );
    }
    if (data.containsKey('flagged_complications')) {
      context.handle(
        _flaggedComplicationsMeta,
        flaggedComplications.isAcceptableOrUnknown(
          data['flagged_complications']!,
          _flaggedComplicationsMeta,
        ),
      );
    }
    if (data.containsKey('overall_health')) {
      context.handle(
        _overallHealthMeta,
        overallHealth.isAcceptableOrUnknown(
          data['overall_health']!,
          _overallHealthMeta,
        ),
      );
    }
    if (data.containsKey('method_of_conception')) {
      context.handle(
        _methodOfConceptionMeta,
        methodOfConception.isAcceptableOrUnknown(
          data['method_of_conception']!,
          _methodOfConceptionMeta,
        ),
      );
    }
    if (data.containsKey('gravidity')) {
      context.handle(
        _gravidityMeta,
        gravidity.isAcceptableOrUnknown(data['gravidity']!, _gravidityMeta),
      );
    }
    if (data.containsKey('parity')) {
      context.handle(
        _parityMeta,
        parity.isAcceptableOrUnknown(data['parity']!, _parityMeta),
      );
    }
    if (data.containsKey('living_children')) {
      context.handle(
        _livingChildrenMeta,
        livingChildren.isAcceptableOrUnknown(
          data['living_children']!,
          _livingChildrenMeta,
        ),
      );
    }
    if (data.containsKey('abortions')) {
      context.handle(
        _abortionsMeta,
        abortions.isAcceptableOrUnknown(data['abortions']!, _abortionsMeta),
      );
    }
    if (data.containsKey('still_births')) {
      context.handle(
        _stillBirthsMeta,
        stillBirths.isAcceptableOrUnknown(
          data['still_births']!,
          _stillBirthsMeta,
        ),
      );
    }
    if (data.containsKey('miscarriages')) {
      context.handle(
        _miscarriagesMeta,
        miscarriages.isAcceptableOrUnknown(
          data['miscarriages']!,
          _miscarriagesMeta,
        ),
      );
    }
    if (data.containsKey('csection_deliveries')) {
      context.handle(
        _csectionDeliveriesMeta,
        csectionDeliveries.isAcceptableOrUnknown(
          data['csection_deliveries']!,
          _csectionDeliveriesMeta,
        ),
      );
    }
    if (data.containsKey('obstetric_code')) {
      context.handle(
        _obstetricCodeMeta,
        obstetricCode.isAcceptableOrUnknown(
          data['obstetric_code']!,
          _obstetricCodeMeta,
        ),
      );
    }
    if (data.containsKey('mrmbs_eligible')) {
      context.handle(
        _mrmbsEligibleMeta,
        mrmbsEligible.isAcceptableOrUnknown(
          data['mrmbs_eligible']!,
          _mrmbsEligibleMeta,
        ),
      );
    }
    if (data.containsKey('mother_age')) {
      context.handle(
        _motherAgeMeta,
        motherAge.isAcceptableOrUnknown(data['mother_age']!, _motherAgeMeta),
      );
    }
    if (data.containsKey('father_age')) {
      context.handle(
        _fatherAgeMeta,
        fatherAge.isAcceptableOrUnknown(data['father_age']!, _fatherAgeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
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
    if (data.containsKey('delivery_conducted_at')) {
      context.handle(
        _deliveryConductedAtMeta,
        deliveryConductedAt.isAcceptableOrUnknown(
          data['delivery_conducted_at']!,
          _deliveryConductedAtMeta,
        ),
      );
    }
    if (data.containsKey('admitted_at')) {
      context.handle(
        _admittedAtMeta,
        admittedAt.isAcceptableOrUnknown(data['admitted_at']!, _admittedAtMeta),
      );
    }
    if (data.containsKey('discharged_at')) {
      context.handle(
        _dischargedAtMeta,
        dischargedAt.isAcceptableOrUnknown(
          data['discharged_at']!,
          _dischargedAtMeta,
        ),
      );
    }
    if (data.containsKey('deceased_at')) {
      context.handle(
        _deceasedAtMeta,
        deceasedAt.isAcceptableOrUnknown(data['deceased_at']!, _deceasedAtMeta),
      );
    }
    if (data.containsKey('cause_of_death')) {
      context.handle(
        _causeOfDeathMeta,
        causeOfDeath.isAcceptableOrUnknown(
          data['cause_of_death']!,
          _causeOfDeathMeta,
        ),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Pregnancy map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pregnancy(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lmpDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}lmp_date'],
      ),
      edDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ed_date'],
      ),
      healthId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_id'],
      ),
      deliveryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}delivery_date'],
      ),
      rchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rch_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      registerWithin12Weeks: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}register_within12_weeks'],
      )!,
      highestRiskStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}highest_risk_status'],
      ),
      allFlaggedComplications: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}all_flagged_complications'],
      ),
      riskStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}risk_status'],
      ),
      flaggedComplications: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flagged_complications'],
      ),
      overallHealth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overall_health'],
      ),
      methodOfConception: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method_of_conception'],
      ),
      gravidity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gravidity'],
      )!,
      parity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parity'],
      )!,
      livingChildren: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}living_children'],
      )!,
      abortions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}abortions'],
      )!,
      stillBirths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}still_births'],
      )!,
      miscarriages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}miscarriages'],
      )!,
      csectionDeliveries: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}csection_deliveries'],
      )!,
      obstetricCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}obstetric_code'],
      ),
      mrmbsEligible: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}mrmbs_eligible'],
      )!,
      motherAge: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mother_age'],
      ),
      fatherAge: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}father_age'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      deliveryConductedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_conducted_at'],
      ),
      admittedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}admitted_at'],
      ),
      dischargedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}discharged_at'],
      ),
      deceasedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deceased_at'],
      ),
      causeOfDeath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cause_of_death'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $PregnanciesTable createAlias(String alias) {
    return $PregnanciesTable(attachedDatabase, alias);
  }
}

class Pregnancy extends DataClass implements Insertable<Pregnancy> {
  final String id;
  final DateTime? lmpDate;
  final DateTime? edDate;
  final String? healthId;
  final DateTime? deliveryDate;
  final String? rchId;
  final String status;
  final String? createdBy;
  final bool registerWithin12Weeks;
  final String? highestRiskStatus;
  final String? allFlaggedComplications;
  final String? riskStatus;
  final String? flaggedComplications;
  final String? overallHealth;
  final String? methodOfConception;
  final int gravidity;
  final int parity;
  final int livingChildren;
  final int abortions;
  final int stillBirths;
  final int miscarriages;
  final int csectionDeliveries;
  final String? obstetricCode;
  final bool mrmbsEligible;
  final int? motherAge;
  final int? fatherAge;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? deliveryConductedAt;
  final DateTime? admittedAt;
  final DateTime? dischargedAt;
  final DateTime? deceasedAt;
  final String? causeOfDeath;
  final int synced;
  const Pregnancy({
    required this.id,
    this.lmpDate,
    this.edDate,
    this.healthId,
    this.deliveryDate,
    this.rchId,
    required this.status,
    this.createdBy,
    required this.registerWithin12Weeks,
    this.highestRiskStatus,
    this.allFlaggedComplications,
    this.riskStatus,
    this.flaggedComplications,
    this.overallHealth,
    this.methodOfConception,
    required this.gravidity,
    required this.parity,
    required this.livingChildren,
    required this.abortions,
    required this.stillBirths,
    required this.miscarriages,
    required this.csectionDeliveries,
    this.obstetricCode,
    required this.mrmbsEligible,
    this.motherAge,
    this.fatherAge,
    required this.createdAt,
    this.completedAt,
    this.deliveryConductedAt,
    this.admittedAt,
    this.dischargedAt,
    this.deceasedAt,
    this.causeOfDeath,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || lmpDate != null) {
      map['lmp_date'] = Variable<DateTime>(lmpDate);
    }
    if (!nullToAbsent || edDate != null) {
      map['ed_date'] = Variable<DateTime>(edDate);
    }
    if (!nullToAbsent || healthId != null) {
      map['health_id'] = Variable<String>(healthId);
    }
    if (!nullToAbsent || deliveryDate != null) {
      map['delivery_date'] = Variable<DateTime>(deliveryDate);
    }
    if (!nullToAbsent || rchId != null) {
      map['rch_id'] = Variable<String>(rchId);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['register_within12_weeks'] = Variable<bool>(registerWithin12Weeks);
    if (!nullToAbsent || highestRiskStatus != null) {
      map['highest_risk_status'] = Variable<String>(highestRiskStatus);
    }
    if (!nullToAbsent || allFlaggedComplications != null) {
      map['all_flagged_complications'] = Variable<String>(
        allFlaggedComplications,
      );
    }
    if (!nullToAbsent || riskStatus != null) {
      map['risk_status'] = Variable<String>(riskStatus);
    }
    if (!nullToAbsent || flaggedComplications != null) {
      map['flagged_complications'] = Variable<String>(flaggedComplications);
    }
    if (!nullToAbsent || overallHealth != null) {
      map['overall_health'] = Variable<String>(overallHealth);
    }
    if (!nullToAbsent || methodOfConception != null) {
      map['method_of_conception'] = Variable<String>(methodOfConception);
    }
    map['gravidity'] = Variable<int>(gravidity);
    map['parity'] = Variable<int>(parity);
    map['living_children'] = Variable<int>(livingChildren);
    map['abortions'] = Variable<int>(abortions);
    map['still_births'] = Variable<int>(stillBirths);
    map['miscarriages'] = Variable<int>(miscarriages);
    map['csection_deliveries'] = Variable<int>(csectionDeliveries);
    if (!nullToAbsent || obstetricCode != null) {
      map['obstetric_code'] = Variable<String>(obstetricCode);
    }
    map['mrmbs_eligible'] = Variable<bool>(mrmbsEligible);
    if (!nullToAbsent || motherAge != null) {
      map['mother_age'] = Variable<int>(motherAge);
    }
    if (!nullToAbsent || fatherAge != null) {
      map['father_age'] = Variable<int>(fatherAge);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || deliveryConductedAt != null) {
      map['delivery_conducted_at'] = Variable<String>(deliveryConductedAt);
    }
    if (!nullToAbsent || admittedAt != null) {
      map['admitted_at'] = Variable<DateTime>(admittedAt);
    }
    if (!nullToAbsent || dischargedAt != null) {
      map['discharged_at'] = Variable<DateTime>(dischargedAt);
    }
    if (!nullToAbsent || deceasedAt != null) {
      map['deceased_at'] = Variable<DateTime>(deceasedAt);
    }
    if (!nullToAbsent || causeOfDeath != null) {
      map['cause_of_death'] = Variable<String>(causeOfDeath);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  PregnanciesCompanion toCompanion(bool nullToAbsent) {
    return PregnanciesCompanion(
      id: Value(id),
      lmpDate: lmpDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lmpDate),
      edDate: edDate == null && nullToAbsent
          ? const Value.absent()
          : Value(edDate),
      healthId: healthId == null && nullToAbsent
          ? const Value.absent()
          : Value(healthId),
      deliveryDate: deliveryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryDate),
      rchId: rchId == null && nullToAbsent
          ? const Value.absent()
          : Value(rchId),
      status: Value(status),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      registerWithin12Weeks: Value(registerWithin12Weeks),
      highestRiskStatus: highestRiskStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(highestRiskStatus),
      allFlaggedComplications: allFlaggedComplications == null && nullToAbsent
          ? const Value.absent()
          : Value(allFlaggedComplications),
      riskStatus: riskStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(riskStatus),
      flaggedComplications: flaggedComplications == null && nullToAbsent
          ? const Value.absent()
          : Value(flaggedComplications),
      overallHealth: overallHealth == null && nullToAbsent
          ? const Value.absent()
          : Value(overallHealth),
      methodOfConception: methodOfConception == null && nullToAbsent
          ? const Value.absent()
          : Value(methodOfConception),
      gravidity: Value(gravidity),
      parity: Value(parity),
      livingChildren: Value(livingChildren),
      abortions: Value(abortions),
      stillBirths: Value(stillBirths),
      miscarriages: Value(miscarriages),
      csectionDeliveries: Value(csectionDeliveries),
      obstetricCode: obstetricCode == null && nullToAbsent
          ? const Value.absent()
          : Value(obstetricCode),
      mrmbsEligible: Value(mrmbsEligible),
      motherAge: motherAge == null && nullToAbsent
          ? const Value.absent()
          : Value(motherAge),
      fatherAge: fatherAge == null && nullToAbsent
          ? const Value.absent()
          : Value(fatherAge),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      deliveryConductedAt: deliveryConductedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryConductedAt),
      admittedAt: admittedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(admittedAt),
      dischargedAt: dischargedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dischargedAt),
      deceasedAt: deceasedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deceasedAt),
      causeOfDeath: causeOfDeath == null && nullToAbsent
          ? const Value.absent()
          : Value(causeOfDeath),
      synced: Value(synced),
    );
  }

  factory Pregnancy.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pregnancy(
      id: serializer.fromJson<String>(json['id']),
      lmpDate: serializer.fromJson<DateTime?>(json['lmpDate']),
      edDate: serializer.fromJson<DateTime?>(json['edDate']),
      healthId: serializer.fromJson<String?>(json['healthId']),
      deliveryDate: serializer.fromJson<DateTime?>(json['deliveryDate']),
      rchId: serializer.fromJson<String?>(json['rchId']),
      status: serializer.fromJson<String>(json['status']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      registerWithin12Weeks: serializer.fromJson<bool>(
        json['registerWithin12Weeks'],
      ),
      highestRiskStatus: serializer.fromJson<String?>(
        json['highestRiskStatus'],
      ),
      allFlaggedComplications: serializer.fromJson<String?>(
        json['allFlaggedComplications'],
      ),
      riskStatus: serializer.fromJson<String?>(json['riskStatus']),
      flaggedComplications: serializer.fromJson<String?>(
        json['flaggedComplications'],
      ),
      overallHealth: serializer.fromJson<String?>(json['overallHealth']),
      methodOfConception: serializer.fromJson<String?>(
        json['methodOfConception'],
      ),
      gravidity: serializer.fromJson<int>(json['gravidity']),
      parity: serializer.fromJson<int>(json['parity']),
      livingChildren: serializer.fromJson<int>(json['livingChildren']),
      abortions: serializer.fromJson<int>(json['abortions']),
      stillBirths: serializer.fromJson<int>(json['stillBirths']),
      miscarriages: serializer.fromJson<int>(json['miscarriages']),
      csectionDeliveries: serializer.fromJson<int>(json['csectionDeliveries']),
      obstetricCode: serializer.fromJson<String?>(json['obstetricCode']),
      mrmbsEligible: serializer.fromJson<bool>(json['mrmbsEligible']),
      motherAge: serializer.fromJson<int?>(json['motherAge']),
      fatherAge: serializer.fromJson<int?>(json['fatherAge']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      deliveryConductedAt: serializer.fromJson<String?>(
        json['deliveryConductedAt'],
      ),
      admittedAt: serializer.fromJson<DateTime?>(json['admittedAt']),
      dischargedAt: serializer.fromJson<DateTime?>(json['dischargedAt']),
      deceasedAt: serializer.fromJson<DateTime?>(json['deceasedAt']),
      causeOfDeath: serializer.fromJson<String?>(json['causeOfDeath']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lmpDate': serializer.toJson<DateTime?>(lmpDate),
      'edDate': serializer.toJson<DateTime?>(edDate),
      'healthId': serializer.toJson<String?>(healthId),
      'deliveryDate': serializer.toJson<DateTime?>(deliveryDate),
      'rchId': serializer.toJson<String?>(rchId),
      'status': serializer.toJson<String>(status),
      'createdBy': serializer.toJson<String?>(createdBy),
      'registerWithin12Weeks': serializer.toJson<bool>(registerWithin12Weeks),
      'highestRiskStatus': serializer.toJson<String?>(highestRiskStatus),
      'allFlaggedComplications': serializer.toJson<String?>(
        allFlaggedComplications,
      ),
      'riskStatus': serializer.toJson<String?>(riskStatus),
      'flaggedComplications': serializer.toJson<String?>(flaggedComplications),
      'overallHealth': serializer.toJson<String?>(overallHealth),
      'methodOfConception': serializer.toJson<String?>(methodOfConception),
      'gravidity': serializer.toJson<int>(gravidity),
      'parity': serializer.toJson<int>(parity),
      'livingChildren': serializer.toJson<int>(livingChildren),
      'abortions': serializer.toJson<int>(abortions),
      'stillBirths': serializer.toJson<int>(stillBirths),
      'miscarriages': serializer.toJson<int>(miscarriages),
      'csectionDeliveries': serializer.toJson<int>(csectionDeliveries),
      'obstetricCode': serializer.toJson<String?>(obstetricCode),
      'mrmbsEligible': serializer.toJson<bool>(mrmbsEligible),
      'motherAge': serializer.toJson<int?>(motherAge),
      'fatherAge': serializer.toJson<int?>(fatherAge),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'deliveryConductedAt': serializer.toJson<String?>(deliveryConductedAt),
      'admittedAt': serializer.toJson<DateTime?>(admittedAt),
      'dischargedAt': serializer.toJson<DateTime?>(dischargedAt),
      'deceasedAt': serializer.toJson<DateTime?>(deceasedAt),
      'causeOfDeath': serializer.toJson<String?>(causeOfDeath),
      'synced': serializer.toJson<int>(synced),
    };
  }

  Pregnancy copyWith({
    String? id,
    Value<DateTime?> lmpDate = const Value.absent(),
    Value<DateTime?> edDate = const Value.absent(),
    Value<String?> healthId = const Value.absent(),
    Value<DateTime?> deliveryDate = const Value.absent(),
    Value<String?> rchId = const Value.absent(),
    String? status,
    Value<String?> createdBy = const Value.absent(),
    bool? registerWithin12Weeks,
    Value<String?> highestRiskStatus = const Value.absent(),
    Value<String?> allFlaggedComplications = const Value.absent(),
    Value<String?> riskStatus = const Value.absent(),
    Value<String?> flaggedComplications = const Value.absent(),
    Value<String?> overallHealth = const Value.absent(),
    Value<String?> methodOfConception = const Value.absent(),
    int? gravidity,
    int? parity,
    int? livingChildren,
    int? abortions,
    int? stillBirths,
    int? miscarriages,
    int? csectionDeliveries,
    Value<String?> obstetricCode = const Value.absent(),
    bool? mrmbsEligible,
    Value<int?> motherAge = const Value.absent(),
    Value<int?> fatherAge = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> deliveryConductedAt = const Value.absent(),
    Value<DateTime?> admittedAt = const Value.absent(),
    Value<DateTime?> dischargedAt = const Value.absent(),
    Value<DateTime?> deceasedAt = const Value.absent(),
    Value<String?> causeOfDeath = const Value.absent(),
    int? synced,
  }) => Pregnancy(
    id: id ?? this.id,
    lmpDate: lmpDate.present ? lmpDate.value : this.lmpDate,
    edDate: edDate.present ? edDate.value : this.edDate,
    healthId: healthId.present ? healthId.value : this.healthId,
    deliveryDate: deliveryDate.present ? deliveryDate.value : this.deliveryDate,
    rchId: rchId.present ? rchId.value : this.rchId,
    status: status ?? this.status,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    registerWithin12Weeks: registerWithin12Weeks ?? this.registerWithin12Weeks,
    highestRiskStatus: highestRiskStatus.present
        ? highestRiskStatus.value
        : this.highestRiskStatus,
    allFlaggedComplications: allFlaggedComplications.present
        ? allFlaggedComplications.value
        : this.allFlaggedComplications,
    riskStatus: riskStatus.present ? riskStatus.value : this.riskStatus,
    flaggedComplications: flaggedComplications.present
        ? flaggedComplications.value
        : this.flaggedComplications,
    overallHealth: overallHealth.present
        ? overallHealth.value
        : this.overallHealth,
    methodOfConception: methodOfConception.present
        ? methodOfConception.value
        : this.methodOfConception,
    gravidity: gravidity ?? this.gravidity,
    parity: parity ?? this.parity,
    livingChildren: livingChildren ?? this.livingChildren,
    abortions: abortions ?? this.abortions,
    stillBirths: stillBirths ?? this.stillBirths,
    miscarriages: miscarriages ?? this.miscarriages,
    csectionDeliveries: csectionDeliveries ?? this.csectionDeliveries,
    obstetricCode: obstetricCode.present
        ? obstetricCode.value
        : this.obstetricCode,
    mrmbsEligible: mrmbsEligible ?? this.mrmbsEligible,
    motherAge: motherAge.present ? motherAge.value : this.motherAge,
    fatherAge: fatherAge.present ? fatherAge.value : this.fatherAge,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    deliveryConductedAt: deliveryConductedAt.present
        ? deliveryConductedAt.value
        : this.deliveryConductedAt,
    admittedAt: admittedAt.present ? admittedAt.value : this.admittedAt,
    dischargedAt: dischargedAt.present ? dischargedAt.value : this.dischargedAt,
    deceasedAt: deceasedAt.present ? deceasedAt.value : this.deceasedAt,
    causeOfDeath: causeOfDeath.present ? causeOfDeath.value : this.causeOfDeath,
    synced: synced ?? this.synced,
  );
  Pregnancy copyWithCompanion(PregnanciesCompanion data) {
    return Pregnancy(
      id: data.id.present ? data.id.value : this.id,
      lmpDate: data.lmpDate.present ? data.lmpDate.value : this.lmpDate,
      edDate: data.edDate.present ? data.edDate.value : this.edDate,
      healthId: data.healthId.present ? data.healthId.value : this.healthId,
      deliveryDate: data.deliveryDate.present
          ? data.deliveryDate.value
          : this.deliveryDate,
      rchId: data.rchId.present ? data.rchId.value : this.rchId,
      status: data.status.present ? data.status.value : this.status,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      registerWithin12Weeks: data.registerWithin12Weeks.present
          ? data.registerWithin12Weeks.value
          : this.registerWithin12Weeks,
      highestRiskStatus: data.highestRiskStatus.present
          ? data.highestRiskStatus.value
          : this.highestRiskStatus,
      allFlaggedComplications: data.allFlaggedComplications.present
          ? data.allFlaggedComplications.value
          : this.allFlaggedComplications,
      riskStatus: data.riskStatus.present
          ? data.riskStatus.value
          : this.riskStatus,
      flaggedComplications: data.flaggedComplications.present
          ? data.flaggedComplications.value
          : this.flaggedComplications,
      overallHealth: data.overallHealth.present
          ? data.overallHealth.value
          : this.overallHealth,
      methodOfConception: data.methodOfConception.present
          ? data.methodOfConception.value
          : this.methodOfConception,
      gravidity: data.gravidity.present ? data.gravidity.value : this.gravidity,
      parity: data.parity.present ? data.parity.value : this.parity,
      livingChildren: data.livingChildren.present
          ? data.livingChildren.value
          : this.livingChildren,
      abortions: data.abortions.present ? data.abortions.value : this.abortions,
      stillBirths: data.stillBirths.present
          ? data.stillBirths.value
          : this.stillBirths,
      miscarriages: data.miscarriages.present
          ? data.miscarriages.value
          : this.miscarriages,
      csectionDeliveries: data.csectionDeliveries.present
          ? data.csectionDeliveries.value
          : this.csectionDeliveries,
      obstetricCode: data.obstetricCode.present
          ? data.obstetricCode.value
          : this.obstetricCode,
      mrmbsEligible: data.mrmbsEligible.present
          ? data.mrmbsEligible.value
          : this.mrmbsEligible,
      motherAge: data.motherAge.present ? data.motherAge.value : this.motherAge,
      fatherAge: data.fatherAge.present ? data.fatherAge.value : this.fatherAge,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      deliveryConductedAt: data.deliveryConductedAt.present
          ? data.deliveryConductedAt.value
          : this.deliveryConductedAt,
      admittedAt: data.admittedAt.present
          ? data.admittedAt.value
          : this.admittedAt,
      dischargedAt: data.dischargedAt.present
          ? data.dischargedAt.value
          : this.dischargedAt,
      deceasedAt: data.deceasedAt.present
          ? data.deceasedAt.value
          : this.deceasedAt,
      causeOfDeath: data.causeOfDeath.present
          ? data.causeOfDeath.value
          : this.causeOfDeath,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pregnancy(')
          ..write('id: $id, ')
          ..write('lmpDate: $lmpDate, ')
          ..write('edDate: $edDate, ')
          ..write('healthId: $healthId, ')
          ..write('deliveryDate: $deliveryDate, ')
          ..write('rchId: $rchId, ')
          ..write('status: $status, ')
          ..write('createdBy: $createdBy, ')
          ..write('registerWithin12Weeks: $registerWithin12Weeks, ')
          ..write('highestRiskStatus: $highestRiskStatus, ')
          ..write('allFlaggedComplications: $allFlaggedComplications, ')
          ..write('riskStatus: $riskStatus, ')
          ..write('flaggedComplications: $flaggedComplications, ')
          ..write('overallHealth: $overallHealth, ')
          ..write('methodOfConception: $methodOfConception, ')
          ..write('gravidity: $gravidity, ')
          ..write('parity: $parity, ')
          ..write('livingChildren: $livingChildren, ')
          ..write('abortions: $abortions, ')
          ..write('stillBirths: $stillBirths, ')
          ..write('miscarriages: $miscarriages, ')
          ..write('csectionDeliveries: $csectionDeliveries, ')
          ..write('obstetricCode: $obstetricCode, ')
          ..write('mrmbsEligible: $mrmbsEligible, ')
          ..write('motherAge: $motherAge, ')
          ..write('fatherAge: $fatherAge, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('deliveryConductedAt: $deliveryConductedAt, ')
          ..write('admittedAt: $admittedAt, ')
          ..write('dischargedAt: $dischargedAt, ')
          ..write('deceasedAt: $deceasedAt, ')
          ..write('causeOfDeath: $causeOfDeath, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    lmpDate,
    edDate,
    healthId,
    deliveryDate,
    rchId,
    status,
    createdBy,
    registerWithin12Weeks,
    highestRiskStatus,
    allFlaggedComplications,
    riskStatus,
    flaggedComplications,
    overallHealth,
    methodOfConception,
    gravidity,
    parity,
    livingChildren,
    abortions,
    stillBirths,
    miscarriages,
    csectionDeliveries,
    obstetricCode,
    mrmbsEligible,
    motherAge,
    fatherAge,
    createdAt,
    completedAt,
    deliveryConductedAt,
    admittedAt,
    dischargedAt,
    deceasedAt,
    causeOfDeath,
    synced,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pregnancy &&
          other.id == this.id &&
          other.lmpDate == this.lmpDate &&
          other.edDate == this.edDate &&
          other.healthId == this.healthId &&
          other.deliveryDate == this.deliveryDate &&
          other.rchId == this.rchId &&
          other.status == this.status &&
          other.createdBy == this.createdBy &&
          other.registerWithin12Weeks == this.registerWithin12Weeks &&
          other.highestRiskStatus == this.highestRiskStatus &&
          other.allFlaggedComplications == this.allFlaggedComplications &&
          other.riskStatus == this.riskStatus &&
          other.flaggedComplications == this.flaggedComplications &&
          other.overallHealth == this.overallHealth &&
          other.methodOfConception == this.methodOfConception &&
          other.gravidity == this.gravidity &&
          other.parity == this.parity &&
          other.livingChildren == this.livingChildren &&
          other.abortions == this.abortions &&
          other.stillBirths == this.stillBirths &&
          other.miscarriages == this.miscarriages &&
          other.csectionDeliveries == this.csectionDeliveries &&
          other.obstetricCode == this.obstetricCode &&
          other.mrmbsEligible == this.mrmbsEligible &&
          other.motherAge == this.motherAge &&
          other.fatherAge == this.fatherAge &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.deliveryConductedAt == this.deliveryConductedAt &&
          other.admittedAt == this.admittedAt &&
          other.dischargedAt == this.dischargedAt &&
          other.deceasedAt == this.deceasedAt &&
          other.causeOfDeath == this.causeOfDeath &&
          other.synced == this.synced);
}

class PregnanciesCompanion extends UpdateCompanion<Pregnancy> {
  final Value<String> id;
  final Value<DateTime?> lmpDate;
  final Value<DateTime?> edDate;
  final Value<String?> healthId;
  final Value<DateTime?> deliveryDate;
  final Value<String?> rchId;
  final Value<String> status;
  final Value<String?> createdBy;
  final Value<bool> registerWithin12Weeks;
  final Value<String?> highestRiskStatus;
  final Value<String?> allFlaggedComplications;
  final Value<String?> riskStatus;
  final Value<String?> flaggedComplications;
  final Value<String?> overallHealth;
  final Value<String?> methodOfConception;
  final Value<int> gravidity;
  final Value<int> parity;
  final Value<int> livingChildren;
  final Value<int> abortions;
  final Value<int> stillBirths;
  final Value<int> miscarriages;
  final Value<int> csectionDeliveries;
  final Value<String?> obstetricCode;
  final Value<bool> mrmbsEligible;
  final Value<int?> motherAge;
  final Value<int?> fatherAge;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  final Value<String?> deliveryConductedAt;
  final Value<DateTime?> admittedAt;
  final Value<DateTime?> dischargedAt;
  final Value<DateTime?> deceasedAt;
  final Value<String?> causeOfDeath;
  final Value<int> synced;
  final Value<int> rowid;
  const PregnanciesCompanion({
    this.id = const Value.absent(),
    this.lmpDate = const Value.absent(),
    this.edDate = const Value.absent(),
    this.healthId = const Value.absent(),
    this.deliveryDate = const Value.absent(),
    this.rchId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.registerWithin12Weeks = const Value.absent(),
    this.highestRiskStatus = const Value.absent(),
    this.allFlaggedComplications = const Value.absent(),
    this.riskStatus = const Value.absent(),
    this.flaggedComplications = const Value.absent(),
    this.overallHealth = const Value.absent(),
    this.methodOfConception = const Value.absent(),
    this.gravidity = const Value.absent(),
    this.parity = const Value.absent(),
    this.livingChildren = const Value.absent(),
    this.abortions = const Value.absent(),
    this.stillBirths = const Value.absent(),
    this.miscarriages = const Value.absent(),
    this.csectionDeliveries = const Value.absent(),
    this.obstetricCode = const Value.absent(),
    this.mrmbsEligible = const Value.absent(),
    this.motherAge = const Value.absent(),
    this.fatherAge = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.deliveryConductedAt = const Value.absent(),
    this.admittedAt = const Value.absent(),
    this.dischargedAt = const Value.absent(),
    this.deceasedAt = const Value.absent(),
    this.causeOfDeath = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PregnanciesCompanion.insert({
    required String id,
    this.lmpDate = const Value.absent(),
    this.edDate = const Value.absent(),
    this.healthId = const Value.absent(),
    this.deliveryDate = const Value.absent(),
    this.rchId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.registerWithin12Weeks = const Value.absent(),
    this.highestRiskStatus = const Value.absent(),
    this.allFlaggedComplications = const Value.absent(),
    this.riskStatus = const Value.absent(),
    this.flaggedComplications = const Value.absent(),
    this.overallHealth = const Value.absent(),
    this.methodOfConception = const Value.absent(),
    this.gravidity = const Value.absent(),
    this.parity = const Value.absent(),
    this.livingChildren = const Value.absent(),
    this.abortions = const Value.absent(),
    this.stillBirths = const Value.absent(),
    this.miscarriages = const Value.absent(),
    this.csectionDeliveries = const Value.absent(),
    this.obstetricCode = const Value.absent(),
    this.mrmbsEligible = const Value.absent(),
    this.motherAge = const Value.absent(),
    this.fatherAge = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.deliveryConductedAt = const Value.absent(),
    this.admittedAt = const Value.absent(),
    this.dischargedAt = const Value.absent(),
    this.deceasedAt = const Value.absent(),
    this.causeOfDeath = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Pregnancy> custom({
    Expression<String>? id,
    Expression<DateTime>? lmpDate,
    Expression<DateTime>? edDate,
    Expression<String>? healthId,
    Expression<DateTime>? deliveryDate,
    Expression<String>? rchId,
    Expression<String>? status,
    Expression<String>? createdBy,
    Expression<bool>? registerWithin12Weeks,
    Expression<String>? highestRiskStatus,
    Expression<String>? allFlaggedComplications,
    Expression<String>? riskStatus,
    Expression<String>? flaggedComplications,
    Expression<String>? overallHealth,
    Expression<String>? methodOfConception,
    Expression<int>? gravidity,
    Expression<int>? parity,
    Expression<int>? livingChildren,
    Expression<int>? abortions,
    Expression<int>? stillBirths,
    Expression<int>? miscarriages,
    Expression<int>? csectionDeliveries,
    Expression<String>? obstetricCode,
    Expression<bool>? mrmbsEligible,
    Expression<int>? motherAge,
    Expression<int>? fatherAge,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<String>? deliveryConductedAt,
    Expression<DateTime>? admittedAt,
    Expression<DateTime>? dischargedAt,
    Expression<DateTime>? deceasedAt,
    Expression<String>? causeOfDeath,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lmpDate != null) 'lmp_date': lmpDate,
      if (edDate != null) 'ed_date': edDate,
      if (healthId != null) 'health_id': healthId,
      if (deliveryDate != null) 'delivery_date': deliveryDate,
      if (rchId != null) 'rch_id': rchId,
      if (status != null) 'status': status,
      if (createdBy != null) 'created_by': createdBy,
      if (registerWithin12Weeks != null)
        'register_within12_weeks': registerWithin12Weeks,
      if (highestRiskStatus != null) 'highest_risk_status': highestRiskStatus,
      if (allFlaggedComplications != null)
        'all_flagged_complications': allFlaggedComplications,
      if (riskStatus != null) 'risk_status': riskStatus,
      if (flaggedComplications != null)
        'flagged_complications': flaggedComplications,
      if (overallHealth != null) 'overall_health': overallHealth,
      if (methodOfConception != null)
        'method_of_conception': methodOfConception,
      if (gravidity != null) 'gravidity': gravidity,
      if (parity != null) 'parity': parity,
      if (livingChildren != null) 'living_children': livingChildren,
      if (abortions != null) 'abortions': abortions,
      if (stillBirths != null) 'still_births': stillBirths,
      if (miscarriages != null) 'miscarriages': miscarriages,
      if (csectionDeliveries != null) 'csection_deliveries': csectionDeliveries,
      if (obstetricCode != null) 'obstetric_code': obstetricCode,
      if (mrmbsEligible != null) 'mrmbs_eligible': mrmbsEligible,
      if (motherAge != null) 'mother_age': motherAge,
      if (fatherAge != null) 'father_age': fatherAge,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (deliveryConductedAt != null)
        'delivery_conducted_at': deliveryConductedAt,
      if (admittedAt != null) 'admitted_at': admittedAt,
      if (dischargedAt != null) 'discharged_at': dischargedAt,
      if (deceasedAt != null) 'deceased_at': deceasedAt,
      if (causeOfDeath != null) 'cause_of_death': causeOfDeath,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PregnanciesCompanion copyWith({
    Value<String>? id,
    Value<DateTime?>? lmpDate,
    Value<DateTime?>? edDate,
    Value<String?>? healthId,
    Value<DateTime?>? deliveryDate,
    Value<String?>? rchId,
    Value<String>? status,
    Value<String?>? createdBy,
    Value<bool>? registerWithin12Weeks,
    Value<String?>? highestRiskStatus,
    Value<String?>? allFlaggedComplications,
    Value<String?>? riskStatus,
    Value<String?>? flaggedComplications,
    Value<String?>? overallHealth,
    Value<String?>? methodOfConception,
    Value<int>? gravidity,
    Value<int>? parity,
    Value<int>? livingChildren,
    Value<int>? abortions,
    Value<int>? stillBirths,
    Value<int>? miscarriages,
    Value<int>? csectionDeliveries,
    Value<String?>? obstetricCode,
    Value<bool>? mrmbsEligible,
    Value<int?>? motherAge,
    Value<int?>? fatherAge,
    Value<DateTime>? createdAt,
    Value<DateTime?>? completedAt,
    Value<String?>? deliveryConductedAt,
    Value<DateTime?>? admittedAt,
    Value<DateTime?>? dischargedAt,
    Value<DateTime?>? deceasedAt,
    Value<String?>? causeOfDeath,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return PregnanciesCompanion(
      id: id ?? this.id,
      lmpDate: lmpDate ?? this.lmpDate,
      edDate: edDate ?? this.edDate,
      healthId: healthId ?? this.healthId,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      rchId: rchId ?? this.rchId,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      registerWithin12Weeks:
          registerWithin12Weeks ?? this.registerWithin12Weeks,
      highestRiskStatus: highestRiskStatus ?? this.highestRiskStatus,
      allFlaggedComplications:
          allFlaggedComplications ?? this.allFlaggedComplications,
      riskStatus: riskStatus ?? this.riskStatus,
      flaggedComplications: flaggedComplications ?? this.flaggedComplications,
      overallHealth: overallHealth ?? this.overallHealth,
      methodOfConception: methodOfConception ?? this.methodOfConception,
      gravidity: gravidity ?? this.gravidity,
      parity: parity ?? this.parity,
      livingChildren: livingChildren ?? this.livingChildren,
      abortions: abortions ?? this.abortions,
      stillBirths: stillBirths ?? this.stillBirths,
      miscarriages: miscarriages ?? this.miscarriages,
      csectionDeliveries: csectionDeliveries ?? this.csectionDeliveries,
      obstetricCode: obstetricCode ?? this.obstetricCode,
      mrmbsEligible: mrmbsEligible ?? this.mrmbsEligible,
      motherAge: motherAge ?? this.motherAge,
      fatherAge: fatherAge ?? this.fatherAge,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      deliveryConductedAt: deliveryConductedAt ?? this.deliveryConductedAt,
      admittedAt: admittedAt ?? this.admittedAt,
      dischargedAt: dischargedAt ?? this.dischargedAt,
      deceasedAt: deceasedAt ?? this.deceasedAt,
      causeOfDeath: causeOfDeath ?? this.causeOfDeath,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lmpDate.present) {
      map['lmp_date'] = Variable<DateTime>(lmpDate.value);
    }
    if (edDate.present) {
      map['ed_date'] = Variable<DateTime>(edDate.value);
    }
    if (healthId.present) {
      map['health_id'] = Variable<String>(healthId.value);
    }
    if (deliveryDate.present) {
      map['delivery_date'] = Variable<DateTime>(deliveryDate.value);
    }
    if (rchId.present) {
      map['rch_id'] = Variable<String>(rchId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (registerWithin12Weeks.present) {
      map['register_within12_weeks'] = Variable<bool>(
        registerWithin12Weeks.value,
      );
    }
    if (highestRiskStatus.present) {
      map['highest_risk_status'] = Variable<String>(highestRiskStatus.value);
    }
    if (allFlaggedComplications.present) {
      map['all_flagged_complications'] = Variable<String>(
        allFlaggedComplications.value,
      );
    }
    if (riskStatus.present) {
      map['risk_status'] = Variable<String>(riskStatus.value);
    }
    if (flaggedComplications.present) {
      map['flagged_complications'] = Variable<String>(
        flaggedComplications.value,
      );
    }
    if (overallHealth.present) {
      map['overall_health'] = Variable<String>(overallHealth.value);
    }
    if (methodOfConception.present) {
      map['method_of_conception'] = Variable<String>(methodOfConception.value);
    }
    if (gravidity.present) {
      map['gravidity'] = Variable<int>(gravidity.value);
    }
    if (parity.present) {
      map['parity'] = Variable<int>(parity.value);
    }
    if (livingChildren.present) {
      map['living_children'] = Variable<int>(livingChildren.value);
    }
    if (abortions.present) {
      map['abortions'] = Variable<int>(abortions.value);
    }
    if (stillBirths.present) {
      map['still_births'] = Variable<int>(stillBirths.value);
    }
    if (miscarriages.present) {
      map['miscarriages'] = Variable<int>(miscarriages.value);
    }
    if (csectionDeliveries.present) {
      map['csection_deliveries'] = Variable<int>(csectionDeliveries.value);
    }
    if (obstetricCode.present) {
      map['obstetric_code'] = Variable<String>(obstetricCode.value);
    }
    if (mrmbsEligible.present) {
      map['mrmbs_eligible'] = Variable<bool>(mrmbsEligible.value);
    }
    if (motherAge.present) {
      map['mother_age'] = Variable<int>(motherAge.value);
    }
    if (fatherAge.present) {
      map['father_age'] = Variable<int>(fatherAge.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (deliveryConductedAt.present) {
      map['delivery_conducted_at'] = Variable<String>(
        deliveryConductedAt.value,
      );
    }
    if (admittedAt.present) {
      map['admitted_at'] = Variable<DateTime>(admittedAt.value);
    }
    if (dischargedAt.present) {
      map['discharged_at'] = Variable<DateTime>(dischargedAt.value);
    }
    if (deceasedAt.present) {
      map['deceased_at'] = Variable<DateTime>(deceasedAt.value);
    }
    if (causeOfDeath.present) {
      map['cause_of_death'] = Variable<String>(causeOfDeath.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PregnanciesCompanion(')
          ..write('id: $id, ')
          ..write('lmpDate: $lmpDate, ')
          ..write('edDate: $edDate, ')
          ..write('healthId: $healthId, ')
          ..write('deliveryDate: $deliveryDate, ')
          ..write('rchId: $rchId, ')
          ..write('status: $status, ')
          ..write('createdBy: $createdBy, ')
          ..write('registerWithin12Weeks: $registerWithin12Weeks, ')
          ..write('highestRiskStatus: $highestRiskStatus, ')
          ..write('allFlaggedComplications: $allFlaggedComplications, ')
          ..write('riskStatus: $riskStatus, ')
          ..write('flaggedComplications: $flaggedComplications, ')
          ..write('overallHealth: $overallHealth, ')
          ..write('methodOfConception: $methodOfConception, ')
          ..write('gravidity: $gravidity, ')
          ..write('parity: $parity, ')
          ..write('livingChildren: $livingChildren, ')
          ..write('abortions: $abortions, ')
          ..write('stillBirths: $stillBirths, ')
          ..write('miscarriages: $miscarriages, ')
          ..write('csectionDeliveries: $csectionDeliveries, ')
          ..write('obstetricCode: $obstetricCode, ')
          ..write('mrmbsEligible: $mrmbsEligible, ')
          ..write('motherAge: $motherAge, ')
          ..write('fatherAge: $fatherAge, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('deliveryConductedAt: $deliveryConductedAt, ')
          ..write('admittedAt: $admittedAt, ')
          ..write('dischargedAt: $dischargedAt, ')
          ..write('deceasedAt: $deceasedAt, ')
          ..write('causeOfDeath: $causeOfDeath, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrescriptionsTable extends Prescriptions
    with TableInfo<$PrescriptionsTable, Prescription> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrescriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _healthIdMeta = const VerificationMeta(
    'healthId',
  );
  @override
  late final GeneratedColumn<String> healthId = GeneratedColumn<String>(
    'health_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _driveFileIdMeta = const VerificationMeta(
    'driveFileId',
  );
  @override
  late final GeneratedColumn<String> driveFileId = GeneratedColumn<String>(
    'drive_file_id',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    healthId,
    description,
    imageUrl,
    driveFileId,
    createdAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prescriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Prescription> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('health_id')) {
      context.handle(
        _healthIdMeta,
        healthId.isAcceptableOrUnknown(data['health_id']!, _healthIdMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('drive_file_id')) {
      context.handle(
        _driveFileIdMeta,
        driveFileId.isAcceptableOrUnknown(
          data['drive_file_id']!,
          _driveFileIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Prescription map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Prescription(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      healthId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_id'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      driveFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}drive_file_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $PrescriptionsTable createAlias(String alias) {
    return $PrescriptionsTable(attachedDatabase, alias);
  }
}

class Prescription extends DataClass implements Insertable<Prescription> {
  final String id;
  final String? healthId;
  final String description;
  final String? imageUrl;
  final String? driveFileId;
  final DateTime createdAt;
  final int synced;
  const Prescription({
    required this.id,
    this.healthId,
    required this.description,
    this.imageUrl,
    this.driveFileId,
    required this.createdAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || healthId != null) {
      map['health_id'] = Variable<String>(healthId);
    }
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || driveFileId != null) {
      map['drive_file_id'] = Variable<String>(driveFileId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  PrescriptionsCompanion toCompanion(bool nullToAbsent) {
    return PrescriptionsCompanion(
      id: Value(id),
      healthId: healthId == null && nullToAbsent
          ? const Value.absent()
          : Value(healthId),
      description: Value(description),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      driveFileId: driveFileId == null && nullToAbsent
          ? const Value.absent()
          : Value(driveFileId),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory Prescription.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Prescription(
      id: serializer.fromJson<String>(json['id']),
      healthId: serializer.fromJson<String?>(json['healthId']),
      description: serializer.fromJson<String>(json['description']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      driveFileId: serializer.fromJson<String?>(json['driveFileId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'healthId': serializer.toJson<String?>(healthId),
      'description': serializer.toJson<String>(description),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'driveFileId': serializer.toJson<String?>(driveFileId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  Prescription copyWith({
    String? id,
    Value<String?> healthId = const Value.absent(),
    String? description,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> driveFileId = const Value.absent(),
    DateTime? createdAt,
    int? synced,
  }) => Prescription(
    id: id ?? this.id,
    healthId: healthId.present ? healthId.value : this.healthId,
    description: description ?? this.description,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    driveFileId: driveFileId.present ? driveFileId.value : this.driveFileId,
    createdAt: createdAt ?? this.createdAt,
    synced: synced ?? this.synced,
  );
  Prescription copyWithCompanion(PrescriptionsCompanion data) {
    return Prescription(
      id: data.id.present ? data.id.value : this.id,
      healthId: data.healthId.present ? data.healthId.value : this.healthId,
      description: data.description.present
          ? data.description.value
          : this.description,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      driveFileId: data.driveFileId.present
          ? data.driveFileId.value
          : this.driveFileId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Prescription(')
          ..write('id: $id, ')
          ..write('healthId: $healthId, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('driveFileId: $driveFileId, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    healthId,
    description,
    imageUrl,
    driveFileId,
    createdAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Prescription &&
          other.id == this.id &&
          other.healthId == this.healthId &&
          other.description == this.description &&
          other.imageUrl == this.imageUrl &&
          other.driveFileId == this.driveFileId &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class PrescriptionsCompanion extends UpdateCompanion<Prescription> {
  final Value<String> id;
  final Value<String?> healthId;
  final Value<String> description;
  final Value<String?> imageUrl;
  final Value<String?> driveFileId;
  final Value<DateTime> createdAt;
  final Value<int> synced;
  final Value<int> rowid;
  const PrescriptionsCompanion({
    this.id = const Value.absent(),
    this.healthId = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.driveFileId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrescriptionsCompanion.insert({
    required String id,
    this.healthId = const Value.absent(),
    required String description,
    this.imageUrl = const Value.absent(),
    this.driveFileId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       description = Value(description);
  static Insertable<Prescription> custom({
    Expression<String>? id,
    Expression<String>? healthId,
    Expression<String>? description,
    Expression<String>? imageUrl,
    Expression<String>? driveFileId,
    Expression<DateTime>? createdAt,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (healthId != null) 'health_id': healthId,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (driveFileId != null) 'drive_file_id': driveFileId,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrescriptionsCompanion copyWith({
    Value<String>? id,
    Value<String?>? healthId,
    Value<String>? description,
    Value<String?>? imageUrl,
    Value<String?>? driveFileId,
    Value<DateTime>? createdAt,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return PrescriptionsCompanion(
      id: id ?? this.id,
      healthId: healthId ?? this.healthId,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      driveFileId: driveFileId ?? this.driveFileId,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (healthId.present) {
      map['health_id'] = Variable<String>(healthId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (driveFileId.present) {
      map['drive_file_id'] = Variable<String>(driveFileId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrescriptionsCompanion(')
          ..write('id: $id, ')
          ..write('healthId: $healthId, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('driveFileId: $driveFileId, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrescriptionMedicinesTable extends PrescriptionMedicines
    with TableInfo<$PrescriptionMedicinesTable, PrescriptionMedicine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrescriptionMedicinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prescriptionIdMeta = const VerificationMeta(
    'prescriptionId',
  );
  @override
  late final GeneratedColumn<String> prescriptionId = GeneratedColumn<String>(
    'prescription_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _medicineNameMeta = const VerificationMeta(
    'medicineName',
  );
  @override
  late final GeneratedColumn<String> medicineName = GeneratedColumn<String>(
    'medicine_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dosageMeta = const VerificationMeta('dosage');
  @override
  late final GeneratedColumn<String> dosage = GeneratedColumn<String>(
    'dosage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timingsMeta = const VerificationMeta(
    'timings',
  );
  @override
  late final GeneratedColumn<String> timings = GeneratedColumn<String>(
    'timings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationDaysMeta = const VerificationMeta(
    'durationDays',
  );
  @override
  late final GeneratedColumn<int> durationDays = GeneratedColumn<int>(
    'duration_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _healthIdMeta = const VerificationMeta(
    'healthId',
  );
  @override
  late final GeneratedColumn<String> healthId = GeneratedColumn<String>(
    'health_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderConfigMeta = const VerificationMeta(
    'reminderConfig',
  );
  @override
  late final GeneratedColumn<String> reminderConfig = GeneratedColumn<String>(
    'reminder_config',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    prescriptionId,
    medicineName,
    dosage,
    timings,
    durationDays,
    notes,
    healthId,
    userId,
    reminderConfig,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prescription_medicines';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrescriptionMedicine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('prescription_id')) {
      context.handle(
        _prescriptionIdMeta,
        prescriptionId.isAcceptableOrUnknown(
          data['prescription_id']!,
          _prescriptionIdMeta,
        ),
      );
    }
    if (data.containsKey('medicine_name')) {
      context.handle(
        _medicineNameMeta,
        medicineName.isAcceptableOrUnknown(
          data['medicine_name']!,
          _medicineNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicineNameMeta);
    }
    if (data.containsKey('dosage')) {
      context.handle(
        _dosageMeta,
        dosage.isAcceptableOrUnknown(data['dosage']!, _dosageMeta),
      );
    } else if (isInserting) {
      context.missing(_dosageMeta);
    }
    if (data.containsKey('timings')) {
      context.handle(
        _timingsMeta,
        timings.isAcceptableOrUnknown(data['timings']!, _timingsMeta),
      );
    } else if (isInserting) {
      context.missing(_timingsMeta);
    }
    if (data.containsKey('duration_days')) {
      context.handle(
        _durationDaysMeta,
        durationDays.isAcceptableOrUnknown(
          data['duration_days']!,
          _durationDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationDaysMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('health_id')) {
      context.handle(
        _healthIdMeta,
        healthId.isAcceptableOrUnknown(data['health_id']!, _healthIdMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('reminder_config')) {
      context.handle(
        _reminderConfigMeta,
        reminderConfig.isAcceptableOrUnknown(
          data['reminder_config']!,
          _reminderConfigMeta,
        ),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrescriptionMedicine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrescriptionMedicine(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      prescriptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prescription_id'],
      ),
      medicineName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medicine_name'],
      )!,
      dosage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dosage'],
      )!,
      timings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timings'],
      )!,
      durationDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_days'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      healthId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      reminderConfig: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_config'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $PrescriptionMedicinesTable createAlias(String alias) {
    return $PrescriptionMedicinesTable(attachedDatabase, alias);
  }
}

class PrescriptionMedicine extends DataClass
    implements Insertable<PrescriptionMedicine> {
  final String id;
  final String? prescriptionId;
  final String medicineName;
  final String dosage;
  final String timings;
  final int durationDays;
  final String? notes;
  final String? healthId;
  final String? userId;
  final String? reminderConfig;
  final int synced;
  const PrescriptionMedicine({
    required this.id,
    this.prescriptionId,
    required this.medicineName,
    required this.dosage,
    required this.timings,
    required this.durationDays,
    this.notes,
    this.healthId,
    this.userId,
    this.reminderConfig,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || prescriptionId != null) {
      map['prescription_id'] = Variable<String>(prescriptionId);
    }
    map['medicine_name'] = Variable<String>(medicineName);
    map['dosage'] = Variable<String>(dosage);
    map['timings'] = Variable<String>(timings);
    map['duration_days'] = Variable<int>(durationDays);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || healthId != null) {
      map['health_id'] = Variable<String>(healthId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || reminderConfig != null) {
      map['reminder_config'] = Variable<String>(reminderConfig);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  PrescriptionMedicinesCompanion toCompanion(bool nullToAbsent) {
    return PrescriptionMedicinesCompanion(
      id: Value(id),
      prescriptionId: prescriptionId == null && nullToAbsent
          ? const Value.absent()
          : Value(prescriptionId),
      medicineName: Value(medicineName),
      dosage: Value(dosage),
      timings: Value(timings),
      durationDays: Value(durationDays),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      healthId: healthId == null && nullToAbsent
          ? const Value.absent()
          : Value(healthId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      reminderConfig: reminderConfig == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderConfig),
      synced: Value(synced),
    );
  }

  factory PrescriptionMedicine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrescriptionMedicine(
      id: serializer.fromJson<String>(json['id']),
      prescriptionId: serializer.fromJson<String?>(json['prescriptionId']),
      medicineName: serializer.fromJson<String>(json['medicineName']),
      dosage: serializer.fromJson<String>(json['dosage']),
      timings: serializer.fromJson<String>(json['timings']),
      durationDays: serializer.fromJson<int>(json['durationDays']),
      notes: serializer.fromJson<String?>(json['notes']),
      healthId: serializer.fromJson<String?>(json['healthId']),
      userId: serializer.fromJson<String?>(json['userId']),
      reminderConfig: serializer.fromJson<String?>(json['reminderConfig']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'prescriptionId': serializer.toJson<String?>(prescriptionId),
      'medicineName': serializer.toJson<String>(medicineName),
      'dosage': serializer.toJson<String>(dosage),
      'timings': serializer.toJson<String>(timings),
      'durationDays': serializer.toJson<int>(durationDays),
      'notes': serializer.toJson<String?>(notes),
      'healthId': serializer.toJson<String?>(healthId),
      'userId': serializer.toJson<String?>(userId),
      'reminderConfig': serializer.toJson<String?>(reminderConfig),
      'synced': serializer.toJson<int>(synced),
    };
  }

  PrescriptionMedicine copyWith({
    String? id,
    Value<String?> prescriptionId = const Value.absent(),
    String? medicineName,
    String? dosage,
    String? timings,
    int? durationDays,
    Value<String?> notes = const Value.absent(),
    Value<String?> healthId = const Value.absent(),
    Value<String?> userId = const Value.absent(),
    Value<String?> reminderConfig = const Value.absent(),
    int? synced,
  }) => PrescriptionMedicine(
    id: id ?? this.id,
    prescriptionId: prescriptionId.present
        ? prescriptionId.value
        : this.prescriptionId,
    medicineName: medicineName ?? this.medicineName,
    dosage: dosage ?? this.dosage,
    timings: timings ?? this.timings,
    durationDays: durationDays ?? this.durationDays,
    notes: notes.present ? notes.value : this.notes,
    healthId: healthId.present ? healthId.value : this.healthId,
    userId: userId.present ? userId.value : this.userId,
    reminderConfig: reminderConfig.present
        ? reminderConfig.value
        : this.reminderConfig,
    synced: synced ?? this.synced,
  );
  PrescriptionMedicine copyWithCompanion(PrescriptionMedicinesCompanion data) {
    return PrescriptionMedicine(
      id: data.id.present ? data.id.value : this.id,
      prescriptionId: data.prescriptionId.present
          ? data.prescriptionId.value
          : this.prescriptionId,
      medicineName: data.medicineName.present
          ? data.medicineName.value
          : this.medicineName,
      dosage: data.dosage.present ? data.dosage.value : this.dosage,
      timings: data.timings.present ? data.timings.value : this.timings,
      durationDays: data.durationDays.present
          ? data.durationDays.value
          : this.durationDays,
      notes: data.notes.present ? data.notes.value : this.notes,
      healthId: data.healthId.present ? data.healthId.value : this.healthId,
      userId: data.userId.present ? data.userId.value : this.userId,
      reminderConfig: data.reminderConfig.present
          ? data.reminderConfig.value
          : this.reminderConfig,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrescriptionMedicine(')
          ..write('id: $id, ')
          ..write('prescriptionId: $prescriptionId, ')
          ..write('medicineName: $medicineName, ')
          ..write('dosage: $dosage, ')
          ..write('timings: $timings, ')
          ..write('durationDays: $durationDays, ')
          ..write('notes: $notes, ')
          ..write('healthId: $healthId, ')
          ..write('userId: $userId, ')
          ..write('reminderConfig: $reminderConfig, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    prescriptionId,
    medicineName,
    dosage,
    timings,
    durationDays,
    notes,
    healthId,
    userId,
    reminderConfig,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrescriptionMedicine &&
          other.id == this.id &&
          other.prescriptionId == this.prescriptionId &&
          other.medicineName == this.medicineName &&
          other.dosage == this.dosage &&
          other.timings == this.timings &&
          other.durationDays == this.durationDays &&
          other.notes == this.notes &&
          other.healthId == this.healthId &&
          other.userId == this.userId &&
          other.reminderConfig == this.reminderConfig &&
          other.synced == this.synced);
}

class PrescriptionMedicinesCompanion
    extends UpdateCompanion<PrescriptionMedicine> {
  final Value<String> id;
  final Value<String?> prescriptionId;
  final Value<String> medicineName;
  final Value<String> dosage;
  final Value<String> timings;
  final Value<int> durationDays;
  final Value<String?> notes;
  final Value<String?> healthId;
  final Value<String?> userId;
  final Value<String?> reminderConfig;
  final Value<int> synced;
  final Value<int> rowid;
  const PrescriptionMedicinesCompanion({
    this.id = const Value.absent(),
    this.prescriptionId = const Value.absent(),
    this.medicineName = const Value.absent(),
    this.dosage = const Value.absent(),
    this.timings = const Value.absent(),
    this.durationDays = const Value.absent(),
    this.notes = const Value.absent(),
    this.healthId = const Value.absent(),
    this.userId = const Value.absent(),
    this.reminderConfig = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrescriptionMedicinesCompanion.insert({
    required String id,
    this.prescriptionId = const Value.absent(),
    required String medicineName,
    required String dosage,
    required String timings,
    required int durationDays,
    this.notes = const Value.absent(),
    this.healthId = const Value.absent(),
    this.userId = const Value.absent(),
    this.reminderConfig = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       medicineName = Value(medicineName),
       dosage = Value(dosage),
       timings = Value(timings),
       durationDays = Value(durationDays);
  static Insertable<PrescriptionMedicine> custom({
    Expression<String>? id,
    Expression<String>? prescriptionId,
    Expression<String>? medicineName,
    Expression<String>? dosage,
    Expression<String>? timings,
    Expression<int>? durationDays,
    Expression<String>? notes,
    Expression<String>? healthId,
    Expression<String>? userId,
    Expression<String>? reminderConfig,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (prescriptionId != null) 'prescription_id': prescriptionId,
      if (medicineName != null) 'medicine_name': medicineName,
      if (dosage != null) 'dosage': dosage,
      if (timings != null) 'timings': timings,
      if (durationDays != null) 'duration_days': durationDays,
      if (notes != null) 'notes': notes,
      if (healthId != null) 'health_id': healthId,
      if (userId != null) 'user_id': userId,
      if (reminderConfig != null) 'reminder_config': reminderConfig,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrescriptionMedicinesCompanion copyWith({
    Value<String>? id,
    Value<String?>? prescriptionId,
    Value<String>? medicineName,
    Value<String>? dosage,
    Value<String>? timings,
    Value<int>? durationDays,
    Value<String?>? notes,
    Value<String?>? healthId,
    Value<String?>? userId,
    Value<String?>? reminderConfig,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return PrescriptionMedicinesCompanion(
      id: id ?? this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      timings: timings ?? this.timings,
      durationDays: durationDays ?? this.durationDays,
      notes: notes ?? this.notes,
      healthId: healthId ?? this.healthId,
      userId: userId ?? this.userId,
      reminderConfig: reminderConfig ?? this.reminderConfig,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (prescriptionId.present) {
      map['prescription_id'] = Variable<String>(prescriptionId.value);
    }
    if (medicineName.present) {
      map['medicine_name'] = Variable<String>(medicineName.value);
    }
    if (dosage.present) {
      map['dosage'] = Variable<String>(dosage.value);
    }
    if (timings.present) {
      map['timings'] = Variable<String>(timings.value);
    }
    if (durationDays.present) {
      map['duration_days'] = Variable<int>(durationDays.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (healthId.present) {
      map['health_id'] = Variable<String>(healthId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (reminderConfig.present) {
      map['reminder_config'] = Variable<String>(reminderConfig.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrescriptionMedicinesCompanion(')
          ..write('id: $id, ')
          ..write('prescriptionId: $prescriptionId, ')
          ..write('medicineName: $medicineName, ')
          ..write('dosage: $dosage, ')
          ..write('timings: $timings, ')
          ..write('durationDays: $durationDays, ')
          ..write('notes: $notes, ')
          ..write('healthId: $healthId, ')
          ..write('userId: $userId, ')
          ..write('reminderConfig: $reminderConfig, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrescriptionMedicineTimingsTable extends PrescriptionMedicineTimings
    with
        TableInfo<
          $PrescriptionMedicineTimingsTable,
          PrescriptionMedicineTiming
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrescriptionMedicineTimingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prescriptionMedicineIdMeta =
      const VerificationMeta('prescriptionMedicineId');
  @override
  late final GeneratedColumn<String> prescriptionMedicineId =
      GeneratedColumn<String>(
        'prescriptionMedicineId',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _timingDateTimeMeta = const VerificationMeta(
    'timingDateTime',
  );
  @override
  late final GeneratedColumn<DateTime> timingDateTime =
      GeneratedColumn<DateTime>(
        'dateTime',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _medicineTakenTimeMeta = const VerificationMeta(
    'medicineTakenTime',
  );
  @override
  late final GeneratedColumn<DateTime> medicineTakenTime =
      GeneratedColumn<DateTime>(
        'medicine_taken_time',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    prescriptionMedicineId,
    timingDateTime,
    medicineTakenTime,
    status,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prescription_medicine_timings';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrescriptionMedicineTiming> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('prescriptionMedicineId')) {
      context.handle(
        _prescriptionMedicineIdMeta,
        prescriptionMedicineId.isAcceptableOrUnknown(
          data['prescriptionMedicineId']!,
          _prescriptionMedicineIdMeta,
        ),
      );
    }
    if (data.containsKey('dateTime')) {
      context.handle(
        _timingDateTimeMeta,
        timingDateTime.isAcceptableOrUnknown(
          data['dateTime']!,
          _timingDateTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timingDateTimeMeta);
    }
    if (data.containsKey('medicine_taken_time')) {
      context.handle(
        _medicineTakenTimeMeta,
        medicineTakenTime.isAcceptableOrUnknown(
          data['medicine_taken_time']!,
          _medicineTakenTimeMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrescriptionMedicineTiming map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrescriptionMedicineTiming(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      prescriptionMedicineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prescriptionMedicineId'],
      ),
      timingDateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dateTime'],
      )!,
      medicineTakenTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}medicine_taken_time'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $PrescriptionMedicineTimingsTable createAlias(String alias) {
    return $PrescriptionMedicineTimingsTable(attachedDatabase, alias);
  }
}

class PrescriptionMedicineTiming extends DataClass
    implements Insertable<PrescriptionMedicineTiming> {
  final String id;
  final String? prescriptionMedicineId;
  final DateTime timingDateTime;
  final DateTime? medicineTakenTime;
  final String status;
  final int synced;
  const PrescriptionMedicineTiming({
    required this.id,
    this.prescriptionMedicineId,
    required this.timingDateTime,
    this.medicineTakenTime,
    required this.status,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || prescriptionMedicineId != null) {
      map['prescriptionMedicineId'] = Variable<String>(prescriptionMedicineId);
    }
    map['dateTime'] = Variable<DateTime>(timingDateTime);
    if (!nullToAbsent || medicineTakenTime != null) {
      map['medicine_taken_time'] = Variable<DateTime>(medicineTakenTime);
    }
    map['status'] = Variable<String>(status);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  PrescriptionMedicineTimingsCompanion toCompanion(bool nullToAbsent) {
    return PrescriptionMedicineTimingsCompanion(
      id: Value(id),
      prescriptionMedicineId: prescriptionMedicineId == null && nullToAbsent
          ? const Value.absent()
          : Value(prescriptionMedicineId),
      timingDateTime: Value(timingDateTime),
      medicineTakenTime: medicineTakenTime == null && nullToAbsent
          ? const Value.absent()
          : Value(medicineTakenTime),
      status: Value(status),
      synced: Value(synced),
    );
  }

  factory PrescriptionMedicineTiming.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrescriptionMedicineTiming(
      id: serializer.fromJson<String>(json['id']),
      prescriptionMedicineId: serializer.fromJson<String?>(
        json['prescriptionMedicineId'],
      ),
      timingDateTime: serializer.fromJson<DateTime>(json['timingDateTime']),
      medicineTakenTime: serializer.fromJson<DateTime?>(
        json['medicineTakenTime'],
      ),
      status: serializer.fromJson<String>(json['status']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'prescriptionMedicineId': serializer.toJson<String?>(
        prescriptionMedicineId,
      ),
      'timingDateTime': serializer.toJson<DateTime>(timingDateTime),
      'medicineTakenTime': serializer.toJson<DateTime?>(medicineTakenTime),
      'status': serializer.toJson<String>(status),
      'synced': serializer.toJson<int>(synced),
    };
  }

  PrescriptionMedicineTiming copyWith({
    String? id,
    Value<String?> prescriptionMedicineId = const Value.absent(),
    DateTime? timingDateTime,
    Value<DateTime?> medicineTakenTime = const Value.absent(),
    String? status,
    int? synced,
  }) => PrescriptionMedicineTiming(
    id: id ?? this.id,
    prescriptionMedicineId: prescriptionMedicineId.present
        ? prescriptionMedicineId.value
        : this.prescriptionMedicineId,
    timingDateTime: timingDateTime ?? this.timingDateTime,
    medicineTakenTime: medicineTakenTime.present
        ? medicineTakenTime.value
        : this.medicineTakenTime,
    status: status ?? this.status,
    synced: synced ?? this.synced,
  );
  PrescriptionMedicineTiming copyWithCompanion(
    PrescriptionMedicineTimingsCompanion data,
  ) {
    return PrescriptionMedicineTiming(
      id: data.id.present ? data.id.value : this.id,
      prescriptionMedicineId: data.prescriptionMedicineId.present
          ? data.prescriptionMedicineId.value
          : this.prescriptionMedicineId,
      timingDateTime: data.timingDateTime.present
          ? data.timingDateTime.value
          : this.timingDateTime,
      medicineTakenTime: data.medicineTakenTime.present
          ? data.medicineTakenTime.value
          : this.medicineTakenTime,
      status: data.status.present ? data.status.value : this.status,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrescriptionMedicineTiming(')
          ..write('id: $id, ')
          ..write('prescriptionMedicineId: $prescriptionMedicineId, ')
          ..write('timingDateTime: $timingDateTime, ')
          ..write('medicineTakenTime: $medicineTakenTime, ')
          ..write('status: $status, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    prescriptionMedicineId,
    timingDateTime,
    medicineTakenTime,
    status,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrescriptionMedicineTiming &&
          other.id == this.id &&
          other.prescriptionMedicineId == this.prescriptionMedicineId &&
          other.timingDateTime == this.timingDateTime &&
          other.medicineTakenTime == this.medicineTakenTime &&
          other.status == this.status &&
          other.synced == this.synced);
}

class PrescriptionMedicineTimingsCompanion
    extends UpdateCompanion<PrescriptionMedicineTiming> {
  final Value<String> id;
  final Value<String?> prescriptionMedicineId;
  final Value<DateTime> timingDateTime;
  final Value<DateTime?> medicineTakenTime;
  final Value<String> status;
  final Value<int> synced;
  final Value<int> rowid;
  const PrescriptionMedicineTimingsCompanion({
    this.id = const Value.absent(),
    this.prescriptionMedicineId = const Value.absent(),
    this.timingDateTime = const Value.absent(),
    this.medicineTakenTime = const Value.absent(),
    this.status = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrescriptionMedicineTimingsCompanion.insert({
    required String id,
    this.prescriptionMedicineId = const Value.absent(),
    required DateTime timingDateTime,
    this.medicineTakenTime = const Value.absent(),
    required String status,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       timingDateTime = Value(timingDateTime),
       status = Value(status);
  static Insertable<PrescriptionMedicineTiming> custom({
    Expression<String>? id,
    Expression<String>? prescriptionMedicineId,
    Expression<DateTime>? timingDateTime,
    Expression<DateTime>? medicineTakenTime,
    Expression<String>? status,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (prescriptionMedicineId != null)
        'prescriptionMedicineId': prescriptionMedicineId,
      if (timingDateTime != null) 'dateTime': timingDateTime,
      if (medicineTakenTime != null) 'medicine_taken_time': medicineTakenTime,
      if (status != null) 'status': status,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrescriptionMedicineTimingsCompanion copyWith({
    Value<String>? id,
    Value<String?>? prescriptionMedicineId,
    Value<DateTime>? timingDateTime,
    Value<DateTime?>? medicineTakenTime,
    Value<String>? status,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return PrescriptionMedicineTimingsCompanion(
      id: id ?? this.id,
      prescriptionMedicineId:
          prescriptionMedicineId ?? this.prescriptionMedicineId,
      timingDateTime: timingDateTime ?? this.timingDateTime,
      medicineTakenTime: medicineTakenTime ?? this.medicineTakenTime,
      status: status ?? this.status,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (prescriptionMedicineId.present) {
      map['prescriptionMedicineId'] = Variable<String>(
        prescriptionMedicineId.value,
      );
    }
    if (timingDateTime.present) {
      map['dateTime'] = Variable<DateTime>(timingDateTime.value);
    }
    if (medicineTakenTime.present) {
      map['medicine_taken_time'] = Variable<DateTime>(medicineTakenTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrescriptionMedicineTimingsCompanion(')
          ..write('id: $id, ')
          ..write('prescriptionMedicineId: $prescriptionMedicineId, ')
          ..write('timingDateTime: $timingDateTime, ')
          ..write('medicineTakenTime: $medicineTakenTime, ')
          ..write('status: $status, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReportsTable extends Reports with TableInfo<$ReportsTable, Report> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reportTypeMeta = const VerificationMeta(
    'reportType',
  );
  @override
  late final GeneratedColumn<String> reportType = GeneratedColumn<String>(
    'report_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _healthDataIDMeta = const VerificationMeta(
    'healthDataID',
  );
  @override
  late final GeneratedColumn<String> healthDataID = GeneratedColumn<String>(
    'healthDataID',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _driveFileIdMeta = const VerificationMeta(
    'driveFileId',
  );
  @override
  late final GeneratedColumn<String> driveFileId = GeneratedColumn<String>(
    'drive_file_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedMeta = const VerificationMeta('saved');
  @override
  late final GeneratedColumn<bool> saved = GeneratedColumn<bool>(
    'saved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("saved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reportType,
    detail,
    healthDataID,
    imageUrl,
    driveFileId,
    description,
    createdAt,
    createdBy,
    saved,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<Report> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('report_type')) {
      context.handle(
        _reportTypeMeta,
        reportType.isAcceptableOrUnknown(data['report_type']!, _reportTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_reportTypeMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    if (data.containsKey('healthDataID')) {
      context.handle(
        _healthDataIDMeta,
        healthDataID.isAcceptableOrUnknown(
          data['healthDataID']!,
          _healthDataIDMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('drive_file_id')) {
      context.handle(
        _driveFileIdMeta,
        driveFileId.isAcceptableOrUnknown(
          data['drive_file_id']!,
          _driveFileIdMeta,
        ),
      );
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('saved')) {
      context.handle(
        _savedMeta,
        saved.isAcceptableOrUnknown(data['saved']!, _savedMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Report map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Report(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      reportType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}report_type'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      ),
      healthDataID: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}healthDataID'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      driveFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}drive_file_id'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      saved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}saved'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $ReportsTable createAlias(String alias) {
    return $ReportsTable(attachedDatabase, alias);
  }
}

class Report extends DataClass implements Insertable<Report> {
  final String id;
  final String reportType;
  final String? detail;
  final String? healthDataID;
  final String? imageUrl;
  final String? driveFileId;
  final String? description;
  final DateTime createdAt;
  final String? createdBy;
  final bool saved;
  final int synced;
  const Report({
    required this.id,
    required this.reportType,
    this.detail,
    this.healthDataID,
    this.imageUrl,
    this.driveFileId,
    this.description,
    required this.createdAt,
    this.createdBy,
    required this.saved,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['report_type'] = Variable<String>(reportType);
    if (!nullToAbsent || detail != null) {
      map['detail'] = Variable<String>(detail);
    }
    if (!nullToAbsent || healthDataID != null) {
      map['healthDataID'] = Variable<String>(healthDataID);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || driveFileId != null) {
      map['drive_file_id'] = Variable<String>(driveFileId);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['saved'] = Variable<bool>(saved);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  ReportsCompanion toCompanion(bool nullToAbsent) {
    return ReportsCompanion(
      id: Value(id),
      reportType: Value(reportType),
      detail: detail == null && nullToAbsent
          ? const Value.absent()
          : Value(detail),
      healthDataID: healthDataID == null && nullToAbsent
          ? const Value.absent()
          : Value(healthDataID),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      driveFileId: driveFileId == null && nullToAbsent
          ? const Value.absent()
          : Value(driveFileId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      saved: Value(saved),
      synced: Value(synced),
    );
  }

  factory Report.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Report(
      id: serializer.fromJson<String>(json['id']),
      reportType: serializer.fromJson<String>(json['reportType']),
      detail: serializer.fromJson<String?>(json['detail']),
      healthDataID: serializer.fromJson<String?>(json['healthDataID']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      driveFileId: serializer.fromJson<String?>(json['driveFileId']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      saved: serializer.fromJson<bool>(json['saved']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'reportType': serializer.toJson<String>(reportType),
      'detail': serializer.toJson<String?>(detail),
      'healthDataID': serializer.toJson<String?>(healthDataID),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'driveFileId': serializer.toJson<String?>(driveFileId),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'saved': serializer.toJson<bool>(saved),
      'synced': serializer.toJson<int>(synced),
    };
  }

  Report copyWith({
    String? id,
    String? reportType,
    Value<String?> detail = const Value.absent(),
    Value<String?> healthDataID = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> driveFileId = const Value.absent(),
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
    Value<String?> createdBy = const Value.absent(),
    bool? saved,
    int? synced,
  }) => Report(
    id: id ?? this.id,
    reportType: reportType ?? this.reportType,
    detail: detail.present ? detail.value : this.detail,
    healthDataID: healthDataID.present ? healthDataID.value : this.healthDataID,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    driveFileId: driveFileId.present ? driveFileId.value : this.driveFileId,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    saved: saved ?? this.saved,
    synced: synced ?? this.synced,
  );
  Report copyWithCompanion(ReportsCompanion data) {
    return Report(
      id: data.id.present ? data.id.value : this.id,
      reportType: data.reportType.present
          ? data.reportType.value
          : this.reportType,
      detail: data.detail.present ? data.detail.value : this.detail,
      healthDataID: data.healthDataID.present
          ? data.healthDataID.value
          : this.healthDataID,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      driveFileId: data.driveFileId.present
          ? data.driveFileId.value
          : this.driveFileId,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      saved: data.saved.present ? data.saved.value : this.saved,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Report(')
          ..write('id: $id, ')
          ..write('reportType: $reportType, ')
          ..write('detail: $detail, ')
          ..write('healthDataID: $healthDataID, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('driveFileId: $driveFileId, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('saved: $saved, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    reportType,
    detail,
    healthDataID,
    imageUrl,
    driveFileId,
    description,
    createdAt,
    createdBy,
    saved,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Report &&
          other.id == this.id &&
          other.reportType == this.reportType &&
          other.detail == this.detail &&
          other.healthDataID == this.healthDataID &&
          other.imageUrl == this.imageUrl &&
          other.driveFileId == this.driveFileId &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.createdBy == this.createdBy &&
          other.saved == this.saved &&
          other.synced == this.synced);
}

class ReportsCompanion extends UpdateCompanion<Report> {
  final Value<String> id;
  final Value<String> reportType;
  final Value<String?> detail;
  final Value<String?> healthDataID;
  final Value<String?> imageUrl;
  final Value<String?> driveFileId;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<String?> createdBy;
  final Value<bool> saved;
  final Value<int> synced;
  final Value<int> rowid;
  const ReportsCompanion({
    this.id = const Value.absent(),
    this.reportType = const Value.absent(),
    this.detail = const Value.absent(),
    this.healthDataID = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.driveFileId = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.saved = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReportsCompanion.insert({
    required String id,
    required String reportType,
    this.detail = const Value.absent(),
    this.healthDataID = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.driveFileId = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.saved = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       reportType = Value(reportType);
  static Insertable<Report> custom({
    Expression<String>? id,
    Expression<String>? reportType,
    Expression<String>? detail,
    Expression<String>? healthDataID,
    Expression<String>? imageUrl,
    Expression<String>? driveFileId,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<String>? createdBy,
    Expression<bool>? saved,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reportType != null) 'report_type': reportType,
      if (detail != null) 'detail': detail,
      if (healthDataID != null) 'healthDataID': healthDataID,
      if (imageUrl != null) 'image_url': imageUrl,
      if (driveFileId != null) 'drive_file_id': driveFileId,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (createdBy != null) 'created_by': createdBy,
      if (saved != null) 'saved': saved,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReportsCompanion copyWith({
    Value<String>? id,
    Value<String>? reportType,
    Value<String?>? detail,
    Value<String?>? healthDataID,
    Value<String?>? imageUrl,
    Value<String?>? driveFileId,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<String?>? createdBy,
    Value<bool>? saved,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return ReportsCompanion(
      id: id ?? this.id,
      reportType: reportType ?? this.reportType,
      detail: detail ?? this.detail,
      healthDataID: healthDataID ?? this.healthDataID,
      imageUrl: imageUrl ?? this.imageUrl,
      driveFileId: driveFileId ?? this.driveFileId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      saved: saved ?? this.saved,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (reportType.present) {
      map['report_type'] = Variable<String>(reportType.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (healthDataID.present) {
      map['healthDataID'] = Variable<String>(healthDataID.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (driveFileId.present) {
      map['drive_file_id'] = Variable<String>(driveFileId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (saved.present) {
      map['saved'] = Variable<bool>(saved.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReportsCompanion(')
          ..write('id: $id, ')
          ..write('reportType: $reportType, ')
          ..write('detail: $detail, ')
          ..write('healthDataID: $healthDataID, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('driveFileId: $driveFileId, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('saved: $saved, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VitalsTable extends Vitals with TableInfo<$VitalsTable, Vital> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VitalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vitalKeyMeta = const VerificationMeta(
    'vitalKey',
  );
  @override
  late final GeneratedColumn<String> vitalKey = GeneratedColumn<String>(
    'vital_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vitalKey,
    value,
    unit,
    createdAt,
    userId,
    data,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vitals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Vital> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vital_key')) {
      context.handle(
        _vitalKeyMeta,
        vitalKey.isAcceptableOrUnknown(data['vital_key']!, _vitalKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_vitalKeyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Vital map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Vital(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vitalKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vital_key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $VitalsTable createAlias(String alias) {
    return $VitalsTable(attachedDatabase, alias);
  }
}

class Vital extends DataClass implements Insertable<Vital> {
  final String id;
  final String vitalKey;
  final double value;
  final String unit;
  final DateTime createdAt;
  final String? userId;
  final String? data;
  final int synced;
  const Vital({
    required this.id,
    required this.vitalKey,
    required this.value,
    required this.unit,
    required this.createdAt,
    this.userId,
    this.data,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vital_key'] = Variable<String>(vitalKey);
    map['value'] = Variable<double>(value);
    map['unit'] = Variable<String>(unit);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || data != null) {
      map['data'] = Variable<String>(data);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  VitalsCompanion toCompanion(bool nullToAbsent) {
    return VitalsCompanion(
      id: Value(id),
      vitalKey: Value(vitalKey),
      value: Value(value),
      unit: Value(unit),
      createdAt: Value(createdAt),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      data: data == null && nullToAbsent ? const Value.absent() : Value(data),
      synced: Value(synced),
    );
  }

  factory Vital.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Vital(
      id: serializer.fromJson<String>(json['id']),
      vitalKey: serializer.fromJson<String>(json['vitalKey']),
      value: serializer.fromJson<double>(json['value']),
      unit: serializer.fromJson<String>(json['unit']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      userId: serializer.fromJson<String?>(json['userId']),
      data: serializer.fromJson<String?>(json['data']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vitalKey': serializer.toJson<String>(vitalKey),
      'value': serializer.toJson<double>(value),
      'unit': serializer.toJson<String>(unit),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'userId': serializer.toJson<String?>(userId),
      'data': serializer.toJson<String?>(data),
      'synced': serializer.toJson<int>(synced),
    };
  }

  Vital copyWith({
    String? id,
    String? vitalKey,
    double? value,
    String? unit,
    DateTime? createdAt,
    Value<String?> userId = const Value.absent(),
    Value<String?> data = const Value.absent(),
    int? synced,
  }) => Vital(
    id: id ?? this.id,
    vitalKey: vitalKey ?? this.vitalKey,
    value: value ?? this.value,
    unit: unit ?? this.unit,
    createdAt: createdAt ?? this.createdAt,
    userId: userId.present ? userId.value : this.userId,
    data: data.present ? data.value : this.data,
    synced: synced ?? this.synced,
  );
  Vital copyWithCompanion(VitalsCompanion data) {
    return Vital(
      id: data.id.present ? data.id.value : this.id,
      vitalKey: data.vitalKey.present ? data.vitalKey.value : this.vitalKey,
      value: data.value.present ? data.value.value : this.value,
      unit: data.unit.present ? data.unit.value : this.unit,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      data: data.data.present ? data.data.value : this.data,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Vital(')
          ..write('id: $id, ')
          ..write('vitalKey: $vitalKey, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('createdAt: $createdAt, ')
          ..write('userId: $userId, ')
          ..write('data: $data, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, vitalKey, value, unit, createdAt, userId, data, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Vital &&
          other.id == this.id &&
          other.vitalKey == this.vitalKey &&
          other.value == this.value &&
          other.unit == this.unit &&
          other.createdAt == this.createdAt &&
          other.userId == this.userId &&
          other.data == this.data &&
          other.synced == this.synced);
}

class VitalsCompanion extends UpdateCompanion<Vital> {
  final Value<String> id;
  final Value<String> vitalKey;
  final Value<double> value;
  final Value<String> unit;
  final Value<DateTime> createdAt;
  final Value<String?> userId;
  final Value<String?> data;
  final Value<int> synced;
  final Value<int> rowid;
  const VitalsCompanion({
    this.id = const Value.absent(),
    this.vitalKey = const Value.absent(),
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.data = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VitalsCompanion.insert({
    required String id,
    required String vitalKey,
    required double value,
    required String unit,
    required DateTime createdAt,
    this.userId = const Value.absent(),
    this.data = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vitalKey = Value(vitalKey),
       value = Value(value),
       unit = Value(unit),
       createdAt = Value(createdAt);
  static Insertable<Vital> custom({
    Expression<String>? id,
    Expression<String>? vitalKey,
    Expression<double>? value,
    Expression<String>? unit,
    Expression<DateTime>? createdAt,
    Expression<String>? userId,
    Expression<String>? data,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vitalKey != null) 'vital_key': vitalKey,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (createdAt != null) 'created_at': createdAt,
      if (userId != null) 'user_id': userId,
      if (data != null) 'data': data,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VitalsCompanion copyWith({
    Value<String>? id,
    Value<String>? vitalKey,
    Value<double>? value,
    Value<String>? unit,
    Value<DateTime>? createdAt,
    Value<String?>? userId,
    Value<String?>? data,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return VitalsCompanion(
      id: id ?? this.id,
      vitalKey: vitalKey ?? this.vitalKey,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      data: data ?? this.data,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vitalKey.present) {
      map['vital_key'] = Variable<String>(vitalKey.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VitalsCompanion(')
          ..write('id: $id, ')
          ..write('vitalKey: $vitalKey, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('createdAt: $createdAt, ')
          ..write('userId: $userId, ')
          ..write('data: $data, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDriftDatabase extends GeneratedDatabase {
  _$AppDriftDatabase(QueryExecutor e) : super(e);
  $AppDriftDatabaseManager get managers => $AppDriftDatabaseManager(this);
  late final $InitialSetupTable initialSetup = $InitialSetupTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $UserEntitiesTable userEntities = $UserEntitiesTable(this);
  late final $UserRelationsTable userRelations = $UserRelationsTable(this);
  late final $FamiliesTable families = $FamiliesTable(this);
  late final $FamilyRequestsTableTable familyRequestsTable =
      $FamilyRequestsTableTable(this);
  late final $FamilyMembersTableTable familyMembersTable =
      $FamilyMembersTableTable(this);
  late final $HealthDataTableTable healthDataTable = $HealthDataTableTable(
    this,
  );
  late final $CycleHistoriesTable cycleHistories = $CycleHistoriesTable(this);
  late final $PregnanciesTable pregnancies = $PregnanciesTable(this);
  late final $PrescriptionsTable prescriptions = $PrescriptionsTable(this);
  late final $PrescriptionMedicinesTable prescriptionMedicines =
      $PrescriptionMedicinesTable(this);
  late final $PrescriptionMedicineTimingsTable prescriptionMedicineTimings =
      $PrescriptionMedicineTimingsTable(this);
  late final $ReportsTable reports = $ReportsTable(this);
  late final $VitalsTable vitals = $VitalsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    initialSetup,
    users,
    userEntities,
    userRelations,
    families,
    familyRequestsTable,
    familyMembersTable,
    healthDataTable,
    cycleHistories,
    pregnancies,
    prescriptions,
    prescriptionMedicines,
    prescriptionMedicineTimings,
    reports,
    vitals,
  ];
}

typedef $$InitialSetupTableCreateCompanionBuilder =
    InitialSetupCompanion Function({
      Value<int> id,
      required String key,
      required String value,
    });
typedef $$InitialSetupTableUpdateCompanionBuilder =
    InitialSetupCompanion Function({
      Value<int> id,
      Value<String> key,
      Value<String> value,
    });

class $$InitialSetupTableFilterComposer
    extends Composer<_$AppDriftDatabase, $InitialSetupTable> {
  $$InitialSetupTableFilterComposer({
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

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InitialSetupTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $InitialSetupTable> {
  $$InitialSetupTableOrderingComposer({
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

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InitialSetupTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $InitialSetupTable> {
  $$InitialSetupTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$InitialSetupTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $InitialSetupTable,
          InitialSetupData,
          $$InitialSetupTableFilterComposer,
          $$InitialSetupTableOrderingComposer,
          $$InitialSetupTableAnnotationComposer,
          $$InitialSetupTableCreateCompanionBuilder,
          $$InitialSetupTableUpdateCompanionBuilder,
          (
            InitialSetupData,
            BaseReferences<
              _$AppDriftDatabase,
              $InitialSetupTable,
              InitialSetupData
            >,
          ),
          InitialSetupData,
          PrefetchHooks Function()
        > {
  $$InitialSetupTableTableManager(
    _$AppDriftDatabase db,
    $InitialSetupTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InitialSetupTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InitialSetupTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InitialSetupTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
              }) => InitialSetupCompanion(id: id, key: key, value: value),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String key,
                required String value,
              }) =>
                  InitialSetupCompanion.insert(id: id, key: key, value: value),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InitialSetupTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $InitialSetupTable,
      InitialSetupData,
      $$InitialSetupTableFilterComposer,
      $$InitialSetupTableOrderingComposer,
      $$InitialSetupTableAnnotationComposer,
      $$InitialSetupTableCreateCompanionBuilder,
      $$InitialSetupTableUpdateCompanionBuilder,
      (
        InitialSetupData,
        BaseReferences<
          _$AppDriftDatabase,
          $InitialSetupTable,
          InitialSetupData
        >,
      ),
      InitialSetupData,
      PrefetchHooks Function()
    >;
typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String id,
      Value<String?> name,
      Value<String?> email,
      Value<String?> phone,
      Value<DateTime?> phoneVerified,
      Value<String?> countryCode,
      Value<String?> password,
      Value<DateTime?> emailVerified,
      Value<String?> gender,
      Value<DateTime?> dob,
      Value<String?> image,
      Value<String?> roleId,
      Value<String> userType,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> adline1,
      Value<String?> adline2,
      Value<String?> city,
      Value<String?> pincode,
      Value<bool> active,
      Value<double?> lat,
      Value<double?> lng,
      Value<String?> entity,
      Value<String?> userName,
      Value<String?> coverPic,
      Value<String?> bio,
      Value<String?> familyID,
      Value<bool> isDeleted,
      Value<String?> healthDataID,
      Value<String?> allowearMacAddress,
      Value<DateTime?> lastActiveAt,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<String?> email,
      Value<String?> phone,
      Value<DateTime?> phoneVerified,
      Value<String?> countryCode,
      Value<String?> password,
      Value<DateTime?> emailVerified,
      Value<String?> gender,
      Value<DateTime?> dob,
      Value<String?> image,
      Value<String?> roleId,
      Value<String> userType,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> adline1,
      Value<String?> adline2,
      Value<String?> city,
      Value<String?> pincode,
      Value<bool> active,
      Value<double?> lat,
      Value<double?> lng,
      Value<String?> entity,
      Value<String?> userName,
      Value<String?> coverPic,
      Value<String?> bio,
      Value<String?> familyID,
      Value<bool> isDeleted,
      Value<String?> healthDataID,
      Value<String?> allowearMacAddress,
      Value<DateTime?> lastActiveAt,
      Value<int> synced,
      Value<int> rowid,
    });

class $$UsersTableFilterComposer
    extends Composer<_$AppDriftDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
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

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get phoneVerified => $composableBuilder(
    column: $table.phoneVerified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get emailVerified => $composableBuilder(
    column: $table.emailVerified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dob => $composableBuilder(
    column: $table.dob,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get image => $composableBuilder(
    column: $table.image,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleId => $composableBuilder(
    column: $table.roleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userType => $composableBuilder(
    column: $table.userType,
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

  ColumnFilters<String> get adline1 => $composableBuilder(
    column: $table.adline1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adline2 => $composableBuilder(
    column: $table.adline2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pincode => $composableBuilder(
    column: $table.pincode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPic => $composableBuilder(
    column: $table.coverPic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get familyID => $composableBuilder(
    column: $table.familyID,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get healthDataID => $composableBuilder(
    column: $table.healthDataID,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allowearMacAddress => $composableBuilder(
    column: $table.allowearMacAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastActiveAt => $composableBuilder(
    column: $table.lastActiveAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
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

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get phoneVerified => $composableBuilder(
    column: $table.phoneVerified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get emailVerified => $composableBuilder(
    column: $table.emailVerified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dob => $composableBuilder(
    column: $table.dob,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get image => $composableBuilder(
    column: $table.image,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleId => $composableBuilder(
    column: $table.roleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userType => $composableBuilder(
    column: $table.userType,
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

  ColumnOrderings<String> get adline1 => $composableBuilder(
    column: $table.adline1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adline2 => $composableBuilder(
    column: $table.adline2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pincode => $composableBuilder(
    column: $table.pincode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPic => $composableBuilder(
    column: $table.coverPic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get familyID => $composableBuilder(
    column: $table.familyID,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthDataID => $composableBuilder(
    column: $table.healthDataID,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allowearMacAddress => $composableBuilder(
    column: $table.allowearMacAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastActiveAt => $composableBuilder(
    column: $table.lastActiveAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
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

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<DateTime> get phoneVerified => $composableBuilder(
    column: $table.phoneVerified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<DateTime> get emailVerified => $composableBuilder(
    column: $table.emailVerified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<DateTime> get dob =>
      $composableBuilder(column: $table.dob, builder: (column) => column);

  GeneratedColumn<String> get image =>
      $composableBuilder(column: $table.image, builder: (column) => column);

  GeneratedColumn<String> get roleId =>
      $composableBuilder(column: $table.roleId, builder: (column) => column);

  GeneratedColumn<String> get userType =>
      $composableBuilder(column: $table.userType, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get adline1 =>
      $composableBuilder(column: $table.adline1, builder: (column) => column);

  GeneratedColumn<String> get adline2 =>
      $composableBuilder(column: $table.adline2, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get pincode =>
      $composableBuilder(column: $table.pincode, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<String> get coverPic =>
      $composableBuilder(column: $table.coverPic, builder: (column) => column);

  GeneratedColumn<String> get bio =>
      $composableBuilder(column: $table.bio, builder: (column) => column);

  GeneratedColumn<String> get familyID =>
      $composableBuilder(column: $table.familyID, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get healthDataID => $composableBuilder(
    column: $table.healthDataID,
    builder: (column) => column,
  );

  GeneratedColumn<String> get allowearMacAddress => $composableBuilder(
    column: $table.allowearMacAddress,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastActiveAt => $composableBuilder(
    column: $table.lastActiveAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDriftDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDriftDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<DateTime?> phoneVerified = const Value.absent(),
                Value<String?> countryCode = const Value.absent(),
                Value<String?> password = const Value.absent(),
                Value<DateTime?> emailVerified = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<DateTime?> dob = const Value.absent(),
                Value<String?> image = const Value.absent(),
                Value<String?> roleId = const Value.absent(),
                Value<String> userType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> adline1 = const Value.absent(),
                Value<String?> adline2 = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> pincode = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<String?> entity = const Value.absent(),
                Value<String?> userName = const Value.absent(),
                Value<String?> coverPic = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> familyID = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String?> healthDataID = const Value.absent(),
                Value<String?> allowearMacAddress = const Value.absent(),
                Value<DateTime?> lastActiveAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                name: name,
                email: email,
                phone: phone,
                phoneVerified: phoneVerified,
                countryCode: countryCode,
                password: password,
                emailVerified: emailVerified,
                gender: gender,
                dob: dob,
                image: image,
                roleId: roleId,
                userType: userType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                adline1: adline1,
                adline2: adline2,
                city: city,
                pincode: pincode,
                active: active,
                lat: lat,
                lng: lng,
                entity: entity,
                userName: userName,
                coverPic: coverPic,
                bio: bio,
                familyID: familyID,
                isDeleted: isDeleted,
                healthDataID: healthDataID,
                allowearMacAddress: allowearMacAddress,
                lastActiveAt: lastActiveAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<DateTime?> phoneVerified = const Value.absent(),
                Value<String?> countryCode = const Value.absent(),
                Value<String?> password = const Value.absent(),
                Value<DateTime?> emailVerified = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<DateTime?> dob = const Value.absent(),
                Value<String?> image = const Value.absent(),
                Value<String?> roleId = const Value.absent(),
                Value<String> userType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> adline1 = const Value.absent(),
                Value<String?> adline2 = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> pincode = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<String?> entity = const Value.absent(),
                Value<String?> userName = const Value.absent(),
                Value<String?> coverPic = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> familyID = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String?> healthDataID = const Value.absent(),
                Value<String?> allowearMacAddress = const Value.absent(),
                Value<DateTime?> lastActiveAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                name: name,
                email: email,
                phone: phone,
                phoneVerified: phoneVerified,
                countryCode: countryCode,
                password: password,
                emailVerified: emailVerified,
                gender: gender,
                dob: dob,
                image: image,
                roleId: roleId,
                userType: userType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                adline1: adline1,
                adline2: adline2,
                city: city,
                pincode: pincode,
                active: active,
                lat: lat,
                lng: lng,
                entity: entity,
                userName: userName,
                coverPic: coverPic,
                bio: bio,
                familyID: familyID,
                isDeleted: isDeleted,
                healthDataID: healthDataID,
                allowearMacAddress: allowearMacAddress,
                lastActiveAt: lastActiveAt,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDriftDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$UserEntitiesTableCreateCompanionBuilder =
    UserEntitiesCompanion Function({
      Value<int> id,
      required String userId,
      required String entityId,
      required String type,
      Value<DateTime?> leftAt,
      Value<DateTime> createdAt,
      Value<int> synced,
    });
typedef $$UserEntitiesTableUpdateCompanionBuilder =
    UserEntitiesCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> entityId,
      Value<String> type,
      Value<DateTime?> leftAt,
      Value<DateTime> createdAt,
      Value<int> synced,
    });

class $$UserEntitiesTableFilterComposer
    extends Composer<_$AppDriftDatabase, $UserEntitiesTable> {
  $$UserEntitiesTableFilterComposer({
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

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get leftAt => $composableBuilder(
    column: $table.leftAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserEntitiesTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $UserEntitiesTable> {
  $$UserEntitiesTableOrderingComposer({
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

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get leftAt => $composableBuilder(
    column: $table.leftAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserEntitiesTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $UserEntitiesTable> {
  $$UserEntitiesTableAnnotationComposer({
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

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get leftAt =>
      $composableBuilder(column: $table.leftAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$UserEntitiesTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $UserEntitiesTable,
          UserEntity,
          $$UserEntitiesTableFilterComposer,
          $$UserEntitiesTableOrderingComposer,
          $$UserEntitiesTableAnnotationComposer,
          $$UserEntitiesTableCreateCompanionBuilder,
          $$UserEntitiesTableUpdateCompanionBuilder,
          (
            UserEntity,
            BaseReferences<_$AppDriftDatabase, $UserEntitiesTable, UserEntity>,
          ),
          UserEntity,
          PrefetchHooks Function()
        > {
  $$UserEntitiesTableTableManager(
    _$AppDriftDatabase db,
    $UserEntitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserEntitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserEntitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserEntitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime?> leftAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
              }) => UserEntitiesCompanion(
                id: id,
                userId: userId,
                entityId: entityId,
                type: type,
                leftAt: leftAt,
                createdAt: createdAt,
                synced: synced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String entityId,
                required String type,
                Value<DateTime?> leftAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
              }) => UserEntitiesCompanion.insert(
                id: id,
                userId: userId,
                entityId: entityId,
                type: type,
                leftAt: leftAt,
                createdAt: createdAt,
                synced: synced,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserEntitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $UserEntitiesTable,
      UserEntity,
      $$UserEntitiesTableFilterComposer,
      $$UserEntitiesTableOrderingComposer,
      $$UserEntitiesTableAnnotationComposer,
      $$UserEntitiesTableCreateCompanionBuilder,
      $$UserEntitiesTableUpdateCompanionBuilder,
      (
        UserEntity,
        BaseReferences<_$AppDriftDatabase, $UserEntitiesTable, UserEntity>,
      ),
      UserEntity,
      PrefetchHooks Function()
    >;
typedef $$UserRelationsTableCreateCompanionBuilder =
    UserRelationsCompanion Function({
      Value<int> id,
      required String userId,
      required String relatedUserId,
      required String relationType,
      Value<DateTime> createdAt,
      Value<int> synced,
    });
typedef $$UserRelationsTableUpdateCompanionBuilder =
    UserRelationsCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> relatedUserId,
      Value<String> relationType,
      Value<DateTime> createdAt,
      Value<int> synced,
    });

class $$UserRelationsTableFilterComposer
    extends Composer<_$AppDriftDatabase, $UserRelationsTable> {
  $$UserRelationsTableFilterComposer({
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

  ColumnFilters<String> get relatedUserId => $composableBuilder(
    column: $table.relatedUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserRelationsTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $UserRelationsTable> {
  $$UserRelationsTableOrderingComposer({
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

  ColumnOrderings<String> get relatedUserId => $composableBuilder(
    column: $table.relatedUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserRelationsTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $UserRelationsTable> {
  $$UserRelationsTableAnnotationComposer({
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

  GeneratedColumn<String> get relatedUserId => $composableBuilder(
    column: $table.relatedUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$UserRelationsTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $UserRelationsTable,
          UserRelation,
          $$UserRelationsTableFilterComposer,
          $$UserRelationsTableOrderingComposer,
          $$UserRelationsTableAnnotationComposer,
          $$UserRelationsTableCreateCompanionBuilder,
          $$UserRelationsTableUpdateCompanionBuilder,
          (
            UserRelation,
            BaseReferences<
              _$AppDriftDatabase,
              $UserRelationsTable,
              UserRelation
            >,
          ),
          UserRelation,
          PrefetchHooks Function()
        > {
  $$UserRelationsTableTableManager(
    _$AppDriftDatabase db,
    $UserRelationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserRelationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserRelationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserRelationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> relatedUserId = const Value.absent(),
                Value<String> relationType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
              }) => UserRelationsCompanion(
                id: id,
                userId: userId,
                relatedUserId: relatedUserId,
                relationType: relationType,
                createdAt: createdAt,
                synced: synced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String relatedUserId,
                required String relationType,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
              }) => UserRelationsCompanion.insert(
                id: id,
                userId: userId,
                relatedUserId: relatedUserId,
                relationType: relationType,
                createdAt: createdAt,
                synced: synced,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserRelationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $UserRelationsTable,
      UserRelation,
      $$UserRelationsTableFilterComposer,
      $$UserRelationsTableOrderingComposer,
      $$UserRelationsTableAnnotationComposer,
      $$UserRelationsTableCreateCompanionBuilder,
      $$UserRelationsTableUpdateCompanionBuilder,
      (
        UserRelation,
        BaseReferences<_$AppDriftDatabase, $UserRelationsTable, UserRelation>,
      ),
      UserRelation,
      PrefetchHooks Function()
    >;
typedef $$FamiliesTableCreateCompanionBuilder =
    FamiliesCompanion Function({
      required String id,
      Value<String?> name,
      Value<String?> code,
      Value<String?> motherId,
      Value<String?> fatherId,
      Value<DateTime> createdAt,
      Value<String?> createdBy,
      Value<String?> profileImage,
      Value<String?> bannerImage,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$FamiliesTableUpdateCompanionBuilder =
    FamiliesCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<String?> code,
      Value<String?> motherId,
      Value<String?> fatherId,
      Value<DateTime> createdAt,
      Value<String?> createdBy,
      Value<String?> profileImage,
      Value<String?> bannerImage,
      Value<int> synced,
      Value<int> rowid,
    });

class $$FamiliesTableFilterComposer
    extends Composer<_$AppDriftDatabase, $FamiliesTable> {
  $$FamiliesTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motherId => $composableBuilder(
    column: $table.motherId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fatherId => $composableBuilder(
    column: $table.fatherId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileImage => $composableBuilder(
    column: $table.profileImage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bannerImage => $composableBuilder(
    column: $table.bannerImage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FamiliesTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $FamiliesTable> {
  $$FamiliesTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motherId => $composableBuilder(
    column: $table.motherId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fatherId => $composableBuilder(
    column: $table.fatherId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileImage => $composableBuilder(
    column: $table.profileImage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bannerImage => $composableBuilder(
    column: $table.bannerImage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FamiliesTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $FamiliesTable> {
  $$FamiliesTableAnnotationComposer({
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

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get motherId =>
      $composableBuilder(column: $table.motherId, builder: (column) => column);

  GeneratedColumn<String> get fatherId =>
      $composableBuilder(column: $table.fatherId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get profileImage => $composableBuilder(
    column: $table.profileImage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bannerImage => $composableBuilder(
    column: $table.bannerImage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$FamiliesTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $FamiliesTable,
          Family,
          $$FamiliesTableFilterComposer,
          $$FamiliesTableOrderingComposer,
          $$FamiliesTableAnnotationComposer,
          $$FamiliesTableCreateCompanionBuilder,
          $$FamiliesTableUpdateCompanionBuilder,
          (Family, BaseReferences<_$AppDriftDatabase, $FamiliesTable, Family>),
          Family,
          PrefetchHooks Function()
        > {
  $$FamiliesTableTableManager(_$AppDriftDatabase db, $FamiliesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamiliesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamiliesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamiliesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<String?> motherId = const Value.absent(),
                Value<String?> fatherId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> profileImage = const Value.absent(),
                Value<String?> bannerImage = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamiliesCompanion(
                id: id,
                name: name,
                code: code,
                motherId: motherId,
                fatherId: fatherId,
                createdAt: createdAt,
                createdBy: createdBy,
                profileImage: profileImage,
                bannerImage: bannerImage,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<String?> motherId = const Value.absent(),
                Value<String?> fatherId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> profileImage = const Value.absent(),
                Value<String?> bannerImage = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamiliesCompanion.insert(
                id: id,
                name: name,
                code: code,
                motherId: motherId,
                fatherId: fatherId,
                createdAt: createdAt,
                createdBy: createdBy,
                profileImage: profileImage,
                bannerImage: bannerImage,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FamiliesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $FamiliesTable,
      Family,
      $$FamiliesTableFilterComposer,
      $$FamiliesTableOrderingComposer,
      $$FamiliesTableAnnotationComposer,
      $$FamiliesTableCreateCompanionBuilder,
      $$FamiliesTableUpdateCompanionBuilder,
      (Family, BaseReferences<_$AppDriftDatabase, $FamiliesTable, Family>),
      Family,
      PrefetchHooks Function()
    >;
typedef $$FamilyRequestsTableTableCreateCompanionBuilder =
    FamilyRequestsTableCompanion Function({
      required String id,
      Value<String?> userId,
      Value<String?> familyId,
      Value<DateTime> createdAt,
      Value<DateTime?> expiresAt,
      Value<String?> status,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$FamilyRequestsTableTableUpdateCompanionBuilder =
    FamilyRequestsTableCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String?> familyId,
      Value<DateTime> createdAt,
      Value<DateTime?> expiresAt,
      Value<String?> status,
      Value<int> synced,
      Value<int> rowid,
    });

class $$FamilyRequestsTableTableFilterComposer
    extends Composer<_$AppDriftDatabase, $FamilyRequestsTableTable> {
  $$FamilyRequestsTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get familyId => $composableBuilder(
    column: $table.familyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FamilyRequestsTableTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $FamilyRequestsTableTable> {
  $$FamilyRequestsTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get familyId => $composableBuilder(
    column: $table.familyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FamilyRequestsTableTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $FamilyRequestsTableTable> {
  $$FamilyRequestsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get familyId =>
      $composableBuilder(column: $table.familyId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$FamilyRequestsTableTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $FamilyRequestsTableTable,
          FamilyRequestsTableData,
          $$FamilyRequestsTableTableFilterComposer,
          $$FamilyRequestsTableTableOrderingComposer,
          $$FamilyRequestsTableTableAnnotationComposer,
          $$FamilyRequestsTableTableCreateCompanionBuilder,
          $$FamilyRequestsTableTableUpdateCompanionBuilder,
          (
            FamilyRequestsTableData,
            BaseReferences<
              _$AppDriftDatabase,
              $FamilyRequestsTableTable,
              FamilyRequestsTableData
            >,
          ),
          FamilyRequestsTableData,
          PrefetchHooks Function()
        > {
  $$FamilyRequestsTableTableTableManager(
    _$AppDriftDatabase db,
    $FamilyRequestsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamilyRequestsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamilyRequestsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FamilyRequestsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> familyId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamilyRequestsTableCompanion(
                id: id,
                userId: userId,
                familyId: familyId,
                createdAt: createdAt,
                expiresAt: expiresAt,
                status: status,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userId = const Value.absent(),
                Value<String?> familyId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamilyRequestsTableCompanion.insert(
                id: id,
                userId: userId,
                familyId: familyId,
                createdAt: createdAt,
                expiresAt: expiresAt,
                status: status,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FamilyRequestsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $FamilyRequestsTableTable,
      FamilyRequestsTableData,
      $$FamilyRequestsTableTableFilterComposer,
      $$FamilyRequestsTableTableOrderingComposer,
      $$FamilyRequestsTableTableAnnotationComposer,
      $$FamilyRequestsTableTableCreateCompanionBuilder,
      $$FamilyRequestsTableTableUpdateCompanionBuilder,
      (
        FamilyRequestsTableData,
        BaseReferences<
          _$AppDriftDatabase,
          $FamilyRequestsTableTable,
          FamilyRequestsTableData
        >,
      ),
      FamilyRequestsTableData,
      PrefetchHooks Function()
    >;
typedef $$FamilyMembersTableTableCreateCompanionBuilder =
    FamilyMembersTableCompanion Function({
      required String id,
      Value<String?> userid,
      Value<String?> familyid,
      Value<String?> relation,
      required String accessLevel,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$FamilyMembersTableTableUpdateCompanionBuilder =
    FamilyMembersTableCompanion Function({
      Value<String> id,
      Value<String?> userid,
      Value<String?> familyid,
      Value<String?> relation,
      Value<String> accessLevel,
      Value<int> synced,
      Value<int> rowid,
    });

class $$FamilyMembersTableTableFilterComposer
    extends Composer<_$AppDriftDatabase, $FamilyMembersTableTable> {
  $$FamilyMembersTableTableFilterComposer({
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

  ColumnFilters<String> get userid => $composableBuilder(
    column: $table.userid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get familyid => $composableBuilder(
    column: $table.familyid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relation => $composableBuilder(
    column: $table.relation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessLevel => $composableBuilder(
    column: $table.accessLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FamilyMembersTableTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $FamilyMembersTableTable> {
  $$FamilyMembersTableTableOrderingComposer({
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

  ColumnOrderings<String> get userid => $composableBuilder(
    column: $table.userid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get familyid => $composableBuilder(
    column: $table.familyid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relation => $composableBuilder(
    column: $table.relation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessLevel => $composableBuilder(
    column: $table.accessLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FamilyMembersTableTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $FamilyMembersTableTable> {
  $$FamilyMembersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userid =>
      $composableBuilder(column: $table.userid, builder: (column) => column);

  GeneratedColumn<String> get familyid =>
      $composableBuilder(column: $table.familyid, builder: (column) => column);

  GeneratedColumn<String> get relation =>
      $composableBuilder(column: $table.relation, builder: (column) => column);

  GeneratedColumn<String> get accessLevel => $composableBuilder(
    column: $table.accessLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$FamilyMembersTableTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $FamilyMembersTableTable,
          FamilyMembersTableData,
          $$FamilyMembersTableTableFilterComposer,
          $$FamilyMembersTableTableOrderingComposer,
          $$FamilyMembersTableTableAnnotationComposer,
          $$FamilyMembersTableTableCreateCompanionBuilder,
          $$FamilyMembersTableTableUpdateCompanionBuilder,
          (
            FamilyMembersTableData,
            BaseReferences<
              _$AppDriftDatabase,
              $FamilyMembersTableTable,
              FamilyMembersTableData
            >,
          ),
          FamilyMembersTableData,
          PrefetchHooks Function()
        > {
  $$FamilyMembersTableTableTableManager(
    _$AppDriftDatabase db,
    $FamilyMembersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamilyMembersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamilyMembersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamilyMembersTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userid = const Value.absent(),
                Value<String?> familyid = const Value.absent(),
                Value<String?> relation = const Value.absent(),
                Value<String> accessLevel = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamilyMembersTableCompanion(
                id: id,
                userid: userid,
                familyid: familyid,
                relation: relation,
                accessLevel: accessLevel,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userid = const Value.absent(),
                Value<String?> familyid = const Value.absent(),
                Value<String?> relation = const Value.absent(),
                required String accessLevel,
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamilyMembersTableCompanion.insert(
                id: id,
                userid: userid,
                familyid: familyid,
                relation: relation,
                accessLevel: accessLevel,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FamilyMembersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $FamilyMembersTableTable,
      FamilyMembersTableData,
      $$FamilyMembersTableTableFilterComposer,
      $$FamilyMembersTableTableOrderingComposer,
      $$FamilyMembersTableTableAnnotationComposer,
      $$FamilyMembersTableTableCreateCompanionBuilder,
      $$FamilyMembersTableTableUpdateCompanionBuilder,
      (
        FamilyMembersTableData,
        BaseReferences<
          _$AppDriftDatabase,
          $FamilyMembersTableTable,
          FamilyMembersTableData
        >,
      ),
      FamilyMembersTableData,
      PrefetchHooks Function()
    >;
typedef $$HealthDataTableTableCreateCompanionBuilder =
    HealthDataTableCompanion Function({
      required String id,
      Value<String?> userId,
      Value<double?> height,
      Value<double?> weight,
      Value<String?> bloodGroup,
      Value<String?> allergies,
      Value<String?> medicalConditions,
      Value<String?> rchId,
      Value<DateTime> createdAt,
      Value<String?> recoveryPhone,
      Value<String?> recoveryEmail,
      Value<DateTime?> lmpDate,
      Value<double?> averagePeriodDuration,
      Value<double?> averageCycle,
      Value<String?> cycleType,
      Value<DateTime?> edDate,
      Value<String?> pregnancyStatus,
      Value<DateTime?> lastDeliveryDate,
      Value<String?> healthStatus,
      Value<bool> allowFamilyAccess,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$HealthDataTableTableUpdateCompanionBuilder =
    HealthDataTableCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<double?> height,
      Value<double?> weight,
      Value<String?> bloodGroup,
      Value<String?> allergies,
      Value<String?> medicalConditions,
      Value<String?> rchId,
      Value<DateTime> createdAt,
      Value<String?> recoveryPhone,
      Value<String?> recoveryEmail,
      Value<DateTime?> lmpDate,
      Value<double?> averagePeriodDuration,
      Value<double?> averageCycle,
      Value<String?> cycleType,
      Value<DateTime?> edDate,
      Value<String?> pregnancyStatus,
      Value<DateTime?> lastDeliveryDate,
      Value<String?> healthStatus,
      Value<bool> allowFamilyAccess,
      Value<int> synced,
      Value<int> rowid,
    });

class $$HealthDataTableTableFilterComposer
    extends Composer<_$AppDriftDatabase, $HealthDataTableTable> {
  $$HealthDataTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bloodGroup => $composableBuilder(
    column: $table.bloodGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allergies => $composableBuilder(
    column: $table.allergies,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicalConditions => $composableBuilder(
    column: $table.medicalConditions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rchId => $composableBuilder(
    column: $table.rchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recoveryPhone => $composableBuilder(
    column: $table.recoveryPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recoveryEmail => $composableBuilder(
    column: $table.recoveryEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lmpDate => $composableBuilder(
    column: $table.lmpDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averagePeriodDuration => $composableBuilder(
    column: $table.averagePeriodDuration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageCycle => $composableBuilder(
    column: $table.averageCycle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cycleType => $composableBuilder(
    column: $table.cycleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get edDate => $composableBuilder(
    column: $table.edDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pregnancyStatus => $composableBuilder(
    column: $table.pregnancyStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastDeliveryDate => $composableBuilder(
    column: $table.lastDeliveryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get healthStatus => $composableBuilder(
    column: $table.healthStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowFamilyAccess => $composableBuilder(
    column: $table.allowFamilyAccess,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HealthDataTableTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $HealthDataTableTable> {
  $$HealthDataTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bloodGroup => $composableBuilder(
    column: $table.bloodGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allergies => $composableBuilder(
    column: $table.allergies,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicalConditions => $composableBuilder(
    column: $table.medicalConditions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rchId => $composableBuilder(
    column: $table.rchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recoveryPhone => $composableBuilder(
    column: $table.recoveryPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recoveryEmail => $composableBuilder(
    column: $table.recoveryEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lmpDate => $composableBuilder(
    column: $table.lmpDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averagePeriodDuration => $composableBuilder(
    column: $table.averagePeriodDuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageCycle => $composableBuilder(
    column: $table.averageCycle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cycleType => $composableBuilder(
    column: $table.cycleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get edDate => $composableBuilder(
    column: $table.edDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pregnancyStatus => $composableBuilder(
    column: $table.pregnancyStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastDeliveryDate => $composableBuilder(
    column: $table.lastDeliveryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthStatus => $composableBuilder(
    column: $table.healthStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowFamilyAccess => $composableBuilder(
    column: $table.allowFamilyAccess,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HealthDataTableTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $HealthDataTableTable> {
  $$HealthDataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<String> get bloodGroup => $composableBuilder(
    column: $table.bloodGroup,
    builder: (column) => column,
  );

  GeneratedColumn<String> get allergies =>
      $composableBuilder(column: $table.allergies, builder: (column) => column);

  GeneratedColumn<String> get medicalConditions => $composableBuilder(
    column: $table.medicalConditions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rchId =>
      $composableBuilder(column: $table.rchId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get recoveryPhone => $composableBuilder(
    column: $table.recoveryPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recoveryEmail => $composableBuilder(
    column: $table.recoveryEmail,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lmpDate =>
      $composableBuilder(column: $table.lmpDate, builder: (column) => column);

  GeneratedColumn<double> get averagePeriodDuration => $composableBuilder(
    column: $table.averagePeriodDuration,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averageCycle => $composableBuilder(
    column: $table.averageCycle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cycleType =>
      $composableBuilder(column: $table.cycleType, builder: (column) => column);

  GeneratedColumn<DateTime> get edDate =>
      $composableBuilder(column: $table.edDate, builder: (column) => column);

  GeneratedColumn<String> get pregnancyStatus => $composableBuilder(
    column: $table.pregnancyStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastDeliveryDate => $composableBuilder(
    column: $table.lastDeliveryDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get healthStatus => $composableBuilder(
    column: $table.healthStatus,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get allowFamilyAccess => $composableBuilder(
    column: $table.allowFamilyAccess,
    builder: (column) => column,
  );

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$HealthDataTableTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $HealthDataTableTable,
          HealthDataTableData,
          $$HealthDataTableTableFilterComposer,
          $$HealthDataTableTableOrderingComposer,
          $$HealthDataTableTableAnnotationComposer,
          $$HealthDataTableTableCreateCompanionBuilder,
          $$HealthDataTableTableUpdateCompanionBuilder,
          (
            HealthDataTableData,
            BaseReferences<
              _$AppDriftDatabase,
              $HealthDataTableTable,
              HealthDataTableData
            >,
          ),
          HealthDataTableData,
          PrefetchHooks Function()
        > {
  $$HealthDataTableTableTableManager(
    _$AppDriftDatabase db,
    $HealthDataTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthDataTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthDataTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthDataTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<double?> height = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<String?> bloodGroup = const Value.absent(),
                Value<String?> allergies = const Value.absent(),
                Value<String?> medicalConditions = const Value.absent(),
                Value<String?> rchId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> recoveryPhone = const Value.absent(),
                Value<String?> recoveryEmail = const Value.absent(),
                Value<DateTime?> lmpDate = const Value.absent(),
                Value<double?> averagePeriodDuration = const Value.absent(),
                Value<double?> averageCycle = const Value.absent(),
                Value<String?> cycleType = const Value.absent(),
                Value<DateTime?> edDate = const Value.absent(),
                Value<String?> pregnancyStatus = const Value.absent(),
                Value<DateTime?> lastDeliveryDate = const Value.absent(),
                Value<String?> healthStatus = const Value.absent(),
                Value<bool> allowFamilyAccess = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthDataTableCompanion(
                id: id,
                userId: userId,
                height: height,
                weight: weight,
                bloodGroup: bloodGroup,
                allergies: allergies,
                medicalConditions: medicalConditions,
                rchId: rchId,
                createdAt: createdAt,
                recoveryPhone: recoveryPhone,
                recoveryEmail: recoveryEmail,
                lmpDate: lmpDate,
                averagePeriodDuration: averagePeriodDuration,
                averageCycle: averageCycle,
                cycleType: cycleType,
                edDate: edDate,
                pregnancyStatus: pregnancyStatus,
                lastDeliveryDate: lastDeliveryDate,
                healthStatus: healthStatus,
                allowFamilyAccess: allowFamilyAccess,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userId = const Value.absent(),
                Value<double?> height = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<String?> bloodGroup = const Value.absent(),
                Value<String?> allergies = const Value.absent(),
                Value<String?> medicalConditions = const Value.absent(),
                Value<String?> rchId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> recoveryPhone = const Value.absent(),
                Value<String?> recoveryEmail = const Value.absent(),
                Value<DateTime?> lmpDate = const Value.absent(),
                Value<double?> averagePeriodDuration = const Value.absent(),
                Value<double?> averageCycle = const Value.absent(),
                Value<String?> cycleType = const Value.absent(),
                Value<DateTime?> edDate = const Value.absent(),
                Value<String?> pregnancyStatus = const Value.absent(),
                Value<DateTime?> lastDeliveryDate = const Value.absent(),
                Value<String?> healthStatus = const Value.absent(),
                Value<bool> allowFamilyAccess = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthDataTableCompanion.insert(
                id: id,
                userId: userId,
                height: height,
                weight: weight,
                bloodGroup: bloodGroup,
                allergies: allergies,
                medicalConditions: medicalConditions,
                rchId: rchId,
                createdAt: createdAt,
                recoveryPhone: recoveryPhone,
                recoveryEmail: recoveryEmail,
                lmpDate: lmpDate,
                averagePeriodDuration: averagePeriodDuration,
                averageCycle: averageCycle,
                cycleType: cycleType,
                edDate: edDate,
                pregnancyStatus: pregnancyStatus,
                lastDeliveryDate: lastDeliveryDate,
                healthStatus: healthStatus,
                allowFamilyAccess: allowFamilyAccess,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HealthDataTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $HealthDataTableTable,
      HealthDataTableData,
      $$HealthDataTableTableFilterComposer,
      $$HealthDataTableTableOrderingComposer,
      $$HealthDataTableTableAnnotationComposer,
      $$HealthDataTableTableCreateCompanionBuilder,
      $$HealthDataTableTableUpdateCompanionBuilder,
      (
        HealthDataTableData,
        BaseReferences<
          _$AppDriftDatabase,
          $HealthDataTableTable,
          HealthDataTableData
        >,
      ),
      HealthDataTableData,
      PrefetchHooks Function()
    >;
typedef $$CycleHistoriesTableCreateCompanionBuilder =
    CycleHistoriesCompanion Function({
      required String id,
      Value<String?> healthId,
      required DateTime cycleStartDate,
      Value<DateTime?> cycleEndDate,
      Value<String?> cycleType,
      Value<DateTime> createdAt,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$CycleHistoriesTableUpdateCompanionBuilder =
    CycleHistoriesCompanion Function({
      Value<String> id,
      Value<String?> healthId,
      Value<DateTime> cycleStartDate,
      Value<DateTime?> cycleEndDate,
      Value<String?> cycleType,
      Value<DateTime> createdAt,
      Value<int> synced,
      Value<int> rowid,
    });

class $$CycleHistoriesTableFilterComposer
    extends Composer<_$AppDriftDatabase, $CycleHistoriesTable> {
  $$CycleHistoriesTableFilterComposer({
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

  ColumnFilters<String> get healthId => $composableBuilder(
    column: $table.healthId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cycleStartDate => $composableBuilder(
    column: $table.cycleStartDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cycleEndDate => $composableBuilder(
    column: $table.cycleEndDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cycleType => $composableBuilder(
    column: $table.cycleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CycleHistoriesTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $CycleHistoriesTable> {
  $$CycleHistoriesTableOrderingComposer({
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

  ColumnOrderings<String> get healthId => $composableBuilder(
    column: $table.healthId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cycleStartDate => $composableBuilder(
    column: $table.cycleStartDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cycleEndDate => $composableBuilder(
    column: $table.cycleEndDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cycleType => $composableBuilder(
    column: $table.cycleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CycleHistoriesTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $CycleHistoriesTable> {
  $$CycleHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get healthId =>
      $composableBuilder(column: $table.healthId, builder: (column) => column);

  GeneratedColumn<DateTime> get cycleStartDate => $composableBuilder(
    column: $table.cycleStartDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cycleEndDate => $composableBuilder(
    column: $table.cycleEndDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cycleType =>
      $composableBuilder(column: $table.cycleType, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$CycleHistoriesTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $CycleHistoriesTable,
          CycleHistory,
          $$CycleHistoriesTableFilterComposer,
          $$CycleHistoriesTableOrderingComposer,
          $$CycleHistoriesTableAnnotationComposer,
          $$CycleHistoriesTableCreateCompanionBuilder,
          $$CycleHistoriesTableUpdateCompanionBuilder,
          (
            CycleHistory,
            BaseReferences<
              _$AppDriftDatabase,
              $CycleHistoriesTable,
              CycleHistory
            >,
          ),
          CycleHistory,
          PrefetchHooks Function()
        > {
  $$CycleHistoriesTableTableManager(
    _$AppDriftDatabase db,
    $CycleHistoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CycleHistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CycleHistoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CycleHistoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> healthId = const Value.absent(),
                Value<DateTime> cycleStartDate = const Value.absent(),
                Value<DateTime?> cycleEndDate = const Value.absent(),
                Value<String?> cycleType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CycleHistoriesCompanion(
                id: id,
                healthId: healthId,
                cycleStartDate: cycleStartDate,
                cycleEndDate: cycleEndDate,
                cycleType: cycleType,
                createdAt: createdAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> healthId = const Value.absent(),
                required DateTime cycleStartDate,
                Value<DateTime?> cycleEndDate = const Value.absent(),
                Value<String?> cycleType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CycleHistoriesCompanion.insert(
                id: id,
                healthId: healthId,
                cycleStartDate: cycleStartDate,
                cycleEndDate: cycleEndDate,
                cycleType: cycleType,
                createdAt: createdAt,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CycleHistoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $CycleHistoriesTable,
      CycleHistory,
      $$CycleHistoriesTableFilterComposer,
      $$CycleHistoriesTableOrderingComposer,
      $$CycleHistoriesTableAnnotationComposer,
      $$CycleHistoriesTableCreateCompanionBuilder,
      $$CycleHistoriesTableUpdateCompanionBuilder,
      (
        CycleHistory,
        BaseReferences<_$AppDriftDatabase, $CycleHistoriesTable, CycleHistory>,
      ),
      CycleHistory,
      PrefetchHooks Function()
    >;
typedef $$PregnanciesTableCreateCompanionBuilder =
    PregnanciesCompanion Function({
      required String id,
      Value<DateTime?> lmpDate,
      Value<DateTime?> edDate,
      Value<String?> healthId,
      Value<DateTime?> deliveryDate,
      Value<String?> rchId,
      Value<String> status,
      Value<String?> createdBy,
      Value<bool> registerWithin12Weeks,
      Value<String?> highestRiskStatus,
      Value<String?> allFlaggedComplications,
      Value<String?> riskStatus,
      Value<String?> flaggedComplications,
      Value<String?> overallHealth,
      Value<String?> methodOfConception,
      Value<int> gravidity,
      Value<int> parity,
      Value<int> livingChildren,
      Value<int> abortions,
      Value<int> stillBirths,
      Value<int> miscarriages,
      Value<int> csectionDeliveries,
      Value<String?> obstetricCode,
      Value<bool> mrmbsEligible,
      Value<int?> motherAge,
      Value<int?> fatherAge,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
      Value<String?> deliveryConductedAt,
      Value<DateTime?> admittedAt,
      Value<DateTime?> dischargedAt,
      Value<DateTime?> deceasedAt,
      Value<String?> causeOfDeath,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$PregnanciesTableUpdateCompanionBuilder =
    PregnanciesCompanion Function({
      Value<String> id,
      Value<DateTime?> lmpDate,
      Value<DateTime?> edDate,
      Value<String?> healthId,
      Value<DateTime?> deliveryDate,
      Value<String?> rchId,
      Value<String> status,
      Value<String?> createdBy,
      Value<bool> registerWithin12Weeks,
      Value<String?> highestRiskStatus,
      Value<String?> allFlaggedComplications,
      Value<String?> riskStatus,
      Value<String?> flaggedComplications,
      Value<String?> overallHealth,
      Value<String?> methodOfConception,
      Value<int> gravidity,
      Value<int> parity,
      Value<int> livingChildren,
      Value<int> abortions,
      Value<int> stillBirths,
      Value<int> miscarriages,
      Value<int> csectionDeliveries,
      Value<String?> obstetricCode,
      Value<bool> mrmbsEligible,
      Value<int?> motherAge,
      Value<int?> fatherAge,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
      Value<String?> deliveryConductedAt,
      Value<DateTime?> admittedAt,
      Value<DateTime?> dischargedAt,
      Value<DateTime?> deceasedAt,
      Value<String?> causeOfDeath,
      Value<int> synced,
      Value<int> rowid,
    });

class $$PregnanciesTableFilterComposer
    extends Composer<_$AppDriftDatabase, $PregnanciesTable> {
  $$PregnanciesTableFilterComposer({
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

  ColumnFilters<DateTime> get lmpDate => $composableBuilder(
    column: $table.lmpDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get edDate => $composableBuilder(
    column: $table.edDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get healthId => $composableBuilder(
    column: $table.healthId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deliveryDate => $composableBuilder(
    column: $table.deliveryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rchId => $composableBuilder(
    column: $table.rchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get registerWithin12Weeks => $composableBuilder(
    column: $table.registerWithin12Weeks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get highestRiskStatus => $composableBuilder(
    column: $table.highestRiskStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allFlaggedComplications => $composableBuilder(
    column: $table.allFlaggedComplications,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get riskStatus => $composableBuilder(
    column: $table.riskStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flaggedComplications => $composableBuilder(
    column: $table.flaggedComplications,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overallHealth => $composableBuilder(
    column: $table.overallHealth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get methodOfConception => $composableBuilder(
    column: $table.methodOfConception,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gravidity => $composableBuilder(
    column: $table.gravidity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parity => $composableBuilder(
    column: $table.parity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get livingChildren => $composableBuilder(
    column: $table.livingChildren,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get abortions => $composableBuilder(
    column: $table.abortions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stillBirths => $composableBuilder(
    column: $table.stillBirths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get miscarriages => $composableBuilder(
    column: $table.miscarriages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get csectionDeliveries => $composableBuilder(
    column: $table.csectionDeliveries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get obstetricCode => $composableBuilder(
    column: $table.obstetricCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get mrmbsEligible => $composableBuilder(
    column: $table.mrmbsEligible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get motherAge => $composableBuilder(
    column: $table.motherAge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fatherAge => $composableBuilder(
    column: $table.fatherAge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryConductedAt => $composableBuilder(
    column: $table.deliveryConductedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get admittedAt => $composableBuilder(
    column: $table.admittedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dischargedAt => $composableBuilder(
    column: $table.dischargedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deceasedAt => $composableBuilder(
    column: $table.deceasedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get causeOfDeath => $composableBuilder(
    column: $table.causeOfDeath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PregnanciesTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $PregnanciesTable> {
  $$PregnanciesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get lmpDate => $composableBuilder(
    column: $table.lmpDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get edDate => $composableBuilder(
    column: $table.edDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthId => $composableBuilder(
    column: $table.healthId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deliveryDate => $composableBuilder(
    column: $table.deliveryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rchId => $composableBuilder(
    column: $table.rchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get registerWithin12Weeks => $composableBuilder(
    column: $table.registerWithin12Weeks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get highestRiskStatus => $composableBuilder(
    column: $table.highestRiskStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allFlaggedComplications => $composableBuilder(
    column: $table.allFlaggedComplications,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get riskStatus => $composableBuilder(
    column: $table.riskStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flaggedComplications => $composableBuilder(
    column: $table.flaggedComplications,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overallHealth => $composableBuilder(
    column: $table.overallHealth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get methodOfConception => $composableBuilder(
    column: $table.methodOfConception,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gravidity => $composableBuilder(
    column: $table.gravidity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parity => $composableBuilder(
    column: $table.parity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get livingChildren => $composableBuilder(
    column: $table.livingChildren,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get abortions => $composableBuilder(
    column: $table.abortions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stillBirths => $composableBuilder(
    column: $table.stillBirths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get miscarriages => $composableBuilder(
    column: $table.miscarriages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get csectionDeliveries => $composableBuilder(
    column: $table.csectionDeliveries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get obstetricCode => $composableBuilder(
    column: $table.obstetricCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get mrmbsEligible => $composableBuilder(
    column: $table.mrmbsEligible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get motherAge => $composableBuilder(
    column: $table.motherAge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fatherAge => $composableBuilder(
    column: $table.fatherAge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryConductedAt => $composableBuilder(
    column: $table.deliveryConductedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get admittedAt => $composableBuilder(
    column: $table.admittedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dischargedAt => $composableBuilder(
    column: $table.dischargedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deceasedAt => $composableBuilder(
    column: $table.deceasedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get causeOfDeath => $composableBuilder(
    column: $table.causeOfDeath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PregnanciesTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $PregnanciesTable> {
  $$PregnanciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get lmpDate =>
      $composableBuilder(column: $table.lmpDate, builder: (column) => column);

  GeneratedColumn<DateTime> get edDate =>
      $composableBuilder(column: $table.edDate, builder: (column) => column);

  GeneratedColumn<String> get healthId =>
      $composableBuilder(column: $table.healthId, builder: (column) => column);

  GeneratedColumn<DateTime> get deliveryDate => $composableBuilder(
    column: $table.deliveryDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rchId =>
      $composableBuilder(column: $table.rchId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<bool> get registerWithin12Weeks => $composableBuilder(
    column: $table.registerWithin12Weeks,
    builder: (column) => column,
  );

  GeneratedColumn<String> get highestRiskStatus => $composableBuilder(
    column: $table.highestRiskStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get allFlaggedComplications => $composableBuilder(
    column: $table.allFlaggedComplications,
    builder: (column) => column,
  );

  GeneratedColumn<String> get riskStatus => $composableBuilder(
    column: $table.riskStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get flaggedComplications => $composableBuilder(
    column: $table.flaggedComplications,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overallHealth => $composableBuilder(
    column: $table.overallHealth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get methodOfConception => $composableBuilder(
    column: $table.methodOfConception,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gravidity =>
      $composableBuilder(column: $table.gravidity, builder: (column) => column);

  GeneratedColumn<int> get parity =>
      $composableBuilder(column: $table.parity, builder: (column) => column);

  GeneratedColumn<int> get livingChildren => $composableBuilder(
    column: $table.livingChildren,
    builder: (column) => column,
  );

  GeneratedColumn<int> get abortions =>
      $composableBuilder(column: $table.abortions, builder: (column) => column);

  GeneratedColumn<int> get stillBirths => $composableBuilder(
    column: $table.stillBirths,
    builder: (column) => column,
  );

  GeneratedColumn<int> get miscarriages => $composableBuilder(
    column: $table.miscarriages,
    builder: (column) => column,
  );

  GeneratedColumn<int> get csectionDeliveries => $composableBuilder(
    column: $table.csectionDeliveries,
    builder: (column) => column,
  );

  GeneratedColumn<String> get obstetricCode => $composableBuilder(
    column: $table.obstetricCode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get mrmbsEligible => $composableBuilder(
    column: $table.mrmbsEligible,
    builder: (column) => column,
  );

  GeneratedColumn<int> get motherAge =>
      $composableBuilder(column: $table.motherAge, builder: (column) => column);

  GeneratedColumn<int> get fatherAge =>
      $composableBuilder(column: $table.fatherAge, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryConductedAt => $composableBuilder(
    column: $table.deliveryConductedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get admittedAt => $composableBuilder(
    column: $table.admittedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dischargedAt => $composableBuilder(
    column: $table.dischargedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deceasedAt => $composableBuilder(
    column: $table.deceasedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get causeOfDeath => $composableBuilder(
    column: $table.causeOfDeath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$PregnanciesTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $PregnanciesTable,
          Pregnancy,
          $$PregnanciesTableFilterComposer,
          $$PregnanciesTableOrderingComposer,
          $$PregnanciesTableAnnotationComposer,
          $$PregnanciesTableCreateCompanionBuilder,
          $$PregnanciesTableUpdateCompanionBuilder,
          (
            Pregnancy,
            BaseReferences<_$AppDriftDatabase, $PregnanciesTable, Pregnancy>,
          ),
          Pregnancy,
          PrefetchHooks Function()
        > {
  $$PregnanciesTableTableManager(_$AppDriftDatabase db, $PregnanciesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PregnanciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PregnanciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PregnanciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime?> lmpDate = const Value.absent(),
                Value<DateTime?> edDate = const Value.absent(),
                Value<String?> healthId = const Value.absent(),
                Value<DateTime?> deliveryDate = const Value.absent(),
                Value<String?> rchId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<bool> registerWithin12Weeks = const Value.absent(),
                Value<String?> highestRiskStatus = const Value.absent(),
                Value<String?> allFlaggedComplications = const Value.absent(),
                Value<String?> riskStatus = const Value.absent(),
                Value<String?> flaggedComplications = const Value.absent(),
                Value<String?> overallHealth = const Value.absent(),
                Value<String?> methodOfConception = const Value.absent(),
                Value<int> gravidity = const Value.absent(),
                Value<int> parity = const Value.absent(),
                Value<int> livingChildren = const Value.absent(),
                Value<int> abortions = const Value.absent(),
                Value<int> stillBirths = const Value.absent(),
                Value<int> miscarriages = const Value.absent(),
                Value<int> csectionDeliveries = const Value.absent(),
                Value<String?> obstetricCode = const Value.absent(),
                Value<bool> mrmbsEligible = const Value.absent(),
                Value<int?> motherAge = const Value.absent(),
                Value<int?> fatherAge = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> deliveryConductedAt = const Value.absent(),
                Value<DateTime?> admittedAt = const Value.absent(),
                Value<DateTime?> dischargedAt = const Value.absent(),
                Value<DateTime?> deceasedAt = const Value.absent(),
                Value<String?> causeOfDeath = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PregnanciesCompanion(
                id: id,
                lmpDate: lmpDate,
                edDate: edDate,
                healthId: healthId,
                deliveryDate: deliveryDate,
                rchId: rchId,
                status: status,
                createdBy: createdBy,
                registerWithin12Weeks: registerWithin12Weeks,
                highestRiskStatus: highestRiskStatus,
                allFlaggedComplications: allFlaggedComplications,
                riskStatus: riskStatus,
                flaggedComplications: flaggedComplications,
                overallHealth: overallHealth,
                methodOfConception: methodOfConception,
                gravidity: gravidity,
                parity: parity,
                livingChildren: livingChildren,
                abortions: abortions,
                stillBirths: stillBirths,
                miscarriages: miscarriages,
                csectionDeliveries: csectionDeliveries,
                obstetricCode: obstetricCode,
                mrmbsEligible: mrmbsEligible,
                motherAge: motherAge,
                fatherAge: fatherAge,
                createdAt: createdAt,
                completedAt: completedAt,
                deliveryConductedAt: deliveryConductedAt,
                admittedAt: admittedAt,
                dischargedAt: dischargedAt,
                deceasedAt: deceasedAt,
                causeOfDeath: causeOfDeath,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime?> lmpDate = const Value.absent(),
                Value<DateTime?> edDate = const Value.absent(),
                Value<String?> healthId = const Value.absent(),
                Value<DateTime?> deliveryDate = const Value.absent(),
                Value<String?> rchId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<bool> registerWithin12Weeks = const Value.absent(),
                Value<String?> highestRiskStatus = const Value.absent(),
                Value<String?> allFlaggedComplications = const Value.absent(),
                Value<String?> riskStatus = const Value.absent(),
                Value<String?> flaggedComplications = const Value.absent(),
                Value<String?> overallHealth = const Value.absent(),
                Value<String?> methodOfConception = const Value.absent(),
                Value<int> gravidity = const Value.absent(),
                Value<int> parity = const Value.absent(),
                Value<int> livingChildren = const Value.absent(),
                Value<int> abortions = const Value.absent(),
                Value<int> stillBirths = const Value.absent(),
                Value<int> miscarriages = const Value.absent(),
                Value<int> csectionDeliveries = const Value.absent(),
                Value<String?> obstetricCode = const Value.absent(),
                Value<bool> mrmbsEligible = const Value.absent(),
                Value<int?> motherAge = const Value.absent(),
                Value<int?> fatherAge = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> deliveryConductedAt = const Value.absent(),
                Value<DateTime?> admittedAt = const Value.absent(),
                Value<DateTime?> dischargedAt = const Value.absent(),
                Value<DateTime?> deceasedAt = const Value.absent(),
                Value<String?> causeOfDeath = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PregnanciesCompanion.insert(
                id: id,
                lmpDate: lmpDate,
                edDate: edDate,
                healthId: healthId,
                deliveryDate: deliveryDate,
                rchId: rchId,
                status: status,
                createdBy: createdBy,
                registerWithin12Weeks: registerWithin12Weeks,
                highestRiskStatus: highestRiskStatus,
                allFlaggedComplications: allFlaggedComplications,
                riskStatus: riskStatus,
                flaggedComplications: flaggedComplications,
                overallHealth: overallHealth,
                methodOfConception: methodOfConception,
                gravidity: gravidity,
                parity: parity,
                livingChildren: livingChildren,
                abortions: abortions,
                stillBirths: stillBirths,
                miscarriages: miscarriages,
                csectionDeliveries: csectionDeliveries,
                obstetricCode: obstetricCode,
                mrmbsEligible: mrmbsEligible,
                motherAge: motherAge,
                fatherAge: fatherAge,
                createdAt: createdAt,
                completedAt: completedAt,
                deliveryConductedAt: deliveryConductedAt,
                admittedAt: admittedAt,
                dischargedAt: dischargedAt,
                deceasedAt: deceasedAt,
                causeOfDeath: causeOfDeath,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PregnanciesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $PregnanciesTable,
      Pregnancy,
      $$PregnanciesTableFilterComposer,
      $$PregnanciesTableOrderingComposer,
      $$PregnanciesTableAnnotationComposer,
      $$PregnanciesTableCreateCompanionBuilder,
      $$PregnanciesTableUpdateCompanionBuilder,
      (
        Pregnancy,
        BaseReferences<_$AppDriftDatabase, $PregnanciesTable, Pregnancy>,
      ),
      Pregnancy,
      PrefetchHooks Function()
    >;
typedef $$PrescriptionsTableCreateCompanionBuilder =
    PrescriptionsCompanion Function({
      required String id,
      Value<String?> healthId,
      required String description,
      Value<String?> imageUrl,
      Value<String?> driveFileId,
      Value<DateTime> createdAt,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$PrescriptionsTableUpdateCompanionBuilder =
    PrescriptionsCompanion Function({
      Value<String> id,
      Value<String?> healthId,
      Value<String> description,
      Value<String?> imageUrl,
      Value<String?> driveFileId,
      Value<DateTime> createdAt,
      Value<int> synced,
      Value<int> rowid,
    });

class $$PrescriptionsTableFilterComposer
    extends Composer<_$AppDriftDatabase, $PrescriptionsTable> {
  $$PrescriptionsTableFilterComposer({
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

  ColumnFilters<String> get healthId => $composableBuilder(
    column: $table.healthId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get driveFileId => $composableBuilder(
    column: $table.driveFileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrescriptionsTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $PrescriptionsTable> {
  $$PrescriptionsTableOrderingComposer({
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

  ColumnOrderings<String> get healthId => $composableBuilder(
    column: $table.healthId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get driveFileId => $composableBuilder(
    column: $table.driveFileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrescriptionsTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $PrescriptionsTable> {
  $$PrescriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get healthId =>
      $composableBuilder(column: $table.healthId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get driveFileId => $composableBuilder(
    column: $table.driveFileId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$PrescriptionsTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $PrescriptionsTable,
          Prescription,
          $$PrescriptionsTableFilterComposer,
          $$PrescriptionsTableOrderingComposer,
          $$PrescriptionsTableAnnotationComposer,
          $$PrescriptionsTableCreateCompanionBuilder,
          $$PrescriptionsTableUpdateCompanionBuilder,
          (
            Prescription,
            BaseReferences<
              _$AppDriftDatabase,
              $PrescriptionsTable,
              Prescription
            >,
          ),
          Prescription,
          PrefetchHooks Function()
        > {
  $$PrescriptionsTableTableManager(
    _$AppDriftDatabase db,
    $PrescriptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrescriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrescriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrescriptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> healthId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> driveFileId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrescriptionsCompanion(
                id: id,
                healthId: healthId,
                description: description,
                imageUrl: imageUrl,
                driveFileId: driveFileId,
                createdAt: createdAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> healthId = const Value.absent(),
                required String description,
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> driveFileId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrescriptionsCompanion.insert(
                id: id,
                healthId: healthId,
                description: description,
                imageUrl: imageUrl,
                driveFileId: driveFileId,
                createdAt: createdAt,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrescriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $PrescriptionsTable,
      Prescription,
      $$PrescriptionsTableFilterComposer,
      $$PrescriptionsTableOrderingComposer,
      $$PrescriptionsTableAnnotationComposer,
      $$PrescriptionsTableCreateCompanionBuilder,
      $$PrescriptionsTableUpdateCompanionBuilder,
      (
        Prescription,
        BaseReferences<_$AppDriftDatabase, $PrescriptionsTable, Prescription>,
      ),
      Prescription,
      PrefetchHooks Function()
    >;
typedef $$PrescriptionMedicinesTableCreateCompanionBuilder =
    PrescriptionMedicinesCompanion Function({
      required String id,
      Value<String?> prescriptionId,
      required String medicineName,
      required String dosage,
      required String timings,
      required int durationDays,
      Value<String?> notes,
      Value<String?> healthId,
      Value<String?> userId,
      Value<String?> reminderConfig,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$PrescriptionMedicinesTableUpdateCompanionBuilder =
    PrescriptionMedicinesCompanion Function({
      Value<String> id,
      Value<String?> prescriptionId,
      Value<String> medicineName,
      Value<String> dosage,
      Value<String> timings,
      Value<int> durationDays,
      Value<String?> notes,
      Value<String?> healthId,
      Value<String?> userId,
      Value<String?> reminderConfig,
      Value<int> synced,
      Value<int> rowid,
    });

class $$PrescriptionMedicinesTableFilterComposer
    extends Composer<_$AppDriftDatabase, $PrescriptionMedicinesTable> {
  $$PrescriptionMedicinesTableFilterComposer({
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

  ColumnFilters<String> get prescriptionId => $composableBuilder(
    column: $table.prescriptionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicineName => $composableBuilder(
    column: $table.medicineName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dosage => $composableBuilder(
    column: $table.dosage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timings => $composableBuilder(
    column: $table.timings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get healthId => $composableBuilder(
    column: $table.healthId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderConfig => $composableBuilder(
    column: $table.reminderConfig,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrescriptionMedicinesTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $PrescriptionMedicinesTable> {
  $$PrescriptionMedicinesTableOrderingComposer({
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

  ColumnOrderings<String> get prescriptionId => $composableBuilder(
    column: $table.prescriptionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicineName => $composableBuilder(
    column: $table.medicineName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dosage => $composableBuilder(
    column: $table.dosage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timings => $composableBuilder(
    column: $table.timings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthId => $composableBuilder(
    column: $table.healthId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderConfig => $composableBuilder(
    column: $table.reminderConfig,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrescriptionMedicinesTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $PrescriptionMedicinesTable> {
  $$PrescriptionMedicinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get prescriptionId => $composableBuilder(
    column: $table.prescriptionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get medicineName => $composableBuilder(
    column: $table.medicineName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dosage =>
      $composableBuilder(column: $table.dosage, builder: (column) => column);

  GeneratedColumn<String> get timings =>
      $composableBuilder(column: $table.timings, builder: (column) => column);

  GeneratedColumn<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get healthId =>
      $composableBuilder(column: $table.healthId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get reminderConfig => $composableBuilder(
    column: $table.reminderConfig,
    builder: (column) => column,
  );

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$PrescriptionMedicinesTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $PrescriptionMedicinesTable,
          PrescriptionMedicine,
          $$PrescriptionMedicinesTableFilterComposer,
          $$PrescriptionMedicinesTableOrderingComposer,
          $$PrescriptionMedicinesTableAnnotationComposer,
          $$PrescriptionMedicinesTableCreateCompanionBuilder,
          $$PrescriptionMedicinesTableUpdateCompanionBuilder,
          (
            PrescriptionMedicine,
            BaseReferences<
              _$AppDriftDatabase,
              $PrescriptionMedicinesTable,
              PrescriptionMedicine
            >,
          ),
          PrescriptionMedicine,
          PrefetchHooks Function()
        > {
  $$PrescriptionMedicinesTableTableManager(
    _$AppDriftDatabase db,
    $PrescriptionMedicinesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrescriptionMedicinesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PrescriptionMedicinesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PrescriptionMedicinesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> prescriptionId = const Value.absent(),
                Value<String> medicineName = const Value.absent(),
                Value<String> dosage = const Value.absent(),
                Value<String> timings = const Value.absent(),
                Value<int> durationDays = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> healthId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> reminderConfig = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrescriptionMedicinesCompanion(
                id: id,
                prescriptionId: prescriptionId,
                medicineName: medicineName,
                dosage: dosage,
                timings: timings,
                durationDays: durationDays,
                notes: notes,
                healthId: healthId,
                userId: userId,
                reminderConfig: reminderConfig,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> prescriptionId = const Value.absent(),
                required String medicineName,
                required String dosage,
                required String timings,
                required int durationDays,
                Value<String?> notes = const Value.absent(),
                Value<String?> healthId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> reminderConfig = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrescriptionMedicinesCompanion.insert(
                id: id,
                prescriptionId: prescriptionId,
                medicineName: medicineName,
                dosage: dosage,
                timings: timings,
                durationDays: durationDays,
                notes: notes,
                healthId: healthId,
                userId: userId,
                reminderConfig: reminderConfig,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrescriptionMedicinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $PrescriptionMedicinesTable,
      PrescriptionMedicine,
      $$PrescriptionMedicinesTableFilterComposer,
      $$PrescriptionMedicinesTableOrderingComposer,
      $$PrescriptionMedicinesTableAnnotationComposer,
      $$PrescriptionMedicinesTableCreateCompanionBuilder,
      $$PrescriptionMedicinesTableUpdateCompanionBuilder,
      (
        PrescriptionMedicine,
        BaseReferences<
          _$AppDriftDatabase,
          $PrescriptionMedicinesTable,
          PrescriptionMedicine
        >,
      ),
      PrescriptionMedicine,
      PrefetchHooks Function()
    >;
typedef $$PrescriptionMedicineTimingsTableCreateCompanionBuilder =
    PrescriptionMedicineTimingsCompanion Function({
      required String id,
      Value<String?> prescriptionMedicineId,
      required DateTime timingDateTime,
      Value<DateTime?> medicineTakenTime,
      required String status,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$PrescriptionMedicineTimingsTableUpdateCompanionBuilder =
    PrescriptionMedicineTimingsCompanion Function({
      Value<String> id,
      Value<String?> prescriptionMedicineId,
      Value<DateTime> timingDateTime,
      Value<DateTime?> medicineTakenTime,
      Value<String> status,
      Value<int> synced,
      Value<int> rowid,
    });

class $$PrescriptionMedicineTimingsTableFilterComposer
    extends Composer<_$AppDriftDatabase, $PrescriptionMedicineTimingsTable> {
  $$PrescriptionMedicineTimingsTableFilterComposer({
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

  ColumnFilters<String> get prescriptionMedicineId => $composableBuilder(
    column: $table.prescriptionMedicineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timingDateTime => $composableBuilder(
    column: $table.timingDateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get medicineTakenTime => $composableBuilder(
    column: $table.medicineTakenTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrescriptionMedicineTimingsTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $PrescriptionMedicineTimingsTable> {
  $$PrescriptionMedicineTimingsTableOrderingComposer({
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

  ColumnOrderings<String> get prescriptionMedicineId => $composableBuilder(
    column: $table.prescriptionMedicineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timingDateTime => $composableBuilder(
    column: $table.timingDateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get medicineTakenTime => $composableBuilder(
    column: $table.medicineTakenTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrescriptionMedicineTimingsTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $PrescriptionMedicineTimingsTable> {
  $$PrescriptionMedicineTimingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get prescriptionMedicineId => $composableBuilder(
    column: $table.prescriptionMedicineId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timingDateTime => $composableBuilder(
    column: $table.timingDateTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get medicineTakenTime => $composableBuilder(
    column: $table.medicineTakenTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$PrescriptionMedicineTimingsTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $PrescriptionMedicineTimingsTable,
          PrescriptionMedicineTiming,
          $$PrescriptionMedicineTimingsTableFilterComposer,
          $$PrescriptionMedicineTimingsTableOrderingComposer,
          $$PrescriptionMedicineTimingsTableAnnotationComposer,
          $$PrescriptionMedicineTimingsTableCreateCompanionBuilder,
          $$PrescriptionMedicineTimingsTableUpdateCompanionBuilder,
          (
            PrescriptionMedicineTiming,
            BaseReferences<
              _$AppDriftDatabase,
              $PrescriptionMedicineTimingsTable,
              PrescriptionMedicineTiming
            >,
          ),
          PrescriptionMedicineTiming,
          PrefetchHooks Function()
        > {
  $$PrescriptionMedicineTimingsTableTableManager(
    _$AppDriftDatabase db,
    $PrescriptionMedicineTimingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrescriptionMedicineTimingsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PrescriptionMedicineTimingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PrescriptionMedicineTimingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> prescriptionMedicineId = const Value.absent(),
                Value<DateTime> timingDateTime = const Value.absent(),
                Value<DateTime?> medicineTakenTime = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrescriptionMedicineTimingsCompanion(
                id: id,
                prescriptionMedicineId: prescriptionMedicineId,
                timingDateTime: timingDateTime,
                medicineTakenTime: medicineTakenTime,
                status: status,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> prescriptionMedicineId = const Value.absent(),
                required DateTime timingDateTime,
                Value<DateTime?> medicineTakenTime = const Value.absent(),
                required String status,
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrescriptionMedicineTimingsCompanion.insert(
                id: id,
                prescriptionMedicineId: prescriptionMedicineId,
                timingDateTime: timingDateTime,
                medicineTakenTime: medicineTakenTime,
                status: status,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrescriptionMedicineTimingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $PrescriptionMedicineTimingsTable,
      PrescriptionMedicineTiming,
      $$PrescriptionMedicineTimingsTableFilterComposer,
      $$PrescriptionMedicineTimingsTableOrderingComposer,
      $$PrescriptionMedicineTimingsTableAnnotationComposer,
      $$PrescriptionMedicineTimingsTableCreateCompanionBuilder,
      $$PrescriptionMedicineTimingsTableUpdateCompanionBuilder,
      (
        PrescriptionMedicineTiming,
        BaseReferences<
          _$AppDriftDatabase,
          $PrescriptionMedicineTimingsTable,
          PrescriptionMedicineTiming
        >,
      ),
      PrescriptionMedicineTiming,
      PrefetchHooks Function()
    >;
typedef $$ReportsTableCreateCompanionBuilder =
    ReportsCompanion Function({
      required String id,
      required String reportType,
      Value<String?> detail,
      Value<String?> healthDataID,
      Value<String?> imageUrl,
      Value<String?> driveFileId,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<String?> createdBy,
      Value<bool> saved,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$ReportsTableUpdateCompanionBuilder =
    ReportsCompanion Function({
      Value<String> id,
      Value<String> reportType,
      Value<String?> detail,
      Value<String?> healthDataID,
      Value<String?> imageUrl,
      Value<String?> driveFileId,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<String?> createdBy,
      Value<bool> saved,
      Value<int> synced,
      Value<int> rowid,
    });

class $$ReportsTableFilterComposer
    extends Composer<_$AppDriftDatabase, $ReportsTable> {
  $$ReportsTableFilterComposer({
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

  ColumnFilters<String> get reportType => $composableBuilder(
    column: $table.reportType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get healthDataID => $composableBuilder(
    column: $table.healthDataID,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get driveFileId => $composableBuilder(
    column: $table.driveFileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get saved => $composableBuilder(
    column: $table.saved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReportsTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $ReportsTable> {
  $$ReportsTableOrderingComposer({
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

  ColumnOrderings<String> get reportType => $composableBuilder(
    column: $table.reportType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthDataID => $composableBuilder(
    column: $table.healthDataID,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get driveFileId => $composableBuilder(
    column: $table.driveFileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get saved => $composableBuilder(
    column: $table.saved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReportsTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $ReportsTable> {
  $$ReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reportType => $composableBuilder(
    column: $table.reportType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<String> get healthDataID => $composableBuilder(
    column: $table.healthDataID,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get driveFileId => $composableBuilder(
    column: $table.driveFileId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<bool> get saved =>
      $composableBuilder(column: $table.saved, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$ReportsTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $ReportsTable,
          Report,
          $$ReportsTableFilterComposer,
          $$ReportsTableOrderingComposer,
          $$ReportsTableAnnotationComposer,
          $$ReportsTableCreateCompanionBuilder,
          $$ReportsTableUpdateCompanionBuilder,
          (Report, BaseReferences<_$AppDriftDatabase, $ReportsTable, Report>),
          Report,
          PrefetchHooks Function()
        > {
  $$ReportsTableTableManager(_$AppDriftDatabase db, $ReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> reportType = const Value.absent(),
                Value<String?> detail = const Value.absent(),
                Value<String?> healthDataID = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> driveFileId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<bool> saved = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReportsCompanion(
                id: id,
                reportType: reportType,
                detail: detail,
                healthDataID: healthDataID,
                imageUrl: imageUrl,
                driveFileId: driveFileId,
                description: description,
                createdAt: createdAt,
                createdBy: createdBy,
                saved: saved,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String reportType,
                Value<String?> detail = const Value.absent(),
                Value<String?> healthDataID = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> driveFileId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<bool> saved = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReportsCompanion.insert(
                id: id,
                reportType: reportType,
                detail: detail,
                healthDataID: healthDataID,
                imageUrl: imageUrl,
                driveFileId: driveFileId,
                description: description,
                createdAt: createdAt,
                createdBy: createdBy,
                saved: saved,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $ReportsTable,
      Report,
      $$ReportsTableFilterComposer,
      $$ReportsTableOrderingComposer,
      $$ReportsTableAnnotationComposer,
      $$ReportsTableCreateCompanionBuilder,
      $$ReportsTableUpdateCompanionBuilder,
      (Report, BaseReferences<_$AppDriftDatabase, $ReportsTable, Report>),
      Report,
      PrefetchHooks Function()
    >;
typedef $$VitalsTableCreateCompanionBuilder =
    VitalsCompanion Function({
      required String id,
      required String vitalKey,
      required double value,
      required String unit,
      required DateTime createdAt,
      Value<String?> userId,
      Value<String?> data,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$VitalsTableUpdateCompanionBuilder =
    VitalsCompanion Function({
      Value<String> id,
      Value<String> vitalKey,
      Value<double> value,
      Value<String> unit,
      Value<DateTime> createdAt,
      Value<String?> userId,
      Value<String?> data,
      Value<int> synced,
      Value<int> rowid,
    });

class $$VitalsTableFilterComposer
    extends Composer<_$AppDriftDatabase, $VitalsTable> {
  $$VitalsTableFilterComposer({
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

  ColumnFilters<String> get vitalKey => $composableBuilder(
    column: $table.vitalKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VitalsTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $VitalsTable> {
  $$VitalsTableOrderingComposer({
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

  ColumnOrderings<String> get vitalKey => $composableBuilder(
    column: $table.vitalKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VitalsTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $VitalsTable> {
  $$VitalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vitalKey =>
      $composableBuilder(column: $table.vitalKey, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$VitalsTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $VitalsTable,
          Vital,
          $$VitalsTableFilterComposer,
          $$VitalsTableOrderingComposer,
          $$VitalsTableAnnotationComposer,
          $$VitalsTableCreateCompanionBuilder,
          $$VitalsTableUpdateCompanionBuilder,
          (Vital, BaseReferences<_$AppDriftDatabase, $VitalsTable, Vital>),
          Vital,
          PrefetchHooks Function()
        > {
  $$VitalsTableTableManager(_$AppDriftDatabase db, $VitalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VitalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VitalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VitalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vitalKey = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> data = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VitalsCompanion(
                id: id,
                vitalKey: vitalKey,
                value: value,
                unit: unit,
                createdAt: createdAt,
                userId: userId,
                data: data,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vitalKey,
                required double value,
                required String unit,
                required DateTime createdAt,
                Value<String?> userId = const Value.absent(),
                Value<String?> data = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VitalsCompanion.insert(
                id: id,
                vitalKey: vitalKey,
                value: value,
                unit: unit,
                createdAt: createdAt,
                userId: userId,
                data: data,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VitalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $VitalsTable,
      Vital,
      $$VitalsTableFilterComposer,
      $$VitalsTableOrderingComposer,
      $$VitalsTableAnnotationComposer,
      $$VitalsTableCreateCompanionBuilder,
      $$VitalsTableUpdateCompanionBuilder,
      (Vital, BaseReferences<_$AppDriftDatabase, $VitalsTable, Vital>),
      Vital,
      PrefetchHooks Function()
    >;

class $AppDriftDatabaseManager {
  final _$AppDriftDatabase _db;
  $AppDriftDatabaseManager(this._db);
  $$InitialSetupTableTableManager get initialSetup =>
      $$InitialSetupTableTableManager(_db, _db.initialSetup);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$UserEntitiesTableTableManager get userEntities =>
      $$UserEntitiesTableTableManager(_db, _db.userEntities);
  $$UserRelationsTableTableManager get userRelations =>
      $$UserRelationsTableTableManager(_db, _db.userRelations);
  $$FamiliesTableTableManager get families =>
      $$FamiliesTableTableManager(_db, _db.families);
  $$FamilyRequestsTableTableTableManager get familyRequestsTable =>
      $$FamilyRequestsTableTableTableManager(_db, _db.familyRequestsTable);
  $$FamilyMembersTableTableTableManager get familyMembersTable =>
      $$FamilyMembersTableTableTableManager(_db, _db.familyMembersTable);
  $$HealthDataTableTableTableManager get healthDataTable =>
      $$HealthDataTableTableTableManager(_db, _db.healthDataTable);
  $$CycleHistoriesTableTableManager get cycleHistories =>
      $$CycleHistoriesTableTableManager(_db, _db.cycleHistories);
  $$PregnanciesTableTableManager get pregnancies =>
      $$PregnanciesTableTableManager(_db, _db.pregnancies);
  $$PrescriptionsTableTableManager get prescriptions =>
      $$PrescriptionsTableTableManager(_db, _db.prescriptions);
  $$PrescriptionMedicinesTableTableManager get prescriptionMedicines =>
      $$PrescriptionMedicinesTableTableManager(_db, _db.prescriptionMedicines);
  $$PrescriptionMedicineTimingsTableTableManager
  get prescriptionMedicineTimings =>
      $$PrescriptionMedicineTimingsTableTableManager(
        _db,
        _db.prescriptionMedicineTimings,
      );
  $$ReportsTableTableManager get reports =>
      $$ReportsTableTableManager(_db, _db.reports);
  $$VitalsTableTableManager get vitals =>
      $$VitalsTableTableManager(_db, _db.vitals);
}
