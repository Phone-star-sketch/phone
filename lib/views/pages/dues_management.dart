import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/views/pages/all_clinets_page.dart'
    as client_page;
import 'package:flutter/animation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:phone_system_app/views/widgets/custom_toolbar.dart';
import 'package:phone_system_app/views/widgets/modern_client_list_view.dart';
import 'package:phone_system_app/views/print_clients_receipts.dart';
import 'package:flutter/services.dart';

class DuesManagement extends StatefulWidget {
  const DuesManagement({super.key});

  @override
  State<DuesManagement> createState() => _DuesManagementState();
}

class _DuesManagementState extends State<DuesManagement>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final controller = Get.find<AccountClientInfo>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      key: const PageStorageKey<String>('duesManagementPage'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFE2E8F0),
          ],
        ),
      ),
      child: Obx(() {
        final q = controller.query.value;
        final filteredData = _getFilteredClients(q);
        final totalCash = _calculateTotalCash(filteredData);

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0), // reduced padding
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.all(6), // reduced from 8
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFEF4444),
                                      Color(0xFFDC2626)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      8), // reduced from 12
                                ),
                                child: const Icon(
                                  FontAwesomeIcons.moneyBillWave,
                                  color: Colors.white,
                                  size: 16, // reduced from 20
                                ),
                              ),
                              const SizedBox(width: 8), // reduced from 12
                              const Expanded(
                                child: Text(
                                  'إدارة المستحقات',
                                  style: TextStyle(
                                    fontSize: 18, // reduced from 22
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12), // reduced from 20
                          // Add Statistics Cards here
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: FontAwesomeIcons.moneyBill,
                                  title: 'إجمالي المستحقات',
                                  value: '${totalCash * -1}',
                                  unit: 'ج.م',
                                  gradient: const [
                                    Color(0xFFEF4444),
                                    Color(0xFFDC2626)
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  icon: FontAwesomeIcons.users,
                                  title: 'عدد العملاء',
                                  value: '${filteredData.length}',
                                  unit: 'عميل',
                                  gradient: const [
                                    Color(0xFF3B82F6),
                                    Color(0xFF1E40AF)
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12), // reduced from 20
                          ModernSearchField(
                            controller: controller.searchController,
                            onChanged: controller.searchQueryChanged,
                          ),
                          const SizedBox(height: 12), // reduced from 16
                          Row(
                            children: [
                              GetBuilder<AccountClientInfo>(
                                builder: (controller) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    child: controller
                                            .enableMulipleClientPrint.value
                                        ? Row(
                                            children: [
                                              _buildActionButton(
                                                icon: Icons.check_circle,
                                                color: const Color(0xFF10B981),
                                                onPressed: () {
                                                  controller
                                                      .enableMulipleClientPrint
                                                      .value = false;
                                                  controller.update();
                                                },
                                                tooltip: 'تأكيد التحديد',
                                              ),
                                              const SizedBox(width: 8),
                                              _buildActionButton(
                                                icon: Icons.cancel,
                                                color: const Color(0xFFEF4444),
                                                onPressed: () {
                                                  controller
                                                      .enableMulipleClientPrint
                                                      .value = false;
                                                  controller.update();
                                                },
                                                tooltip: 'إلغاء التحديد',
                                              ),
                                            ],
                                          )
                                        : _buildActionButton(
                                            icon: Icons.checklist,
                                            color: const Color(0xFF3B82F6),
                                            onPressed: () {
                                              controller.toggleMultiSelection();
                                              controller.update();
                                            },
                                            tooltip: 'تحديد متعدد',
                                          ),
                                  );
                                },
                              ),
                              const Spacer(),
                              _buildActionButton(
                                icon: FontAwesomeIcons.print,
                                color: const Color(0xFF8B5CF6),
                                onPressed: () => _showPrintDialog(context),
                                tooltip: 'طباعة',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ModernClientListView(
                      data: filteredData,
                      isLoading: controller.isLoading.value,
                      query: q,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Extract filtering logic to separate method for better performance
  List<Client> _getFilteredClients(String query) {
    List<Client> clients = controller.clinets.value
        .where((element) => element.totalCash < 0)
        .toList();

    if (query.isEmpty) return clients;

    return clients.where((element) {
      final hasMatchingPhone = element.numbers?.isNotEmpty == true &&
          element.numbers![0].phoneNumber?.contains(query) == true;

      final hasMatchingName = element.name != null &&
          removeSpecialArabicChars(element.name!)
              .contains(removeSpecialArabicChars(query));

      return hasMatchingPhone || hasMatchingName;
    }).toList();
  }

  // Extract calculation to separate method
  num _calculateTotalCash(List<Client> clients) {
    if (clients.isEmpty) return 0;
    return clients
        .map((e) => e.totalCash)
        .reduce((value, element) => value + element);
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPrintDialog(BuildContext context) {
    Get.dialog(
      GetBuilder<AccountClientInfo>(
        builder: (ctrl) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 600,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        FontAwesomeIcons.print,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'قائمة الطباعة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ctrl.clientPrintAdded.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Color(0xFF94A3B8),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'لا توجد عناصر للطباعة',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: ctrl.clientPrintAdded.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final client = ctrl.clientPrintAdded[index];
                            return ModernClientPrintCard(
                              client: client,
                              onRemove: () {
                                ctrl.clientPrintAdded.remove(client);
                                ctrl.update();
                              },
                            );
                          },
                        ),
                ),
                if (ctrl.clientPrintAdded.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${ctrl.clientPrintAdded.length} عنصر محدد للطباعة',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Get.back();
                            Get.to(() => PrintClientsReceipts(
                                  clients: ctrl.clientPrintAdded,
                                ));
                          },
                          child: const Text('طباعة'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(12), // reduced from 16
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradient[0].withOpacity(0.1), gradient[1].withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16), // reduced from 20
        border: Border.all(
          color: gradient[0].withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // reduced from 8
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(8), // reduced from 12
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 14, // reduced from 16
                ),
              ),
              const SizedBox(width: 8), // reduced from 12
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: gradient[0],
                    fontWeight: FontWeight.w500,
                    fontSize: 12, // reduced from 14
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // reduced from 16
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: gradient[0],
                  fontWeight: FontWeight.bold,
                  fontSize: 20, // reduced from 24
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: gradient[0].withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  fontSize: 12, // reduced from 14
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Add this class at the end of the file
class ModernSearchField extends StatelessWidget {
  const ModernSearchField({
    super.key,
    required this.controller,
    this.onChanged,
  });

  final TextEditingController controller;
  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: "ابحث عن عميل (الاسم، رقم الهاتف)",
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              FontAwesomeIcons.magnifyingGlass,
              color: Colors.white,
              size: 18,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class ModernClientPrintCard extends StatelessWidget {
  const ModernClientPrintCard({
    super.key,
    required this.client,
    required this.onRemove,
  });

  final Client client;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      offset: Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[700]!, Colors.blue[900]!],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client.name ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF3B82F6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      size: 14,
                                      color: Color(0xFF3B82F6),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        client.numbers?.isNotEmpty == true
                                            ? (client.numbers![0].phoneNumber ??
                                                'غير متوفر')
                                            : 'غير متوفر',
                                        style: const TextStyle(
                                          color: Color(0xFF3B82F6),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            onRemove();
                            HapticFeedback.mediumImpact();
                          },
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
