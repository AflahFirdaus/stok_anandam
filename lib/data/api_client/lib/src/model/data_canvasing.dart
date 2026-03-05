//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:my_api_client/src/model/canvasing.dart';
import 'package:json_annotation/json_annotation.dart';

part 'data_canvasing.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DataCanvasing {
  /// Returns a new [DataCanvasing] instance.
  DataCanvasing({

     this.id,

     this.canvasing,

     this.tanggal,

     this.canvasVisit,

     this.keterangan,

     this.catatan,
  });

  @JsonKey(
    
    name: r'id',
    required: false,
    includeIfNull: false
  )


  final Object? id;



  @JsonKey(
    
    name: r'canvasing',
    required: false,
    includeIfNull: false
  )


  final Canvasing? canvasing;



  @JsonKey(
    
    name: r'tanggal',
    required: false,
    includeIfNull: false
  )


  final Object? tanggal;



  @JsonKey(
    
    name: r'canvasVisit',
    required: false,
    includeIfNull: false
  )


  final Object? canvasVisit;



  @JsonKey(
    
    name: r'keterangan',
    required: false,
    includeIfNull: false
  )


  final Object? keterangan;



  @JsonKey(
    
    name: r'catatan',
    required: false,
    includeIfNull: false
  )


  final Object? catatan;



  @override
  bool operator ==(Object other) => identical(this, other) || other is DataCanvasing &&
     other.id == id &&
     other.canvasing == canvasing &&
     other.tanggal == tanggal &&
     other.canvasVisit == canvasVisit &&
     other.keterangan == keterangan &&
     other.catatan == catatan;

  @override
  int get hashCode =>
    (id == null ? 0 : id.hashCode) +
    canvasing.hashCode +
    (tanggal == null ? 0 : tanggal.hashCode) +
    (canvasVisit == null ? 0 : canvasVisit.hashCode) +
    (keterangan == null ? 0 : keterangan.hashCode) +
    (catatan == null ? 0 : catatan.hashCode);

  factory DataCanvasing.fromJson(Map<String, dynamic> json) => _$DataCanvasingFromJson(json);

  Map<String, dynamic> toJson() => _$DataCanvasingToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

