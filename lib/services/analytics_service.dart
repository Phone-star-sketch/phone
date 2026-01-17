import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  static final _supabase = Supabase.instance.client;

  // ==================== تحليلات العملاء ====================

  /// متوسط الإنفاق لكل عميل
  static Future<Map<String, dynamic>> getClientSpendingAnalytics() async {
    final result = await _supabase.rpc('get_client_spending_analytics');
    return result ?? {};
  }

  /// العملاء المنتهية اشتراكاتهم
  static Future<List<Map<String, dynamic>>> getExpiredClients() async {
    final now = DateTime.now().toIso8601String();
    final result = await _supabase
        .from('client')
        .select('id, name, expire_date, total_cash')
        .lt('expire_date', now)
        .order('expire_date', ascending: false);
    return List<Map<String, dynamic>>.from(result);
  }

  /// العملاء القريبة من الانتهاء (خلال 7 أيام)
  static Future<List<Map<String, dynamic>>> getExpiringClients(
      {int days = 7}) async {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    final result = await _supabase
        .from('client')
        .select('id, name, expire_date')
        .gte('expire_date', now.toIso8601String())
        .lte('expire_date', future.toIso8601String())
        .order('expire_date');
    return List<Map<String, dynamic>>.from(result);
  }

  /// عمر العملاء (منذ التسجيل)
  static Future<Map<String, dynamic>> getClientAgeStats() async {
    final result = await _supabase.from('client').select('created_at');
    final clients = List<Map<String, dynamic>>.from(result);

    if (clients.isEmpty) return {'avgDays': 0, 'maxDays': 0, 'minDays': 0};

    final now = DateTime.now();
    final ages = clients.map((c) {
      final created = DateTime.parse(c['created_at']);
      return now.difference(created).inDays;
    }).toList();

    return {
      'avgDays': (ages.reduce((a, b) => a + b) / ages.length).round(),
      'maxDays': ages.reduce((a, b) => a > b ? a : b),
      'minDays': ages.reduce((a, b) => a < b ? a : b),
      'totalClients': clients.length,
    };
  }

  // ==================== تحليلات مالية ====================

  /// نسبة التحصيل الفعلي من month_profit
  static Future<List<Map<String, dynamic>>> getCollectionRates() async {
    final result = await _supabase
        .from('month_profit')
        .select('month, year, collected, expected, income, discount, reminder')
        .order('year', ascending: false)
        .order('month', ascending: false);

    return List<Map<String, dynamic>>.from(result).map((row) {
      final expected = (row['expected'] ?? 0).toDouble();
      final collected = (row['collected'] ?? 0).toDouble();
      final rate = expected > 0 ? (collected / expected * 100) : 0.0;
      return {
        ...row,
        'collection_rate': rate.toStringAsFixed(1),
        'net_profit': (row['income'] ?? 0) - (row['discount'] ?? 0),
      };
    }).toList();
  }

  /// إجمالي المديونيات
  static Future<Map<String, dynamic>> getTotalDebts() async {
    final result =
        await _supabase.from('log').select('reminder, price, paid');
    final logs = List<Map<String, dynamic>>.from(result);

    double totalReminder = 0;
    double totalPrice = 0;
    double totalPaid = 0;

    for (var log in logs) {
      totalReminder += (log['reminder'] ?? 0).toDouble();
      totalPrice += (log['price'] ?? 0).toDouble();
      totalPaid += (log['paid'] ?? 0).toDouble();
    }

    return {
      'totalReminder': totalReminder,
      'totalPrice': totalPrice,
      'totalPaid': totalPaid,
      'unpaidAmount': totalPrice - totalPaid,
      'paymentRate':
          totalPrice > 0 ? (totalPaid / totalPrice * 100).toStringAsFixed(1) : '0',
    };
  }

  /// متوسط الخصم للعملاء
  static Future<Map<String, dynamic>> getDiscountStats() async {
    final result = await _supabase
        .from('client')
        .select('discount_percentage, discount_end_date');
    final clients = List<Map<String, dynamic>>.from(result);

    final withDiscount = clients
        .where((c) => c['discount_percentage'] != null && c['discount_percentage'] > 0)
        .toList();

    if (withDiscount.isEmpty) {
      return {'avgDiscount': 0, 'clientsWithDiscount': 0, 'totalClients': clients.length};
    }

    final avgDiscount = withDiscount
            .map((c) => (c['discount_percentage'] as num).toDouble())
            .reduce((a, b) => a + b) /
        withDiscount.length;

    return {
      'avgDiscount': avgDiscount.toStringAsFixed(1),
      'clientsWithDiscount': withDiscount.length,
      'totalClients': clients.length,
      'discountRate': (withDiscount.length / clients.length * 100).toStringAsFixed(1),
    };
  }

  // ==================== تحليلات الأنظمة ====================

  /// أكثر الأنظمة مبيعاً
  static Future<List<Map<String, dynamic>>> getTopSystems() async {
    final systems = await _supabase
        .from('system')
        .select('type_id, system_type(name, price)');
    final systemsList = List<Map<String, dynamic>>.from(systems);

    final Map<int, Map<String, dynamic>> counts = {};
    for (var sys in systemsList) {
      final typeId = sys['type_id'] as int?;
      if (typeId != null) {
        if (!counts.containsKey(typeId)) {
          counts[typeId] = {
            'type_id': typeId,
            'name': sys['system_type']?['name'] ?? 'غير معروف',
            'price': sys['system_type']?['price'] ?? 0,
            'count': 0,
          };
        }
        counts[typeId]!['count'] = (counts[typeId]!['count'] as int) + 1;
      }
    }

    final sorted = counts.values.toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    return sorted.take(10).toList();
  }

  /// متوسط مدة الاشتراك
  static Future<Map<String, dynamic>> getSubscriptionDurationStats() async {
    final result =
        await _supabase.from('system').select('start_date, end_date');
    final systems = List<Map<String, dynamic>>.from(result);

    if (systems.isEmpty) return {'avgDays': 0, 'totalSystems': 0};

    final durations = systems.where((s) => s['start_date'] != null && s['end_date'] != null).map((s) {
      final start = DateTime.parse(s['start_date']);
      final end = DateTime.parse(s['end_date']);
      return end.difference(start).inDays;
    }).toList();

    if (durations.isEmpty) return {'avgDays': 0, 'totalSystems': systems.length};

    return {
      'avgDays': (durations.reduce((a, b) => a + b) / durations.length).round(),
      'maxDays': durations.reduce((a, b) => a > b ? a : b),
      'minDays': durations.reduce((a, b) => a < b ? a : b),
      'totalSystems': systems.length,
    };
  }

  /// الأنظمة القريبة من الانتهاء
  static Future<List<Map<String, dynamic>>> getExpiringSystems({int days = 7}) async {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    final result = await _supabase
        .from('system')
        .select('id, name, end_date, phone_id, system_type(name)')
        .gte('end_date', now.toIso8601String())
        .lte('end_date', future.toIso8601String())
        .order('end_date');
    return List<Map<String, dynamic>>.from(result);
  }

  // ==================== تحليلات الأداء ====================

  /// أداء كل مستخدم (المعاملات)
  static Future<List<Map<String, dynamic>>> getUserPerformance() async {
    final logs = await _supabase
        .from('log')
        .select('creator, price, paid, users(name)');
    final logsList = List<Map<String, dynamic>>.from(logs);

    final Map<int, Map<String, dynamic>> performance = {};
    for (var log in logsList) {
      final creator = log['creator'] as int?;
      if (creator != null) {
        if (!performance.containsKey(creator)) {
          performance[creator] = {
            'creator_id': creator,
            'name': log['users']?['name'] ?? 'غير معروف',
            'transactions': 0,
            'totalPrice': 0.0,
            'totalPaid': 0.0,
          };
        }
        performance[creator]!['transactions'] =
            (performance[creator]!['transactions'] as int) + 1;
        performance[creator]!['totalPrice'] =
            (performance[creator]!['totalPrice'] as double) +
                (log['price'] ?? 0).toDouble();
        performance[creator]!['totalPaid'] =
            (performance[creator]!['totalPaid'] as double) +
                (log['paid'] ?? 0).toDouble();
      }
    }

    final sorted = performance.values.toList()
      ..sort((a, b) =>
          (b['transactions'] as int).compareTo(a['transactions'] as int));

    return sorted;
  }

  /// مقارنة الشهور
  static Future<List<Map<String, dynamic>>> getMonthlyComparison() async {
    final result = await _supabase
        .from('month_profit')
        .select()
        .order('year', ascending: true)
        .order('month', ascending: true);

    final months = List<Map<String, dynamic>>.from(result);

    for (int i = 1; i < months.length; i++) {
      final prev = (months[i - 1]['income'] ?? 0).toDouble();
      final curr = (months[i]['income'] ?? 0).toDouble();
      final growth = prev > 0 ? ((curr - prev) / prev * 100) : 0.0;
      months[i]['growth_rate'] = growth.toStringAsFixed(1);
    }

    if (months.isNotEmpty) months[0]['growth_rate'] = '0';

    return months;
  }

  /// إحصائيات المعاملات حسب الشهر
  static Future<List<Map<String, dynamic>>> getTransactionsByMonth() async {
    final result = await _supabase
        .from('log')
        .select('month, year, price, paid')
        .order('year', ascending: false)
        .order('month', ascending: false);

    final logs = List<Map<String, dynamic>>.from(result);

    final Map<String, Map<String, dynamic>> monthly = {};
    for (var log in logs) {
      final key = '${log['year']}-${log['month']}';
      if (!monthly.containsKey(key)) {
        monthly[key] = {
          'month': log['month'],
          'year': log['year'],
          'count': 0,
          'totalPrice': 0.0,
          'totalPaid': 0.0,
        };
      }
      monthly[key]!['count'] = (monthly[key]!['count'] as int) + 1;
      monthly[key]!['totalPrice'] = (monthly[key]!['totalPrice'] as double) +
          (log['price'] ?? 0).toDouble();
      monthly[key]!['totalPaid'] = (monthly[key]!['totalPaid'] as double) +
          (log['paid'] ?? 0).toDouble();
    }

    return monthly.values.toList();
  }

  // ==================== ملخص شامل ====================

  /// الحصول على ملخص شامل لكل التحليلات
  static Future<Map<String, dynamic>> getFullAnalyticsSummary() async {
    final results = await Future.wait([
      getClientAgeStats(),
      getTotalDebts(),
      getDiscountStats(),
      getSubscriptionDurationStats(),
      getCollectionRates(),
      getTopSystems(),
      getUserPerformance(),
    ]);

    return {
      'clientStats': results[0],
      'debtStats': results[1],
      'discountStats': results[2],
      'subscriptionStats': results[3],
      'collectionRates': results[4],
      'topSystems': results[5],
      'userPerformance': results[6],
    };
  }
}
