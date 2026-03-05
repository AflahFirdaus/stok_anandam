// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvasing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Canvasing _$CanvasingFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Canvasing',
      json,
      ($checkedConvert) {
        final val = Canvasing(
          id: $checkedConvert('id', (v) => v),
          kategori: $checkedConvert('kategori', (v) => v),
          namaInstansi: $checkedConvert('namaInstansi', (v) => v),
          provinsi: $checkedConvert('provinsi', (v) => v),
          kabupaten: $checkedConvert('kabupaten', (v) => v),
          kecamatan: $checkedConvert('kecamatan', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$CanvasingToJson(Canvasing instance) => <String, dynamic>{
      if (instance.id != null) 'id': instance.id,
      if (instance.kategori != null) 'kategori': instance.kategori,
      if (instance.namaInstansi != null) 'namaInstansi': instance.namaInstansi,
      if (instance.provinsi != null) 'provinsi': instance.provinsi,
      if (instance.kabupaten != null) 'kabupaten': instance.kabupaten,
      if (instance.kecamatan != null) 'kecamatan': instance.kecamatan,
    };
