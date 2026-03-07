// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tkdn.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Tkdn _$TkdnFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Tkdn',
      json,
      ($checkedConvert) {
        final val = Tkdn(
          id: $checkedConvert('id', (v) => v),
          kategori: $checkedConvert('kategori', (v) => v),
          modal: $checkedConvert('modal', (v) => v),
          dealer: $checkedConvert('dealer', (v) => v),
          principal: $checkedConvert('principal', (v) => v),
          tayang: $checkedConvert('tayang', (v) => v),
          sertifikatTkd: $checkedConvert('sertifikatTkd', (v) => v),
          presentase: $checkedConvert('presentase', (v) => v),
          noMerek: $checkedConvert('noMerek', (v) => v),
          nama: $checkedConvert('nama', (v) => v),
          spesifikasi: $checkedConvert('spesifikasi', (v) => v),
          distri: $checkedConvert('distri', (v) => v as String?),
          processor: $checkedConvert('processor', (v) => v),
          ram: $checkedConvert('ram', (v) => v),
          ssd: $checkedConvert('ssd', (v) => v),
          hdd: $checkedConvert('hdd', (v) => v),
          vga: $checkedConvert('vga', (v) => v),
          layar: $checkedConvert('layar', (v) => v),
          os: $checkedConvert('os', (v) => v),
          garansi: $checkedConvert('garansi', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$TkdnToJson(Tkdn instance) => <String, dynamic>{
      if (instance.id case final value?) 'id': value,
      if (instance.kategori case final value?) 'kategori': value,
      if (instance.modal case final value?) 'modal': value,
      if (instance.dealer case final value?) 'dealer': value,
      if (instance.principal case final value?) 'principal': value,
      if (instance.tayang case final value?) 'tayang': value,
      if (instance.sertifikatTkd case final value?) 'sertifikatTkd': value,
      if (instance.presentase case final value?) 'presentase': value,
      if (instance.noMerek case final value?) 'noMerek': value,
      if (instance.nama case final value?) 'nama': value,
      if (instance.spesifikasi case final value?) 'spesifikasi': value,
      if (instance.distri case final value?) 'distri': value,
      if (instance.processor case final value?) 'processor': value,
      if (instance.ram case final value?) 'ram': value,
      if (instance.ssd case final value?) 'ssd': value,
      if (instance.hdd case final value?) 'hdd': value,
      if (instance.vga case final value?) 'vga': value,
      if (instance.layar case final value?) 'layar': value,
      if (instance.os case final value?) 'os': value,
      if (instance.garansi case final value?) 'garansi': value,
    };
