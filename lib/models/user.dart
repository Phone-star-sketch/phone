import 'package:phone_system_app/models/model.dart';

class AppUser extends Model {
  static const String uidColumn = "uid";
  static const String nameColumn = "name";
  static const String roleColumn = "role";

  String? uid;
  String? name;
  int? role;

  AppUser({
    required super.id,
    super.createdAt,
    required this.uid,
    required this.name,
    required this.role,
  });

  AppUser.fromJson(super.data)
      : uid = data[uidColumn],
        name = data[nameColumn],
        role = data[roleColumn] as int,
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      uidColumn: uid,
      nameColumn: name,
      roleColumn: role,
    };
  }
}
