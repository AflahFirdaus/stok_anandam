// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRequest _$UserRequestFromJson(Map<String, dynamic> json) => $checkedCreate(
      'UserRequest',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['nama', 'username', 'role'],
        );
        final val = UserRequest(
          nama: $checkedConvert('nama', (v) => v),
          username: $checkedConvert('username', (v) => v),
          password: $checkedConvert('password', (v) => v),
          role: $checkedConvert('role',
              (v) => $enumDecodeNullable(_$UserRequestRoleEnumEnumMap, v)),
        );
        return val;
      },
    );

Map<String, dynamic> _$UserRequestToJson(UserRequest instance) =>
    <String, dynamic>{
      'nama': instance.nama,
      'username': instance.username,
      if (instance.password case final value?) 'password': value,
      'role': _$UserRequestRoleEnumEnumMap[instance.role],
    };

const _$UserRequestRoleEnumEnumMap = {
  UserRequestRoleEnum.ADMIN: 'ADMIN',
  UserRequestRoleEnum.SUPERVISOR: 'SUPERVISOR',
  UserRequestRoleEnum.SPV_MARKETING: 'SPV_MARKETING',
  UserRequestRoleEnum.MARKETING: 'MARKETING',
  UserRequestRoleEnum.GUDANG: 'GUDANG',
  UserRequestRoleEnum.NOTA: 'NOTA',
  UserRequestRoleEnum.DELIVERY: 'DELIVERY',
  UserRequestRoleEnum.TEKNISI: 'TEKNISI',
};
