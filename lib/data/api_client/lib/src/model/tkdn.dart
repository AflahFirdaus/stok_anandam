//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'tkdn.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Tkdn {
  /// Returns a new [Tkdn] instance.
  Tkdn({

     this.id,

     this.kategori,

     this.modal,

     this.dealer,

     this.principal,

     this.tayang,

     this.sertifikatTkd,

     this.presentase,

     this.noMerek,

     this.nama,

     this.spesifikasi,

     this.distri,

     this.processor,

     this.ram,

     this.ssd,

     this.hdd,

     this.vga,

     this.layar,

     this.os,

     this.garansi,
  });

  @JsonKey(
    
    name: r'id',
    required: false,
    includeIfNull: false
  )


  final Object? id;



  @JsonKey(
    
    name: r'kategori',
    required: false,
    includeIfNull: false
  )


  final Object? kategori;



  @JsonKey(
    
    name: r'modal',
    required: false,
    includeIfNull: false
  )


  final Object? modal;



  @JsonKey(
    
    name: r'dealer',
    required: false,
    includeIfNull: false
  )


  final Object? dealer;



  @JsonKey(
    
    name: r'principal',
    required: false,
    includeIfNull: false
  )


  final Object? principal;



  @JsonKey(
    
    name: r'tayang',
    required: false,
    includeIfNull: false
  )


  final Object? tayang;



  @JsonKey(
    
    name: r'sertifikatTkd',
    required: false,
    includeIfNull: false
  )


  final Object? sertifikatTkd;



  @JsonKey(
    
    name: r'presentase',
    required: false,
    includeIfNull: false
  )


  final Object? presentase;



  @JsonKey(
    
    name: r'noMerek',
    required: false,
    includeIfNull: false
  )


  final Object? noMerek;



  @JsonKey(
    
    name: r'nama',
    required: false,
    includeIfNull: false
  )


  final Object? nama;



  @JsonKey(
    
    name: r'spesifikasi',
    required: false,
    includeIfNull: false
  )


  final Object? spesifikasi;



  @JsonKey(
    
    name: r'distri',
    required: false,
    includeIfNull: false
  )


  final Object? distri;



  @JsonKey(
    
    name: r'processor',
    required: false,
    includeIfNull: false
  )


  final Object? processor;



  @JsonKey(
    
    name: r'ram',
    required: false,
    includeIfNull: false
  )


  final Object? ram;



  @JsonKey(
    
    name: r'ssd',
    required: false,
    includeIfNull: false
  )


  final Object? ssd;



  @JsonKey(
    
    name: r'hdd',
    required: false,
    includeIfNull: false
  )


  final Object? hdd;



  @JsonKey(
    
    name: r'vga',
    required: false,
    includeIfNull: false
  )


  final Object? vga;



  @JsonKey(
    
    name: r'layar',
    required: false,
    includeIfNull: false
  )


  final Object? layar;



  @JsonKey(
    
    name: r'os',
    required: false,
    includeIfNull: false
  )


  final Object? os;



  @JsonKey(
    
    name: r'garansi',
    required: false,
    includeIfNull: false
  )


  final Object? garansi;



  @override
  bool operator ==(Object other) => identical(this, other) || other is Tkdn &&
     other.id == id &&
     other.kategori == kategori &&
     other.modal == modal &&
     other.dealer == dealer &&
     other.principal == principal &&
     other.tayang == tayang &&
     other.sertifikatTkd == sertifikatTkd &&
     other.presentase == presentase &&
     other.noMerek == noMerek &&
     other.nama == nama &&
     other.spesifikasi == spesifikasi &&
     other.distri == distri &&
     other.processor == processor &&
     other.ram == ram &&
     other.ssd == ssd &&
     other.hdd == hdd &&
     other.vga == vga &&
     other.layar == layar &&
     other.os == os &&
     other.garansi == garansi;

  @override
  int get hashCode =>
    (id == null ? 0 : id.hashCode) +
    (kategori == null ? 0 : kategori.hashCode) +
    (modal == null ? 0 : modal.hashCode) +
    (dealer == null ? 0 : dealer.hashCode) +
    (principal == null ? 0 : principal.hashCode) +
    (tayang == null ? 0 : tayang.hashCode) +
    (sertifikatTkd == null ? 0 : sertifikatTkd.hashCode) +
    (presentase == null ? 0 : presentase.hashCode) +
    (noMerek == null ? 0 : noMerek.hashCode) +
    (nama == null ? 0 : nama.hashCode) +
    (spesifikasi == null ? 0 : spesifikasi.hashCode) +
    (distri == null ? 0 : distri.hashCode) +
    (processor == null ? 0 : processor.hashCode) +
    (ram == null ? 0 : ram.hashCode) +
    (ssd == null ? 0 : ssd.hashCode) +
    (hdd == null ? 0 : hdd.hashCode) +
    (vga == null ? 0 : vga.hashCode) +
    (layar == null ? 0 : layar.hashCode) +
    (os == null ? 0 : os.hashCode) +
    (garansi == null ? 0 : garansi.hashCode);

  factory Tkdn.fromJson(Map<String, dynamic> json) => _$TkdnFromJson(json);

  Map<String, dynamic> toJson() => _$TkdnToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

