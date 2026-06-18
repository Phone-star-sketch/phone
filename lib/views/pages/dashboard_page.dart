import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/views/pages/follow.dart';
import 'package:phone_system_app/views/pages/monthly_invoice_pdf.dart';

// ─── colours ──────────────────────────────────────────────────────────────────
const _kGreen = Color(0xFF10b981);
const _kRed = Color(0xFFff6b6b);
const _kYellow = Color(0xFFfeca57);
const _kBlue = Color(0xFF3b82f6);
const _kPurple = Color(0xFF8b5cf6);
const _kAmber = Color(0xFFf59e0b);
const _kCyan = Color(0xFF06b6d4);
const _kCard = Color(0xFF1a1a1a);

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AccountClientInfo>();
    final profit = ProfitController.to;

    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: _kRed));
      }

      final clients = ctrl.clinets;
      final total = clients.length;
      final paid = clients.where((c) => c.totalCash >= 0).length;
      final unpaid = total - paid;
      final debt = clients.fold<double>(
          0, (s, c) => s + (c.totalCash < 0 ? c.totalCash.abs() : 0));
      final balance = clients.fold<double>(
          0, (s, c) => s + (c.totalCash > 0 ? c.totalCash : 0));

      final top5Debtors = ([...clients]
            ..sort((a, b) => a.totalCash.compareTo(b.totalCash)))
          .take(5)
          .where((c) => c.totalCash < 0)
          .toList();

      final expiredClients = clients
          .where((c) =>
              c.numbers?.any((n) => n.getExpiredSystems().isNotEmpty) ?? false)
          .toList();

      // عملاء قريبين من الانتهاء (خلال 7 أيام)
      final soonExpiring = clients.where((c) {
        if (c.expireDate == null) return false;
        final diff = c.expireDate!.difference(DateTime.now()).inDays;
        return diff >= 0 && diff <= 7;
      }).toList();

      // عملاء بدون أرقام
      final noPhone = clients
          .where((c) => c.numbers == null || c.numbers!.isEmpty)
          .toList();

      final followCtrl = Get.isRegistered<FollowController>()
          ? Get.find<FollowController>()
          : null;
      final monthlyData = _buildMonthlyData(profit);

      // إحصاء أنواع العمليات
      final allLogs = clients.expand((c) => c.logs ?? []).toList();
      final moneyIn = allLogs
          .where((l) => l.transactionType == TransactionType.moneyAdded)
          .fold<double>(0, (s, l) => s + l.price);
      final moneyOut = allLogs
          .where((l) => l.transactionType == TransactionType.moneyDeducted)
          .fold<double>(0, (s, l) => s + l.price);

      return LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ① نظرة عامة ──────────────────────────────────────────────────
              _SectionTitle(
                  title: 'نظرة عامة', subtitle: ctrl.currentAccount.name ?? ''),
              const SizedBox(height: 12),
              _StatsGrid(
                  isWide: isWide,
                  total: total,
                  paid: paid,
                  unpaid: unpaid,
                  debt: debt,
                  balance: balance),
              const SizedBox(height: 20),

              // ② ملخص مالي سريع ─────────────────────────────────────────────
              const _SectionTitle(title: 'الملخص المالي', subtitle: ''),
              const SizedBox(height: 12),
              _FinancialSummary(
                  debt: debt,
                  balance: balance,
                  moneyIn: moneyIn,
                  moneyOut: moneyOut,
                  isWide: isWide),
              const SizedBox(height: 20),

              // ③ شارت + دونات ───────────────────────────────────────────────
              if (isWide)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (monthlyData.isNotEmpty) ...[
                    Expanded(
                        flex: 3,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(
                                  title: 'الأرباح الشهرية', subtitle: ''),
                              const SizedBox(height: 12),
                              _MonthlyProfitChart(data: monthlyData),
                            ])),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                      flex: 2,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionTitle(
                                title: 'نسبة الدفع', subtitle: ''),
                            const SizedBox(height: 12),
                            _PaymentDonut(paid: paid, unpaid: unpaid),
                          ])),
                ])
              else ...[
                if (monthlyData.isNotEmpty) ...[
                  const _SectionTitle(title: 'الأرباح الشهرية', subtitle: ''),
                  const SizedBox(height: 12),
                  _MonthlyProfitChart(data: monthlyData),
                  const SizedBox(height: 20),
                ],
                const _SectionTitle(title: 'نسبة الدفع', subtitle: ''),
                const SizedBox(height: 12),
                _PaymentDonut(paid: paid, unpaid: unpaid),
              ],
              const SizedBox(height: 20),

              // ④ تنبيهات ────────────────────────────────────────────────────
              if (expiredClients.isNotEmpty || soonExpiring.isNotEmpty) ...[
                const _SectionTitle(title: 'التنبيهات', subtitle: ''),
                const SizedBox(height: 12),
                _AlertsSection(
                    expired: expiredClients, soonExpiring: soonExpiring),
                const SizedBox(height: 20),
              ],

              // ⑤ أعلى المديونيات ────────────────────────────────────────────
              if (top5Debtors.isNotEmpty) ...[
                _SectionTitle(
                    title: 'أعلى المديونيات',
                    subtitle:
                        '${clients.where((c) => c.totalCash < 0).length} عميل',
                    badgeColor: _kRed),
                const SizedBox(height: 12),
                _TopDebtorsList(clients: top5Debtors),
                const SizedBox(height: 20),
              ],

              // ⑥ عملاء بدون رقم ─────────────────────────────────────────────
              if (noPhone.isNotEmpty) ...[
                _SectionTitle(
                    title: 'عملاء بدون رقم هاتف',
                    subtitle: '${noPhone.length}',
                    badgeColor: _kAmber),
                const SizedBox(height: 12),
                _SimpleClientList(
                    clients: noPhone.take(5).toList(), color: _kAmber),
                const SizedBox(height: 20),
              ],

              // ⑦ سجل العمليات الكامل ────────────────────────────────────────
              const _SectionTitle(title: 'سجل العمليات', subtitle: ''),
              const SizedBox(height: 12),
              _LastOperationsSection(followCtrl: followCtrl),
              const SizedBox(height: 20),

              // ⑧ زر الفاتورة ────────────────────────────────────────────────
              _InvoiceButton(clients: clients),
              const SizedBox(height: 20),
            ],
          ),
        );
      });
    });
  }

  List<_MonthPoint> _buildMonthlyData(ProfitController profit) {
    const names = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'إبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return profit.profits
        .take(6)
        .map((p) => _MonthPoint(
            label: names[p.month],
            collected: p.totalCollected,
            income: p.totalIncome))
        .toList()
        .reversed
        .toList();
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────
class _MonthPoint {
  final String label;
  final double collected, income;
  const _MonthPoint(
      {required this.label, required this.collected, required this.income});
}

// ── Section Title ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title, subtitle;
  final Color? badgeColor;
  const _SectionTitle(
      {required this.title, required this.subtitle, this.badgeColor});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                    colors: [_kRed, _kYellow],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter))),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: (badgeColor ?? Colors.white).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(subtitle,
                  style: TextStyle(
                      color: badgeColor ?? Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600))),
        ],
      ]);
}

