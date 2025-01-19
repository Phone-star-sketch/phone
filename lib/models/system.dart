import 'package:phone_system_app/models/model.dart';
import 'package:phone_system_app/models/system_type.dart';

class System extends Model {
  static const String startDateColumnName = "start_date";
  static const String endDateColumnName = "end_date";
  static const String phoneColumnName = "phone_id";
  static const String systemColumnName = "name";
  static const String typeColumnName = "type_id";
  static const String typeTableName = "system_type";

  DateTime? startDate;
  DateTime? endDate;
  int? phoneID;
  String? name;
  int? typeId;
  SystemType? type;

  System({
    required super.id,
    super.createdAt,
    this.startDate,
    this.endDate,
    this.phoneID,
    this.type,
    this.typeId,
    this.name,
  });

  System.fromJson(super.data)
      : startDate = DateTime.parse(data[startDateColumnName]),
        endDate = DateTime.parse(data[endDateColumnName]),
        phoneID = data[phoneColumnName],
        name = data[systemColumnName].toString(),
        typeId = data[typeColumnName].toInt(),
        type = SystemType.fromJson(data[typeTableName]),
        super.fromJson();

  bool isExpired() {
    return endDate != null && endDate!.isBefore(DateTime.now());
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      startDateColumnName: startDate!.toIso8601String(),
      endDateColumnName: endDate!.toIso8601String(),
      phoneColumnName: phoneID,
      typeColumnName: typeId,
      systemColumnName: name
    };
  }
}
