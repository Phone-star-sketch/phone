import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:phone_system_app/models/model.dart';

enum TransactionType {
  moneyAdded,
  moneyDeducted,
  transactionDone,
  deposit,
  income,
  expense,
  transfer,
  payment,
  addition,
  debt, // Add this new type for phone purchases
}

extension Printing on TransactionType {
  String name() {
    Map<TransactionType, String> names = {
      TransactionType.moneyAdded: "تم استلام نقدية",
      TransactionType.moneyDeducted: "تمت حذف نقدية",
      TransactionType.transactionDone: "تم دفع حساب الخدمات المقدمة",
    };

    return names[this]!;
  }

  Color color() {
    if (this.index == 0) {
      return Colors.green;
    } else if (this.index == 1) {
      return Colors.blue;
    } else {
      return Colors.blueAccent;
    }
  }

  IconData icon() {
    Map<TransactionType, IconData> icons = {
      TransactionType.moneyAdded: FontAwesomeIcons.moneyBillTransfer,
      TransactionType.moneyDeducted: FontAwesomeIcons.moneyBillTransfer,
      TransactionType.transactionDone: FontAwesomeIcons.moneyBillWave,
    };

    return icons[this]!;
  }
}

class Log extends Model {
  static const priceColumnName = "price";
  static const yearColumnName = "year";
  static const monthColumnName = "month";
  static const paidColumnName = "paid";
  static const reminderColumnName = "reminder";
  static const systemTypeDateColumnName = "system_type";
  static const phoneIdColumnName = "phone_id";
  static const clientIdColumnName = "client_id";
  static const createdByColumnName = "creator";
  static const accountIdColumnName = "account_id";
  static const transactionTypeColumnName = "transaction_type";

  int? year;
  int? month;
  double price;
  double? paid;
  double? reminder;
  String systemType;
  Object? phoneId;
  Object? clientId;
  Object accountId;
  Object? createdBy;
  TransactionType transactionType;

  Log({
    required super.id,
    super.createdAt,
    required this.systemType,
    required this.price,
    this.paid = 0.0,
    this.reminder = 0.0,
    this.year = 0,
    this.month = 0,
    required this.createdBy,
    required this.transactionType,
    required this.clientId,
    required this.phoneId,
    required this.accountId,
  });

  Log.fromJson(super.data)
      : price = data[priceColumnName].toDouble(),
        paid = data[paidColumnName].toDouble(),
        year = data[yearColumnName].toInt(),
        month = data[monthColumnName].toInt(),
        accountId = data[accountIdColumnName],
        reminder = data[reminderColumnName].toDouble(),
        createdBy = data[createdByColumnName],
        transactionType =
            TransactionType.values[data[transactionTypeColumnName] as int],
        systemType = data[systemTypeDateColumnName].toString(),
        phoneId = data[phoneIdColumnName] as Object?,
        clientId = data[clientIdColumnName] as Object?,
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      Log.priceColumnName: price,
      Log.yearColumnName: year ?? 0,
      Log.monthColumnName: month ?? 0,
      Log.paidColumnName: paid,
      Log.accountIdColumnName: accountId,
      Log.reminderColumnName: reminder,
      Log.systemTypeDateColumnName: systemType,
      Log.transactionTypeColumnName: transactionType.index,
      Log.clientIdColumnName: clientId,
      Log.phoneIdColumnName: phoneId,
      Log.createdByColumnName: createdBy
    };
  }
}
