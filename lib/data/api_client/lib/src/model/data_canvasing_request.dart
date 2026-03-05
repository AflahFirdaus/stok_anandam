//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'data_canvasing_request.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DataCanvasingRequest {
  /// Returns a new [DataCanvasingRequest] instance.
  DataCanvasingRequest({

    required  this.canvasingId,

    required  this.tanggal,

    required  this.canvasVisit,

     this.keterangan,

     this.catatan,
  });

  @JsonKey(
    
    name: r'canvasingId',
    required: true,
    includeIfNull: true
  )


  final Object? canvasingId;



  @JsonKey(
    
    name: r'tanggal',
    required: true,
    includeIfNull: true
  )


  final Object? tanggal;



  @JsonKey(
    
    name: r'canvasVisit',
    required: true,
    includeIfNull: true
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
  bool operator ==(Object other) => identical(this, other) || other is DataCanvasingRequest &&
     other.canvasingId == canvasingId &&
     other.tanggal == tanggal &&
     other.canvasVisit == canvasVisit &&
     other.keterangan == keterangan &&
     other.catatan == catatan;

  @override
  int get hashCode =>
    (canvasingId == null ? 0 : canvasingId.hashCode) +
    (tanggal == null ? 0 : tanggal.hashCode) +
    (canvasVisit == null ? 0 : canvasVisit.hashCode) +
    (keterangan == null ? 0 : keterangan.hashCode) +
    (catatan == null ? 0 : catatan.hashCode);

  factory DataCanvasingRequest.fromJson(Map<String, dynamic> json) => _$DataCanvasingRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DataCanvasingRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

