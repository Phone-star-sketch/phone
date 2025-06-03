import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';
import 'package:phone_system_app/views/client_list_view.dart';
import 'package:phone_system_app/views/print_clients_receipts.dart';
import 'package:flutter/services.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/widget_models/clientCreationModelSheet.dart';

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
    List<Client> clients = controller.clinets.value;
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
      child: Obx(() {
        final q = controller.query.value;
        final filteredData = _getSmartFilteredClients(q);
        final isLoading = controller.isLoading.value;
        final printingClients = controller.clientPrintAdded.value;

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Modern Header with Glass Effect
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
                                  '${filteredData.length} عميل',
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
                            controller: controller,
                            printingClients: printingClients,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Content Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: (isLoading)
                        ? const ModernLoadingIndicator()
                        : (Loaders.to.paymentIsLoading.value)
                            ? ModernPaymentLoadingWidget()
                            : ModernClientListView(
                                data: filteredData,
                                isLoading: isLoading,
                                query: controller.query.value,
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

class ModernClientListView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (data.isEmpty) {
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

    return ListView.separated(
      itemCount: data.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return ModernClientCard(
          client: data[index],
          index: index,
        );
      },
    );
  }
}

class ModernClientCard extends StatefulWidget {
  const ModernClientCard({
    super.key,
    required this.client,
    required this.index,
  });

  final Client client;
  final int index;

  @override
  State<ModernClientCard> createState() => _ModernClientCardState();
}

class _ModernClientCardState extends State<ModernClientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 50)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getBaseColor(int index) {
    // Define a default color in case the list is empty
    const defaultColor = Color(0xFF3B82F6); // Blue

    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF59E0B), // Orange
      const Color(0xFFEF4444), // Red
    ];

    // Safely get color or return default
    try {
      return colors[index % colors.length];
    } catch (_) {
      return defaultColor;
    }
  }

  List<Color> _getGradientColors(int index) {
    final baseColor = _getBaseColor(index);
    return [
      baseColor,
      baseColor.withOpacity(0.7),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AccountClientInfo>(
      builder: (accountController) {
        final isSelected =
            accountController.clientPrintAdded.contains(widget.client);

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isSelected ? Colors.blue[700]! : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? Colors.blue[700]!.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () =>
                          accountController.enableMulipleClientPrint.value
                              ? _handleSelection(accountController)
                              : showClientInfoSheet(context, widget.client),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Main Content
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    // Avatar with safe gradient
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors:
                                              _getGradientColors(widget.index),
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _getBaseColor(widget.index)
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.person,
                                          color: Colors.white, size: 28),
                                    ),
                                    const SizedBox(width: 20),
                                    // Client Info with null safety
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.client.name ?? 'غير محدد',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3B82F6)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                                    widget.client
                                                        .getFormattedPhoneNumber(),
                                                    style: const TextStyle(
                                                      color: Color(0xFF3B82F6),
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Action Buttons
                                    Column(
                                      children: [
                                        _buildActionIcon(
                                          Icons.copy,
                                          const Color(0xFF10B981),
                                          () {
                                            final phoneNumber = widget.client
                                                .getFormattedPhoneNumber();
                                            if (phoneNumber != 'غير متوفر') {
                                              Clipboard.setData(ClipboardData(
                                                  text: phoneNumber));
                                              _showSuccessSnackbar(
                                                  'تم نسخ رقم الهاتف');
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        _buildActionIcon(
                                          Icons.edit,
                                          const Color(0xFF64748B),
                                          () => clientEditModelSheet(
                                            context,
                                            client: widget.client,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Money Status Bar
                              _buildMoneyStatusBar(),
                            ],
                          ),
                          if (accountController.enableMulipleClientPrint.value)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.blue[700]
                                      : Colors.grey[200],
                                ),
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  isSelected ? Icons.check : Icons.add,
                                  size: 20,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleSelection(AccountClientInfo controller) {
    if (controller.clientPrintAdded.contains(widget.client)) {
      controller.clientPrintAdded.remove(widget.client);
    } else {
      controller.clientPrintAdded.add(widget.client);
      HapticFeedback.selectionClick();
    }
    controller.update(); // Add this to trigger UI update
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 18),
        onPressed: onPressed,
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildMoneyStatusBar() {
    final totalCash = widget.client.totalCash ?? 0;
    final isPositive = totalCash >= 0;
    final statusColor =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                size: 20,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Text(
                isPositive ? 'لا يوجد مستحقات' : 'المبلغ المطلوب',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            '${totalCash.abs()} ج.م',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
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
          const ModernLoadingIndicator(),
        ],
      ),
    );
  }
}

class ModernLoadingIndicator extends StatefulWidget {
  const ModernLoadingIndicator({super.key});

  @override
  State<ModernLoadingIndicator> createState() => _ModernLoadingIndicatorState();
}

class _ModernLoadingIndicatorState extends State<ModernLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_rotationController);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3B82F6),
                    Color(0xFF8B5CF6),
                    Color(0xFF10B981),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Custom Indicator Widget for compatibility
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
        const ModernLoadingIndicator(),
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
