// @dart=3.5
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'login_user_request.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LoginUserRequest {
  /// Returns a new [LoginUserRequest] instance.
  LoginUserRequest({

    required  this.username,

    required  this.password,
  });

  @JsonKey(
    
    name: r'username',
    required: true,
    includeIfNull: true
  )


  final Object? username;



  @JsonKey(
    
    name: r'password',
    required: true,
    includeIfNull: true
  )


  final Object? password;



  @override
  bool operator ==(Object other) => identical(this, other) || other is LoginUserRequest &&
     other.username == username &&
     other.password == password;

  @override
  int get hashCode =>
    (username == null ? 0 : username.hashCode) +
    (password == null ? 0 : password.hashCode);

  factory LoginUserRequest.fromJson(Map<String, dynamic> json) => _$LoginUserRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginUserRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

