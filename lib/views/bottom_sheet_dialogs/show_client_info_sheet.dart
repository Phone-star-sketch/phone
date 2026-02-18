import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/client_bottom_sheet_controller.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/views/print_client_full_report.dart';
import 'package:phone_system_app/views/pages/all_clinets_page.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/other_services_exclude_price.dart';
import 'package:phone_system_app/views/pages/system_choice.dart';
import 'package:phone_system_app/views/pages/successfull_payment.dart';
import 'package:phone_system_app/models/system_type.dart';

Future showClientInfoSheet(BuildContext? context, Client client) async {
  final effectiveContext = context ?? Get.context;
  if (effectiveContext == null) {
    Get.snackbar('خطأ', 'لا يمكن فتح صفحة معلومات العميل');
    return;
  }

  if (effectiveContext is Element && !effectiveContext.mounted) {
    Get.snackbar('خطأ', 'السياق غير صالح');
    return;
  }

  if (Get.isRegistered<ClientBottomSheetController>()) {
    Get.delete<ClientBottomSheetController>(force: true);
  }

  if (!Get.isRegistered<ExcludedSystemsManager>()) {
    Get.put(ExcludedSystemsManager());
  } else {
    Get.find<ExcludedSystemsManager>().clearExclusions();
  }

  final controller = Get.put(ClientBottomSheetController());
  await controller.setClient(client);

  return showModalBottomSheet(
    backgroundColor: const Color(0xFFF8FAFC),
    enableDrag: true,
    showDragHandle: false,
    isScrollControlled: true,
    barrierLabel: "بيانات العميل",
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    constraints: BoxConstraints.expand(
      width: min(MediaQuery.maybeOf(effectiveContext)?.size.width ?? 600, 600),
    ),
    context: effectiveContext,
    builder: (builderContext) {
      return GetBuilder<ClientBottomSheetController>(
        builder: (controller) => GetBuilder<ExcludedSystemsManager>(
          builder: (excludedManager) => _ModernClientSheet(
            client: client,
            controller: controller,
          ),
        ),
      );
    },
  ).whenComplete(() {
    if (Get.isRegistered<ClientBottomSheetController>()) {
      Get.delete<ClientBottomSheetController>(force: true);
    }
    if (Get.isRegistered<ExcludedSystemsManager>()) {
      Get.delete<ExcludedSystemsManager>(force: true);
    }
  });
}

class _ModernClientSheet extends StatelessWidget {
  final Client client;
  final ClientBottomSheetController controller;

  const _ModernClientSheet({required this.client, required this.controller});

  Color _getStatusColor(num cash) {
    if (cash > 10) return const Color(0xFF10b981);
    if (cash >= 0) return const Color(0xFFf59e0b);
    return const Color(0xFFef4444);
  }

