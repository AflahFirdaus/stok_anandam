// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserResponse _$UserResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'UserResponse',
      json,
      ($checkedConvert) {
        final val = UserResponse(
          id: $checkedConvert('id', (v) => v),
          nama: $checkedConvert('nama', (v) => v),
          username: $checkedConvert('username', (v) => v),
          role: $checkedConvert('role',
              (v) => $enumDecodeNullable(_$UserResponseRoleEnumEnumMap, v)),
          active: $checkedConvert('active', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$UserResponseToJson(UserResponse instance) =>
    <String, dynamic>{
      if (instance.id case final value?) 'id': value,
      if (instance.nama case final value?) 'nama': value,
      if (instance.username case final value?) 'username': value,
      if (_$UserResponseRoleEnumEnumMap[instance.role] case final value?)
        'role': value,
      if (instance.active case final value?) 'active': value,
    };

const _$UserResponseRoleEnumEnumMap = {
  UserResponseRoleEnum.ADMIN: 'ADMIN',
  UserResponseRoleEnum.SUPERVISOR: 'SUPERVISOR',
  UserResponseRoleEnum.SPV_MARKETING: 'SPV_MARKETING',
  UserResponseRoleEnum.MARKETING: 'MARKETING',
  UserResponseRoleEnum.GUDANG: 'GUDANG',
  UserResponseRoleEnum.NOTA: 'NOTA',
  UserResponseRoleEnum.DELIVERY: 'DELIVERY',
  UserResponseRoleEnum.TEKNISI: 'TEKNISI',
};
