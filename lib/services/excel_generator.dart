import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:isolate';

// Conditional imports for web and mobile
import 'web_stubs.dart' if (dart.library.html) 'dart:html' as html;

class OptimizedExcelGenerator {
  static Future<void> generateClientsReceiptsExcel(List<Client> clients) async {
    try {
      developer.log('=== Starting Optimized Excel Generation ===',
          name: 'OptimizedExcelGenerator');
      developer.log('Input clients count: ${clients.length}',
          name: 'OptimizedExcelGenerator');
      developer.log('Platform: ${kIsWeb ? "Web" : "Mobile"}',
          name: 'OptimizedExcelGenerator');

      final stopwatch = Stopwatch()..start();

      if (clients.isEmpty) {
        _showMessage('لا توجد بيانات عملاء لتصديرها', Colors.orange);
        return;
      }

      // Filter valid clients
      final validClients = clients
          .where((client) =>
              client.id != null &&
              client.name != null &&
              client.name!.isNotEmpty)
          .toList();

      if (validClients.isEmpty) {
        _showMessage('لا توجد بيانات عملاء صالحة', Colors.orange);
        return;
      }

      // Show progress
      _showProgressDialog();

      // For web, skip permission check
      if (!kIsWeb) {
        if (!await _requestPermissions()) {
          if (Get.isDialogOpen == true) Get.back();
          _showMessage('لم يتم منح الصلاحيات المطلوبة', Colors.red);
          return;
        }
      }

      // Batch fetch all client notes at once
      final Map<dynamic, String> clientNotesMap = 
          await _batchGetClientNotes(validClients.map((c) => c.id).toList());

      // Pre-process client data for faster Excel generation
      final List<List<dynamic>> processedData = await _preprocessClientData(validClients, clientNotesMap);

      // Generate Excel in isolate for better performance
      late Excel excel;
      if (validClients.length > 100) {
        excel = await _generateExcelInIsolate(processedData);
      } else {
        excel = await _generateExcelDirectly(processedData);
      }

      // Handle file saving based on platform
      if (kIsWeb) {
        await _downloadForWeb(excel);
      } else {
        await _saveAndShowFile(excel);
      }

      stopwatch.stop();
      developer.log('=== Excel Generation Completed in ${stopwatch.elapsedMilliseconds}ms ===',
          name: 'OptimizedExcelGenerator');
    } catch (e, stackTrace) {
      developer.log('Excel generation failed: $e',
          name: 'OptimizedExcelGenerator', error: e, stackTrace: stackTrace);
      if (Get.isDialogOpen == true) Get.back();
      _showMessage('فشل في إنشاء ملف Excel: ${e.toString()}', Colors.red);
    }
  }

  // Batch fetch all client notes in a single query
  static Future<Map<dynamic, String>> _batchGetClientNotes(List<dynamic> clientIds) async {
    final Map<dynamic, String> notesMap = {};
    
    if (clientIds.isEmpty) return notesMap;

    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('client')
          .select('id, notes')
          .filter('id', 'in', clientIds.where((id) => id != null).toList())
          .timeout(const Duration(seconds: 10));

      for (final row in result) {
        final id = row['id'];
        final notes = row['notes']?.toString() ?? '';
        notesMap[id] = notes.isEmpty ? 'لا توجد ملاحظات' : notes;
      }

      // Fill missing entries
      for (final id in clientIds) {
        if (id != null && !notesMap.containsKey(id)) {
          notesMap[id] = 'لا توجد ملاحظات';
        }
      }
    } catch (e) {
      developer.log('Error batch getting notes: $e',
          name: 'OptimizedExcelGenerator');
      // Fill with default values on error
      for (final id in clientIds) {
        if (id != null) {
          notesMap[id] = 'خطأ في تحميل الملاحظات';
        }
      }
    }

