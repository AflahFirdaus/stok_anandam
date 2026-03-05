//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:my_api_client/src/model/paging_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'web_response_list_user_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WebResponseListUserResponse {
  /// Returns a new [WebResponseListUserResponse] instance.
  WebResponseListUserResponse({

     this.status,

     this.message,

     this.data,

     this.paging,
  });

  @JsonKey(
    
    name: r'status',
    required: false,
    includeIfNull: false
  )


  final Object? status;



  @JsonKey(
    
    name: r'message',
    required: false,
    includeIfNull: false
  )


  final Object? message;



  @JsonKey(
    
    name: r'data',
    required: false,
    includeIfNull: false
  )


  final Object? data;



  @JsonKey(
    
    name: r'paging',
    required: false,
    includeIfNull: false
  )


  final PagingResponse? paging;



  @override
  bool operator ==(Object other) => identical(this, other) || other is WebResponseListUserResponse &&
     other.status == status &&
     other.message == message &&
     other.data == data &&
     other.paging == paging;

  @override
  int get hashCode =>
    (status == null ? 0 : status.hashCode) +
    (message == null ? 0 : message.hashCode) +
    (data == null ? 0 : data.hashCode) +
    paging.hashCode;

  factory WebResponseListUserResponse.fromJson(Map<String, dynamic> json) => _$WebResponseListUserResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WebResponseListUserResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

