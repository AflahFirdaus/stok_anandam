part of 'data_canvasing.dart';


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
      if (instance.id case final value?) 'id': value,
      if (instance.canvasing?.toJson() case final value?) 'canvasing': value,
      if (instance.tanggal case final value?) 'tanggal': value,
      if (instance.canvasVisit case final value?) 'canvasVisit': value,
      if (instance.keterangan case final value?) 'keterangan': value,
      if (instance.catatan case final value?) 'catatan': value,
    };