    return notesMap;
  }

  // Pre-process all client data into a simple format
  static Future<List<List<dynamic>>> _preprocessClientData(
      List<Client> clients, Map<dynamic, String> notesMap) async {
    final List<List<dynamic>> processedData = [];
    
    // Calculate totals for summary
    double totalAmount = 0.0;
    
    for (final client in clients) {
      try {
        // Client name
        final name = client.name ?? 'غير محدد';

        // Phone number
        String phone = 'غير متوفر';
        if (client.numbers?.isNotEmpty == true) {
          phone = client.numbers![0].phoneNumber ?? 'غير متوفر';
        }

        // Amount due - Improved calculation
        double amountDue = 0.0;
        if (client.totalCash != null) {
          if (client.totalCash is int) {
            amountDue = (client.totalCash as int).toDouble() * -1;
          } else if (client.totalCash is double) {
            amountDue = (client.totalCash as double) * -1;
          } else if (client.totalCash is num) {
            amountDue = (client.totalCash as num).toDouble() * -1;
          }
        }
        final absoluteAmount = amountDue.abs();
        totalAmount += absoluteAmount;
        final formattedAmount = '${absoluteAmount.toStringAsFixed(0)} ج.م';

        // Systems - Pre-process system names
        String systems = '';
        if (client.numbers?.isNotEmpty == true) {
          final systemNames = <String>[];
          for (final number in client.numbers!) {
            if (number.systems?.isNotEmpty == true) {
              for (final system in number.systems!) {
                final systemName = system.type?.name ?? 'غير محدد';
                if (!systemNames.contains(systemName)) {
                  systemNames.add(systemName);
                }
              }
            }
          }
          systems = systemNames.isNotEmpty ? systemNames.join(', ') : 'لا توجد خدمات';
        } else {
          systems = 'لا توجد خدمات';
        }

        // Notes from pre-fetched map
        final notes = notesMap[client.id] ?? 'لا توجد ملاحظات';

        processedData.add([name, phone, formattedAmount, systems, notes]);
      } catch (e) {
        developer.log('Error preprocessing client ${client.name}: $e',
            name: 'OptimizedExcelGenerator');
        processedData.add(['خطأ في البيانات', 'خطأ', 'خطأ', 'خطأ', 'خطأ في البيانات']);
      }
    }

    // Add summary data at the end
    processedData.add(['SUMMARY', clients.length.toString(), totalAmount.toStringAsFixed(0)]);

    return processedData;
  }

  // Generate Excel directly for smaller datasets
  static Future<Excel> _generateExcelDirectly(List<List<dynamic>> data) async {
    final excel = Excel.createExcel();
    const String sheetName = 'فواتير العملاء';
    final Sheet sheet = excel[sheetName];

    // Add headers with pre-defined style
    _addHeadersOptimized(sheet);

    // Add data rows in batches
    _addDataRowsOptimized(sheet, data);

    return excel;
  }

  // Generate Excel in isolate for larger datasets
  static Future<Excel> _generateExcelInIsolate(List<List<dynamic>> data) async {
    final receivePort = ReceivePort();
    
    await Isolate.spawn(_excelIsolateEntryPoint, {
      'sendPort': receivePort.sendPort,
      'data': data,
    });

    final excelBytes = await receivePort.first as List<int>;
    receivePort.close();

    // Reconstruct Excel from bytes
    final excel = Excel.decodeBytes(excelBytes);
    return excel;
  }

  // Isolate entry point for Excel generation
  static void _excelIsolateEntryPoint(Map<String, dynamic> message) {
    try {
      final SendPort sendPort = message['sendPort'];
      final List<List<dynamic>> data = message['data'];

      final excel = Excel.createExcel();
      const String sheetName = 'فواتير العملاء';
      final Sheet sheet = excel[sheetName];

      // Add headers
      _addHeadersOptimized(sheet);

      // Add data rows
      _addDataRowsOptimized(sheet, data);

      // Send back the Excel bytes
      final bytes = excel.save();
      sendPort.send(bytes);
    } catch (e) {
      // Send error back to main isolate
      throw Exception('Isolate error: $e');
    }
  }

  static void _addHeadersOptimized(Sheet sheet) {
    final headers = [
      'اسم العميل',
      'رقم الهاتف',
      'المبلغ المستحق',
      'الخدمات',
      'الملاحظات'
    ];

    // Pre-define header style
    final headerStyle = CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: '#4CAF50',
      fontColorHex: '#FFFFFF',
    );

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = headerStyle;
    }
  }

  static void _addDataRowsOptimized(Sheet sheet, List<List<dynamic>> data) {
    // Pre-define row styles for better performance
    final evenRowStyle = CellStyle(
      backgroundColorHex: '#F5F5F5',
      fontSize: 12,
      horizontalAlign: HorizontalAlign.Right,
    );

    final oddRowStyle = CellStyle(
      backgroundColorHex: '#FFFFFF',
      fontSize: 12,
      horizontalAlign: HorizontalAlign.Right,
    );

    final summaryStyle = CellStyle(
      bold: true,
      fontSize: 13,
      backgroundColorHex: '#E3F2FD',
      fontColorHex: '#1976D2',
    );

    for (int rowIndex = 0; rowIndex < data.length; rowIndex++) {
      final rowData = data[rowIndex];
      final excelRow = rowIndex + 1;

      // Check if this is summary data
      if (rowData[0] == 'SUMMARY') {
        // Add summary
        final summaryRowStart = excelRow + 1;
        
        // Total clients
        _setCellValueWithStyle(sheet, 0, summaryRowStart, 'إجمالي العملاء:', summaryStyle);
        _setCellValueWithStyle(sheet, 1, summaryRowStart, rowData[1], summaryStyle);
        
        // Total amount
        _setCellValueWithStyle(sheet, 0, summaryRowStart + 1, 'إجمالي المبلغ:', summaryStyle);
        _setCellValueWithStyle(sheet, 1, summaryRowStart + 1, '${rowData[2]} ج.م', summaryStyle);
        
        break;
      }

      // Regular data row
      final isEvenRow = excelRow % 2 == 0;
      final rowStyle = isEvenRow ? evenRowStyle : oddRowStyle;

      for (int colIndex = 0; colIndex < rowData.length && colIndex < 5; colIndex++) {
        _setCellValueWithStyle(sheet, colIndex, excelRow, rowData[colIndex], rowStyle);
      }
    }
  }

  static void _setCellValueWithStyle(Sheet sheet, int col, int row, dynamic value, CellStyle style) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = value;
    cell.cellStyle = style;
  }

  // Web download method (unchanged)
  static Future<void> _downloadForWeb(Excel excel) async {
    if (!kIsWeb) {
      throw UnsupportedError('Web download is only supported on web platform');
    }

    try {
      final fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception('فشل في إنشاء بيانات Excel');
      }

      final fileName =
          'فواتير_العملاء_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      await _webDownload(fileBytes, fileName);

      if (Get.isDialogOpen == true) Get.back();

      developer.log('File downloaded successfully for web: $fileName',
          name: 'OptimizedExcelGenerator');

      Get.showSnackbar(
        GetSnackBar(
          title: 'تم بنجاح ✅',
          message: 'تم تحميل ملف Excel بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade50,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.check_circle, color: Colors.green),
        ),
      );
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      developer.log('Error downloading file for web: $e',
          name: 'OptimizedExcelGenerator');
      throw Exception('فشل في تحميل الملف: ${e.toString()}');
    }
  }

  static Future<void> _webDownload(List<int> fileBytes, String fileName) async {
    if (!kIsWeb) {
      throw UnsupportedError('Web download not supported on this platform');
    }

    if (kIsWeb) {
      final blob = html.Blob([Uint8List.fromList(fileBytes)]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();

      html.Url.revokeObjectUrl(url);
    }
  }

  // Remaining methods (unchanged for brevity but optimized where needed)
  static Future<bool> _requestPermissions() async {
    if (kIsWeb) return true;

    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        if (androidInfo.version.sdkInt >= 30) {
          var status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            status = await Permission.manageExternalStorage.request();
            if (!status.isGranted) {
              return true;
            }
          }
          return status.isGranted;
        } else {
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
          return status.isGranted;
        }
      }
      return true;
    } catch (e) {
      developer.log('Permission error: $e', name: 'OptimizedExcelGenerator');
      return true;
    }
  }

  static Future<void> _saveAndShowFile(Excel excel) async {
    if (kIsWeb) {
      throw UnsupportedError('Mobile file saving is not supported on web');
    }

    try {
      final directory = await _getStorageDirectory();
      final fileName =
          'فواتير_العملاء_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${directory.path}/$fileName';

      final fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception('فشل في إنشاء بيانات Excel');
      }

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      if (Get.isDialogOpen == true) Get.back();

      developer.log('File saved successfully: $filePath',
          name: 'OptimizedExcelGenerator');

      try {
        final result = await OpenFile.open(filePath);
        if (result.type == ResultType.done) {
          Get.showSnackbar(
            GetSnackBar(
              title: 'تم بنجاح ✅',
              message: 'تم إنشاء وفتح ملف Excel بنجاح',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.shade50,
              duration: const Duration(seconds: 2),
              icon: const Icon(Icons.check_circle, color: Colors.green),
            ),
          );
        } else {
          _showSuccessMessage(fileName, filePath);
        }
      } catch (openError) {
        developer.log('Error opening file: $openError',
            name: 'OptimizedExcelGenerator');
        _showSuccessMessage(fileName, filePath);
      }
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      developer.log('Error saving file: $e', name: 'OptimizedExcelGenerator');
      throw Exception('فشل في حفظ الملف: ${e.toString()}');
    }
  }

  static Future<Directory> _getStorageDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('File system not supported on web');
    }

    if (Platform.isAndroid) {
      try {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          return downloadsDir;
        }

        final documentsDir = Directory('/storage/emulated/0/Documents');
        if (await documentsDir.exists()) {
          return documentsDir;
        }
      } catch (e) {
        developer.log('Error accessing public directories: $e',
            name: 'OptimizedExcelGenerator');
      }

      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          return externalDir;
        }
      } catch (e) {
        developer.log('Error getting external storage: $e',
            name: 'OptimizedExcelGenerator');
      }

      return await getApplicationDocumentsDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  static void _showProgressDialog() {
    if (Get.isDialogOpen == true) return;

    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  kIsWeb ? 'جاري تحضير التحميل...' : 'جاري إنشاء ملف Excel...',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void _showSuccessMessage(String fileName, String filePath) {
    Get.showSnackbar(
      GetSnackBar(
        title: 'تم بنجاح ✅',
        messageText: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تم إنشاء ملف Excel بنجاح',
              style: TextStyle(
                color: Colors.green[900],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'اسم الملف: $fileName',
              style: TextStyle(
                color: Colors.green[800],
                fontSize: 12,
              ),
            ),
          ],
        ),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade50,
        duration: const Duration(seconds: 8),
        mainButton: TextButton(
          onPressed: () async {
            try {
              final result = await OpenFile.open(filePath);
              if (result.type == ResultType.done) {
                Get.closeCurrentSnackbar();
              } else {
                _showMessage('تم حفظ الملف: $filePath', Colors.green);
              }
            } catch (e) {
              developer.log('Error opening file: $e',
                  name: 'OptimizedExcelGenerator');
              _showMessage('تم حفظ الملف في: $filePath', Colors.green);
            }
          },
          child: Text(
            'فتح الملف',
            style: TextStyle(
              color: Colors.green[900],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  static void _showMessage(String message, Color color) {
    Get.showSnackbar(
      GetSnackBar(
        title: color == Colors.red ? 'خطأ' : 'تنبيه',
        message: message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: color.withOpacity(0.1),
        messageText: Text(
          message,
          style: TextStyle(color: color.withOpacity(0.8)),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Backward compatibility aliases
class SimpleExcelGenerator {
  static Future<void> generateClientsReceiptsExcel(List<Client> clients) async {
    return OptimizedExcelGenerator.generateClientsReceiptsExcel(clients);
  }
}

class ClientReceiptsExcelGenerator {
  static Future<void> generateExcelSheet(List<Client> clients) async {
    return OptimizedExcelGenerator.generateClientsReceiptsExcel(clients);
  }
}