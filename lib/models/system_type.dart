import 'package:phone_system_app/models/model.dart';

enum SystemCategory {
  mainPackage,
  internetPackage,
  mobileInternet,
}

extension SystemPrinting on SystemCategory {
  String icon() {
    Map<SystemCategory, String> paths = {
      SystemCategory.mainPackage: "assets/images/flex.jpg",
      SystemCategory.internetPackage: "assets/images/dsl_packages.png",
      SystemCategory.mobileInternet: "assets/images/v_logo.jpg",
    };

    return paths[this]!;
  }
}

class SystemType extends Model {
  static const String nameColumnName = "name";
  static const String descriptionColumnName = "description";
  static const String priceColumnName = "price";
  static const String categoryColumnName = "category";

  String? name;
  String? description;
  double price;
  SystemCategory? category;
  String? image;

  SystemType({
    required super.id,
    super.createdAt,
    this.description,
    this.price = 0.0,
    this.name,
    this.category = SystemCategory.mobileInternet,
    this.image,

  });

  SystemType.fromJson(super.data)
      : name = data[nameColumnName].toString(),
        price = data[priceColumnName].toDouble(),
        description = data[descriptionColumnName].toString(),
        category = SystemCategory.values[data[categoryColumnName]],
        image = data['image']?.toString(),
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      nameColumnName: name,
      descriptionColumnName: description,
      priceColumnName: price,
      categoryColumnName: category!.index,
      'image': image,
    };
  }
}
