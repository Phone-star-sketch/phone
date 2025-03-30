import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';
import 'package:printing/printing.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PrintClientsReceipts extends StatelessWidget {
  List<Client> clients;
  PrintClientsReceipts({super.key, required this.clients});
  final controller = Get.find<AccountClientInfo>();

  String _getAppropriateMonthName() {
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

  String _getArabicMonthName(int month) {
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'إبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return months[month - 1];
  }

  (int month, int year) getPreviousMonthAndYear() {
    final now = DateTime.now();
    final collectionDay = AccountClientInfo.to.currentAccount.day;

    if (now.day < collectionDay) {
      if (now.month == 1) {
        return (12, now.year - 1);
      }
      return (now.month - 1, now.year);
    }
    return (now.month, now.year);
  }

  bool hasPaymentForMonth(Client client, int month, int year) {
    return client.logs!.any((log) =>
        log.createdAt!.year == year &&
        log.createdAt!.month == month &&
        log.systemType == "تسديد" &&
        log.price > 0);
  }

  @override
  Widget build(BuildContext context) {
    final calculatedMonthName = _getAppropriateMonthName();

    return Scaffold(
      appBar: AppBar(
        title: const Text("عرض سجل الفواتير"),
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                controller.clientPrintAdded.clear();
                Get.back();
                Navigator.pop(context);
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
      ),
      body: PdfPreview(
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

  pw.Widget buildBackground(Uint8List backgroundImage) {
    return pw.Stack(
      children: [
        pw.Positioned.fill(
          child: pw.Center(
            child: pw.Opacity(
              opacity: 0.06,
              child: pw.Image(
                pw.MemoryImage(backgroundImage),
                fit: pw.BoxFit.contain,
                width: 600,
                height: 600,
              ),
            ),
          ),
        ),
        pw.Positioned(
          bottom: 30,
          right: 30,
          child: pw.Opacity(
            opacity: 0.08,
            child: pw.Image(
              pw.MemoryImage(backgroundImage),
              width: 150,
              height: 150,
            ),
          ),
        ),
      ],
    );
  }

  Future<Uint8List> _createPdf(PdfPageFormat format) async {
    final pageFormat = format.copyWith(
      marginTop: 40,
      marginBottom: 40,
      marginLeft: 40,
      marginRight: 40,
    );

    final document = pw.Document();

    try {
      final logo = await getImage("assets/images/rece_bg.jpg");
      final backgroundImage = await getImage("assets/images/rece_bg.jpg");
      final vCashIcon = await getImage("assets/images/v_cash_icon.png");
      final instaPayIcon = await getImage("assets/images/instapay_icon.png");
      final whatsappIcon = await getImage("assets/images/whatsapp_icon.png");

      final cairoRegular = await PdfGoogleFonts.cairoRegular();
      final cairoBold = await PdfGoogleFonts.cairoBold();
      final cairoExtraBold = await PdfGoogleFonts.cairoExtraBold();

      // Create first page with header and total stats
      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (context) {
            return pw.Stack(
              children: [
                buildBackground(backgroundImage), // Changed this line
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    buildHeader(
                      logo,
                      cairoBold,
                      isFirstPage: true,
                      extraBoldFont: cairoExtraBold,
                    ),
                    pw.SizedBox(height: 20),
                    pw.Divider(color: PdfColors.red),
                    pw.Expanded(
                        child: pw.Container()), // Add this to push footer down
                    buildFooter(
                        vCashIcon, instaPayIcon, whatsappIcon, cairoBold),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Create subsequent pages for each client
      final (month, year) = getPreviousMonthAndYear();
      int pageNumber = 0;

      for (Client c in clients) {
        if (!hasPaymentForMonth(c, month, year) && c.totalCash < 0) {
          final logs = c.logs!
              .where((log) =>
                  log.createdAt!.year == year &&
                  log.createdAt!.month == month &&
                  log.systemType != "تسديد" &&
                  log.transactionType != TransactionType.moneyAdded)
              .toList();

          if (logs.isNotEmpty) {
            pageNumber++;
            document.addPage(
              pw.Page(
                pageFormat: pageFormat,
                build: (context) {
                  return pw.Stack(
                    children: [
                      buildBackground(backgroundImage), // Changed this line
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          buildHeader(logo, cairoBold,
                              extraBoldFont: cairoExtraBold),
                          pw.SizedBox(height: 20),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              makeText(c.name!, cairoBold, 16.0),
                              makeText(
                                  "  سجل المعاملات المالية الخاصة بالسيد/ ",
                                  cairoRegular,
                                  14.0),
                            ],
                          ),
                          pw.SizedBox(height: 20),
                          ...buildTableWithFlexibleHeight(
                            c,
                            logs,
                            cairoBold,
                            cairoRegular,
                          ),
                          pw.Expanded(
                              child: pw
                                  .Container()), // Add this to push footer down
                          buildFooter(
                              vCashIcon, instaPayIcon, whatsappIcon, cairoBold),
                        ],
                      ),
                    ],
                  );
                },
              ),
            );
          }
        }
      }
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        title: 'Error',
        message: e.toString(),
      ));
    }

    return document.save();
  }

  List<pw.Widget> buildTableWithFlexibleHeight(
    Client client,
    List<Log> items,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final filteredItems = items
        .where((item) =>
            item.systemType != "تسديد" &&
            item.transactionType != TransactionType.moneyAdded)
        .toList();

    double totalPrice = (client.totalCash < 0) ? -client.totalCash : 0;
    String number = client.numbers![0].phoneNumber!;

    // Calculate flexible row height based on number of items
    final double rowHeight = 25.0; // Base height for each row

    return [
      // Table title and info
      ...buildTableTitle(
        "المعاملات",
        boldFont,
        boldFont,
        regularFont,
        'رقم الهاتف',
        'المطلوب سداده',
        totalPrice,
        number,
      ),

      // Flexible table
      pw.Container(
        child: pw.Table(
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          border: pw.TableBorder.all(width: 1, color: PdfColors.black),
          columnWidths: {
            0: const pw.FlexColumnWidth(2), // Time
            1: const pw.FlexColumnWidth(2), // Date
            2: const pw.FlexColumnWidth(1.5), // Amount
            3: const pw.FlexColumnWidth(2), // Type
          },
          children: [
            buildTableHead(
              ["الوقت", "تاريخ تجديد الباقة", "المبلغ", "نوع الباقة"],
              boldFont,
              12,
            ),
            ...filteredItems.map((item) => buildRow(
                  [
                    formatTimeToString(item.createdAt!, "ar"),
                    formatDateToString(item.createdAt!),
                    item.price.toString(),
                    item.systemType,
                  ],
                  regularFont,
                  11.0,
                )),
          ],
        ),
      ),
    ];
  }

  static pw.Widget makeText(String text, pw.Font font, double fontSize,
      [PdfColor color = PdfColors.black]) {
    return pw.Text(text,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(font: font, fontSize: fontSize, color: color));
  }

  Future<Uint8List> getImage(String path) async {
    final imageData = await rootBundle.load(path);
    final bytes = imageData.buffer.asUint8List();
    return bytes;
  }

  pw.TableRow buildRow(List<String> data, pw.Font font, double fontSize) {
    // Create lighter version of #02ccfe
    final lightBlue = PdfColor.fromHex('#e5f9fe');
    final borderBlue = PdfColor.fromHex('#02ccfe');

    return pw.TableRow(
        decoration: pw.BoxDecoration(color: lightBlue),
        children: [
          for (final d in data)
            pw.Container(
                padding: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderBlue, width: 0.5),
                ),
                child: pw.Center(child: makeText(d, font, fontSize)))
        ]);
  }

  pw.TableRow buildTableHead(
      List<String> headers, pw.Font font, double fontSize) {
    final headerBlue = PdfColor.fromHex('#02ccfe');

    return pw.TableRow(
        decoration: pw.BoxDecoration(color: headerBlue),
        children: [
          for (final head in headers)
            pw.Container(
                padding: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.white, width: 0.5),
                ),
                child: pw.Center(
                    child: makeText(head, font, fontSize, PdfColors.white)))
        ]);
  }

  List<pw.Widget> buildTableTitle(
      String tableTitle,
      pw.Font titleFont,
      pw.Font fieldFont,
      pw.Font font,
      String fs,
      String ss,
      double totalPrice,
      String number) {
    pw.Widget titleValue(String field, String value) {
      return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blue200, width: 1.5),
            borderRadius: pw.BorderRadius.circular(8),
            color: PdfColors.grey100,
          ),
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                makeText(field, fieldFont, 16,
                    PdfColors.blue900), // Increased font size
                pw.SizedBox(height: 8),
                makeText(value, fieldFont, 15,
                    PdfColors.red900), // Changed to fieldFont for bold
              ]));
    }

    return [
      pw.Align(
        alignment: pw.Alignment.center,
        child: makeText(tableTitle, titleFont, 18), // Increased font size
      ),
      pw.SizedBox(height: 15),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          titleValue(fs, number.toString()),
          pw.SizedBox(width: 50),
          titleValue(ss, '$totalPrice جنيه'),
        ],
      ),
      pw.SizedBox(height: 15),
    ];
  }

  String formatDateToString(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String formatTimeToString(DateTime fdt, [String lang = "en"]) {
    final dt = TimeOfDay.fromDateTime(fdt);

    if (lang == "en") {
      return "${dt.hourOfPeriod.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}${dt.period.name.toUpperCase()}";
    } else {
      if (dt.period.name == "am") {
        return "${dt.hourOfPeriod.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} صباحاً";
      }
      return "${dt.hourOfPeriod.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} مساءً";
    }
  }

  List<pw.Widget> buildTable(
    String tableTitle,
    Client client,
    List<Log> items,
    List<String> header,
    pw.Font titleFont,
    pw.Font fieldFont,
    pw.Font valueFont,
  ) {
    List<List<String>> rows = [];

    double totalPrice = (client.totalCash < 0) ? -client.totalCash : 0;
    String number = client.numbers![0].phoneNumber!;

    // Filter out تسديد transactions and only show financial transactions
    final filteredItems = items
        .where((item) =>
            item.systemType != "تسديد" &&
            item.transactionType != TransactionType.moneyAdded)
        .toList();

    for (final item in filteredItems) {
      rows.add([
        formatTimeToString(item.createdAt!),
        formatDateToString(item.createdAt!),
        item.price.toString(),
        item.systemType,
      ]);
    }

    return [
      for (final w in buildTableTitle(tableTitle, titleFont, fieldFont,
          valueFont, 'رقم الهاتف', 'المطلوب سداده', totalPrice, number))
        w,
      pw.Align(
        alignment: pw.Alignment.center,
        child: pw.Table(
          border: pw.TableBorder.all(width: 1, color: PdfColors.black),
          children: [
            buildTableHead(header, fieldFont, 14), // Increased font size
            ...rows.map(
                (row) => buildRow(row, valueFont, 12.0)), // Increased font size
          ],
        ),
      ),
    ];
  }

  pw.Widget _buildStatBox(String label, String value, pw.Font font) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        makeText(label, font, 16.0, PdfColors.blue900),
        pw.SizedBox(height: 8),
        makeText(value, font, 15.0, PdfColors.red900),
      ],
    );
  }

  (int clientCount, double totalAmount) calculateStats() {
    final (month, year) = getPreviousMonthAndYear();
    int count = 0;
    double total = 0.0;

    for (var client in clients) {
      if (!hasPaymentForMonth(client, month, year) && client.totalCash < 0) {
        count++;
        total += -client.totalCash;
      }
    }
    return (count, total);
  }

  pw.Widget buildHeader(Uint8List logo, pw.Font font,
      {bool isFirstPage = false, required pw.Font extraBoldFont}) {
    final monthName = _getAppropriateMonthName();
    final (clientCount, totalAmount) = calculateStats();

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(pw.MemoryImage(logo), width: 100),
                pw.Column(
                  children: [
                    makeText("فاتورة تحصيل", font, 24.0),
                    pw.SizedBox(height: 8),
                    makeText("شهر $monthName", font, 18.0, PdfColors.blue900),
                  ],
                ),
                pw.SizedBox(width: 100),
              ],
            ),
          ),
          if (isFirstPage) ...[
            pw.SizedBox(height: 25),
            pw.Divider(color: PdfColors.red),
            pw.SizedBox(height: 15),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Column(
                children: [
                  makeText("الحساب الكلي", extraBoldFont, 18.0),
                  pw.SizedBox(height: 15),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      pw.Column(
                        children: [
                          makeText("عدد العملاء", extraBoldFont, 18.0,
                              PdfColors.blue900),
                          makeText("$clientCount", extraBoldFont, 22.0,
                              PdfColors.red900),
                        ],
                      ),
                      pw.Container(
                        height: 40,
                        width: 1,
                        color: PdfColors.blue200,
                      ),
                      pw.Column(
                        children: [
                          makeText("المبلغ المطلوب", extraBoldFont, 18.0,
                              PdfColors.blue900),
                          makeText("${totalAmount.toStringAsFixed(2)} جنيه",
                              extraBoldFont, 22.0, PdfColors.red900),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget buildFooter(Uint8List vCashIcon, Uint8List instaPayIcon,
      Uint8List whatsappIcon, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      margin: const pw.EdgeInsets.only(top: 60),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        children: [
          makeText("وسائل الدفع المتاحة", font, 14.0, PdfColors.blue900),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Row(
                children: [
                  pw.Image(pw.MemoryImage(vCashIcon), width: 50),
                  pw.SizedBox(width: 10),
                  makeText("01022690901", font, 14.0, PdfColors.red900),
                ],
              ),
              pw.Container(
                width: 1,
                height: 40,
                color: PdfColors.grey300,
              ),
              pw.Row(
                children: [
                  pw.Image(pw.MemoryImage(instaPayIcon), width: 50),
                  pw.SizedBox(width: 10),
                  makeText("01017174149", font, 14.0, PdfColors.purple900),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Image(pw.MemoryImage(whatsappIcon), width: 20),
              makeText("01017174149", font, 14.0, PdfColors.red900),
              pw.SizedBox(width: 10),
              
              pw.SizedBox(width: 5),
              makeText("للاستفسار: ", font, 14.0, PdfColors.blue900),
            ],
          ),
        ],
      ),
    );
  }
}
