// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_database.dart';

// ignore_for_file: type=lint
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
  static const VerificationMeta _profilePictureMeta = const VerificationMeta(
    'profilePicture',
  );
  @override
  late final GeneratedColumn<String> profilePicture = GeneratedColumn<String>(
    'profile_picture',
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
  static const VerificationMeta _addressLine1Meta = const VerificationMeta(
    'addressLine1',
  );
  @override
  late final GeneratedColumn<String> addressLine1 = GeneratedColumn<String>(
    'address_line_1',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressLine2Meta = const VerificationMeta(
    'addressLine2',
  );
  @override
  late final GeneratedColumn<String> addressLine2 = GeneratedColumn<String>(
    'address_line_2',
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
  static const VerificationMeta _isRegisteredMeta = const VerificationMeta(
    'isRegistered',
  );
  @override
  late final GeneratedColumn<bool> isRegistered = GeneratedColumn<bool>(
    'is_registered',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_registered" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
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
    emailVerified,
    coverPic,
    bio,
    gender,
    dob,
    profilePicture,
    userType,
    addressLine1,
    addressLine2,
    city,
    pincode,
    lat,
    lng,
    isRegistered,
    userName,
    deletedAt,
    createdAt,
    updatedAt,
    syncedAt,
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
    if (data.containsKey('email_verified')) {
      context.handle(
        _emailVerifiedMeta,
        emailVerified.isAcceptableOrUnknown(
          data['email_verified']!,
          _emailVerifiedMeta,
        ),
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
    if (data.containsKey('profile_picture')) {
      context.handle(
        _profilePictureMeta,
        profilePicture.isAcceptableOrUnknown(
          data['profile_picture']!,
          _profilePictureMeta,
        ),
      );
    }
    if (data.containsKey('user_type')) {
      context.handle(
        _userTypeMeta,
        userType.isAcceptableOrUnknown(data['user_type']!, _userTypeMeta),
      );
    }
    if (data.containsKey('address_line_1')) {
      context.handle(
        _addressLine1Meta,
        addressLine1.isAcceptableOrUnknown(
          data['address_line_1']!,
          _addressLine1Meta,
        ),
      );
    }
    if (data.containsKey('address_line_2')) {
      context.handle(
        _addressLine2Meta,
        addressLine2.isAcceptableOrUnknown(
          data['address_line_2']!,
          _addressLine2Meta,
        ),
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
    if (data.containsKey('is_registered')) {
      context.handle(
        _isRegisteredMeta,
        isRegistered.isAcceptableOrUnknown(
          data['is_registered']!,
          _isRegisteredMeta,
        ),
      );
    }
    if (data.containsKey('user_name')) {
      context.handle(
        _userNameMeta,
        userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
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
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
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
      emailVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}email_verified'],
      ),
      coverPic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_pic'],
      ),
      bio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bio'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      ),
      dob: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dob'],
      ),
      profilePicture: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_picture'],
      ),
      userType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_type'],
      )!,
      addressLine1: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address_line_1'],
      ),
      addressLine2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address_line_2'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      pincode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pincode'],
      ),
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      ),
      isRegistered: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_registered'],
      )!,
      userName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_name'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
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
  final DateTime? emailVerified;
  final String? coverPic;
  final String? bio;
  final String? gender;
  final DateTime? dob;
  final String? profilePicture;
  final String userType;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? pincode;
  final double? lat;
  final double? lng;
  final bool isRegistered;
  final String? userName;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final int synced;
  const User({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.phoneVerified,
    this.countryCode,
    this.emailVerified,
    this.coverPic,
    this.bio,
    this.gender,
    this.dob,
    this.profilePicture,
    required this.userType,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.pincode,
    this.lat,
    this.lng,
    required this.isRegistered,
    this.userName,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
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
    if (!nullToAbsent || emailVerified != null) {
      map['email_verified'] = Variable<DateTime>(emailVerified);
    }
    if (!nullToAbsent || coverPic != null) {
      map['cover_pic'] = Variable<String>(coverPic);
    }
    if (!nullToAbsent || bio != null) {
      map['bio'] = Variable<String>(bio);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || dob != null) {
      map['dob'] = Variable<DateTime>(dob);
    }
    if (!nullToAbsent || profilePicture != null) {
      map['profile_picture'] = Variable<String>(profilePicture);
    }
    map['user_type'] = Variable<String>(userType);
    if (!nullToAbsent || addressLine1 != null) {
      map['address_line_1'] = Variable<String>(addressLine1);
    }
    if (!nullToAbsent || addressLine2 != null) {
      map['address_line_2'] = Variable<String>(addressLine2);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || pincode != null) {
      map['pincode'] = Variable<String>(pincode);
    }
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    map['is_registered'] = Variable<bool>(isRegistered);
    if (!nullToAbsent || userName != null) {
      map['user_name'] = Variable<String>(userName);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
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
      emailVerified: emailVerified == null && nullToAbsent
          ? const Value.absent()
          : Value(emailVerified),
      coverPic: coverPic == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPic),
      bio: bio == null && nullToAbsent ? const Value.absent() : Value(bio),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
      dob: dob == null && nullToAbsent ? const Value.absent() : Value(dob),
      profilePicture: profilePicture == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePicture),
      userType: Value(userType),
      addressLine1: addressLine1 == null && nullToAbsent
          ? const Value.absent()
          : Value(addressLine1),
      addressLine2: addressLine2 == null && nullToAbsent
          ? const Value.absent()
          : Value(addressLine2),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      pincode: pincode == null && nullToAbsent
          ? const Value.absent()
          : Value(pincode),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      isRegistered: Value(isRegistered),
      userName: userName == null && nullToAbsent
          ? const Value.absent()
          : Value(userName),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
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
      emailVerified: serializer.fromJson<DateTime?>(json['emailVerified']),
      coverPic: serializer.fromJson<String?>(json['coverPic']),
      bio: serializer.fromJson<String?>(json['bio']),
      gender: serializer.fromJson<String?>(json['gender']),
      dob: serializer.fromJson<DateTime?>(json['dob']),
      profilePicture: serializer.fromJson<String?>(json['profilePicture']),
      userType: serializer.fromJson<String>(json['userType']),
      addressLine1: serializer.fromJson<String?>(json['addressLine1']),
      addressLine2: serializer.fromJson<String?>(json['addressLine2']),
      city: serializer.fromJson<String?>(json['city']),
      pincode: serializer.fromJson<String?>(json['pincode']),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      isRegistered: serializer.fromJson<bool>(json['isRegistered']),
      userName: serializer.fromJson<String?>(json['userName']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
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
      'emailVerified': serializer.toJson<DateTime?>(emailVerified),
      'coverPic': serializer.toJson<String?>(coverPic),
      'bio': serializer.toJson<String?>(bio),
      'gender': serializer.toJson<String?>(gender),
      'dob': serializer.toJson<DateTime?>(dob),
      'profilePicture': serializer.toJson<String?>(profilePicture),
      'userType': serializer.toJson<String>(userType),
      'addressLine1': serializer.toJson<String?>(addressLine1),
      'addressLine2': serializer.toJson<String?>(addressLine2),
      'city': serializer.toJson<String?>(city),
      'pincode': serializer.toJson<String?>(pincode),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'isRegistered': serializer.toJson<bool>(isRegistered),
      'userName': serializer.toJson<String?>(userName),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
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
    Value<DateTime?> emailVerified = const Value.absent(),
    Value<String?> coverPic = const Value.absent(),
    Value<String?> bio = const Value.absent(),
    Value<String?> gender = const Value.absent(),
    Value<DateTime?> dob = const Value.absent(),
    Value<String?> profilePicture = const Value.absent(),
    String? userType,
    Value<String?> addressLine1 = const Value.absent(),
    Value<String?> addressLine2 = const Value.absent(),
    Value<String?> city = const Value.absent(),
    Value<String?> pincode = const Value.absent(),
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    bool? isRegistered,
    Value<String?> userName = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
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
    emailVerified: emailVerified.present
        ? emailVerified.value
        : this.emailVerified,
    coverPic: coverPic.present ? coverPic.value : this.coverPic,
    bio: bio.present ? bio.value : this.bio,
    gender: gender.present ? gender.value : this.gender,
    dob: dob.present ? dob.value : this.dob,
    profilePicture: profilePicture.present
        ? profilePicture.value
        : this.profilePicture,
    userType: userType ?? this.userType,
    addressLine1: addressLine1.present ? addressLine1.value : this.addressLine1,
    addressLine2: addressLine2.present ? addressLine2.value : this.addressLine2,
    city: city.present ? city.value : this.city,
    pincode: pincode.present ? pincode.value : this.pincode,
    lat: lat.present ? lat.value : this.lat,
    lng: lng.present ? lng.value : this.lng,
    isRegistered: isRegistered ?? this.isRegistered,
    userName: userName.present ? userName.value : this.userName,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
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
      emailVerified: data.emailVerified.present
          ? data.emailVerified.value
          : this.emailVerified,
      coverPic: data.coverPic.present ? data.coverPic.value : this.coverPic,
      bio: data.bio.present ? data.bio.value : this.bio,
      gender: data.gender.present ? data.gender.value : this.gender,
      dob: data.dob.present ? data.dob.value : this.dob,
      profilePicture: data.profilePicture.present
          ? data.profilePicture.value
          : this.profilePicture,
      userType: data.userType.present ? data.userType.value : this.userType,
      addressLine1: data.addressLine1.present
          ? data.addressLine1.value
          : this.addressLine1,
      addressLine2: data.addressLine2.present
          ? data.addressLine2.value
          : this.addressLine2,
      city: data.city.present ? data.city.value : this.city,
      pincode: data.pincode.present ? data.pincode.value : this.pincode,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      isRegistered: data.isRegistered.present
          ? data.isRegistered.value
          : this.isRegistered,
      userName: data.userName.present ? data.userName.value : this.userName,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
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
          ..write('emailVerified: $emailVerified, ')
          ..write('coverPic: $coverPic, ')
          ..write('bio: $bio, ')
          ..write('gender: $gender, ')
          ..write('dob: $dob, ')
          ..write('profilePicture: $profilePicture, ')
          ..write('userType: $userType, ')
          ..write('addressLine1: $addressLine1, ')
          ..write('addressLine2: $addressLine2, ')
          ..write('city: $city, ')
          ..write('pincode: $pincode, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('isRegistered: $isRegistered, ')
          ..write('userName: $userName, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
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
    emailVerified,
    coverPic,
    bio,
    gender,
    dob,
    profilePicture,
    userType,
    addressLine1,
    addressLine2,
    city,
    pincode,
    lat,
    lng,
    isRegistered,
    userName,
    deletedAt,
    createdAt,
    updatedAt,
    syncedAt,
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
          other.emailVerified == this.emailVerified &&
          other.coverPic == this.coverPic &&
          other.bio == this.bio &&
          other.gender == this.gender &&
          other.dob == this.dob &&
          other.profilePicture == this.profilePicture &&
          other.userType == this.userType &&
          other.addressLine1 == this.addressLine1 &&
          other.addressLine2 == this.addressLine2 &&
          other.city == this.city &&
          other.pincode == this.pincode &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.isRegistered == this.isRegistered &&
          other.userName == this.userName &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.synced == this.synced);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> email;
  final Value<String?> phone;
  final Value<DateTime?> phoneVerified;
  final Value<String?> countryCode;
  final Value<DateTime?> emailVerified;
  final Value<String?> coverPic;
  final Value<String?> bio;
  final Value<String?> gender;
  final Value<DateTime?> dob;
  final Value<String?> profilePicture;
  final Value<String> userType;
  final Value<String?> addressLine1;
  final Value<String?> addressLine2;
  final Value<String?> city;
  final Value<String?> pincode;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<bool> isRegistered;
  final Value<String?> userName;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> synced;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.phoneVerified = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.emailVerified = const Value.absent(),
    this.coverPic = const Value.absent(),
    this.bio = const Value.absent(),
    this.gender = const Value.absent(),
    this.dob = const Value.absent(),
    this.profilePicture = const Value.absent(),
    this.userType = const Value.absent(),
    this.addressLine1 = const Value.absent(),
    this.addressLine2 = const Value.absent(),
    this.city = const Value.absent(),
    this.pincode = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.isRegistered = const Value.absent(),
    this.userName = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
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
    this.emailVerified = const Value.absent(),
    this.coverPic = const Value.absent(),
    this.bio = const Value.absent(),
    this.gender = const Value.absent(),
    this.dob = const Value.absent(),
    this.profilePicture = const Value.absent(),
    this.userType = const Value.absent(),
    this.addressLine1 = const Value.absent(),
    this.addressLine2 = const Value.absent(),
    this.city = const Value.absent(),
    this.pincode = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.isRegistered = const Value.absent(),
    this.userName = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
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
    Expression<DateTime>? emailVerified,
    Expression<String>? coverPic,
    Expression<String>? bio,
    Expression<String>? gender,
    Expression<DateTime>? dob,
    Expression<String>? profilePicture,
    Expression<String>? userType,
    Expression<String>? addressLine1,
    Expression<String>? addressLine2,
    Expression<String>? city,
    Expression<String>? pincode,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<bool>? isRegistered,
    Expression<String>? userName,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
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
      if (emailVerified != null) 'email_verified': emailVerified,
      if (coverPic != null) 'cover_pic': coverPic,
      if (bio != null) 'bio': bio,
      if (gender != null) 'gender': gender,
      if (dob != null) 'dob': dob,
      if (profilePicture != null) 'profile_picture': profilePicture,
      if (userType != null) 'user_type': userType,
      if (addressLine1 != null) 'address_line_1': addressLine1,
      if (addressLine2 != null) 'address_line_2': addressLine2,
      if (city != null) 'city': city,
      if (pincode != null) 'pincode': pincode,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (isRegistered != null) 'is_registered': isRegistered,
      if (userName != null) 'user_name': userName,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
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
    Value<DateTime?>? emailVerified,
    Value<String?>? coverPic,
    Value<String?>? bio,
    Value<String?>? gender,
    Value<DateTime?>? dob,
    Value<String?>? profilePicture,
    Value<String>? userType,
    Value<String?>? addressLine1,
    Value<String?>? addressLine2,
    Value<String?>? city,
    Value<String?>? pincode,
    Value<double?>? lat,
    Value<double?>? lng,
    Value<bool>? isRegistered,
    Value<String?>? userName,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
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
      emailVerified: emailVerified ?? this.emailVerified,
      coverPic: coverPic ?? this.coverPic,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      profilePicture: profilePicture ?? this.profilePicture,
      userType: userType ?? this.userType,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isRegistered: isRegistered ?? this.isRegistered,
      userName: userName ?? this.userName,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
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
    if (emailVerified.present) {
      map['email_verified'] = Variable<DateTime>(emailVerified.value);
    }
    if (coverPic.present) {
      map['cover_pic'] = Variable<String>(coverPic.value);
    }
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (dob.present) {
      map['dob'] = Variable<DateTime>(dob.value);
    }
    if (profilePicture.present) {
      map['profile_picture'] = Variable<String>(profilePicture.value);
    }
    if (userType.present) {
      map['user_type'] = Variable<String>(userType.value);
    }
    if (addressLine1.present) {
      map['address_line_1'] = Variable<String>(addressLine1.value);
    }
    if (addressLine2.present) {
      map['address_line_2'] = Variable<String>(addressLine2.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (pincode.present) {
      map['pincode'] = Variable<String>(pincode.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (isRegistered.present) {
      map['is_registered'] = Variable<bool>(isRegistered.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
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
          ..write('emailVerified: $emailVerified, ')
          ..write('coverPic: $coverPic, ')
          ..write('bio: $bio, ')
          ..write('gender: $gender, ')
          ..write('dob: $dob, ')
          ..write('profilePicture: $profilePicture, ')
          ..write('userType: $userType, ')
          ..write('addressLine1: $addressLine1, ')
          ..write('addressLine2: $addressLine2, ')
          ..write('city: $city, ')
          ..write('pincode: $pincode, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('isRegistered: $isRegistered, ')
          ..write('userName: $userName, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserLoginsTableTable extends UserLoginsTable
    with TableInfo<$UserLoginsTableTable, UserLoginsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserLoginsTableTable(this.attachedDatabase, [this._alias]);
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
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ipAddressMeta = const VerificationMeta(
    'ipAddress',
  );
  @override
  late final GeneratedColumn<String> ipAddress = GeneratedColumn<String>(
    'ip_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceTypeMeta = const VerificationMeta(
    'deviceType',
  );
  @override
  late final GeneratedColumn<String> deviceType = GeneratedColumn<String>(
    'device_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<String> latitude = GeneratedColumn<String>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<String> longitude = GeneratedColumn<String>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revokedAtMeta = const VerificationMeta(
    'revokedAt',
  );
  @override
  late final GeneratedColumn<DateTime> revokedAt = GeneratedColumn<DateTime>(
    'revoked_at',
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
  static const VerificationMeta _fcmTokenMeta = const VerificationMeta(
    'fcmToken',
  );
  @override
  late final GeneratedColumn<String> fcmToken = GeneratedColumn<String>(
    'fcm_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAccessedAtMeta = const VerificationMeta(
    'lastAccessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>(
        'last_accessed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _loggedOutAtMeta = const VerificationMeta(
    'loggedOutAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedOutAt = GeneratedColumn<DateTime>(
    'logged_out_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    ipAddress,
    deviceType,
    location,
    latitude,
    longitude,
    revokedAt,
    createdAt,
    fcmToken,
    lastAccessedAt,
    loggedOutAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_logins';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserLoginsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('ip_address')) {
      context.handle(
        _ipAddressMeta,
        ipAddress.isAcceptableOrUnknown(data['ip_address']!, _ipAddressMeta),
      );
    }
    if (data.containsKey('device_type')) {
      context.handle(
        _deviceTypeMeta,
        deviceType.isAcceptableOrUnknown(data['device_type']!, _deviceTypeMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('revoked_at')) {
      context.handle(
        _revokedAtMeta,
        revokedAt.isAcceptableOrUnknown(data['revoked_at']!, _revokedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('fcm_token')) {
      context.handle(
        _fcmTokenMeta,
        fcmToken.isAcceptableOrUnknown(data['fcm_token']!, _fcmTokenMeta),
      );
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
        _lastAccessedAtMeta,
        lastAccessedAt.isAcceptableOrUnknown(
          data['last_accessed_at']!,
          _lastAccessedAtMeta,
        ),
      );
    }
    if (data.containsKey('logged_out_at')) {
      context.handle(
        _loggedOutAtMeta,
        loggedOutAt.isAcceptableOrUnknown(
          data['logged_out_at']!,
          _loggedOutAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserLoginsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserLoginsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      ipAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ip_address'],
      ),
      deviceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_type'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}longitude'],
      ),
      revokedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}revoked_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      fcmToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fcm_token'],
      ),
      lastAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_accessed_at'],
      ),
      loggedOutAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_out_at'],
      ),
    );
  }

  @override
  $UserLoginsTableTable createAlias(String alias) {
    return $UserLoginsTableTable(attachedDatabase, alias);
  }
}

class UserLoginsTableData extends DataClass
    implements Insertable<UserLoginsTableData> {
  final String id;
  final String userId;
  final String? ipAddress;
  final String? deviceType;
  final String? location;
  final String? latitude;
  final String? longitude;
  final DateTime? revokedAt;
  final DateTime createdAt;
  final String? fcmToken;
  final DateTime? lastAccessedAt;
  final DateTime? loggedOutAt;
  const UserLoginsTableData({
    required this.id,
    required this.userId,
    this.ipAddress,
    this.deviceType,
    this.location,
    this.latitude,
    this.longitude,
    this.revokedAt,
    required this.createdAt,
    this.fcmToken,
    this.lastAccessedAt,
    this.loggedOutAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || ipAddress != null) {
      map['ip_address'] = Variable<String>(ipAddress);
    }
    if (!nullToAbsent || deviceType != null) {
      map['device_type'] = Variable<String>(deviceType);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<String>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<String>(longitude);
    }
    if (!nullToAbsent || revokedAt != null) {
      map['revoked_at'] = Variable<DateTime>(revokedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || fcmToken != null) {
      map['fcm_token'] = Variable<String>(fcmToken);
    }
    if (!nullToAbsent || lastAccessedAt != null) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    }
    if (!nullToAbsent || loggedOutAt != null) {
      map['logged_out_at'] = Variable<DateTime>(loggedOutAt);
    }
    return map;
  }

  UserLoginsTableCompanion toCompanion(bool nullToAbsent) {
    return UserLoginsTableCompanion(
      id: Value(id),
      userId: Value(userId),
      ipAddress: ipAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(ipAddress),
      deviceType: deviceType == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceType),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      revokedAt: revokedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(revokedAt),
      createdAt: Value(createdAt),
      fcmToken: fcmToken == null && nullToAbsent
          ? const Value.absent()
          : Value(fcmToken),
      lastAccessedAt: lastAccessedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAccessedAt),
      loggedOutAt: loggedOutAt == null && nullToAbsent
          ? const Value.absent()
          : Value(loggedOutAt),
    );
  }

  factory UserLoginsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserLoginsTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      ipAddress: serializer.fromJson<String?>(json['ipAddress']),
      deviceType: serializer.fromJson<String?>(json['deviceType']),
      location: serializer.fromJson<String?>(json['location']),
      latitude: serializer.fromJson<String?>(json['latitude']),
      longitude: serializer.fromJson<String?>(json['longitude']),
      revokedAt: serializer.fromJson<DateTime?>(json['revokedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      fcmToken: serializer.fromJson<String?>(json['fcmToken']),
      lastAccessedAt: serializer.fromJson<DateTime?>(json['lastAccessedAt']),
      loggedOutAt: serializer.fromJson<DateTime?>(json['loggedOutAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'ipAddress': serializer.toJson<String?>(ipAddress),
      'deviceType': serializer.toJson<String?>(deviceType),
      'location': serializer.toJson<String?>(location),
      'latitude': serializer.toJson<String?>(latitude),
      'longitude': serializer.toJson<String?>(longitude),
      'revokedAt': serializer.toJson<DateTime?>(revokedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'fcmToken': serializer.toJson<String?>(fcmToken),
      'lastAccessedAt': serializer.toJson<DateTime?>(lastAccessedAt),
      'loggedOutAt': serializer.toJson<DateTime?>(loggedOutAt),
    };
  }

  UserLoginsTableData copyWith({
    String? id,
    String? userId,
    Value<String?> ipAddress = const Value.absent(),
    Value<String?> deviceType = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> latitude = const Value.absent(),
    Value<String?> longitude = const Value.absent(),
    Value<DateTime?> revokedAt = const Value.absent(),
    DateTime? createdAt,
    Value<String?> fcmToken = const Value.absent(),
    Value<DateTime?> lastAccessedAt = const Value.absent(),
    Value<DateTime?> loggedOutAt = const Value.absent(),
  }) => UserLoginsTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    ipAddress: ipAddress.present ? ipAddress.value : this.ipAddress,
    deviceType: deviceType.present ? deviceType.value : this.deviceType,
    location: location.present ? location.value : this.location,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    revokedAt: revokedAt.present ? revokedAt.value : this.revokedAt,
    createdAt: createdAt ?? this.createdAt,
    fcmToken: fcmToken.present ? fcmToken.value : this.fcmToken,
    lastAccessedAt: lastAccessedAt.present
        ? lastAccessedAt.value
        : this.lastAccessedAt,
    loggedOutAt: loggedOutAt.present ? loggedOutAt.value : this.loggedOutAt,
  );
  UserLoginsTableData copyWithCompanion(UserLoginsTableCompanion data) {
    return UserLoginsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      ipAddress: data.ipAddress.present ? data.ipAddress.value : this.ipAddress,
      deviceType: data.deviceType.present
          ? data.deviceType.value
          : this.deviceType,
      location: data.location.present ? data.location.value : this.location,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      revokedAt: data.revokedAt.present ? data.revokedAt.value : this.revokedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      fcmToken: data.fcmToken.present ? data.fcmToken.value : this.fcmToken,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
      loggedOutAt: data.loggedOutAt.present
          ? data.loggedOutAt.value
          : this.loggedOutAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserLoginsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('deviceType: $deviceType, ')
          ..write('location: $location, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('fcmToken: $fcmToken, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('loggedOutAt: $loggedOutAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    ipAddress,
    deviceType,
    location,
    latitude,
    longitude,
    revokedAt,
    createdAt,
    fcmToken,
    lastAccessedAt,
    loggedOutAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserLoginsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.ipAddress == this.ipAddress &&
          other.deviceType == this.deviceType &&
          other.location == this.location &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.revokedAt == this.revokedAt &&
          other.createdAt == this.createdAt &&
          other.fcmToken == this.fcmToken &&
          other.lastAccessedAt == this.lastAccessedAt &&
          other.loggedOutAt == this.loggedOutAt);
}

class UserLoginsTableCompanion extends UpdateCompanion<UserLoginsTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> ipAddress;
  final Value<String?> deviceType;
  final Value<String?> location;
  final Value<String?> latitude;
  final Value<String?> longitude;
  final Value<DateTime?> revokedAt;
  final Value<DateTime> createdAt;
  final Value<String?> fcmToken;
  final Value<DateTime?> lastAccessedAt;
  final Value<DateTime?> loggedOutAt;
  final Value<int> rowid;
  const UserLoginsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.ipAddress = const Value.absent(),
    this.deviceType = const Value.absent(),
    this.location = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.fcmToken = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.loggedOutAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserLoginsTableCompanion.insert({
    required String id,
    required String userId,
    this.ipAddress = const Value.absent(),
    this.deviceType = const Value.absent(),
    this.location = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.fcmToken = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.loggedOutAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId);
  static Insertable<UserLoginsTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? ipAddress,
    Expression<String>? deviceType,
    Expression<String>? location,
    Expression<String>? latitude,
    Expression<String>? longitude,
    Expression<DateTime>? revokedAt,
    Expression<DateTime>? createdAt,
    Expression<String>? fcmToken,
    Expression<DateTime>? lastAccessedAt,
    Expression<DateTime>? loggedOutAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (ipAddress != null) 'ip_address': ipAddress,
      if (deviceType != null) 'device_type': deviceType,
      if (location != null) 'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (revokedAt != null) 'revoked_at': revokedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (fcmToken != null) 'fcm_token': fcmToken,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (loggedOutAt != null) 'logged_out_at': loggedOutAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserLoginsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String?>? ipAddress,
    Value<String?>? deviceType,
    Value<String?>? location,
    Value<String?>? latitude,
    Value<String?>? longitude,
    Value<DateTime?>? revokedAt,
    Value<DateTime>? createdAt,
    Value<String?>? fcmToken,
    Value<DateTime?>? lastAccessedAt,
    Value<DateTime?>? loggedOutAt,
    Value<int>? rowid,
  }) {
    return UserLoginsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ipAddress: ipAddress ?? this.ipAddress,
      deviceType: deviceType ?? this.deviceType,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      revokedAt: revokedAt ?? this.revokedAt,
      createdAt: createdAt ?? this.createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      loggedOutAt: loggedOutAt ?? this.loggedOutAt,
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
      map['user_id'] = Variable<String>(userId.value);
    }
    if (ipAddress.present) {
      map['ip_address'] = Variable<String>(ipAddress.value);
    }
    if (deviceType.present) {
      map['device_type'] = Variable<String>(deviceType.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<String>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<String>(longitude.value);
    }
    if (revokedAt.present) {
      map['revoked_at'] = Variable<DateTime>(revokedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (fcmToken.present) {
      map['fcm_token'] = Variable<String>(fcmToken.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (loggedOutAt.present) {
      map['logged_out_at'] = Variable<DateTime>(loggedOutAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserLoginsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('deviceType: $deviceType, ')
          ..write('location: $location, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('fcmToken: $fcmToken, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('loggedOutAt: $loggedOutAt, ')
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
    'user_id',
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
  static const VerificationMeta _rchIdMeta = const VerificationMeta('rchId');
  @override
  late final GeneratedColumn<String> rchId = GeneratedColumn<String>(
    'rch_id',
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
  static const VerificationMeta _medicalConditionMeta = const VerificationMeta(
    'medicalCondition',
  );
  @override
  late final GeneratedColumn<String> medicalCondition = GeneratedColumn<String>(
    'medical_condition',
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
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
    userId,
    lmpDate,
    rchId,
    allergies,
    medicalCondition,
    createdAt,
    updatedAt,
    syncedAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_data';
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
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('lmp_date')) {
      context.handle(
        _lmpDateMeta,
        lmpDate.isAcceptableOrUnknown(data['lmp_date']!, _lmpDateMeta),
      );
    }
    if (data.containsKey('rch_id')) {
      context.handle(
        _rchIdMeta,
        rchId.isAcceptableOrUnknown(data['rch_id']!, _rchIdMeta),
      );
    }
    if (data.containsKey('allergies')) {
      context.handle(
        _allergiesMeta,
        allergies.isAcceptableOrUnknown(data['allergies']!, _allergiesMeta),
      );
    }
    if (data.containsKey('medical_condition')) {
      context.handle(
        _medicalConditionMeta,
        medicalCondition.isAcceptableOrUnknown(
          data['medical_condition']!,
          _medicalConditionMeta,
        ),
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
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
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
        data['${effectivePrefix}user_id'],
      )!,
      lmpDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}lmp_date'],
      ),
      rchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rch_id'],
      ),
      allergies: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allergies'],
      ),
      medicalCondition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medical_condition'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
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
  final String userId;
  final DateTime? lmpDate;
  final String? rchId;
  final String? allergies;
  final String? medicalCondition;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final int synced;
  const HealthDataTableData({
    required this.id,
    required this.userId,
    this.lmpDate,
    this.rchId,
    this.allergies,
    this.medicalCondition,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || lmpDate != null) {
      map['lmp_date'] = Variable<DateTime>(lmpDate);
    }
    if (!nullToAbsent || rchId != null) {
      map['rch_id'] = Variable<String>(rchId);
    }
    if (!nullToAbsent || allergies != null) {
      map['allergies'] = Variable<String>(allergies);
    }
    if (!nullToAbsent || medicalCondition != null) {
      map['medical_condition'] = Variable<String>(medicalCondition);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  HealthDataTableCompanion toCompanion(bool nullToAbsent) {
    return HealthDataTableCompanion(
      id: Value(id),
      userId: Value(userId),
      lmpDate: lmpDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lmpDate),
      rchId: rchId == null && nullToAbsent
          ? const Value.absent()
          : Value(rchId),
      allergies: allergies == null && nullToAbsent
          ? const Value.absent()
          : Value(allergies),
      medicalCondition: medicalCondition == null && nullToAbsent
          ? const Value.absent()
          : Value(medicalCondition),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
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
      userId: serializer.fromJson<String>(json['userId']),
      lmpDate: serializer.fromJson<DateTime?>(json['lmpDate']),
      rchId: serializer.fromJson<String?>(json['rchId']),
      allergies: serializer.fromJson<String?>(json['allergies']),
      medicalCondition: serializer.fromJson<String?>(json['medicalCondition']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'lmpDate': serializer.toJson<DateTime?>(lmpDate),
      'rchId': serializer.toJson<String?>(rchId),
      'allergies': serializer.toJson<String?>(allergies),
      'medicalCondition': serializer.toJson<String?>(medicalCondition),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  HealthDataTableData copyWith({
    String? id,
    String? userId,
    Value<DateTime?> lmpDate = const Value.absent(),
    Value<String?> rchId = const Value.absent(),
    Value<String?> allergies = const Value.absent(),
    Value<String?> medicalCondition = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    int? synced,
  }) => HealthDataTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    lmpDate: lmpDate.present ? lmpDate.value : this.lmpDate,
    rchId: rchId.present ? rchId.value : this.rchId,
    allergies: allergies.present ? allergies.value : this.allergies,
    medicalCondition: medicalCondition.present
        ? medicalCondition.value
        : this.medicalCondition,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    synced: synced ?? this.synced,
  );
  HealthDataTableData copyWithCompanion(HealthDataTableCompanion data) {
    return HealthDataTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      lmpDate: data.lmpDate.present ? data.lmpDate.value : this.lmpDate,
      rchId: data.rchId.present ? data.rchId.value : this.rchId,
      allergies: data.allergies.present ? data.allergies.value : this.allergies,
      medicalCondition: data.medicalCondition.present
          ? data.medicalCondition.value
          : this.medicalCondition,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthDataTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('lmpDate: $lmpDate, ')
          ..write('rchId: $rchId, ')
          ..write('allergies: $allergies, ')
          ..write('medicalCondition: $medicalCondition, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    lmpDate,
    rchId,
    allergies,
    medicalCondition,
    createdAt,
    updatedAt,
    syncedAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthDataTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.lmpDate == this.lmpDate &&
          other.rchId == this.rchId &&
          other.allergies == this.allergies &&
          other.medicalCondition == this.medicalCondition &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.synced == this.synced);
}

class HealthDataTableCompanion extends UpdateCompanion<HealthDataTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime?> lmpDate;
  final Value<String?> rchId;
  final Value<String?> allergies;
  final Value<String?> medicalCondition;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> synced;
  final Value<int> rowid;
  const HealthDataTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.lmpDate = const Value.absent(),
    this.rchId = const Value.absent(),
    this.allergies = const Value.absent(),
    this.medicalCondition = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HealthDataTableCompanion.insert({
    required String id,
    required String userId,
    this.lmpDate = const Value.absent(),
    this.rchId = const Value.absent(),
    this.allergies = const Value.absent(),
    this.medicalCondition = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId);
  static Insertable<HealthDataTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<DateTime>? lmpDate,
    Expression<String>? rchId,
    Expression<String>? allergies,
    Expression<String>? medicalCondition,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (lmpDate != null) 'lmp_date': lmpDate,
      if (rchId != null) 'rch_id': rchId,
      if (allergies != null) 'allergies': allergies,
      if (medicalCondition != null) 'medical_condition': medicalCondition,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HealthDataTableCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<DateTime?>? lmpDate,
    Value<String?>? rchId,
    Value<String?>? allergies,
    Value<String?>? medicalCondition,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return HealthDataTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lmpDate: lmpDate ?? this.lmpDate,
      rchId: rchId ?? this.rchId,
      allergies: allergies ?? this.allergies,
      medicalCondition: medicalCondition ?? this.medicalCondition,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
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
      map['user_id'] = Variable<String>(userId.value);
    }
    if (lmpDate.present) {
      map['lmp_date'] = Variable<DateTime>(lmpDate.value);
    }
    if (rchId.present) {
      map['rch_id'] = Variable<String>(rchId.value);
    }
    if (allergies.present) {
      map['allergies'] = Variable<String>(allergies.value);
    }
    if (medicalCondition.present) {
      map['medical_condition'] = Variable<String>(medicalCondition.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
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
          ..write('lmpDate: $lmpDate, ')
          ..write('rchId: $rchId, ')
          ..write('allergies: $allergies, ')
          ..write('medicalCondition: $medicalCondition, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VitalsStreamTableTable extends VitalsStreamTable
    with TableInfo<$VitalsStreamTableTable, VitalsStreamTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VitalsStreamTableTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'createdAt',
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
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
    healthId,
    key,
    value,
    unit,
    data,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vitals_stream';
  @override
  VerificationContext validateIntegrity(
    Insertable<VitalsStreamTableData> instance, {
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
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    }
    if (data.containsKey('createdAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['createdAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
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
  VitalsStreamTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VitalsStreamTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      healthId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_id'],
      ),
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}createdAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $VitalsStreamTableTable createAlias(String alias) {
    return $VitalsStreamTableTable(attachedDatabase, alias);
  }
}

class VitalsStreamTableData extends DataClass
    implements Insertable<VitalsStreamTableData> {
  final String id;
  final String? healthId;
  final String key;
  final double? value;
  final String? unit;
  final String? data;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? syncedAt;
  final int synced;
  const VitalsStreamTableData({
    required this.id,
    this.healthId,
    required this.key,
    this.value,
    this.unit,
    this.data,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncedAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || healthId != null) {
      map['health_id'] = Variable<String>(healthId);
    }
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<double>(value);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || data != null) {
      map['data'] = Variable<String>(data);
    }
    map['createdAt'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  VitalsStreamTableCompanion toCompanion(bool nullToAbsent) {
    return VitalsStreamTableCompanion(
      id: Value(id),
      healthId: healthId == null && nullToAbsent
          ? const Value.absent()
          : Value(healthId),
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      data: data == null && nullToAbsent ? const Value.absent() : Value(data),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      synced: Value(synced),
    );
  }

  factory VitalsStreamTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VitalsStreamTableData(
      id: serializer.fromJson<String>(json['id']),
      healthId: serializer.fromJson<String?>(json['healthId']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<double?>(json['value']),
      unit: serializer.fromJson<String?>(json['unit']),
      data: serializer.fromJson<String?>(json['data']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'healthId': serializer.toJson<String?>(healthId),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<double?>(value),
      'unit': serializer.toJson<String?>(unit),
      'data': serializer.toJson<String?>(data),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  VitalsStreamTableData copyWith({
    String? id,
    Value<String?> healthId = const Value.absent(),
    String? key,
    Value<double?> value = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<String?> data = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    int? synced,
  }) => VitalsStreamTableData(
    id: id ?? this.id,
    healthId: healthId.present ? healthId.value : this.healthId,
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
    unit: unit.present ? unit.value : this.unit,
    data: data.present ? data.value : this.data,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    synced: synced ?? this.synced,
  );
  VitalsStreamTableData copyWithCompanion(VitalsStreamTableCompanion data) {
    return VitalsStreamTableData(
      id: data.id.present ? data.id.value : this.id,
      healthId: data.healthId.present ? data.healthId.value : this.healthId,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      unit: data.unit.present ? data.unit.value : this.unit,
      data: data.data.present ? data.data.value : this.data,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VitalsStreamTableData(')
          ..write('id: $id, ')
          ..write('healthId: $healthId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('data: $data, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    healthId,
    key,
    value,
    unit,
    data,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VitalsStreamTableData &&
          other.id == this.id &&
          other.healthId == this.healthId &&
          other.key == this.key &&
          other.value == this.value &&
          other.unit == this.unit &&
          other.data == this.data &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncedAt == this.syncedAt &&
          other.synced == this.synced);
}

class VitalsStreamTableCompanion
    extends UpdateCompanion<VitalsStreamTableData> {
  final Value<String> id;
  final Value<String?> healthId;
  final Value<String> key;
  final Value<double?> value;
  final Value<String?> unit;
  final Value<String?> data;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> synced;
  final Value<int> rowid;
  const VitalsStreamTableCompanion({
    this.id = const Value.absent(),
    this.healthId = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.data = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VitalsStreamTableCompanion.insert({
    required String id,
    this.healthId = const Value.absent(),
    required String key,
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.data = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       key = Value(key);
  static Insertable<VitalsStreamTableData> custom({
    Expression<String>? id,
    Expression<String>? healthId,
    Expression<String>? key,
    Expression<double>? value,
    Expression<String>? unit,
    Expression<String>? data,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (healthId != null) 'health_id': healthId,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (data != null) 'data': data,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VitalsStreamTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? healthId,
    Value<String>? key,
    Value<double?>? value,
    Value<String?>? unit,
    Value<String?>? data,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return VitalsStreamTableCompanion(
      id: id ?? this.id,
      healthId: healthId ?? this.healthId,
      key: key ?? this.key,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncedAt: syncedAt ?? this.syncedAt,
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
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (createdAt.present) {
      map['createdAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
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
    return (StringBuffer('VitalsStreamTableCompanion(')
          ..write('id: $id, ')
          ..write('healthId: $healthId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('data: $data, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt, ')
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
  static const VerificationMeta _eddDateMeta = const VerificationMeta(
    'eddDate',
  );
  @override
  late final GeneratedColumn<DateTime> eddDate = GeneratedColumn<DateTime>(
    'edd_date',
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
  static const VerificationMeta _deliveryDateTimeMeta = const VerificationMeta(
    'deliveryDateTime',
  );
  @override
  late final GeneratedColumn<DateTime> deliveryDateTime =
      GeneratedColumn<DateTime>(
        'delivery_date_time',
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
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
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
    lmpDate,
    eddDate,
    healthId,
    deliveryDateTime,
    status,
    createdBy,
    data,
    highestRiskStatus,
    allFlaggedComplications,
    riskStatus,
    flaggedComplications,
    overallHealth,
    gravidity,
    parity,
    livingChildren,
    abortions,
    stillBirths,
    miscarriages,
    csectionDeliveries,
    obstetricCode,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pregnancy';
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
    if (data.containsKey('edd_date')) {
      context.handle(
        _eddDateMeta,
        eddDate.isAcceptableOrUnknown(data['edd_date']!, _eddDateMeta),
      );
    }
    if (data.containsKey('health_id')) {
      context.handle(
        _healthIdMeta,
        healthId.isAcceptableOrUnknown(data['health_id']!, _healthIdMeta),
      );
    }
    if (data.containsKey('delivery_date_time')) {
      context.handle(
        _deliveryDateTimeMeta,
        deliveryDateTime.isAcceptableOrUnknown(
          data['delivery_date_time']!,
          _deliveryDateTimeMeta,
        ),
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
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
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
      eddDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}edd_date'],
      ),
      healthId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_id'],
      ),
      deliveryDateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}delivery_date_time'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      ),
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
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
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
  final DateTime? eddDate;
  final String? healthId;
  final DateTime? deliveryDateTime;
  final String status;
  final String? createdBy;
  final String? data;
  final String? highestRiskStatus;
  final String? allFlaggedComplications;
  final String? riskStatus;
  final String? flaggedComplications;
  final String? overallHealth;
  final int gravidity;
  final int parity;
  final int livingChildren;
  final int abortions;
  final int stillBirths;
  final int miscarriages;
  final int csectionDeliveries;
  final String? obstetricCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? syncedAt;
  final int synced;
  const Pregnancy({
    required this.id,
    this.lmpDate,
    this.eddDate,
    this.healthId,
    this.deliveryDateTime,
    required this.status,
    this.createdBy,
    this.data,
    this.highestRiskStatus,
    this.allFlaggedComplications,
    this.riskStatus,
    this.flaggedComplications,
    this.overallHealth,
    required this.gravidity,
    required this.parity,
    required this.livingChildren,
    required this.abortions,
    required this.stillBirths,
    required this.miscarriages,
    required this.csectionDeliveries,
    this.obstetricCode,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncedAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || lmpDate != null) {
      map['lmp_date'] = Variable<DateTime>(lmpDate);
    }
    if (!nullToAbsent || eddDate != null) {
      map['edd_date'] = Variable<DateTime>(eddDate);
    }
    if (!nullToAbsent || healthId != null) {
      map['health_id'] = Variable<String>(healthId);
    }
    if (!nullToAbsent || deliveryDateTime != null) {
      map['delivery_date_time'] = Variable<DateTime>(deliveryDateTime);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || data != null) {
      map['data'] = Variable<String>(data);
    }
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
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
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
      eddDate: eddDate == null && nullToAbsent
          ? const Value.absent()
          : Value(eddDate),
      healthId: healthId == null && nullToAbsent
          ? const Value.absent()
          : Value(healthId),
      deliveryDateTime: deliveryDateTime == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryDateTime),
      status: Value(status),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      data: data == null && nullToAbsent ? const Value.absent() : Value(data),
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
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
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
      eddDate: serializer.fromJson<DateTime?>(json['eddDate']),
      healthId: serializer.fromJson<String?>(json['healthId']),
      deliveryDateTime: serializer.fromJson<DateTime?>(
        json['deliveryDateTime'],
      ),
      status: serializer.fromJson<String>(json['status']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      data: serializer.fromJson<String?>(json['data']),
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
      gravidity: serializer.fromJson<int>(json['gravidity']),
      parity: serializer.fromJson<int>(json['parity']),
      livingChildren: serializer.fromJson<int>(json['livingChildren']),
      abortions: serializer.fromJson<int>(json['abortions']),
      stillBirths: serializer.fromJson<int>(json['stillBirths']),
      miscarriages: serializer.fromJson<int>(json['miscarriages']),
      csectionDeliveries: serializer.fromJson<int>(json['csectionDeliveries']),
      obstetricCode: serializer.fromJson<String?>(json['obstetricCode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lmpDate': serializer.toJson<DateTime?>(lmpDate),
      'eddDate': serializer.toJson<DateTime?>(eddDate),
      'healthId': serializer.toJson<String?>(healthId),
      'deliveryDateTime': serializer.toJson<DateTime?>(deliveryDateTime),
      'status': serializer.toJson<String>(status),
      'createdBy': serializer.toJson<String?>(createdBy),
      'data': serializer.toJson<String?>(data),
      'highestRiskStatus': serializer.toJson<String?>(highestRiskStatus),
      'allFlaggedComplications': serializer.toJson<String?>(
        allFlaggedComplications,
      ),
      'riskStatus': serializer.toJson<String?>(riskStatus),
      'flaggedComplications': serializer.toJson<String?>(flaggedComplications),
      'overallHealth': serializer.toJson<String?>(overallHealth),
      'gravidity': serializer.toJson<int>(gravidity),
      'parity': serializer.toJson<int>(parity),
      'livingChildren': serializer.toJson<int>(livingChildren),
      'abortions': serializer.toJson<int>(abortions),
      'stillBirths': serializer.toJson<int>(stillBirths),
      'miscarriages': serializer.toJson<int>(miscarriages),
      'csectionDeliveries': serializer.toJson<int>(csectionDeliveries),
      'obstetricCode': serializer.toJson<String?>(obstetricCode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  Pregnancy copyWith({
    String? id,
    Value<DateTime?> lmpDate = const Value.absent(),
    Value<DateTime?> eddDate = const Value.absent(),
    Value<String?> healthId = const Value.absent(),
    Value<DateTime?> deliveryDateTime = const Value.absent(),
    String? status,
    Value<String?> createdBy = const Value.absent(),
    Value<String?> data = const Value.absent(),
    Value<String?> highestRiskStatus = const Value.absent(),
    Value<String?> allFlaggedComplications = const Value.absent(),
    Value<String?> riskStatus = const Value.absent(),
    Value<String?> flaggedComplications = const Value.absent(),
    Value<String?> overallHealth = const Value.absent(),
    int? gravidity,
    int? parity,
    int? livingChildren,
    int? abortions,
    int? stillBirths,
    int? miscarriages,
    int? csectionDeliveries,
    Value<String?> obstetricCode = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    int? synced,
  }) => Pregnancy(
    id: id ?? this.id,
    lmpDate: lmpDate.present ? lmpDate.value : this.lmpDate,
    eddDate: eddDate.present ? eddDate.value : this.eddDate,
    healthId: healthId.present ? healthId.value : this.healthId,
    deliveryDateTime: deliveryDateTime.present
        ? deliveryDateTime.value
        : this.deliveryDateTime,
    status: status ?? this.status,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    data: data.present ? data.value : this.data,
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
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    synced: synced ?? this.synced,
  );
  Pregnancy copyWithCompanion(PregnanciesCompanion data) {
    return Pregnancy(
      id: data.id.present ? data.id.value : this.id,
      lmpDate: data.lmpDate.present ? data.lmpDate.value : this.lmpDate,
      eddDate: data.eddDate.present ? data.eddDate.value : this.eddDate,
      healthId: data.healthId.present ? data.healthId.value : this.healthId,
      deliveryDateTime: data.deliveryDateTime.present
          ? data.deliveryDateTime.value
          : this.deliveryDateTime,
      status: data.status.present ? data.status.value : this.status,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      data: data.data.present ? data.data.value : this.data,
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
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pregnancy(')
          ..write('id: $id, ')
          ..write('lmpDate: $lmpDate, ')
          ..write('eddDate: $eddDate, ')
          ..write('healthId: $healthId, ')
          ..write('deliveryDateTime: $deliveryDateTime, ')
          ..write('status: $status, ')
          ..write('createdBy: $createdBy, ')
          ..write('data: $data, ')
          ..write('highestRiskStatus: $highestRiskStatus, ')
          ..write('allFlaggedComplications: $allFlaggedComplications, ')
          ..write('riskStatus: $riskStatus, ')
          ..write('flaggedComplications: $flaggedComplications, ')
          ..write('overallHealth: $overallHealth, ')
          ..write('gravidity: $gravidity, ')
          ..write('parity: $parity, ')
          ..write('livingChildren: $livingChildren, ')
          ..write('abortions: $abortions, ')
          ..write('stillBirths: $stillBirths, ')
          ..write('miscarriages: $miscarriages, ')
          ..write('csectionDeliveries: $csectionDeliveries, ')
          ..write('obstetricCode: $obstetricCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    lmpDate,
    eddDate,
    healthId,
    deliveryDateTime,
    status,
    createdBy,
    data,
    highestRiskStatus,
    allFlaggedComplications,
    riskStatus,
    flaggedComplications,
    overallHealth,
    gravidity,
    parity,
    livingChildren,
    abortions,
    stillBirths,
    miscarriages,
    csectionDeliveries,
    obstetricCode,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
    synced,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pregnancy &&
          other.id == this.id &&
          other.lmpDate == this.lmpDate &&
          other.eddDate == this.eddDate &&
          other.healthId == this.healthId &&
          other.deliveryDateTime == this.deliveryDateTime &&
          other.status == this.status &&
          other.createdBy == this.createdBy &&
          other.data == this.data &&
          other.highestRiskStatus == this.highestRiskStatus &&
          other.allFlaggedComplications == this.allFlaggedComplications &&
          other.riskStatus == this.riskStatus &&
          other.flaggedComplications == this.flaggedComplications &&
          other.overallHealth == this.overallHealth &&
          other.gravidity == this.gravidity &&
          other.parity == this.parity &&
          other.livingChildren == this.livingChildren &&
          other.abortions == this.abortions &&
          other.stillBirths == this.stillBirths &&
          other.miscarriages == this.miscarriages &&
          other.csectionDeliveries == this.csectionDeliveries &&
          other.obstetricCode == this.obstetricCode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncedAt == this.syncedAt &&
          other.synced == this.synced);
}

class PregnanciesCompanion extends UpdateCompanion<Pregnancy> {
  final Value<String> id;
  final Value<DateTime?> lmpDate;
  final Value<DateTime?> eddDate;
  final Value<String?> healthId;
  final Value<DateTime?> deliveryDateTime;
  final Value<String> status;
  final Value<String?> createdBy;
  final Value<String?> data;
  final Value<String?> highestRiskStatus;
  final Value<String?> allFlaggedComplications;
  final Value<String?> riskStatus;
  final Value<String?> flaggedComplications;
  final Value<String?> overallHealth;
  final Value<int> gravidity;
  final Value<int> parity;
  final Value<int> livingChildren;
  final Value<int> abortions;
  final Value<int> stillBirths;
  final Value<int> miscarriages;
  final Value<int> csectionDeliveries;
  final Value<String?> obstetricCode;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> synced;
  final Value<int> rowid;
  const PregnanciesCompanion({
    this.id = const Value.absent(),
    this.lmpDate = const Value.absent(),
    this.eddDate = const Value.absent(),
    this.healthId = const Value.absent(),
    this.deliveryDateTime = const Value.absent(),
    this.status = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.data = const Value.absent(),
    this.highestRiskStatus = const Value.absent(),
    this.allFlaggedComplications = const Value.absent(),
    this.riskStatus = const Value.absent(),
    this.flaggedComplications = const Value.absent(),
    this.overallHealth = const Value.absent(),
    this.gravidity = const Value.absent(),
    this.parity = const Value.absent(),
    this.livingChildren = const Value.absent(),
    this.abortions = const Value.absent(),
    this.stillBirths = const Value.absent(),
    this.miscarriages = const Value.absent(),
    this.csectionDeliveries = const Value.absent(),
    this.obstetricCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PregnanciesCompanion.insert({
    required String id,
    this.lmpDate = const Value.absent(),
    this.eddDate = const Value.absent(),
    this.healthId = const Value.absent(),
    this.deliveryDateTime = const Value.absent(),
    this.status = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.data = const Value.absent(),
    this.highestRiskStatus = const Value.absent(),
    this.allFlaggedComplications = const Value.absent(),
    this.riskStatus = const Value.absent(),
    this.flaggedComplications = const Value.absent(),
    this.overallHealth = const Value.absent(),
    this.gravidity = const Value.absent(),
    this.parity = const Value.absent(),
    this.livingChildren = const Value.absent(),
    this.abortions = const Value.absent(),
    this.stillBirths = const Value.absent(),
    this.miscarriages = const Value.absent(),
    this.csectionDeliveries = const Value.absent(),
    this.obstetricCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Pregnancy> custom({
    Expression<String>? id,
    Expression<DateTime>? lmpDate,
    Expression<DateTime>? eddDate,
    Expression<String>? healthId,
    Expression<DateTime>? deliveryDateTime,
    Expression<String>? status,
    Expression<String>? createdBy,
    Expression<String>? data,
    Expression<String>? highestRiskStatus,
    Expression<String>? allFlaggedComplications,
    Expression<String>? riskStatus,
    Expression<String>? flaggedComplications,
    Expression<String>? overallHealth,
    Expression<int>? gravidity,
    Expression<int>? parity,
    Expression<int>? livingChildren,
    Expression<int>? abortions,
    Expression<int>? stillBirths,
    Expression<int>? miscarriages,
    Expression<int>? csectionDeliveries,
    Expression<String>? obstetricCode,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lmpDate != null) 'lmp_date': lmpDate,
      if (eddDate != null) 'edd_date': eddDate,
      if (healthId != null) 'health_id': healthId,
      if (deliveryDateTime != null) 'delivery_date_time': deliveryDateTime,
      if (status != null) 'status': status,
      if (createdBy != null) 'created_by': createdBy,
      if (data != null) 'data': data,
      if (highestRiskStatus != null) 'highest_risk_status': highestRiskStatus,
      if (allFlaggedComplications != null)
        'all_flagged_complications': allFlaggedComplications,
      if (riskStatus != null) 'risk_status': riskStatus,
      if (flaggedComplications != null)
        'flagged_complications': flaggedComplications,
      if (overallHealth != null) 'overall_health': overallHealth,
      if (gravidity != null) 'gravidity': gravidity,
      if (parity != null) 'parity': parity,
      if (livingChildren != null) 'living_children': livingChildren,
      if (abortions != null) 'abortions': abortions,
      if (stillBirths != null) 'still_births': stillBirths,
      if (miscarriages != null) 'miscarriages': miscarriages,
      if (csectionDeliveries != null) 'csection_deliveries': csectionDeliveries,
      if (obstetricCode != null) 'obstetric_code': obstetricCode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PregnanciesCompanion copyWith({
    Value<String>? id,
    Value<DateTime?>? lmpDate,
    Value<DateTime?>? eddDate,
    Value<String?>? healthId,
    Value<DateTime?>? deliveryDateTime,
    Value<String>? status,
    Value<String?>? createdBy,
    Value<String?>? data,
    Value<String?>? highestRiskStatus,
    Value<String?>? allFlaggedComplications,
    Value<String?>? riskStatus,
    Value<String?>? flaggedComplications,
    Value<String?>? overallHealth,
    Value<int>? gravidity,
    Value<int>? parity,
    Value<int>? livingChildren,
    Value<int>? abortions,
    Value<int>? stillBirths,
    Value<int>? miscarriages,
    Value<int>? csectionDeliveries,
    Value<String?>? obstetricCode,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return PregnanciesCompanion(
      id: id ?? this.id,
      lmpDate: lmpDate ?? this.lmpDate,
      eddDate: eddDate ?? this.eddDate,
      healthId: healthId ?? this.healthId,
      deliveryDateTime: deliveryDateTime ?? this.deliveryDateTime,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      data: data ?? this.data,
      highestRiskStatus: highestRiskStatus ?? this.highestRiskStatus,
      allFlaggedComplications:
          allFlaggedComplications ?? this.allFlaggedComplications,
      riskStatus: riskStatus ?? this.riskStatus,
      flaggedComplications: flaggedComplications ?? this.flaggedComplications,
      overallHealth: overallHealth ?? this.overallHealth,
      gravidity: gravidity ?? this.gravidity,
      parity: parity ?? this.parity,
      livingChildren: livingChildren ?? this.livingChildren,
      abortions: abortions ?? this.abortions,
      stillBirths: stillBirths ?? this.stillBirths,
      miscarriages: miscarriages ?? this.miscarriages,
      csectionDeliveries: csectionDeliveries ?? this.csectionDeliveries,
      obstetricCode: obstetricCode ?? this.obstetricCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncedAt: syncedAt ?? this.syncedAt,
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
    if (eddDate.present) {
      map['edd_date'] = Variable<DateTime>(eddDate.value);
    }
    if (healthId.present) {
      map['health_id'] = Variable<String>(healthId.value);
    }
    if (deliveryDateTime.present) {
      map['delivery_date_time'] = Variable<DateTime>(deliveryDateTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
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
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
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
          ..write('eddDate: $eddDate, ')
          ..write('healthId: $healthId, ')
          ..write('deliveryDateTime: $deliveryDateTime, ')
          ..write('status: $status, ')
          ..write('createdBy: $createdBy, ')
          ..write('data: $data, ')
          ..write('highestRiskStatus: $highestRiskStatus, ')
          ..write('allFlaggedComplications: $allFlaggedComplications, ')
          ..write('riskStatus: $riskStatus, ')
          ..write('flaggedComplications: $flaggedComplications, ')
          ..write('overallHealth: $overallHealth, ')
          ..write('gravidity: $gravidity, ')
          ..write('parity: $parity, ')
          ..write('livingChildren: $livingChildren, ')
          ..write('abortions: $abortions, ')
          ..write('stillBirths: $stillBirths, ')
          ..write('miscarriages: $miscarriages, ')
          ..write('csectionDeliveries: $csectionDeliveries, ')
          ..write('obstetricCode: $obstetricCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AncCheckupDatesTable extends AncCheckupDates
    with TableInfo<$AncCheckupDatesTable, AncCheckupDate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AncCheckupDatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pregnancyIdMeta = const VerificationMeta(
    'pregnancyId',
  );
  @override
  late final GeneratedColumn<String> pregnancyId = GeneratedColumn<String>(
    'pregnancy_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>(
        'scheduled_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _scheduledDateRangeFromMeta =
      const VerificationMeta('scheduledDateRangeFrom');
  @override
  late final GeneratedColumn<DateTime> scheduledDateRangeFrom =
      GeneratedColumn<DateTime>(
        'scheduled_date_range_from',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _scheduledDateRangeToMeta =
      const VerificationMeta('scheduledDateRangeTo');
  @override
  late final GeneratedColumn<DateTime> scheduledDateRangeTo =
      GeneratedColumn<DateTime>(
        'scheduled_date_range_to',
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
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
    pregnancyId,
    scheduledDate,
    month,
    completedAt,
    scheduledDateRangeFrom,
    scheduledDateRangeTo,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'anc_checkup_dates';
  @override
  VerificationContext validateIntegrity(
    Insertable<AncCheckupDate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pregnancy_id')) {
      context.handle(
        _pregnancyIdMeta,
        pregnancyId.isAcceptableOrUnknown(
          data['pregnancy_id']!,
          _pregnancyIdMeta,
        ),
      );
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
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
    if (data.containsKey('scheduled_date_range_from')) {
      context.handle(
        _scheduledDateRangeFromMeta,
        scheduledDateRangeFrom.isAcceptableOrUnknown(
          data['scheduled_date_range_from']!,
          _scheduledDateRangeFromMeta,
        ),
      );
    }
    if (data.containsKey('scheduled_date_range_to')) {
      context.handle(
        _scheduledDateRangeToMeta,
        scheduledDateRangeTo.isAcceptableOrUnknown(
          data['scheduled_date_range_to']!,
          _scheduledDateRangeToMeta,
        ),
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
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
  AncCheckupDate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AncCheckupDate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pregnancyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pregnancy_id'],
      ),
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date'],
      ),
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      scheduledDateRangeFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date_range_from'],
      ),
      scheduledDateRangeTo: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date_range_to'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $AncCheckupDatesTable createAlias(String alias) {
    return $AncCheckupDatesTable(attachedDatabase, alias);
  }
}

class AncCheckupDate extends DataClass implements Insertable<AncCheckupDate> {
  final String id;
  final String? pregnancyId;
  final DateTime? scheduledDate;
  final int month;
  final DateTime? completedAt;
  final DateTime? scheduledDateRangeFrom;
  final DateTime? scheduledDateRangeTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? syncedAt;
  final int synced;
  const AncCheckupDate({
    required this.id,
    this.pregnancyId,
    this.scheduledDate,
    required this.month,
    this.completedAt,
    this.scheduledDateRangeFrom,
    this.scheduledDateRangeTo,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncedAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || pregnancyId != null) {
      map['pregnancy_id'] = Variable<String>(pregnancyId);
    }
    if (!nullToAbsent || scheduledDate != null) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    }
    map['month'] = Variable<int>(month);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || scheduledDateRangeFrom != null) {
      map['scheduled_date_range_from'] = Variable<DateTime>(
        scheduledDateRangeFrom,
      );
    }
    if (!nullToAbsent || scheduledDateRangeTo != null) {
      map['scheduled_date_range_to'] = Variable<DateTime>(scheduledDateRangeTo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  AncCheckupDatesCompanion toCompanion(bool nullToAbsent) {
    return AncCheckupDatesCompanion(
      id: Value(id),
      pregnancyId: pregnancyId == null && nullToAbsent
          ? const Value.absent()
          : Value(pregnancyId),
      scheduledDate: scheduledDate == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDate),
      month: Value(month),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      scheduledDateRangeFrom: scheduledDateRangeFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDateRangeFrom),
      scheduledDateRangeTo: scheduledDateRangeTo == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDateRangeTo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      synced: Value(synced),
    );
  }

  factory AncCheckupDate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AncCheckupDate(
      id: serializer.fromJson<String>(json['id']),
      pregnancyId: serializer.fromJson<String?>(json['pregnancyId']),
      scheduledDate: serializer.fromJson<DateTime?>(json['scheduledDate']),
      month: serializer.fromJson<int>(json['month']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      scheduledDateRangeFrom: serializer.fromJson<DateTime?>(
        json['scheduledDateRangeFrom'],
      ),
      scheduledDateRangeTo: serializer.fromJson<DateTime?>(
        json['scheduledDateRangeTo'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pregnancyId': serializer.toJson<String?>(pregnancyId),
      'scheduledDate': serializer.toJson<DateTime?>(scheduledDate),
      'month': serializer.toJson<int>(month),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'scheduledDateRangeFrom': serializer.toJson<DateTime?>(
        scheduledDateRangeFrom,
      ),
      'scheduledDateRangeTo': serializer.toJson<DateTime?>(
        scheduledDateRangeTo,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  AncCheckupDate copyWith({
    String? id,
    Value<String?> pregnancyId = const Value.absent(),
    Value<DateTime?> scheduledDate = const Value.absent(),
    int? month,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> scheduledDateRangeFrom = const Value.absent(),
    Value<DateTime?> scheduledDateRangeTo = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    int? synced,
  }) => AncCheckupDate(
    id: id ?? this.id,
    pregnancyId: pregnancyId.present ? pregnancyId.value : this.pregnancyId,
    scheduledDate: scheduledDate.present
        ? scheduledDate.value
        : this.scheduledDate,
    month: month ?? this.month,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    scheduledDateRangeFrom: scheduledDateRangeFrom.present
        ? scheduledDateRangeFrom.value
        : this.scheduledDateRangeFrom,
    scheduledDateRangeTo: scheduledDateRangeTo.present
        ? scheduledDateRangeTo.value
        : this.scheduledDateRangeTo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    synced: synced ?? this.synced,
  );
  AncCheckupDate copyWithCompanion(AncCheckupDatesCompanion data) {
    return AncCheckupDate(
      id: data.id.present ? data.id.value : this.id,
      pregnancyId: data.pregnancyId.present
          ? data.pregnancyId.value
          : this.pregnancyId,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      month: data.month.present ? data.month.value : this.month,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      scheduledDateRangeFrom: data.scheduledDateRangeFrom.present
          ? data.scheduledDateRangeFrom.value
          : this.scheduledDateRangeFrom,
      scheduledDateRangeTo: data.scheduledDateRangeTo.present
          ? data.scheduledDateRangeTo.value
          : this.scheduledDateRangeTo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AncCheckupDate(')
          ..write('id: $id, ')
          ..write('pregnancyId: $pregnancyId, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('month: $month, ')
          ..write('completedAt: $completedAt, ')
          ..write('scheduledDateRangeFrom: $scheduledDateRangeFrom, ')
          ..write('scheduledDateRangeTo: $scheduledDateRangeTo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pregnancyId,
    scheduledDate,
    month,
    completedAt,
    scheduledDateRangeFrom,
    scheduledDateRangeTo,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AncCheckupDate &&
          other.id == this.id &&
          other.pregnancyId == this.pregnancyId &&
          other.scheduledDate == this.scheduledDate &&
          other.month == this.month &&
          other.completedAt == this.completedAt &&
          other.scheduledDateRangeFrom == this.scheduledDateRangeFrom &&
          other.scheduledDateRangeTo == this.scheduledDateRangeTo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncedAt == this.syncedAt &&
          other.synced == this.synced);
}

class AncCheckupDatesCompanion extends UpdateCompanion<AncCheckupDate> {
  final Value<String> id;
  final Value<String?> pregnancyId;
  final Value<DateTime?> scheduledDate;
  final Value<int> month;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> scheduledDateRangeFrom;
  final Value<DateTime?> scheduledDateRangeTo;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> synced;
  final Value<int> rowid;
  const AncCheckupDatesCompanion({
    this.id = const Value.absent(),
    this.pregnancyId = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.month = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.scheduledDateRangeFrom = const Value.absent(),
    this.scheduledDateRangeTo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AncCheckupDatesCompanion.insert({
    required String id,
    this.pregnancyId = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    required int month,
    this.completedAt = const Value.absent(),
    this.scheduledDateRangeFrom = const Value.absent(),
    this.scheduledDateRangeTo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       month = Value(month);
  static Insertable<AncCheckupDate> custom({
    Expression<String>? id,
    Expression<String>? pregnancyId,
    Expression<DateTime>? scheduledDate,
    Expression<int>? month,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? scheduledDateRangeFrom,
    Expression<DateTime>? scheduledDateRangeTo,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pregnancyId != null) 'pregnancy_id': pregnancyId,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (month != null) 'month': month,
      if (completedAt != null) 'completed_at': completedAt,
      if (scheduledDateRangeFrom != null)
        'scheduled_date_range_from': scheduledDateRangeFrom,
      if (scheduledDateRangeTo != null)
        'scheduled_date_range_to': scheduledDateRangeTo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AncCheckupDatesCompanion copyWith({
    Value<String>? id,
    Value<String?>? pregnancyId,
    Value<DateTime?>? scheduledDate,
    Value<int>? month,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? scheduledDateRangeFrom,
    Value<DateTime?>? scheduledDateRangeTo,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return AncCheckupDatesCompanion(
      id: id ?? this.id,
      pregnancyId: pregnancyId ?? this.pregnancyId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      month: month ?? this.month,
      completedAt: completedAt ?? this.completedAt,
      scheduledDateRangeFrom:
          scheduledDateRangeFrom ?? this.scheduledDateRangeFrom,
      scheduledDateRangeTo: scheduledDateRangeTo ?? this.scheduledDateRangeTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncedAt: syncedAt ?? this.syncedAt,
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
    if (pregnancyId.present) {
      map['pregnancy_id'] = Variable<String>(pregnancyId.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (scheduledDateRangeFrom.present) {
      map['scheduled_date_range_from'] = Variable<DateTime>(
        scheduledDateRangeFrom.value,
      );
    }
    if (scheduledDateRangeTo.present) {
      map['scheduled_date_range_to'] = Variable<DateTime>(
        scheduledDateRangeTo.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
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
    return (StringBuffer('AncCheckupDatesCompanion(')
          ..write('id: $id, ')
          ..write('pregnancyId: $pregnancyId, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('month: $month, ')
          ..write('completedAt: $completedAt, ')
          ..write('scheduledDateRangeFrom: $scheduledDateRangeFrom, ')
          ..write('scheduledDateRangeTo: $scheduledDateRangeTo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PregnancyImmunizationRecordsTable extends PregnancyImmunizationRecords
    with
        TableInfo<
          $PregnancyImmunizationRecordsTable,
          PregnancyImmunizationRecord
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PregnancyImmunizationRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pregnancyIdMeta = const VerificationMeta(
    'pregnancyId',
  );
  @override
  late final GeneratedColumn<String> pregnancyId = GeneratedColumn<String>(
    'pregnancy_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vaccineNameMeta = const VerificationMeta(
    'vaccineName',
  );
  @override
  late final GeneratedColumn<String> vaccineName = GeneratedColumn<String>(
    'vaccine_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>(
        'scheduled_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _receivedDateMeta = const VerificationMeta(
    'receivedDate',
  );
  @override
  late final GeneratedColumn<DateTime> receivedDate = GeneratedColumn<DateTime>(
    'received_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requiredMeta = const VerificationMeta(
    'required',
  );
  @override
  late final GeneratedColumn<bool> required = GeneratedColumn<bool>(
    'required',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("required" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _scheduledDateRangeFromMeta =
      const VerificationMeta('scheduledDateRangeFrom');
  @override
  late final GeneratedColumn<DateTime> scheduledDateRangeFrom =
      GeneratedColumn<DateTime>(
        'scheduled_date_range_from',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _scheduledDateRangeToMeta =
      const VerificationMeta('scheduledDateRangeTo');
  @override
  late final GeneratedColumn<DateTime> scheduledDateRangeTo =
      GeneratedColumn<DateTime>(
        'scheduled_date_range_to',
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
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
    pregnancyId,
    vaccineName,
    scheduledDate,
    receivedDate,
    required,
    scheduledDateRangeFrom,
    scheduledDateRangeTo,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pregnancy_immunization_record';
  @override
  VerificationContext validateIntegrity(
    Insertable<PregnancyImmunizationRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pregnancy_id')) {
      context.handle(
        _pregnancyIdMeta,
        pregnancyId.isAcceptableOrUnknown(
          data['pregnancy_id']!,
          _pregnancyIdMeta,
        ),
      );
    }
    if (data.containsKey('vaccine_name')) {
      context.handle(
        _vaccineNameMeta,
        vaccineName.isAcceptableOrUnknown(
          data['vaccine_name']!,
          _vaccineNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vaccineNameMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    }
    if (data.containsKey('received_date')) {
      context.handle(
        _receivedDateMeta,
        receivedDate.isAcceptableOrUnknown(
          data['received_date']!,
          _receivedDateMeta,
        ),
      );
    }
    if (data.containsKey('required')) {
      context.handle(
        _requiredMeta,
        required.isAcceptableOrUnknown(data['required']!, _requiredMeta),
      );
    }
    if (data.containsKey('scheduled_date_range_from')) {
      context.handle(
        _scheduledDateRangeFromMeta,
        scheduledDateRangeFrom.isAcceptableOrUnknown(
          data['scheduled_date_range_from']!,
          _scheduledDateRangeFromMeta,
        ),
      );
    }
    if (data.containsKey('scheduled_date_range_to')) {
      context.handle(
        _scheduledDateRangeToMeta,
        scheduledDateRangeTo.isAcceptableOrUnknown(
          data['scheduled_date_range_to']!,
          _scheduledDateRangeToMeta,
        ),
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
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
  PregnancyImmunizationRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PregnancyImmunizationRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pregnancyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pregnancy_id'],
      ),
      vaccineName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vaccine_name'],
      )!,
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date'],
      ),
      receivedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_date'],
      ),
      required: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}required'],
      )!,
      scheduledDateRangeFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date_range_from'],
      ),
      scheduledDateRangeTo: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date_range_to'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $PregnancyImmunizationRecordsTable createAlias(String alias) {
    return $PregnancyImmunizationRecordsTable(attachedDatabase, alias);
  }
}

class PregnancyImmunizationRecord extends DataClass
    implements Insertable<PregnancyImmunizationRecord> {
  final String id;
  final String? pregnancyId;
  final String vaccineName;
  final DateTime? scheduledDate;
  final DateTime? receivedDate;
  final bool required;
  final DateTime? scheduledDateRangeFrom;
  final DateTime? scheduledDateRangeTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? syncedAt;
  final int synced;
  const PregnancyImmunizationRecord({
    required this.id,
    this.pregnancyId,
    required this.vaccineName,
    this.scheduledDate,
    this.receivedDate,
    required this.required,
    this.scheduledDateRangeFrom,
    this.scheduledDateRangeTo,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncedAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || pregnancyId != null) {
      map['pregnancy_id'] = Variable<String>(pregnancyId);
    }
    map['vaccine_name'] = Variable<String>(vaccineName);
    if (!nullToAbsent || scheduledDate != null) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    }
    if (!nullToAbsent || receivedDate != null) {
      map['received_date'] = Variable<DateTime>(receivedDate);
    }
    map['required'] = Variable<bool>(required);
    if (!nullToAbsent || scheduledDateRangeFrom != null) {
      map['scheduled_date_range_from'] = Variable<DateTime>(
        scheduledDateRangeFrom,
      );
    }
    if (!nullToAbsent || scheduledDateRangeTo != null) {
      map['scheduled_date_range_to'] = Variable<DateTime>(scheduledDateRangeTo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  PregnancyImmunizationRecordsCompanion toCompanion(bool nullToAbsent) {
    return PregnancyImmunizationRecordsCompanion(
      id: Value(id),
      pregnancyId: pregnancyId == null && nullToAbsent
          ? const Value.absent()
          : Value(pregnancyId),
      vaccineName: Value(vaccineName),
      scheduledDate: scheduledDate == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDate),
      receivedDate: receivedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedDate),
      required: Value(required),
      scheduledDateRangeFrom: scheduledDateRangeFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDateRangeFrom),
      scheduledDateRangeTo: scheduledDateRangeTo == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDateRangeTo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      synced: Value(synced),
    );
  }

  factory PregnancyImmunizationRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PregnancyImmunizationRecord(
      id: serializer.fromJson<String>(json['id']),
      pregnancyId: serializer.fromJson<String?>(json['pregnancyId']),
      vaccineName: serializer.fromJson<String>(json['vaccineName']),
      scheduledDate: serializer.fromJson<DateTime?>(json['scheduledDate']),
      receivedDate: serializer.fromJson<DateTime?>(json['receivedDate']),
      required: serializer.fromJson<bool>(json['required']),
      scheduledDateRangeFrom: serializer.fromJson<DateTime?>(
        json['scheduledDateRangeFrom'],
      ),
      scheduledDateRangeTo: serializer.fromJson<DateTime?>(
        json['scheduledDateRangeTo'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pregnancyId': serializer.toJson<String?>(pregnancyId),
      'vaccineName': serializer.toJson<String>(vaccineName),
      'scheduledDate': serializer.toJson<DateTime?>(scheduledDate),
      'receivedDate': serializer.toJson<DateTime?>(receivedDate),
      'required': serializer.toJson<bool>(required),
      'scheduledDateRangeFrom': serializer.toJson<DateTime?>(
        scheduledDateRangeFrom,
      ),
      'scheduledDateRangeTo': serializer.toJson<DateTime?>(
        scheduledDateRangeTo,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  PregnancyImmunizationRecord copyWith({
    String? id,
    Value<String?> pregnancyId = const Value.absent(),
    String? vaccineName,
    Value<DateTime?> scheduledDate = const Value.absent(),
    Value<DateTime?> receivedDate = const Value.absent(),
    bool? required,
    Value<DateTime?> scheduledDateRangeFrom = const Value.absent(),
    Value<DateTime?> scheduledDateRangeTo = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    int? synced,
  }) => PregnancyImmunizationRecord(
    id: id ?? this.id,
    pregnancyId: pregnancyId.present ? pregnancyId.value : this.pregnancyId,
    vaccineName: vaccineName ?? this.vaccineName,
    scheduledDate: scheduledDate.present
        ? scheduledDate.value
        : this.scheduledDate,
    receivedDate: receivedDate.present ? receivedDate.value : this.receivedDate,
    required: required ?? this.required,
    scheduledDateRangeFrom: scheduledDateRangeFrom.present
        ? scheduledDateRangeFrom.value
        : this.scheduledDateRangeFrom,
    scheduledDateRangeTo: scheduledDateRangeTo.present
        ? scheduledDateRangeTo.value
        : this.scheduledDateRangeTo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    synced: synced ?? this.synced,
  );
  PregnancyImmunizationRecord copyWithCompanion(
    PregnancyImmunizationRecordsCompanion data,
  ) {
    return PregnancyImmunizationRecord(
      id: data.id.present ? data.id.value : this.id,
      pregnancyId: data.pregnancyId.present
          ? data.pregnancyId.value
          : this.pregnancyId,
      vaccineName: data.vaccineName.present
          ? data.vaccineName.value
          : this.vaccineName,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      receivedDate: data.receivedDate.present
          ? data.receivedDate.value
          : this.receivedDate,
      required: data.required.present ? data.required.value : this.required,
      scheduledDateRangeFrom: data.scheduledDateRangeFrom.present
          ? data.scheduledDateRangeFrom.value
          : this.scheduledDateRangeFrom,
      scheduledDateRangeTo: data.scheduledDateRangeTo.present
          ? data.scheduledDateRangeTo.value
          : this.scheduledDateRangeTo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PregnancyImmunizationRecord(')
          ..write('id: $id, ')
          ..write('pregnancyId: $pregnancyId, ')
          ..write('vaccineName: $vaccineName, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('receivedDate: $receivedDate, ')
          ..write('required: $required, ')
          ..write('scheduledDateRangeFrom: $scheduledDateRangeFrom, ')
          ..write('scheduledDateRangeTo: $scheduledDateRangeTo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pregnancyId,
    vaccineName,
    scheduledDate,
    receivedDate,
    required,
    scheduledDateRangeFrom,
    scheduledDateRangeTo,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PregnancyImmunizationRecord &&
          other.id == this.id &&
          other.pregnancyId == this.pregnancyId &&
          other.vaccineName == this.vaccineName &&
          other.scheduledDate == this.scheduledDate &&
          other.receivedDate == this.receivedDate &&
          other.required == this.required &&
          other.scheduledDateRangeFrom == this.scheduledDateRangeFrom &&
          other.scheduledDateRangeTo == this.scheduledDateRangeTo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncedAt == this.syncedAt &&
          other.synced == this.synced);
}

class PregnancyImmunizationRecordsCompanion
    extends UpdateCompanion<PregnancyImmunizationRecord> {
  final Value<String> id;
  final Value<String?> pregnancyId;
  final Value<String> vaccineName;
  final Value<DateTime?> scheduledDate;
  final Value<DateTime?> receivedDate;
  final Value<bool> required;
  final Value<DateTime?> scheduledDateRangeFrom;
  final Value<DateTime?> scheduledDateRangeTo;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> synced;
  final Value<int> rowid;
  const PregnancyImmunizationRecordsCompanion({
    this.id = const Value.absent(),
    this.pregnancyId = const Value.absent(),
    this.vaccineName = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.receivedDate = const Value.absent(),
    this.required = const Value.absent(),
    this.scheduledDateRangeFrom = const Value.absent(),
    this.scheduledDateRangeTo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PregnancyImmunizationRecordsCompanion.insert({
    required String id,
    this.pregnancyId = const Value.absent(),
    required String vaccineName,
    this.scheduledDate = const Value.absent(),
    this.receivedDate = const Value.absent(),
    this.required = const Value.absent(),
    this.scheduledDateRangeFrom = const Value.absent(),
    this.scheduledDateRangeTo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vaccineName = Value(vaccineName);
  static Insertable<PregnancyImmunizationRecord> custom({
    Expression<String>? id,
    Expression<String>? pregnancyId,
    Expression<String>? vaccineName,
    Expression<DateTime>? scheduledDate,
    Expression<DateTime>? receivedDate,
    Expression<bool>? required,
    Expression<DateTime>? scheduledDateRangeFrom,
    Expression<DateTime>? scheduledDateRangeTo,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pregnancyId != null) 'pregnancy_id': pregnancyId,
      if (vaccineName != null) 'vaccine_name': vaccineName,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (receivedDate != null) 'received_date': receivedDate,
      if (required != null) 'required': required,
      if (scheduledDateRangeFrom != null)
        'scheduled_date_range_from': scheduledDateRangeFrom,
      if (scheduledDateRangeTo != null)
        'scheduled_date_range_to': scheduledDateRangeTo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PregnancyImmunizationRecordsCompanion copyWith({
    Value<String>? id,
    Value<String?>? pregnancyId,
    Value<String>? vaccineName,
    Value<DateTime?>? scheduledDate,
    Value<DateTime?>? receivedDate,
    Value<bool>? required,
    Value<DateTime?>? scheduledDateRangeFrom,
    Value<DateTime?>? scheduledDateRangeTo,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return PregnancyImmunizationRecordsCompanion(
      id: id ?? this.id,
      pregnancyId: pregnancyId ?? this.pregnancyId,
      vaccineName: vaccineName ?? this.vaccineName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      receivedDate: receivedDate ?? this.receivedDate,
      required: required ?? this.required,
      scheduledDateRangeFrom:
          scheduledDateRangeFrom ?? this.scheduledDateRangeFrom,
      scheduledDateRangeTo: scheduledDateRangeTo ?? this.scheduledDateRangeTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncedAt: syncedAt ?? this.syncedAt,
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
    if (pregnancyId.present) {
      map['pregnancy_id'] = Variable<String>(pregnancyId.value);
    }
    if (vaccineName.present) {
      map['vaccine_name'] = Variable<String>(vaccineName.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (receivedDate.present) {
      map['received_date'] = Variable<DateTime>(receivedDate.value);
    }
    if (required.present) {
      map['required'] = Variable<bool>(required.value);
    }
    if (scheduledDateRangeFrom.present) {
      map['scheduled_date_range_from'] = Variable<DateTime>(
        scheduledDateRangeFrom.value,
      );
    }
    if (scheduledDateRangeTo.present) {
      map['scheduled_date_range_to'] = Variable<DateTime>(
        scheduledDateRangeTo.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
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
    return (StringBuffer('PregnancyImmunizationRecordsCompanion(')
          ..write('id: $id, ')
          ..write('pregnancyId: $pregnancyId, ')
          ..write('vaccineName: $vaccineName, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('receivedDate: $receivedDate, ')
          ..write('required: $required, ')
          ..write('scheduledDateRangeFrom: $scheduledDateRangeFrom, ')
          ..write('scheduledDateRangeTo: $scheduledDateRangeTo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PregnancyReportChecklistsTable extends PregnancyReportChecklists
    with TableInfo<$PregnancyReportChecklistsTable, PregnancyReportChecklist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PregnancyReportChecklistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pregnancyIdMeta = const VerificationMeta(
    'pregnancyId',
  );
  @override
  late final GeneratedColumn<String> pregnancyId = GeneratedColumn<String>(
    'pregnancy_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reportNameMeta = const VerificationMeta(
    'reportName',
  );
  @override
  late final GeneratedColumn<String> reportName = GeneratedColumn<String>(
    'report_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedDateMeta = const VerificationMeta(
    'expectedDate',
  );
  @override
  late final GeneratedColumn<DateTime> expectedDate = GeneratedColumn<DateTime>(
    'expected_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedDateMeta = const VerificationMeta(
    'completedDate',
  );
  @override
  late final GeneratedColumn<DateTime> completedDate =
      GeneratedColumn<DateTime>(
        'completed_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _reportTypeMeta = const VerificationMeta(
    'reportType',
  );
  @override
  late final GeneratedColumn<String> reportType = GeneratedColumn<String>(
    'report_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requiredMeta = const VerificationMeta(
    'required',
  );
  @override
  late final GeneratedColumn<bool> required = GeneratedColumn<bool>(
    'required',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("required" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _scheduledDateRangeFromMeta =
      const VerificationMeta('scheduledDateRangeFrom');
  @override
  late final GeneratedColumn<DateTime> scheduledDateRangeFrom =
      GeneratedColumn<DateTime>(
        'scheduled_date_range_from',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _scheduledDateRangeToMeta =
      const VerificationMeta('scheduledDateRangeTo');
  @override
  late final GeneratedColumn<DateTime> scheduledDateRangeTo =
      GeneratedColumn<DateTime>(
        'scheduled_date_range_to',
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
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
    pregnancyId,
    reportName,
    expectedDate,
    completedDate,
    reportType,
    required,
    scheduledDateRangeFrom,
    scheduledDateRangeTo,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pregnancy_report_checklist';
  @override
  VerificationContext validateIntegrity(
    Insertable<PregnancyReportChecklist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pregnancy_id')) {
      context.handle(
        _pregnancyIdMeta,
        pregnancyId.isAcceptableOrUnknown(
          data['pregnancy_id']!,
          _pregnancyIdMeta,
        ),
      );
    }
    if (data.containsKey('report_name')) {
      context.handle(
        _reportNameMeta,
        reportName.isAcceptableOrUnknown(data['report_name']!, _reportNameMeta),
      );
    } else if (isInserting) {
      context.missing(_reportNameMeta);
    }
    if (data.containsKey('expected_date')) {
      context.handle(
        _expectedDateMeta,
        expectedDate.isAcceptableOrUnknown(
          data['expected_date']!,
          _expectedDateMeta,
        ),
      );
    }
    if (data.containsKey('completed_date')) {
      context.handle(
        _completedDateMeta,
        completedDate.isAcceptableOrUnknown(
          data['completed_date']!,
          _completedDateMeta,
        ),
      );
    }
    if (data.containsKey('report_type')) {
      context.handle(
        _reportTypeMeta,
        reportType.isAcceptableOrUnknown(data['report_type']!, _reportTypeMeta),
      );
    }
    if (data.containsKey('required')) {
      context.handle(
        _requiredMeta,
        required.isAcceptableOrUnknown(data['required']!, _requiredMeta),
      );
    }
    if (data.containsKey('scheduled_date_range_from')) {
      context.handle(
        _scheduledDateRangeFromMeta,
        scheduledDateRangeFrom.isAcceptableOrUnknown(
          data['scheduled_date_range_from']!,
          _scheduledDateRangeFromMeta,
        ),
      );
    }
    if (data.containsKey('scheduled_date_range_to')) {
      context.handle(
        _scheduledDateRangeToMeta,
        scheduledDateRangeTo.isAcceptableOrUnknown(
          data['scheduled_date_range_to']!,
          _scheduledDateRangeToMeta,
        ),
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
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
  PregnancyReportChecklist map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PregnancyReportChecklist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pregnancyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pregnancy_id'],
      ),
      reportName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}report_name'],
      )!,
      expectedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expected_date'],
      ),
      completedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_date'],
      ),
      reportType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}report_type'],
      ),
      required: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}required'],
      )!,
      scheduledDateRangeFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date_range_from'],
      ),
      scheduledDateRangeTo: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date_range_to'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $PregnancyReportChecklistsTable createAlias(String alias) {
    return $PregnancyReportChecklistsTable(attachedDatabase, alias);
  }
}

class PregnancyReportChecklist extends DataClass
    implements Insertable<PregnancyReportChecklist> {
  final String id;
  final String? pregnancyId;
  final String reportName;
  final DateTime? expectedDate;
  final DateTime? completedDate;
  final String? reportType;
  final bool required;
  final DateTime? scheduledDateRangeFrom;
  final DateTime? scheduledDateRangeTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? syncedAt;
  final int synced;
  const PregnancyReportChecklist({
    required this.id,
    this.pregnancyId,
    required this.reportName,
    this.expectedDate,
    this.completedDate,
    this.reportType,
    required this.required,
    this.scheduledDateRangeFrom,
    this.scheduledDateRangeTo,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncedAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || pregnancyId != null) {
      map['pregnancy_id'] = Variable<String>(pregnancyId);
    }
    map['report_name'] = Variable<String>(reportName);
    if (!nullToAbsent || expectedDate != null) {
      map['expected_date'] = Variable<DateTime>(expectedDate);
    }
    if (!nullToAbsent || completedDate != null) {
      map['completed_date'] = Variable<DateTime>(completedDate);
    }
    if (!nullToAbsent || reportType != null) {
      map['report_type'] = Variable<String>(reportType);
    }
    map['required'] = Variable<bool>(required);
    if (!nullToAbsent || scheduledDateRangeFrom != null) {
      map['scheduled_date_range_from'] = Variable<DateTime>(
        scheduledDateRangeFrom,
      );
    }
    if (!nullToAbsent || scheduledDateRangeTo != null) {
      map['scheduled_date_range_to'] = Variable<DateTime>(scheduledDateRangeTo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  PregnancyReportChecklistsCompanion toCompanion(bool nullToAbsent) {
    return PregnancyReportChecklistsCompanion(
      id: Value(id),
      pregnancyId: pregnancyId == null && nullToAbsent
          ? const Value.absent()
          : Value(pregnancyId),
      reportName: Value(reportName),
      expectedDate: expectedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedDate),
      completedDate: completedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(completedDate),
      reportType: reportType == null && nullToAbsent
          ? const Value.absent()
          : Value(reportType),
      required: Value(required),
      scheduledDateRangeFrom: scheduledDateRangeFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDateRangeFrom),
      scheduledDateRangeTo: scheduledDateRangeTo == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDateRangeTo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      synced: Value(synced),
    );
  }

  factory PregnancyReportChecklist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PregnancyReportChecklist(
      id: serializer.fromJson<String>(json['id']),
      pregnancyId: serializer.fromJson<String?>(json['pregnancyId']),
      reportName: serializer.fromJson<String>(json['reportName']),
      expectedDate: serializer.fromJson<DateTime?>(json['expectedDate']),
      completedDate: serializer.fromJson<DateTime?>(json['completedDate']),
      reportType: serializer.fromJson<String?>(json['reportType']),
      required: serializer.fromJson<bool>(json['required']),
      scheduledDateRangeFrom: serializer.fromJson<DateTime?>(
        json['scheduledDateRangeFrom'],
      ),
      scheduledDateRangeTo: serializer.fromJson<DateTime?>(
        json['scheduledDateRangeTo'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pregnancyId': serializer.toJson<String?>(pregnancyId),
      'reportName': serializer.toJson<String>(reportName),
      'expectedDate': serializer.toJson<DateTime?>(expectedDate),
      'completedDate': serializer.toJson<DateTime?>(completedDate),
      'reportType': serializer.toJson<String?>(reportType),
      'required': serializer.toJson<bool>(required),
      'scheduledDateRangeFrom': serializer.toJson<DateTime?>(
        scheduledDateRangeFrom,
      ),
      'scheduledDateRangeTo': serializer.toJson<DateTime?>(
        scheduledDateRangeTo,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  PregnancyReportChecklist copyWith({
    String? id,
    Value<String?> pregnancyId = const Value.absent(),
    String? reportName,
    Value<DateTime?> expectedDate = const Value.absent(),
    Value<DateTime?> completedDate = const Value.absent(),
    Value<String?> reportType = const Value.absent(),
    bool? required,
    Value<DateTime?> scheduledDateRangeFrom = const Value.absent(),
    Value<DateTime?> scheduledDateRangeTo = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    int? synced,
  }) => PregnancyReportChecklist(
    id: id ?? this.id,
    pregnancyId: pregnancyId.present ? pregnancyId.value : this.pregnancyId,
    reportName: reportName ?? this.reportName,
    expectedDate: expectedDate.present ? expectedDate.value : this.expectedDate,
    completedDate: completedDate.present
        ? completedDate.value
        : this.completedDate,
    reportType: reportType.present ? reportType.value : this.reportType,
    required: required ?? this.required,
    scheduledDateRangeFrom: scheduledDateRangeFrom.present
        ? scheduledDateRangeFrom.value
        : this.scheduledDateRangeFrom,
    scheduledDateRangeTo: scheduledDateRangeTo.present
        ? scheduledDateRangeTo.value
        : this.scheduledDateRangeTo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    synced: synced ?? this.synced,
  );
  PregnancyReportChecklist copyWithCompanion(
    PregnancyReportChecklistsCompanion data,
  ) {
    return PregnancyReportChecklist(
      id: data.id.present ? data.id.value : this.id,
      pregnancyId: data.pregnancyId.present
          ? data.pregnancyId.value
          : this.pregnancyId,
      reportName: data.reportName.present
          ? data.reportName.value
          : this.reportName,
      expectedDate: data.expectedDate.present
          ? data.expectedDate.value
          : this.expectedDate,
      completedDate: data.completedDate.present
          ? data.completedDate.value
          : this.completedDate,
      reportType: data.reportType.present
          ? data.reportType.value
          : this.reportType,
      required: data.required.present ? data.required.value : this.required,
      scheduledDateRangeFrom: data.scheduledDateRangeFrom.present
          ? data.scheduledDateRangeFrom.value
          : this.scheduledDateRangeFrom,
      scheduledDateRangeTo: data.scheduledDateRangeTo.present
          ? data.scheduledDateRangeTo.value
          : this.scheduledDateRangeTo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PregnancyReportChecklist(')
          ..write('id: $id, ')
          ..write('pregnancyId: $pregnancyId, ')
          ..write('reportName: $reportName, ')
          ..write('expectedDate: $expectedDate, ')
          ..write('completedDate: $completedDate, ')
          ..write('reportType: $reportType, ')
          ..write('required: $required, ')
          ..write('scheduledDateRangeFrom: $scheduledDateRangeFrom, ')
          ..write('scheduledDateRangeTo: $scheduledDateRangeTo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pregnancyId,
    reportName,
    expectedDate,
    completedDate,
    reportType,
    required,
    scheduledDateRangeFrom,
    scheduledDateRangeTo,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PregnancyReportChecklist &&
          other.id == this.id &&
          other.pregnancyId == this.pregnancyId &&
          other.reportName == this.reportName &&
          other.expectedDate == this.expectedDate &&
          other.completedDate == this.completedDate &&
          other.reportType == this.reportType &&
          other.required == this.required &&
          other.scheduledDateRangeFrom == this.scheduledDateRangeFrom &&
          other.scheduledDateRangeTo == this.scheduledDateRangeTo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncedAt == this.syncedAt &&
          other.synced == this.synced);
}

class PregnancyReportChecklistsCompanion
    extends UpdateCompanion<PregnancyReportChecklist> {
  final Value<String> id;
  final Value<String?> pregnancyId;
  final Value<String> reportName;
  final Value<DateTime?> expectedDate;
  final Value<DateTime?> completedDate;
  final Value<String?> reportType;
  final Value<bool> required;
  final Value<DateTime?> scheduledDateRangeFrom;
  final Value<DateTime?> scheduledDateRangeTo;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> synced;
  final Value<int> rowid;
  const PregnancyReportChecklistsCompanion({
    this.id = const Value.absent(),
    this.pregnancyId = const Value.absent(),
    this.reportName = const Value.absent(),
    this.expectedDate = const Value.absent(),
    this.completedDate = const Value.absent(),
    this.reportType = const Value.absent(),
    this.required = const Value.absent(),
    this.scheduledDateRangeFrom = const Value.absent(),
    this.scheduledDateRangeTo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PregnancyReportChecklistsCompanion.insert({
    required String id,
    this.pregnancyId = const Value.absent(),
    required String reportName,
    this.expectedDate = const Value.absent(),
    this.completedDate = const Value.absent(),
    this.reportType = const Value.absent(),
    this.required = const Value.absent(),
    this.scheduledDateRangeFrom = const Value.absent(),
    this.scheduledDateRangeTo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       reportName = Value(reportName);
  static Insertable<PregnancyReportChecklist> custom({
    Expression<String>? id,
    Expression<String>? pregnancyId,
    Expression<String>? reportName,
    Expression<DateTime>? expectedDate,
    Expression<DateTime>? completedDate,
    Expression<String>? reportType,
    Expression<bool>? required,
    Expression<DateTime>? scheduledDateRangeFrom,
    Expression<DateTime>? scheduledDateRangeTo,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pregnancyId != null) 'pregnancy_id': pregnancyId,
      if (reportName != null) 'report_name': reportName,
      if (expectedDate != null) 'expected_date': expectedDate,
      if (completedDate != null) 'completed_date': completedDate,
      if (reportType != null) 'report_type': reportType,
      if (required != null) 'required': required,
      if (scheduledDateRangeFrom != null)
        'scheduled_date_range_from': scheduledDateRangeFrom,
      if (scheduledDateRangeTo != null)
        'scheduled_date_range_to': scheduledDateRangeTo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PregnancyReportChecklistsCompanion copyWith({
    Value<String>? id,
    Value<String?>? pregnancyId,
    Value<String>? reportName,
    Value<DateTime?>? expectedDate,
    Value<DateTime?>? completedDate,
    Value<String?>? reportType,
    Value<bool>? required,
    Value<DateTime?>? scheduledDateRangeFrom,
    Value<DateTime?>? scheduledDateRangeTo,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return PregnancyReportChecklistsCompanion(
      id: id ?? this.id,
      pregnancyId: pregnancyId ?? this.pregnancyId,
      reportName: reportName ?? this.reportName,
      expectedDate: expectedDate ?? this.expectedDate,
      completedDate: completedDate ?? this.completedDate,
      reportType: reportType ?? this.reportType,
      required: required ?? this.required,
      scheduledDateRangeFrom:
          scheduledDateRangeFrom ?? this.scheduledDateRangeFrom,
      scheduledDateRangeTo: scheduledDateRangeTo ?? this.scheduledDateRangeTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncedAt: syncedAt ?? this.syncedAt,
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
    if (pregnancyId.present) {
      map['pregnancy_id'] = Variable<String>(pregnancyId.value);
    }
    if (reportName.present) {
      map['report_name'] = Variable<String>(reportName.value);
    }
    if (expectedDate.present) {
      map['expected_date'] = Variable<DateTime>(expectedDate.value);
    }
    if (completedDate.present) {
      map['completed_date'] = Variable<DateTime>(completedDate.value);
    }
    if (reportType.present) {
      map['report_type'] = Variable<String>(reportType.value);
    }
    if (required.present) {
      map['required'] = Variable<bool>(required.value);
    }
    if (scheduledDateRangeFrom.present) {
      map['scheduled_date_range_from'] = Variable<DateTime>(
        scheduledDateRangeFrom.value,
      );
    }
    if (scheduledDateRangeTo.present) {
      map['scheduled_date_range_to'] = Variable<DateTime>(
        scheduledDateRangeTo.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
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
    return (StringBuffer('PregnancyReportChecklistsCompanion(')
          ..write('id: $id, ')
          ..write('pregnancyId: $pregnancyId, ')
          ..write('reportName: $reportName, ')
          ..write('expectedDate: $expectedDate, ')
          ..write('completedDate: $completedDate, ')
          ..write('reportType: $reportType, ')
          ..write('required: $required, ')
          ..write('scheduledDateRangeFrom: $scheduledDateRangeFrom, ')
          ..write('scheduledDateRangeTo: $scheduledDateRangeTo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BabiesTable extends Babies with TableInfo<$BabiesTable, Baby> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BabiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pregnancyIdMeta = const VerificationMeta(
    'pregnancyId',
  );
  @override
  late final GeneratedColumn<String> pregnancyId = GeneratedColumn<String>(
    'pregnancy_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _deliveryDateMeta = const VerificationMeta(
    'deliveryDate',
  );
  @override
  late final GeneratedColumn<DateTime> deliveryDate = GeneratedColumn<DateTime>(
    'delivery_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeOfDeliveryMeta = const VerificationMeta(
    'typeOfDelivery',
  );
  @override
  late final GeneratedColumn<String> typeOfDelivery = GeneratedColumn<String>(
    'type_of_delivery',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
    'condition',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
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
  static const VerificationMeta _photoMeta = const VerificationMeta('photo');
  @override
  late final GeneratedColumn<String> photo = GeneratedColumn<String>(
    'photo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoMeta = const VerificationMeta('video');
  @override
  late final GeneratedColumn<String> video = GeneratedColumn<String>(
    'video',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  static const VerificationMeta _complicationsMeta = const VerificationMeta(
    'complications',
  );
  @override
  late final GeneratedColumn<String> complications = GeneratedColumn<String>(
    'complications',
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
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
    pregnancyId,
    name,
    deliveryDate,
    typeOfDelivery,
    condition,
    gender,
    weight,
    height,
    photo,
    video,
    bloodGroup,
    complications,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'baby';
  @override
  VerificationContext validateIntegrity(
    Insertable<Baby> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pregnancy_id')) {
      context.handle(
        _pregnancyIdMeta,
        pregnancyId.isAcceptableOrUnknown(
          data['pregnancy_id']!,
          _pregnancyIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('delivery_date')) {
      context.handle(
        _deliveryDateMeta,
        deliveryDate.isAcceptableOrUnknown(
          data['delivery_date']!,
          _deliveryDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryDateMeta);
    }
    if (data.containsKey('type_of_delivery')) {
      context.handle(
        _typeOfDeliveryMeta,
        typeOfDelivery.isAcceptableOrUnknown(
          data['type_of_delivery']!,
          _typeOfDeliveryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_typeOfDeliveryMeta);
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('photo')) {
      context.handle(
        _photoMeta,
        photo.isAcceptableOrUnknown(data['photo']!, _photoMeta),
      );
    }
    if (data.containsKey('video')) {
      context.handle(
        _videoMeta,
        video.isAcceptableOrUnknown(data['video']!, _videoMeta),
      );
    }
    if (data.containsKey('blood_group')) {
      context.handle(
        _bloodGroupMeta,
        bloodGroup.isAcceptableOrUnknown(data['blood_group']!, _bloodGroupMeta),
      );
    }
    if (data.containsKey('complications')) {
      context.handle(
        _complicationsMeta,
        complications.isAcceptableOrUnknown(
          data['complications']!,
          _complicationsMeta,
        ),
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
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
  Baby map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Baby(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pregnancyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pregnancy_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      deliveryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}delivery_date'],
      )!,
      typeOfDelivery: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_of_delivery'],
      )!,
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      ),
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height'],
      ),
      photo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo'],
      ),
      video: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video'],
      ),
      bloodGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blood_group'],
      ),
      complications: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}complications'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $BabiesTable createAlias(String alias) {
    return $BabiesTable(attachedDatabase, alias);
  }
}

class Baby extends DataClass implements Insertable<Baby> {
  final String id;
  final String? pregnancyId;
  final String name;
  final DateTime deliveryDate;
  final String typeOfDelivery;
  final String? condition;
  final String? gender;
  final double? weight;
  final double? height;
  final String? photo;
  final String? video;
  final String? bloodGroup;
  final String? complications;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? syncedAt;
  final int synced;
  const Baby({
    required this.id,
    this.pregnancyId,
    required this.name,
    required this.deliveryDate,
    required this.typeOfDelivery,
    this.condition,
    this.gender,
    this.weight,
    this.height,
    this.photo,
    this.video,
    this.bloodGroup,
    this.complications,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncedAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || pregnancyId != null) {
      map['pregnancy_id'] = Variable<String>(pregnancyId);
    }
    map['name'] = Variable<String>(name);
    map['delivery_date'] = Variable<DateTime>(deliveryDate);
    map['type_of_delivery'] = Variable<String>(typeOfDelivery);
    if (!nullToAbsent || condition != null) {
      map['condition'] = Variable<String>(condition);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<double>(height);
    }
    if (!nullToAbsent || photo != null) {
      map['photo'] = Variable<String>(photo);
    }
    if (!nullToAbsent || video != null) {
      map['video'] = Variable<String>(video);
    }
    if (!nullToAbsent || bloodGroup != null) {
      map['blood_group'] = Variable<String>(bloodGroup);
    }
    if (!nullToAbsent || complications != null) {
      map['complications'] = Variable<String>(complications);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  BabiesCompanion toCompanion(bool nullToAbsent) {
    return BabiesCompanion(
      id: Value(id),
      pregnancyId: pregnancyId == null && nullToAbsent
          ? const Value.absent()
          : Value(pregnancyId),
      name: Value(name),
      deliveryDate: Value(deliveryDate),
      typeOfDelivery: Value(typeOfDelivery),
      condition: condition == null && nullToAbsent
          ? const Value.absent()
          : Value(condition),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
      weight: weight == null && nullToAbsent
          ? const Value.absent()
          : Value(weight),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      photo: photo == null && nullToAbsent
          ? const Value.absent()
          : Value(photo),
      video: video == null && nullToAbsent
          ? const Value.absent()
          : Value(video),
      bloodGroup: bloodGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(bloodGroup),
      complications: complications == null && nullToAbsent
          ? const Value.absent()
          : Value(complications),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      synced: Value(synced),
    );
  }

  factory Baby.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Baby(
      id: serializer.fromJson<String>(json['id']),
      pregnancyId: serializer.fromJson<String?>(json['pregnancyId']),
      name: serializer.fromJson<String>(json['name']),
      deliveryDate: serializer.fromJson<DateTime>(json['deliveryDate']),
      typeOfDelivery: serializer.fromJson<String>(json['typeOfDelivery']),
      condition: serializer.fromJson<String?>(json['condition']),
      gender: serializer.fromJson<String?>(json['gender']),
      weight: serializer.fromJson<double?>(json['weight']),
      height: serializer.fromJson<double?>(json['height']),
      photo: serializer.fromJson<String?>(json['photo']),
      video: serializer.fromJson<String?>(json['video']),
      bloodGroup: serializer.fromJson<String?>(json['bloodGroup']),
      complications: serializer.fromJson<String?>(json['complications']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pregnancyId': serializer.toJson<String?>(pregnancyId),
      'name': serializer.toJson<String>(name),
      'deliveryDate': serializer.toJson<DateTime>(deliveryDate),
      'typeOfDelivery': serializer.toJson<String>(typeOfDelivery),
      'condition': serializer.toJson<String?>(condition),
      'gender': serializer.toJson<String?>(gender),
      'weight': serializer.toJson<double?>(weight),
      'height': serializer.toJson<double?>(height),
      'photo': serializer.toJson<String?>(photo),
      'video': serializer.toJson<String?>(video),
      'bloodGroup': serializer.toJson<String?>(bloodGroup),
      'complications': serializer.toJson<String?>(complications),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  Baby copyWith({
    String? id,
    Value<String?> pregnancyId = const Value.absent(),
    String? name,
    DateTime? deliveryDate,
    String? typeOfDelivery,
    Value<String?> condition = const Value.absent(),
    Value<String?> gender = const Value.absent(),
    Value<double?> weight = const Value.absent(),
    Value<double?> height = const Value.absent(),
    Value<String?> photo = const Value.absent(),
    Value<String?> video = const Value.absent(),
    Value<String?> bloodGroup = const Value.absent(),
    Value<String?> complications = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    int? synced,
  }) => Baby(
    id: id ?? this.id,
    pregnancyId: pregnancyId.present ? pregnancyId.value : this.pregnancyId,
    name: name ?? this.name,
    deliveryDate: deliveryDate ?? this.deliveryDate,
    typeOfDelivery: typeOfDelivery ?? this.typeOfDelivery,
    condition: condition.present ? condition.value : this.condition,
    gender: gender.present ? gender.value : this.gender,
    weight: weight.present ? weight.value : this.weight,
    height: height.present ? height.value : this.height,
    photo: photo.present ? photo.value : this.photo,
    video: video.present ? video.value : this.video,
    bloodGroup: bloodGroup.present ? bloodGroup.value : this.bloodGroup,
    complications: complications.present
        ? complications.value
        : this.complications,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    synced: synced ?? this.synced,
  );
  Baby copyWithCompanion(BabiesCompanion data) {
    return Baby(
      id: data.id.present ? data.id.value : this.id,
      pregnancyId: data.pregnancyId.present
          ? data.pregnancyId.value
          : this.pregnancyId,
      name: data.name.present ? data.name.value : this.name,
      deliveryDate: data.deliveryDate.present
          ? data.deliveryDate.value
          : this.deliveryDate,
      typeOfDelivery: data.typeOfDelivery.present
          ? data.typeOfDelivery.value
          : this.typeOfDelivery,
      condition: data.condition.present ? data.condition.value : this.condition,
      gender: data.gender.present ? data.gender.value : this.gender,
      weight: data.weight.present ? data.weight.value : this.weight,
      height: data.height.present ? data.height.value : this.height,
      photo: data.photo.present ? data.photo.value : this.photo,
      video: data.video.present ? data.video.value : this.video,
      bloodGroup: data.bloodGroup.present
          ? data.bloodGroup.value
          : this.bloodGroup,
      complications: data.complications.present
          ? data.complications.value
          : this.complications,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Baby(')
          ..write('id: $id, ')
          ..write('pregnancyId: $pregnancyId, ')
          ..write('name: $name, ')
          ..write('deliveryDate: $deliveryDate, ')
          ..write('typeOfDelivery: $typeOfDelivery, ')
          ..write('condition: $condition, ')
          ..write('gender: $gender, ')
          ..write('weight: $weight, ')
          ..write('height: $height, ')
          ..write('photo: $photo, ')
          ..write('video: $video, ')
          ..write('bloodGroup: $bloodGroup, ')
          ..write('complications: $complications, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pregnancyId,
    name,
    deliveryDate,
    typeOfDelivery,
    condition,
    gender,
    weight,
    height,
    photo,
    video,
    bloodGroup,
    complications,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Baby &&
          other.id == this.id &&
          other.pregnancyId == this.pregnancyId &&
          other.name == this.name &&
          other.deliveryDate == this.deliveryDate &&
          other.typeOfDelivery == this.typeOfDelivery &&
          other.condition == this.condition &&
          other.gender == this.gender &&
          other.weight == this.weight &&
          other.height == this.height &&
          other.photo == this.photo &&
          other.video == this.video &&
          other.bloodGroup == this.bloodGroup &&
          other.complications == this.complications &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncedAt == this.syncedAt &&
          other.synced == this.synced);
}

class BabiesCompanion extends UpdateCompanion<Baby> {
  final Value<String> id;
  final Value<String?> pregnancyId;
  final Value<String> name;
  final Value<DateTime> deliveryDate;
  final Value<String> typeOfDelivery;
  final Value<String?> condition;
  final Value<String?> gender;
  final Value<double?> weight;
  final Value<double?> height;
  final Value<String?> photo;
  final Value<String?> video;
  final Value<String?> bloodGroup;
  final Value<String?> complications;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> synced;
  final Value<int> rowid;
  const BabiesCompanion({
    this.id = const Value.absent(),
    this.pregnancyId = const Value.absent(),
    this.name = const Value.absent(),
    this.deliveryDate = const Value.absent(),
    this.typeOfDelivery = const Value.absent(),
    this.condition = const Value.absent(),
    this.gender = const Value.absent(),
    this.weight = const Value.absent(),
    this.height = const Value.absent(),
    this.photo = const Value.absent(),
    this.video = const Value.absent(),
    this.bloodGroup = const Value.absent(),
    this.complications = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BabiesCompanion.insert({
    required String id,
    this.pregnancyId = const Value.absent(),
    required String name,
    required DateTime deliveryDate,
    required String typeOfDelivery,
    this.condition = const Value.absent(),
    this.gender = const Value.absent(),
    this.weight = const Value.absent(),
    this.height = const Value.absent(),
    this.photo = const Value.absent(),
    this.video = const Value.absent(),
    this.bloodGroup = const Value.absent(),
    this.complications = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       deliveryDate = Value(deliveryDate),
       typeOfDelivery = Value(typeOfDelivery);
  static Insertable<Baby> custom({
    Expression<String>? id,
    Expression<String>? pregnancyId,
    Expression<String>? name,
    Expression<DateTime>? deliveryDate,
    Expression<String>? typeOfDelivery,
    Expression<String>? condition,
    Expression<String>? gender,
    Expression<double>? weight,
    Expression<double>? height,
    Expression<String>? photo,
    Expression<String>? video,
    Expression<String>? bloodGroup,
    Expression<String>? complications,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pregnancyId != null) 'pregnancy_id': pregnancyId,
      if (name != null) 'name': name,
      if (deliveryDate != null) 'delivery_date': deliveryDate,
      if (typeOfDelivery != null) 'type_of_delivery': typeOfDelivery,
      if (condition != null) 'condition': condition,
      if (gender != null) 'gender': gender,
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (photo != null) 'photo': photo,
      if (video != null) 'video': video,
      if (bloodGroup != null) 'blood_group': bloodGroup,
      if (complications != null) 'complications': complications,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BabiesCompanion copyWith({
    Value<String>? id,
    Value<String?>? pregnancyId,
    Value<String>? name,
    Value<DateTime>? deliveryDate,
    Value<String>? typeOfDelivery,
    Value<String?>? condition,
    Value<String?>? gender,
    Value<double?>? weight,
    Value<double?>? height,
    Value<String?>? photo,
    Value<String?>? video,
    Value<String?>? bloodGroup,
    Value<String?>? complications,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return BabiesCompanion(
      id: id ?? this.id,
      pregnancyId: pregnancyId ?? this.pregnancyId,
      name: name ?? this.name,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      typeOfDelivery: typeOfDelivery ?? this.typeOfDelivery,
      condition: condition ?? this.condition,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      photo: photo ?? this.photo,
      video: video ?? this.video,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      complications: complications ?? this.complications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncedAt: syncedAt ?? this.syncedAt,
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
    if (pregnancyId.present) {
      map['pregnancy_id'] = Variable<String>(pregnancyId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (deliveryDate.present) {
      map['delivery_date'] = Variable<DateTime>(deliveryDate.value);
    }
    if (typeOfDelivery.present) {
      map['type_of_delivery'] = Variable<String>(typeOfDelivery.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (photo.present) {
      map['photo'] = Variable<String>(photo.value);
    }
    if (video.present) {
      map['video'] = Variable<String>(video.value);
    }
    if (bloodGroup.present) {
      map['blood_group'] = Variable<String>(bloodGroup.value);
    }
    if (complications.present) {
      map['complications'] = Variable<String>(complications.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
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
    return (StringBuffer('BabiesCompanion(')
          ..write('id: $id, ')
          ..write('pregnancyId: $pregnancyId, ')
          ..write('name: $name, ')
          ..write('deliveryDate: $deliveryDate, ')
          ..write('typeOfDelivery: $typeOfDelivery, ')
          ..write('condition: $condition, ')
          ..write('gender: $gender, ')
          ..write('weight: $weight, ')
          ..write('height: $height, ')
          ..write('photo: $photo, ')
          ..write('video: $video, ')
          ..write('bloodGroup: $bloodGroup, ')
          ..write('complications: $complications, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BabyImmunizationRecordsTable extends BabyImmunizationRecords
    with TableInfo<$BabyImmunizationRecordsTable, BabyImmunizationRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BabyImmunizationRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _babyIdMeta = const VerificationMeta('babyId');
  @override
  late final GeneratedColumn<String> babyId = GeneratedColumn<String>(
    'baby_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vaccineNameMeta = const VerificationMeta(
    'vaccineName',
  );
  @override
  late final GeneratedColumn<String> vaccineName = GeneratedColumn<String>(
    'vaccine_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>(
        'scheduled_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _receivedDateMeta = const VerificationMeta(
    'receivedDate',
  );
  @override
  late final GeneratedColumn<DateTime> receivedDate = GeneratedColumn<DateTime>(
    'received_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requiredMeta = const VerificationMeta(
    'required',
  );
  @override
  late final GeneratedColumn<bool> required = GeneratedColumn<bool>(
    'required',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("required" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _scheduledDateRangeFromMeta =
      const VerificationMeta('scheduledDateRangeFrom');
  @override
  late final GeneratedColumn<DateTime> scheduledDateRangeFrom =
      GeneratedColumn<DateTime>(
        'scheduled_date_range_from',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _scheduledDateRangeToMeta =
      const VerificationMeta('scheduledDateRangeTo');
  @override
  late final GeneratedColumn<DateTime> scheduledDateRangeTo =
      GeneratedColumn<DateTime>(
        'scheduled_date_range_to',
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
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
    babyId,
    vaccineName,
    scheduledDate,
    receivedDate,
    required,
    scheduledDateRangeFrom,
    scheduledDateRangeTo,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'baby_immunization_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<BabyImmunizationRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('baby_id')) {
      context.handle(
        _babyIdMeta,
        babyId.isAcceptableOrUnknown(data['baby_id']!, _babyIdMeta),
      );
    }
    if (data.containsKey('vaccine_name')) {
      context.handle(
        _vaccineNameMeta,
        vaccineName.isAcceptableOrUnknown(
          data['vaccine_name']!,
          _vaccineNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vaccineNameMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    }
    if (data.containsKey('received_date')) {
      context.handle(
        _receivedDateMeta,
        receivedDate.isAcceptableOrUnknown(
          data['received_date']!,
          _receivedDateMeta,
        ),
      );
    }
    if (data.containsKey('required')) {
      context.handle(
        _requiredMeta,
        required.isAcceptableOrUnknown(data['required']!, _requiredMeta),
      );
    }
    if (data.containsKey('scheduled_date_range_from')) {
      context.handle(
        _scheduledDateRangeFromMeta,
        scheduledDateRangeFrom.isAcceptableOrUnknown(
          data['scheduled_date_range_from']!,
          _scheduledDateRangeFromMeta,
        ),
      );
    }
    if (data.containsKey('scheduled_date_range_to')) {
      context.handle(
        _scheduledDateRangeToMeta,
        scheduledDateRangeTo.isAcceptableOrUnknown(
          data['scheduled_date_range_to']!,
          _scheduledDateRangeToMeta,
        ),
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
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
  BabyImmunizationRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BabyImmunizationRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      babyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}baby_id'],
      ),
      vaccineName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vaccine_name'],
      )!,
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date'],
      ),
      receivedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_date'],
      ),
      required: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}required'],
      )!,
      scheduledDateRangeFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date_range_from'],
      ),
      scheduledDateRangeTo: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date_range_to'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $BabyImmunizationRecordsTable createAlias(String alias) {
    return $BabyImmunizationRecordsTable(attachedDatabase, alias);
  }
}

class BabyImmunizationRecord extends DataClass
    implements Insertable<BabyImmunizationRecord> {
  final String id;
  final String? babyId;
  final String vaccineName;
  final DateTime? scheduledDate;
  final DateTime? receivedDate;
  final bool required;
  final DateTime? scheduledDateRangeFrom;
  final DateTime? scheduledDateRangeTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? syncedAt;
  final int synced;
  const BabyImmunizationRecord({
    required this.id,
    this.babyId,
    required this.vaccineName,
    this.scheduledDate,
    this.receivedDate,
    required this.required,
    this.scheduledDateRangeFrom,
    this.scheduledDateRangeTo,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncedAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || babyId != null) {
      map['baby_id'] = Variable<String>(babyId);
    }
    map['vaccine_name'] = Variable<String>(vaccineName);
    if (!nullToAbsent || scheduledDate != null) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    }
    if (!nullToAbsent || receivedDate != null) {
      map['received_date'] = Variable<DateTime>(receivedDate);
    }
    map['required'] = Variable<bool>(required);
    if (!nullToAbsent || scheduledDateRangeFrom != null) {
      map['scheduled_date_range_from'] = Variable<DateTime>(
        scheduledDateRangeFrom,
      );
    }
    if (!nullToAbsent || scheduledDateRangeTo != null) {
      map['scheduled_date_range_to'] = Variable<DateTime>(scheduledDateRangeTo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  BabyImmunizationRecordsCompanion toCompanion(bool nullToAbsent) {
    return BabyImmunizationRecordsCompanion(
      id: Value(id),
      babyId: babyId == null && nullToAbsent
          ? const Value.absent()
          : Value(babyId),
      vaccineName: Value(vaccineName),
      scheduledDate: scheduledDate == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDate),
      receivedDate: receivedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedDate),
      required: Value(required),
      scheduledDateRangeFrom: scheduledDateRangeFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDateRangeFrom),
      scheduledDateRangeTo: scheduledDateRangeTo == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDateRangeTo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      synced: Value(synced),
    );
  }

  factory BabyImmunizationRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BabyImmunizationRecord(
      id: serializer.fromJson<String>(json['id']),
      babyId: serializer.fromJson<String?>(json['babyId']),
      vaccineName: serializer.fromJson<String>(json['vaccineName']),
      scheduledDate: serializer.fromJson<DateTime?>(json['scheduledDate']),
      receivedDate: serializer.fromJson<DateTime?>(json['receivedDate']),
      required: serializer.fromJson<bool>(json['required']),
      scheduledDateRangeFrom: serializer.fromJson<DateTime?>(
        json['scheduledDateRangeFrom'],
      ),
      scheduledDateRangeTo: serializer.fromJson<DateTime?>(
        json['scheduledDateRangeTo'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'babyId': serializer.toJson<String?>(babyId),
      'vaccineName': serializer.toJson<String>(vaccineName),
      'scheduledDate': serializer.toJson<DateTime?>(scheduledDate),
      'receivedDate': serializer.toJson<DateTime?>(receivedDate),
      'required': serializer.toJson<bool>(required),
      'scheduledDateRangeFrom': serializer.toJson<DateTime?>(
        scheduledDateRangeFrom,
      ),
      'scheduledDateRangeTo': serializer.toJson<DateTime?>(
        scheduledDateRangeTo,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  BabyImmunizationRecord copyWith({
    String? id,
    Value<String?> babyId = const Value.absent(),
    String? vaccineName,
    Value<DateTime?> scheduledDate = const Value.absent(),
    Value<DateTime?> receivedDate = const Value.absent(),
    bool? required,
    Value<DateTime?> scheduledDateRangeFrom = const Value.absent(),
    Value<DateTime?> scheduledDateRangeTo = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    int? synced,
  }) => BabyImmunizationRecord(
    id: id ?? this.id,
    babyId: babyId.present ? babyId.value : this.babyId,
    vaccineName: vaccineName ?? this.vaccineName,
    scheduledDate: scheduledDate.present
        ? scheduledDate.value
        : this.scheduledDate,
    receivedDate: receivedDate.present ? receivedDate.value : this.receivedDate,
    required: required ?? this.required,
    scheduledDateRangeFrom: scheduledDateRangeFrom.present
        ? scheduledDateRangeFrom.value
        : this.scheduledDateRangeFrom,
    scheduledDateRangeTo: scheduledDateRangeTo.present
        ? scheduledDateRangeTo.value
        : this.scheduledDateRangeTo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    synced: synced ?? this.synced,
  );
  BabyImmunizationRecord copyWithCompanion(
    BabyImmunizationRecordsCompanion data,
  ) {
    return BabyImmunizationRecord(
      id: data.id.present ? data.id.value : this.id,
      babyId: data.babyId.present ? data.babyId.value : this.babyId,
      vaccineName: data.vaccineName.present
          ? data.vaccineName.value
          : this.vaccineName,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      receivedDate: data.receivedDate.present
          ? data.receivedDate.value
          : this.receivedDate,
      required: data.required.present ? data.required.value : this.required,
      scheduledDateRangeFrom: data.scheduledDateRangeFrom.present
          ? data.scheduledDateRangeFrom.value
          : this.scheduledDateRangeFrom,
      scheduledDateRangeTo: data.scheduledDateRangeTo.present
          ? data.scheduledDateRangeTo.value
          : this.scheduledDateRangeTo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BabyImmunizationRecord(')
          ..write('id: $id, ')
          ..write('babyId: $babyId, ')
          ..write('vaccineName: $vaccineName, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('receivedDate: $receivedDate, ')
          ..write('required: $required, ')
          ..write('scheduledDateRangeFrom: $scheduledDateRangeFrom, ')
          ..write('scheduledDateRangeTo: $scheduledDateRangeTo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    babyId,
    vaccineName,
    scheduledDate,
    receivedDate,
    required,
    scheduledDateRangeFrom,
    scheduledDateRangeTo,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BabyImmunizationRecord &&
          other.id == this.id &&
          other.babyId == this.babyId &&
          other.vaccineName == this.vaccineName &&
          other.scheduledDate == this.scheduledDate &&
          other.receivedDate == this.receivedDate &&
          other.required == this.required &&
          other.scheduledDateRangeFrom == this.scheduledDateRangeFrom &&
          other.scheduledDateRangeTo == this.scheduledDateRangeTo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncedAt == this.syncedAt &&
          other.synced == this.synced);
}

class BabyImmunizationRecordsCompanion
    extends UpdateCompanion<BabyImmunizationRecord> {
  final Value<String> id;
  final Value<String?> babyId;
  final Value<String> vaccineName;
  final Value<DateTime?> scheduledDate;
  final Value<DateTime?> receivedDate;
  final Value<bool> required;
  final Value<DateTime?> scheduledDateRangeFrom;
  final Value<DateTime?> scheduledDateRangeTo;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> synced;
  final Value<int> rowid;
  const BabyImmunizationRecordsCompanion({
    this.id = const Value.absent(),
    this.babyId = const Value.absent(),
    this.vaccineName = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.receivedDate = const Value.absent(),
    this.required = const Value.absent(),
    this.scheduledDateRangeFrom = const Value.absent(),
    this.scheduledDateRangeTo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BabyImmunizationRecordsCompanion.insert({
    required String id,
    this.babyId = const Value.absent(),
    required String vaccineName,
    this.scheduledDate = const Value.absent(),
    this.receivedDate = const Value.absent(),
    this.required = const Value.absent(),
    this.scheduledDateRangeFrom = const Value.absent(),
    this.scheduledDateRangeTo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vaccineName = Value(vaccineName);
  static Insertable<BabyImmunizationRecord> custom({
    Expression<String>? id,
    Expression<String>? babyId,
    Expression<String>? vaccineName,
    Expression<DateTime>? scheduledDate,
    Expression<DateTime>? receivedDate,
    Expression<bool>? required,
    Expression<DateTime>? scheduledDateRangeFrom,
    Expression<DateTime>? scheduledDateRangeTo,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (babyId != null) 'baby_id': babyId,
      if (vaccineName != null) 'vaccine_name': vaccineName,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (receivedDate != null) 'received_date': receivedDate,
      if (required != null) 'required': required,
      if (scheduledDateRangeFrom != null)
        'scheduled_date_range_from': scheduledDateRangeFrom,
      if (scheduledDateRangeTo != null)
        'scheduled_date_range_to': scheduledDateRangeTo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BabyImmunizationRecordsCompanion copyWith({
    Value<String>? id,
    Value<String?>? babyId,
    Value<String>? vaccineName,
    Value<DateTime?>? scheduledDate,
    Value<DateTime?>? receivedDate,
    Value<bool>? required,
    Value<DateTime?>? scheduledDateRangeFrom,
    Value<DateTime?>? scheduledDateRangeTo,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return BabyImmunizationRecordsCompanion(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      vaccineName: vaccineName ?? this.vaccineName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      receivedDate: receivedDate ?? this.receivedDate,
      required: required ?? this.required,
      scheduledDateRangeFrom:
          scheduledDateRangeFrom ?? this.scheduledDateRangeFrom,
      scheduledDateRangeTo: scheduledDateRangeTo ?? this.scheduledDateRangeTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncedAt: syncedAt ?? this.syncedAt,
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
    if (babyId.present) {
      map['baby_id'] = Variable<String>(babyId.value);
    }
    if (vaccineName.present) {
      map['vaccine_name'] = Variable<String>(vaccineName.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (receivedDate.present) {
      map['received_date'] = Variable<DateTime>(receivedDate.value);
    }
    if (required.present) {
      map['required'] = Variable<bool>(required.value);
    }
    if (scheduledDateRangeFrom.present) {
      map['scheduled_date_range_from'] = Variable<DateTime>(
        scheduledDateRangeFrom.value,
      );
    }
    if (scheduledDateRangeTo.present) {
      map['scheduled_date_range_to'] = Variable<DateTime>(
        scheduledDateRangeTo.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
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
    return (StringBuffer('BabyImmunizationRecordsCompanion(')
          ..write('id: $id, ')
          ..write('babyId: $babyId, ')
          ..write('vaccineName: $vaccineName, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('receivedDate: $receivedDate, ')
          ..write('required: $required, ')
          ..write('scheduledDateRangeFrom: $scheduledDateRangeFrom, ')
          ..write('scheduledDateRangeTo: $scheduledDateRangeTo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BabyMilestonesTable extends BabyMilestones
    with TableInfo<$BabyMilestonesTable, BabyMilestone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BabyMilestonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _babyIdMeta = const VerificationMeta('babyId');
  @override
  late final GeneratedColumn<String> babyId = GeneratedColumn<String>(
    'baby_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expectedDateMeta = const VerificationMeta(
    'expectedDate',
  );
  @override
  late final GeneratedColumn<DateTime> expectedDate = GeneratedColumn<DateTime>(
    'expected_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _milestoneMeta = const VerificationMeta(
    'milestone',
  );
  @override
  late final GeneratedColumn<String> milestone = GeneratedColumn<String>(
    'milestone',
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
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
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
    babyId,
    expectedDate,
    milestone,
    description,
    completedAt,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'baby_milestones';
  @override
  VerificationContext validateIntegrity(
    Insertable<BabyMilestone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('baby_id')) {
      context.handle(
        _babyIdMeta,
        babyId.isAcceptableOrUnknown(data['baby_id']!, _babyIdMeta),
      );
    }
    if (data.containsKey('expected_date')) {
      context.handle(
        _expectedDateMeta,
        expectedDate.isAcceptableOrUnknown(
          data['expected_date']!,
          _expectedDateMeta,
        ),
      );
    }
    if (data.containsKey('milestone')) {
      context.handle(
        _milestoneMeta,
        milestone.isAcceptableOrUnknown(data['milestone']!, _milestoneMeta),
      );
    } else if (isInserting) {
      context.missing(_milestoneMeta);
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
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
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
  BabyMilestone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BabyMilestone(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      babyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}baby_id'],
      ),
      expectedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expected_date'],
      ),
      milestone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}milestone'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $BabyMilestonesTable createAlias(String alias) {
    return $BabyMilestonesTable(attachedDatabase, alias);
  }
}

class BabyMilestone extends DataClass implements Insertable<BabyMilestone> {
  final int id;
  final String? babyId;
  final DateTime? expectedDate;
  final String milestone;
  final String description;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? syncedAt;
  final int synced;
  const BabyMilestone({
    required this.id,
    this.babyId,
    this.expectedDate,
    required this.milestone,
    required this.description,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncedAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || babyId != null) {
      map['baby_id'] = Variable<String>(babyId);
    }
    if (!nullToAbsent || expectedDate != null) {
      map['expected_date'] = Variable<DateTime>(expectedDate);
    }
    map['milestone'] = Variable<String>(milestone);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  BabyMilestonesCompanion toCompanion(bool nullToAbsent) {
    return BabyMilestonesCompanion(
      id: Value(id),
      babyId: babyId == null && nullToAbsent
          ? const Value.absent()
          : Value(babyId),
      expectedDate: expectedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedDate),
      milestone: Value(milestone),
      description: Value(description),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      synced: Value(synced),
    );
  }

  factory BabyMilestone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BabyMilestone(
      id: serializer.fromJson<int>(json['id']),
      babyId: serializer.fromJson<String?>(json['babyId']),
      expectedDate: serializer.fromJson<DateTime?>(json['expectedDate']),
      milestone: serializer.fromJson<String>(json['milestone']),
      description: serializer.fromJson<String>(json['description']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'babyId': serializer.toJson<String?>(babyId),
      'expectedDate': serializer.toJson<DateTime?>(expectedDate),
      'milestone': serializer.toJson<String>(milestone),
      'description': serializer.toJson<String>(description),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  BabyMilestone copyWith({
    int? id,
    Value<String?> babyId = const Value.absent(),
    Value<DateTime?> expectedDate = const Value.absent(),
    String? milestone,
    String? description,
    Value<DateTime?> completedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    int? synced,
  }) => BabyMilestone(
    id: id ?? this.id,
    babyId: babyId.present ? babyId.value : this.babyId,
    expectedDate: expectedDate.present ? expectedDate.value : this.expectedDate,
    milestone: milestone ?? this.milestone,
    description: description ?? this.description,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    synced: synced ?? this.synced,
  );
  BabyMilestone copyWithCompanion(BabyMilestonesCompanion data) {
    return BabyMilestone(
      id: data.id.present ? data.id.value : this.id,
      babyId: data.babyId.present ? data.babyId.value : this.babyId,
      expectedDate: data.expectedDate.present
          ? data.expectedDate.value
          : this.expectedDate,
      milestone: data.milestone.present ? data.milestone.value : this.milestone,
      description: data.description.present
          ? data.description.value
          : this.description,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BabyMilestone(')
          ..write('id: $id, ')
          ..write('babyId: $babyId, ')
          ..write('expectedDate: $expectedDate, ')
          ..write('milestone: $milestone, ')
          ..write('description: $description, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    babyId,
    expectedDate,
    milestone,
    description,
    completedAt,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BabyMilestone &&
          other.id == this.id &&
          other.babyId == this.babyId &&
          other.expectedDate == this.expectedDate &&
          other.milestone == this.milestone &&
          other.description == this.description &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncedAt == this.syncedAt &&
          other.synced == this.synced);
}

class BabyMilestonesCompanion extends UpdateCompanion<BabyMilestone> {
  final Value<int> id;
  final Value<String?> babyId;
  final Value<DateTime?> expectedDate;
  final Value<String> milestone;
  final Value<String> description;
  final Value<DateTime?> completedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> synced;
  const BabyMilestonesCompanion({
    this.id = const Value.absent(),
    this.babyId = const Value.absent(),
    this.expectedDate = const Value.absent(),
    this.milestone = const Value.absent(),
    this.description = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  BabyMilestonesCompanion.insert({
    this.id = const Value.absent(),
    this.babyId = const Value.absent(),
    this.expectedDate = const Value.absent(),
    required String milestone,
    required String description,
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.synced = const Value.absent(),
  }) : milestone = Value(milestone),
       description = Value(description);
  static Insertable<BabyMilestone> custom({
    Expression<int>? id,
    Expression<String>? babyId,
    Expression<DateTime>? expectedDate,
    Expression<String>? milestone,
    Expression<String>? description,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (babyId != null) 'baby_id': babyId,
      if (expectedDate != null) 'expected_date': expectedDate,
      if (milestone != null) 'milestone': milestone,
      if (description != null) 'description': description,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (synced != null) 'synced': synced,
    });
  }

  BabyMilestonesCompanion copyWith({
    Value<int>? id,
    Value<String?>? babyId,
    Value<DateTime?>? expectedDate,
    Value<String>? milestone,
    Value<String>? description,
    Value<DateTime?>? completedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? synced,
  }) {
    return BabyMilestonesCompanion(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      expectedDate: expectedDate ?? this.expectedDate,
      milestone: milestone ?? this.milestone,
      description: description ?? this.description,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (babyId.present) {
      map['baby_id'] = Variable<String>(babyId.value);
    }
    if (expectedDate.present) {
      map['expected_date'] = Variable<DateTime>(expectedDate.value);
    }
    if (milestone.present) {
      map['milestone'] = Variable<String>(milestone.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BabyMilestonesCompanion(')
          ..write('id: $id, ')
          ..write('babyId: $babyId, ')
          ..write('expectedDate: $expectedDate, ')
          ..write('milestone: $milestone, ')
          ..write('description: $description, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $SyncStatesTable extends SyncStates
    with TableInfo<$SyncStatesTable, SyncState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _moduleMeta = const VerificationMeta('module');
  @override
  late final GeneratedColumn<String> module = GeneratedColumn<String>(
    'module',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    module,
    syncedAt,
    lastAttemptAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('module')) {
      context.handle(
        _moduleMeta,
        module.isAcceptableOrUnknown(data['module']!, _moduleMeta),
      );
    } else if (isInserting) {
      context.missing(_moduleMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {module};
  @override
  SyncState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncState(
      module: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncStatesTable createAlias(String alias) {
    return $SyncStatesTable(attachedDatabase, alias);
  }
}

class SyncState extends DataClass implements Insertable<SyncState> {
  final String module;
  final DateTime? syncedAt;
  final DateTime? lastAttemptAt;
  final String? lastError;
  const SyncState({
    required this.module,
    this.syncedAt,
    this.lastAttemptAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['module'] = Variable<String>(module);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncStatesCompanion toCompanion(bool nullToAbsent) {
    return SyncStatesCompanion(
      module: Value(module),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncState(
      module: serializer.fromJson<String>(json['module']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'module': serializer.toJson<String>(module),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncState copyWith({
    String? module,
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => SyncState(
    module: module ?? this.module,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncState copyWithCompanion(SyncStatesCompanion data) {
    return SyncState(
      module: data.module.present ? data.module.value : this.module,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncState(')
          ..write('module: $module, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(module, syncedAt, lastAttemptAt, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncState &&
          other.module == this.module &&
          other.syncedAt == this.syncedAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastError == this.lastError);
}

class SyncStatesCompanion extends UpdateCompanion<SyncState> {
  final Value<String> module;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncStatesCompanion({
    this.module = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStatesCompanion.insert({
    required String module,
    this.syncedAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : module = Value(module);
  static Insertable<SyncState> custom({
    Expression<String>? module,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (module != null) 'module': module,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStatesCompanion copyWith({
    Value<String>? module,
    Value<DateTime?>? syncedAt,
    Value<DateTime?>? lastAttemptAt,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return SyncStatesCompanion(
      module: module ?? this.module,
      syncedAt: syncedAt ?? this.syncedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (module.present) {
      map['module'] = Variable<String>(module.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatesCompanion(')
          ..write('module: $module, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

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

class $UserNickNamesTable extends UserNickNames
    with TableInfo<$UserNickNamesTable, UserNickName> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserNickNamesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nickNameMeta = const VerificationMeta(
    'nickName',
  );
  @override
  late final GeneratedColumn<String> nickName = GeneratedColumn<String>(
    'nick_name',
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
    nickName,
    createdAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_nick_names';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserNickName> instance, {
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
    if (data.containsKey('nick_name')) {
      context.handle(
        _nickNameMeta,
        nickName.isAcceptableOrUnknown(data['nick_name']!, _nickNameMeta),
      );
    } else if (isInserting) {
      context.missing(_nickNameMeta);
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
  UserNickName map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserNickName(
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
      nickName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nick_name'],
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
  $UserNickNamesTable createAlias(String alias) {
    return $UserNickNamesTable(attachedDatabase, alias);
  }
}

class UserNickName extends DataClass implements Insertable<UserNickName> {
  final int id;
  final String userId;
  final String relatedUserId;
  final String nickName;
  final DateTime createdAt;
  final int synced;
  const UserNickName({
    required this.id,
    required this.userId,
    required this.relatedUserId,
    required this.nickName,
    required this.createdAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['related_user_id'] = Variable<String>(relatedUserId);
    map['nick_name'] = Variable<String>(nickName);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  UserNickNamesCompanion toCompanion(bool nullToAbsent) {
    return UserNickNamesCompanion(
      id: Value(id),
      userId: Value(userId),
      relatedUserId: Value(relatedUserId),
      nickName: Value(nickName),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory UserNickName.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserNickName(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      relatedUserId: serializer.fromJson<String>(json['relatedUserId']),
      nickName: serializer.fromJson<String>(json['nickName']),
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
      'nickName': serializer.toJson<String>(nickName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  UserNickName copyWith({
    int? id,
    String? userId,
    String? relatedUserId,
    String? nickName,
    DateTime? createdAt,
    int? synced,
  }) => UserNickName(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    relatedUserId: relatedUserId ?? this.relatedUserId,
    nickName: nickName ?? this.nickName,
    createdAt: createdAt ?? this.createdAt,
    synced: synced ?? this.synced,
  );
  UserNickName copyWithCompanion(UserNickNamesCompanion data) {
    return UserNickName(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      relatedUserId: data.relatedUserId.present
          ? data.relatedUserId.value
          : this.relatedUserId,
      nickName: data.nickName.present ? data.nickName.value : this.nickName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserNickName(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('relatedUserId: $relatedUserId, ')
          ..write('nickName: $nickName, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, relatedUserId, nickName, createdAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserNickName &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.relatedUserId == this.relatedUserId &&
          other.nickName == this.nickName &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class UserNickNamesCompanion extends UpdateCompanion<UserNickName> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> relatedUserId;
  final Value<String> nickName;
  final Value<DateTime> createdAt;
  final Value<int> synced;
  const UserNickNamesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.relatedUserId = const Value.absent(),
    this.nickName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  UserNickNamesCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String relatedUserId,
    required String nickName,
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  }) : userId = Value(userId),
       relatedUserId = Value(relatedUserId),
       nickName = Value(nickName);
  static Insertable<UserNickName> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? relatedUserId,
    Expression<String>? nickName,
    Expression<DateTime>? createdAt,
    Expression<int>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (relatedUserId != null) 'related_user_id': relatedUserId,
      if (nickName != null) 'nick_name': nickName,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
    });
  }

  UserNickNamesCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? relatedUserId,
    Value<String>? nickName,
    Value<DateTime>? createdAt,
    Value<int>? synced,
  }) {
    return UserNickNamesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      nickName: nickName ?? this.nickName,
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
    if (nickName.present) {
      map['nick_name'] = Variable<String>(nickName.value);
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
    return (StringBuffer('UserNickNamesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('relatedUserId: $relatedUserId, ')
          ..write('nickName: $nickName, ')
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

class $ReportAttachmentsTable extends ReportAttachments
    with TableInfo<$ReportAttachmentsTable, ReportAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReportAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reportIdMeta = const VerificationMeta(
    'reportId',
  );
  @override
  late final GeneratedColumn<String> reportId = GeneratedColumn<String>(
    'report_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cloudUrlMeta = const VerificationMeta(
    'cloudUrl',
  );
  @override
  late final GeneratedColumn<String> cloudUrl = GeneratedColumn<String>(
    'cloud_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
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
    reportId,
    localPath,
    cloudUrl,
    fileName,
    mimeType,
    fileSizeBytes,
    createdAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'report_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReportAttachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('report_id')) {
      context.handle(
        _reportIdMeta,
        reportId.isAcceptableOrUnknown(data['report_id']!, _reportIdMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('cloud_url')) {
      context.handle(
        _cloudUrlMeta,
        cloudUrl.isAcceptableOrUnknown(data['cloud_url']!, _cloudUrlMeta),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
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
  ReportAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReportAttachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      reportId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}report_id'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      cloudUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_url'],
      ),
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      ),
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
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
  $ReportAttachmentsTable createAlias(String alias) {
    return $ReportAttachmentsTable(attachedDatabase, alias);
  }
}

class ReportAttachment extends DataClass
    implements Insertable<ReportAttachment> {
  final String id;
  final String? reportId;
  final String localPath;
  final String? cloudUrl;
  final String? fileName;
  final String? mimeType;
  final int? fileSizeBytes;
  final DateTime createdAt;
  final int synced;
  const ReportAttachment({
    required this.id,
    this.reportId,
    required this.localPath,
    this.cloudUrl,
    this.fileName,
    this.mimeType,
    this.fileSizeBytes,
    required this.createdAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || reportId != null) {
      map['report_id'] = Variable<String>(reportId);
    }
    map['local_path'] = Variable<String>(localPath);
    if (!nullToAbsent || cloudUrl != null) {
      map['cloud_url'] = Variable<String>(cloudUrl);
    }
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    if (!nullToAbsent || fileSizeBytes != null) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  ReportAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return ReportAttachmentsCompanion(
      id: Value(id),
      reportId: reportId == null && nullToAbsent
          ? const Value.absent()
          : Value(reportId),
      localPath: Value(localPath),
      cloudUrl: cloudUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudUrl),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      fileSizeBytes: fileSizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSizeBytes),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory ReportAttachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReportAttachment(
      id: serializer.fromJson<String>(json['id']),
      reportId: serializer.fromJson<String?>(json['reportId']),
      localPath: serializer.fromJson<String>(json['localPath']),
      cloudUrl: serializer.fromJson<String?>(json['cloudUrl']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      fileSizeBytes: serializer.fromJson<int?>(json['fileSizeBytes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'reportId': serializer.toJson<String?>(reportId),
      'localPath': serializer.toJson<String>(localPath),
      'cloudUrl': serializer.toJson<String?>(cloudUrl),
      'fileName': serializer.toJson<String?>(fileName),
      'mimeType': serializer.toJson<String?>(mimeType),
      'fileSizeBytes': serializer.toJson<int?>(fileSizeBytes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  ReportAttachment copyWith({
    String? id,
    Value<String?> reportId = const Value.absent(),
    String? localPath,
    Value<String?> cloudUrl = const Value.absent(),
    Value<String?> fileName = const Value.absent(),
    Value<String?> mimeType = const Value.absent(),
    Value<int?> fileSizeBytes = const Value.absent(),
    DateTime? createdAt,
    int? synced,
  }) => ReportAttachment(
    id: id ?? this.id,
    reportId: reportId.present ? reportId.value : this.reportId,
    localPath: localPath ?? this.localPath,
    cloudUrl: cloudUrl.present ? cloudUrl.value : this.cloudUrl,
    fileName: fileName.present ? fileName.value : this.fileName,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    fileSizeBytes: fileSizeBytes.present
        ? fileSizeBytes.value
        : this.fileSizeBytes,
    createdAt: createdAt ?? this.createdAt,
    synced: synced ?? this.synced,
  );
  ReportAttachment copyWithCompanion(ReportAttachmentsCompanion data) {
    return ReportAttachment(
      id: data.id.present ? data.id.value : this.id,
      reportId: data.reportId.present ? data.reportId.value : this.reportId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      cloudUrl: data.cloudUrl.present ? data.cloudUrl.value : this.cloudUrl,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReportAttachment(')
          ..write('id: $id, ')
          ..write('reportId: $reportId, ')
          ..write('localPath: $localPath, ')
          ..write('cloudUrl: $cloudUrl, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    reportId,
    localPath,
    cloudUrl,
    fileName,
    mimeType,
    fileSizeBytes,
    createdAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReportAttachment &&
          other.id == this.id &&
          other.reportId == this.reportId &&
          other.localPath == this.localPath &&
          other.cloudUrl == this.cloudUrl &&
          other.fileName == this.fileName &&
          other.mimeType == this.mimeType &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class ReportAttachmentsCompanion extends UpdateCompanion<ReportAttachment> {
  final Value<String> id;
  final Value<String?> reportId;
  final Value<String> localPath;
  final Value<String?> cloudUrl;
  final Value<String?> fileName;
  final Value<String?> mimeType;
  final Value<int?> fileSizeBytes;
  final Value<DateTime> createdAt;
  final Value<int> synced;
  final Value<int> rowid;
  const ReportAttachmentsCompanion({
    this.id = const Value.absent(),
    this.reportId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.cloudUrl = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReportAttachmentsCompanion.insert({
    required String id,
    this.reportId = const Value.absent(),
    required String localPath,
    this.cloudUrl = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       localPath = Value(localPath);
  static Insertable<ReportAttachment> custom({
    Expression<String>? id,
    Expression<String>? reportId,
    Expression<String>? localPath,
    Expression<String>? cloudUrl,
    Expression<String>? fileName,
    Expression<String>? mimeType,
    Expression<int>? fileSizeBytes,
    Expression<DateTime>? createdAt,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reportId != null) 'report_id': reportId,
      if (localPath != null) 'local_path': localPath,
      if (cloudUrl != null) 'cloud_url': cloudUrl,
      if (fileName != null) 'file_name': fileName,
      if (mimeType != null) 'mime_type': mimeType,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReportAttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String?>? reportId,
    Value<String>? localPath,
    Value<String?>? cloudUrl,
    Value<String?>? fileName,
    Value<String?>? mimeType,
    Value<int?>? fileSizeBytes,
    Value<DateTime>? createdAt,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return ReportAttachmentsCompanion(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      localPath: localPath ?? this.localPath,
      cloudUrl: cloudUrl ?? this.cloudUrl,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
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
    if (reportId.present) {
      map['report_id'] = Variable<String>(reportId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (cloudUrl.present) {
      map['cloud_url'] = Variable<String>(cloudUrl.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
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
    return (StringBuffer('ReportAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('reportId: $reportId, ')
          ..write('localPath: $localPath, ')
          ..write('cloudUrl: $cloudUrl, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
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
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _reminderTypeMeta = const VerificationMeta(
    'reminderType',
  );
  @override
  late final GeneratedColumn<String> reminderType = GeneratedColumn<String>(
    'reminder_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Daily'),
  );
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
    'hour',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
    'minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelsMeta = const VerificationMeta(
    'channels',
  );
  @override
  late final GeneratedColumn<String> channels = GeneratedColumn<String>(
    'channels',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _configurableMeta = const VerificationMeta(
    'configurable',
  );
  @override
  late final GeneratedColumn<bool> configurable = GeneratedColumn<bool>(
    'configurable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("configurable" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
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
    title,
    reminderType,
    frequency,
    hour,
    minute,
    channels,
    enabled,
    configurable,
    startDate,
    endDate,
    createdAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('reminder_type')) {
      context.handle(
        _reminderTypeMeta,
        reminderType.isAcceptableOrUnknown(
          data['reminder_type']!,
          _reminderTypeMeta,
        ),
      );
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('hour')) {
      context.handle(
        _hourMeta,
        hour.isAcceptableOrUnknown(data['hour']!, _hourMeta),
      );
    }
    if (data.containsKey('minute')) {
      context.handle(
        _minuteMeta,
        minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta),
      );
    }
    if (data.containsKey('channels')) {
      context.handle(
        _channelsMeta,
        channels.isAcceptableOrUnknown(data['channels']!, _channelsMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('configurable')) {
      context.handle(
        _configurableMeta,
        configurable.isAcceptableOrUnknown(
          data['configurable']!,
          _configurableMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
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
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      reminderType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_type'],
      ),
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      hour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour'],
      ),
      minute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute'],
      ),
      channels: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channels'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      configurable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}configurable'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
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
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final String id;
  final String? userId;
  final String title;
  final String? reminderType;
  final String frequency;
  final int? hour;
  final int? minute;
  final String? channels;
  final bool enabled;
  final bool configurable;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final int synced;
  const Reminder({
    required this.id,
    this.userId,
    required this.title,
    this.reminderType,
    required this.frequency,
    this.hour,
    this.minute,
    this.channels,
    required this.enabled,
    required this.configurable,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || reminderType != null) {
      map['reminder_type'] = Variable<String>(reminderType);
    }
    map['frequency'] = Variable<String>(frequency);
    if (!nullToAbsent || hour != null) {
      map['hour'] = Variable<int>(hour);
    }
    if (!nullToAbsent || minute != null) {
      map['minute'] = Variable<int>(minute);
    }
    if (!nullToAbsent || channels != null) {
      map['channels'] = Variable<String>(channels);
    }
    map['enabled'] = Variable<bool>(enabled);
    map['configurable'] = Variable<bool>(configurable);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<int>(synced);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      title: Value(title),
      reminderType: reminderType == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderType),
      frequency: Value(frequency),
      hour: hour == null && nullToAbsent ? const Value.absent() : Value(hour),
      minute: minute == null && nullToAbsent
          ? const Value.absent()
          : Value(minute),
      channels: channels == null && nullToAbsent
          ? const Value.absent()
          : Value(channels),
      enabled: Value(enabled),
      configurable: Value(configurable),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      reminderType: serializer.fromJson<String?>(json['reminderType']),
      frequency: serializer.fromJson<String>(json['frequency']),
      hour: serializer.fromJson<int?>(json['hour']),
      minute: serializer.fromJson<int?>(json['minute']),
      channels: serializer.fromJson<String?>(json['channels']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      configurable: serializer.fromJson<bool>(json['configurable']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'title': serializer.toJson<String>(title),
      'reminderType': serializer.toJson<String?>(reminderType),
      'frequency': serializer.toJson<String>(frequency),
      'hour': serializer.toJson<int?>(hour),
      'minute': serializer.toJson<int?>(minute),
      'channels': serializer.toJson<String?>(channels),
      'enabled': serializer.toJson<bool>(enabled),
      'configurable': serializer.toJson<bool>(configurable),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<int>(synced),
    };
  }

  Reminder copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    String? title,
    Value<String?> reminderType = const Value.absent(),
    String? frequency,
    Value<int?> hour = const Value.absent(),
    Value<int?> minute = const Value.absent(),
    Value<String?> channels = const Value.absent(),
    bool? enabled,
    bool? configurable,
    Value<DateTime?> startDate = const Value.absent(),
    Value<DateTime?> endDate = const Value.absent(),
    DateTime? createdAt,
    int? synced,
  }) => Reminder(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    title: title ?? this.title,
    reminderType: reminderType.present ? reminderType.value : this.reminderType,
    frequency: frequency ?? this.frequency,
    hour: hour.present ? hour.value : this.hour,
    minute: minute.present ? minute.value : this.minute,
    channels: channels.present ? channels.value : this.channels,
    enabled: enabled ?? this.enabled,
    configurable: configurable ?? this.configurable,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    createdAt: createdAt ?? this.createdAt,
    synced: synced ?? this.synced,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      reminderType: data.reminderType.present
          ? data.reminderType.value
          : this.reminderType,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
      channels: data.channels.present ? data.channels.value : this.channels,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      configurable: data.configurable.present
          ? data.configurable.value
          : this.configurable,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('reminderType: $reminderType, ')
          ..write('frequency: $frequency, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('channels: $channels, ')
          ..write('enabled: $enabled, ')
          ..write('configurable: $configurable, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    title,
    reminderType,
    frequency,
    hour,
    minute,
    channels,
    enabled,
    configurable,
    startDate,
    endDate,
    createdAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.reminderType == this.reminderType &&
          other.frequency == this.frequency &&
          other.hour == this.hour &&
          other.minute == this.minute &&
          other.channels == this.channels &&
          other.enabled == this.enabled &&
          other.configurable == this.configurable &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String> title;
  final Value<String?> reminderType;
  final Value<String> frequency;
  final Value<int?> hour;
  final Value<int?> minute;
  final Value<String?> channels;
  final Value<bool> enabled;
  final Value<bool> configurable;
  final Value<DateTime?> startDate;
  final Value<DateTime?> endDate;
  final Value<DateTime> createdAt;
  final Value<int> synced;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.reminderType = const Value.absent(),
    this.frequency = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.channels = const Value.absent(),
    this.enabled = const Value.absent(),
    this.configurable = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    required String title,
    this.reminderType = const Value.absent(),
    this.frequency = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.channels = const Value.absent(),
    this.enabled = const Value.absent(),
    this.configurable = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<Reminder> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? reminderType,
    Expression<String>? frequency,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<String>? channels,
    Expression<bool>? enabled,
    Expression<bool>? configurable,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<DateTime>? createdAt,
    Expression<int>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (reminderType != null) 'reminder_type': reminderType,
      if (frequency != null) 'frequency': frequency,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (channels != null) 'channels': channels,
      if (enabled != null) 'enabled': enabled,
      if (configurable != null) 'configurable': configurable,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String>? title,
    Value<String?>? reminderType,
    Value<String>? frequency,
    Value<int?>? hour,
    Value<int?>? minute,
    Value<String?>? channels,
    Value<bool>? enabled,
    Value<bool>? configurable,
    Value<DateTime?>? startDate,
    Value<DateTime?>? endDate,
    Value<DateTime>? createdAt,
    Value<int>? synced,
    Value<int>? rowid,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      reminderType: reminderType ?? this.reminderType,
      frequency: frequency ?? this.frequency,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      channels: channels ?? this.channels,
      enabled: enabled ?? this.enabled,
      configurable: configurable ?? this.configurable,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
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
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (reminderType.present) {
      map['reminder_type'] = Variable<String>(reminderType.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (channels.present) {
      map['channels'] = Variable<String>(channels.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (configurable.present) {
      map['configurable'] = Variable<bool>(configurable.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
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
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('reminderType: $reminderType, ')
          ..write('frequency: $frequency, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('channels: $channels, ')
          ..write('enabled: $enabled, ')
          ..write('configurable: $configurable, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDriftDatabase extends GeneratedDatabase {
  _$AppDriftDatabase(QueryExecutor e) : super(e);
  $AppDriftDatabaseManager get managers => $AppDriftDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $UserLoginsTableTable userLoginsTable = $UserLoginsTableTable(
    this,
  );
  late final $HealthDataTableTable healthDataTable = $HealthDataTableTable(
    this,
  );
  late final $VitalsStreamTableTable vitalsStreamTable =
      $VitalsStreamTableTable(this);
  late final $PregnanciesTable pregnancies = $PregnanciesTable(this);
  late final $AncCheckupDatesTable ancCheckupDates = $AncCheckupDatesTable(
    this,
  );
  late final $PregnancyImmunizationRecordsTable pregnancyImmunizationRecords =
      $PregnancyImmunizationRecordsTable(this);
  late final $PregnancyReportChecklistsTable pregnancyReportChecklists =
      $PregnancyReportChecklistsTable(this);
  late final $BabiesTable babies = $BabiesTable(this);
  late final $BabyImmunizationRecordsTable babyImmunizationRecords =
      $BabyImmunizationRecordsTable(this);
  late final $BabyMilestonesTable babyMilestones = $BabyMilestonesTable(this);
  late final $SyncStatesTable syncStates = $SyncStatesTable(this);
  late final $InitialSetupTable initialSetup = $InitialSetupTable(this);
  late final $UserEntitiesTable userEntities = $UserEntitiesTable(this);
  late final $UserRelationsTable userRelations = $UserRelationsTable(this);
  late final $UserNickNamesTable userNickNames = $UserNickNamesTable(this);
  late final $FamiliesTable families = $FamiliesTable(this);
  late final $FamilyRequestsTableTable familyRequestsTable =
      $FamilyRequestsTableTable(this);
  late final $FamilyMembersTableTable familyMembersTable =
      $FamilyMembersTableTable(this);
  late final $CycleHistoriesTable cycleHistories = $CycleHistoriesTable(this);
  late final $PrescriptionsTable prescriptions = $PrescriptionsTable(this);
  late final $PrescriptionMedicinesTable prescriptionMedicines =
      $PrescriptionMedicinesTable(this);
  late final $PrescriptionMedicineTimingsTable prescriptionMedicineTimings =
      $PrescriptionMedicineTimingsTable(this);
  late final $ReportsTable reports = $ReportsTable(this);
  late final $ReportAttachmentsTable reportAttachments =
      $ReportAttachmentsTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    userLoginsTable,
    healthDataTable,
    vitalsStreamTable,
    pregnancies,
    ancCheckupDates,
    pregnancyImmunizationRecords,
    pregnancyReportChecklists,
    babies,
    babyImmunizationRecords,
    babyMilestones,
    syncStates,
    initialSetup,
    userEntities,
    userRelations,
    userNickNames,
    families,
    familyRequestsTable,
    familyMembersTable,
    cycleHistories,
    prescriptions,
    prescriptionMedicines,
    prescriptionMedicineTimings,
    reports,
    reportAttachments,
    reminders,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String id,
      Value<String?> name,
      Value<String?> email,
      Value<String?> phone,
      Value<DateTime?> phoneVerified,
      Value<String?> countryCode,
      Value<DateTime?> emailVerified,
      Value<String?> coverPic,
      Value<String?> bio,
      Value<String?> gender,
      Value<DateTime?> dob,
      Value<String?> profilePicture,
      Value<String> userType,
      Value<String?> addressLine1,
      Value<String?> addressLine2,
      Value<String?> city,
      Value<String?> pincode,
      Value<double?> lat,
      Value<double?> lng,
      Value<bool> isRegistered,
      Value<String?> userName,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> syncedAt,
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
      Value<DateTime?> emailVerified,
      Value<String?> coverPic,
      Value<String?> bio,
      Value<String?> gender,
      Value<DateTime?> dob,
      Value<String?> profilePicture,
      Value<String> userType,
      Value<String?> addressLine1,
      Value<String?> addressLine2,
      Value<String?> city,
      Value<String?> pincode,
      Value<double?> lat,
      Value<double?> lng,
      Value<bool> isRegistered,
      Value<String?> userName,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> syncedAt,
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

  ColumnFilters<DateTime> get emailVerified => $composableBuilder(
    column: $table.emailVerified,
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

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dob => $composableBuilder(
    column: $table.dob,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profilePicture => $composableBuilder(
    column: $table.profilePicture,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userType => $composableBuilder(
    column: $table.userType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addressLine1 => $composableBuilder(
    column: $table.addressLine1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addressLine2 => $composableBuilder(
    column: $table.addressLine2,
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

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRegistered => $composableBuilder(
    column: $table.isRegistered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
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

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
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

  ColumnOrderings<DateTime> get emailVerified => $composableBuilder(
    column: $table.emailVerified,
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

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dob => $composableBuilder(
    column: $table.dob,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profilePicture => $composableBuilder(
    column: $table.profilePicture,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userType => $composableBuilder(
    column: $table.userType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addressLine1 => $composableBuilder(
    column: $table.addressLine1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addressLine2 => $composableBuilder(
    column: $table.addressLine2,
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

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRegistered => $composableBuilder(
    column: $table.isRegistered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
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

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
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

  GeneratedColumn<DateTime> get emailVerified => $composableBuilder(
    column: $table.emailVerified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverPic =>
      $composableBuilder(column: $table.coverPic, builder: (column) => column);

  GeneratedColumn<String> get bio =>
      $composableBuilder(column: $table.bio, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<DateTime> get dob =>
      $composableBuilder(column: $table.dob, builder: (column) => column);

  GeneratedColumn<String> get profilePicture => $composableBuilder(
    column: $table.profilePicture,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userType =>
      $composableBuilder(column: $table.userType, builder: (column) => column);

  GeneratedColumn<String> get addressLine1 => $composableBuilder(
    column: $table.addressLine1,
    builder: (column) => column,
  );

  GeneratedColumn<String> get addressLine2 => $composableBuilder(
    column: $table.addressLine2,
    builder: (column) => column,
  );

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get pincode =>
      $composableBuilder(column: $table.pincode, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<bool> get isRegistered => $composableBuilder(
    column: $table.isRegistered,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

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
                Value<DateTime?> emailVerified = const Value.absent(),
                Value<String?> coverPic = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<DateTime?> dob = const Value.absent(),
                Value<String?> profilePicture = const Value.absent(),
                Value<String> userType = const Value.absent(),
                Value<String?> addressLine1 = const Value.absent(),
                Value<String?> addressLine2 = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> pincode = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<bool> isRegistered = const Value.absent(),
                Value<String?> userName = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                name: name,
                email: email,
                phone: phone,
                phoneVerified: phoneVerified,
                countryCode: countryCode,
                emailVerified: emailVerified,
                coverPic: coverPic,
                bio: bio,
                gender: gender,
                dob: dob,
                profilePicture: profilePicture,
                userType: userType,
                addressLine1: addressLine1,
                addressLine2: addressLine2,
                city: city,
                pincode: pincode,
                lat: lat,
                lng: lng,
                isRegistered: isRegistered,
                userName: userName,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
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
                Value<DateTime?> emailVerified = const Value.absent(),
                Value<String?> coverPic = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<DateTime?> dob = const Value.absent(),
                Value<String?> profilePicture = const Value.absent(),
                Value<String> userType = const Value.absent(),
                Value<String?> addressLine1 = const Value.absent(),
                Value<String?> addressLine2 = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> pincode = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<bool> isRegistered = const Value.absent(),
                Value<String?> userName = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                name: name,
                email: email,
                phone: phone,
                phoneVerified: phoneVerified,
                countryCode: countryCode,
                emailVerified: emailVerified,
                coverPic: coverPic,
                bio: bio,
                gender: gender,
                dob: dob,
                profilePicture: profilePicture,
                userType: userType,
                addressLine1: addressLine1,
                addressLine2: addressLine2,
                city: city,
                pincode: pincode,
                lat: lat,
                lng: lng,
                isRegistered: isRegistered,
                userName: userName,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
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
typedef $$UserLoginsTableTableCreateCompanionBuilder =
    UserLoginsTableCompanion Function({
      required String id,
      required String userId,
      Value<String?> ipAddress,
      Value<String?> deviceType,
      Value<String?> location,
      Value<String?> latitude,
      Value<String?> longitude,
      Value<DateTime?> revokedAt,
      Value<DateTime> createdAt,
      Value<String?> fcmToken,
      Value<DateTime?> lastAccessedAt,
      Value<DateTime?> loggedOutAt,
      Value<int> rowid,
    });
typedef $$UserLoginsTableTableUpdateCompanionBuilder =
    UserLoginsTableCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String?> ipAddress,
      Value<String?> deviceType,
      Value<String?> location,
      Value<String?> latitude,
      Value<String?> longitude,
      Value<DateTime?> revokedAt,
      Value<DateTime> createdAt,
      Value<String?> fcmToken,
      Value<DateTime?> lastAccessedAt,
      Value<DateTime?> loggedOutAt,
      Value<int> rowid,
    });

class $$UserLoginsTableTableFilterComposer
    extends Composer<_$AppDriftDatabase, $UserLoginsTableTable> {
  $$UserLoginsTableTableFilterComposer({
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

  ColumnFilters<String> get ipAddress => $composableBuilder(
    column: $table.ipAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceType => $composableBuilder(
    column: $table.deviceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fcmToken => $composableBuilder(
    column: $table.fcmToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedOutAt => $composableBuilder(
    column: $table.loggedOutAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserLoginsTableTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $UserLoginsTableTable> {
  $$UserLoginsTableTableOrderingComposer({
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

  ColumnOrderings<String> get ipAddress => $composableBuilder(
    column: $table.ipAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceType => $composableBuilder(
    column: $table.deviceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fcmToken => $composableBuilder(
    column: $table.fcmToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedOutAt => $composableBuilder(
    column: $table.loggedOutAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserLoginsTableTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $UserLoginsTableTable> {
  $$UserLoginsTableTableAnnotationComposer({
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

  GeneratedColumn<String> get ipAddress =>
      $composableBuilder(column: $table.ipAddress, builder: (column) => column);

  GeneratedColumn<String> get deviceType => $composableBuilder(
    column: $table.deviceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<String> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get revokedAt =>
      $composableBuilder(column: $table.revokedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get fcmToken =>
      $composableBuilder(column: $table.fcmToken, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get loggedOutAt => $composableBuilder(
    column: $table.loggedOutAt,
    builder: (column) => column,
  );
}

class $$UserLoginsTableTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $UserLoginsTableTable,
          UserLoginsTableData,
          $$UserLoginsTableTableFilterComposer,
          $$UserLoginsTableTableOrderingComposer,
          $$UserLoginsTableTableAnnotationComposer,
          $$UserLoginsTableTableCreateCompanionBuilder,
          $$UserLoginsTableTableUpdateCompanionBuilder,
          (
            UserLoginsTableData,
            BaseReferences<
              _$AppDriftDatabase,
              $UserLoginsTableTable,
              UserLoginsTableData
            >,
          ),
          UserLoginsTableData,
          PrefetchHooks Function()
        > {
  $$UserLoginsTableTableTableManager(
    _$AppDriftDatabase db,
    $UserLoginsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserLoginsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserLoginsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserLoginsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> ipAddress = const Value.absent(),
                Value<String?> deviceType = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> latitude = const Value.absent(),
                Value<String?> longitude = const Value.absent(),
                Value<DateTime?> revokedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> fcmToken = const Value.absent(),
                Value<DateTime?> lastAccessedAt = const Value.absent(),
                Value<DateTime?> loggedOutAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserLoginsTableCompanion(
                id: id,
                userId: userId,
                ipAddress: ipAddress,
                deviceType: deviceType,
                location: location,
                latitude: latitude,
                longitude: longitude,
                revokedAt: revokedAt,
                createdAt: createdAt,
                fcmToken: fcmToken,
                lastAccessedAt: lastAccessedAt,
                loggedOutAt: loggedOutAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String?> ipAddress = const Value.absent(),
                Value<String?> deviceType = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> latitude = const Value.absent(),
                Value<String?> longitude = const Value.absent(),
                Value<DateTime?> revokedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> fcmToken = const Value.absent(),
                Value<DateTime?> lastAccessedAt = const Value.absent(),
                Value<DateTime?> loggedOutAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserLoginsTableCompanion.insert(
                id: id,
                userId: userId,
                ipAddress: ipAddress,
                deviceType: deviceType,
                location: location,
                latitude: latitude,
                longitude: longitude,
                revokedAt: revokedAt,
                createdAt: createdAt,
                fcmToken: fcmToken,
                lastAccessedAt: lastAccessedAt,
                loggedOutAt: loggedOutAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserLoginsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $UserLoginsTableTable,
      UserLoginsTableData,
      $$UserLoginsTableTableFilterComposer,
      $$UserLoginsTableTableOrderingComposer,
      $$UserLoginsTableTableAnnotationComposer,
      $$UserLoginsTableTableCreateCompanionBuilder,
      $$UserLoginsTableTableUpdateCompanionBuilder,
      (
        UserLoginsTableData,
        BaseReferences<
          _$AppDriftDatabase,
          $UserLoginsTableTable,
          UserLoginsTableData
        >,
      ),
      UserLoginsTableData,
      PrefetchHooks Function()
    >;
typedef $$HealthDataTableTableCreateCompanionBuilder =
    HealthDataTableCompanion Function({
      required String id,
      required String userId,
      Value<DateTime?> lmpDate,
      Value<String?> rchId,
      Value<String?> allergies,
      Value<String?> medicalCondition,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> syncedAt,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$HealthDataTableTableUpdateCompanionBuilder =
    HealthDataTableCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<DateTime?> lmpDate,
      Value<String?> rchId,
      Value<String?> allergies,
      Value<String?> medicalCondition,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> syncedAt,
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

  ColumnFilters<DateTime> get lmpDate => $composableBuilder(
    column: $table.lmpDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rchId => $composableBuilder(
    column: $table.rchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allergies => $composableBuilder(
    column: $table.allergies,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicalCondition => $composableBuilder(
    column: $table.medicalCondition,
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

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
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

  ColumnOrderings<DateTime> get lmpDate => $composableBuilder(
    column: $table.lmpDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rchId => $composableBuilder(
    column: $table.rchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allergies => $composableBuilder(
    column: $table.allergies,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicalCondition => $composableBuilder(
    column: $table.medicalCondition,
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

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
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

  GeneratedColumn<DateTime> get lmpDate =>
      $composableBuilder(column: $table.lmpDate, builder: (column) => column);

  GeneratedColumn<String> get rchId =>
      $composableBuilder(column: $table.rchId, builder: (column) => column);

  GeneratedColumn<String> get allergies =>
      $composableBuilder(column: $table.allergies, builder: (column) => column);

  GeneratedColumn<String> get medicalCondition => $composableBuilder(
    column: $table.medicalCondition,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

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
                Value<String> userId = const Value.absent(),
                Value<DateTime?> lmpDate = const Value.absent(),
                Value<String?> rchId = const Value.absent(),
                Value<String?> allergies = const Value.absent(),
                Value<String?> medicalCondition = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthDataTableCompanion(
                id: id,
                userId: userId,
                lmpDate: lmpDate,
                rchId: rchId,
                allergies: allergies,
                medicalCondition: medicalCondition,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<DateTime?> lmpDate = const Value.absent(),
                Value<String?> rchId = const Value.absent(),
                Value<String?> allergies = const Value.absent(),
                Value<String?> medicalCondition = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthDataTableCompanion.insert(
                id: id,
                userId: userId,
                lmpDate: lmpDate,
                rchId: rchId,
                allergies: allergies,
                medicalCondition: medicalCondition,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
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
typedef $$VitalsStreamTableTableCreateCompanionBuilder =
    VitalsStreamTableCompanion Function({
      required String id,
      Value<String?> healthId,
      required String key,
      Value<double?> value,
      Value<String?> unit,
      Value<String?> data,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$VitalsStreamTableTableUpdateCompanionBuilder =
    VitalsStreamTableCompanion Function({
      Value<String> id,
      Value<String?> healthId,
      Value<String> key,
      Value<double?> value,
      Value<String?> unit,
      Value<String?> data,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
      Value<int> synced,
      Value<int> rowid,
    });

class $$VitalsStreamTableTableFilterComposer
    extends Composer<_$AppDriftDatabase, $VitalsStreamTableTable> {
  $$VitalsStreamTableTableFilterComposer({
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

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
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

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VitalsStreamTableTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $VitalsStreamTableTable> {
  $$VitalsStreamTableTableOrderingComposer({
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

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
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

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VitalsStreamTableTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $VitalsStreamTableTable> {
  $$VitalsStreamTableTableAnnotationComposer({
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

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$VitalsStreamTableTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $VitalsStreamTableTable,
          VitalsStreamTableData,
          $$VitalsStreamTableTableFilterComposer,
          $$VitalsStreamTableTableOrderingComposer,
          $$VitalsStreamTableTableAnnotationComposer,
          $$VitalsStreamTableTableCreateCompanionBuilder,
          $$VitalsStreamTableTableUpdateCompanionBuilder,
          (
            VitalsStreamTableData,
            BaseReferences<
              _$AppDriftDatabase,
              $VitalsStreamTableTable,
              VitalsStreamTableData
            >,
          ),
          VitalsStreamTableData,
          PrefetchHooks Function()
        > {
  $$VitalsStreamTableTableTableManager(
    _$AppDriftDatabase db,
    $VitalsStreamTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VitalsStreamTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VitalsStreamTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VitalsStreamTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> healthId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<double?> value = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> data = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VitalsStreamTableCompanion(
                id: id,
                healthId: healthId,
                key: key,
                value: value,
                unit: unit,
                data: data,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> healthId = const Value.absent(),
                required String key,
                Value<double?> value = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> data = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VitalsStreamTableCompanion.insert(
                id: id,
                healthId: healthId,
                key: key,
                value: value,
                unit: unit,
                data: data,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
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

typedef $$VitalsStreamTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $VitalsStreamTableTable,
      VitalsStreamTableData,
      $$VitalsStreamTableTableFilterComposer,
      $$VitalsStreamTableTableOrderingComposer,
      $$VitalsStreamTableTableAnnotationComposer,
      $$VitalsStreamTableTableCreateCompanionBuilder,
      $$VitalsStreamTableTableUpdateCompanionBuilder,
      (
        VitalsStreamTableData,
        BaseReferences<
          _$AppDriftDatabase,
          $VitalsStreamTableTable,
          VitalsStreamTableData
        >,
      ),
      VitalsStreamTableData,
      PrefetchHooks Function()
    >;
typedef $$PregnanciesTableCreateCompanionBuilder =
    PregnanciesCompanion Function({
      required String id,
      Value<DateTime?> lmpDate,
      Value<DateTime?> eddDate,
      Value<String?> healthId,
      Value<DateTime?> deliveryDateTime,
      Value<String> status,
      Value<String?> createdBy,
      Value<String?> data,
      Value<String?> highestRiskStatus,
      Value<String?> allFlaggedComplications,
      Value<String?> riskStatus,
      Value<String?> flaggedComplications,
      Value<String?> overallHealth,
      Value<int> gravidity,
      Value<int> parity,
      Value<int> livingChildren,
      Value<int> abortions,
      Value<int> stillBirths,
      Value<int> miscarriages,
      Value<int> csectionDeliveries,
      Value<String?> obstetricCode,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$PregnanciesTableUpdateCompanionBuilder =
    PregnanciesCompanion Function({
      Value<String> id,
      Value<DateTime?> lmpDate,
      Value<DateTime?> eddDate,
      Value<String?> healthId,
      Value<DateTime?> deliveryDateTime,
      Value<String> status,
      Value<String?> createdBy,
      Value<String?> data,
      Value<String?> highestRiskStatus,
      Value<String?> allFlaggedComplications,
      Value<String?> riskStatus,
      Value<String?> flaggedComplications,
      Value<String?> overallHealth,
      Value<int> gravidity,
      Value<int> parity,
      Value<int> livingChildren,
      Value<int> abortions,
      Value<int> stillBirths,
      Value<int> miscarriages,
      Value<int> csectionDeliveries,
      Value<String?> obstetricCode,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
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

  ColumnFilters<DateTime> get eddDate => $composableBuilder(
    column: $table.eddDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get healthId => $composableBuilder(
    column: $table.healthId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deliveryDateTime => $composableBuilder(
    column: $table.deliveryDateTime,
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

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
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

  ColumnOrderings<DateTime> get eddDate => $composableBuilder(
    column: $table.eddDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthId => $composableBuilder(
    column: $table.healthId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deliveryDateTime => $composableBuilder(
    column: $table.deliveryDateTime,
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

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
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

  GeneratedColumn<DateTime> get eddDate =>
      $composableBuilder(column: $table.eddDate, builder: (column) => column);

  GeneratedColumn<String> get healthId =>
      $composableBuilder(column: $table.healthId, builder: (column) => column);

  GeneratedColumn<DateTime> get deliveryDateTime => $composableBuilder(
    column: $table.deliveryDateTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

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
                Value<DateTime?> eddDate = const Value.absent(),
                Value<String?> healthId = const Value.absent(),
                Value<DateTime?> deliveryDateTime = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> data = const Value.absent(),
                Value<String?> highestRiskStatus = const Value.absent(),
                Value<String?> allFlaggedComplications = const Value.absent(),
                Value<String?> riskStatus = const Value.absent(),
                Value<String?> flaggedComplications = const Value.absent(),
                Value<String?> overallHealth = const Value.absent(),
                Value<int> gravidity = const Value.absent(),
                Value<int> parity = const Value.absent(),
                Value<int> livingChildren = const Value.absent(),
                Value<int> abortions = const Value.absent(),
                Value<int> stillBirths = const Value.absent(),
                Value<int> miscarriages = const Value.absent(),
                Value<int> csectionDeliveries = const Value.absent(),
                Value<String?> obstetricCode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PregnanciesCompanion(
                id: id,
                lmpDate: lmpDate,
                eddDate: eddDate,
                healthId: healthId,
                deliveryDateTime: deliveryDateTime,
                status: status,
                createdBy: createdBy,
                data: data,
                highestRiskStatus: highestRiskStatus,
                allFlaggedComplications: allFlaggedComplications,
                riskStatus: riskStatus,
                flaggedComplications: flaggedComplications,
                overallHealth: overallHealth,
                gravidity: gravidity,
                parity: parity,
                livingChildren: livingChildren,
                abortions: abortions,
                stillBirths: stillBirths,
                miscarriages: miscarriages,
                csectionDeliveries: csectionDeliveries,
                obstetricCode: obstetricCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime?> lmpDate = const Value.absent(),
                Value<DateTime?> eddDate = const Value.absent(),
                Value<String?> healthId = const Value.absent(),
                Value<DateTime?> deliveryDateTime = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> data = const Value.absent(),
                Value<String?> highestRiskStatus = const Value.absent(),
                Value<String?> allFlaggedComplications = const Value.absent(),
                Value<String?> riskStatus = const Value.absent(),
                Value<String?> flaggedComplications = const Value.absent(),
                Value<String?> overallHealth = const Value.absent(),
                Value<int> gravidity = const Value.absent(),
                Value<int> parity = const Value.absent(),
                Value<int> livingChildren = const Value.absent(),
                Value<int> abortions = const Value.absent(),
                Value<int> stillBirths = const Value.absent(),
                Value<int> miscarriages = const Value.absent(),
                Value<int> csectionDeliveries = const Value.absent(),
                Value<String?> obstetricCode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PregnanciesCompanion.insert(
                id: id,
                lmpDate: lmpDate,
                eddDate: eddDate,
                healthId: healthId,
                deliveryDateTime: deliveryDateTime,
                status: status,
                createdBy: createdBy,
                data: data,
                highestRiskStatus: highestRiskStatus,
                allFlaggedComplications: allFlaggedComplications,
                riskStatus: riskStatus,
                flaggedComplications: flaggedComplications,
                overallHealth: overallHealth,
                gravidity: gravidity,
                parity: parity,
                livingChildren: livingChildren,
                abortions: abortions,
                stillBirths: stillBirths,
                miscarriages: miscarriages,
                csectionDeliveries: csectionDeliveries,
                obstetricCode: obstetricCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
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
typedef $$AncCheckupDatesTableCreateCompanionBuilder =
    AncCheckupDatesCompanion Function({
      required String id,
      Value<String?> pregnancyId,
      Value<DateTime?> scheduledDate,
      required int month,
      Value<DateTime?> completedAt,
      Value<DateTime?> scheduledDateRangeFrom,
      Value<DateTime?> scheduledDateRangeTo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$AncCheckupDatesTableUpdateCompanionBuilder =
    AncCheckupDatesCompanion Function({
      Value<String> id,
      Value<String?> pregnancyId,
      Value<DateTime?> scheduledDate,
      Value<int> month,
      Value<DateTime?> completedAt,
      Value<DateTime?> scheduledDateRangeFrom,
      Value<DateTime?> scheduledDateRangeTo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
      Value<int> synced,
      Value<int> rowid,
    });

class $$AncCheckupDatesTableFilterComposer
    extends Composer<_$AppDriftDatabase, $AncCheckupDatesTable> {
  $$AncCheckupDatesTableFilterComposer({
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

  ColumnFilters<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDateRangeFrom => $composableBuilder(
    column: $table.scheduledDateRangeFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDateRangeTo => $composableBuilder(
    column: $table.scheduledDateRangeTo,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AncCheckupDatesTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $AncCheckupDatesTable> {
  $$AncCheckupDatesTableOrderingComposer({
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

  ColumnOrderings<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDateRangeFrom => $composableBuilder(
    column: $table.scheduledDateRangeFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDateRangeTo => $composableBuilder(
    column: $table.scheduledDateRangeTo,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AncCheckupDatesTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $AncCheckupDatesTable> {
  $$AncCheckupDatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledDateRangeFrom => $composableBuilder(
    column: $table.scheduledDateRangeFrom,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledDateRangeTo => $composableBuilder(
    column: $table.scheduledDateRangeTo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$AncCheckupDatesTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $AncCheckupDatesTable,
          AncCheckupDate,
          $$AncCheckupDatesTableFilterComposer,
          $$AncCheckupDatesTableOrderingComposer,
          $$AncCheckupDatesTableAnnotationComposer,
          $$AncCheckupDatesTableCreateCompanionBuilder,
          $$AncCheckupDatesTableUpdateCompanionBuilder,
          (
            AncCheckupDate,
            BaseReferences<
              _$AppDriftDatabase,
              $AncCheckupDatesTable,
              AncCheckupDate
            >,
          ),
          AncCheckupDate,
          PrefetchHooks Function()
        > {
  $$AncCheckupDatesTableTableManager(
    _$AppDriftDatabase db,
    $AncCheckupDatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AncCheckupDatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AncCheckupDatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AncCheckupDatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> pregnancyId = const Value.absent(),
                Value<DateTime?> scheduledDate = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> scheduledDateRangeFrom = const Value.absent(),
                Value<DateTime?> scheduledDateRangeTo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AncCheckupDatesCompanion(
                id: id,
                pregnancyId: pregnancyId,
                scheduledDate: scheduledDate,
                month: month,
                completedAt: completedAt,
                scheduledDateRangeFrom: scheduledDateRangeFrom,
                scheduledDateRangeTo: scheduledDateRangeTo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> pregnancyId = const Value.absent(),
                Value<DateTime?> scheduledDate = const Value.absent(),
                required int month,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> scheduledDateRangeFrom = const Value.absent(),
                Value<DateTime?> scheduledDateRangeTo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AncCheckupDatesCompanion.insert(
                id: id,
                pregnancyId: pregnancyId,
                scheduledDate: scheduledDate,
                month: month,
                completedAt: completedAt,
                scheduledDateRangeFrom: scheduledDateRangeFrom,
                scheduledDateRangeTo: scheduledDateRangeTo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
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

typedef $$AncCheckupDatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $AncCheckupDatesTable,
      AncCheckupDate,
      $$AncCheckupDatesTableFilterComposer,
      $$AncCheckupDatesTableOrderingComposer,
      $$AncCheckupDatesTableAnnotationComposer,
      $$AncCheckupDatesTableCreateCompanionBuilder,
      $$AncCheckupDatesTableUpdateCompanionBuilder,
      (
        AncCheckupDate,
        BaseReferences<
          _$AppDriftDatabase,
          $AncCheckupDatesTable,
          AncCheckupDate
        >,
      ),
      AncCheckupDate,
      PrefetchHooks Function()
    >;
typedef $$PregnancyImmunizationRecordsTableCreateCompanionBuilder =
    PregnancyImmunizationRecordsCompanion Function({
      required String id,
      Value<String?> pregnancyId,
      required String vaccineName,
      Value<DateTime?> scheduledDate,
      Value<DateTime?> receivedDate,
      Value<bool> required,
      Value<DateTime?> scheduledDateRangeFrom,
      Value<DateTime?> scheduledDateRangeTo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$PregnancyImmunizationRecordsTableUpdateCompanionBuilder =
    PregnancyImmunizationRecordsCompanion Function({
      Value<String> id,
      Value<String?> pregnancyId,
      Value<String> vaccineName,
      Value<DateTime?> scheduledDate,
      Value<DateTime?> receivedDate,
      Value<bool> required,
      Value<DateTime?> scheduledDateRangeFrom,
      Value<DateTime?> scheduledDateRangeTo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
      Value<int> synced,
      Value<int> rowid,
    });

class $$PregnancyImmunizationRecordsTableFilterComposer
    extends Composer<_$AppDriftDatabase, $PregnancyImmunizationRecordsTable> {
  $$PregnancyImmunizationRecordsTableFilterComposer({
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

  ColumnFilters<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vaccineName => $composableBuilder(
    column: $table.vaccineName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedDate => $composableBuilder(
    column: $table.receivedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get required => $composableBuilder(
    column: $table.required,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDateRangeFrom => $composableBuilder(
    column: $table.scheduledDateRangeFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDateRangeTo => $composableBuilder(
    column: $table.scheduledDateRangeTo,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PregnancyImmunizationRecordsTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $PregnancyImmunizationRecordsTable> {
  $$PregnancyImmunizationRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vaccineName => $composableBuilder(
    column: $table.vaccineName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedDate => $composableBuilder(
    column: $table.receivedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get required => $composableBuilder(
    column: $table.required,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDateRangeFrom => $composableBuilder(
    column: $table.scheduledDateRangeFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDateRangeTo => $composableBuilder(
    column: $table.scheduledDateRangeTo,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PregnancyImmunizationRecordsTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $PregnancyImmunizationRecordsTable> {
  $$PregnancyImmunizationRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vaccineName => $composableBuilder(
    column: $table.vaccineName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get receivedDate => $composableBuilder(
    column: $table.receivedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get required =>
      $composableBuilder(column: $table.required, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDateRangeFrom => $composableBuilder(
    column: $table.scheduledDateRangeFrom,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledDateRangeTo => $composableBuilder(
    column: $table.scheduledDateRangeTo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$PregnancyImmunizationRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $PregnancyImmunizationRecordsTable,
          PregnancyImmunizationRecord,
          $$PregnancyImmunizationRecordsTableFilterComposer,
          $$PregnancyImmunizationRecordsTableOrderingComposer,
          $$PregnancyImmunizationRecordsTableAnnotationComposer,
          $$PregnancyImmunizationRecordsTableCreateCompanionBuilder,
          $$PregnancyImmunizationRecordsTableUpdateCompanionBuilder,
          (
            PregnancyImmunizationRecord,
            BaseReferences<
              _$AppDriftDatabase,
              $PregnancyImmunizationRecordsTable,
              PregnancyImmunizationRecord
            >,
          ),
          PregnancyImmunizationRecord,
          PrefetchHooks Function()
        > {
  $$PregnancyImmunizationRecordsTableTableManager(
    _$AppDriftDatabase db,
    $PregnancyImmunizationRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PregnancyImmunizationRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PregnancyImmunizationRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PregnancyImmunizationRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> pregnancyId = const Value.absent(),
                Value<String> vaccineName = const Value.absent(),
                Value<DateTime?> scheduledDate = const Value.absent(),
                Value<DateTime?> receivedDate = const Value.absent(),
                Value<bool> required = const Value.absent(),
                Value<DateTime?> scheduledDateRangeFrom = const Value.absent(),
                Value<DateTime?> scheduledDateRangeTo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PregnancyImmunizationRecordsCompanion(
                id: id,
                pregnancyId: pregnancyId,
                vaccineName: vaccineName,
                scheduledDate: scheduledDate,
                receivedDate: receivedDate,
                required: required,
                scheduledDateRangeFrom: scheduledDateRangeFrom,
                scheduledDateRangeTo: scheduledDateRangeTo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> pregnancyId = const Value.absent(),
                required String vaccineName,
                Value<DateTime?> scheduledDate = const Value.absent(),
                Value<DateTime?> receivedDate = const Value.absent(),
                Value<bool> required = const Value.absent(),
                Value<DateTime?> scheduledDateRangeFrom = const Value.absent(),
                Value<DateTime?> scheduledDateRangeTo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PregnancyImmunizationRecordsCompanion.insert(
                id: id,
                pregnancyId: pregnancyId,
                vaccineName: vaccineName,
                scheduledDate: scheduledDate,
                receivedDate: receivedDate,
                required: required,
                scheduledDateRangeFrom: scheduledDateRangeFrom,
                scheduledDateRangeTo: scheduledDateRangeTo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
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

typedef $$PregnancyImmunizationRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $PregnancyImmunizationRecordsTable,
      PregnancyImmunizationRecord,
      $$PregnancyImmunizationRecordsTableFilterComposer,
      $$PregnancyImmunizationRecordsTableOrderingComposer,
      $$PregnancyImmunizationRecordsTableAnnotationComposer,
      $$PregnancyImmunizationRecordsTableCreateCompanionBuilder,
      $$PregnancyImmunizationRecordsTableUpdateCompanionBuilder,
      (
        PregnancyImmunizationRecord,
        BaseReferences<
          _$AppDriftDatabase,
          $PregnancyImmunizationRecordsTable,
          PregnancyImmunizationRecord
        >,
      ),
      PregnancyImmunizationRecord,
      PrefetchHooks Function()
    >;
typedef $$PregnancyReportChecklistsTableCreateCompanionBuilder =
    PregnancyReportChecklistsCompanion Function({
      required String id,
      Value<String?> pregnancyId,
      required String reportName,
      Value<DateTime?> expectedDate,
      Value<DateTime?> completedDate,
      Value<String?> reportType,
      Value<bool> required,
      Value<DateTime?> scheduledDateRangeFrom,
      Value<DateTime?> scheduledDateRangeTo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$PregnancyReportChecklistsTableUpdateCompanionBuilder =
    PregnancyReportChecklistsCompanion Function({
      Value<String> id,
      Value<String?> pregnancyId,
      Value<String> reportName,
      Value<DateTime?> expectedDate,
      Value<DateTime?> completedDate,
      Value<String?> reportType,
      Value<bool> required,
      Value<DateTime?> scheduledDateRangeFrom,
      Value<DateTime?> scheduledDateRangeTo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
      Value<int> synced,
      Value<int> rowid,
    });

class $$PregnancyReportChecklistsTableFilterComposer
    extends Composer<_$AppDriftDatabase, $PregnancyReportChecklistsTable> {
  $$PregnancyReportChecklistsTableFilterComposer({
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

  ColumnFilters<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reportName => $composableBuilder(
    column: $table.reportName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expectedDate => $composableBuilder(
    column: $table.expectedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedDate => $composableBuilder(
    column: $table.completedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reportType => $composableBuilder(
    column: $table.reportType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get required => $composableBuilder(
    column: $table.required,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDateRangeFrom => $composableBuilder(
    column: $table.scheduledDateRangeFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDateRangeTo => $composableBuilder(
    column: $table.scheduledDateRangeTo,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PregnancyReportChecklistsTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $PregnancyReportChecklistsTable> {
  $$PregnancyReportChecklistsTableOrderingComposer({
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

  ColumnOrderings<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reportName => $composableBuilder(
    column: $table.reportName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expectedDate => $composableBuilder(
    column: $table.expectedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedDate => $composableBuilder(
    column: $table.completedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reportType => $composableBuilder(
    column: $table.reportType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get required => $composableBuilder(
    column: $table.required,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDateRangeFrom => $composableBuilder(
    column: $table.scheduledDateRangeFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDateRangeTo => $composableBuilder(
    column: $table.scheduledDateRangeTo,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PregnancyReportChecklistsTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $PregnancyReportChecklistsTable> {
  $$PregnancyReportChecklistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reportName => $composableBuilder(
    column: $table.reportName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expectedDate => $composableBuilder(
    column: $table.expectedDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedDate => $composableBuilder(
    column: $table.completedDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reportType => $composableBuilder(
    column: $table.reportType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get required =>
      $composableBuilder(column: $table.required, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDateRangeFrom => $composableBuilder(
    column: $table.scheduledDateRangeFrom,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledDateRangeTo => $composableBuilder(
    column: $table.scheduledDateRangeTo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$PregnancyReportChecklistsTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $PregnancyReportChecklistsTable,
          PregnancyReportChecklist,
          $$PregnancyReportChecklistsTableFilterComposer,
          $$PregnancyReportChecklistsTableOrderingComposer,
          $$PregnancyReportChecklistsTableAnnotationComposer,
          $$PregnancyReportChecklistsTableCreateCompanionBuilder,
          $$PregnancyReportChecklistsTableUpdateCompanionBuilder,
          (
            PregnancyReportChecklist,
            BaseReferences<
              _$AppDriftDatabase,
              $PregnancyReportChecklistsTable,
              PregnancyReportChecklist
            >,
          ),
          PregnancyReportChecklist,
          PrefetchHooks Function()
        > {
  $$PregnancyReportChecklistsTableTableManager(
    _$AppDriftDatabase db,
    $PregnancyReportChecklistsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PregnancyReportChecklistsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PregnancyReportChecklistsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PregnancyReportChecklistsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> pregnancyId = const Value.absent(),
                Value<String> reportName = const Value.absent(),
                Value<DateTime?> expectedDate = const Value.absent(),
                Value<DateTime?> completedDate = const Value.absent(),
                Value<String?> reportType = const Value.absent(),
                Value<bool> required = const Value.absent(),
                Value<DateTime?> scheduledDateRangeFrom = const Value.absent(),
                Value<DateTime?> scheduledDateRangeTo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PregnancyReportChecklistsCompanion(
                id: id,
                pregnancyId: pregnancyId,
                reportName: reportName,
                expectedDate: expectedDate,
                completedDate: completedDate,
                reportType: reportType,
                required: required,
                scheduledDateRangeFrom: scheduledDateRangeFrom,
                scheduledDateRangeTo: scheduledDateRangeTo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> pregnancyId = const Value.absent(),
                required String reportName,
                Value<DateTime?> expectedDate = const Value.absent(),
                Value<DateTime?> completedDate = const Value.absent(),
                Value<String?> reportType = const Value.absent(),
                Value<bool> required = const Value.absent(),
                Value<DateTime?> scheduledDateRangeFrom = const Value.absent(),
                Value<DateTime?> scheduledDateRangeTo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PregnancyReportChecklistsCompanion.insert(
                id: id,
                pregnancyId: pregnancyId,
                reportName: reportName,
                expectedDate: expectedDate,
                completedDate: completedDate,
                reportType: reportType,
                required: required,
                scheduledDateRangeFrom: scheduledDateRangeFrom,
                scheduledDateRangeTo: scheduledDateRangeTo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
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

typedef $$PregnancyReportChecklistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $PregnancyReportChecklistsTable,
      PregnancyReportChecklist,
      $$PregnancyReportChecklistsTableFilterComposer,
      $$PregnancyReportChecklistsTableOrderingComposer,
      $$PregnancyReportChecklistsTableAnnotationComposer,
      $$PregnancyReportChecklistsTableCreateCompanionBuilder,
      $$PregnancyReportChecklistsTableUpdateCompanionBuilder,
      (
        PregnancyReportChecklist,
        BaseReferences<
          _$AppDriftDatabase,
          $PregnancyReportChecklistsTable,
          PregnancyReportChecklist
        >,
      ),
      PregnancyReportChecklist,
      PrefetchHooks Function()
    >;
typedef $$BabiesTableCreateCompanionBuilder =
    BabiesCompanion Function({
      required String id,
      Value<String?> pregnancyId,
      required String name,
      required DateTime deliveryDate,
      required String typeOfDelivery,
      Value<String?> condition,
      Value<String?> gender,
      Value<double?> weight,
      Value<double?> height,
      Value<String?> photo,
      Value<String?> video,
      Value<String?> bloodGroup,
      Value<String?> complications,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$BabiesTableUpdateCompanionBuilder =
    BabiesCompanion Function({
      Value<String> id,
      Value<String?> pregnancyId,
      Value<String> name,
      Value<DateTime> deliveryDate,
      Value<String> typeOfDelivery,
      Value<String?> condition,
      Value<String?> gender,
      Value<double?> weight,
      Value<double?> height,
      Value<String?> photo,
      Value<String?> video,
      Value<String?> bloodGroup,
      Value<String?> complications,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
      Value<int> synced,
      Value<int> rowid,
    });

class $$BabiesTableFilterComposer
    extends Composer<_$AppDriftDatabase, $BabiesTable> {
  $$BabiesTableFilterComposer({
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

  ColumnFilters<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deliveryDate => $composableBuilder(
    column: $table.deliveryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get typeOfDelivery => $composableBuilder(
    column: $table.typeOfDelivery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get video => $composableBuilder(
    column: $table.video,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bloodGroup => $composableBuilder(
    column: $table.bloodGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get complications => $composableBuilder(
    column: $table.complications,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BabiesTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $BabiesTable> {
  $$BabiesTableOrderingComposer({
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

  ColumnOrderings<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deliveryDate => $composableBuilder(
    column: $table.deliveryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typeOfDelivery => $composableBuilder(
    column: $table.typeOfDelivery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get video => $composableBuilder(
    column: $table.video,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bloodGroup => $composableBuilder(
    column: $table.bloodGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get complications => $composableBuilder(
    column: $table.complications,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BabiesTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $BabiesTable> {
  $$BabiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get deliveryDate => $composableBuilder(
    column: $table.deliveryDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get typeOfDelivery => $composableBuilder(
    column: $table.typeOfDelivery,
    builder: (column) => column,
  );

  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get photo =>
      $composableBuilder(column: $table.photo, builder: (column) => column);

  GeneratedColumn<String> get video =>
      $composableBuilder(column: $table.video, builder: (column) => column);

  GeneratedColumn<String> get bloodGroup => $composableBuilder(
    column: $table.bloodGroup,
    builder: (column) => column,
  );

  GeneratedColumn<String> get complications => $composableBuilder(
    column: $table.complications,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$BabiesTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $BabiesTable,
          Baby,
          $$BabiesTableFilterComposer,
          $$BabiesTableOrderingComposer,
          $$BabiesTableAnnotationComposer,
          $$BabiesTableCreateCompanionBuilder,
          $$BabiesTableUpdateCompanionBuilder,
          (Baby, BaseReferences<_$AppDriftDatabase, $BabiesTable, Baby>),
          Baby,
          PrefetchHooks Function()
        > {
  $$BabiesTableTableManager(_$AppDriftDatabase db, $BabiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BabiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BabiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BabiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> pregnancyId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> deliveryDate = const Value.absent(),
                Value<String> typeOfDelivery = const Value.absent(),
                Value<String?> condition = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<double?> height = const Value.absent(),
                Value<String?> photo = const Value.absent(),
                Value<String?> video = const Value.absent(),
                Value<String?> bloodGroup = const Value.absent(),
                Value<String?> complications = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BabiesCompanion(
                id: id,
                pregnancyId: pregnancyId,
                name: name,
                deliveryDate: deliveryDate,
                typeOfDelivery: typeOfDelivery,
                condition: condition,
                gender: gender,
                weight: weight,
                height: height,
                photo: photo,
                video: video,
                bloodGroup: bloodGroup,
                complications: complications,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> pregnancyId = const Value.absent(),
                required String name,
                required DateTime deliveryDate,
                required String typeOfDelivery,
                Value<String?> condition = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<double?> height = const Value.absent(),
                Value<String?> photo = const Value.absent(),
                Value<String?> video = const Value.absent(),
                Value<String?> bloodGroup = const Value.absent(),
                Value<String?> complications = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BabiesCompanion.insert(
                id: id,
                pregnancyId: pregnancyId,
                name: name,
                deliveryDate: deliveryDate,
                typeOfDelivery: typeOfDelivery,
                condition: condition,
                gender: gender,
                weight: weight,
                height: height,
                photo: photo,
                video: video,
                bloodGroup: bloodGroup,
                complications: complications,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
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

typedef $$BabiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $BabiesTable,
      Baby,
      $$BabiesTableFilterComposer,
      $$BabiesTableOrderingComposer,
      $$BabiesTableAnnotationComposer,
      $$BabiesTableCreateCompanionBuilder,
      $$BabiesTableUpdateCompanionBuilder,
      (Baby, BaseReferences<_$AppDriftDatabase, $BabiesTable, Baby>),
      Baby,
      PrefetchHooks Function()
    >;
typedef $$BabyImmunizationRecordsTableCreateCompanionBuilder =
    BabyImmunizationRecordsCompanion Function({
      required String id,
      Value<String?> babyId,
      required String vaccineName,
      Value<DateTime?> scheduledDate,
      Value<DateTime?> receivedDate,
      Value<bool> required,
      Value<DateTime?> scheduledDateRangeFrom,
      Value<DateTime?> scheduledDateRangeTo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$BabyImmunizationRecordsTableUpdateCompanionBuilder =
    BabyImmunizationRecordsCompanion Function({
      Value<String> id,
      Value<String?> babyId,
      Value<String> vaccineName,
      Value<DateTime?> scheduledDate,
      Value<DateTime?> receivedDate,
      Value<bool> required,
      Value<DateTime?> scheduledDateRangeFrom,
      Value<DateTime?> scheduledDateRangeTo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
      Value<int> synced,
      Value<int> rowid,
    });

class $$BabyImmunizationRecordsTableFilterComposer
    extends Composer<_$AppDriftDatabase, $BabyImmunizationRecordsTable> {
  $$BabyImmunizationRecordsTableFilterComposer({
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

  ColumnFilters<String> get babyId => $composableBuilder(
    column: $table.babyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vaccineName => $composableBuilder(
    column: $table.vaccineName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedDate => $composableBuilder(
    column: $table.receivedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get required => $composableBuilder(
    column: $table.required,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDateRangeFrom => $composableBuilder(
    column: $table.scheduledDateRangeFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDateRangeTo => $composableBuilder(
    column: $table.scheduledDateRangeTo,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BabyImmunizationRecordsTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $BabyImmunizationRecordsTable> {
  $$BabyImmunizationRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get babyId => $composableBuilder(
    column: $table.babyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vaccineName => $composableBuilder(
    column: $table.vaccineName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedDate => $composableBuilder(
    column: $table.receivedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get required => $composableBuilder(
    column: $table.required,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDateRangeFrom => $composableBuilder(
    column: $table.scheduledDateRangeFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDateRangeTo => $composableBuilder(
    column: $table.scheduledDateRangeTo,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BabyImmunizationRecordsTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $BabyImmunizationRecordsTable> {
  $$BabyImmunizationRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get babyId =>
      $composableBuilder(column: $table.babyId, builder: (column) => column);

  GeneratedColumn<String> get vaccineName => $composableBuilder(
    column: $table.vaccineName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get receivedDate => $composableBuilder(
    column: $table.receivedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get required =>
      $composableBuilder(column: $table.required, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDateRangeFrom => $composableBuilder(
    column: $table.scheduledDateRangeFrom,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledDateRangeTo => $composableBuilder(
    column: $table.scheduledDateRangeTo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$BabyImmunizationRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $BabyImmunizationRecordsTable,
          BabyImmunizationRecord,
          $$BabyImmunizationRecordsTableFilterComposer,
          $$BabyImmunizationRecordsTableOrderingComposer,
          $$BabyImmunizationRecordsTableAnnotationComposer,
          $$BabyImmunizationRecordsTableCreateCompanionBuilder,
          $$BabyImmunizationRecordsTableUpdateCompanionBuilder,
          (
            BabyImmunizationRecord,
            BaseReferences<
              _$AppDriftDatabase,
              $BabyImmunizationRecordsTable,
              BabyImmunizationRecord
            >,
          ),
          BabyImmunizationRecord,
          PrefetchHooks Function()
        > {
  $$BabyImmunizationRecordsTableTableManager(
    _$AppDriftDatabase db,
    $BabyImmunizationRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BabyImmunizationRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$BabyImmunizationRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BabyImmunizationRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> babyId = const Value.absent(),
                Value<String> vaccineName = const Value.absent(),
                Value<DateTime?> scheduledDate = const Value.absent(),
                Value<DateTime?> receivedDate = const Value.absent(),
                Value<bool> required = const Value.absent(),
                Value<DateTime?> scheduledDateRangeFrom = const Value.absent(),
                Value<DateTime?> scheduledDateRangeTo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BabyImmunizationRecordsCompanion(
                id: id,
                babyId: babyId,
                vaccineName: vaccineName,
                scheduledDate: scheduledDate,
                receivedDate: receivedDate,
                required: required,
                scheduledDateRangeFrom: scheduledDateRangeFrom,
                scheduledDateRangeTo: scheduledDateRangeTo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> babyId = const Value.absent(),
                required String vaccineName,
                Value<DateTime?> scheduledDate = const Value.absent(),
                Value<DateTime?> receivedDate = const Value.absent(),
                Value<bool> required = const Value.absent(),
                Value<DateTime?> scheduledDateRangeFrom = const Value.absent(),
                Value<DateTime?> scheduledDateRangeTo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BabyImmunizationRecordsCompanion.insert(
                id: id,
                babyId: babyId,
                vaccineName: vaccineName,
                scheduledDate: scheduledDate,
                receivedDate: receivedDate,
                required: required,
                scheduledDateRangeFrom: scheduledDateRangeFrom,
                scheduledDateRangeTo: scheduledDateRangeTo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
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

typedef $$BabyImmunizationRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $BabyImmunizationRecordsTable,
      BabyImmunizationRecord,
      $$BabyImmunizationRecordsTableFilterComposer,
      $$BabyImmunizationRecordsTableOrderingComposer,
      $$BabyImmunizationRecordsTableAnnotationComposer,
      $$BabyImmunizationRecordsTableCreateCompanionBuilder,
      $$BabyImmunizationRecordsTableUpdateCompanionBuilder,
      (
        BabyImmunizationRecord,
        BaseReferences<
          _$AppDriftDatabase,
          $BabyImmunizationRecordsTable,
          BabyImmunizationRecord
        >,
      ),
      BabyImmunizationRecord,
      PrefetchHooks Function()
    >;
typedef $$BabyMilestonesTableCreateCompanionBuilder =
    BabyMilestonesCompanion Function({
      Value<int> id,
      Value<String?> babyId,
      Value<DateTime?> expectedDate,
      required String milestone,
      required String description,
      Value<DateTime?> completedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
      Value<int> synced,
    });
typedef $$BabyMilestonesTableUpdateCompanionBuilder =
    BabyMilestonesCompanion Function({
      Value<int> id,
      Value<String?> babyId,
      Value<DateTime?> expectedDate,
      Value<String> milestone,
      Value<String> description,
      Value<DateTime?> completedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
      Value<int> synced,
    });

class $$BabyMilestonesTableFilterComposer
    extends Composer<_$AppDriftDatabase, $BabyMilestonesTable> {
  $$BabyMilestonesTableFilterComposer({
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

  ColumnFilters<String> get babyId => $composableBuilder(
    column: $table.babyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expectedDate => $composableBuilder(
    column: $table.expectedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get milestone => $composableBuilder(
    column: $table.milestone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BabyMilestonesTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $BabyMilestonesTable> {
  $$BabyMilestonesTableOrderingComposer({
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

  ColumnOrderings<String> get babyId => $composableBuilder(
    column: $table.babyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expectedDate => $composableBuilder(
    column: $table.expectedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get milestone => $composableBuilder(
    column: $table.milestone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BabyMilestonesTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $BabyMilestonesTable> {
  $$BabyMilestonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get babyId =>
      $composableBuilder(column: $table.babyId, builder: (column) => column);

  GeneratedColumn<DateTime> get expectedDate => $composableBuilder(
    column: $table.expectedDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get milestone =>
      $composableBuilder(column: $table.milestone, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$BabyMilestonesTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $BabyMilestonesTable,
          BabyMilestone,
          $$BabyMilestonesTableFilterComposer,
          $$BabyMilestonesTableOrderingComposer,
          $$BabyMilestonesTableAnnotationComposer,
          $$BabyMilestonesTableCreateCompanionBuilder,
          $$BabyMilestonesTableUpdateCompanionBuilder,
          (
            BabyMilestone,
            BaseReferences<
              _$AppDriftDatabase,
              $BabyMilestonesTable,
              BabyMilestone
            >,
          ),
          BabyMilestone,
          PrefetchHooks Function()
        > {
  $$BabyMilestonesTableTableManager(
    _$AppDriftDatabase db,
    $BabyMilestonesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BabyMilestonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BabyMilestonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BabyMilestonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> babyId = const Value.absent(),
                Value<DateTime?> expectedDate = const Value.absent(),
                Value<String> milestone = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
              }) => BabyMilestonesCompanion(
                id: id,
                babyId: babyId,
                expectedDate: expectedDate,
                milestone: milestone,
                description: description,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
                synced: synced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> babyId = const Value.absent(),
                Value<DateTime?> expectedDate = const Value.absent(),
                required String milestone,
                required String description,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
              }) => BabyMilestonesCompanion.insert(
                id: id,
                babyId: babyId,
                expectedDate: expectedDate,
                milestone: milestone,
                description: description,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
                synced: synced,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BabyMilestonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $BabyMilestonesTable,
      BabyMilestone,
      $$BabyMilestonesTableFilterComposer,
      $$BabyMilestonesTableOrderingComposer,
      $$BabyMilestonesTableAnnotationComposer,
      $$BabyMilestonesTableCreateCompanionBuilder,
      $$BabyMilestonesTableUpdateCompanionBuilder,
      (
        BabyMilestone,
        BaseReferences<_$AppDriftDatabase, $BabyMilestonesTable, BabyMilestone>,
      ),
      BabyMilestone,
      PrefetchHooks Function()
    >;
typedef $$SyncStatesTableCreateCompanionBuilder =
    SyncStatesCompanion Function({
      required String module,
      Value<DateTime?> syncedAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$SyncStatesTableUpdateCompanionBuilder =
    SyncStatesCompanion Function({
      Value<String> module,
      Value<DateTime?> syncedAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$SyncStatesTableFilterComposer
    extends Composer<_$AppDriftDatabase, $SyncStatesTable> {
  $$SyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStatesTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $SyncStatesTable> {
  $$SyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStatesTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $SyncStatesTable> {
  $$SyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get module =>
      $composableBuilder(column: $table.module, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncStatesTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $SyncStatesTable,
          SyncState,
          $$SyncStatesTableFilterComposer,
          $$SyncStatesTableOrderingComposer,
          $$SyncStatesTableAnnotationComposer,
          $$SyncStatesTableCreateCompanionBuilder,
          $$SyncStatesTableUpdateCompanionBuilder,
          (
            SyncState,
            BaseReferences<_$AppDriftDatabase, $SyncStatesTable, SyncState>,
          ),
          SyncState,
          PrefetchHooks Function()
        > {
  $$SyncStatesTableTableManager(_$AppDriftDatabase db, $SyncStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> module = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatesCompanion(
                module: module,
                syncedAt: syncedAt,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String module,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatesCompanion.insert(
                module: module,
                syncedAt: syncedAt,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $SyncStatesTable,
      SyncState,
      $$SyncStatesTableFilterComposer,
      $$SyncStatesTableOrderingComposer,
      $$SyncStatesTableAnnotationComposer,
      $$SyncStatesTableCreateCompanionBuilder,
      $$SyncStatesTableUpdateCompanionBuilder,
      (
        SyncState,
        BaseReferences<_$AppDriftDatabase, $SyncStatesTable, SyncState>,
      ),
      SyncState,
      PrefetchHooks Function()
    >;
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
typedef $$UserNickNamesTableCreateCompanionBuilder =
    UserNickNamesCompanion Function({
      Value<int> id,
      required String userId,
      required String relatedUserId,
      required String nickName,
      Value<DateTime> createdAt,
      Value<int> synced,
    });
typedef $$UserNickNamesTableUpdateCompanionBuilder =
    UserNickNamesCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> relatedUserId,
      Value<String> nickName,
      Value<DateTime> createdAt,
      Value<int> synced,
    });

class $$UserNickNamesTableFilterComposer
    extends Composer<_$AppDriftDatabase, $UserNickNamesTable> {
  $$UserNickNamesTableFilterComposer({
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

  ColumnFilters<String> get nickName => $composableBuilder(
    column: $table.nickName,
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

class $$UserNickNamesTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $UserNickNamesTable> {
  $$UserNickNamesTableOrderingComposer({
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

  ColumnOrderings<String> get nickName => $composableBuilder(
    column: $table.nickName,
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

class $$UserNickNamesTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $UserNickNamesTable> {
  $$UserNickNamesTableAnnotationComposer({
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

  GeneratedColumn<String> get nickName =>
      $composableBuilder(column: $table.nickName, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$UserNickNamesTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $UserNickNamesTable,
          UserNickName,
          $$UserNickNamesTableFilterComposer,
          $$UserNickNamesTableOrderingComposer,
          $$UserNickNamesTableAnnotationComposer,
          $$UserNickNamesTableCreateCompanionBuilder,
          $$UserNickNamesTableUpdateCompanionBuilder,
          (
            UserNickName,
            BaseReferences<
              _$AppDriftDatabase,
              $UserNickNamesTable,
              UserNickName
            >,
          ),
          UserNickName,
          PrefetchHooks Function()
        > {
  $$UserNickNamesTableTableManager(
    _$AppDriftDatabase db,
    $UserNickNamesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserNickNamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserNickNamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserNickNamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> relatedUserId = const Value.absent(),
                Value<String> nickName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
              }) => UserNickNamesCompanion(
                id: id,
                userId: userId,
                relatedUserId: relatedUserId,
                nickName: nickName,
                createdAt: createdAt,
                synced: synced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String relatedUserId,
                required String nickName,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
              }) => UserNickNamesCompanion.insert(
                id: id,
                userId: userId,
                relatedUserId: relatedUserId,
                nickName: nickName,
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

typedef $$UserNickNamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $UserNickNamesTable,
      UserNickName,
      $$UserNickNamesTableFilterComposer,
      $$UserNickNamesTableOrderingComposer,
      $$UserNickNamesTableAnnotationComposer,
      $$UserNickNamesTableCreateCompanionBuilder,
      $$UserNickNamesTableUpdateCompanionBuilder,
      (
        UserNickName,
        BaseReferences<_$AppDriftDatabase, $UserNickNamesTable, UserNickName>,
      ),
      UserNickName,
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
typedef $$ReportAttachmentsTableCreateCompanionBuilder =
    ReportAttachmentsCompanion Function({
      required String id,
      Value<String?> reportId,
      required String localPath,
      Value<String?> cloudUrl,
      Value<String?> fileName,
      Value<String?> mimeType,
      Value<int?> fileSizeBytes,
      Value<DateTime> createdAt,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$ReportAttachmentsTableUpdateCompanionBuilder =
    ReportAttachmentsCompanion Function({
      Value<String> id,
      Value<String?> reportId,
      Value<String> localPath,
      Value<String?> cloudUrl,
      Value<String?> fileName,
      Value<String?> mimeType,
      Value<int?> fileSizeBytes,
      Value<DateTime> createdAt,
      Value<int> synced,
      Value<int> rowid,
    });

class $$ReportAttachmentsTableFilterComposer
    extends Composer<_$AppDriftDatabase, $ReportAttachmentsTable> {
  $$ReportAttachmentsTableFilterComposer({
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

  ColumnFilters<String> get reportId => $composableBuilder(
    column: $table.reportId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudUrl => $composableBuilder(
    column: $table.cloudUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
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

class $$ReportAttachmentsTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $ReportAttachmentsTable> {
  $$ReportAttachmentsTableOrderingComposer({
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

  ColumnOrderings<String> get reportId => $composableBuilder(
    column: $table.reportId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudUrl => $composableBuilder(
    column: $table.cloudUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
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

class $$ReportAttachmentsTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $ReportAttachmentsTable> {
  $$ReportAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reportId =>
      $composableBuilder(column: $table.reportId, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get cloudUrl =>
      $composableBuilder(column: $table.cloudUrl, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$ReportAttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $ReportAttachmentsTable,
          ReportAttachment,
          $$ReportAttachmentsTableFilterComposer,
          $$ReportAttachmentsTableOrderingComposer,
          $$ReportAttachmentsTableAnnotationComposer,
          $$ReportAttachmentsTableCreateCompanionBuilder,
          $$ReportAttachmentsTableUpdateCompanionBuilder,
          (
            ReportAttachment,
            BaseReferences<
              _$AppDriftDatabase,
              $ReportAttachmentsTable,
              ReportAttachment
            >,
          ),
          ReportAttachment,
          PrefetchHooks Function()
        > {
  $$ReportAttachmentsTableTableManager(
    _$AppDriftDatabase db,
    $ReportAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReportAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReportAttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReportAttachmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> reportId = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<String?> cloudUrl = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<int?> fileSizeBytes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReportAttachmentsCompanion(
                id: id,
                reportId: reportId,
                localPath: localPath,
                cloudUrl: cloudUrl,
                fileName: fileName,
                mimeType: mimeType,
                fileSizeBytes: fileSizeBytes,
                createdAt: createdAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> reportId = const Value.absent(),
                required String localPath,
                Value<String?> cloudUrl = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<int?> fileSizeBytes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReportAttachmentsCompanion.insert(
                id: id,
                reportId: reportId,
                localPath: localPath,
                cloudUrl: cloudUrl,
                fileName: fileName,
                mimeType: mimeType,
                fileSizeBytes: fileSizeBytes,
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

typedef $$ReportAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $ReportAttachmentsTable,
      ReportAttachment,
      $$ReportAttachmentsTableFilterComposer,
      $$ReportAttachmentsTableOrderingComposer,
      $$ReportAttachmentsTableAnnotationComposer,
      $$ReportAttachmentsTableCreateCompanionBuilder,
      $$ReportAttachmentsTableUpdateCompanionBuilder,
      (
        ReportAttachment,
        BaseReferences<
          _$AppDriftDatabase,
          $ReportAttachmentsTable,
          ReportAttachment
        >,
      ),
      ReportAttachment,
      PrefetchHooks Function()
    >;
typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      required String id,
      Value<String?> userId,
      required String title,
      Value<String?> reminderType,
      Value<String> frequency,
      Value<int?> hour,
      Value<int?> minute,
      Value<String?> channels,
      Value<bool> enabled,
      Value<bool> configurable,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<DateTime> createdAt,
      Value<int> synced,
      Value<int> rowid,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String> title,
      Value<String?> reminderType,
      Value<String> frequency,
      Value<int?> hour,
      Value<int?> minute,
      Value<String?> channels,
      Value<bool> enabled,
      Value<bool> configurable,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<DateTime> createdAt,
      Value<int> synced,
      Value<int> rowid,
    });

class $$RemindersTableFilterComposer
    extends Composer<_$AppDriftDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderType => $composableBuilder(
    column: $table.reminderType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channels => $composableBuilder(
    column: $table.channels,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get configurable => $composableBuilder(
    column: $table.configurable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
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

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDriftDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderType => $composableBuilder(
    column: $table.reminderType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channels => $composableBuilder(
    column: $table.channels,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get configurable => $composableBuilder(
    column: $table.configurable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
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

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDriftDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
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

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get reminderType => $composableBuilder(
    column: $table.reminderType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get hour =>
      $composableBuilder(column: $table.hour, builder: (column) => column);

  GeneratedColumn<int> get minute =>
      $composableBuilder(column: $table.minute, builder: (column) => column);

  GeneratedColumn<String> get channels =>
      $composableBuilder(column: $table.channels, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<bool> get configurable => $composableBuilder(
    column: $table.configurable,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDriftDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (
            Reminder,
            BaseReferences<_$AppDriftDatabase, $RemindersTable, Reminder>,
          ),
          Reminder,
          PrefetchHooks Function()
        > {
  $$RemindersTableTableManager(_$AppDriftDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> reminderType = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<int?> hour = const Value.absent(),
                Value<int?> minute = const Value.absent(),
                Value<String?> channels = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> configurable = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                userId: userId,
                title: title,
                reminderType: reminderType,
                frequency: frequency,
                hour: hour,
                minute: minute,
                channels: channels,
                enabled: enabled,
                configurable: configurable,
                startDate: startDate,
                endDate: endDate,
                createdAt: createdAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userId = const Value.absent(),
                required String title,
                Value<String?> reminderType = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<int?> hour = const Value.absent(),
                Value<int?> minute = const Value.absent(),
                Value<String?> channels = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> configurable = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                reminderType: reminderType,
                frequency: frequency,
                hour: hour,
                minute: minute,
                channels: channels,
                enabled: enabled,
                configurable: configurable,
                startDate: startDate,
                endDate: endDate,
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

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDriftDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, BaseReferences<_$AppDriftDatabase, $RemindersTable, Reminder>),
      Reminder,
      PrefetchHooks Function()
    >;

class $AppDriftDatabaseManager {
  final _$AppDriftDatabase _db;
  $AppDriftDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$UserLoginsTableTableTableManager get userLoginsTable =>
      $$UserLoginsTableTableTableManager(_db, _db.userLoginsTable);
  $$HealthDataTableTableTableManager get healthDataTable =>
      $$HealthDataTableTableTableManager(_db, _db.healthDataTable);
  $$VitalsStreamTableTableTableManager get vitalsStreamTable =>
      $$VitalsStreamTableTableTableManager(_db, _db.vitalsStreamTable);
  $$PregnanciesTableTableManager get pregnancies =>
      $$PregnanciesTableTableManager(_db, _db.pregnancies);
  $$AncCheckupDatesTableTableManager get ancCheckupDates =>
      $$AncCheckupDatesTableTableManager(_db, _db.ancCheckupDates);
  $$PregnancyImmunizationRecordsTableTableManager
  get pregnancyImmunizationRecords =>
      $$PregnancyImmunizationRecordsTableTableManager(
        _db,
        _db.pregnancyImmunizationRecords,
      );
  $$PregnancyReportChecklistsTableTableManager get pregnancyReportChecklists =>
      $$PregnancyReportChecklistsTableTableManager(
        _db,
        _db.pregnancyReportChecklists,
      );
  $$BabiesTableTableManager get babies =>
      $$BabiesTableTableManager(_db, _db.babies);
  $$BabyImmunizationRecordsTableTableManager get babyImmunizationRecords =>
      $$BabyImmunizationRecordsTableTableManager(
        _db,
        _db.babyImmunizationRecords,
      );
  $$BabyMilestonesTableTableManager get babyMilestones =>
      $$BabyMilestonesTableTableManager(_db, _db.babyMilestones);
  $$SyncStatesTableTableManager get syncStates =>
      $$SyncStatesTableTableManager(_db, _db.syncStates);
  $$InitialSetupTableTableManager get initialSetup =>
      $$InitialSetupTableTableManager(_db, _db.initialSetup);
  $$UserEntitiesTableTableManager get userEntities =>
      $$UserEntitiesTableTableManager(_db, _db.userEntities);
  $$UserRelationsTableTableManager get userRelations =>
      $$UserRelationsTableTableManager(_db, _db.userRelations);
  $$UserNickNamesTableTableManager get userNickNames =>
      $$UserNickNamesTableTableManager(_db, _db.userNickNames);
  $$FamiliesTableTableManager get families =>
      $$FamiliesTableTableManager(_db, _db.families);
  $$FamilyRequestsTableTableTableManager get familyRequestsTable =>
      $$FamilyRequestsTableTableTableManager(_db, _db.familyRequestsTable);
  $$FamilyMembersTableTableTableManager get familyMembersTable =>
      $$FamilyMembersTableTableTableManager(_db, _db.familyMembersTable);
  $$CycleHistoriesTableTableManager get cycleHistories =>
      $$CycleHistoriesTableTableManager(_db, _db.cycleHistories);
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
  $$ReportAttachmentsTableTableManager get reportAttachments =>
      $$ReportAttachmentsTableTableManager(_db, _db.reportAttachments);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
}