  @override
  Widget build(BuildContext context) {
    final currentClient = controller.getClient() ?? client;
    final systems = controller.getClientSystems() ?? [];
    final logs = controller.getClientLogs() ?? [];
    final cash = currentClient.totalCash ?? 0;
    final statusColor = _getStatusColor(cash);
    final isManager =
        SupabaseAuthentication.myUser!.role != UserRoles.assistant.index;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                // Container(
                //   width: 60,
                //   height: 60,
                //   decoration: BoxDecoration(
                //     color: Colors.white.withOpacity(0.2),
                //     borderRadius: BorderRadius.circular(16),
                //   ),
                //   child: Center(
                //     child: Text(
                //       currentClient.name?[0].toUpperCase() ?? '؟',
                //       style: const TextStyle(
                //         fontSize: 28,
                //         fontWeight: FontWeight.w700,
                //         color: Colors.white,
                //       ),
                //     ),
                //   ),
                // ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentClient.name ?? 'غير محدد',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded,
                              size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            currentClient.getFormattedPhoneNumber(),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${cash.abs().toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Text('ج.م',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Always show: Add and Payment buttons
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.arrow_downward_rounded,
                    label: 'تسديد',
                    color: const Color(0xFF10b981),
                    onTap: () => showMoneyDialog(context, currentClient, true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.arrow_upward_rounded,
                    label: 'إضافة',
                    color: const Color(0xFFef4444),
                    onTap: () => showMoneyDialog(context, currentClient, false),
                  ),
                ),
                // Show these buttons only for manager
                if (isManager) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.add_box_rounded,
                      label: 'باقة جديدة',
                      color: const Color(0xFF10b981),
                      onTap: () => showSystemAddDialog(currentClient),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.print_rounded,
                      label: 'طباعة',
                      color: const Color(0xFF8b5cf6),
                      onTap: () {
                        final clientLogs = controller.getClientLogs() ?? [];
                        final clientSystems =
                            controller.getClientSystems() ?? [];
                        showPrintClientReport(context, currentClient,
                            logs: clientLogs, systems: clientSystems);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.apps_rounded,
                      label: 'الباقات',
                      color: const Color(0xFFf59e0b),
                      onTap: () =>
                          showModernSystemChoiceSheet(context, currentClient),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Content
          Expanded(
            child: DefaultTabController(
              length: isManager ? 3 : 1,
              child: Column(
                children: [
                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      labelColor: const Color(0xFF3b82f6),
                      unselectedLabelColor: Colors.grey[500],
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: const Color(0xFF3b82f6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tabs: [
                        const Tab(text: 'السجل'),
                        if (isManager) const Tab(text: 'البيانات'),
                        if (isManager) const Tab(text: 'الإعدادات'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      children: [
                        _LogsTab(logs: logs, client: currentClient),
                        if (isManager)
                          _InfoTab(client: currentClient, systems: systems),
                        if (isManager) _SettingsTab(client: currentClient),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogsTab extends StatelessWidget {
  final List<Log> logs;
  final Client client;

  const _LogsTab({required this.logs, required this.client});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('لا توجد تعاملات', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final isAddition = log.transactionType == TransactionType.addition ||
            log.transactionType == TransactionType.moneyAdded;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isAddition
                          ? const Color(0xFF10b981)
                          : const Color(0xFFef4444))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isAddition
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: isAddition
                      ? const Color(0xFF10b981)
                      : const Color(0xFFef4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.systemType.isNotEmpty
                          ? log.systemType
                          : (isAddition ? 'قيمة إضافة' : 'قيمة تسديد'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      log.createdAt != null
                          ? fullExpressionArabicDate(log.createdAt!)
                          : '',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '${log.price.toStringAsFixed(0)} ج.م',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isAddition
                      ? const Color(0xFF10b981)
                      : const Color(0xFFef4444),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoTab extends StatelessWidget {
  final Client client;
  final List<System> systems;

  const _InfoTab({required this.client, required this.systems});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _InfoCard(
          items: [
            _InfoItem(
                icon: Icons.badge_rounded,
                label: 'الرقم القومي',
                value: client.nationalId ?? 'غير متوفر'),
            _InfoItem(
                icon: Icons.location_on_rounded,
                label: 'العنوان',
                value: client.address ?? 'غير متوفر'),
            _InfoItem(
                icon: Icons.phone_rounded,
                label: 'رقم الخط',
                value: client.getFormattedPhoneNumber()),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          items: [
            _InfoItem(
              icon: Icons.calendar_today_rounded,
              label: 'تاريخ بداية الاشتراك',
              value: client.createdAt != null
                  ? fullExpressionArabicDate(client.createdAt!)
                  : 'غير محدد',
            ),
            if (client.expireDate != null)
              _InfoItem(
                icon: Icons.event_rounded,
                label: 'تاريخ انتهاء العرض',
                value: fullExpressionArabicDate(client.expireDate!),
              ),
            _InfoItem(
              icon: Icons.event_available_rounded,
              label: 'نهاية الاشتراك',
              value: systems.isNotEmpty && systems.first.endDate != null
                  ? fullExpressionArabicDate(systems.first.endDate!)
                  : 'غير محدد',
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;

  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3b82f6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon,
                        color: const Color(0xFF3b82f6), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label,
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(
                          item.value,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (index < items.length - 1)
                Divider(height: 24, color: Colors.grey[100]),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem({required this.icon, required this.label, required this.value});
}

class _SettingsTab extends StatelessWidget {
  final Client client;

  const _SettingsTab({required this.client});

  @override
  Widget build(BuildContext context) {
    // Check if user is manager
    final isManager =
        SupabaseAuthentication.myUser!.role != UserRoles.assistant.index;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Show all buttons for manager, only specific buttons for assistant
        if (isManager) ...[
          _SettingButton(
            icon: Icons.calendar_month_rounded,
            label: 'تغيير تاريخ انتهاء العرض',
            color: const Color(0xFF10b981),
            onTap: () async {
              final data = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 50)),
                lastDate: DateTime(DateTime.now().year + 10),
              );
              if (data != null) {
                client.expireDate = data;
                await BackendServices.instance.clientRepository.update(client);
                AccountClientInfo.to.updateCurrnetClinets();
                Get.back();
              }
            },
          ),
          const SizedBox(height: 10),
          _SettingButton(
            icon: Icons.discount_rounded,
            label: 'إضافة خصم',
            color: const Color(0xFFf59e0b),
            onTap: () => showDiscountDialog(context, client),
          ),
          const SizedBox(height: 10),
          _SettingButton(
            icon: Icons.delete_rounded,
            label: 'حذف العميل',
            color: const Color(0xFFef4444),
            onTap: () => _showDeleteDialog(client),
          ),
        ],
      ],
    );
  }

  void _showDeleteDialog(Client client) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('حذف العميل',
            style: TextStyle(
                color: Colors.grey[800], fontWeight: FontWeight.w600)),
        content: Text('هل أنت متأكد من حذف "${client.name}"؟',
            style: TextStyle(color: Colors.grey[600])),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Close confirmation dialog first
                Get.back();

                // Show loading with barrier
                Get.dialog(
                  WillPopScope(
                    onWillPop: () async => false,
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF3b82f6),
                              ),
                              SizedBox(height: 16),
                              Text('جاري الحذف...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  barrierDismissible: false,
                );

                // Delete from database
                await BackendServices.instance.clientRepository.delete(client);

                // Update controller - use correct syntax for RxList
                final controller = AccountClientInfo.to;
                controller.clinets.removeWhere((c) => c.id == client.id);
                controller.clinets.refresh();

                // Close loading dialog
                Get.back();

                // Close bottom sheet
                Get.back();

                // Show success message
                Get.showSnackbar(const GetSnackBar(
                  message: 'تم حذف العميل بنجاح',
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF10b981),
                  borderRadius: 10,
                  margin: EdgeInsets.all(12),
                ));
              } catch (e) {
                // Close loading if still open
                if (Get.isDialogOpen ?? false) {
                  Get.back();
                }

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
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SettingButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SettingButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey[800]),
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// Money Dialog
Future<void> showMoneyDialog(BuildContext context, Client client, bool adding,
    [bool both = false]) async {
  final controller = TextEditingController();
  final loaders = Get.put(Loaders());

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  (adding ? const Color(0xFFef4444) : const Color(0xFF10b981))
                      .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              adding
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: adding ? const Color(0xFFef4444) : const Color(0xFF10b981),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            adding ? 'قيمة إضافة' : 'قيمة تسديد',
            style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
                fontSize: 18),
          ),
        ],
      ),
      content: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(both ? r'[0-9.]' : r'[0-9]'))
                ],
                style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  suffixText: 'ج.م',
                  suffixStyle: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loaders.moneyIsLoading.value
                    ? null
                    : () async {
                        try {
                          // Prevent multiple submissions
                          if (loaders.moneyIsLoading.value) {
                            return;
                          }

                          if (controller.text.isEmpty) {
                            throw 'الرجاء إدخال مبلغ صحيح';
                          }
                          final amount = int.tryParse(controller.text);
                          if (amount == null) {
                            throw 'الرجاء إدخال مبلغ صحيح';
                          }

                          // Set loading state
                          loaders.moneyIsLoading.value = true;

                          try {
                            await loaders.changeMoneyValue(
                                client, controller.text, adding);

                            // Store the values before closing dialog
                            final amountText = controller.text;
                            final isAdding = adding;

                            // Reset loading state
                            loaders.moneyIsLoading.value = false;

                            // Close only the money dialog
                            Navigator.of(dialogContext).pop();

                            // Small delay to ensure dialog is closed
                            await Future.delayed(
                                const Duration(milliseconds: 100));

                            // Navigate to success page and wait for result
                            final result = await Get.to(
                              () => SuccessfulPaymentPage(
                                amount: '$amountText جنيه',
                                transactionId:
                                    'TXN${DateTime.now().millisecondsSinceEpoch}',
                                paymentMethod:
                                    isAdding ? 'إيداع نقدي' : 'تسديد نقدي',
                                client: client,
                              ),
                            );

                            // If success page wants to close bottom sheet, do it
                            if (result != null &&
                                result['closeBottomSheet'] == true) {
                              // Close the bottom sheet to return to AccountDetails
                              Get.back();
                            }
                          } catch (e) {
                            // Reset loading state on error
                            loaders.moneyIsLoading.value = false;
                            rethrow;
                          }
                        } catch (e) {
                          Get.snackbar(
                            'خطأ',
                            e.toString(),
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor:
                                const Color(0xFFef4444).withOpacity(0.1),
                            colorText: const Color(0xFFef4444),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: adding
                      ? const Color(0xFFef4444)
                      : const Color(0xFF10b981),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: loaders.moneyIsLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('تأكيد',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Discount Dialog
Future<void> showDiscountDialog(BuildContext context, Client client) async {
  final amountController =
      TextEditingController(text: client.discountPercentage?.toString() ?? '');
  final selectedDate = (client.discountEndDate ?? DateTime.now()).obs;

  await Get.dialog(
    AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFf59e0b).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.discount_rounded, color: Color(0xFFf59e0b)),
          ),
          const SizedBox(width: 12),
          Text('إضافة خصم',
              style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 18)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                suffixText: '%',
                suffixStyle: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate.value,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(DateTime.now().year + 5),
                  );
                  if (date != null) selectedDate.value = date;
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: Colors.grey[500], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        fullExpressionArabicDate(selectedDate.value),
                        style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  final discountAmount = double.tryParse(amountController.text);
                  if (discountAmount == null ||
                      discountAmount <= 0 ||
                      discountAmount > 100) {
                    throw 'نسبة الخصم يجب أن تكون بين 0 و 100';
                  }

                  client.discountPercentage = discountAmount;
                  client.discountEndDate = selectedDate.value;
                  await BackendServices.instance.clientRepository
                      .update(client);

                  if (Get.isRegistered<ClientBottomSheetController>()) {
                    Get.find<ClientBottomSheetController>().updateClient();
                  }

                  Get.back();
                  Get.snackbar(
                    'نجاح',
                    'تم إضافة الخصم بنجاح',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFF10b981).withOpacity(0.1),
                    colorText: const Color(0xFF10b981),
                  );
                } catch (e) {
                  Get.snackbar(
                    'خطأ',
                    e.toString(),
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFFef4444).withOpacity(0.1),
                    colorText: const Color(0xFFef4444),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf59e0b),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('تطبيق الخصم',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );
}

// Danger Dialog
Future<void> showDangerDialog(
    String title, String message, Function() action) async {
  await Get.dialog(
    AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title,
          style:
              TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600)),
      content: Text(message, style: TextStyle(color: Colors.grey[600])),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('إلغاء', style: TextStyle(color: Colors.grey[500])),
        ),
        ElevatedButton(
          onPressed: () async {
            await action();
            Get.back();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFef4444),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

// Edit System Dialog
Future<void> showEditSystemDialog(System system) async {
  final nameController = TextEditingController(text: system.name);

  await Get.dialog(
    AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('تعديل النظام',
          style:
              TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('النظام: ${system.type!.name}',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: nameController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'الملاحظات',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('إلغاء', style: TextStyle(color: Colors.grey[500])),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              system.name = nameController.text;
              await BackendServices.instance.systemRepository.update(system);
              Get.back();
              Get.snackbar('نجاح', 'تم تحديث الملاحظات بنجاح',
                  snackPosition: SnackPosition.BOTTOM);
              if (Get.isRegistered<ClientBottomSheetController>()) {
                Get.find<ClientBottomSheetController>().updateClient();
              }
            } catch (e) {
              Get.snackbar('خطأ', 'حدث خطأ أثناء تحديث الملاحظات',
                  snackPosition: SnackPosition.BOTTOM);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3b82f6),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('حفظ', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

// Helper functions
bool shouldShowSystem(System system) {
  return true;
}

// Add System Dialog - إضافة باقة جديدة للعميل
void showSystemAddDialog(Client client) async {
  SystemType? currentType;
  final controller = Get.find<ClientBottomSheetController>();
  final loaders = Get.put(Loaders());

  await Get.dialog(
    AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF10b981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.add_circle_outline, color: Color(0xFF10b981)),
          ),
          const SizedBox(width: 12),
          Text(
            'إضافة باقة جديدة',
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownMenu<SystemType>(
                width: 250,
                menuHeight: 400,
                enableFilter: true,
                requestFocusOnTap: true,
                enableSearch: true,
                hintText: 'اختر الباقة',
                textStyle: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                  elevation: WidgetStateProperty.all(8),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                dropdownMenuEntries: _buildGroupedSystemEntries(controller),
                onSelected: (value) {
                  currentType = value;
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loaders.systemIsLoading.value
                    ? null
                    : () async {
                        if (currentType != null) {
                          await loaders.manageSystemType(client, currentType!);
                          Get.back();
                          Get.snackbar(
                            'نجاح',
                            'تم إضافة الباقة بنجاح',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor:
                                const Color(0xFF10b981).withValues(alpha: 0.1),
                            colorText: const Color(0xFF10b981),
                          );
                        } else {
                          Get.snackbar(
                            'تنبيه',
                            'الرجاء اختيار باقة أولاً',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor:
                                const Color(0xFFf59e0b).withValues(alpha: 0.1),
                            colorText: const Color(0xFFf59e0b),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10b981),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: loaders.systemIsLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text('إضافة',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CustomIndicator extends StatelessWidget {
  final String? title;

  const CustomIndicator({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: Color(0xFF3b82f6)),
        ),
        if (title != null && title!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(title!, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ],
    );
  }
}

// Helper function to build grouped system entries with headers
List<DropdownMenuEntry<SystemType>> _buildGroupedSystemEntries(
    ClientBottomSheetController controller) {
  final allTypes = controller.getAllTypes();
  final List<DropdownMenuEntry<SystemType>> entries = [];

  // Group by category
  final internetTypes = allTypes
      .where((type) => type.category == SystemCategory.internetPackage)
      .toList();
  final mobileTypes = allTypes
      .where((type) => type.category == SystemCategory.mobileInternet)
      .toList();
  final mainTypes = allTypes
      .where((type) => type.category == SystemCategory.mainPackage)
      .toList();

  // Add Main Packages section FIRST
  if (mainTypes.isNotEmpty) {
    entries.add(
      DropdownMenuEntry<SystemType>(
        value: mainTypes.first,
        label: '━━━ الباقات الرئيسية ━━━',
        enabled: false,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
            const Color(0xFFf59e0b).withValues(alpha: 0.05),
          ),
          foregroundColor: WidgetStateProperty.all(
            const Color(0xFFf59e0b),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );

    for (var type in mainTypes) {
      entries.add(
        DropdownMenuEntry<SystemType>(
          value: type,
          label: type.name ?? '',
          leadingIcon: Icon(
            Icons.router_rounded,
            color: const Color(0xFFf59e0b),
            size: 20,
          ),
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(Colors.grey[800]),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return const Color(0xFFf59e0b).withValues(alpha: 0.1);
              }
              return Colors.white;
            }),
          ),
        ),
      );
    }
  }

  // Add Internet section SECOND
  if (internetTypes.isNotEmpty) {
    // Add header (disabled entry)
    entries.add(
      DropdownMenuEntry<SystemType>(
        value: internetTypes.first, // Dummy value, won't be selectable
        label: '━━━ باقات الإنترنت ━━━',
        enabled: false,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
            const Color(0xFF3b82f6).withValues(alpha: 0.05),
          ),
          foregroundColor: WidgetStateProperty.all(
            const Color(0xFF3b82f6),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );

    // Add internet packages
    for (var type in internetTypes) {
      entries.add(
        DropdownMenuEntry<SystemType>(
          value: type,
          label: type.name ?? '',
          leadingIcon: Icon(
            Icons.wifi_rounded,
            color: const Color(0xFF3b82f6),
            size: 20,
          ),
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(Colors.grey[800]),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return const Color(0xFF3b82f6).withValues(alpha: 0.1);
              }
              return Colors.white;
            }),
          ),
        ),
      );
    }
  }

  // Add Mobile section THIRD
  if (mobileTypes.isNotEmpty) {
    entries.add(
      DropdownMenuEntry<SystemType>(
        value: mobileTypes.first,
        label: '━━━ باقات الموبايل ━━━',
        enabled: false,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
            const Color(0xFF10b981).withValues(alpha: 0.05),
          ),
          foregroundColor: WidgetStateProperty.all(
            const Color(0xFF10b981),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );

    for (var type in mobileTypes) {
      entries.add(
        DropdownMenuEntry<SystemType>(
          value: type,
          label: type.name ?? '',
          leadingIcon: Icon(
            Icons.smartphone_rounded,
            color: const Color(0xFF10b981),
            size: 20,
          ),
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(Colors.grey[800]),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return const Color(0xFF10b981).withValues(alpha: 0.1);
              }
              return Colors.white;
            }),
          ),
        ),
      );
    }
  }

  return entries;
}
