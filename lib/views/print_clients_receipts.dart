import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/widgets.dart' as pw;

class PrintClientsReceipts extends StatelessWidget {
  final List<Client> clients;
  PrintClientsReceipts({super.key, required this.clients});
  final controller = Get.find<AccountClientInfo>();
  late final pw.Font cairoRegular;
  late final pw.Font cairoBold;
  late final pw.Font cairoExtraBold;

  String _getAppropriateMonthName() {
    final now = DateTime.now();
    final collectionDay = AccountClientInfo.to.currentAccount.day;

    if (now.day < collectionDay) {
      if (now.month == 1) return _getArabicMonthName(12);
      return _getArabicMonthName(now.month - 1);
    }
    return _getArabicMonthName(now.month);
  }

  String _getArabicMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'إبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final calculatedMonthName = _getAppropriateMonthName();

    return Scaffold(
      appBar: AppBar(
        title: const Text("عرض سجل الفواتير"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            controller.clientPrintAdded.clear();
            Get.back();
          },
        ),
      ),
      body: kIsWeb
          ? FutureBuilder(
              future: _createPdf(PdfPageFormat.a4),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return PdfPreview(
                    build: (_) => snapshot.data!,
                    pdfFileName: "فاتورة شهر $calculatedMonthName.pdf",
                    onError: (context, error) {
                      Get.showSnackbar(GetSnackBar(
                        title: "مشكلة الطباعة",
                        message: error.toString(),
                      ));
                      return const Text("Error loading PDF");
                    },
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                return const Center(child: CircularProgressIndicator());
              },
            )
          : PdfPreview(
              pdfFileName: "فاتورة شهر $calculatedMonthName.pdf",
              build: _createPdf,
              loadingWidget: CustomIndicator(),
              onError: (context, error) {
                Get.showSnackbar(GetSnackBar(
                  title: "مشكلة الطباعة",
                  message: error.toString(),
                ));
                return const Text("Error");
              },
            ),
    );
  }

  Future<Uint8List> _createPdf(PdfPageFormat format) async {
    final document = pw.Document();

    try {
      // Load assets
      final logo = await getImage("assets/images/rece_bg.jpg");
      final nbLogo = await getImage("assets/images/rece_bg.jpg");
      final vCashIcon = await getImage("assets/images/v_cash_icon.png");
      final instaPayIcon = await getImage("assets/images/instapay_icon.png");

      // Load fonts
      cairoRegular = await PdfGoogleFonts.cairoRegular();
      cairoBold = await PdfGoogleFonts.cairoBold();
      cairoExtraBold = await PdfGoogleFonts.cairoExtraBold();

      // Generate pages
      for (final client in clients) {
        document.addPage(
          pw.Page(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(15),
            build: (context) => _buildPage(
              client: client,
              logo: logo,
              nbLogo: nbLogo,
              vCashIcon: vCashIcon,
              instaPayIcon: instaPayIcon,
            ),
          ),
        );
      }
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        title: 'Error',
        message: e.toString(),
      ));
    }

    return document.save();
  }

  pw.Widget _buildPage({
    required Client client,
    required Uint8List logo,
    required Uint8List nbLogo,
    required Uint8List vCashIcon,
    required Uint8List instaPayIcon,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue900, width: 0.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          // Header with reversed layout
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Logo on left
                pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Image(
                    pw.MemoryImage(logo),
                    width: 60,
                    height: 60,
                    fit: pw.BoxFit.cover,
                  ),
                ),
                // Title on right
                makeText(
                  "فاتورة تحصيل شهر ${_getAppropriateMonthName()}",
                  cairoBold,
                  24.0,
                  PdfColors.white,
                ),
              ],
            ),
          ),

          // Content
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                ..._buildClientInfo(client),
                _buildTransactionsTable(client),
                _buildPaymentMethods(vCashIcon, instaPayIcon, cairoBold),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildClientInfo(Client client) {
    // Calculate total amount
    double totalAmount = clients.fold(
        0.0, (sum, c) => sum + ((c.totalCash < 0.0) ? -c.totalCash : 0.0));

    return [
      // Client name header
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 15),
        child: pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                makeText(client.name!, cairoExtraBold, 16.0, PdfColors.blue900),
                makeText(" سجل المعاملات المالية الخاصة بالسيد   /   ",
                    cairoRegular, 12.0),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoCard("عدد العملاء", "${clients.length}", false),
                  pw.Container(
                    height: 40,
                    width: 1,
                    color: PdfColors.grey300,
                  ),
                  _buildInfoCard("المبلغ المطلوب", "$totalAmount جنيه", true),
                ],
              ),
            ),
          ],
        ),
      ),
      pw.Divider(color: PdfColors.blue200),
      pw.SizedBox(height: 10),
    ];
  }

  pw.Widget _buildInfoCard(String title, String value, bool isHighlighted) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: pw.BoxDecoration(
        color: isHighlighted ? PdfColors.red50 : PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(
          color: isHighlighted ? PdfColors.red300 : PdfColors.blue200,
          width: isHighlighted ? 1.5 : 0.5,
        ),
      ),
      child: pw.Column(
        children: [
          makeText(
            title,
            cairoBold,
            12,
            isHighlighted ? PdfColors.red900 : PdfColors.blue900,
          ),
          pw.SizedBox(height: 6),
          makeText(
            value,
            cairoExtraBold,
            isHighlighted ? 18 : 14,
            isHighlighted ? PdfColors.red900 : PdfColors.blue900,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTransactionsTable(Client client) {
    final startDate = DateTime.now().subtract(const Duration(days: 45));
    final logs = client.logs
            ?.where((log) => log.createdAt?.isAfter(startDate) ?? false)
            .toList() ??
        [];

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        children: [
          // Table header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: const pw.BorderRadius.vertical(
                top: pw.Radius.circular(8),
              ),
            ),
            child: pw.Center(
              child: makeText(
                "المعاملات",
                cairoBold,
                14.0,
                PdfColors.white,
              ),
            ),
          ),

          // Table content
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(
                color: PdfColors.grey300,
                width: 0.5,
              ),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              buildTableHead(
                ["الوقت", "التاريخ", "المبلغ", "نوع التعامل"],
                cairoBold,
                10.0,
              ),
              ...logs.map((log) => buildTableRow([
                    formatTimeToString(log.createdAt ?? DateTime.now()),
                    formatDateToString(log.createdAt ?? DateTime.now()),
                    log.price?.toString() ?? "0",
                    log.systemType ?? "",
                  ], cairoRegular, 9.0)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentMethods(
      Uint8List vCashIcon, Uint8List instaPayIcon, pw.Font font) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      padding: const pw.EdgeInsets.all(15),
      child: pw.Column(
        children: [
          makeText("وسائل الدفع المتاحة", font, 14.0, PdfColors.blue900),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _buildPaymentMethod(
                  vCashIcon, "01022690901", PdfColors.red900, font),
              pw.Container(
                width: 1,
                height: 40,
                color: PdfColors.grey300,
              ),
              _buildPaymentMethod(
                instaPayIcon,
                "01017174149",
                PdfColors.purple900,
                font,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentMethod(
      Uint8List icon, String number, PdfColor color, pw.Font font) {
    return pw.Row(
      children: [
        pw.Image(pw.MemoryImage(icon), width: 50),
        pw.SizedBox(width: 10),
        makeText(number, font, 14.0, color),
      ],
    );
  }

  pw.TableRow buildTableHead(
      List<String> headers, pw.Font font, double fontSize) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius:
            const pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
      ),
      children: [
        for (final head in headers)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: pw.Center(
              child: makeText(head, font, fontSize, PdfColors.white),
            ),
          ),
      ],
    );
  }

  pw.TableRow buildTableRow(List<String> data, pw.Font font, double fontSize) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      children: [
        for (final d in data)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: pw.Center(
              child: makeText(d, font, fontSize),
            ),
          ),
      ],
    );
  }

  static pw.Widget makeText(String text, pw.Font font, double fontSize,
      [PdfColor color = PdfColors.black]) {
    return pw.Text(
      text,
      textDirection: pw.TextDirection.rtl,
      style: pw.TextStyle(font: font, fontSize: fontSize, color: color),
    );
  }

  Future<Uint8List> getImage(String path) async {
    final imageData = await rootBundle.load(path);
    return imageData.buffer.asUint8List();
  }

  String formatDateToString(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String formatTimeToString(DateTime dt, [String lang = "en"]) {
    final time = TimeOfDay.fromDateTime(dt);

    if (lang == "en") {
      return "${time.hourOfPeriod.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ${time.period.name.toUpperCase()}";
    } else {
      return "${time.hourOfPeriod.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ${time.period.name == 'am' ? 'صباحاً' : 'مساءً'}";
    }
  }
}
