import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LetterOfWaiver extends StatefulWidget {
  const LetterOfWaiver({Key? key}) : super(key: key);

  @override
  State<LetterOfWaiver> createState() => _LetterOfWaiverState();
}

class _LetterOfWaiverState extends State<LetterOfWaiver> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _recipientNameController =
      TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _waivedPhoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneNumberController.addListener(() {
      _waivedPhoneController.text = _phoneNumberController.text;
    });
  }

  @override
  void dispose() {
    _phoneNumberController.removeListener(() {});
    _phoneNumberController.dispose();
    _recipientNameController.dispose();
    _nationalIdController.dispose();
    _waivedPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.white,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description_outlined,
                        color: Colors.blue[700], size: 32),
                    const SizedBox(width: 12),
                    Text(
                      'خطاب تنازل',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Form Section
              Card(
                elevation: 8,
                shadowColor: Colors.blue.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAnimatedFormField(
                          controller: _phoneNumberController,
                          label: 'المالك للخط رقم',
                          icon: Icons.phone_android,
                          validator: (value) => value?.isEmpty == true
                              ? 'برجاء إدخال رقم الخط'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _buildAnimatedFormField(
                          controller: _recipientNameController,
                          label: 'تفويض للسيد/السيدة',
                          icon: Icons.person,
                          validator: (value) => value?.isEmpty == true
                              ? 'برجاء إدخال اسم المفوض إليه'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _buildAnimatedFormField(
                          controller: _nationalIdController,
                          label: 'بطاقة رقم قومي',
                          icon: Icons.credit_card,
                          validator: (value) => value?.isEmpty == true
                              ? 'برجاء إدخال الرقم القومي'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _buildAnimatedFormField(
                          controller: _waivedPhoneController,
                          label: 'للتنازل عن خط رقم',
                          icon: Icons.phone_forwarded,
                          validator: (value) => value?.isEmpty == true
                              ? 'برجاء إدخال رقم الخط المتنازل عنه'
                              : null,
                        ),
                        const SizedBox(height: 32),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: Colors.blue[700]),
      ),
      validator: validator,
      style: const TextStyle(fontSize: 16),
      selectionControls: MaterialTextSelectionControls(),
      cursorColor: Colors.blue[700],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: _isLoading
            ? null
            : () async {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _isLoading = true;
                  });
                  try {
                    // Generate and handle the PDF
                    await _generatePDF();
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'إنشاء خطاب التنازل',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String convertToArabicNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicBoldFont = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Header
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Container(
                      width: 200, // Fixed width for the underline
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(width: 1),
                        ),
                      ),
                      child: pw.Text(
                        'السادة / شركـة فودافـون',
                        style: pw.TextStyle(
                          font: arabicBoldFont,
                          fontSize: 18,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Greeting
                  pw.Center(
                    child: pw.Text(
                      'تحية طيبه وبعد ،،،',
                      style: pw.TextStyle(font: arabicBoldFont, fontSize: 16),
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Body content with consistent spacing
                  pw.Text(
                    'يرجي التكرم الإحاطة بالعلم بأننا شركة : محمد السيد عبد المجيد',
                    style: pw.TextStyle(font: arabicBoldFont, fontSize: 14),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'المشهرة بسجل ضريبي رقم : ${convertToArabicNumbers("478-466-477")}',
                    style: pw.TextStyle(font: arabicBoldFont, fontSize: 14),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'و المالكـة للخــط رقم : ${convertToArabicNumbers(_phoneNumberController.text)}',
                    style: pw.TextStyle(font: arabicBoldFont, fontSize: 14),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'بأننا قد فوضنا السيد - ة / ${_recipientNameController.text}',
                    style: pw.TextStyle(font: arabicBoldFont, fontSize: 14),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'بطاقة رقم قومي : ${convertToArabicNumbers(_nationalIdController.text)}',
                    style: pw.TextStyle(font: arabicBoldFont, fontSize: 14),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'للتنازل عن الخط رقم : ${convertToArabicNumbers(_waivedPhoneController.text)}',
                    style: pw.TextStyle(font: arabicBoldFont, fontSize: 14),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'لنفسه و كمـا تقرر الشركه بأنها قـد قامت بسداد جميع المستحقات المتعلقة بالخط المذكور عاليه قبل تاريخ هذا الإقرار كما نقر بموافقتنا علي الأعمال السابق ذكرها وأنه لا يجوز لنا الرجوع في اى عمـل مــن الأعمال المتضمنة في هذا الإقرار.',
                    style: pw.TextStyle(
                        font: arabicBoldFont, fontSize: 14, letterSpacing: 0),
                  ),
                  pw.SizedBox(height: 40),

                  // Signature section
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'إسم المفوض الأصلي :',
                        style: pw.TextStyle(font: arabicBoldFont, fontSize: 14),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Container(
                            child: pw.Text(
                              'التوقيع : إسلام محمد عبد الرسول النني               ',
                              style: pw.TextStyle(
                                  font: arabicBoldFont, fontSize: 14),
                            ),
                          ),
                          pw.Text(
                            'توقيع المفوض بموجب هذا الإقرار ،،،',
                            style: pw.TextStyle(
                                font: arabicBoldFont, fontSize: 14),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'التاريخ     /      /    ٢٠٢ ',
                        style: pw.TextStyle(font: arabicBoldFont, fontSize: 14),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          'خاتم الشركه المفوضة:',
                          style:
                              pw.TextStyle(font: arabicBoldFont, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final Uint8List pdfData = await pdf.save();

    final dateStr = DateFormat('yyyy_MM_dd').format(DateTime.now());
    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: pdfData,
        filename: 'خطاب_تنازل_$dateStr.pdf',
      );
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/خطاب_تنازل_$dateStr.pdf';
      final File file = File(filePath);
      await file.writeAsBytes(pdfData);
      await OpenFile.open(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء خطاب التنازل بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
