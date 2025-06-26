import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart'; // Este arquivo será gerado automaticamente

@JsonSerializable()
class User {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final bool isInTherapy;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.isInTherapy,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}