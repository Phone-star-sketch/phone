abstract class Model {
  static const String idColumnName = "id";
  static const String creationDateColumnName = "created_at";

  Object id;
  DateTime? createdAt;

  Model({required this.id, this.createdAt});

  Model.fromJson(Map<String, dynamic> data)
      : this(
          id: data[idColumnName] as Object,
          createdAt: DateTime.parse(data[creationDateColumnName]),
        );

  Map<String, dynamic> toJson() {
    return {
      idColumnName: id,
      creationDateColumnName:
          (createdAt == null) ? null : createdAt!.toIso8601String()
    };
  }
}
