//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'user_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UserResponse {
  /// Returns a new [UserResponse] instance.
  UserResponse({

     this.id,

     this.nama,

     this.username,

     this.role,
 
     this.active,
  });

  @JsonKey(
    
    name: r'id',
    required: false,
    includeIfNull: false
  )


  final Object? id;



  @JsonKey(
    
    name: r'nama',
    required: false,
    includeIfNull: false
  )


  final Object? nama;



  @JsonKey(
    
    name: r'username',
    required: false,
    includeIfNull: false
  )


  final Object? username;



  @JsonKey(
    
    name: r'role',
    required: false,
    includeIfNull: false
  )


  final UserResponseRoleEnum? role;
 
 
 
   @JsonKey(
     
     name: r'active',
     required: false,
     includeIfNull: false
   )
 
 
   final bool? active;



  @override
  bool operator ==(Object other) => identical(this, other) || other is UserResponse &&
     other.id == id &&
     other.nama == nama &&
     other.username == username &&
     other.role == role &&
     other.active == active;

  @override
  int get hashCode =>
    (id == null ? 0 : id.hashCode) +
    (nama == null ? 0 : nama.hashCode) +
    (username == null ? 0 : username.hashCode) +
    (role == null ? 0 : role.hashCode) +
    (active == null ? 0 : active.hashCode);

  factory UserResponse.fromJson(Map<String, dynamic> json) => _$UserResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum UserResponseRoleEnum {
  @JsonValue('ADMIN')
  ADMIN,
  @JsonValue('SUPERVISOR')
  SUPERVISOR,
  @JsonValue('SPV_MARKETING')
  SPV_MARKETING,
  @JsonValue('MARKETING')
  MARKETING,
  @JsonValue('GUDANG')
  GUDANG,
  @JsonValue('NOTA')
  NOTA,
  @JsonValue('DELIVERY')
  DELIVERY,
  @JsonValue('TEKNISI')
  TEKNISI,
}


