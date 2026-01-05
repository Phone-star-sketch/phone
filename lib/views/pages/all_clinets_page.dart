import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';
import 'package:phone_system_app/views/print_clients_receipts.dart';
import 'package:flutter/services.dart';
import 'package:phone_system_app/widget_models/clientCreationModelSheet.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';

// Add this extension at the top of the file, after imports
extension ClientPhoneHelper on Client {
  String getFormattedPhoneNumber() {
    if (numbers == null || numbers!.isEmpty) return 'غير متوفر';
    final phoneNumber = numbers![0].phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) return 'غير متوفر';
    return phoneNumber;
  }
}

class AllClientsPage extends StatefulWidget {
  const AllClientsPage({super.key});

  @override
  _AllClientsPageState createState() => _AllClientsPageState();
}

class _AllClientsPageState extends State<AllClientsPage>
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

  List<Client> _getSmartFilteredClients(String query) {
    // Use optimized search from controller
    return controller.searchClients(query);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      key: const PageStorageKey<String>('allClientsPage'),
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
      child: GetBuilder<AccountClientInfo>(
        id: 'client-list',
        builder: (ctrl) {
          final q = ctrl.query.value;
          final filteredData = _getSmartFilteredClients(q);
          final isLoading = ctrl.isLoading.value;
          final printingClients = ctrl.clientPrintAdded;

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Modern Header with Glass Effect
                  GetBuilder<AccountClientInfo>(
                    id: 'toolbar',
                    builder: (toolbarCtrl) => Container(
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
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              // Page Title
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF3B82F6),
                                          Color(0xFF1E40AF)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      FontAwesomeIcons.users,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'إدارة العملاء',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Client Count Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF10B981),
                                          Color(0xFF059669)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      q.isEmpty
                                          ? '${ctrl.totalClientsCount} عميل (عرض ${filteredData.length})'
                                          : '${filteredData.length} نتيجة',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Custom Toolbar
                              ModernToolBar(
                                controller: toolbarCtrl,
                                printingClients: printingClients,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Content Area
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: (isLoading)
                          ? const SoundWaveIndicator()
                          : (Loaders.to.paymentIsLoading.value)
                              ? ModernPaymentLoadingWidget()
                              : ModernClientListView(
                                  data: filteredData,
                                  isLoading: isLoading,
                                  query: ctrl.query.value,
                                ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ModernToolBar extends StatelessWidget {
  const ModernToolBar({
    super.key,
    required this.controller,
    required this.printingClients,
  });

  final AccountClientInfo controller;
  final List<Client> printingClients;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModernSearchField(
          controller: controller.searchController,
          onChanged: controller.searchQueryChanged,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Multi-select Toggle
            GetBuilder<AccountClientInfo>(
              builder: (controller) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: controller.enableMulipleClientPrint.value
                      ? Row(
                          children: [
                            _buildActionButton(
                              icon: Icons.check_circle,
                              color: const Color(0xFF10B981),
                              onPressed: () {
                                controller.enableMulipleClientPrint.value =
                                    false;
                                controller.update();
                              },
                              tooltip: 'تأكيد التحديد',
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.cancel,
                              color: const Color(0xFFEF4444),
                              onPressed: () {
                                controller.enableMulipleClientPrint.value =
                                    false;
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
            // Add User Button
            _buildActionButton(
              icon: Icons.person_add,
              color: const Color(0xFF10B981),
              onPressed: () => clientEditModelSheet(context),
              tooltip: 'إضافة عميل',
            ),
            const SizedBox(width: 8),
            // Print Button
            _buildActionButton(
              icon: FontAwesomeIcons.print,
              color: const Color(0xFF8B5CF6),
              onPressed: () => _showPrintDialog(context),
              tooltip: 'طباعة',
            ),
          ],
        ),
      ],
    );
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
        ));
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
                // Header
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
                        onPressed: () {
                          Navigator.of(context).pop(); // Replace Get.back()
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
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
                // Footer
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
                            Get.to(PrintClientsReceipts(
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
                // Selection Indicator
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
                        // Avatar
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
                        // Client Info
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
                                        client.getFormattedPhoneNumber(),
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
                        // Remove Button with animation
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

class ModernClientListView extends StatefulWidget {
  const ModernClientListView({
    super.key,
    required this.data,
    required this.isLoading,
    required this.query,
  });

  final List<Client> data;
  final bool isLoading;
  final String query;

  @override
  State<ModernClientListView> createState() => _ModernClientListViewState();
}

class _ModernClientListViewState extends State<ModernClientListView> {
  final ScrollController _scrollController = ScrollController();
  final controller = Get.find<AccountClientInfo>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when reaching 80% of scroll
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Only load more when not searching
      if (widget.query.isEmpty && controller.hasMoreData) {
        controller.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد نتائج',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final hasMore = controller.hasMoreData && widget.query.isEmpty;

    return ListView.separated(
      controller: _scrollController,
      itemCount: widget.data.length + (hasMore ? 1 : 0),
      physics: const BouncingScrollPhysics(),
      cacheExtent: 500,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        // Show loading indicator at the end
        if (index == widget.data.length) {
          return _buildLoadMoreButton();
        }

        return RepaintBoundary(
          child: ModernClientCard(
            client: widget.data[index],
            index: index,
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreButton() {
    return Obx(() {
      if (controller.isLoadingMore.value) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'جاري تحميل المزيد...',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Show "load more" button
      return GestureDetector(
        onTap: () => controller.loadMore(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'تحميل المزيد (${controller.totalClientsCount - widget.data.length} متبقي)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class ModernClientCard extends StatelessWidget {
  const ModernClientCard({
    super.key,
    required this.client,
    required this.index,
  });

  final Client client;
  final int index;

  // Cached colors to avoid recalculation
  static final List<Color> _baseColors = [
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF10B981), // Green
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFF59E0B), // Orange
    const Color(0xFFEF4444), // Red
  ];

  Color _getBaseColor(int index) {
    return _baseColors[index % _baseColors.length];
  }

  List<Color> _getGradientColors(int index) {
    final baseColor = _getBaseColor(index);
    return [
      baseColor,
      baseColor.withValues(alpha: 0.7),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AccountClientInfo>(
      id: 'client-${client.id}',
      builder: (accountController) {
        final isSelected = accountController.clientPrintAdded.contains(client);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
            border: Border.all(
              color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                    : Colors.black.withOpacity(0.06),
                blurRadius: isSelected ? 20 : 15,
                offset: const Offset(0, 4),
                spreadRadius: isSelected ? 2 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Subtle Background Pattern
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _getBaseColor(index).withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Main Content
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () =>
                        accountController.enableMulipleClientPrint.value
                            ? _handleSelection(accountController)
                            : _handleTap(context, accountController),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Section: Avatar + Name + Phone
                          Row(
                            children: [
                              // Modern Avatar
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: _getGradientColors(index),
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getBaseColor(index)
                                          .withOpacity(0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Client Name & Phone
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      client.name ?? 'غير محدد',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF1E293B),
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    // Phone Number
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.phone_rounded,
                                          size: 13,
                                          color: Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            client.getFormattedPhoneNumber(),
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Divider
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFE2E8F0),
                            ),
                          ),

                          // Bottom Section: Money Status + Action Buttons
                          Row(
                            children: [
                              // Money Status (Compact)
                              Expanded(
                                child: _buildCompactMoneyStatus(),
                              ),
                              const SizedBox(width: 12),

                              // Action Buttons Row
                              Row(
                                children: [
                                  // Copy Button
                                  _buildCompactActionButton(
                                    icon: Icons.content_copy_rounded,
                                    color: const Color(0xFF10B981),
                                    onPressed: () {
                                      final phoneNumber =
                                          client.getFormattedPhoneNumber();
                                      if (phoneNumber != 'غير متوفر') {
                                        Clipboard.setData(
                                            ClipboardData(text: phoneNumber));
                                        HapticFeedback.mediumImpact();
                                        _showSuccessSnackbar(
                                            'تم نسخ رقم الهاتف');
                                      }
                                    },
                                    tooltip: 'نسخ',
                                  ),
                                  const SizedBox(width: 6),
                                  // Edit Button
                                  _buildCompactActionButton(
                                    icon: Icons.edit_rounded,
                                    color: const Color(0xFF8B5CF6),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      clientEditModelSheet(context,
                                          client: client);
                                    },
                                    tooltip: 'تعديل',
                                  ),
                                  const SizedBox(width: 6),
                                  // Delete Button
                                  _buildCompactActionButton(
                                    icon: Icons.delete_rounded,
                                    color: const Color(0xFFEF4444),
                                    onPressed: () {
                                      HapticFeedback.heavyImpact();
                                      _showDeleteConfirmation(
                                          context, accountController);
                                    },
                                    tooltip: 'حذف',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Selection Indicator
                if (accountController.enableMulipleClientPrint.value)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isSelected ? const Color(0xFF3B82F6) : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(0xFF3B82F6).withOpacity(0.3)
                                : Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isSelected ? Icons.check_rounded : Icons.add_rounded,
                        size: 18,
                        color: isSelected ? Colors.white : Colors.grey[400],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSelection(AccountClientInfo controller) {
    if (controller.clientPrintAdded.contains(client)) {
      controller.clientPrintAdded.remove(client);
    } else {
      controller.clientPrintAdded.add(client);
      HapticFeedback.selectionClick();
    }
    // Trigger targeted rebuild for this specific card only
    controller.update(['client-${client.id}', 'toolbar']);
  }

  Future<void> _handleTap(
      BuildContext context, AccountClientInfo controller) async {
    // Fetch full client data before opening details
    final fullClient = await controller.getFullClientData(client.id as int);
    if (context.mounted) {
      showClientInfoSheet(context, fullClient);
    }
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withOpacity(0.25),
            width: 1.2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onPressed,
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactMoneyStatus() {
    final totalCash = client.totalCash;
    final isPositive = totalCash >= 0;
    final statusColor =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.check_circle_rounded : Icons.warning_rounded,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              isPositive ? 'لا مستحقات' : '${totalCash.abs()} ج.م',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, AccountClientInfo controller) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFEF4444),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'تأكيد الحذف',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                'هل أنت متأكد من حذف العميل "${client.name}"؟',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'لا يمكن التراجع عن هذا الإجراء',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: const Color(0xFF64748B),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();
                        await _deleteClient(controller);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'حذف',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteClient(AccountClientInfo controller) async {
    try {
      // Show loading
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري الحذف...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Delete from backend
      await BackendServices.instance.clientRepository.delete(client);

      // Update local list
      controller.clinets.remove(client);
      controller.update();

      // Close loading
      Get.back();

      // Show success message
      Get.showSnackbar(const GetSnackBar(
        message: 'تم حذف العميل بنجاح',
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF10B981),
        borderRadius: 12,
        margin: EdgeInsets.all(16),
        icon: Icon(Icons.check_circle, color: Colors.white),
      ));
    } catch (e) {
      // Close loading
      Get.back();

      // Show error
      Get.showSnackbar(GetSnackBar(
        message: 'حدث خطأ أثناء الحذف: ${e.toString()}',
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFFEF4444),
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error, color: Colors.white),
      ));
    }
  }

  void _showSuccessSnackbar(String message) {
    Get.showSnackbar(GetSnackBar(
      message: message,
      duration: const Duration(seconds: 2),
      backgroundColor: const Color(0xFF10B981),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(
        Icons.check_circle,
        color: Colors.white,
      ),
    ));
  }
}

class ModernPaymentLoadingWidget extends StatelessWidget {
  final controller = Get.find<AccountClientInfo>();

  ModernPaymentLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final next = ProfitController.to.getNextMonthToBePaid();
    final month = next.month;
    final year = next.year;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loading Animation
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.payment,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "معالجة المدفوعات",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "يتم الآن تحصيل الفواتير المتبقية الخاصة بشهر ${ProfitController.to.months[month]} لعام $year",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),

          // Reactive Current Client Section
          Obx(() => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "العميل الحالي:",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            controller.currentPayingClient.value.name ??
                                "غير محدد",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),

          // Reactive Progress Section
          Obx(() {
            final totalLength = controller.clinets.length;
            final totalPaid = controller.countPaid.value;
            final progress = totalPaid / totalLength;

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "التقدم: $totalPaid من $totalLength",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          "${(progress * 100).toStringAsFixed(1)}%",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B82F6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 32),
          const SoundWaveIndicator(),
        ],
      ),
    );
  }
}

// NEW SOUND WAVE INDICATOR
class SoundWaveIndicator extends StatefulWidget {
  final Color color;
  final double size;
  final int numberOfWaves;

  const SoundWaveIndicator({
    super.key,
    this.color = const Color(0xFF3B82F6),
    this.size = 80,
    this.numberOfWaves = 5,
  });

  @override
  State<SoundWaveIndicator> createState() => _SoundWaveIndicatorState();
}

class _SoundWaveIndicatorState extends State<SoundWaveIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = [];
    _animations = [];

    for (int i = 0; i < widget.numberOfWaves; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 800 + (i * 100)),
        vsync: this,
      );

      final animation = Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));

      _controllers.add(controller);
      _animations.add(animation);

      // Start each animation with a delay
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          controller.repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.numberOfWaves, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: widget.size / widget.numberOfWaves * 0.6,
                height: widget.size * _animations[index].value,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(widget.size / 10),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// Keep the CustomIndicator for backward compatibility but use SoundWaveIndicator
class CustomIndicator extends StatelessWidget {
  final String title;

  const CustomIndicator({
    super.key,
    this.title = "جاري التحميل...",
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SoundWaveIndicator(),
        if (title.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ],
    );
  }
}
