import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/other_services_exclude_price.dart'
    as exclude_price;
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

    // Get the appropriate date
    DateTime targetDate;
    if (now.day < collectionDay) {
      if (now.month == 1) {
        targetDate = DateTime(now.year - 1, 12, collectionDay);
      } else {
        targetDate = DateTime(now.year, now.month - 1, collectionDay);
      }
    } else {
      targetDate = DateTime(now.year, now.month, collectionDay);
    }

    // Return full date format: "15/01/2025"
    return '${targetDate.year}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.day.toString().padLeft(2, '0')}';
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
        actions: [
          // Custom share button for better Android compatibility
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'مشاركة',
            onPressed: () async {
              try {
                // Show loading
                Get.dialog(
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                  barrierDismissible: false,
                );

                // Generate PDF
                final pdfData = await _createPdf(PdfPageFormat.a4);

                // Save to temp directory
                final directory = await getTemporaryDirectory();
                final timestamp = DateTime.now().millisecondsSinceEpoch;
                final file = File(
                    '${directory.path}/فاتورة_شهر_${calculatedMonthName.replaceAll('/', '_')}_$timestamp.pdf');
                await file.writeAsBytes(pdfData);

                // Close loading
                Get.back();

                // Share using share_plus
                await Share.shareXFiles(
                  [XFile(file.path)],
                  subject: 'فاتورة شهر $calculatedMonthName',
                  text: 'فاتورة التحصيل الشهرية',
                );
              } catch (e) {
                // Close loading if still open
                if (Get.isDialogOpen ?? false) {
                  Get.back();
                }

                Get.showSnackbar(GetSnackBar(
                  title: "خطأ",
                  message: "فشلت المشاركة: ${e.toString()}",
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ));
              }
            },
          ),
        ],
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
              opacity: 0.03,
              child: pw.Image(
                pw.MemoryImage(backgroundImage),
                fit: pw.BoxFit.contain,
                width: 300,
                height: 300,
              ),
            ),
          ),
        ),
        pw.Positioned(
          bottom: 30,
          right: 30,
          child: pw.Opacity(
            opacity: 0.05,
            child: pw.Image(
              pw.MemoryImage(backgroundImage),
              width: 80,
              height: 80,
            ),
          ),
        ),
      ],
    );
  }

  // Cache for logo and icons
  static Uint8List? _cachedLogo;
  static Uint8List? _cachedBackgroundImage;
  static Uint8List? _cachedHeaderBackground;
  static Uint8List? _cachedFooterBackground;
  static String? _cachedFooterVodafoneSvg;
  static Uint8List? _cachedInstaPayIcon;
  static Uint8List? _cachedWhatsappIcon;

  Future<Uint8List> _createPdf(PdfPageFormat format) async {
    final pageFormat = format.copyWith(
      marginTop: 40,
      marginBottom: 40,
      marginLeft: 40,
      marginRight: 40,
    );

    final document = pw.Document();

    try {
      // Load and cache images only once
      _cachedLogo ??= await getImage("assets/images/newlogo.png");
      _cachedBackgroundImage ??= await getImage("assets/images/newlogo.png");
      _cachedHeaderBackground ??=
          await getImage("assets/images/invoice_header_background_v2.png");
      _cachedFooterBackground ??=
          await getImage("assets/images/invoice_footer_background_v3.png");
      _cachedFooterVodafoneSvg ??= await rootBundle
          .loadString("assets/images/invoice_footer_vodafone.svg");
      _cachedInstaPayIcon ??=
          await getImage("assets/images/invoice_footer_instapay.png");
      _cachedWhatsappIcon ??=
          await getImage("assets/images/invoice_footer_whatsapp.png");

      final logo = _cachedLogo!;
      final backgroundImage = _cachedBackgroundImage!;
      final headerBackground = _cachedHeaderBackground!;
      final footerBackground = _cachedFooterBackground!;
      final vodafoneSvg = _cachedFooterVodafoneSvg!;
      final instaPayIcon = _cachedInstaPayIcon!;
      final whatsappIcon = _cachedWhatsappIcon!;

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
                      headerBackground,
                      cairoBold,
                      isFirstPage: true,
                      extraBoldFont: cairoExtraBold,
                    ),
                    pw.SizedBox(height: 18),
                    pw.Expanded(child: pw.Container()),
                    buildFooter(footerBackground, vodafoneSvg, instaPayIcon,
                        whatsappIcon, cairoBold),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Create subsequent pages for each client
      final (month, year) = getPreviousMonthAndYear();

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
                        buildHeader(logo, headerBackground, cairoBold,
                            extraBoldFont: cairoExtraBold),
                        pw.SizedBox(height: 18),
                        pw.Container(
                          width: double.infinity,
                          child: pw.Text(
                            "سجل المعاملات للسيد/ ${c.name ?? 'غير محدد'}",
                            textDirection: pw.TextDirection.rtl,
                            textAlign: pw.TextAlign.center,
                            style:
                                pw.TextStyle(font: cairoBold, fontSize: 16.0),
                            softWrap: true,
                            maxLines: 2,
                            overflow: pw.TextOverflow.visible,
                          ),
                        ),
                        pw.SizedBox(height: 20),
                        ...buildTableWithFlexibleHeight(
                          c,
                          logs,
                          cairoBold,
                          cairoRegular,
                        ),
                        pw.Expanded(child: pw.Container()),
                        buildFooter(footerBackground, vodafoneSvg, instaPayIcon,
                            whatsappIcon, cairoBold),
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
      debugPrint("Error checking exclusion for $systemTypeName: $e");
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
          border: pw.TableBorder(
            horizontalInside:
                pw.BorderSide(width: 0.4, color: PdfColor.fromHex('#dce7f5')),
            verticalInside:
                pw.BorderSide(width: 0.4, color: PdfColor.fromHex('#e7eef7')),
            top: pw.BorderSide(width: 0.7, color: PdfColor.fromHex('#101827')),
            bottom:
                pw.BorderSide(width: 0.7, color: PdfColor.fromHex('#101827')),
            left: pw.BorderSide(width: 0.7, color: PdfColor.fromHex('#101827')),
            right:
                pw.BorderSide(width: 0.7, color: PdfColor.fromHex('#101827')),
          ),
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
                  "${system.type?.price.toStringAsFixed(0) ?? '0'} جنيه",
                  system.type?.name ?? "غير محدد"
                ],
                regularFont,
                11.0,
                index: index,
              );
            }),
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

  pw.TableRow buildRow(List<String> data, pw.Font font, double fontSize,
      {int index = 0}) {
    final rowColor =
        index.isEven ? PdfColors.white : PdfColor.fromHex('#f8fafc');
    final borderColor = PdfColor.fromHex('#e7eef7');

    return pw
        .TableRow(decoration: pw.BoxDecoration(color: rowColor), children: [
      for (final d in data)
        pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 5),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderColor, width: 0.35),
            ),
            child: pw.Center(
                child: pw.Text(
              d,
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: font,
                fontSize: fontSize,
                color: PdfColor.fromHex('#101827'),
              ),
              maxLines: 2,
              softWrap: true,
            )))
    ]);
  }

  pw.TableRow buildTableHead(
      List<String> headers, pw.Font font, double fontSize) {
    final headerColor = PdfColor.fromHex('#101827');

    return pw
        .TableRow(decoration: pw.BoxDecoration(color: headerColor), children: [
      for (final head in headers)
        pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: pw.BoxDecoration(
              border:
                  pw.Border.all(color: PdfColor.fromHex('#27364a'), width: 0.5),
            ),
            child: pw.Center(
                child: makeText(head, font, fontSize, PdfColors.white)))
    ]);
  }

  pw.Widget _buildInfoIcon(String type, PdfColor accent) {
    final path = switch (type) {
      'clients' =>
        '<circle cx="13" cy="10" r="5"/><path d="M4 27v-3c0-5 4-8 9-8s9 3 9 8v3M23 7a4 4 0 0 1 0 8m3 12v-3c0-3-2-6-5-7"/>',
      'phone' =>
        '<path d="M7 3h6l2 7-4 2c2 5 5 8 10 10l2-4 7 2v6c0 2-2 4-4 4C13 29 3 19 3 7c0-2 2-4 4-4Z"/>',
      _ =>
        '<circle cx="16" cy="16" r="12"/><path d="M20 10c-1-1-3-2-5-2-3 0-5 2-5 4 0 3 2 4 6 4s6 1 6 4c0 2-2 4-6 4-2 0-5-1-6-2M16 5v22"/>',
    };

    return pw.Container(
      width: 48,
      height: 48,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.Container(
            width: 48,
            height: 48,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: PdfColor(accent.red, accent.green, accent.blue, 0.08),
            ),
          ),
          pw.Container(
            width: 36,
            height: 36,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: PdfColor(accent.red, accent.green, accent.blue, 0.13),
              border: pw.Border.all(
                color: PdfColor(
                  accent.red,
                  accent.green,
                  accent.blue,
                  0.32,
                ),
                width: 0.8,
              ),
            ),
            child: pw.Center(
              child: pw.SvgImage(
                svg:
                    '<svg viewBox="0 0 32 32" fill="none" stroke="#000000" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">$path</svg>',
                width: 19,
                height: 19,
                colorFilter: accent,
              ),
            ),
          ),
        ],
      ),
    );
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
      final isAmount = field == ss;
      final accent =
          isAmount ? PdfColor.fromHex('#d71920') : PdfColor.fromHex('#20aeea');

      return pw.Container(
        width: 200,
        height: 76,
        child: pw.Stack(
          overflow: pw.Overflow.visible,
          children: [
            pw.Positioned.fill(
              child: pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(42, 11, 14, 11),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                      color: PdfColor.fromHex('#dce7f5'), width: 1),
                  borderRadius: pw.BorderRadius.circular(14),
                  color: PdfColors.white,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    makeText(
                        field, fieldFont, 12.5, PdfColor.fromHex('#0b4db3')),
                    pw.SizedBox(height: 6),
                    makeText(
                      value,
                      fieldFont,
                      isAmount ? 15.5 : 14.0,
                      isAmount
                          ? PdfColor.fromHex('#d71920')
                          : PdfColor.fromHex('#101827'),
                    ),
                  ],
                ),
              ),
            ),
            pw.Positioned(
              left: -9,
              top: 14,
              child: _buildInfoIcon(isAmount ? 'money' : 'phone', accent),
            ),
          ],
        ),
      );
    }

    return [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#f8fafc'),
          borderRadius: pw.BorderRadius.circular(14),
          border: pw.Border.all(color: PdfColor.fromHex('#dce7f5'), width: 0.8),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Container(
                width: 46, height: 2, color: PdfColor.fromHex('#d71920')),
            makeText(tableTitle, titleFont, 18, PdfColor.fromHex('#101827')),
            pw.Container(
                width: 46, height: 2, color: PdfColor.fromHex('#d71920')),
          ],
        ),
      ),
      pw.SizedBox(height: 12),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          titleValue(ss, '${totalPrice.toStringAsFixed(2)} جنيه'),
          pw.SizedBox(width: 24),
          titleValue(fs, number),
        ],
      ),
      pw.SizedBox(height: 14),
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

  pw.Widget buildHeader(
      Uint8List logo, Uint8List headerBackground, pw.Font font,
      {bool isFirstPage = false, required pw.Font extraBoldFont}) {
    final monthName = _getAppropriateMonthName();
    final (clientCount, totalAmount) = calculateStats();
    final (month, year) = getPreviousMonthAndYear();
    final arabicMonth = _getArabicMonthName(month);

    final ink = PdfColor.fromHex('#101827');
    final red = PdfColor.fromHex('#d71920');
    final blue = PdfColor.fromHex('#0b4db3');
    final paper = PdfColor.fromHex('#f8fafc');
    final line = PdfColor.fromHex('#dce7f5');

    pw.Widget metricCard({
      required String label,
      required String value,
      required PdfColor valueColor,
      required pw.Font valueFont,
      required String iconType,
    }) {
      return pw.Expanded(
        child: pw.Container(
          height: 78,
          child: pw.Stack(
            overflow: pw.Overflow.visible,
            children: [
              pw.Positioned.fill(
                child: pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(42, 11, 12, 11),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: line, width: 0.8),
                  ),
                  child: pw.Column(
                    children: [
                      makeText(label, font, 12.5, blue),
                      pw.SizedBox(height: 6),
                      makeText(value, valueFont, 18.0, valueColor),
                    ],
                  ),
                ),
              ),
              pw.Positioned(
                left: -9,
                top: 15,
                child: _buildInfoIcon(iconType, valueColor),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Container(
      child: pw.Column(
        children: [
          pw.Container(
            height: 118,
            child: pw.Stack(
              children: [
                pw.Positioned.fill(
                  child: pw.Image(
                    pw.MemoryImage(headerBackground),
                    fit: pw.BoxFit.fill,
                  ),
                ),
                pw.Positioned(
                  left: 20,
                  top: 32,
                  child: pw.Container(
                    width: 92,
                    height: 54,
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child:
                        pw.Image(pw.MemoryImage(logo), fit: pw.BoxFit.contain),
                  ),
                ),
                pw.Positioned(
                  left: 135,
                  right: 125,
                  top: 29,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      makeText('فاتورة تحصيل', extraBoldFont, 23.0, ink),
                      pw.SizedBox(height: 5),
                      makeText(
                        'شهر $arabicMonth لسنة $year',
                        font,
                        14.5,
                        PdfColor.fromHex('#49657d'),
                      ),
                    ],
                  ),
                ),
                pw.Positioned(
                  right: 20,
                  top: 34,
                  child: pw.Container(
                    width: 88,
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 7,
                      horizontal: 9,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        makeText(
                          'تاريخ الفاتورة',
                          font,
                          9.0,
                          PdfColor.fromHex('#49657d'),
                        ),
                        pw.SizedBox(height: 4),
                        makeText(monthName, extraBoldFont, 11.0, ink),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isFirstPage) ...[
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: paper,
                borderRadius: pw.BorderRadius.circular(16),
                border: pw.Border.all(color: line, width: 0.9),
              ),
              child: pw.Column(
                children: [
                  makeText('الحساب الكلي', extraBoldFont, 18.0, ink),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    children: [
                      metricCard(
                        label: 'عدد العملاء',
                        value: '$clientCount',
                        valueColor: red,
                        valueFont: extraBoldFont,
                        iconType: 'clients',
                      ),
                      pw.SizedBox(width: 12),
                      metricCard(
                        label: 'المبلغ المطلوب',
                        value: '${totalAmount.toStringAsFixed(2)} جنيه',
                        valueColor: red,
                        valueFont: extraBoldFont,
                        iconType: 'money',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(height: 1.2, color: red),
          ],
        ],
      ),
    );
  }

  pw.Widget buildFooter(Uint8List footerBackground, String vodafoneSvg,
      Uint8List instaPayIcon, Uint8List whatsappIcon, pw.Font font) {
    final ink = PdfColor.fromHex('#101827');
    final red = PdfColor.fromHex('#d71920');

    pw.Widget paymentTile({
      required pw.Widget icon,
      required String label,
      required String value,
      required PdfColor color,
    }) {
      return pw.Expanded(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(width: 22, height: 22, child: icon),
                pw.SizedBox(width: 7),
                makeText(label, font, 9.2, color),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              textDirection: pw.TextDirection.ltr,
              style: pw.TextStyle(
                font: font,
                fontSize: 11.5,
                color: ink,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 28),
      height: 172,
      child: pw.Stack(
        children: [
          pw.Positioned.fill(
            child: pw.Image(
              pw.MemoryImage(footerBackground),
              fit: pw.BoxFit.fill,
            ),
          ),
          pw.Positioned(
            top: 7,
            left: 0,
            right: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(width: 52, height: 1.2, color: red),
                pw.SizedBox(width: 12),
                makeText('وسائل الدفع المتاحة', font, 14.0, ink),
                pw.SizedBox(width: 12),
                pw.Container(width: 52, height: 1.2, color: red),
              ],
            ),
          ),
          pw.Positioned(
            top: 35,
            left: 96,
            right: 96,
            bottom: 86,
            child: pw.Row(
              children: [
                paymentTile(
                  icon: pw.SvgImage(
                    svg: vodafoneSvg,
                    width: 20,
                    height: 20,
                  ),
                  label: 'فودافون كاش',
                  value: '01022690901',
                  color: red,
                ),
                pw.SizedBox(width: 18),
                paymentTile(
                  icon: pw.Image(
                    pw.MemoryImage(instaPayIcon),
                    fit: pw.BoxFit.contain,
                  ),
                  label: 'InstaPay',
                  value: '01017174149',
                  color: PdfColors.purple700,
                ),
                pw.SizedBox(width: 18),
                paymentTile(
                  icon: pw.Image(
                    pw.MemoryImage(whatsappIcon),
                    fit: pw.BoxFit.contain,
                  ),
                  label: 'للاستفسار',
                  value: '01017174149',
                  color: PdfColors.green700,
                ),
              ],
            ),
          ),
          pw.Positioned(
            left: 0,
            right: 0,
            bottom: 22,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(width: 50, height: 1.1, color: red),
                pw.SizedBox(width: 12),
                makeText('شكرا لثقتكم بنا', font, 12.0, ink),
                pw.SizedBox(width: 12),
                pw.Container(width: 50, height: 1.1, color: red),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
