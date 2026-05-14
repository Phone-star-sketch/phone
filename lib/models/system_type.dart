import 'package:phone_system_app/models/model.dart';

enum SystemCategory {
  mainPackage, // 0 - أنظمة الفليكسات
  dslInternet, // 1 - إنترنت أرضي (ADSL/هوائي)
  mobileInternet, // 2 - إنترنت موبايل
  otherServices, // 3 - خدمات أخرى
}

extension SystemPrinting on SystemCategory {
  String icon() {
    Map<SystemCategory, String> paths = {
      SystemCategory.mainPackage: "assets/images/flex.jpg",
      SystemCategory.dslInternet: "assets/images/dsl_packages.png",
      SystemCategory.mobileInternet: "assets/images/v_logo.jpg",
      SystemCategory.otherServices: "assets/images/v_logo.jpg",
    };

    return paths[this]!;
  }

  String displayName() {
    Map<SystemCategory, String> names = {
      SystemCategory.mainPackage: "أنظمة الفليكسات",
      SystemCategory.dslInternet: "إنترنت أرضي",
      SystemCategory.mobileInternet: "إنترنت موبايل",
      SystemCategory.otherServices: "خدمات أخرى",
    };

    return names[this]!;
  }
}

class SystemType extends Model {
  static const String nameColumnName = "name";
  static const String descriptionColumnName = "description";
  static const String priceColumnName = "price";
  static const String categoryColumnName = "category";
  static const String isRecurringColumnName = "is_recurring";

  String? name;
  String? description;
  double price;
  SystemCategory? category;
  String? image;
  bool isRecurring; // خدمة متكررة شهرياً

  SystemType({
    required super.id,
    super.createdAt,
    this.description,
    this.price = 0.0,
    this.name,
    this.category = SystemCategory.mobileInternet,
    this.image,
    this.isRecurring = true, // القيمة الافتراضية
  });

  SystemType.fromJson(super.data)
      : name = data[nameColumnName].toString(),
        price = data[priceColumnName].toDouble(),
        description = data[descriptionColumnName].toString(),
        category = SystemCategory.values[data[categoryColumnName]],
        image = data['image']?.toString(),
        isRecurring =
            data[isRecurringColumnName] ?? true, // القيمة الافتراضية true
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
      isRecurringColumnName: isRecurring,
    };
  }
}
