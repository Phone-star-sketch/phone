import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/models/model.dart';
import 'package:phone_system_app/models/phone_number.dart';
import 'package:phone_system_app/views/pages/system_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Client extends Model {
  static const String nameColumn = "name";
  static const String nationalIdColumn = "national_id";
  static const String accountIdColumn = "account_id";
  static const String phoneNumbersTable = "phone";
  static const String logsTable = "log";
  static const String totalCashColumns = "total_cash";
  static const String addressColumns = "address";
  static const String expireColumns = "expire_date";

  String? nationalId;
  String? name;
  String? address;
  Object? accountId;
  double totalCash;
  List<Log>? logs;
  List<PhoneNumber>? numbers;
  DateTime? expireDate;

  Client(
      {required super.id,
      super.createdAt,
      required this.totalCash,
      this.name,
      this.nationalId,
      this.address,
      this.accountId,
      this.logs,
      this.numbers,
      this.expireDate});

  double systemsCost() {
    if (numbers?.isEmpty ?? true) return 0.0;
    final systems = numbers![0].systems;
    if (systems?.isEmpty ?? true) return 0.0;

    return systems!
        .map((e) => e.type?.price ?? 0.0)
        .reduce((value, element) => value + element)
        .toDouble();
  }

  String systemsFullName() {
    if (numbers?.isEmpty ?? true) return 'لا توجد باقات';
    final systems = numbers![0].systems;
    if (systems?.isEmpty ?? true) return 'لا توجد باقات';

    return systems!
        .map((e) => e.name ?? '')
        .where((name) => name.isNotEmpty)
        .toList()
        .join(" || ");
  }

  Client.fromJson(super.data)
      : nationalId = data[nationalIdColumn].toString(),
        accountId = data[accountIdColumn],
        name = data[nameColumn].toString(),
        address = data[addressColumns].toString(),
        totalCash = (data[totalCashColumns]).toDouble(),
        expireDate = (data[expireColumns] != null)
            ? DateTime.parse(data[expireColumns])
            : null,
        numbers = (data[phoneNumbersTable] != null)
            ? (data[phoneNumbersTable] as List)
                .map((e) => PhoneNumber.fromJson(e))
                .toList()
            : [],
        logs = (data[logsTable] != null)
            ? (data[logsTable] as List).map((e) => Log.fromJson(e)).toList()
            : [],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      nationalIdColumn: nationalId,
      accountIdColumn: accountId,
      nameColumn: name,
      addressColumns: address,
      totalCashColumns: totalCash,
      expireColumns: (expireDate != null) ? expireDate.toString() : null,
    };
  }

  static Future<Map<String, double>> getAccountStats() async {
    final response = await supabase
        .from('clients')
        .select('account_id, accounts!inner(name)')
        .not('account_id', 'is', null);

    final Map<String, double> stats = {};
    final data = response as List;

    for (var row in data) {
      String accountName = row['accounts']['name'].toString();
      stats[accountName] = (stats[accountName] ?? 0) + 1;
    }

    return stats;
  }
}
