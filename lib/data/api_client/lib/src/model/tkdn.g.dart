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
          distri: $checkedConvert('distri', (v) => v),
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
      if (instance.id != null) 'id': instance.id,
      if (instance.kategori != null) 'kategori': instance.kategori,
      if (instance.modal != null) 'modal': instance.modal,
      if (instance.dealer != null) 'dealer': instance.dealer,
      if (instance.principal != null) 'principal': instance.principal,
      if (instance.tayang != null) 'tayang': instance.tayang,
      if (instance.sertifikatTkd != null) 'sertifikatTkd': instance.sertifikatTkd,
      if (instance.presentase != null) 'presentase': instance.presentase,
      if (instance.noMerek != null) 'noMerek': instance.noMerek,
      if (instance.nama != null) 'nama': instance.nama,
      if (instance.spesifikasi != null) 'spesifikasi': instance.spesifikasi,
      if (instance.distri != null) 'distri': instance.distri,
      if (instance.processor != null) 'processor': instance.processor,
      if (instance.ram != null) 'ram': instance.ram,
      if (instance.ssd != null) 'ssd': instance.ssd,
      if (instance.hdd != null) 'hdd': instance.hdd,
      if (instance.vga != null) 'vga': instance.vga,
      if (instance.layar != null) 'layar': instance.layar,
      if (instance.os != null) 'os': instance.os,
      if (instance.garansi != null) 'garansi': instance.garansi,
    };
