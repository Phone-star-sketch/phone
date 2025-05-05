import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/profit.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';

class PdfService {
  static String _getAppropriateMonthName() {
    final now = DateTime.now();
    final collectionDay = AccountClientInfo.to.currentAccount.day;

    // If we're before collection day, use previous month
    if (now.day < collectionDay) {
      // If it's January, go to previous year's December
      if (now.month == 1) {
        return _getArabicMonthName(12);
      }
      return _getArabicMonthName(now.month - 1);
    }

    // If we're on or after collection day, use current month
    return _getArabicMonthName(now.month);
  }

  static String _getArabicMonthName(int month) {
    final months = [
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

  static Future<void> generateProfitReport(
      MonthlyProfit profit, String _) async {
    // Use the calculated month name instead of the passed parameter
    final monthName = _getAppropriateMonthName();

    // Load and register Arabic fonts
    final arabicFont =
        await rootBundle.load("assets/fonts/cairo/Cairo-Regular.ttf");
    final arabicBoldFont =
        await rootBundle.load("assets/fonts/cairo/Cairo-Bold.ttf");

    final ttf = pw.Font.ttf(arabicFont);
    final ttfBold = pw.Font.ttf(arabicBoldFont);

    final pdf = pw.Document();

    try {
      final logoImage = pw.MemoryImage(
        (await rootBundle.load('assets/images/nb_logo.png'))
            .buffer
            .asUint8List(),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: ttf,
            bold: ttfBold,
          ),
          textDirection: pw.TextDirection.rtl, // Set default text direction
          build: (pw.Context context) {
            return pw.Container(
              padding: pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [
                    PdfColor.fromHex('#F5F5F5'),
                    PdfColor.fromHex('#FFFFFF')
                  ],
                  begin: pw.Alignment.topCenter,
                  end: pw.Alignment.bottomCenter,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // Header with logo
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Image(logoImage, width: 60, height: 60),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'تقرير الأرباح',
                            style: pw.TextStyle(
                              font: ttfBold,
                              fontSize: 24,
                            ),
                          ),
                          pw.Text(
                            'شهر $monthName',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 20),

                  _buildProfitItem(
                    "حساب الشركة قبل الخصم",
                    "${profit.totalIncome.toStringAsFixed(2)} ج.م",
                    PdfColors.blue,
                    ttf,
                    ttfBold,
                  ),
                  _buildProfitItem(
                    "المبلغ المتوقع جمعه",
                    "${profit.expectedToBeCollected.toStringAsFixed(2)} ج.م",
                    PdfColors.green,
                    ttf,
                    ttfBold,
                  ),
                  _buildProfitItem(
                    "حساب الفاتورة بعد الخصم",
                    "${(profit.totalIncome - profit.totalIncome * profit.discount).toStringAsFixed(2)} ج.م",
                    PdfColors.orange,
                    ttf,
                    ttfBold,
                  ),
                  _buildProfitItem(
                    "صافي الربح الشهري",
                    "${(profit.expectedToBeCollected - (profit.totalIncome - profit.totalIncome * profit.discount)).toStringAsFixed(2)} ج.م",
                    PdfColors.purple,
                    ttf,
                    ttfBold,
                  ),

                  // Footer
                  pw.SizedBox(height: 30),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'شكرًا لاستخدامك تطبيقنا',
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final bytes = await pdf.save();

      if (kIsWeb) {
        // Handle web platform
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = 'profit_report_$monthName.pdf';
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        // Handle native platform (Android, iOS, etc.)
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/profit_report_$monthName.pdf');
        await file.writeAsBytes(bytes);
        await OpenFile.open(file.path);
      }
    } catch (e) {
      print('Error generating PDF: $e');
      rethrow;
    }
  }

  static pw.Widget _buildProfitItem(
    String title,
    String value,
    PdfColor color,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 16),
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.grey300,
            blurRadius: 5,
            offset: PdfPoint(0, 2),
          ),
        ],
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 16,
                color: color,
              ),
              textDirection: pw.TextDirection.rtl,
              maxLines: 2,
              softWrap: true,
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 16,
                color: PdfColors.black,
              ),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.left,
              maxLines: 2,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
