part of 'data_canvasing_request.dart';

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
      if (instance.keterangan case final value?) 'keterangan': value,
      if (instance.catatan case final value?) 'catatan': value,
    };
