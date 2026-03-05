// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_canvasing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataCanvasing _$DataCanvasingFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DataCanvasing',
      json,
      ($checkedConvert) {
        final val = DataCanvasing(
          id: $checkedConvert('id', (v) => v),
          canvasing: $checkedConvert(
              'canvasing',
              (v) => v == null
                  ? null
                  : Canvasing.fromJson(v as Map<String, dynamic>)),
          tanggal: $checkedConvert('tanggal', (v) => v),
          canvasVisit: $checkedConvert('canvasVisit', (v) => v),
          keterangan: $checkedConvert('keterangan', (v) => v),
          catatan: $checkedConvert('catatan', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$DataCanvasingToJson(DataCanvasing instance) =>
    <String, dynamic>{
      if (instance.id != null) 'id': instance.id,
      if (instance.canvasing != null) 'canvasing': instance.canvasing!.toJson(),
      if (instance.tanggal != null) 'tanggal': instance.tanggal,
      if (instance.canvasVisit != null) 'canvasVisit': instance.canvasVisit,
      if (instance.keterangan != null) 'keterangan': instance.keterangan,
      if (instance.catatan != null) 'catatan': instance.catatan,
    };
