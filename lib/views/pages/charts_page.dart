import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/account_view_controller.dart';
import 'package:phone_system_app/controllers/client_systems_controller.dart';
import 'package:phone_system_app/controllers/system_types_controller.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/services/analytics_service.dart';
import 'package:phone_system_app/theme/app_colors.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});
  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Analytics Data
  Map<String, dynamic> _clientStats = {};
  Map<String, dynamic> _debtStats = {};
  Map<String, dynamic> _discountStats = {};
  Map<String, dynamic> _subscriptionStats = {};
  List<Map<String, dynamic>> _collectionRates = [];
  List<Map<String, dynamic>> _topSystems = [];
  List<Map<String, dynamic>> _userPerformance = [];
  List<Map<String, dynamic>> _expiringClients = [];
  List<Map<String, dynamic>> _expiringSystems = [];
  List<Map<String, dynamic>> _monthlyComparison = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initControllers();
  }

  Future<void> _initControllers() async {
    Get.put(AccountViewController());
    Get.put(SystemTypeController());
    Get.put(ClientSystemController());
    if (!Get.isRegistered<AccountClientInfo>()) {
      final accountInfo = AccountClientInfo(currentAccount: Account(id: -1));
      Get.put(accountInfo);
      await accountInfo.getAllClients();
    }
    await _loadAnalytics();
    setState(() => _isLoading = false);
  }

  Future<void> _loadAnalytics() async {
    try {
      final results = await Future.wait([
        AnalyticsService.getClientAgeStats(),
        AnalyticsService.getTotalDebts(),
        AnalyticsService.getDiscountStats(),
        AnalyticsService.getSubscriptionDurationStats(),
        AnalyticsService.getCollectionRates(),
        AnalyticsService.getTopSystems(),
        AnalyticsService.getUserPerformance(),
        AnalyticsService.getExpiringClients(),
        AnalyticsService.getExpiringSystems(),
        AnalyticsService.getMonthlyComparison(),
      ]);

      setState(() {
        _clientStats = results[0] as Map<String, dynamic>;
        _debtStats = results[1] as Map<String, dynamic>;
        _discountStats = results[2] as Map<String, dynamic>;
        _subscriptionStats = results[3] as Map<String, dynamic>;
        _collectionRates = results[4] as List<Map<String, dynamic>>;
        _topSystems = results[5] as List<Map<String, dynamic>>;
        _userPerformance = results[6] as List<Map<String, dynamic>>;
        _expiringClients = results[7] as List<Map<String, dynamic>>;
        _expiringSystems = results[8] as List<Map<String, dynamic>>;
        _monthlyComparison = results[9] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.skyGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildFinancialTab(),
                          _buildSystemsTab(),
                          _buildPerformanceTab(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
          const Expanded(
            child: Text('لوحة الإحصائيات المتقدمة',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          IconButton(
              onPressed: () async {
                setState(() => _isLoading = true);
                await _loadAnalytics();
                setState(() => _isLoading = false);
              },
              icon: const Icon(Icons.refresh, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16)),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        labelColor: AppColors.skyDark,
        unselectedLabelColor: Colors.white,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 11),
        tabs: const [
          Tab(icon: Icon(Icons.dashboard, size: 20), text: 'نظرة عامة'),
          Tab(icon: Icon(Icons.attach_money, size: 20), text: 'المالية'),
          Tab(icon: Icon(Icons.subscriptions, size: 20), text: 'الأنظمة'),
          Tab(icon: Icon(Icons.trending_up, size: 20), text: 'الأداء'),
        ],
      ),
    );
  }

  // ==================== Helper Methods ====================
  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    final num = double.tryParse(number.toString()) ?? 0;
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toStringAsFixed(0);
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return date.toString();
    }
  }

  String _getMonthName(dynamic month) {
    final months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    final m = int.tryParse(month.toString()) ?? 0;
    return m > 0 && m <= 12 ? months[m] : '';
  }

  Color _getColorForPercentage(double pct) {
    if (pct >= 80) return const Color(0xFF10B981);
    if (pct >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
    ];
    return colors[index % colors.length];
  }

  // ==================== Reusable Widgets ====================
  Widget _buildKPICard(IconData icon, String title, String value, Color color,
      List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Text(title,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
      String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.skyLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.skyDark, size: 20),
            ),
            const SizedBox(width: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard(int clients, int accounts, int subs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(FontAwesomeIcons.chartSimple,
                color: AppColors.skyDark, size: 20),
            SizedBox(width: 12),
            Text('إحصائيات سريعة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          _buildStatRow(
              'متوسط العملاء لكل حساب',
              accounts > 0
                  ? '${(clients / accounts).toStringAsFixed(1)}'
                  : '0'),
          _buildStatRow('متوسط الاشتراكات لكل عميل',
              clients > 0 ? '${(subs / clients).toStringAsFixed(2)}' : '0'),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildPieChartCard(
      String title, List<String> labels, List<int> values) {
    final total = values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(FontAwesomeIcons.chartPie,
                color: AppColors.skyDark, size: 20),
            const SizedBox(width: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: List.generate(values.length.clamp(0, 6), (i) {
                final pct = (values[i] / total * 100);
                return PieChartSectionData(
                  value: values[i].toDouble(),
                  title: '${pct.toStringAsFixed(0)}%',
                  color: _getColorForIndex(i),
                  radius: 50,
                  titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                );
              }),
            )),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(
                labels.length.clamp(0, 6),
                (i) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                                color: _getColorForIndex(i),
                                borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 6),
                        Text(labels[i], style: const TextStyle(fontSize: 11)),
                      ],
                    )),
          ),
        ],
      ),
    );
  }

  // ==================== تاب نظرة عامة ====================
  Widget _buildOverviewTab() {
    return Obx(() {
      final accounts = AccountViewController.accounts;
      final allClients = AccountClientInfo.allClients;
      final systemTypes = SystemTypeController.types;
      final allTypesId = ClientSystemController.allTypesId;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildMainKPIs(allClients.length, accounts.length, systemTypes.length,
              allTypesId.length),
          const SizedBox(height: 20),
          _buildClientStatsCard(),
          const SizedBox(height: 20),
          _buildExpiringClientsCard(),
          const SizedBox(height: 20),
          _buildQuickStatsCard(
              allClients.length, accounts.length, allTypesId.length),
        ]),
      );
    });
  }

  Widget _buildMainKPIs(int clients, int accounts, int packages, int subs) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildKPICard(
            FontAwesomeIcons.users,
            'إجمالي العملاء',
            clients.toString(),
            const Color(0xFF6366F1),
            const [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
        _buildKPICard(
            FontAwesomeIcons.building,
            'الحسابات',
            accounts.toString(),
            const Color(0xFF10B981),
            const [Color(0xFF10B981), Color(0xFF34D399)]),
        _buildKPICard(
            FontAwesomeIcons.boxOpen,
            'الباقات المتاحة',
            packages.toString(),
            const Color(0xFFF59E0B),
            const [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
        _buildKPICard(
            FontAwesomeIcons.chartLine,
            'الاشتراكات',
            subs.toString(),
            const Color(0xFFEF4444),
            const [Color(0xFFEF4444), Color(0xFFF87171)]),
      ],
    );
  }

  Widget _buildClientStatsCard() {
    return _buildAnalyticsCard(
      'تحليلات العملاء',
      FontAwesomeIcons.userClock,
      [
        _buildStatRow(
            'متوسط عمر العميل', '${_clientStats['avgDays'] ?? 0} يوم'),
        _buildStatRow('أقدم عميل', '${_clientStats['maxDays'] ?? 0} يوم'),
        _buildStatRow('أحدث عميل', '${_clientStats['minDays'] ?? 0} يوم'),
        _buildStatRow('إجمالي العملاء', '${_clientStats['totalClients'] ?? 0}'),
      ],
    );
  }

  Widget _buildExpiringClientsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(FontAwesomeIcons.clockRotateLeft,
                color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
              child: Text('عملاء قريبة من الانتهاء (7 أيام)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.orange, borderRadius: BorderRadius.circular(20)),
            child: Text('${_expiringClients.length}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
        if (_expiringClients.isNotEmpty) ...[
          const SizedBox(height: 16),
          ..._expiringClients.take(5).map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.person_outline,
                      size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(c['name'] ?? '',
                          style: const TextStyle(fontSize: 13))),
                  Text(_formatDate(c['expire_date']),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ]),
              )),
        ],
      ]),
    );
  }

  // ==================== تاب المالية ====================
  Widget _buildFinancialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _buildFinancialKPIs(),
        const SizedBox(height: 20),
        _buildDebtAnalysisCard(),
        const SizedBox(height: 20),
        _buildDiscountStatsCard(),
        const SizedBox(height: 20),
        _buildCollectionRatesCard(),
        const SizedBox(height: 20),
        _buildMonthlyComparisonChart(),
      ]),
    );
  }

  Widget _buildFinancialKPIs() {
    final totalDebt = _debtStats['totalReminder'] ?? 0;
    final paymentRate = _debtStats['paymentRate'] ?? '0';
    final avgDiscount = _discountStats['avgDiscount'] ?? '0';
    final latestGrowth = _monthlyComparison.isNotEmpty
        ? _monthlyComparison.last['growth_rate'] ?? '0'
        : '0';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildKPICard(
            FontAwesomeIcons.moneyBillWave,
            'إجمالي المديونيات',
            '${_formatNumber(totalDebt)} ج.م',
            const Color(0xFFEF4444),
            const [Color(0xFFEF4444), Color(0xFFF87171)]),
        _buildKPICard(
            FontAwesomeIcons.percent,
            'نسبة التحصيل',
            '$paymentRate%',
            const Color(0xFF10B981),
            const [Color(0xFF10B981), Color(0xFF34D399)]),
        _buildKPICard(
            FontAwesomeIcons.tags,
            'متوسط الخصم',
            '$avgDiscount%',
            const Color(0xFFF59E0B),
            const [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
        _buildKPICard(
            FontAwesomeIcons.arrowTrendUp,
            'معدل النمو',
            '$latestGrowth%',
            const Color(0xFF6366F1),
            const [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
      ],
    );
  }

  Widget _buildDebtAnalysisCard() {
    return _buildAnalyticsCard(
      'تحليل المديونيات',
      FontAwesomeIcons.fileInvoiceDollar,
      [
        _buildStatRow('إجمالي الأسعار',
            '${_formatNumber(_debtStats['totalPrice'] ?? 0)} ج.م'),
        _buildStatRow('إجمالي المدفوع',
            '${_formatNumber(_debtStats['totalPaid'] ?? 0)} ج.م'),
        _buildStatRow('المبلغ المتبقي',
            '${_formatNumber(_debtStats['unpaidAmount'] ?? 0)} ج.م'),
        _buildStatRow('نسبة السداد', '${_debtStats['paymentRate'] ?? 0}%'),
      ],
    );
  }

  Widget _buildDiscountStatsCard() {
    return _buildAnalyticsCard(
      'إحصائيات الخصومات',
      FontAwesomeIcons.percent,
      [
        _buildStatRow('متوسط الخصم', '${_discountStats['avgDiscount'] ?? 0}%'),
        _buildStatRow(
            'عملاء لديهم خصم', '${_discountStats['clientsWithDiscount'] ?? 0}'),
        _buildStatRow(
            'إجمالي العملاء', '${_discountStats['totalClients'] ?? 0}'),
        _buildStatRow(
            'نسبة العملاء بخصم', '${_discountStats['discountRate'] ?? 0}%'),
      ],
    );
  }

  Widget _buildCollectionRatesCard() {
    if (_collectionRates.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(FontAwesomeIcons.chartPie, color: AppColors.skyDark, size: 20),
          SizedBox(width: 12),
          Text('نسب التحصيل الشهرية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        ..._collectionRates.take(6).map((rate) {
          final pct =
              double.tryParse(rate['collection_rate']?.toString() ?? '0') ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${_getMonthName(rate['month'])} ${rate['year']}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text('${rate['collection_rate']}%',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _getColorForPercentage(pct)),
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildMonthlyComparisonChart() {
    if (_monthlyComparison.isEmpty) return const SizedBox();
    final data = _monthlyComparison.take(12).toList().reversed.toList();
    final maxIncome = data
        .map((d) => (d['income'] ?? 0).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(FontAwesomeIcons.chartColumn,
              color: AppColors.skyDark, size: 20),
          SizedBox(width: 12),
          Text('مقارنة الإيرادات الشهرية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxIncome * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.skyDark,
                getTooltipItem: (g, gi, r, ri) {
                  final d = data[gi];
                  return BarTooltipItem(
                    '${_getMonthName(d['month'])} ${d['year']}\n${_formatNumber(d['income'])} ج.م\nنمو: ${d['growth_rate'] ?? 0}%',
                    const TextStyle(color: Colors.white, fontSize: 11),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, m) {
                    final i = v.toInt();
                    if (i >= 0 && i < data.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('${data[i]['month']}',
                            style: const TextStyle(fontSize: 10)),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(data.length, (i) {
              final growth =
                  double.tryParse(data[i]['growth_rate']?.toString() ?? '0') ??
                      0;
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: (data[i]['income'] ?? 0).toDouble(),
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: growth >= 0
                        ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                        : [const Color(0xFFEF4444), const Color(0xFFF87171)],
                  ),
                ),
              ]);
            }),
          )),
        ),
      ]),
    );
  }

  // ==================== تاب الأنظمة ====================
  Widget _buildSystemsTab() {
    return Obx(() {
      final systemTypes = SystemTypeController.types;
      final allTypesId = ClientSystemController.allTypesId;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildSystemKPIs(),
          const SizedBox(height: 20),
          _buildSubscriptionStatsCard(),
          const SizedBox(height: 20),
          _buildTopSystemsCard(),
          const SizedBox(height: 20),
          _buildExpiringSystemsCard(),
          const SizedBox(height: 20),
          if (systemTypes.isNotEmpty)
            _buildSystemsPieChart(systemTypes, allTypesId),
        ]),
      );
    });
  }

  Widget _buildSystemKPIs() {
    final avgDays = _subscriptionStats['avgDays'] ?? 0;
    final totalSystems = _subscriptionStats['totalSystems'] ?? 0;
    final expiring = _expiringSystems.length;
    final topCount =
        _topSystems.isNotEmpty ? _topSystems.first['count'] ?? 0 : 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildKPICard(
            FontAwesomeIcons.calendarDays,
            'متوسط مدة الاشتراك',
            '$avgDays يوم',
            const Color(0xFF6366F1),
            const [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
        _buildKPICard(
            FontAwesomeIcons.layerGroup,
            'إجمالي الأنظمة',
            '$totalSystems',
            const Color(0xFF10B981),
            const [Color(0xFF10B981), Color(0xFF34D399)]),
        _buildKPICard(
            FontAwesomeIcons.hourglassEnd,
            'قريبة من الانتهاء',
            '$expiring',
            const Color(0xFFF59E0B),
            const [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
        _buildKPICard(
            FontAwesomeIcons.trophy,
            'أعلى نظام',
            '$topCount اشتراك',
            const Color(0xFFEF4444),
            const [Color(0xFFEF4444), Color(0xFFF87171)]),
      ],
    );
  }

  Widget _buildSubscriptionStatsCard() {
    return _buildAnalyticsCard(
      'إحصائيات الاشتراكات',
      FontAwesomeIcons.chartArea,
      [
        _buildStatRow(
            'متوسط المدة', '${_subscriptionStats['avgDays'] ?? 0} يوم'),
        _buildStatRow(
            'أطول اشتراك', '${_subscriptionStats['maxDays'] ?? 0} يوم'),
        _buildStatRow(
            'أقصر اشتراك', '${_subscriptionStats['minDays'] ?? 0} يوم'),
        _buildStatRow(
            'إجمالي الأنظمة', '${_subscriptionStats['totalSystems'] ?? 0}'),
      ],
    );
  }

  Widget _buildTopSystemsCard() {
    if (_topSystems.isEmpty) return const SizedBox();
    final total =
        _topSystems.fold<int>(0, (sum, s) => sum + (s['count'] as int? ?? 0));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.skyLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(FontAwesomeIcons.rankingStar,
                color: AppColors.skyDark, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('أكثر الأنظمة مبيعاً',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        ..._topSystems.take(5).toList().asMap().entries.map((e) {
          final sys = e.value;
          final pct = total > 0 ? (sys['count'] as int) / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _getColorForIndex(e.key),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                    child: Text('${e.key + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sys['name'] ?? '',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _getColorForIndex(e.key)),
                        ),
                      ),
                    ]),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${sys['count']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${(pct * 100).toStringAsFixed(1)}%',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildExpiringSystemsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(FontAwesomeIcons.triangleExclamation,
                color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
              child: Text('أنظمة قريبة من الانتهاء (7 أيام)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.red, borderRadius: BorderRadius.circular(20)),
            child: Text('${_expiringSystems.length}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
        if (_expiringSystems.isNotEmpty) ...[
          const SizedBox(height: 16),
          ..._expiringSystems.take(5).map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.subscriptions_outlined,
                      size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(s['system_type']?['name'] ?? s['name'] ?? '',
                          style: const TextStyle(fontSize: 13))),
                  Text(_formatDate(s['end_date']),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ]),
              )),
        ],
      ]),
    );
  }

  Widget _buildSystemsPieChart(
      List<SystemType> systemTypes, List<Map<String, dynamic>> allTypesId) {
    final values = systemTypes
        .map((s) => allTypesId
            .where((m) => int.parse(m['type_id'].toString()) == s.id)
            .length)
        .toList();
    final labels = systemTypes.map((s) => s.name ?? '').toList();
    return _buildPieChartCard('توزيع الباقات', labels, values);
  }

  // ==================== تاب الأداء ====================
  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _buildPerformanceKPIs(),
        const SizedBox(height: 20),
        _buildUserPerformanceCard(),
        const SizedBox(height: 20),
        _buildUserPerformanceChart(),
      ]),
    );
  }

  Widget _buildPerformanceKPIs() {
    final totalUsers = _userPerformance.length;
    final totalTransactions = _userPerformance.fold<int>(
        0, (sum, u) => sum + (u['transactions'] as int? ?? 0));
    final avgTransactions =
        totalUsers > 0 ? (totalTransactions / totalUsers).round() : 0;
    final topUser =
        _userPerformance.isNotEmpty ? _userPerformance.first['name'] ?? '' : '';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildKPICard(
            FontAwesomeIcons.userTie,
            'عدد المستخدمين',
            '$totalUsers',
            const Color(0xFF6366F1),
            const [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
        _buildKPICard(
            FontAwesomeIcons.receipt,
            'إجمالي المعاملات',
            '$totalTransactions',
            const Color(0xFF10B981),
            const [Color(0xFF10B981), Color(0xFF34D399)]),
        _buildKPICard(
            FontAwesomeIcons.calculator,
            'متوسط المعاملات',
            '$avgTransactions',
            const Color(0xFFF59E0B),
            const [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
        _buildKPICard(
            FontAwesomeIcons.medal,
            'الأفضل أداءً',
            topUser,
            const Color(0xFFEF4444),
            const [Color(0xFFEF4444), Color(0xFFF87171)]),
      ],
    );
  }

  Widget _buildUserPerformanceCard() {
    if (_userPerformance.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(FontAwesomeIcons.usersGear, color: AppColors.skyDark, size: 20),
          SizedBox(width: 12),
          Text('أداء المستخدمين',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        ..._userPerformance.toList().asMap().entries.map((e) {
          final user = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getColorForIndex(e.key).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _getColorForIndex(e.key).withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: _getColorForIndex(e.key),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                    child: Text('${e.key + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(children: [
                        _buildMiniStat(Icons.receipt_long,
                            '${user['transactions']} معاملة'),
                        const SizedBox(width: 16),
                        _buildMiniStat(Icons.attach_money,
                            '${_formatNumber(user['totalPaid'])} ج.م'),
                      ]),
                    ]),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildUserPerformanceChart() {
    if (_userPerformance.isEmpty) return const SizedBox();
    final maxVal = _userPerformance
        .map((u) => u['transactions'] as int? ?? 0)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(FontAwesomeIcons.chartBar, color: AppColors.skyDark, size: 20),
          SizedBox(width: 12),
          Text('مقارنة أداء المستخدمين',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal.toDouble() * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.skyDark,
                getTooltipItem: (g, gi, r, ri) {
                  final user = _userPerformance[gi];
                  return BarTooltipItem(
                    '${user['name']}\n${user['transactions']} معاملة',
                    const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, m) {
                    final i = v.toInt();
                    if (i >= 0 && i < _userPerformance.length) {
                      final name = _userPerformance[i]['name'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                            name.length > 6
                                ? '${name.substring(0, 6)}..'
                                : name,
                            style: const TextStyle(fontSize: 9)),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(_userPerformance.length, (i) {
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: (_userPerformance[i]['transactions'] ?? 0).toDouble(),
                  width: 20,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      _getColorForIndex(i),
                      _getColorForIndex(i).withValues(alpha: 0.7)
                    ],
                  ),
                ),
              ]);
            }),
          )),
        ),
      ]),
    );
  }
}