// ── Stats Grid ────────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final bool isWide;
  final int total, paid, unpaid;
  final double debt, balance;
  const _StatsGrid(
      {required this.isWide,
      required this.total,
      required this.paid,
      required this.unpaid,
      required this.debt,
      required this.balance});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SD('إجمالي العملاء', '$total', Icons.people_rounded, _kPurple,
          const Color(0xFF9c8fff)),
      _SD('مدفوعين', '$paid', Icons.check_circle_rounded, _kGreen,
          const Color(0xFF34d399)),
      _SD('غير مدفوعين', '$unpaid', Icons.warning_rounded, _kRed,
          const Color(0xFFfca5a5)),
      _SD('المديونيات', '${debt.toStringAsFixed(0)} ج', Icons.money_off_rounded,
          _kAmber, const Color(0xFFfcd34d)),
      _SD(
          'الرصيد المتاح',
          '${balance.toStringAsFixed(0)} ج',
          Icons.account_balance_wallet_rounded,
          _kCyan,
          const Color(0xFF67e8f9)),
    ];
    if (isWide) {
      return Row(
          children: List.generate(
              cards.length,
              (i) => Expanded(
                  child: Padding(
                      padding:
                          EdgeInsets.only(left: i < cards.length - 1 ? 10 : 0),
                      child: _StatCard(d: cards[i])))));
    }
    return Column(children: [
      Row(children: [
        Expanded(child: _StatCard(d: cards[0])),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(d: cards[1]))
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _StatCard(d: cards[2])),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(d: cards[3]))
      ]),
      const SizedBox(height: 10),
      _StatCard(d: cards[4]),
    ]);
  }
}

