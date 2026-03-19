import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/pages/smart_reminders/controllers/reminders_controller.dart';
import 'package:phone_system_app/pages/smart_reminders/services/whatsapp_service.dart';
import 'package:phone_system_app/pages/smart_reminders/widgets/reminder_client_card.dart';
import 'package:phone_system_app/pages/smart_reminders/widgets/whatsapp_settings_page.dart';

class SmartRemindersPage extends StatelessWidget {
  const SmartRemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RemindersController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF25D366)),
            );
          }
          return Column(
            children: [
              _buildHeader(controller),
              _buildSearchBar(controller),
              _buildKPICards(controller),
              _buildTabBar(controller),
              Expanded(child: _buildTabContent(controller)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeader(RemindersController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.message_rounded,
              color: Color(0xFF25D366),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مركز التذكيرات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1a1a2e),
                  ),
                ),
                Text(
                  'أرسل رسائل WhatsApp بضغطة زر',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Get.to(() => const WhatsAppSettingsPage()),
            icon: const Icon(Icons.settings_rounded, color: Color(0xFF6b7280)),
            tooltip: 'إعدادات الرسائل',
          ),
          IconButton(
            onPressed: () => controller.loadData(),
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6b7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(RemindersController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        onChanged: (val) => controller.searchQuery.value = val,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم أو رقم الهاتف...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? GestureDetector(
                  onTap: () => controller.searchQuery.value = '',
                  child: Icon(Icons.close, color: Colors.grey[400], size: 18),
                )
              : const SizedBox()),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF25D366)),
          ),
        ),
      ),
    );
  }

  Widget _buildKPICards(RemindersController controller) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildKPI(
            icon: Icons.warning_amber_rounded,
            label: 'عليهم فلوس',
            value: '${controller.totalDebtClients.value}',
            color: const Color(0xFFef4444),
          ),
          const SizedBox(width: 10),
          _buildKPI(
            icon: Icons.timer_outlined,
            label: 'قرب ينتهي',
            value: '${controller.totalExpiringClients.value}',
            color: const Color(0xFFf59e0b),
          ),
          const SizedBox(width: 10),
          _buildKPI(
            icon: Icons.attach_money_rounded,
            label: 'إجمالي الدين',
            value: _formatAmount(controller.totalDebtAmount.value),
            color: const Color(0xFF8b5cf6),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildKPI({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(RemindersController controller) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Obx(() => Row(
            children: [
              _buildTab(
                controller,
                index: 0,
                label: 'مديونيات',
                icon: Icons.money_off_rounded,
              ),
              _buildTab(
                controller,
                index: 1,
                label: 'اشتراكات منتهية',
                icon: Icons.timer_off_rounded,
              ),
              _buildTab(
                controller,
                index: 2,
                label: 'إرسال جماعي',
                icon: Icons.send_rounded,
              ),
            ],
          )),
    );
  }

  Widget _buildTab(
    RemindersController controller, {
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectedTab.value = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? const Color(0xFF25D366) : Colors.grey[500],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isSelected ? const Color(0xFF1a1a2e) : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(RemindersController controller) {
    return Obx(() {
      switch (controller.selectedTab.value) {
        case 0:
          return _buildDebtList(controller);
        case 1:
          return _buildExpiringList(controller);
        case 2:
          return _buildBulkSend(controller);
        default:
          return const SizedBox();
      }
    });
  }

  Widget _buildDebtList(RemindersController controller) {
    final clients = controller.filteredDebtClients;
    if (clients.isEmpty) {
      return _buildEmptyState(
          controller.searchQuery.value.isNotEmpty
              ? 'لا يوجد نتائج للبحث'
              : 'لا يوجد عملاء عليهم مديونيات 🎉',
          controller.searchQuery.value.isNotEmpty
              ? Icons.search_off
              : Icons.check_circle_outline);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: clients.length,
      itemBuilder: (context, index) => ReminderClientCard(
        client: clients[index],
        showDebt: true,
      ),
    );
  }

  Widget _buildExpiringList(RemindersController controller) {
    final expiring = controller.filteredExpiringClients;
    if (expiring.isEmpty) {
      return _buildEmptyState(
          controller.searchQuery.value.isNotEmpty
              ? 'لا يوجد نتائج للبحث'
              : 'لا يوجد اشتراكات قريبة من الانتهاء 👍',
          controller.searchQuery.value.isNotEmpty
              ? Icons.search_off
              : Icons.event_available);
    }

    // Match expiring data with actual client objects
    final allClients = AccountClientInfo.to.clinets;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: expiring.length,
      itemBuilder: (context, index) {
        final data = expiring[index];
        final clientId = data['id'];
        final matchedClient =
            allClients.firstWhereOrNull((c) => c.id == clientId);

        if (matchedClient == null) {
          return _buildExpiringFallbackCard(data);
        }

        return ReminderClientCard(
          client: matchedClient,
          showDebt: false,
        );
      },
    );
  }

  Widget _buildExpiringFallbackCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFFf59e0b), Color(0xFFfbbf24)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.timer, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'عميل',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                if (data['expire_date'] != null)
                  Text(
                    'ينتهي: ${_formatDate(data['expire_date'])}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return date.toString();
    }
  }

  Widget _buildBulkSend(RemindersController controller) {
    final debtClients = controller.debtClients
        .where((c) =>
            c.numbers != null &&
            c.numbers!.isNotEmpty &&
            (c.numbers![0].phoneNumber?.isNotEmpty ?? false))
        .toList();

    if (debtClients.isEmpty) {
      return _buildEmptyState(
          'لا يوجد عملاء بأرقام هواتف للإرسال', Icons.phone_disabled);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF25D366).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF25D366)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'اضغط على نوع الرسالة لفتح WhatsApp لكل عميل واحد واحد.\n'
                    '${debtClients.length} عميل جاهز للإرسال.',
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF1a1a2e)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Bulk action buttons
          ...WhatsAppService.templates.map((template) {
            Color color;
            switch (template.type) {
              case ReminderType.paymentDue:
                color = const Color(0xFFef4444);
                break;
              case ReminderType.subscriptionExpiring:
                color = const Color(0xFFf59e0b);
                break;
              case ReminderType.specialOffer:
                color = const Color(0xFF10b981);
                break;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _startBulkSend(debtClients, template, controller),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(template.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${template.title} لكل العملاء',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: color,
                              ),
                            ),
                            Text(
                              '${debtClients.length} عميل - هيتفتح WhatsApp لكل واحد',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: color),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _startBulkSend(
    List clients,
    MessageTemplate template,
    RemindersController controller,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${template.icon} ${template.title}'),
        content: Text(
          'هيتفتح WhatsApp لـ ${clients.length} عميل واحد واحد.\n'
          'كل مرة هتبعت الرسالة وترجع للتطبيق.\n\nمتأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _executeBulkSend(clients, template, controller);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ابدأ الإرسال',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _executeBulkSend(
    List clients,
    MessageTemplate template,
    RemindersController controller,
  ) async {
    for (final client in clients) {
      final phone = controller.getClientPhone(client);
      if (phone.isEmpty) continue;

      final packages = controller.getClientPackages(client);
      final message = WhatsAppService.buildFromTemplate(
        type: template.type,
        clientName: client.name ?? 'عميل',
        amount: client.totalCash.abs().toStringAsFixed(0),
        date: client.expireDate != null
            ? '${client.expireDate!.day}/${client.expireDate!.month}/${client.expireDate!.year}'
            : 'غير محدد',
        packageName: packages.isNotEmpty ? packages : 'الباقة',
      );

      await WhatsAppService.sendMessage(phoneNumber: phone, message: message);
      // Small delay between opens so user can send each one
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 15, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
