//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'token_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TokenResponse {
  /// Returns a new [TokenResponse] instance.
  TokenResponse({

     this.accessToken,

     this.refreshToken,

     this.type,
  });

  @JsonKey(
    
    name: r'accessToken',
    required: false,
    includeIfNull: false
  )


  final Object? accessToken;



  @JsonKey(
    
    name: r'refreshToken',
    required: false,
    includeIfNull: false
  )


  final Object? refreshToken;



  @JsonKey(
    
    name: r'type',
    required: false,
    includeIfNull: false
  )


  final Object? type;



  @override
  bool operator ==(Object other) => identical(this, other) || other is TokenResponse &&
     other.accessToken == accessToken &&
     other.refreshToken == refreshToken &&
     other.type == type;

  @override
  int get hashCode =>
    (accessToken == null ? 0 : accessToken.hashCode) +
    (refreshToken == null ? 0 : refreshToken.hashCode) +
    (type == null ? 0 : type.hashCode);

  factory TokenResponse.fromJson(Map<String, dynamic> json) => _$TokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TokenResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