class _SD {
  // StatData
  final String label, value;
  final IconData icon;
  final Color color, light;
  const _SD(this.label, this.value, this.icon, this.color, this.light);
}

class _StatCard extends StatelessWidget {
  final _SD d;
  const _StatCard({required this.d});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _kCard,
            border: Border.all(color: d.color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                  color: d.color.withValues(alpha: 0.1),
                  blurRadius: 14,
                  offset: const Offset(0, 5))
            ]),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: d.color.withValues(alpha: 0.15)),
              child: Icon(d.icon, color: d.color, size: 18)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(d.value,
                        style: TextStyle(
                            color: d.light,
                            fontSize: 16,
                            fontWeight: FontWeight.w800))),
                Text(d.label,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ])),
        ]),
      );
}

// ── Financial Summary ─────────────────────────────────────────────────────────
class _FinancialSummary extends StatelessWidget {
  final double debt, balance, moneyIn, moneyOut;
  final bool isWide;
  const _FinancialSummary(
      {required this.debt,
      required this.balance,
      required this.moneyIn,
      required this.moneyOut,
      required this.isWide});

  @override
  Widget build(BuildContext context) {
    final items = [
      _FS('إجمالي الديون', debt, _kRed, Icons.trending_down_rounded),
      _FS('الرصيد الإجمالي', balance, _kGreen, Icons.trending_up_rounded),
      _FS('إجمالي الإيداعات', moneyIn, _kBlue,
          Icons.add_circle_outline_rounded),
      _FS('إجمالي الخصومات', moneyOut, _kAmber,
          Icons.remove_circle_outline_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _kCard,
          border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: isWide
          ? Row(
              children:
                  items.map((e) => Expanded(child: _FSItem(e: e))).toList())
          : Column(children: [
              Row(children: [
                Expanded(child: _FSItem(e: items[0])),
                const SizedBox(width: 12),
                Expanded(child: _FSItem(e: items[1]))
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _FSItem(e: items[2])),
                const SizedBox(width: 12),
                Expanded(child: _FSItem(e: items[3]))
              ]),
            ]),
    );
  }
}

class _FS {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  const _FS(this.label, this.value, this.color, this.icon);
}

class _FSItem extends StatelessWidget {
  final _FS e;
  const _FSItem({required this.e});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(e.icon, color: e.color, size: 14),
          const SizedBox(width: 6),
          Expanded(
              child: Text(e.label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 4),
        Text('${e.value.toStringAsFixed(0)} ج',
            style: TextStyle(
                color: e.color, fontSize: 15, fontWeight: FontWeight.w700)),
      ]);
}

// ── Monthly Chart ─────────────────────────────────────────────────────────────
class _MonthlyProfitChart extends StatelessWidget {
  final List<_MonthPoint> data;
  const _MonthlyProfitChart({required this.data});
  @override
  Widget build(BuildContext context) {
    final maxY = data.fold<double>(
        0, (m, p) => math.max(m, math.max(p.collected, p.income)));
    return Container(
      height: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _kCard,
          border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: BarChart(BarChartData(
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (g, _, rod, ri) => BarTooltipItem(
                    '${ri == 0 ? "محصّل" : "متوقع"}\n${rod.toY.toStringAsFixed(0)} ج',
                    const TextStyle(color: Colors.white, fontSize: 10)))),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(data[v.toInt()].label,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 9))))),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
            getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        barGroups: data
            .asMap()
            .entries
            .map((e) => BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                      toY: e.value.collected,
                      color: _kGreen,
                      width: 9,
                      borderRadius: BorderRadius.circular(4)),
                  BarChartRodData(
                      toY: e.value.income,
                      color: _kRed.withValues(alpha: 0.5),
                      width: 9,
                      borderRadius: BorderRadius.circular(4)),
                ]))
            .toList(),
      )),
    );
  }
}

