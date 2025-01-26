import 'package:phone_system_app/models/model.dart';

class AppUser extends Model {
  static const String uidColumn = "uid";
  static const String nameColumn = "name";
  static const String roleColumn = "role";
  static const String secpassColumn = "secpass";

  String? uid;
  String? name;
  int? role;
  int? secpass;

  AppUser({
    required super.id,
    super.createdAt,
    required this.uid,
    required this.name,
    required this.role,
    this.secpass,
  });

  AppUser.fromJson(super.data)
      : uid = data[uidColumn],
        name = data[nameColumn],
        role = data[roleColumn] as int,
        secpass = data[secpassColumn] as int?,
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      uidColumn: uid,
      nameColumn: name,
      roleColumn: role,
      secpassColumn: secpass,
    };
  }
}
