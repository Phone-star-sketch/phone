import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

/// Enhanced Arabic PDF Generator for Dues Report
class ArabicDuesPdfGenerator {
  // Static fonts to be loaded once
  static pw.Font? _cairoRegular;
  static pw.Font? _cairoBold;
  static pw.Font? _cairoExtraBold;
  static bool _fontsInitialized = false;

  /// Initialize fonts using local Cairo assets
  static Future<void> initializeFonts() async {
    try {
      if (_fontsInitialized) return;

      print('Loading Cairo fonts from assets...');

      // Load Cairo fonts from your local assets
      final regularFontData =
          await rootBundle.load('assets/fonts/cairo/Cairo-Regular.ttf');
      final boldFontData =
          await rootBundle.load('assets/fonts/cairo/Cairo-Bold.ttf');
      final extraBoldFontData =
          await rootBundle.load('assets/fonts/cairo/Cairo-ExtraBold.ttf');

      _cairoRegular = pw.Font.ttf(regularFontData);
      _cairoBold = pw.Font.ttf(boldFontData);
      _cairoExtraBold = pw.Font.ttf(extraBoldFontData);

      _fontsInitialized = true;
      print('Cairo fonts from assets initialized successfully');
    } catch (e) {
      print('Error loading local Cairo fonts: $e');
      // Try fallback with Google Fonts as last resort
    }
  }

  /// Get fonts with null safety
  static pw.Font _getRegularFont() {
    if (_cairoRegular == null) {
      throw Exception(
          'Regular font not initialized. Call initializeFonts() first.');
    }
    return _cairoRegular!;
  }

  static pw.Font _getBoldFont() {
    if (_cairoBold == null) {
      throw Exception(
          'Bold font not initialized. Call initializeFonts() first.');
    }
    return _cairoBold!;
  }

  static pw.Font _getExtraBoldFont() {
    if (_cairoExtraBold == null) {
      throw Exception(
          'Extra bold font not initialized. Call initializeFonts() first.');
    }
    return _cairoExtraBold!;
  }

  /// Load asset image as bytes with error handling
  static Future<Uint8List?> _loadAssetImage(String path) async {
    try {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } catch (e) {
      print('Failed to load asset image: $path, Error: $e');
      return null;
    }
  }

  /// Format date in Arabic locale (dd/MM/yyyy)
  static String _formatArabicDate(dynamic value) {
    if (value == null) return "غير محدد";

    DateTime? dateTime;

    try {
      if (value is String) {
        dateTime = DateTime.tryParse(value);
      } else if (value is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is DateTime) {
        dateTime = value;
      }

      if (dateTime == null) return "غير محدد";

      // Format in Arabic numbers
      final formatter = DateFormat('dd/MM/yyyy', 'ar_EG');
      return formatter.format(dateTime);
    } catch (e) {
      return "غير محدد";
    }
  }

  /// Format phone number with proper Arabic formatting
  static String _formatPhoneNumber(dynamic phone) {
    if (phone == null) return "غير محدد";

    String phoneStr = phone.toString().trim();
    if (phoneStr.isEmpty) return "غير محدد";

    // Add leading zero if needed
    if (phoneStr.length == 10 && !phoneStr.startsWith('0')) {
      phoneStr = '0$phoneStr';
    }

    // Format as: 0123-456-7890
    if (phoneStr.length == 11 && phoneStr.startsWith('0')) {
      return '${phoneStr.substring(0, 4)}-${phoneStr.substring(4, 7)}-${phoneStr.substring(7)}';
    }

    return phoneStr;
  }

  /// Format amount with Arabic currency
  static String _formatAmount(dynamic amount) {
    if (amount == null) return "0 ج.م";

    double numAmount = 0.0;
    if (amount is num) {
      numAmount = amount.toDouble();
    } else if (amount is String) {
      numAmount = double.tryParse(amount) ?? 0.0;
    }

    // Format with thousand separators
    final formatter = NumberFormat('#,##0', 'ar_EG');
    return '${formatter.format(numAmount)} ج.م';
  }

  /// Get status text based on end date
  static String _getStatusText(dynamic endsAt) {
    if (endsAt == null) return "غير محدد";

    DateTime? endDate;
    try {
      if (endsAt is String) {
        endDate = DateTime.tryParse(endsAt);
      } else if (endsAt is int) {
        endDate = DateTime.fromMillisecondsSinceEpoch(endsAt);
      } else if (endsAt is DateTime) {
        endDate = endsAt;
      }

      if (endDate == null) return "غير محدد";

      final now = DateTime.now();
      final difference = endDate.difference(now);

      if (difference.isNegative) {
        final daysOverdue = difference.inDays.abs();
        return "متأخر ($daysOverdue يوم)";
      }

      final daysLeft = difference.inDays;
      if (daysLeft == 0) return "ينتهي اليوم";
      if (daysLeft <= 3) return "ينتهي خلال $daysLeft أيام";
      if (daysLeft <= 7) return "ينتهي قريباً";

      return "نشط";
    } catch (e) {
      return "غير محدد";
    }
  }