// ── Payment Donut ─────────────────────────────────────────────────────────────
class _PaymentDonut extends StatelessWidget {
  final int paid, unpaid;
  const _PaymentDonut({required this.paid, required this.unpaid});
  @override
  Widget build(BuildContext context) {
    final total = paid + unpaid;
    if (total == 0) return const SizedBox();
    final pct = (paid / total * 100).toStringAsFixed(1);
    return Container(
      height: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _kCard,
          border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Row(children: [
        Expanded(
            child: PieChart(PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: [
              PieChartSectionData(
                  value: paid.toDouble(),
                  color: _kGreen,
                  radius: 28,
                  showTitle: false),
              PieChartSectionData(
                  value: unpaid.toDouble(),
                  color: _kRed,
                  radius: 28,
                  showTitle: false),
            ]))),
        const SizedBox(width: 12),
        Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$pct%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
              Text('نسبة الدفع',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11)),
              const SizedBox(height: 10),
              _Leg(color: _kGreen, label: 'مدفوع ($paid)'),
              const SizedBox(height: 5),
              _Leg(color: _kRed, label: 'غير مدفوع ($unpaid)'),
            ]),
      ]),
    );
  }
}

class _Leg extends StatelessWidget {
  final Color color;
  final String label;
  const _Leg({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      ]);
}

// ── Alerts Section ────────────────────────────────────────────────────────────
class _AlertsSection extends StatelessWidget {
  final List<Client> expired, soonExpiring;
  const _AlertsSection({required this.expired, required this.soonExpiring});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (expired.isNotEmpty)
        _AlertCard(
          icon: Icons.error_outline_rounded,
          color: _kRed,
          title: 'باقات منتهية',
          count: expired.length,
          clients: expired.take(3).toList(),
          subtitle: (c) =>
              '${c.numbers?.fold<int>(0, (s, n) => s + n.getExpiredSystems().length) ?? 0} باقة منتهية',
        ),
      if (expired.isNotEmpty && soonExpiring.isNotEmpty)
        const SizedBox(height: 10),
      if (soonExpiring.isNotEmpty)
        _AlertCard(
          icon: Icons.schedule_rounded,
          color: _kAmber,
          title: 'تنتهي قريباً (7 أيام)',
          count: soonExpiring.length,
          clients: soonExpiring.take(3).toList(),
          subtitle: (c) => c.expireDate != null
              ? 'ينتهي ${DateFormat('d/M').format(c.expireDate!)}'
              : '',
        ),
    ]);
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final int count;
  final List<Client> clients;
  final String Function(Client) subtitle;
  const _AlertCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.count,
      required this.clients,
      required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _kCard,
            border: Border.all(color: color.withValues(alpha: 0.25))),
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('$count',
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700))),
              ])),
          ...clients.asMap().entries.map((e) {
            final c = e.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05)))),
              child: Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(c.name ?? '—',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                Text(subtitle(c),
                    style: TextStyle(
                        color: color.withValues(alpha: 0.8), fontSize: 11)),
              ]),
            );
          }),
        ]),
      );
}

