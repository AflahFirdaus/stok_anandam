// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_canvasing_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataCanvasingRequest _$DataCanvasingRequestFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'DataCanvasingRequest',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['canvasingId', 'tanggal', 'canvasVisit'],
        );
        final val = DataCanvasingRequest(
          canvasingId: $checkedConvert('canvasingId', (v) => v),
          tanggal: $checkedConvert('tanggal', (v) => v),
          canvasVisit: $checkedConvert('canvasVisit', (v) => v),
          keterangan: $checkedConvert('keterangan', (v) => v),
          catatan: $checkedConvert('catatan', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$DataCanvasingRequestToJson(
        DataCanvasingRequest instance) =>
    <String, dynamic>{
      'canvasingId': instance.canvasingId,
      'tanggal': instance.tanggal,
      'canvasVisit': instance.canvasVisit,
      if (instance.keterangan != null) 'keterangan': instance.keterangan,
      if (instance.catatan != null) 'catatan': instance.catatan,
    };
