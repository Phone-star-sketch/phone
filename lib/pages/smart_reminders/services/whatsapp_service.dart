import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

enum ReminderType {
  paymentDue,
  subscriptionExpiring,
  specialOffer,
}

class MessageTemplate {
  final String title;
  final String icon;
  final ReminderType type;
  final String Function(String clientName,
      {String? amount, String? date, String? packageName}) buildMessage;

  const MessageTemplate({
    required this.title,
    required this.icon,
    required this.type,
    required this.buildMessage,
  });
}

class WhatsAppService {
  static final List<MessageTemplate> templates = [
    MessageTemplate(
      title: 'تذكير دفع',
      icon: '🔴',
      type: ReminderType.paymentDue,
      buildMessage: (clientName, {amount, date, packageName}) =>
          'السلام عليكم يا $clientName 🙏\n'
          'ده تذكير إن عليك مبلغ $amount جنيه.\n'
          'برجاء السداد في أقرب وقت.\n'
          'شكراً لتعاملك معانا ❤️',
    ),
    MessageTemplate(
      title: 'تجديد اشتراك',
      icon: '🟡',
      type: ReminderType.subscriptionExpiring,
      buildMessage: (clientName, {amount, date, packageName}) =>
          'أهلاً يا $clientName 👋\n'
          'اشتراكك ${packageName ?? ""} هينتهي يوم $date.\n'
          'عايز تجدد؟ تواصل معانا.\n'
          'شكراً ليك 🌟',
    ),
    MessageTemplate(
      title: 'عرض خاص',
      icon: '🟢',
      type: ReminderType.specialOffer,
      buildMessage: (clientName, {amount, date, packageName}) =>
          'مبروك يا $clientName 🎉\n'
          'عندنا عرض خاص على باقة ${packageName ?? ""}!\n'
          'السعر: $amount جنيه بس.\n'
          'العرض لفترة محدودة ⏰',
    ),
  ];

  /// Opens WhatsApp with a pre-filled message.
  /// Works on both mobile (app) and web (WhatsApp Web).
  static Future<bool> sendMessage({
    required String phoneNumber,
    required String message,
  }) async {
    // Clean phone number - remove spaces, dashes
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Add Egypt country code if not present
    if (cleaned.startsWith('0')) {
      cleaned = '2$cleaned'; // Egypt: 2 + 0xxxxxxxxxx
    }
    if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }

    final encoded = Uri.encodeComponent(message);
    final url = 'https://wa.me/$cleaned?text=$encoded';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        // Fallback: try without canLaunchUrl check (works better on some devices)
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('WhatsApp launch error: $e');
      return false;
    }
  }

  /// Builds a message from a template with client data
  static String buildFromTemplate({
    required ReminderType type,
    required String clientName,
    String? amount,
    String? date,
    String? packageName,
  }) {
    final template = templates.firstWhere((t) => t.type == type);
    return template.buildMessage(
      clientName,
      amount: amount,
      date: date,
      packageName: packageName,
    );
  }
}
