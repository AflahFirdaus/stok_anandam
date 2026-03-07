part of 'canvasing.dart';

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
      if (instance.id case final value?) 'id': value,
      if (instance.kategori case final value?) 'kategori': value,
      if (instance.namaInstansi case final value?) 'namaInstansi': value,
      if (instance.provinsi case final value?) 'provinsi': value,
      if (instance.kabupaten case final value?) 'kabupaten': value,
      if (instance.kecamatan case final value?) 'kecamatan': value,
    };
