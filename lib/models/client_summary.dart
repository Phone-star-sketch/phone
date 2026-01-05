import 'package:phone_system_app/models/model.dart';

/// Lightweight model for client list display
/// Uses database function for optimized performance
class ClientSummary extends Model {
  static const String nameColumn = "name";
  static const String totalCashColumn = "total_cash";
  static const String expireDateColumn = "expire_date";
  static const String phoneNumbersColumn = "phone_numbers";
  static const String systemNamesColumn = "system_names";
  static const String totalServicesPriceColumn = "total_services_price";
  static const String accountIdColumn = "account_id";

  String? name;
  double? totalCash;
  DateTime? expireDate;
  List<String>? phoneNumbers;
  List<String>? systemNames;
  double? totalServicesPrice;
  int? accountId;

  ClientSummary({
    required super.id,
    super.createdAt,
    this.name,
    this.totalCash,
    this.expireDate,
    this.phoneNumbers,
    this.systemNames,
    this.totalServicesPrice,
    this.accountId,
  });

  ClientSummary.fromJson(super.data)
      : name = data[nameColumn]?.toString(),
        totalCash = (data[totalCashColumn] as num?)?.toDouble(),
        expireDate = data[expireDateColumn] != null
            ? DateTime.parse(data[expireDateColumn].toString())
            : null,
        phoneNumbers = (data[phoneNumbersColumn] as List?)
            ?.map((e) => e.toString())
            .toList(),
        systemNames = (data[systemNamesColumn] as List?)
            ?.map((e) => e.toString())
            .toList(),
        totalServicesPrice =
            (data[totalServicesPriceColumn] as num?)?.toDouble(),
        accountId = data[accountIdColumn] as int?,
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      nameColumn: name,
      totalCashColumn: totalCash,
      expireDateColumn: expireDate?.toIso8601String(),
      phoneNumbersColumn: phoneNumbers,
      systemNamesColumn: systemNames,
      totalServicesPriceColumn: totalServicesPrice,
      accountIdColumn: accountId,
    };
  }

  /// Get first phone number or empty string
  String get firstPhoneNumber =>
      phoneNumbers?.isNotEmpty == true ? phoneNumbers!.first : '';

  /// Get comma-separated system names
  String get systemNamesText =>
      systemNames?.isNotEmpty == true ? systemNames!.join(', ') : '';
}
