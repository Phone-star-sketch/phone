import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/other_services_exclude_price.dart'
    as exclude_price;
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';
import 'package:printing/printing.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PrintClientsReceipts extends StatelessWidget {
  final List<Client> clients;
  PrintClientsReceipts({super.key, required this.clients});
  final controller = Get.find<AccountClientInfo>();

  // Use the existing ExcludedSystemsManager instance if available
  exclude_price.ExcludedSystemsManager get excludedManager {
    if (Get.isRegistered<exclude_price.ExcludedSystemsManager>()) {
      return Get.find<exclude_price.ExcludedSystemsManager>();
    }
    return Get.put(exclude_price.ExcludedSystemsManager());
  }

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
    return client.logs?.any((log) =>
            log.createdAt?.year == year &&
            log.createdAt?.month == month &&
            log.systemType == "تسديد" &&
            log.price > 0) ??
        false;
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
        loadingWidget: const CircularProgressIndicator(),
        onError: (context, error) {
          Get.showSnackbar(GetSnackBar(
            title: "مشكلة الطباعة",
            message: error.toString(),
          ));
          return Text("Error: ${error.toString()}");
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
                buildBackground(backgroundImage),
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
                    pw.Expanded(child: pw.Container()),
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
        // Fixed: Added null safety checks
        final logs = (c.logs ?? [])
            .where((log) =>
                log.createdAt?.year == year &&
                log.createdAt?.month == month &&
                log.systemType != "تسديد" &&
                log.transactionType != TransactionType.moneyAdded)
            .toList();

        // Create page if client has transactions OR negative balance (even without payment)
        if (logs.isNotEmpty ||
            (!hasPaymentForMonth(c, month, year) && c.totalCash < 0)) {
          pageNumber++;
          document.addPage(
            pw.Page(
              pageFormat: pageFormat,
              build: (context) {
                return pw.Stack(
                  children: [
                    buildBackground(backgroundImage),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        buildHeader(logo, cairoBold,
                            extraBoldFont: cairoExtraBold),
                        pw.SizedBox(height: 20),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            makeText(c.name ?? "غير محدد", cairoBold, 16.0),
                            makeText("  سجل المعاملات المالية الخاصة بالسيد/ ",
                                cairoRegular, 14.0),
                          ],
                        ),
                        pw.SizedBox(height: 20),
                        ...buildTableWithFlexibleHeight(
                          c,
                          logs,
                          cairoBold,
                          cairoRegular,
                        ),
                        pw.Expanded(child: pw.Container()),
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
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        title: 'Error',
        message: e.toString(),
      ));
      rethrow;
    }

    return document.save();
  }

  // Helper method to check if a system type is excluded
  bool _isSystemTypeExcluded(String systemTypeName) {
    try {
      return excludedManager.isSystemTypeExcluded(systemTypeName);
    } catch (e) {
      print("Error checking exclusion for $systemTypeName: $e");
      return false;
    }
  }

  // Helper method to get all systems for a client (including from numbers)
  List<System> _getAllClientSystems(Client client) {
    List<System> allSystems = [];

    // Add systems from client.systems if available
    if (client.systems != null) {
      allSystems.addAll(client.systems!);
    }

    // Add systems from client.numbers if available
    if (client.numbers != null) {
      for (var number in client.numbers!) {
        if (number.systems != null) {
          allSystems.addAll(number.systems!);
        }
      }
    }

    return allSystems;
  }

  // Helper method to check if a system still exists (not permanently deleted)
  bool _systemStillExists(System system, Client client) {
    final allCurrentSystems = _getAllClientSystems(client);
    return allCurrentSystems.any((s) => s.id == system.id);
  }

  // Helper method to calculate adjusted total cash considering exclusions and deletions
  double _getAdjustedTotalCash(Client client) {
    // Use the updated totalCash from client which should already reflect permanent deletions
    if (client.totalCash >= 0) return 0;

    double originalAmount = -client.totalCash;
    double excludedAmount = 0;

    // Calculate excluded amount only from existing systems (not permanently deleted)
    final currentSystems = _getAllClientSystems(client);
    for (var system in currentSystems) {
      if (_isSystemTypeExcluded(system.type?.name ?? '')) {
        // Only count unpaid mobile internet services
        if (system.type?.category == SystemCategory.mobileInternet) {
          bool isPaid = system.name?.contains('[مدفوع]') ?? false;
          if (!isPaid) {
            excludedAmount += system.type?.price ?? 0;
          }
        }
      }
    }

    return originalAmount - excludedAmount;
  }

  List<pw.Widget> buildTableWithFlexibleHeight(
    Client client,
    List<Log> items,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    // Get currently assigned systems only
    final currentSystems = _getAllClientSystems(client);

    // Filter to get only visible/active systems
    final visibleSystems = currentSystems.where((system) {
      // Apply the same filtering logic as in the client info sheet
      if (system.type?.category == SystemCategory.mobileInternet) {
        // For mobile internet services, check if paid and within collection period
        bool isPaid = system.name?.contains('[مدفوع]') ?? false;
        bool shouldShow = _shouldShowSystem(system);
        return !isPaid && shouldShow;
      }
      // Always show flex systems
      return true;
    }).toList();

    // Filter out excluded systems
    final finalVisibleSystems = visibleSystems.where((system) {
      return !_isSystemTypeExcluded(system.type?.name ?? '');
    }).toList();

    // Group systems by type to avoid duplicates
    final Map<String, System> uniqueSystems = {};
    for (var system in finalVisibleSystems) {
      final key = system.type?.name ?? 'غير محدد';
      // Keep the first occurrence of each system type
      if (!uniqueSystems.containsKey(key)) {
        uniqueSystems[key] = system;
      }
    }

    final uniqueSystemsList = uniqueSystems.values.toList();

    double totalPrice = _getAdjustedTotalCash(client);
    String number = (client.numbers != null && client.numbers!.isNotEmpty)
        ? client.numbers![0].phoneNumber ?? "غير محدد"
        : "غير محدد";

    return [
      // Table title and info
      ...buildTableTitle(
        "المعاملات",
        boldFont,
        boldFont,
        regularFont,
        'رقم الهاتف',
        'المبلغ المطلوب',
        totalPrice,
        number,
      ),

      // Flexible table
      pw.Container(
        child: pw.Table(
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          border: pw.TableBorder.all(width: 1, color: PdfColors.black),
          columnWidths: const {
            0: pw.FlexColumnWidth(2), // Date
            1: pw.FlexColumnWidth(1.5), // Amount
            2: pw.FlexColumnWidth(1.5), // Price
            3: pw.FlexColumnWidth(2), // Type
          },
          children: [
            buildTableHead(
              ["تاريخ الاشتراك", "المبلغ الكلي", "سعر الباقة", "نوع الباقة"],
              boldFont,
              12,
            ),
            // Show unique systems only (no duplicates)
            ...uniqueSystemsList.asMap().entries.map((entry) {
              final index = entry.key;
              final system = entry.value;

              return buildRow(
                [
                  system.createdAt != null
                      ? formatDateToString(system.createdAt!)
                      : "غير محدد",
                  // Show total amount only in first row, empty for others
                  index == 0 ? totalPrice.toStringAsFixed(2) : "",
                  "${system.type?.price?.toStringAsFixed(0) ?? '0'} جنيه",
                  system.type?.name ?? "غير محدد"
                ],
                regularFont,
                11.0,
              );
            }).toList(),
            // Add a row if no visible systems to show
            if (uniqueSystemsList.isEmpty)
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Center(
                        child:
                            makeText("لا توجد باقات للعرض", regularFont, 12.0)),
                  ),
                  // Show total amount even when no systems
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Center(
                        child: makeText(
                            totalPrice.toStringAsFixed(2), regularFont, 12.0)),
                  ),
                  pw.Container(),
                  pw.Container(),
                ],
              ),
          ],
        ),
      ),
    ];
  }

  // Add helper method to check if system should be shown (same logic as client info sheet)
  bool _shouldShowSystem(System system) {
    if (system.type?.category == SystemCategory.mobileInternet) {
      if (system.createdAt != null) {
        final collectionDay = AccountClientInfo.to.currentAccount.day;
        final nextCollection = DateTime(
          system.createdAt!.month == 12
              ? system.createdAt!.year + 1
              : system.createdAt!.year,
          system.createdAt!.month == 12 ? 1 : system.createdAt!.month + 1,
          collectionDay,
        );
        return !DateTime.now().isAfter(nextCollection);
      }
    }
    return true;
  }

  // (Removed duplicate _createPdf method)

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
    final lightBlue = PdfColor.fromHex('#e5f9fe');
    final borderBlue = PdfColor.fromHex('#02ccfe');

    return pw
        .TableRow(decoration: pw.BoxDecoration(color: lightBlue), children: [
      for (final d in data)
        pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 3),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderBlue, width: 0.5),
            ),
            child: pw.Center(
                child: pw.Text(
              d,
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(font: font, fontSize: fontSize),
              maxLines: 2,
              softWrap: true,
            )))
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
                makeText(field, fieldFont, 16, PdfColors.blue900),
                pw.SizedBox(height: 8),
                makeText(value, fieldFont, 15, PdfColors.red900),
              ]));
    }

    return [
      pw.Align(
        alignment: pw.Alignment.center,
        child: makeText(tableTitle, titleFont, 18),
      ),
      pw.SizedBox(height: 15),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          titleValue(ss, '${totalPrice.toStringAsFixed(2)} جنيه'),
          pw.SizedBox(width: 50),
          titleValue(fs, number),
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

  (int clientCount, double totalAmount) calculateStats() {
    final (month, year) = getPreviousMonthAndYear();
    int count = 0;
    double total = 0.0;

    for (var client in clients) {
      if (!hasPaymentForMonth(client, month, year)) {
        double adjustedAmount = _getAdjustedTotalCash(client);
        if (adjustedAmount > 0) {
          count++;
          total += adjustedAmount;
        }
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
                pw.SizedBox(width: 8),
                makeText("01017174149", font, 14.0, PdfColors.red900),
              makeText("للاستفسار : ", font, 14.0, PdfColors.blue900),
              //makeText("01017174149", font, 14.0, PdfColors.red900),
              pw.SizedBox(width: 5),
              pw.SizedBox(width: 5),
            ],
          ),
        ],
      ),
    );
  }
}
