import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/pages/smart_reminders/services/whatsapp_service.dart';

class WhatsAppSettingsPage extends StatefulWidget {
  const WhatsAppSettingsPage({super.key});

  @override
  State<WhatsAppSettingsPage> createState() => _WhatsAppSettingsPageState();
}

class _WhatsAppSettingsPageState extends State<WhatsAppSettingsPage> {
  bool _isLoading = true;
  List<MessageTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    await WhatsAppService.loadTemplates();
    setState(() {
      _templates = WhatsAppService.templates;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'إعدادات رسائل WhatsApp',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1a1a2e),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF25D366)))
          : _templates.isEmpty
              ? const Center(child: Text('لا يوجد قوالب رسائل'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildInfoCard(),
                    ..._templates.map((t) => _TemplateCard(
                          template: t,
                          onSaved: _loadTemplates,
                        )),
                  ],
                ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF25D366).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF25D366).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF25D366), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'عدّل نص الرسالة لكل نوع تذكير.',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a1a2e)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'المتغيرات المتاحة (هتتبدل تلقائي):',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
                ),
                const SizedBox(height: 4),
                _buildVariableChip('{clientName}', 'اسم العميل'),
                _buildVariableChip('{amount}', 'المبلغ'),
                _buildVariableChip('{date}', 'التاريخ'),
                _buildVariableChip('{packageName}', 'اسم الباقة'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariableChip(String variable, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(variable,
                style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF166534))),
          ),
          const SizedBox(width: 6),
          Text('= $label',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6b7280))),
        ],
      ),
    );
  }
}

/// Helper to convert literal \n from DB to real newlines for display
String _displayText(String text) => text.replaceAll('\\n', '\n');

class _TemplateCard extends StatefulWidget {
  final MessageTemplate template;
  final VoidCallback onSaved;

  const _TemplateCard({required this.template, required this.onSaved});

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard> {
  late TextEditingController _controller;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // Show real newlines in the editor (not literal \n)
    _controller =
        TextEditingController(text: _displayText(widget.template.messageBody));
  }

  @override
  void didUpdateWidget(covariant _TemplateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.template.messageBody != widget.template.messageBody) {
      _controller.text = _displayText(widget.template.messageBody);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.template.type) {
      case ReminderType.paymentDue:
        return const Color(0xFFef4444);
      case ReminderType.subscriptionExpiring:
        return const Color(0xFFf59e0b);
      case ReminderType.specialOffer:
        return const Color(0xFF10b981);
    }
  }

  Future<void> _save() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    // Save as-is (real newlines) - the DB stores real newlines
    final success = await WhatsAppService.updateTemplate(
      widget.template.id,
      _controller.text.trim(),
    );

    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    if (success) {
      widget.onSaved();
      Get.showSnackbar(GetSnackBar(
        message: 'تم حفظ "${widget.template.title}" بنجاح ✅',
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF25D366),
        borderRadius: 10,
        margin: const EdgeInsets.all(12),
      ));
    } else {
      Get.showSnackbar(const GetSnackBar(
        message: 'فشل الحفظ، حاول مرة تانية ❌',
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFFef4444),
        borderRadius: 10,
        margin: EdgeInsets.all(12),
      ));
    }
  }

  void _showPreview() {
    final preview = _displayText(_controller.text)
        .replaceAll('{clientName}', 'أيمن الخولية')
        .replaceAll('{amount}', '58')
        .replaceAll('{date}', '25/4/2026')
        .replaceAll('{packageName}', 'فليكس 70 الجديد');

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1a1a2e),
        title: Row(
          children: [
            const Icon(Icons.chat_bubble, color: Color(0xFF25D366), size: 22),
            const SizedBox(width: 8),
            const Text('معاينة الرسالة',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // WhatsApp-style bubble
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF005C4B),
                borderRadius: BorderRadius.circular(12).copyWith(
                  topRight: const Radius.circular(0),
                ),
              ),
              child: Text(
                preview,
                style: const TextStyle(
                    fontSize: 14, height: 1.7, color: Colors.white),
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ✓✓',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child:
                const Text('إغلاق', style: TextStyle(color: Color(0xFF25D366))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(widget.template.icon,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.template.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: _color,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _showPreview,
                  icon: Icon(Icons.visibility_rounded, color: _color, size: 20),
                  tooltip: 'معاينة',
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _isEditing = !_isEditing;
                    if (_isEditing) {
                      _controller.text =
                          _displayText(widget.template.messageBody);
                    }
                  }),
                  icon: Icon(
                    _isEditing ? Icons.close : Icons.edit_rounded,
                    color: _color,
                    size: 20,
                  ),
                  tooltip: _isEditing ? 'إلغاء' : 'تعديل',
                ),
              ],
            ),
          ),
          // Message body
          Padding(
            padding: const EdgeInsets.all(14),
            child: _isEditing ? _buildEditor() : _buildDisplay(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        TextField(
          controller: _controller,
          maxLines: 10,
          minLines: 5,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 14, height: 1.6),
          decoration: InputDecoration(
            hintText: 'اكتب نص الرسالة هنا...\nاضغط Enter للسطر الجديد',
            hintTextDirection: TextDirection.rtl,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _color),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ التعديلات'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFdcf8c6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _displayText(widget.template.messageBody),
        style: const TextStyle(fontSize: 13, height: 1.6),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