  /// Get status color based on end date
  static PdfColor _getStatusColor(dynamic endsAt) {
    if (endsAt == null) return PdfColors.grey600;

    DateTime? endDate;
    try {
      if (endsAt is String) {
        endDate = DateTime.tryParse(endsAt);
      } else if (endsAt is int) {
        endDate = DateTime.fromMillisecondsSinceEpoch(endsAt);
      } else if (endsAt is DateTime) {
        endDate = endsAt;
      }

      if (endDate == null) return PdfColors.grey600;

      final now = DateTime.now();
      final difference = endDate.difference(now);

      if (difference.isNegative) return PdfColors.red700; // Overdue

      final daysLeft = difference.inDays;
      if (daysLeft <= 3) return PdfColors.red500; // Critical
      if (daysLeft <= 7) return PdfColors.orange700; // Warning

      return PdfColors.green700; // Active
    } catch (e) {
      return PdfColors.grey600;
    }
  }

  /// Build PDF header with logo and title
  static pw.Widget _buildHeader({
    required String monthName,
    Uint8List? logoBytes,
    required pw.Font boldFont,
    required pw.Font extraBoldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: pw.Column(
        children: [
          // Logo positioned at top-left
          pw.Align(
            alignment: pw.Alignment.topLeft,
            child: _buildLogoWidget(logoBytes, boldFont, isSmaller: true),
          ),
          // Title positioned higher with reduced spacing
          pw.SizedBox(height: 5),
          pw.Center(
            child: pw.Text(
              "كشف المستحقات المالية",
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: extraBoldFont,
                fontSize: 24,
                color: PdfColors.blue800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build logo widget with error handling
  static pw.Widget _buildLogoWidget(Uint8List? logoBytes, pw.Font boldFont,
      {bool isSmaller = false}) {
    final size = isSmaller ? 80.0 : 120.0;
    final fontSize = isSmaller ? 16.0 : 20.0;

    if (logoBytes != null) {
      try {
        return pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Image(
            pw.MemoryImage(logoBytes),
            width: size,
            height: size,
            fit: pw.BoxFit.contain,
          ),
        );
      } catch (e) {
        print('Error loading logo image: $e');
      }
    }

    // Fallback logo without border
    return pw.Container(
      width: size,
      height: size,
      child: pw.Center(
        child: pw.Text(
          "شعار",
          style: pw.TextStyle(
            font: boldFont,
            fontSize: fontSize,
            color: PdfColors.blue800,
          ),
        ),
      ),
    );
  }

  /// Safe string extraction with null handling
  static String _safeString(dynamic value, {String defaultValue = "غير محدد"}) {
    if (value == null) return defaultValue;
    if (value is String)
      return value.trim().isEmpty ? defaultValue : value.trim();
    return value.toString().trim().isEmpty
        ? defaultValue
        : value.toString().trim();
  }

  /// Safe number extraction with null handling
  static double _safeNumber(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  /// Build summary statistics card
  static pw.Widget _buildSummaryCard({
    required List<Map<String, dynamic>> dues,
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font extraBoldFont,
  }) {
    final totalAmount = dues.fold<double>(0, (sum, due) {
      return sum + _safeNumber(due['amount']);
    });

    final totalCount = dues.length;

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 16),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(
          color: PdfColors.blue300,
          width: 2,
        ),
        gradient: pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [
            PdfColors.blue50,
            PdfColors.white,
          ],
        ),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.grey300,
            offset: const PdfPoint(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const pw.EdgeInsets.all(24),
      child: pw.Column(children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(25),
            gradient: pw.LinearGradient(
              colors: [PdfColors.blue600, PdfColors.blue800],
            ),
          ),
          child: pw.Text(
            "ملخص المستحقات",
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: extraBoldFont,
              fontSize: 20,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.SizedBox(height: 25),
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    "إجمالي المبلغ",
                    textDirection: pw.TextDirection.rtl,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 12,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  // Plain value without any style
                  pw.Text(
                    _formatAmount(totalAmount),
                    textDirection: pw.TextDirection.rtl,
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
              _buildModernDivider(),
              pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    "إجمالي العدد",
                    textDirection: pw.TextDirection.rtl,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 12,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  // Plain value without any style
                  pw.Text(
                    totalCount.toString(),
                    textDirection: pw.TextDirection.rtl,
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }

  /// Build modern divider for stat cards
  static pw.Widget _buildModernDivider() {
    return pw.Container(
      width: 3,
      height: 60,
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(2),
        gradient: pw.LinearGradient(
          begin: pw.Alignment.topCenter,
          end: pw.Alignment.bottomCenter,
          colors: [
            PdfColors.blue200,
            PdfColors.blue400,
            PdfColors.blue200,
          ],
        ),
      ),
    );
  }

  /// Build a single stat card used in the summary (title + value)
  static pw.Widget _buildStatCard({
    required String title,
    required String value,
    required PdfColor color,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      width: 200,
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.blue100, width: 1),
        color: PdfColors.white,
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.grey200,
            offset: const PdfPoint(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            textDirection: pw.TextDirection.rtl,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 12,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(8),
              gradient: pw.LinearGradient(
                colors: [color, PdfColors.white],
                begin: pw.Alignment.topCenter,
                end: pw.Alignment.bottomCenter,
              ),
            ),
            child: pw.Text(
              value,
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 16,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build table header
  static pw.TableRow _buildTableHeader({required pw.Font boldFont}) {
    final headerStyle = pw.TextStyle(
      font: boldFont,
      fontSize: 14,
      color: PdfColors.white,
    );

    return pw.TableRow(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.blue700, PdfColors.blue800],
        ),
      ),
      children: [
        _buildHeaderCell("المبلغ", headerStyle),
        _buildHeaderCell("رقم الهاتف", headerStyle),
        _buildHeaderCell("الاسم", headerStyle),
      ],
    );
  }

  /// Build header cell
  static pw.Widget _buildHeaderCell(String text, pw.TextStyle style) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
        style: style,
      ),
    );
  }

  /// Check if due is overdue with null safety
  static bool _isOverdue(dynamic endsAt) {
    if (endsAt == null) return false;

    DateTime? endDate;
    try {
      if (endsAt is String) {
        endDate = DateTime.tryParse(endsAt);
      } else if (endsAt is int) {
        endDate = DateTime.fromMillisecondsSinceEpoch(endsAt);
      } else if (endsAt is DateTime) {
        endDate = endsAt;
      }

      return endDate != null && endDate.isBefore(DateTime.now());
    } catch (e) {
      print('Error checking overdue status: $e');
      return false;
    }
  }

  /// Build table row with null safety
  static pw.TableRow _buildTableRow({
    required Map<String, dynamic> due,
    required int index,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    final isEven = index % 2 == 0;
    final backgroundColor = isEven ? PdfColors.grey50 : PdfColors.white;

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: backgroundColor),
      children: [
        _buildDataCell(
          _formatAmount(due['amount']),
          boldFont,
          color: PdfColors.blue900,
          textAlign: pw.TextAlign.center,
        ),
        _buildDataCell(
          _formatPhoneNumber(due['phone']),
          regularFont,
          textAlign: pw.TextAlign.center,
        ),
        _buildDataCell(
          _safeString(due['name']),
          regularFont,
          textAlign: pw.TextAlign.right,
        ),
      ],
    );
  }

  /// Build data cell
  static pw.Widget _buildDataCell(
    String text,
    pw.Font font, {
    PdfColor? color,
    pw.TextAlign textAlign = pw.TextAlign.right,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        textAlign: textAlign,
        style: pw.TextStyle(
          font: font,
          fontSize: 12,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  /// Main function to build the Arabic dues PDF with enhanced error handling
  static Future<Uint8List> buildDuesPdf({
    required List<Map<String, dynamic>> dues,
    required String monthName,
    String? logoAssetPath,
    Uint8List? logoBytes,
    String companyName = "",
  }) async {
    try {
      print('Starting PDF generation...');

      // Initialize fonts if not already done
      await initializeFonts();

      if (!_fontsInitialized) {
        throw Exception('Fonts initialization failed');
      }

      // Validate input data
      if (dues.isEmpty) {
        throw Exception('No dues data provided');
      }

      print('Fonts initialized, processing ${dues.length} dues');

      // Load logo - always use rece.png only
      Uint8List? logo = await _loadAssetImage('assets/images/rece.png');

      // Get fonts with null safety
      final regularFont = _getRegularFont();
      final boldFont = _getBoldFont();
      final extraBoldFont = _getExtraBoldFont();

      print('Creating PDF document...');

      final doc = pw.Document();

      // Create the widgets list first
      final List<pw.Widget> allWidgets = [];

      // Add main header (only on first page)
      allWidgets.add(_buildHeader(
        monthName: monthName,
        logoBytes: logo,
        boldFont: boldFont,
        extraBoldFont: extraBoldFont,
      ));

      allWidgets.add(pw.SizedBox(height: 20));

      // Add summary card
      allWidgets.add(_buildSummaryCard(
        dues: dues,
        regularFont: regularFont,
        boldFont: boldFont,
        extraBoldFont: extraBoldFont,
      ));

      allWidgets.add(pw.SizedBox(height: 20));

      // Main data table
      if (dues.isNotEmpty) {
        final tableRows = <pw.TableRow>[
          _buildTableHeader(boldFont: boldFont),
        ];

        for (int i = 0; i < dues.length; i++) {
          try {
            tableRows.add(_buildTableRow(
              due: dues[i],
              index: i,
              regularFont: regularFont,
              boldFont: boldFont,
            ));
          } catch (e) {
            print('Error building row $i: $e');
            // Continue with other rows
          }
        }

        allWidgets.add(pw.Table(
          border: pw.TableBorder.all(
            width: 1,
            color: PdfColors.blue300,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.0), // Amount
            1: const pw.FlexColumnWidth(2.5), // Phone
            2: const pw.FlexColumnWidth(3.0), // Name - wider
          },
          children: tableRows,
        ));
      }

      // Create page with simplified header and no footer
      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            theme: pw.ThemeData.withFont(
              base: regularFont,
              bold: boldFont,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          header: (context) {
            // Simple header for subsequent pages - no pageNumber dependency
            try {
              final pageNum = context.pagesCount > 0 && context.pageNumber > 1
                  ? context.pageNumber
                  : null;

              if (pageNum != null && pageNum > 1) {
                return pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "كشف المستحقات - ${_safeString(monthName)}",
                          textDirection: pw.TextDirection.rtl,
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 16,
                            color: PdfColors.blue800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return pw.Container(); // Empty header for first page
            } catch (e) {
              print('Error in header: $e');
              return pw.Container(); // Return empty container on error
            }
          },
          footer: (context) {
            // Empty footer - no footer at all
            return pw.Container();
          },
          build: (context) {
            // Return the pre-built widgets without context dependency
            return allWidgets;
          },
        ),
      );

      print('Generating PDF bytes...');

      // Generate and return the PDF
      final pdfBytes = await doc.save();

      // Validate the generated PDF is not empty
      if (pdfBytes.isEmpty) {
        throw Exception('Generated PDF is empty');
      }

      print('PDF generated successfully, size: ${pdfBytes.length} bytes');
      return pdfBytes;
    } catch (e, stackTrace) {
      print('Error generating PDF: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to generate PDF: $e');
    }
  }

  /// Save PDF directly to device storage and open it
  static Future<File> savePdfToFile({
    required List<Map<String, dynamic>> dues,
    required String monthName,
    String? logoAssetPath,
    Uint8List? logoBytes,
    String companyName = "",
    String? customFileName,
    bool autoOpen = true,
  }) async {
    try {
      // Generate PDF bytes
      final pdfBytes = await buildDuesPdf(
        dues: dues,
        monthName: monthName,
        logoAssetPath: logoAssetPath,
        logoBytes: logoBytes,
        companyName: companyName,
      );

      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Create filename
      final fileName = customFileName ??
          'كشف_المستحقات_${monthName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');

      // Write PDF bytes to file
      await file.writeAsBytes(pdfBytes);

      print('PDF saved to: ${file.path}');

      // Automatically open the PDF if requested
      if (autoOpen) {
        try {
          final result = await OpenFile.open(file.path);
          print('Open file result: ${result.message}');
          if (result.type != ResultType.done) {
            print(
                'Warning: Could not open PDF automatically: ${result.message}');
          }
        } catch (e) {
          print('Error opening PDF: $e');
        }
      }

      return file;
    } catch (e) {
      print('Error saving PDF to file: $e');
      throw Exception('Failed to save PDF: $e');
    }
  }

  /// Save PDF to Downloads folder and open it
  static Future<File> savePdfToDownloads({
    required List<Map<String, dynamic>> dues,
    required String monthName,
    String? logoAssetPath,
    Uint8List? logoBytes,
    String companyName = "",
    String? customFileName,
    bool autoOpen = true,
  }) async {
    try {
      // Generate PDF bytes
      final pdfBytes = await buildDuesPdf(
        dues: dues,
        monthName: monthName,
        logoAssetPath: logoAssetPath,
        logoBytes: logoBytes,
        companyName: companyName,
      );

      // Get the downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create filename with timestamp
      final timestamp =
          DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName =
          customFileName ?? 'كشف_المستحقات_${monthName}_$timestamp.pdf';
      final file = File('${directory.path}/$fileName');

      // Write PDF bytes to file
      await file.writeAsBytes(pdfBytes);

      print('PDF saved to Downloads: ${file.path}');

      // Automatically open the PDF if requested
      if (autoOpen) {
        try {
          final result = await OpenFile.open(file.path);
          print('Open file result: ${result.message}');
          if (result.type != ResultType.done) {
            print(
                'Warning: Could not open PDF automatically: ${result.message}');
          }
        } catch (e) {
          print('Error opening PDF: $e');
        }
      }

      return file;
    } catch (e) {
      print('Error saving PDF to Downloads: $e');
      throw Exception('Failed to save PDF to Downloads: $e');
    }
  }

  /// Generate and directly save PDF to Downloads folder without print preview
  static Future<File> generateAndSavePdf({
    required List<Map<String, dynamic>> dues,
    required String monthName,
    String? logoAssetPath,
    Uint8List? logoBytes,
    String companyName = "",
    String? customFileName,
    bool autoOpen = true,
  }) async {
    try {
      print('Generating PDF directly to Downloads...');

      // Generate PDF bytes
      final pdfBytes = await buildDuesPdf(
        dues: dues,
        monthName: monthName,
        logoAssetPath: logoAssetPath,
        logoBytes: logoBytes,
        companyName: companyName,
      );

      // Get the downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        // Try Downloads folder first
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to external storage
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // iOS saves to Documents directory
        directory = await getApplicationDocumentsDirectory();
      } else {
        // Other platforms
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create unique filename with timestamp
      final timestamp =
          DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName =
          customFileName ?? 'كشف_المستحقات_${monthName}_$timestamp.pdf';
      final file = File('${directory.path}/$fileName');

      // Write PDF bytes directly to file
      await file.writeAsBytes(pdfBytes);

      print('PDF saved successfully to: ${file.path}');

      // Automatically open the PDF if requested
      if (autoOpen) {
        try {
          print('Opening PDF file...');
          final result = await OpenFile.open(file.path);
          print('Open file result: ${result.message}');

          if (result.type == ResultType.done) {
            print('PDF opened successfully');
          } else {
            print('Could not open PDF: ${result.message}');
            // Even if we can't open it, the file was saved successfully
          }
        } catch (e) {
          print('Error opening PDF: $e');
          // File was still saved successfully
        }
      }

      return file;
    } catch (e, stackTrace) {
      print('Error generating and saving PDF: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to generate and save PDF: $e');
    }
  }
}

/// Extension functions for easier usage
extension DuesPdfExtension on List<Map<String, dynamic>> {
  Future<Uint8List> toPdf({
    required String monthName,
    String? logoAssetPath,
    Uint8List? logoBytes,
    String companyName = "",
  }) async {
    return ArabicDuesPdfGenerator.buildDuesPdf(
      dues: this,
      monthName: monthName,
      logoAssetPath: 'assets/images/rece.png', // Always use rece.png
      logoBytes: logoBytes,
      companyName: companyName,
    );
  }

  /// Generate and directly save PDF without print preview
  Future<File> generateAndSave({
    required String monthName,
    String? logoAssetPath,
    Uint8List? logoBytes,
    String companyName = "",
    String? customFileName,
    bool autoOpen = true,
  }) async {
    return ArabicDuesPdfGenerator.generateAndSavePdf(
      dues: this,
      monthName: monthName,
      logoAssetPath: logoAssetPath ?? 'assets/images/rece.png',
      logoBytes: logoBytes,
      companyName: companyName,
      customFileName: customFileName,
      autoOpen: autoOpen,
    );
  }

  /// Save PDF directly to Downloads folder and optionally open it
  Future<File> saveToDownloads({
    required String monthName,
    String? logoAssetPath,
    Uint8List? logoBytes,
    String companyName = "",
    String? customFileName,
    bool autoOpen = true,
  }) async {
    return ArabicDuesPdfGenerator.savePdfToDownloads(
      dues: this,
      monthName: monthName,
      logoAssetPath: 'assets/images/rece.png',
      logoBytes: logoBytes,
      companyName: companyName,
      customFileName: customFileName,
      autoOpen: autoOpen,
    );
  }
}
