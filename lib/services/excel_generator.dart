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

class SimpleExcelGenerator {
  static Future<void> generateClientsReceiptsExcel(List<Client> clients) async {
    try {
      developer.log('=== Starting Simple Excel Generation ===',
          name: 'SimpleExcelGenerator');
      developer.log('Input clients count: ${clients.length}',
          name: 'SimpleExcelGenerator');

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

      // Check permissions
      if (!await _requestPermissions()) {
        if (Get.isDialogOpen == true) Get.back();
        _showMessage('لم يتم منح الصلاحيات المطلوبة', Colors.red);
        return;
      }

      // Create Excel with proper sheet handling - Fixed to avoid delete error
      final excel = Excel.createExcel();
      const String sheetName = 'فواتير العملاء';

      // Directly create the sheet with the desired name (no delete needed)
      final Sheet sheet = excel[sheetName];

      // Add headers
      _addHeaders(sheet);

      // Add client data
      await _addClientData(sheet, validClients);

      // Add summary
      _addSummary(sheet, validClients);

      // Save file
      await _saveAndShowFile(excel);

      developer.log('=== Excel Generation Completed ===',
          name: 'SimpleExcelGenerator');
    } catch (e, stackTrace) {
      developer.log('Excel generation failed: $e',
          name: 'SimpleExcelGenerator', error: e, stackTrace: stackTrace);
      _showMessage('فشل في إنشاء ملف Excel: ${e.toString()}', Colors.red);
    }
  }

