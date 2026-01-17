import 'package:phone_system_app/models/model.dart';

class AppUser extends Model {
  static const String uidColumn = "uid";
  static const String nameColumn = "name";
  static const String roleColumn = "role";
  static const String secpassColumn = "secpass";
  static const String avatarUrlColumn = "avatar_url";

  String? uid;
  String? name;
  int? role;
  int? secpass;
  String? avatarUrl;

  AppUser({
    required super.id,
    super.createdAt,
    required this.uid,
    required this.name,
    required this.role,
    this.secpass,
    this.avatarUrl,
  });

  AppUser.fromJson(super.data)
      : uid = data[uidColumn],
        name = data[nameColumn],
        role = data[roleColumn] as int,
        secpass = data[secpassColumn] as int?,
        avatarUrl = data[avatarUrlColumn] as String?,
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      uidColumn: uid,
      nameColumn: name,
      roleColumn: role,
      secpassColumn: secpass,
      avatarUrlColumn: avatarUrl,
    };
  }
}
