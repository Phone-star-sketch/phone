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
import 'dart:async';
import 'dart:convert';

// Use a conditional import for web-specific functionality
import 'web_stubs.dart' if (dart.library.html) 'dart:html' as html;

class OptimizedExcelGenerator {
  static const int WEB_CHUNK_SIZE = 20; // Reduced chunk size
  static const int MOBILE_ISOLATE_THRESHOLD = 100;
  static const int MAX_DB_BATCH_SIZE =
      50; // Maximum batch size for database queries
  static const int MAX_RETRIES = 3;
  static const Duration RETRY_DELAY = Duration(milliseconds: 500);

  // Connection pool to limit concurrent database connections
  static int _activeConnections = 0;
  static const int MAX_CONCURRENT_CONNECTIONS = 3;

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

      // Platform-specific processing with connection management
      if (kIsWeb) {
        await _processForWebWithConnectionPool(validClients);
      } else {
        await _processForMobileWithConnectionPool(validClients);
      }

      stopwatch.stop();
      developer.log(
          '=== Excel Generation Completed in ${stopwatch.elapsedMilliseconds}ms ===',
          name: 'OptimizedExcelGenerator');
    } catch (e, stackTrace) {
      developer.log('Excel generation failed: $e',
          name: 'OptimizedExcelGenerator', error: e, stackTrace: stackTrace);
      if (Get.isDialogOpen == true) Get.back();
      _showMessage('فشل في إنشاء ملف Excel: ${e.toString()}', Colors.red);
    }
  }

  // Web processing with connection pooling
  static Future<void> _processForWebWithConnectionPool(
      List<Client> validClients) async {
    try {
      final chunks = _chunkList(validClients, WEB_CHUNK_SIZE);
      final List<List<dynamic>> allProcessedData = [];
      double totalAmount = 0.0;

      // Update progress dialog
      _updateProgressDialog('جاري معالجة البيانات... (0/${chunks.length})');

      // Process chunks with connection limiting
      for (int i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];

        // Wait for available connection slot
        await _waitForConnectionSlot();

        try {
          _activeConnections++;

          // Batch fetch notes for this chunk with retry
          final clientIds = chunk.map((c) => c.id).toList();
          final notesMap = await _batchGetClientNotesWithRetry(clientIds);

          // Process chunk data
          final chunkData = await _preprocessClientDataChunk(chunk, notesMap);

          // Calculate chunk total
          for (final rowData in chunkData) {
            if (rowData.length >= 3 && rowData[2] is String) {
              final amountStr = rowData[2] as String;
              final amount = double.tryParse(
                      amountStr.replaceAll(RegExp(r'[^\d.]'), '')) ??
                  0.0;
              totalAmount += amount;
            }
          }

          allProcessedData.addAll(chunkData);
        } finally {
          _activeConnections--;
        }

        // Update progress
        _updateProgressDialog(
            'جاري معالجة البيانات... (${i + 1}/${chunks.length})');

        // Small delay between chunks
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Add summary
      allProcessedData.add([
        'SUMMARY',
        validClients.length.toString(),
        totalAmount.toStringAsFixed(0)
      ]);

      // Generate Excel with web optimization
      _updateProgressDialog('جاري إنشاء ملف Excel...');
      final excel = await _generateExcelForWeb(allProcessedData);

      // Download file
      _updateProgressDialog('جاري تحضير التحميل...');
      await _downloadForWeb(excel);
    } catch (e) {
      throw Exception('Web processing failed: $e');
    }
  }

  // Mobile processing with connection pooling
  static Future<void> _processForMobileWithConnectionPool(
      List<Client> validClients) async {
    if (!await _requestPermissions()) {
      if (Get.isDialogOpen == true) Get.back();
      _showMessage('لم يتم منح الصلاحيات المطلوبة', Colors.red);
      return;
    }

    // Use offline processing for mobile to avoid database issues
    final processedData = await _preprocessClientDataOffline(validClients);

    // Generate Excel
    late Excel excel;
    if (validClients.length > MOBILE_ISOLATE_THRESHOLD) {
      excel = await _generateExcelInIsolate(processedData);
    } else {
      excel = await _generateExcelDirectly(processedData);
    }

    await _saveAndShowFile(excel);
  }

  // Wait for available connection slot
  static Future<void> _waitForConnectionSlot() async {
    while (_activeConnections >= MAX_CONCURRENT_CONNECTIONS) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  // Batch fetch with retry logic and connection management
  static Future<Map<dynamic, String>> _batchGetClientNotesWithRetry(
      List<dynamic> clientIds) async {
    Map<dynamic, String> notesMap = {};

    if (clientIds.isEmpty) return notesMap;

    // Split into smaller batches to avoid channel limits
    final batches = _chunkList(
        clientIds.where((id) => id != null).toList(), MAX_DB_BATCH_SIZE);

    for (final batch in batches) {
      int retryCount = 0;
      bool success = false;

      while (!success && retryCount < MAX_RETRIES) {
        try {
          final supabase = Supabase.instance.client;
          final result = await supabase
              .from('client')
              .select('id, notes')
              .filter('id', 'in', batch)
              .timeout(const Duration(seconds: 15)); // Increased timeout

          for (final row in result) {
            final id = row['id'];
            final notes = row['notes']?.toString() ?? '';
            notesMap[id] = notes.isEmpty ? 'لا توجد ملاحظات' : notes;
          }

          success = true;
        } catch (e) {
          retryCount++;
          developer.log(
              'Batch query retry $retryCount for batch size ${batch.length}: $e',
              name: 'OptimizedExcelGenerator');

          if (retryCount < MAX_RETRIES) {
            // Exponential backoff
            await Future.delayed(Duration(
                milliseconds: RETRY_DELAY.inMilliseconds * retryCount));
          } else {
            developer.log('Max retries reached for batch, using fallback',
                name: 'OptimizedExcelGenerator');
            // Fill with fallback values
            for (final id in batch) {
              notesMap[id] = 'خطأ في تحميل الملاحظات';
            }
          }
        }
      }

      // Small delay between batches
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Fill missing entries with defaults
    for (final id in clientIds) {
      if (id != null && !notesMap.containsKey(id)) {
        notesMap[id] = 'لا توجد ملاحظات';
      }
    }

    return notesMap;
  }

  // Offline processing for mobile (no database calls)
  static Future<List<List<dynamic>>> _preprocessClientDataOffline(
      List<Client> clients) async {
    final List<List<dynamic>> processedData = [];
    double totalAmount = 0.0;

    _updateProgressDialog('جاري معالجة بيانات ${clients.length} عميل...');

    for (final client in clients) {
      try {
        // Client name
        final name = client.name ?? 'غير محدد';

        // Phone number
        String phone = 'غير متوفر';
        if (client.numbers?.isNotEmpty == true) {
          phone = client.numbers![0].phoneNumber ?? 'غير متوفر';
        }

        // Amount due
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
        final formattedAmount = '${absoluteAmount.toStringAsFixed(0)} ';

        // Systems
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
          systems =
              systemNames.isNotEmpty ? systemNames.join(', ') : 'لا توجد خدمات';
        } else {
          systems = 'لا توجد خدمات';
        }

        // Use existing notes from client object (if available) instead of database
        final notes = 'استخدم التطبيق لعرض الملاحظات';

        processedData.add([name, phone, formattedAmount, systems, notes]);
      } catch (e) {
        developer.log('Error preprocessing client ${client.name}: $e',
            name: 'OptimizedExcelGenerator');
        processedData
            .add(['خطأ في البيانات', 'خطأ', 'خطأ', 'خطأ', 'خطأ في البيانات']);
      }
    }

    // Add summary
    processedData.add(
        ['SUMMARY', clients.length.toString(), totalAmount.toStringAsFixed(0)]);

    return processedData;
  }

  // Chunk list into smaller pieces
  static List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (int i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  // Process a chunk of client data
  static Future<List<List<dynamic>>> _preprocessClientDataChunk(
      List<Client> clients, Map<dynamic, String> notesMap) async {
    final List<List<dynamic>> processedData = [];

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
        final formattedAmount = '${absoluteAmount.toStringAsFixed(0)} ';

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
          systems =
              systemNames.isNotEmpty ? systemNames.join(', ') : 'لا توجد خدمات';
        } else {
          systems = 'لا توجد خدمات';
        }

        // Notes from pre-fetched map
        final notes = notesMap[client.id] ?? 'لا توجد ملاحظات';

        processedData.add([name, phone, formattedAmount, systems, notes]);
      } catch (e) {
        developer.log('Error preprocessing client ${client.name}: $e',
            name: 'OptimizedExcelGenerator');
        processedData
            .add(['خطأ في البيانات', 'خطأ', 'خطأ', 'خطأ', 'خطأ في البيانات']);
      }
    }

    return processedData;
  }

  // Web-optimized Excel generation
  static Future<Excel> _generateExcelForWeb(List<List<dynamic>> data) async {
    final excel = Excel.createExcel();
    const String sheetName = 'فواتير العملاء';
    final Sheet sheet = excel[sheetName];

    // Add headers with pre-defined style
    _addHeadersOptimized(sheet);

    // Add data rows in chunks with periodic yielding
    await _addDataRowsOptimizedWeb(sheet, data);

    return excel;
  }

  // Web-optimized row addition with yielding
  static Future<void> _addDataRowsOptimizedWeb(
      Sheet sheet, List<List<dynamic>> data) async {
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

      // Yield control periodically to prevent UI blocking
      if (rowIndex % 25 == 0 && rowIndex > 0) {
        await Future.delayed(const Duration(microseconds: 1));
      }

      // Check if this is summary data
      if (rowData[0] == 'SUMMARY') {
        // Add summary
        final summaryRowStart = excelRow + 1;

        // Total clients
        _setCellValueWithStyle(
            sheet, 0, summaryRowStart, 'إجمالي العملاء:', summaryStyle);
        _setCellValueWithStyle(
            sheet, 1, summaryRowStart, rowData[1], summaryStyle);

        // Total amount
        _setCellValueWithStyle(
            sheet, 0, summaryRowStart + 1, 'إجمالي المبلغ:', summaryStyle);
        _setCellValueWithStyle(
            sheet, 1, summaryRowStart + 1, '${rowData[2]} ', summaryStyle);

        break;
      }

      // Regular data row
      final isEvenRow = excelRow % 2 == 0;
      final rowStyle = isEvenRow ? evenRowStyle : oddRowStyle;

      for (int colIndex = 0;
          colIndex < rowData.length && colIndex < 5;
          colIndex++) {
        _setCellValueWithStyle(
            sheet, colIndex, excelRow, rowData[colIndex], rowStyle);
      }
    }
  }

  // Update progress dialog with new message
  static void _updateProgressDialog(String message) {
    if (!Get.isDialogOpen!) return;

    // Close current dialog
    Get.back();

    // Show new progress dialog
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
                  message,
                  textAlign: TextAlign.center,
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

  // Batch fetch all client notes in a single query
  static Future<Map<dynamic, String>> _batchGetClientNotes(
      List<dynamic> clientIds) async {
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
        final formattedAmount = '${absoluteAmount.toStringAsFixed(0)} ';

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
          systems =
              systemNames.isNotEmpty ? systemNames.join(', ') : 'لا توجد خدمات';
        } else {
          systems = 'لا توجد خدمات';
        }

        // Notes from pre-fetched map
        final notes = notesMap[client.id] ?? 'لا توجد ملاحظات';

        processedData.add([name, phone, formattedAmount, systems, notes]);
      } catch (e) {
        developer.log('Error preprocessing client ${client.name}: $e',
            name: 'OptimizedExcelGenerator');
        processedData
            .add(['خطأ في البيانات', 'خطأ', 'خطأ', 'خطأ', 'خطأ في البيانات']);
      }
    }

    // Add summary data at the end
    processedData.add(
        ['SUMMARY', clients.length.toString(), totalAmount.toStringAsFixed(0)]);

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
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
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
        _setCellValueWithStyle(
            sheet, 0, summaryRowStart, 'إجمالي العملاء:', summaryStyle);
        _setCellValueWithStyle(
            sheet, 1, summaryRowStart, rowData[1], summaryStyle);

        // Total amount
        _setCellValueWithStyle(
            sheet, 0, summaryRowStart + 1, 'إجمالي المبلغ:', summaryStyle);
        _setCellValueWithStyle(
            sheet, 1, summaryRowStart + 1, '${rowData[2]} ', summaryStyle);

        break;
      }

      // Regular data row
      final isEvenRow = excelRow % 2 == 0;
      final rowStyle = isEvenRow ? evenRowStyle : oddRowStyle;

      for (int colIndex = 0;
          colIndex < rowData.length && colIndex < 5;
          colIndex++) {
        _setCellValueWithStyle(
            sheet, colIndex, excelRow, rowData[colIndex], rowStyle);
      }
    }
  }

  static void _setCellValueWithStyle(
      Sheet sheet, int col, int row, dynamic value, CellStyle style) {
    final cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = value;
    cell.cellStyle = style;
  }

  // Web download method (optimized with better error handling)
  static Future<void> _downloadForWeb(Excel excel) async {
    if (!kIsWeb) {
      throw UnsupportedError('Web download is only supported on web platform');
    }

    try {
      // Generate file bytes with progress
      _updateProgressDialog('جاري تحضير الملف للتحميل...');

      final fileBytes = excel.save();
      if (fileBytes == null || fileBytes.isEmpty) {
        throw Exception('فشل في إنشاء بيانات Excel');
      }

      final fileName =
          'فواتير_العملاء_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      // Use optimized web download with fallback
      try {
        await _webDownloadOptimized(fileBytes, fileName);
      } catch (downloadError) {
        developer.log(
            'Primary download failed, trying alternative: $downloadError',
            name: 'OptimizedExcelGenerator');

        // Alternative download method
        await _alternativeWebDownload(fileBytes, fileName);
      }

      if (Get.isDialogOpen == true) Get.back();

      developer.log('File download initiated successfully for web: $fileName',
          name: 'OptimizedExcelGenerator');

      Get.showSnackbar(
        GetSnackBar(
          title: 'تم بنجاح ✅',
          message: 'تم تحضير ملف Excel للتحميل',
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

      // Show user-friendly error message
      _showMessage('فشل في تحميل الملف. يرجى المحاولة مرة أخرى.', Colors.red);
    }
  }

  // Optimized web download with better memory management and error handling
  static Future<void> _webDownloadOptimized(
      List<int> fileBytes, String fileName) async {
    if (!kIsWeb) {
      throw UnsupportedError('Web download not supported on this platform');
    }

    try {
      // Use dynamic import to avoid compilation issues
      await _performWebDownload(fileBytes, fileName);
    } catch (e) {
      developer.log('Web download error: $e', name: 'OptimizedExcelGenerator');
      // Fallback: show save dialog with file content
      _showWebDownloadFallback(fileName);
    }
  }

  // Separate method for web download to isolate web-specific code
  static Future<void> _performWebDownload(
      List<int> fileBytes, String fileName) async {
    if (!kIsWeb) return;

    try {
      // Create blob with proper MIME type
      final blob = html.Blob([Uint8List.fromList(fileBytes)]);

      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create and configure download link
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('style', 'display: none')
        ..setAttribute('download', fileName)
        ..setAttribute('type',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

      // Add to DOM, click, and remove
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();

      // Clean up object URL after a delay
      Future.delayed(const Duration(seconds: 1), () {
        try {
          html.Url.revokeObjectUrl(url);
        } catch (e) {
          developer.log('Error revoking URL: $e',
              name: 'OptimizedExcelGenerator');
        }
      });

      // Small delay to ensure download starts
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      developer.log('Perform web download error: $e',
          name: 'OptimizedExcelGenerator');
      rethrow;
    }
  }

  // Fallback method for web download issues
  static void _showWebDownloadFallback(String fileName) {
    Get.showSnackbar(
      GetSnackBar(
        title: 'تحميل الملف',
        message: 'يرجى النقر بزر الماوس الأيمن على الرابط وحفظ الملف',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade50,
        duration: const Duration(seconds: 5),
        icon: const Icon(Icons.download, color: Colors.orange),
        mainButton: TextButton(
          onPressed: () {
            Get.closeCurrentSnackbar();
          },
          child: const Text('موافق'),
        ),
      ),
    );
  }

  // Alternative web download method
  static Future<void> _alternativeWebDownload(
      List<int> fileBytes, String fileName) async {
    if (!kIsWeb) return;

    try {
      // Convert to base64 data URL as fallback
      final base64String = base64Encode(fileBytes);
      final dataUrl =
          'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64String';

      // Create download link with data URL
      final anchor = html.AnchorElement(href: dataUrl)
        ..setAttribute('download', fileName)
        ..setAttribute('style', 'display: none');

      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();

      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      developer.log('Alternative download failed: $e',
          name: 'OptimizedExcelGenerator');
      _showWebDownloadFallback(fileName);
    }
  }

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
