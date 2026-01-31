import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/controllers/client_bottom_sheet_controller.dart';
import 'package:phone_system_app/views/pages/all_clinets_page.dart';

class PrintClientFullReport extends StatelessWidget {
  final Client client;
  final List<Log>? logs;
  final List<System>? systems;

  const PrintClientFullReport({
    super.key,
    required this.client,
    this.logs,
    this.systems,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تقرير ${client.name ?? "العميل"}'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3b82f6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PdfPreview(
        build: _createPdf,
        pdfFileName:
            'تقرير_${client.name ?? "عميل"}_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}.pdf',
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        maxPageWidth: 700,
        loadingWidget: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF3b82f6)),
              SizedBox(height: 16),
              Text('جاري إنشاء التقرير...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _createPdf(PdfPageFormat format) async {
    final document = pw.Document(
      compress: true, // Enable compression for smaller file size
    );

    // Load fonts from assets (much faster than PdfGoogleFonts)
    final cairoRegular =
        await _loadFontFromAssets('assets/fonts/cairo/Cairo-Regular.ttf');
    final cairoBold =
        await _loadFontFromAssets('assets/fonts/cairo/Cairo-Bold.ttf');
    final cairoExtraBold =
        await _loadFontFromAssets('assets/fonts/cairo/Cairo-ExtraBold.ttf');

    // Load logo (optional - skip if fails)
    Uint8List? logo;
    try {
      logo = await _getCachedLogo();
    } catch (_) {
      logo = null;
    }

    // Get data
    final clientLogs = logs ?? _getClientLogs();
    final clientSystems = systems ?? _getClientSystems();

    // Limit logs to last 15 for better performance
    final limitedLogs =
        clientLogs.length > 15 ? clientLogs.sublist(0, 15) : clientLogs;

    // Colors
    const primaryColor = PdfColor.fromInt(0xFF3b82f6);
    const successColor = PdfColor.fromInt(0xFF10b981);
    const dangerColor = PdfColor.fromInt(0xFFef4444);
    const warningColor = PdfColor.fromInt(0xFFf59e0b);

    // Add main page
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        textDirection: pw.TextDirection.rtl,
        header: (context) =>
            _buildHeader(logo, cairoBold, cairoExtraBold, primaryColor),
        footer: (context) =>
            _buildFooter(cairoRegular, context.pageNumber, context.pagesCount),
        build: (context) => [
          // Client Info
          _buildClientInfoCard(
              cairoBold, cairoRegular, primaryColor, successColor, dangerColor),
          pw.SizedBox(height: 20),

          // Systems
          if (clientSystems.isNotEmpty) ...[
            _buildSectionTitle('الباقات المشترك بها', cairoBold, warningColor),
            pw.SizedBox(height: 10),
            _buildSystemsTable(
                clientSystems, cairoBold, cairoRegular, warningColor),
            pw.SizedBox(height: 20),
          ],

          // Logs
          _buildSectionTitle('سجل المعاملات', cairoBold, primaryColor),
          pw.SizedBox(height: 10),
          if (limitedLogs.isEmpty)
            _buildEmptyState('لا توجد معاملات مسجلة', cairoRegular)
          else ...[
            _buildLogsTable(limitedLogs, cairoBold, cairoRegular, successColor,
                dangerColor),
            if (clientLogs.length > 15)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 10),
                child: pw.Text(
                  'تم عرض آخر 15 معاملة فقط من أصل ${clientLogs.length}',
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      font: cairoRegular,
                      fontSize: 10,
                      color: PdfColors.grey600),
                ),
              ),
          ],

          pw.SizedBox(height: 20),

          // Summary
          _buildSummaryCard(clientLogs, cairoBold, cairoRegular, primaryColor,
              successColor, dangerColor),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _buildHeader(Uint8List? logo, pw.Font boldFont,
      pw.Font extraBoldFont, PdfColor primaryColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 15),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (logo != null)
            pw.Image(pw.MemoryImage(logo), width: 50, height: 50)
          else
            pw.Container(width: 50),
          pw.Column(
            children: [
              pw.Text(
                'تقرير العميل',
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(
                    font: extraBoldFont, fontSize: 18, color: primaryColor),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _formatDate(DateTime.now()),
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(
                    font: boldFont, fontSize: 11, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Container(width: 50),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Font font, int pageNumber, int totalPages) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border:
            pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'صفحة $pageNumber من $totalPages',
            textDirection: pw.TextDirection.rtl,
            style:
                pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500),
          ),
          pw.Text(
            'نظام إدارة العملاء',
            textDirection: pw.TextDirection.rtl,
            style:
                pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClientInfoCard(pw.Font boldFont, pw.Font regularFont,
      PdfColor primaryColor, PdfColor successColor, PdfColor dangerColor) {
    final cash = client.totalCash ?? 0;
    final statusColor =
        cash > 0 ? successColor : (cash < 0 ? dangerColor : PdfColors.grey600);

    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: primaryColor, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            client.name ?? 'غير محدد',
            textDirection: pw.TextDirection.rtl,
            style:
                pw.TextStyle(font: boldFont, fontSize: 16, color: primaryColor),
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem('الرصيد', '${cash.abs().toStringAsFixed(0)} ج.م',
                  boldFont, regularFont, statusColor),
              _buildInfoItem('الهاتف', client.getFormattedPhoneNumber(),
                  boldFont, regularFont, primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoItem(String label, String value, pw.Font boldFont,
      pw.Font regularFont, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(
              font: regularFont, fontSize: 9, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(font: boldFont, fontSize: 11, color: color),
        ),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title, pw.Font font, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        title,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.white),
      ),
    );
  }

  pw.Widget _buildSystemsTable(List<System> systems, pw.Font boldFont,
      pw.Font regularFont, PdfColor headerColor) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: [
            _buildTableCell('السعر', boldFont, 10, PdfColors.white),
            _buildTableCell('التاريخ', boldFont, 10, PdfColors.white),
            _buildTableCell('الباقة', boldFont, 10, PdfColors.white),
          ],
        ),
        ...systems.map((system) => pw.TableRow(
              children: [
                _buildTableCell(
                    '${system.type?.price?.toStringAsFixed(0) ?? "0"} ج.م',
                    regularFont,
                    9,
                    PdfColors.black),
                _buildTableCell(
                    system.createdAt != null
                        ? _formatDate(system.createdAt!)
                        : '-',
                    regularFont,
                    9,
                    PdfColors.black),
                _buildTableCell(system.type?.name ?? 'غير محدد', regularFont, 9,
                    PdfColors.black),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildLogsTable(List<Log> logs, pw.Font boldFont,
      pw.Font regularFont, PdfColor successColor, PdfColor dangerColor) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFF3b82f6)),
          children: [
            _buildTableCell('المبلغ', boldFont, 10, PdfColors.white),
            _buildTableCell('التاريخ', boldFont, 10, PdfColors.white),
            _buildTableCell('النوع', boldFont, 10, PdfColors.white),
          ],
        ),
        ...logs.map((log) {
          final isAddition = log.transactionType == TransactionType.addition ||
              log.transactionType == TransactionType.moneyAdded;
          return pw.TableRow(
            children: [
              _buildTableCell('${log.price.toStringAsFixed(0)} ج.م',
                  regularFont, 9, isAddition ? dangerColor : successColor),
              _buildTableCell(
                  log.createdAt != null ? _formatDate(log.createdAt!) : '-',
                  regularFont,
                  9,
                  PdfColors.black),
              _buildTableCell(_getTransactionTypeName(log), regularFont, 9,
                  PdfColors.black),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableCell(
      String text, pw.Font font, double fontSize, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: fontSize, color: color),
      ),
    );
  }

  pw.Widget _buildSummaryCard(
      List<Log> logs,
      pw.Font boldFont,
      pw.Font regularFont,
      PdfColor primaryColor,
      PdfColor successColor,
      PdfColor dangerColor) {
    double totalAdded = 0;
    double totalPaid = 0;

    for (var log in logs) {
      if (log.transactionType == TransactionType.addition ||
          log.transactionType == TransactionType.moneyAdded) {
        totalAdded += log.price;
      } else {
        totalPaid += log.price;
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: primaryColor, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'ملخص الحساب',
            textDirection: pw.TextDirection.rtl,
            style:
                pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('المضاف', '${totalAdded.toStringAsFixed(0)}',
                  boldFont, regularFont, dangerColor),
              _buildSummaryItem('المسدد', '${totalPaid.toStringAsFixed(0)}',
                  boldFont, regularFont, successColor),
              _buildSummaryItem(
                  'الرصيد',
                  '${(client.totalCash ?? 0).abs().toStringAsFixed(0)}',
                  boldFont,
                  regularFont,
                  (client.totalCash ?? 0) >= 0 ? successColor : dangerColor),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value, pw.Font boldFont,
      pw.Font regularFont, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(
              font: regularFont, fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(font: boldFont, fontSize: 12, color: color),
        ),
      ],
    );
  }

  pw.Widget _buildEmptyState(String message, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      child: pw.Text(
        message,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey500),
      ),
    );
  }

  // Helper methods
  static final Map<String, pw.Font> _fontCache = {};
  static Uint8List? _logoCache;

  // Load font from assets (MUCH faster than PdfGoogleFonts)
  Future<pw.Font> _loadFontFromAssets(String path) async {
    if (_fontCache.containsKey(path)) {
      return _fontCache[path]!;
    }

    final fontData = await rootBundle.load(path);
    final font = pw.Font.ttf(fontData);

    _fontCache[path] = font;
    return font;
  }

  Future<Uint8List?> _getCachedLogo() async {
    if (_logoCache != null) {
      return _logoCache;
    }

    try {
      final imageData = await rootBundle.load('assets/images/newlogo.png');
      _logoCache = imageData.buffer.asUint8List();
      return _logoCache;
    } catch (_) {
      return null;
    }
  }

  List<Log> _getClientLogs() {
    try {
      if (Get.isRegistered<ClientBottomSheetController>()) {
        return Get.find<ClientBottomSheetController>().getClientLogs() ?? [];
      }
    } catch (_) {}
    return client.logs ?? [];
  }

  List<System> _getClientSystems() {
    try {
      if (Get.isRegistered<ClientBottomSheetController>()) {
        return Get.find<ClientBottomSheetController>().getClientSystems() ?? [];
      }
    } catch (_) {}

    List<System> allSystems = [];
    if (client.systems != null) allSystems.addAll(client.systems!);
    if (client.numbers != null) {
      for (var number in client.numbers!) {
        if (number.systems != null) allSystems.addAll(number.systems!);
      }
    }
    return allSystems;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getTransactionTypeName(Log log) {
    if (log.systemType.isNotEmpty) return log.systemType;

    switch (log.transactionType) {
      case TransactionType.addition:
        return 'إضافة مبلغ';
      case TransactionType.moneyAdded:
        return 'إيداع';
      case TransactionType.payment:
        return 'تسديد';
      default:
        return 'معاملة';
    }
  }
}

// Function to show print dialog
Future<void> showPrintClientReport(BuildContext context, Client client,
    {List<Log>? logs, List<System>? systems}) async {
  Get.to(() => PrintClientFullReport(
        client: client,
        logs: logs,
        systems: systems,
      ));
}
