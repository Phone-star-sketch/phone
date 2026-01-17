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
        pdfFileName:
            'تقرير_${client.name ?? "عميل"}_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}.pdf',
        build: _createPdf,
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
        onError: (context, error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('حدث خطأ: ${error.toString()}'),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Uint8List> _createPdf(PdfPageFormat format) async {
    final document = pw.Document();

    // Load fonts and logo in parallel for better performance
    final results = await Future.wait([
      PdfGoogleFonts.cairoRegular(),
      PdfGoogleFonts.cairoBold(),
      PdfGoogleFonts.cairoExtraBold(),
      _getImage('assets/images/bg-logo.png').catchError((_) => Uint8List(0)),
    ]);

    final cairoRegular = results[0] as pw.Font;
    final cairoBold = results[1] as pw.Font;
    final cairoExtraBold = results[2] as pw.Font;
    final logoData = results[3] as Uint8List;
    final logo = logoData.isNotEmpty ? logoData : null;

    // Get data
    final clientLogs = logs ?? _getClientLogs();
    final clientSystems = systems ?? _getClientSystems();

    // Limit logs to last 100 for performance
    final limitedLogs =
        clientLogs.length > 100 ? clientLogs.sublist(0, 100) : clientLogs;

    // Colors
    const primaryColor = PdfColor.fromInt(0xFF3b82f6);
    const successColor = PdfColor.fromInt(0xFF10b981);
    const dangerColor = PdfColor.fromInt(0xFFef4444);
    const warningColor = PdfColor.fromInt(0xFFf59e0b);

    // Page format
    final pageFormat = format.copyWith(
      marginTop: 30,
      marginBottom: 30,
      marginLeft: 30,
      marginRight: 30,
    );

    // Add main page
    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        textDirection: pw.TextDirection.rtl,
        header: (context) =>
            _buildHeader(logo, cairoBold, cairoExtraBold, primaryColor),
        footer: (context) =>
            _buildFooter(cairoRegular, context.pageNumber, context.pagesCount),
        build: (context) => [
          // Client Info Card
          _buildClientInfoCard(
              cairoBold, cairoRegular, primaryColor, successColor, dangerColor),
          pw.SizedBox(height: 20),

          // Systems Section
          if (clientSystems.isNotEmpty) ...[
            _buildSectionTitle('الباقات المشترك بها', cairoBold, warningColor),
            pw.SizedBox(height: 10),
            _buildSystemsTable(
                clientSystems, cairoBold, cairoRegular, warningColor),
            pw.SizedBox(height: 20),
          ],

          // Logs Section
          _buildSectionTitle('سجل المعاملات', cairoBold, primaryColor),
          pw.SizedBox(height: 10),
          if (limitedLogs.isEmpty)
            _buildEmptyState('لا توجد معاملات مسجلة', cairoRegular)
          else ...[
            _buildLogsTable(limitedLogs, cairoBold, cairoRegular, successColor,
                dangerColor),
            if (clientLogs.length > 100)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 10),
                child: pw.Text(
                  'تم عرض آخر 100 معاملة فقط من أصل ${clientLogs.length}',
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

          // Summary Section
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
            pw.ClipRRect(
              horizontalRadius: 30,
              verticalRadius: 30,
              child: pw.Image(
                pw.MemoryImage(logo),
                width: 60,
                height: 60,
                fit: pw.BoxFit.cover,
              ),
            )
          else
            pw.Container(width: 60),
          pw.Column(
            children: [
              pw.Text(
                'تقرير العميل الشامل',
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(
                    font: extraBoldFont, fontSize: 20, color: primaryColor),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _formatDate(DateTime.now()),
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(
                    font: boldFont, fontSize: 12, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Container(width: 60),
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
            style: pw.TextStyle(
                font: font, fontSize: 10, color: PdfColors.grey500),
          ),
          pw.Text(
            'تم الإنشاء بواسطة نظام إدارة العملاء',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
                font: font, fontSize: 10, color: PdfColors.grey500),
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
    final statusText =
        cash > 0 ? 'رصيد إيجابي' : (cash < 0 ? 'مديونية' : 'متوازن');

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: primaryColor, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // Name and Status Row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: statusColor,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  statusText,
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                      font: boldFont, fontSize: 10, color: PdfColors.white),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  client.name ?? 'غير محدد',
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                      font: boldFont, fontSize: 18, color: primaryColor),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 15),

          // Info Grid
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem('الرصيد', '${cash.abs().toStringAsFixed(0)} ج.م',
                  boldFont, regularFont, statusColor),
              _buildInfoItem('رقم الهاتف', client.getFormattedPhoneNumber(),
                  boldFont, regularFont, primaryColor),
              _buildInfoItem('الرقم القومي', client.nationalId ?? 'غير متوفر',
                  boldFont, regularFont, primaryColor),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem('العنوان', client.address ?? 'غير متوفر', boldFont,
                  regularFont, primaryColor),
              _buildInfoItem(
                  'تاريخ التسجيل',
                  client.createdAt != null
                      ? _formatDate(client.createdAt!)
                      : 'غير محدد',
                  boldFont,
                  regularFont,
                  primaryColor),
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

  pw.Widget _buildSectionTitle(String title, pw.Font font, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            title,
            textDirection: pw.TextDirection.rtl,
            style:
                pw.TextStyle(font: font, fontSize: 14, color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSystemsTable(List<System> systems, pw.Font boldFont,
      pw.Font regularFont, PdfColor headerColor) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: [
            _buildTableCell('السعر', boldFont, 11, PdfColors.white,
                isHeader: true),
            _buildTableCell('تاريخ الاشتراك', boldFont, 11, PdfColors.white,
                isHeader: true),
            _buildTableCell('اسم الباقة', boldFont, 11, PdfColors.white,
                isHeader: true),
          ],
        ),
        // Data rows
        ...systems.map((system) => pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.white),
              children: [
                _buildTableCell(
                    '${system.type?.price?.toStringAsFixed(0) ?? "0"} ج.م',
                    regularFont,
                    10,
                    PdfColors.black),
                _buildTableCell(
                    system.createdAt != null
                        ? _formatDate(system.createdAt!)
                        : '-',
                    regularFont,
                    10,
                    PdfColors.black),
                _buildTableCell(system.type?.name ?? 'غير محدد', regularFont,
                    10, PdfColors.black),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildLogsTable(List<Log> logs, pw.Font boldFont,
      pw.Font regularFont, PdfColor successColor, PdfColor dangerColor) {
    // Build table rows efficiently
    final tableRows = <pw.TableRow>[
      // Header
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF3b82f6)),
        children: [
          _buildTableCell('المبلغ', boldFont, 11, PdfColors.white,
              isHeader: true),
          _buildTableCell('الوقت', boldFont, 11, PdfColors.white,
              isHeader: true),
          _buildTableCell('التاريخ', boldFont, 11, PdfColors.white,
              isHeader: true),
          _buildTableCell('نوع المعاملة', boldFont, 11, PdfColors.white,
              isHeader: true),
        ],
      ),
    ];

    // Add data rows
    for (var log in logs) {
      final isAddition = log.transactionType == TransactionType.addition ||
          log.transactionType == TransactionType.moneyAdded;
      final amountColor = isAddition ? dangerColor : successColor;

      tableRows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            _buildTableCell('${log.price.toStringAsFixed(0)} ج.م', regularFont,
                10, amountColor),
            _buildTableCell(
                log.createdAt != null ? _formatTime(log.createdAt!) : '-',
                regularFont,
                10,
                PdfColors.black),
            _buildTableCell(
                log.createdAt != null ? _formatDate(log.createdAt!) : '-',
                regularFont,
                10,
                PdfColors.black),
            _buildTableCell(
                _getTransactionTypeName(log), regularFont, 10, PdfColors.black),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(2),
      },
      children: tableRows,
    );
  }

  pw.Widget _buildTableCell(
      String text, pw.Font font, double fontSize, PdfColor color,
      {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
    // Calculate totals
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
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: primaryColor, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'ملخص الحساب',
            textDirection: pw.TextDirection.rtl,
            style:
                pw.TextStyle(font: boldFont, fontSize: 16, color: primaryColor),
          ),
          pw.SizedBox(height: 15),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                  'إجمالي المضاف',
                  '${totalAdded.toStringAsFixed(0)} ج.م',
                  boldFont,
                  regularFont,
                  dangerColor),
              pw.Container(width: 1, height: 40, color: PdfColors.grey300),
              _buildSummaryItem(
                  'إجمالي المسدد',
                  '${totalPaid.toStringAsFixed(0)} ج.م',
                  boldFont,
                  regularFont,
                  successColor),
              pw.Container(width: 1, height: 40, color: PdfColors.grey300),
              _buildSummaryItem('عدد المعاملات', '${logs.length}', boldFont,
                  regularFont, primaryColor),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 15),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: (client.totalCash ?? 0) >= 0 ? successColor : dangerColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  '${(client.totalCash ?? 0).abs().toStringAsFixed(0)} ج.م',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                      font: boldFont, fontSize: 18, color: PdfColors.white),
                ),
                pw.SizedBox(width: 10),
                pw.Text(
                  (client.totalCash ?? 0) >= 0
                      ? 'الرصيد الحالي:'
                      : 'المديونية الحالية:',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                      font: regularFont, fontSize: 14, color: PdfColors.white),
                ),
              ],
            ),
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
              font: regularFont, fontSize: 11, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          value,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(font: boldFont, fontSize: 14, color: color),
        ),
      ],
    );
  }

  pw.Widget _buildEmptyState(String message, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(30),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Center(
        child: pw.Text(
          message,
          textDirection: pw.TextDirection.rtl,
          style:
              pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey500),
        ),
      ),
    );
  }

  // Helper methods
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

  Future<Uint8List> _getImage(String path) async {
    final imageData = await rootBundle.load(path);
    return imageData.buffer.asUint8List();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour =
        date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'م' : 'ص';
    return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
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