// ── Top Debtors ───────────────────────────────────────────────────────────────
class _TopDebtorsList extends StatelessWidget {
  final List<Client> clients;
  const _TopDebtorsList({required this.clients});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _kCard,
            border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
        child: Column(
            children: clients.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
                border: i > 0
                    ? Border(
                        top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.05)))
                    : null),
            child: Row(children: [
              Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      gradient: LinearGradient(colors: [
                        _kRed.withValues(alpha: 0.9 - i * 0.12),
                        _kYellow.withValues(alpha: 0.9 - i * 0.12)
                      ])),
                  child: Center(
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11)))),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(c.name ?? '—',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500))),
              Text('${c.totalCash.abs().toStringAsFixed(0)} ج',
                  style: const TextStyle(
                      color: _kRed, fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
          );
        }).toList()),
      );
}

// ── Simple Client List ────────────────────────────────────────────────────────
class _SimpleClientList extends StatelessWidget {
  final List<Client> clients;
  final Color color;
  const _SimpleClientList({required this.clients, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _kCard,
            border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(
            children: clients.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                border: i > 0
                    ? Border(
                        top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.05)))
                    : null),
            child: Row(children: [
              Icon(Icons.person_outline_rounded, color: color, size: 16),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(c.name ?? '—',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13))),
              Text(
                  c.numbers?.isNotEmpty == true
                      ? (c.numbers![0].phoneNumber ?? '—')
                      : 'لا يوجد رقم',
                  style: TextStyle(
                      color: color.withValues(alpha: 0.7), fontSize: 11)),
            ]),
          );
        }).toList()),
      );
}

// ── Last Operations (Full from FollowController) ──────────────────────────────
class _LastOperationsSection extends StatelessWidget {
  final FollowController? followCtrl;
  const _LastOperationsSection({required this.followCtrl});

  @override
  Widget build(BuildContext context) {
    final FollowController ctrl;
    if (followCtrl != null) {
      ctrl = followCtrl!;
    } else if (Get.isRegistered<FollowController>()) {
      ctrl = Get.find<FollowController>();
    } else {
      ctrl = Get.put(FollowController());
    }

    return Obx(() {
      final logs = ctrl.logs;

      // header row مع حالة الاتصال
      final header = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          const Icon(Icons.history_rounded, color: _kBlue, size: 16),
          const SizedBox(width: 8),
          Text('${logs.length} عملية',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          const Spacer(),
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      ctrl.connectionStatus.value == 'متصل' ? _kGreen : _kRed)),
          const SizedBox(width: 6),
          Text(ctrl.connectionStatus.value,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
        ]),
      );

      if (logs.isEmpty) {
        return Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _kCard,
              border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
          child: Column(children: [
            header,
            Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                    child: Text('لا توجد عمليات',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 13)))),
          ]),
        );
      }

      return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _kCard,
            border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
        child: Column(children: [
          header,
          const Divider(height: 1, color: Color(0xFF2a2a2a)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFF222222)),
            itemBuilder: (_, i) {
              final lwu = logs[i];
              final log = lwu.log;
              final typeColor = log.transactionType.color();
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(children: [
                  Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          color: typeColor.withValues(alpha: 0.15)),
                      child: Icon(log.transactionType.icon(),
                          color: typeColor, size: 14)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(lwu.client?.name ?? 'عميل محذوف',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(children: [
                          Text(log.transactionType.name(),
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 10)),
                          if (log.systemType.isNotEmpty) ...[
                            Text(' · ',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 10)),
                            Expanded(
                                child: Text(log.systemType,
                                    style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.35),
                                        fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                          ],
                        ]),
                      ])),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${log.price.toStringAsFixed(0)} ج',
                        style: TextStyle(
                            color: typeColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                        log.createdAt != null
                            ? DateFormat('d/M HH:mm').format(log.createdAt!)
                            : '',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10)),
                  ]),
                ]),
              );
            },
          ),
        ]),
      );
    });
  }
}

// ── Invoice Button ────────────────────────────────────────────────────────────
class _InvoiceButton extends StatelessWidget {
  final List<Client> clients;
  const _InvoiceButton({required this.clients});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Get.to(MonthlyInvoicePdf(clients: clients),
            transition: Transition.downToUp),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [_kRed, _kYellow]),
              boxShadow: [
                BoxShadow(
                    color: _kRed.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
              ]),
          child:
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('طباعة الفاتورة الشهرية',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}
