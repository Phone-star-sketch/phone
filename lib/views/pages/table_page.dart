import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:device_info_plus/device_info_plus.dart';

class InfoTablePage extends StatefulWidget {
  const InfoTablePage({Key? key}) : super(key: key);

  @override
  _InfoTablePageState createState() => _InfoTablePageState();
}

class _InfoTablePageState extends State<InfoTablePage> {
  final supabaseClient = Supabase.instance.client;
  bool isLoading = true;
  String? error;
  List<Map<String, dynamic>> infoData = [];

  Future<void> fetchData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Start from client table and join related tables
      final response = await supabaseClient
          .from('client')
          .select('''
            *,
            phone(
              id,
              phone_number,
              system(
                id,
                name,
                start_date,
                end_date,
                system_type(
                  id,
                  name,
                  price,
                  category
                )
              )
            )
          ''')
          .order('created_at', ascending: false);

      if (response != null && response is List) {
        debugPrint('Fetched Data: $response');
        setState(() {
          infoData = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'حدث خطأ أثناء تحميل البيانات: $e';
        isLoading = false;
      });
      debugPrint("Error fetching data: $e");
    }
  }

  String formatArabicDate(String? date) {
    if (date == null || date.isEmpty) return 'غير متوفر';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat.yMMMMd('ar').format(parsedDate);
    } catch (e) {
      return 'غير متوفر';
    }
  }

  String formatPhoneNumbers(List<dynamic>? phones) {
    if (phones == null || phones.isEmpty) return 'غير متوفر';
    return phones.join('، ');
  }

  String formatSystems(List<dynamic>? systems) {
    if (systems == null || systems.isEmpty) return 'غير متوفر';
    return systems.join('، ');
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final storage = await Permission.storage.status;
      if (storage.isDenied) {
        await Permission.storage.request();
      }

      if (await Permission.manageExternalStorage.status.isDenied) {
        await Permission.manageExternalStorage.request();
      }
    } else if (Platform.isIOS) {
      final status = await Permission.storage.status;
      if (status.isDenied) {
        await Permission.storage.request();
      }
    }
  }

  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      final sdkVersion = await DeviceInfoPlugin().androidInfo;
      if (sdkVersion.version.sdkInt >= 30) {
        return await Permission.manageExternalStorage.status.isGranted;
      } else {
        return await Permission.storage.status.isGranted;
      }
    } else if (Platform.isIOS) {
      return await Permission.storage.status.isGranted;
    }
    return true;
  }

  Future<Directory?> _getExternalStorageDirectory() async {
    try {
      if (Platform.isAndroid) {
        return await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        return await getApplicationDocumentsDirectory();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting storage directory: $e');
      return null;
    }
  }

  Future<void> _saveFile(List<int> bytes) async {
    try {
      await _requestStoragePermission();

      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يرجى منح الإذن للوصول إلى وحدة التخزين'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final directory = await _getExternalStorageDirectory();
      if (directory == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لم يتم العثور على مجلد التخزين'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final downloadsDir = Directory('${directory.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${downloadsDir.path}/بيانات_العملاء_$timestamp.xlsx');

      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الملف في ${file.path}'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'فتح',
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
      }

      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint('Error saving file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء حفظ الملف'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> generateAndDownloadExcel() async {
    try {
      setState(() {
        isLoading = true;
      });

      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      sheet.appendRow([
        'الاسم',
        'العنوان',
        'الرقم القومي',
        'أرقام الهاتف',
        'الأنظمة المرتبطة',
        'تاريخ انتهاء العرض'
      ]);

      final headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Right,
        backgroundColorHex: '#CCCCCC',
      );

      for (var i = 0; i < 6; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .cellStyle = headerStyle;
      }

      for (var info in infoData) {
        sheet.appendRow([
          info['name'] ?? 'غير متوفر',
          info['address'] ?? 'غير متوفر',
          info['national_id'] ?? 'غير متوفر',
          formatPhoneNumbers(info['phone_numbers']),
          formatSystems(info['system_names']),
          formatArabicDate(info['expire_date']),
        ]);
      }

      final bytes = excel.encode()!;

      if (kIsWeb) {
        final blob = html.Blob([Uint8List.fromList(bytes)]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'بيانات_العملاء.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        await _saveFile(bytes);
      }
    } catch (e) {
      debugPrint('Error generating Excel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء إنشاء ملف Excel'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جدول بيانات العملاء'),
        actions: [
          if (!isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: fetchData,
              tooltip: 'تحديث البيانات',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            columns: const [
                              DataColumn(label: Text('الاسم')),
                              DataColumn(label: Text('العنوان')),
                              DataColumn(label: Text('الرقم القومي')),
                              DataColumn(label: Text('أرقام الهاتف')),
                              DataColumn(label: Text('الأنظمة')),
                              DataColumn(label: Text('تاريخ الإنشاء')),
                              DataColumn(label: Text('تاريخ انتهاء العرض')),
                            ],
                            rows: infoData.map((info) {
                              final phoneData = info['phone'] as List?;
                              
                              final phones = phoneData?.map((p) => p['phone_number'].toString()).toList() ?? [];
                              
                              final systems = phoneData?.expand((p) {
                                final systemsList = (p['system'] as List?)?.map((s) {
                                  final systemType = s['system_type'] as Map<String, dynamic>;
                                  return '${s['name']} (${systemType['price']} جنيه)';
                                }).toList() ?? [];
                                return systemsList;
                              }).toList() ?? [];

                              return DataRow(
                                cells: [
                                  DataCell(Text(info['name'] ?? 'غير متوفر')),
                                  DataCell(Text(info['address'] ?? 'غير متوفر')),
                                  DataCell(Text(info['national_id'] ?? 'غير متوفر')),
                                  DataCell(Text(phones.join(', '))),
                                  DataCell(Text(systems.join(', '))),
                                  DataCell(Text(formatArabicDate(info['created_at']))),
                                  DataCell(Text(formatArabicDate(info['expire_date']))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: !isLoading ? generateAndDownloadExcel : null,
        tooltip: 'تصدير إلى Excel',
        icon: const Icon(Icons.download),
        label: const Text('تصدير'),
      ),
    );
  }
}
