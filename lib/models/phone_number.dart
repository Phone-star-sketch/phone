import 'package:phone_system_app/models/model.dart';
import 'package:phone_system_app/models/system.dart';

class PhoneNumber extends Model {
  static const String phoneColumnName = "phone_number";

  static const String priceColumnName = "price";
  static const String forSaleColumnName = "for_sale";

  static const String clientIdColumnName = "client_id";
  static const String systemTableName = "system";

  Object? clientId;
  String? phoneNumber;
  bool? forSale;
  double? price;
  List<System>? systems;

  PhoneNumber({
    required super.id,
    super.createdAt,
    this.phoneNumber,
    this.systems,
    this.forSale = false,
    this.price = 0.0,
    this.clientId,
  });

  PhoneNumber.fromJson(super.data)
      : phoneNumber = "${data[phoneColumnName].toString()}",
        clientId = data[clientIdColumnName],
        forSale = data[forSaleColumnName] ?? false,
        price = (data[priceColumnName] != null)
            ? (data[priceColumnName]).toDouble()
            : 0.0,
        systems = (data[systemTableName] != null)
            ? (data[systemTableName] as List)
                .map((e) => System.fromJson(e))
                .toList()
            : [],
        super.fromJson();

  List<System> getExpiredSystems() {
    return systems?.where((system) => system.isExpired()).toList() ?? [];
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      phoneColumnName: phoneNumber,
      clientIdColumnName: clientId,
      forSaleColumnName: forSale,
      priceColumnName: price
    };
  }
}
