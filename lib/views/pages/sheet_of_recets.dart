import 'dart:io';
import 'dart:async';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/system.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/client_bottom_sheet_controller.dart';
import 'package:phone_system_app/models/system_type.dart';

class ClientReceiptsExcelGenerator {
  static Future<void> generateExcelSheet(List<Client> clients) async {
    try {
      // Add debugging log
      developer.log('Starting Excel generation for ${clients.length} clients',
          name: 'ClientReceiptsExcelGenerator');

      // Validate input
      if (clients.isEmpty) {
        Get.showSnackbar(
          GetSnackBar(
            title: 'تنبيه',
            message: 'لا توجد بيانات عملاء لتصديرها',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange[100]!,
            messageText: Text(
              'لا توجد بيانات عملاء لتصديرها',
              style: TextStyle(color: Colors.orange[900]),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Filter valid clients
      List<Client> validClients = clients.where(_isValidClient).toList();
      developer.log('Valid clients after filtering: ${validClients.length}',
          name: 'ClientReceiptsExcelGenerator');

      if (validClients.isEmpty) {
        Get.showSnackbar(
          GetSnackBar(
            title: 'تحذير',
            message: 'لا توجد بيانات عملاء صالحة لتصديرها',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange[100]!,
            messageText: Text(
              'لا توجد بيانات عملاء صالحة لتصديرها',
              style: TextStyle(color: Colors.orange[900]),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          Get.showSnackbar(
            GetSnackBar(
              title: 'خطأ',
              message: 'يجب منح صلاحية الوصول للتخزين لحفظ الملف',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red[100]!,
              messageText: Text(
                'يجب منح صلاحية الوصول للتخزين لحفظ الملف',
                style: TextStyle(color: Colors.red[900]),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
      }

      // Create Excel workbook
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['فواتير العملاء'];
      excel.delete('Sheet1'); // Remove default sheet

      // Set up headers with Arabic text and styling - Updated with more columns
      List<String> headers = [
        'اسم العميل',
        'رقم الهاتف',
        'المبلغ المستحق',
        'الخدمات المشترك بها',
        'حالة الدفع للخدمات',
        'تاريخ الإنشاء',
        'الملاحظات الحالية',
        'حالة الملاحظة',
      ];

      // Add headers to first row with styling
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 12,
          fontFamily: getFontFamily(FontFamily.Arial),
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
          backgroundColorHex: '#4CAF50',
          fontColorHex: '#FFFFFF',
        );
      }

      // Add client data rows - Use validClients instead of clients
      int rowIndex = 1;
      for (Client client in validClients) {
        developer.log('Processing client: ${client.name} (ID: ${client.id})',
            name: 'ClientReceiptsExcelGenerator');

        // Client Name
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = client.name ?? 'غير محدد';

        // Phone Number
        String phoneNumber = 'غير متوفر';
        if (client.numbers?.isNotEmpty == true) {
          phoneNumber = client.numbers![0].phoneNumber ?? 'غير متوفر';
        }
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = phoneNumber;

        // Amount Due (convert to positive for display)
        double amountDue = ((client.totalCash ?? 0) * -1).toDouble();
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = '${amountDue.toStringAsFixed(0)} ج.م';

        // Get detailed systems information (same as cards)
        Map<String, dynamic> systemsInfo =
            await _getDetailedClientSystemsInfo(client);

        // Systems (get all systems for this client)
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = systemsInfo['systemsText'];

        // System Payment Status
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = systemsInfo['paymentStatus'];

        // Creation Date
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .value = systemsInfo['creationDate'];

        // Notes - Fetch from Supabase database (same as cards)
        String notesText = await _getClientNotesFromDatabase(client.id);
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
            .value = notesText;

        // Note Status
        String noteStatus =
            notesText == 'لا توجد ملاحظات' ? 'بدون ملاحظات' : 'يوجد ملاحظة';
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
            .value = noteStatus;

        // Apply alternating row colors for better readability
        String bgColor = rowIndex % 2 == 0 ? '#F5F5F5' : '#FFFFFF';
        for (int col = 0; col < headers.length; col++) {
          var cell = sheetObject.cell(
              CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
          cell.cellStyle = CellStyle(
            backgroundColorHex: bgColor,
            fontSize: 11,
            fontFamily: getFontFamily(FontFamily.Arial),
            horizontalAlign:
                HorizontalAlign.Right, // Right align for Arabic text
            verticalAlign: VerticalAlign.Center,
          );
        }

        rowIndex++;
      }

      // Add summary row - Use validClients for calculations
      var summaryRowIndex = rowIndex + 1;
      sheetObject
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 0, rowIndex: summaryRowIndex))
          .value = 'إجمالي عدد العملاء:';
      sheetObject
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 1, rowIndex: summaryRowIndex))
          .value = validClients.length.toString();

      // Calculate total amount due
      double totalAmount = validClients.fold(
          0.0, (sum, client) => sum + ((client.totalCash ?? 0) * -1));
      sheetObject
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 0, rowIndex: summaryRowIndex + 1))
          .value = 'إجمالي المبلغ المستحق:';
      sheetObject
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 1, rowIndex: summaryRowIndex + 1))
          .value = '${totalAmount.toStringAsFixed(0)} ج.م';

      // Count clients with notes
      int clientsWithNotes = 0;
      for (Client client in validClients) {
        String notes = await _getClientNotesFromDatabase(client.id);
        if (notes != 'لا توجد ملاحظات') clientsWithNotes++;
      }

      sheetObject
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 0, rowIndex: summaryRowIndex + 2))
          .value = 'عدد العملاء مع ملاحظات:';
      sheetObject
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 1, rowIndex: summaryRowIndex + 2))
          .value = clientsWithNotes.toString();

      // Style summary rows
      for (int row = summaryRowIndex; row <= summaryRowIndex + 2; row++) {
        for (int col = 0; col < 2; col++) {
          var cell = sheetObject.cell(
              CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
          cell.cellStyle = CellStyle(
            bold: true,
            fontSize: 12,
            fontFamily: getFontFamily(FontFamily.Arial),
            backgroundColorHex: '#E3F2FD',
            fontColorHex: '#1976D2',
          );
        }
      }

      // Set column widths for better appearance
      _setColumnWidths(sheetObject, headers.length);

      // Save file
      String fileName =
          'فواتير_العملاء_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      await _saveExcelFile(excel, fileName);

      developer.log(
          'Excel file generated successfully with ${validClients.length} clients',
          name: 'ClientReceiptsExcelGenerator');
    } catch (e) {
      developer.log('Error generating Excel sheet: $e',
          name: 'ClientReceiptsExcelGenerator');

      Get.showSnackbar(
        GetSnackBar(
          title: 'خطأ',
          message: 'فشل في إنشاء ملف Excel: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100]!,
          messageText: Text(
            'فشل في إنشاء ملف Excel: ${e.toString()}',
            style: TextStyle(color: Colors.red[900]),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Enhanced method to get detailed systems information (same logic as cards) - Add error protection
  static Future<Map<String, dynamic>> _getDetailedClientSystemsInfo(
      Client client) async {
    List<String> systemNames = [];
    List<String> paymentStatuses = [];
    String creationDate = 'غير محدد';

    try {
      // Ensure client data is valid before processing
      if (client.id == null) {
        throw Exception('Client ID is null');
      }

      // Use the same approach as ClientReceiptCard for loading systems
      final String controllerTag =
          'temp_excel_${client.id}_${DateTime.now().millisecondsSinceEpoch}';

      try {
        final tempController =
            Get.put(ClientBottomSheetController(), tag: controllerTag);
        await tempController.setClient(client);
        final systems = tempController.getClientSystems();

        // Get visible systems using same logic as cards
        final visibleSystems = _getVisibleSystems(systems);

        for (var system in visibleSystems) {
          String systemText = system.type?.name ?? 'غير محدد';
          if (system.type?.price != null) {
            systemText += ' (${system.type!.price} ج.م)';
          }
          systemNames.add(systemText);

          // Payment status
          bool isPaid = _isSystemPaid(system);
          paymentStatuses.add(isPaid ? 'مدفوع' : 'غير مدفوع');

          // Get creation date from first system
          if (creationDate == 'غير محدد' && system.createdAt != null) {
            creationDate =
                '${system.createdAt!.day}/${system.createdAt!.month}/${system.createdAt!.year}';
          }
        }

        await Future.delayed(const Duration(milliseconds: 50));
      } finally {
        if (Get.isRegistered<ClientBottomSheetController>(tag: controllerTag)) {
          Get.delete<ClientBottomSheetController>(
              tag: controllerTag, force: true);
        }
      }

      // Fallback: try to get systems from client numbers if controller failed
      if (systemNames.isEmpty && client.numbers?.isNotEmpty == true) {
        for (var number in client.numbers!) {
          if (number.systems?.isNotEmpty == true) {
            for (var system in number.systems!) {
              String systemText = system.type?.name ?? 'غير محدد';
              if (system.type?.price != null) {
                systemText += ' (${system.type!.price} ج.م)';
              }
              systemNames.add(systemText);

              bool isPaid = _isSystemPaid(system);
              paymentStatuses.add(isPaid ? 'مدفوع' : 'غير مدفوع');

              if (creationDate == 'غير محدد' && system.createdAt != null) {
                creationDate =
                    '${system.createdAt!.day}/${system.createdAt!.month}/${system.createdAt!.year}';
              }
            }
          }
        }
      }
    } catch (e) {
      developer.log(
          'Error getting detailed systems info for client ${client.id}: $e',
          name: 'ClientReceiptsExcelGenerator');
    }

    return {
      'systemsText':
          systemNames.isEmpty ? 'لا توجد خدمات' : systemNames.join('، '),
      'paymentStatus':
          paymentStatuses.isEmpty ? 'غير محدد' : paymentStatuses.join('، '),
      'creationDate': creationDate,
    };
  }

  // Helper methods from ClientReceiptCard
  static List<System> _getVisibleSystems(List<System> systems) {
    return systems.where((system) {
      if (system.type!.category == SystemCategory.mobileInternet) {
        // Show other services only if not paid and within collection period
        bool isPaid = _isSystemPaid(system);
        bool shouldShow = _shouldShowSystem(system);
        return !isPaid && shouldShow;
      }
      // Always show flex systems
      return true;
    }).toList();
  }

  static bool _isSystemPaid(System system) {
    // Check if system is marked as paid
    bool isPaid = system.name?.contains('[مدفوع]') ?? false;
    return isPaid;
  }

  static bool _shouldShowSystem(System system) {
    if (system.type!.category == SystemCategory.mobileInternet) {
      if (system.createdAt != null) {
        try {
          final accountController = Get.find<AccountClientInfo>();
          final collectionDay = accountController.currentAccount.day;
          final nextCollection = DateTime(
            system.createdAt!.month == 12
                ? system.createdAt!.year + 1
                : system.createdAt!.year,
            system.createdAt!.month == 12 ? 1 : system.createdAt!.month + 1,
            collectionDay,
          );
          return !DateTime.now().isAfter(nextCollection);
        } catch (e) {
          developer.log('Error checking system show status: $e',
              name: 'ClientReceiptsExcelGenerator');
          return true;
        }
      }
    }
    return true;
  }

  static Future<String> _getClientSystemsText(Client client) async {
    List<String> systemNames = [];

    try {
      if (client.numbers?.isNotEmpty == true) {
        for (var number in client.numbers!) {
          if (number.systems?.isNotEmpty == true) {
            for (var system in number.systems!) {
              String systemText = system.type?.name ?? 'غير محدد';
              if (system.type?.price != null) {
                systemText += ' (${system.type!.price} ج.م)';
              }
              systemNames.add(systemText);
            }
          }
        }
      }
    } catch (e) {
      developer.log('Error getting systems text for client ${client.id}: $e',
          name: 'ClientReceiptsExcelGenerator');
    }

    return systemNames.isEmpty ? 'لا توجد خدمات' : systemNames.join('، ');
  }

  static void _setColumnWidths(Sheet sheet, int columnCount) {
    // The excel package does not support setting column widths directly.
    // This method is intentionally left empty.
  }

  static Future<void> _saveExcelFile(Excel excel, String fileName) async {
    try {
      // Get the Downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        // Try different Android storage paths
        List<String> possiblePaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Documents',
          '/sdcard/Download',
          '/sdcard/Documents',
        ];

        for (String path in possiblePaths) {
          Directory testDir = Directory(path);
          if (await testDir.exists()) {
            directory = testDir;
            break;
          }
        }

        // Fallback to external storage directory
        directory ??= await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('لا يمكن الوصول لمجلد التحميل');
      }

      String filePath = '${directory.path}/$fileName';

      // Save the Excel file
      var fileBytes = excel.save();
      if (fileBytes != null) {
        File file = File(filePath);
        await file.writeAsBytes(fileBytes);

        // Show success message with option to open file
        Get.showSnackbar(
          GetSnackBar(
            title: 'تم بنجاح',
            message: 'تم حفظ ملف Excel في: ${directory.path}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green[100]!,
            messageText: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تم حفظ ملف Excel بنجاح',
                  style: TextStyle(
                      color: Colors.green[900], fontWeight: FontWeight.bold),
                ),
                Text(
                  'اسم الملف: $fileName',
                  style: TextStyle(color: Colors.green[800], fontSize: 12),
                ),
                Text(
                  'المسار: ${directory.path}',
                  style: TextStyle(color: Colors.green[700], fontSize: 10),
                ),
              ],
            ),
            duration: const Duration(seconds: 8),
            icon: const Icon(Icons.check_circle, color: Colors.green),
            mainButton: TextButton(
              onPressed: () async {
                try {
                  await OpenFile.open(filePath);
                } catch (e) {
                  developer.log('Error opening file: $e',
                      name: 'ClientReceiptsExcelGenerator');
                  Get.showSnackbar(
                    GetSnackBar(
                      title: 'تنبيه',
                      message: 'لا يمكن فتح الملف تلقائياً',
                      backgroundColor: Colors.orange[100]!,
                      messageText: Text(
                        'لا يمكن فتح الملف تلقائياً، يرجى البحث عنه في مجلد التحميل',
                        style: TextStyle(color: Colors.orange[900]),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
                Get.closeCurrentSnackbar();
              },
              child: Text(
                'فتح الملف',
                style: TextStyle(
                    color: Colors.green[900], fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );

        developer.log('Excel file saved successfully: $filePath',
            name: 'ClientReceiptsExcelGenerator');
      } else {
        throw Exception('فشل في حفظ الملف - البيانات فارغة');
      }
    } catch (e) {
      developer.log('Error saving Excel file: $e',
          name: 'ClientReceiptsExcelGenerator');
      rethrow; // Re-throw to be caught by the calling method
    }
  }

  // Method to fetch notes directly from Supabase
  static Future<String> _getClientNotesFromDatabase(dynamic clientId) async {
    if (clientId == null) {
      return 'لا توجد ملاحظات';
    }

    try {
      final supabase = Supabase.instance.client;

      developer.log('Fetching notes for client ID: $clientId',
          name: 'ClientReceiptsExcelGenerator');

      // Use a timeout to prevent hanging
      final result = await supabase
          .from('client')
          .select('notes')
          .eq('id', clientId)
          .maybeSingle()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => null,
          );

      String notes = result?['notes']?.toString() ?? '';

      developer.log('Fetched notes for client $clientId: "$notes"',
          name: 'ClientReceiptsExcelGenerator');

      return notes.isEmpty ? 'لا توجد ملاحظات' : notes;
    } on TimeoutException catch (e) {
      developer.log('Timeout fetching notes for client $clientId: $e',
          name: 'ClientReceiptsExcelGenerator');
      return 'لا توجد ملاحظات';
    } catch (e) {
      // Handle various Supabase errors gracefully
      String errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('channelratelimitreached') ||
          errorMessage.contains('too many channels') ||
          errorMessage.contains('rate limit') ||
          errorMessage.contains('connection')) {
        developer.log(
            'Supabase connection issue while fetching notes for client $clientId: $e',
            name: 'ClientReceiptsExcelGenerator');
      } else {
        developer.log('Error fetching notes for client $clientId: $e',
            name: 'ClientReceiptsExcelGenerator');
      }

      return 'لا توجد ملاحظات';
    }
  }

  // Helper method to validate client data before processing - Add null safety
  static bool _isValidClient(Client client) {
    try {
      bool isValid = client.id != null &&
          client.name != null &&
          client.name!.isNotEmpty &&
          client.totalCash != null;

      if (!isValid) {
        developer.log(
            'Invalid client found: ID=${client.id}, Name=${client.name}, TotalCash=${client.totalCash}',
            name: 'ClientReceiptsExcelGenerator');
      }

      return isValid;
    } catch (e) {
      developer.log('Error validating client: $e',
          name: 'ClientReceiptsExcelGenerator');
      return false;
    }
  }

  // Method to generate Excel with error handling for each client
  static Future<void> generateExcelSheetSafe(List<Client> clients) async {
    // Filter out invalid clients
    List<Client> validClients = clients.where(_isValidClient).toList();

    if (validClients.isEmpty) {
      Get.showSnackbar(
        GetSnackBar(
          title: 'تحذير',
          message: 'لا توجد بيانات عملاء صالحة لتصديرها',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[100]!,
          messageText: Text(
            'لا توجد بيانات عملاء صالحة لتصديرها',
            style: TextStyle(color: Colors.orange[900]),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    await generateExcelSheet(validClients);
  }

  // Utility method to create a formatted date string
  static String _getFormattedDate() {
    DateTime now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
  }

  // Method to generate Excel with custom filename
  static Future<void> generateExcelSheetWithCustomName(
      List<Client> clients, String customName) async {
    try {
      // Add debugging
      developer.log(
          'Starting custom Excel generation for ${clients.length} clients with name: $customName',
          name: 'ClientReceiptsExcelGenerator');

      // Validate input
      if (clients.isEmpty) {
        Get.showSnackbar(
          GetSnackBar(
            title: 'تنبيه',
            message: 'لا توجد بيانات عملاء لتصديرها',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange[100]!,
            messageText: Text(
              'لا توجد بيانات عملاء لتصديرها',
              style: TextStyle(color: Colors.orange[900]),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Filter valid clients
      List<Client> validClients = clients.where(_isValidClient).toList();
      developer.log('Valid clients after filtering: ${validClients.length}',
          name: 'ClientReceiptsExcelGenerator');

      if (validClients.isEmpty) {
        Get.showSnackbar(
          GetSnackBar(
            title: 'تحذير',
            message: 'لا توجد بيانات عملاء صالحة لتصديرها',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange[100]!,
            messageText: Text(
              'لا توجد بيانات عملاء صالحة لتصديرها',
              style: TextStyle(color: Colors.orange[900]),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Follow the same process as generateExcelSheet but with custom filename
      String fileName = '${customName}_${_getFormattedDate()}.xlsx';

      // Create Excel workbook
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['فواتير العملاء'];
      excel.delete('Sheet1');

      // Set up headers - Updated with new columns
      List<String> headers = [
        'اسم العميل',
        'رقم الهاتف',
        'المبلغ المستحق',
        'الخدمات المشترك بها',
        'حالة الدفع للخدمات',
        'تاريخ الإنشاء',
        'الملاحظات الحالية',
        'حالة الملاحظة',
      ];

      // Add headers with styling
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 12,
          fontFamily: getFontFamily(FontFamily.Arial),
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
          backgroundColorHex: '#4CAF50',
          fontColorHex: '#FFFFFF',
        );
      }

      // Process client data - Use validClients instead of clients
      int rowIndex = 1;
      for (Client client in validClients) {
        developer.log('Processing client: ${client.name} (ID: ${client.id})',
            name: 'ClientReceiptsExcelGenerator');

        // Add client data to row
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = client.name ?? 'غير محدد';

        String phoneNumber = 'غير متوفر';
        if (client.numbers?.isNotEmpty == true) {
          phoneNumber = client.numbers![0].phoneNumber ?? 'غير متوفر';
        }
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = phoneNumber;

        double amountDue = ((client.totalCash ?? 0) * -1).toDouble();
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = '${amountDue.toStringAsFixed(0)} ج.م';

        // Get detailed systems information
        Map<String, dynamic> systemsInfo =
            await _getDetailedClientSystemsInfo(client);

        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = systemsInfo['systemsText'];

        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = systemsInfo['paymentStatus'];

        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .value = systemsInfo['creationDate'];

        String notesText = await _getClientNotesFromDatabase(client.id);
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
            .value = notesText;

        String noteStatus =
            notesText == 'لا توجد ملاحظات' ? 'بدون ملاحظات' : 'يوجد ملاحظة';
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
            .value = noteStatus;

        // Style the row
        String bgColor = rowIndex % 2 == 0 ? '#F5F5F5' : '#FFFFFF';
        for (int col = 0; col < headers.length; col++) {
          var cell = sheetObject.cell(
              CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
          cell.cellStyle = CellStyle(
            backgroundColorHex: bgColor,
            fontSize: 11,
            fontFamily: getFontFamily(FontFamily.Arial),
            horizontalAlign: HorizontalAlign.Right,
            verticalAlign: VerticalAlign.Center,
          );
        }

        rowIndex++;
      }

      // Add summary - Use validClients for calculations
      var summaryRowIndex = rowIndex + 1;
      sheetObject
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 0, rowIndex: summaryRowIndex))
          .value = 'إجمالي عدد العملاء:';
      sheetObject
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 1, rowIndex: summaryRowIndex))
          .value = validClients.length.toString();

      // Calculate total amount due
      double totalAmount = validClients.fold(
          0.0, (sum, client) => sum + ((client.totalCash ?? 0) * -1));
      sheetObject
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 0, rowIndex: summaryRowIndex + 1))
          .value = 'إجمالي المبلغ المستحق:';
      sheetObject
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 1, rowIndex: summaryRowIndex + 1))
          .value = '${totalAmount.toStringAsFixed(0)} ج.م';

      // Count clients with notes
      int clientsWithNotes = 0;
      for (Client client in validClients) {
        String notes = await _getClientNotesFromDatabase(client.id);
        if (notes != 'لا توجد ملاحظات') clientsWithNotes++;
      }

      sheetObject
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 0, rowIndex: summaryRowIndex + 2))
          .value = 'عدد العملاء مع ملاحظات:';
      sheetObject
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 1, rowIndex: summaryRowIndex + 2))
          .value = clientsWithNotes.toString();

      // Style summary rows
      for (int row = summaryRowIndex; row <= summaryRowIndex + 2; row++) {
        for (int col = 0; col < 2; col++) {
          var cell = sheetObject.cell(
              CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
          cell.cellStyle = CellStyle(
            bold: true,
            fontSize: 12,
            fontFamily: getFontFamily(FontFamily.Arial),
            backgroundColorHex: '#E3F2FD',
            fontColorHex: '#1976D2',
          );
        }
      }

      _setColumnWidths(sheetObject, headers.length);
      await _saveExcelFile(excel, fileName);

      developer.log(
          'Excel file generated successfully with ${validClients.length} clients',
          name: 'ClientReceiptsExcelGenerator');
    } catch (e) {
      developer.log('Error generating custom Excel sheet: $e',
          name: 'ClientReceiptsExcelGenerator');

      Get.showSnackbar(
        GetSnackBar(
          title: 'خطأ',
          message: 'فشل في إنشاء ملف Excel المخصص',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100]!,
          messageText: Text(
            'فشل في إنشاء ملف Excel المخصص: ${e.toString()}',
            style: TextStyle(color: Colors.red[900]),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
