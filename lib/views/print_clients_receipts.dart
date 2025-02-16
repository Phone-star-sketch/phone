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

    if (now.day > collectionDay) {
      final nextMonth = DateTime(now.year, now.month + 1);
      return _getArabicMonthName(nextMonth.month);
    }
    return _getArabicMonthName(now.month);
  }

  String _getArabicMonthName(int month) {
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

  Future<Uint8List> _createPdf(PdfPageFormat format) async {
    final documnet = pw.Document();

    try {
      final logo = await getImage("assets/images/rece_bg.jpg");
      final nbLogo = await getImage("assets/images/rece_bg.jpg");

      final vCashIcon = await getImage("assets/images/v_cash_icon.png");
      final instaPayIcon = await getImage("assets/images/instapay_icon.png");

      final cairoRegular = await PdfGoogleFonts.cairoRegular();
      final cairoBold = await PdfGoogleFonts.cairoBold();
      final cairoExtraBold = await PdfGoogleFonts.cairoExtraBold();
      final dateFormater = DateFormat("dd/MM/yyyy");

      double totalPrice = 0.0;
      final count = clients.length;

      for (final c in clients) {
        totalPrice += (c.totalCash < 0.0) ? -c.totalCash : 0.0;
      }

      addClientData(Client client) {
        final startDate = DateTime.now().subtract(const Duration(days: 45));

        final logs = client.logs!
            .where(
              (log) => log.createdAt!.isAfter(startDate),
            )
            .toList();

        return [
          pw.Row(
            children: [
              makeText("سجل المعاملات المالية الخاصة بالسيد  /  ", cairoRegular,
                  10.0),
              makeText(client.name!, cairoBold, 12.0)
            ],
          ),
          pw.Divider(endIndent: 50, indent: 50),
          pw.SizedBox(height: 20),
          ...buildTable(
              "المعاملات",
              client,
              logs,
              [
                "الوقت",
                "التاريخ",
                "المبلغ",
                "نوع التعامل",
              ],
              cairoBold,
              cairoBold,
              cairoRegular),
        ];
      }

      for (Client c in clients) {
        documnet.addPage(pw.MultiPage(
          build: (context) {
            return [
              ...[
                ...addClientData(c),
                pw.SizedBox(height: 60),
                pw.Divider(indent: 0, endIndent: 0)
              ],
            ];
          },
          pageTheme: pw.PageTheme(
            textDirection: pw.TextDirection.rtl,
            pageFormat: PdfPageFormat.a4,
            buildBackground: (context) {
              return pw.Container(
                  margin: const pw.EdgeInsets.all(-35),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: const pw.BoxDecoration(),
                  child: pw.Stack(overflow: pw.Overflow.visible, children: [
                    pw.Positioned.fill(
                        child: pw.Container(
                      child: pw.Center(
                        child: pw.Opacity(
                          opacity: 0.1,
                          child: pw.Image(pw.MemoryImage(nbLogo), width: 800),
                        ),
                      ),
                    )),
                    (context.pageNumber == 1)
                        ? pw.Positioned(
                            left: -35,
                            top: -35,
                            child: pw.Opacity(
                                opacity: 0.5,
                                child: pw.Image(
                                  pw.MemoryImage(logo),
                                  width: 150,
                                )))
                        : pw.SizedBox()
                  ]));
            },
          ),
          footer: (context) {
            return pw.Container(
                child: pw.Column(children: [
              pw.Divider(color: PdfColors.red),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  makeText("وسائل الدفع", cairoBold, 16.0),
                  pw.Image(pw.MemoryImage(vCashIcon), width: 80.0),
                  makeText("01022690901", cairoBold, 16.0, PdfColors.red),
                  pw.Container(
                      width: 1,
                      height: 5,
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.black)),
                  pw.Image(pw.MemoryImage(instaPayIcon), width: 80),
                  makeText("01017174149", cairoBold, 16, PdfColors.purple),
                ],
              )
            ]));
          },
          header: (context) {
            return (context.pageNumber == 1)
                ? pw.Column(
                    children: [
                      pw.Container(
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            makeText("سجل المعاملات المالية", cairoBold, 18.0),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 25),
                      pw.Divider(color: PdfColors.red),
                      ...buildTableTitle(
                        "الحساب الكلي",
                        cairoExtraBold,
                        cairoBold,
                        cairoRegular,
                        "عدد العملاء",
                        "المطلوب سداده",
                        totalPrice.toDouble(),
                        count.toString(),
                      ),
                      pw.Divider(),
                      makeText("تنويه: تشمل جداول المعاملات سجل اخر 45 يوم",
                          cairoBold, 8.0, PdfColors.red),
                      pw.SizedBox(height: 60),
                    ],
                  )
                : pw.SizedBox();
          },
        ));
      }
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        title: 'Hello',
        message: e.toString(),
      ));
    }
    return documnet.save();
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
    return pw.TableRow(children: [
      for (final d in data)
        pw.Container(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Center(child: makeText(d, font, fontSize)))
    ]);
  }

  pw.TableRow buildTableHead(
      List<String> headers, pw.Font font, double fontSize) {
    return pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.red),
        children: [
          for (final head in headers)
            pw.Container(
                padding: const pw.EdgeInsets.all(3),
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
      return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            makeText(field, fieldFont, 12),
            makeText(value, font, 11),
          ]);
    }

    return [
      pw.Align(
        alignment: pw.Alignment.center,
        child: makeText(tableTitle, titleFont, 16),
      ),
      pw.Divider(indent: 150, endIndent: 150),
      pw.Align(
        alignment: pw.Alignment.center,
        child:
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
          titleValue(fs, number.toString()),
          pw.SizedBox(width: 100),
          titleValue(ss, '$totalPrice جنيه'),
        ]),
      ),
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

    for (final item in items) {
      rows.add([
        formatTimeToString(item.createdAt!),
        formatDateToString(item.createdAt!),
        item.price.toString(),
        item.systemType,
      ]);
    }

    return [
      for (final w in buildTableTitle(tableTitle, titleFont, fieldFont,
          valueFont, 'رقم المحمول', 'المطلوب سداده', totalPrice, number))
        w,
      pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Table(
              border: pw.TableBorder.all(width: 1, color: PdfColors.black),
              children: [
                for (int i = 0; i < header.length && (i < 1); i++)
                  buildTableHead(header, fieldFont, 12),
                for (final row in rows) buildRow(row, valueFont, 10.0)
              ])),
    ];
  }
}
