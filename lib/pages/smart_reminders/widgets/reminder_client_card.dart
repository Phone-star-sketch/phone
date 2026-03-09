import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/pages/smart_reminders/controllers/reminders_controller.dart';
import 'package:phone_system_app/pages/smart_reminders/services/whatsapp_service.dart';

class ReminderClientCard extends StatelessWidget {
  final Client client;
  final bool showDebt;

  const ReminderClientCard({
    super.key,
    required this.client,
    this.showDebt = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RemindersController>();
    final phone = controller.getClientPhone(client);
    final packages = controller.getClientPackages(client);
    final hasPhone = phone.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client info row
            Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: showDebt
                          ? [const Color(0xFFef4444), const Color(0xFFf87171)]
                          : [const Color(0xFFf59e0b), const Color(0xFFfbbf24)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      client.name?[0] ?? '؟',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name & phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name ?? 'بدون اسم',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (hasPhone)
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                // Debt amount
                if (showDebt)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFfef2f2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${client.totalCash.abs().toStringAsFixed(0)} ج.م',
                      style: const TextStyle(
                        color: Color(0xFFef4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            // Packages info
            if (packages.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '📦 $packages',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            // WhatsApp action buttons
            if (hasPhone)
              _buildActionButtons(context, phone, packages)
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_disabled,
                        size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text(
                      'لا يوجد رقم هاتف',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, String phone, String packages) {
    return Row(
      children: WhatsAppService.templates.map((template) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _TemplateButton(
              template: template,
              onTap: () => _sendWhatsApp(context, template, phone, packages),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _sendWhatsApp(
    BuildContext context,
    MessageTemplate template,
    String phone,
    String packages,
  ) async {
    final message = WhatsAppService.buildFromTemplate(
      type: template.type,
      clientName: client.name ?? 'عميل',
      amount: client.totalCash.abs().toStringAsFixed(0),
      date: client.expireDate != null
          ? '${client.expireDate!.day}/${client.expireDate!.month}/${client.expireDate!.year}'
          : 'غير محدد',
      packageName: packages.isNotEmpty ? packages : 'الباقة',
    );

    final success = await WhatsAppService.sendMessage(
      phoneNumber: phone,
      message: message,
    );

    if (!success && context.mounted) {
      Get.showSnackbar(const GetSnackBar(
        message: 'فشل فتح WhatsApp. تأكد إن التطبيق مثبت.',
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFFef4444),
        borderRadius: 10,
        margin: EdgeInsets.all(12),
      ));
    }
  }
}

class _TemplateButton extends StatelessWidget {
  final MessageTemplate template;
  final VoidCallback onTap;

  const _TemplateButton({required this.template, required this.onTap});

  Color get _color {
    switch (template.type) {
      case ReminderType.paymentDue:
        return const Color(0xFFef4444);
      case ReminderType.subscriptionExpiring:
        return const Color(0xFFf59e0b);
      case ReminderType.specialOffer:
        return const Color(0xFF10b981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(template.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              template.title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
