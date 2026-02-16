import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';
import 'package:phone_system_app/views/print_clients_receipts.dart';
import 'package:flutter/services.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/widget_models/clientCreationModelSheet.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/services/backend/auth.dart';

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
  State<AllClientsPage> createState() => _AllClientsPageState();
}

class _AllClientsPageState extends State<AllClientsPage>
    with AutomaticKeepAliveClientMixin {
  final controller = Get.find<AccountClientInfo>();

  List<Client> _getFilteredClients(String query) {
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Obx(() {
          final q = controller.query.value;
          final filteredData = _getFilteredClients(q);
          final isLoading = controller.isLoading.value;

          return Column(
            children: [
              // Compact Header with Search
              _buildCompactHeader(filteredData.length),

              // Content
              Expanded(
                child: isLoading
                    ? _buildLoader()
                    : _buildClientsList(filteredData),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCompactHeader(int clientCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title Row with Actions
          Row(
            children: [
              // Title & Count
              Text(
                'إدارة العملاء',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10b981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$clientCount',
                  style: const TextStyle(
                    color: Color(0xFF10b981),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              // Action Buttons
              _buildMiniButton(
                icon: Icons.person_add_rounded,
                color: const Color(0xFF10b981),
                onTap: () => clientEditModelSheet(context),
              ),
              const SizedBox(width: 6),
              GetBuilder<AccountClientInfo>(
                builder: (ctrl) {
                  return _buildMiniButton(
                    icon: ctrl.enableMulipleClientPrint.value
                        ? Icons.close_rounded
                        : Icons.checklist_rounded,
                    color: ctrl.enableMulipleClientPrint.value
                        ? const Color(0xFFef4444)
                        : const Color(0xFF3b82f6),
                    onTap: () {
                      ctrl.toggleMultiSelection();
                      ctrl.update();
                    },
                  );
                },
              ),
              const SizedBox(width: 6),
              _buildMiniButton(
                icon: FontAwesomeIcons.print,
                color: const Color(0xFF8b5cf6),
                onTap: () => _showPrintDialog(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Search Bar
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.searchQueryChanged,
              style: TextStyle(color: Colors.grey[800], fontSize: 14),
              decoration: InputDecoration(
                hintText: 'بحث...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.grey[400], size: 20),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withOpacity(0.1),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF3b82f6),
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 12),
          Text(
            'جاري التحميل...',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList(List<Client> clients) {
    if (clients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'لا توجد نتائج',
              style: TextStyle(fontSize: 15, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ModernClientCard(
              client: clients[index], index: index, lightTheme: true),
        );
      },
    );
  }

  void _showPrintDialog() {
    Get.dialog(
      GetBuilder<AccountClientInfo>(
        builder: (ctrl) => Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 400,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF8b5cf6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(FontAwesomeIcons.print,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 10),
                      const Text(
                        'قائمة الطباعة',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: ctrl.clientPrintAdded.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_rounded,
                                  size: 40, color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              Text('لا توجد عناصر',
                                  style: TextStyle(color: Colors.grey[400])),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          shrinkWrap: true,
                          itemCount: ctrl.clientPrintAdded.length,
                          itemBuilder: (context, index) {
                            final client = ctrl.clientPrintAdded[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: const Color(0xFFF8FAFC),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF3b82f6),
                                    child: Text(
                                      client.name?.substring(0, 1) ?? '؟',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      client.name ?? '',
                                      style: TextStyle(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      ctrl.clientPrintAdded.remove(client);
                                      ctrl.update();
                                    },
                                    child: const Icon(
                                        Icons.remove_circle_rounded,
                                        color: Color(0xFFef4444),
                                        size: 20),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                // Footer
                if (ctrl.clientPrintAdded.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          Get.to(PrintClientsReceipts(
                              clients: ctrl.clientPrintAdded));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10b981),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('طباعة',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
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

// Public Modern Client Card - can be used from other files
class ModernClientCard extends StatefulWidget {
  final Client client;
  final int index;
  final bool lightTheme;

  const ModernClientCard({
    super.key,
    required this.client,
    required this.index,
    this.lightTheme = true,
  });

  @override
  State<ModernClientCard> createState() => _ModernClientCardState();
}

class _ModernClientCardState extends State<ModernClientCard> {
  Color _getStatusColor() {
    final cash = widget.client.totalCash ?? 0;
    if (cash > 10) return const Color(0xFF10b981);
    if (cash >= 0) return const Color.fromARGB(255, 58, 195, 9);
    return const Color(0xFFef4444);
  }

  String _getStatusText() {
    final cash = widget.client.totalCash ?? 0;
    if (cash > 10) return 'لا يوجد مستحقات';
    if (cash >= 0) return 'لا يوجد عليه مستحقات';
    return 'عليه مستحقات';
  }

  @override
  Widget build(BuildContext context) {
    final cash = widget.client.totalCash ?? 0;
    final isNegative = cash < 0;

    return GetBuilder<AccountClientInfo>(
      builder: (ctrl) {
        final isSelected =
            ctrl.clientPrintAdded.any((c) => c.id == widget.client.id);

        return GestureDetector(
          onTap: () {
            if (ctrl.enableMulipleClientPrint.value) {
              if (isSelected) {
                ctrl.clientPrintAdded
                    .removeWhere((c) => c.id == widget.client.id);
              } else {
                ctrl.clientPrintAdded.add(widget.client);
                HapticFeedback.selectionClick();
              }
              ctrl.update();
            } else {
              showClientInfoSheet(context, widget.client);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3b82f6)
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Main Content
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _getStatusColor().withOpacity(0.1),
                        ),
                        child: Center(
                          child: Text(
                            widget.client.name?.substring(0, 1).toUpperCase() ??
                                '؟',
                            style: TextStyle(
                              color: _getStatusColor(),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.client.name ?? 'غير معروف',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.phone_rounded,
                                    size: 12, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(
                                  widget.client.getFormattedPhoneNumber(),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Action Buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionBtn(
                            icon: Icons.copy_rounded,
                            color: const Color(0xFF3b82f6),
                            onTap: () {
                              final phone =
                                  widget.client.getFormattedPhoneNumber();
                              if (phone != 'غير متوفر') {
                                Clipboard.setData(ClipboardData(text: phone));
                                Get.showSnackbar(const GetSnackBar(
                                  message: 'تم نسخ الرقم',
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Color(0xFF10b981),
                                  borderRadius: 10,
                                  margin: EdgeInsets.all(12),
                                ));
                              }
                            },
                          ),
                          // Hide edit and delete buttons for assistant role
                          if (SupabaseAuthentication.myUser!.role !=
                              UserRoles.assistant.index) ...[
                            const SizedBox(width: 6),
                            _buildActionBtn(
                              icon: Icons.edit_rounded,
                              color: const Color(0xFFf59e0b),
                              onTap: () => clientEditModelSheet(context,
                                  client: widget.client),
                            ),
                            const SizedBox(width: 6),
                            _buildActionBtn(
                              icon: Icons.delete_rounded,
                              color: const Color(0xFFef4444),
                              onTap: () => _showDeleteDialog(),
                            ),
                          ],
                        ],
                      ),
                      // Selection Checkbox
                      if (ctrl.enableMulipleClientPrint.value)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: isSelected
                                  ? const Color(0xFF3b82f6)
                                  : const Color(0xFFF1F5F9),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF3b82f6)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
                // Status Bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    color: _getStatusColor().withOpacity(0.08),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isNegative
                            ? Icons.warning_rounded
                            : Icons.check_circle_rounded,
                        size: 14,
                        color: _getStatusColor(),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${cash.abs().toStringAsFixed(0)} ج.م',
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.1),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  void _showDeleteDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'حذف العميل',
          style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
              fontSize: 16),
        ),
        content: Text(
          'هل أنت متأكد من حذف "${widget.client.name}"؟',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close confirmation dialog
              Get.back();

              // Show loading indicator
              Get.dialog(
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3b82f6),
                  ),
                ),
                barrierDismissible: false,
              );

              try {
                // Delete from database
                await BackendServices.instance.clientRepository
                    .delete(widget.client);

                // Update controller
                final controller = Get.find<AccountClientInfo>();
                controller.clinets.value
                    .removeWhere((c) => c.id == widget.client.id);
                controller.clinets.refresh();
                controller.update(); // Force GetBuilder to rebuild

                // Close loading
                Get.back();

                // Show success message
                Get.showSnackbar(const GetSnackBar(
                  message: 'تم حذف العميل بنجاح',
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF10b981),
                  borderRadius: 10,
                  margin: EdgeInsets.all(12),
                ));

                // Force rebuild of the widget
                if (mounted) {
                  setState(() {});
                }
              } catch (e) {
                // Close loading
                Get.back();

                // Show error message
                Get.showSnackbar(GetSnackBar(
                  message: 'حدث خطأ أثناء الحذف: ${e.toString()}',
                  duration: const Duration(seconds: 3),
                  backgroundColor: const Color(0xFFef4444),
                  borderRadius: 10,
                  margin: const EdgeInsets.all(12),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