  static Future<bool> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        if (androidInfo.version.sdkInt >= 30) {
          // Android 11+ - Use MANAGE_EXTERNAL_STORAGE
          var status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            status = await Permission.manageExternalStorage.request();
            if (!status.isGranted) {
              // Fallback to app-specific directory
              return true; // We can still write to app directory
            }
          }
          return status.isGranted;
        } else {
          // Android 10 and below
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
          return status.isGranted;
        }
      }
      return true; // iOS doesn't need storage permission
    } catch (e) {
      developer.log('Permission error: $e', name: 'SimpleExcelGenerator');
      return true; // Continue with app directory if permission fails
    }
  }

  static void _addHeaders(Sheet sheet) {
    final headers = [
      'اسم العميل',
      'رقم الهاتف',
      'المبلغ المستحق',
      'الخدمات', // Changed from 'عدد الخدمات' to 'الخدمات' to include names
      'الملاحظات'
    ];

    for (int i = 0; i < headers.length; i++) {
      _setCellValue(sheet, i, 0, headers[i]);

      // Apply header styling - Fixed deprecated properties
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: '#4CAF50', // Green color hex
        fontColorHex: '#FFFFFF', // White color hex
      );
    }
  }

  static Future<void> _addClientData(Sheet sheet, List<Client> clients) async {
    for (int index = 0; index < clients.length; index++) {
      final client = clients[index];
      final row = index + 1;

      try {
        // Client name
        _setCellValue(sheet, 0, row, client.name ?? 'غير محدد');

        // Phone number
        String phone = 'غير متوفر';
        if (client.numbers?.isNotEmpty == true) {
          phone = client.numbers![0].phoneNumber ?? 'غير متوفر';
        }
        _setCellValue(sheet, 1, row, phone);

        // Amount due - Improved null safety and type handling
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
        _setCellValue(
            sheet, 2, row, '${absoluteAmount.toStringAsFixed(0)} ج.م');

        // Systems - Collect system names instead of count
        String systems = '';
        if (client.numbers?.isNotEmpty == true) {
          for (final number in client.numbers!) {
            if (number.systems?.isNotEmpty == true) {
              for (final system in number.systems!) {
                systems += '${system.type?.name ?? 'غير محدد'}, ';
              }
            }
          }
        }
        if (systems.isNotEmpty) {
          systems = systems.substring(
              0, systems.length - 2); // Remove last comma and space
        } else {
          systems = 'لا توجد خدمات';
        }
        _setCellValue(sheet, 3, row, systems);

        // Notes with better error handling
        String notes = 'لا توجد ملاحظات';
        try {
          notes = await _getClientNotes(client.id).timeout(
            const Duration(seconds: 3),
            onTimeout: () => 'انتهت مهلة تحميل الملاحظات',
          );
        } catch (e) {
          developer.log('Error getting notes for client ${client.id}: $e',
              name: 'SimpleExcelGenerator');
          notes = 'خطأ في تحميل الملاحظات';
        }
        _setCellValue(sheet, 4, row, notes);

        // Style row
        _styleRow(sheet, row, 5);
      } catch (e) {
        developer.log('Error processing client ${client.name}: $e',
            name: 'SimpleExcelGenerator');
        // Continue with error data
        _setCellValue(sheet, 0, row, client.name ?? 'خطأ في البيانات');
        _setCellValue(sheet, 1, row, 'خطأ');
        _setCellValue(sheet, 2, row, 'خطأ');
        _setCellValue(sheet, 3, row, 'خطأ');
        _setCellValue(sheet, 4, row, 'خطأ في البيانات');
        _styleRow(sheet, row, 5);
      }
    }
  }

  static Future<String> _getClientNotes(dynamic clientId) async {
    if (clientId == null) return 'لا توجد ملاحظات';

    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('client')
          .select('notes')
          .eq('id', clientId)
          .maybeSingle();

      if (result == null) return 'لا توجد ملاحظات';

      final notes = result['notes']?.toString() ?? '';
      return notes.isEmpty ? 'لا توجد ملاحظات' : notes;
    } catch (e) {
      developer.log('Error getting notes for client $clientId: $e',
          name: 'SimpleExcelGenerator');
      return 'خطأ في تحميل الملاحظات';
    }
  }

  static void _setCellValue(Sheet sheet, int col, int row, dynamic value) {
    final cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = value;
  }

  static void _styleRow(Sheet sheet, int row, int colCount) {
    final bgColor =
        row % 2 == 0 ? '#F5F5F5' : '#FFFFFF'; // Gray/White alternating

    for (int col = 0; col < colCount; col++) {
      final cell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
      cell.cellStyle = CellStyle(
        backgroundColorHex: bgColor,
        fontSize: 12,
        horizontalAlign: HorizontalAlign.Right,
      );
    }
  }

  static void _addSummary(Sheet sheet, List<Client> clients) {
    final summaryRow = clients.length + 2;

    // Total clients
    _setCellValue(sheet, 0, summaryRow, 'إجمالي العملاء:');
    _setCellValue(sheet, 1, summaryRow, clients.length.toString());

    // Total amount - Improved calculation
    double totalAmount = 0.0;
    for (final client in clients) {
      if (client.totalCash != null) {
        double clientAmount = 0.0;
        if (client.totalCash is int) {
          clientAmount = (client.totalCash as int).toDouble();
        } else if (client.totalCash is double) {
          clientAmount = client.totalCash as double;
        } else if (client.totalCash is num) {
          clientAmount = (client.totalCash as num).toDouble();
        }
        totalAmount += (clientAmount * -1).abs();
      }
    }

    _setCellValue(sheet, 0, summaryRow + 1, 'إجمالي المبلغ:');
    _setCellValue(
        sheet, 1, summaryRow + 1, '${totalAmount.toStringAsFixed(0)} ج.م');

    // Style summary
    for (int row = summaryRow; row <= summaryRow + 1; row++) {
      for (int col = 0; col < 2; col++) {
        final cell = sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 13,
          backgroundColorHex: '#E3F2FD', // Light blue
          fontColorHex: '#1976D2', // Dark blue
        );
      }
    }
  }

  static Future<void> _saveAndShowFile(Excel excel) async {
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

      developer.log('File saved successfully: $filePath',
          name: 'SimpleExcelGenerator');

      // Automatically try to open the file
      try {
        final result = await OpenFile.open(filePath);
        if (result.type == ResultType.done) {
          // File opened successfully, show brief success message
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
          // Fallback to manual open option
          _showSuccessMessage(fileName, filePath);
        }
      } catch (openError) {
        developer.log('Error opening file: $openError',
            name: 'SimpleExcelGenerator');
        // Fallback to manual open option
        _showSuccessMessage(fileName, filePath);
      }
    } catch (e) {
      developer.log('Error saving file: $e', name: 'SimpleExcelGenerator');
      throw Exception('فشل في حفظ الملف: ${e.toString()}');
    }
  }

  static Future<Directory> _getStorageDirectory() async {
    if (Platform.isAndroid) {
      try {
        // Try Downloads folder first
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          return downloadsDir;
        }

        // Try Documents folder
        final documentsDir = Directory('/storage/emulated/0/Documents');
        if (await documentsDir.exists()) {
          return documentsDir;
        }
      } catch (e) {
        developer.log('Error accessing public directories: $e',
            name: 'SimpleExcelGenerator');
      }

      // Fallback to external storage directory
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          return externalDir;
        }
      } catch (e) {
        developer.log('Error getting external storage: $e',
            name: 'SimpleExcelGenerator');
      }

      // Last fallback - app documents directory
      return await getApplicationDocumentsDirectory();
    } else {
      // iOS
      return await getApplicationDocumentsDirectory();
    }
  }

  static void _showProgressDialog() {
    if (Get.isDialogOpen == true) return; // Prevent multiple dialogs

    Get.dialog(
      PopScope(
        // Updated from WillPopScope
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
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'جاري إنشاء ملف Excel...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                  name: 'SimpleExcelGenerator');
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

// Backward compatibility alias
class ClientReceiptsExcelGenerator {
  static Future<void> generateExcelSheet(List<Client> clients) async {
    return SimpleExcelGenerator.generateClientsReceiptsExcel(clients);
  }
}
