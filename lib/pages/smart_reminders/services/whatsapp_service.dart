import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

enum ReminderType {
  paymentDue,
  subscriptionExpiring,
  specialOffer,
}

class MessageTemplate {
  final String id;
  final String templateKey;
  final String title;
  final String icon;
  final ReminderType type;
  final String messageBody;

  const MessageTemplate({
    required this.id,
    required this.templateKey,
    required this.title,
    required this.icon,
    required this.type,
    required this.messageBody,
  });

  /// Builds the final message by replacing placeholders
  String buildMessage(String clientName,
      {String? amount, String? date, String? packageName}) {
    // Replace literal \n (from DB) with real newlines, then replace placeholders
    return messageBody
        .replaceAll('\\n', '\n')
        .replaceAll('{clientName}', clientName)
        .replaceAll('{amount}', amount ?? '')
        .replaceAll('{date}', date ?? '')
        .replaceAll('{packageName}', packageName ?? '');
  }

  factory MessageTemplate.fromJson(Map<String, dynamic> json) {
    return MessageTemplate(
      id: json['id'] ?? '',
      templateKey: json['template_key'] ?? '',
      title: json['title'] ?? '',
      icon: json['icon'] ?? '📩',
      type: _typeFromKey(json['template_key'] ?? ''),
      messageBody: json['message_body'] ?? '',
    );
  }

  static ReminderType _typeFromKey(String key) {
    switch (key) {
      case 'payment_due':
        return ReminderType.paymentDue;
      case 'subscription_expiring':
        return ReminderType.subscriptionExpiring;
      case 'special_offer':
        return ReminderType.specialOffer;
      default:
        return ReminderType.paymentDue;
    }
  }
}

class WhatsAppService {
  static List<MessageTemplate> templates = [];

  /// Load templates from Supabase
  static Future<void> loadTemplates() async {
    try {
      final result = await Supabase.instance.client
          .from('whatsapp_templates')
          .select()
          .eq('is_active', true)
          .order('created_at');

      templates =
          (result as List).map((e) => MessageTemplate.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode) print('Error loading WhatsApp templates: $e');
      // Fallback to defaults if DB fails
      if (templates.isEmpty) _loadDefaults();
    }
  }

  static void _loadDefaults() {
    templates = [
      MessageTemplate(
        id: '',
        templateKey: 'payment_due',
        title: 'تذكير دفع',
        icon: '🔴',
        type: ReminderType.paymentDue,
        messageBody:
            'السلام عليكم\nأ/ {clientName}\nنود تذكير حضرتكم بوجود مبلغ مستحق {amount} جنيه.\nيرجى التكرم بالسداد في أقرب وقت مناسب لسيادتكم.\nشاكرين ثقتكم وتعاملكم معنا.',
      ),
      MessageTemplate(
        id: '',
        templateKey: 'subscription_expiring',
        title: 'تجديد اشتراك',
        icon: '🟡',
        type: ReminderType.subscriptionExpiring,
        messageBody:
            'أهلاً يا {clientName} 👋\nاشتراكك {packageName} هينتهي يوم {date}.\nعايز تجدد؟ تواصل معانا.\nشكراً ليك 🌟',
      ),
      MessageTemplate(
        id: '',
        templateKey: 'special_offer',
        title: 'عرض خاص',
        icon: '🟢',
        type: ReminderType.specialOffer,
        messageBody:
            'مبروك يا {clientName} 🎉\nعندنا عرض خاص على باقة {packageName}!\nالسعر: {amount} جنيه بس.\nالعرض لفترة محدودة ⏰',
      ),
    ];
  }

  /// Update a template in Supabase
  static Future<bool> updateTemplate(String id, String newMessageBody) async {
    try {
      await Supabase.instance.client.from('whatsapp_templates').update({
        'message_body': newMessageBody,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      // Reload after update
      await loadTemplates();
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating template: $e');
      return false;
    }
  }

  /// Manually encode text for WhatsApp URL.
  /// This avoids double-encoding issues on Flutter Web and
  /// properly handles emoji + newlines for WhatsApp Web/Mobile.
  static String _encodeForWhatsApp(String text) {
    final buffer = StringBuffer();
    // Encode each code unit properly
    for (final codeUnit in utf8.encode(text)) {
      if ((codeUnit >= 0x41 && codeUnit <= 0x5A) || // A-Z
          (codeUnit >= 0x61 && codeUnit <= 0x7A) || // a-z
          (codeUnit >= 0x30 && codeUnit <= 0x39) || // 0-9
          codeUnit == 0x2D || // -
          codeUnit == 0x5F || // _
          codeUnit == 0x2E || // .
          codeUnit == 0x21 || // !
          codeUnit == 0x7E || // ~
          codeUnit == 0x2A || // *
          codeUnit == 0x27) {
        // '
        buffer.writeCharCode(codeUnit);
      } else if (codeUnit == 0x20) {
        buffer.write('%20');
      } else if (codeUnit == 0x0A) {
        // newline → %0A
        buffer.write('%0A');
      } else if (codeUnit == 0x0D) {
        // carriage return → skip
        continue;
      } else {
        buffer.write(
            '%${codeUnit.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      }
    }
    return buffer.toString();
  }

  /// Opens WhatsApp with a pre-filled message.
  static Future<bool> sendMessage({
    required String phoneNumber,
    required String message,
  }) async {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '2$cleaned';
    }
    if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }

    // Use api.whatsapp.com/send instead of wa.me
    // wa.me has a known bug where emoji get corrupted in the text parameter
    // api.whatsapp.com/send handles emoji + newlines correctly
    final encoded = _encodeForWhatsApp(message);
    final urlString =
        'https://api.whatsapp.com/send?phone=$cleaned&text=$encoded';

    try {
      final uri = Uri.parse(urlString);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
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
    // Ensure templates are loaded
    if (templates.isEmpty) _loadDefaults();

    final template = templates.firstWhere((t) => t.type == type,
        orElse: () => templates.first);
    return template.buildMessage(
      clientName,
      amount: amount,
      date: date,
      packageName: packageName,
    );
  }
}
