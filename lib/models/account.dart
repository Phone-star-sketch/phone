import 'package:phone_system_app/models/model.dart';

class Account extends Model {
  static const String nameColumn = "name";
  static const String dayColumn = "day";

  String? name;
  int day;

  Account({required super.id, super.createdAt, this.name, this.day = 11});

  Account.fromJson(super.data)
      : name = data[nameColumn].toString(),
        day = data[dayColumn],
        super.fromJson();

  factory Account.empty() {
    return Account(
      id: '',
      name: '',
      createdAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {...super.toJson(), nameColumn: name, dayColumn: day};
  }
}
