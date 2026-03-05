//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'canvasing.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Canvasing {
  /// Returns a new [Canvasing] instance.
  Canvasing({

     this.id,

     this.kategori,

     this.namaInstansi,

     this.provinsi,

     this.kabupaten,

     this.kecamatan,
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
    
    name: r'namaInstansi',
    required: false,
    includeIfNull: false
  )


  final Object? namaInstansi;



  @JsonKey(
    
    name: r'provinsi',
    required: false,
    includeIfNull: false
  )


  final Object? provinsi;



  @JsonKey(
    
    name: r'kabupaten',
    required: false,
    includeIfNull: false
  )


  final Object? kabupaten;



  @JsonKey(
    
    name: r'kecamatan',
    required: false,
    includeIfNull: false
  )


  final Object? kecamatan;



  @override
  bool operator ==(Object other) => identical(this, other) || other is Canvasing &&
     other.id == id &&
     other.kategori == kategori &&
     other.namaInstansi == namaInstansi &&
     other.provinsi == provinsi &&
     other.kabupaten == kabupaten &&
     other.kecamatan == kecamatan;

  @override
  int get hashCode =>
    (id == null ? 0 : id.hashCode) +
    (kategori == null ? 0 : kategori.hashCode) +
    (namaInstansi == null ? 0 : namaInstansi.hashCode) +
    (provinsi == null ? 0 : provinsi.hashCode) +
    (kabupaten == null ? 0 : kabupaten.hashCode) +
    (kecamatan == null ? 0 : kecamatan.hashCode);

  factory Canvasing.fromJson(Map<String, dynamic> json) => _$CanvasingFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasingToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

