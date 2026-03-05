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
      if (instance.id != null) 'id': instance.id,
      if (instance.nama != null) 'nama': instance.nama,
      if (instance.username != null) 'username': instance.username,
      if (_$UserResponseRoleEnumEnumMap[instance.role] != null)
        'role': _$UserResponseRoleEnumEnumMap[instance.role]!,
      if (instance.active != null) 'active': instance.active,
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
