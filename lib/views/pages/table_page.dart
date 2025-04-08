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
  List<Map<String, dynamic>> filteredData = [];
  String searchQuery = '';
  String sortColumn = 'created_at';
  bool sortAscending = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await supabaseClient.from('client').select('''
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
          ''').order('created_at', ascending: false);

      if (response != null && response is List) {
        setState(() {
          infoData = List<Map<String, dynamic>>.from(response);
          filteredData = infoData;
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

  void filterData(String query) {
    setState(() {
      searchQuery = query;
      filteredData = infoData.where((item) {
        final name = item['name']?.toString().toLowerCase() ?? '';
        final address = item['address']?.toString().toLowerCase() ?? '';
        final nationalId = item['national_id']?.toString().toLowerCase() ?? '';
        final phoneNumbers = formatPhoneNumbers(item['phone']).toLowerCase();
        return name.contains(query.toLowerCase()) ||
            address.contains(query.toLowerCase()) ||
            nationalId.contains(query.toLowerCase()) ||
            phoneNumbers.contains(query.toLowerCase());
      }).toList();
    });
  }

  void sortData(String column) {
    setState(() {
      if (sortColumn == column) {
        sortAscending = !sortAscending;
      } else {
        sortColumn = column;
        sortAscending = true;
      }

      filteredData.sort((a, b) {
        final aValue = a[column] ?? '';
        final bValue = b[column] ?? '';
        return sortAscending
            ? aValue.toString().compareTo(bValue.toString())
            : bValue.toString().compareTo(aValue.toString());
      });
    });
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
    try {
      return phones
          .map((phone) {
            if (phone is Map<String, dynamic>) {
              return phone['phone_number']?.toString() ?? '';
            }
            return '';
          })
          .where((number) => number.isNotEmpty)
          .join('، ');
    } catch (e) {
      debugPrint('Error formatting phone numbers: $e');
      return 'غير متوفر';
    }
  }

  String formatSystems(List<dynamic>? systems) {
    if (systems == null || systems.isEmpty) return 'غير متوفر';
    try {
      return systems
          .map((system) {
            if (system is Map<String, dynamic>) {
              return system['name']?.toString() ?? '';
            }
            return '';
          })
          .where((name) => name.isNotEmpty)
          .join('، ');
    } catch (e) {
      debugPrint('Error formatting systems: $e');
      return 'غير متوفر';
    }
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

      // Headers
      sheet.appendRow([
        'الاسم',
        'العنوان',
        'الرقم القومي',
        'أرقام الهاتف',
        'الأنظمة المرتبطة',
        'تاريخ انتهاء العرض',
        'تاريخ الإنشاء'
      ]);

      // Style for headers
      final headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Right,
        backgroundColorHex: '#4CAF50',
        fontColorHex: '#FFFFFF',
      );

      for (var i = 0; i < 7; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .cellStyle = headerStyle;
      }

      // Data rows
      for (var info in infoData) {
        final phones = info['phone'] as List<dynamic>?;
        final systems = phones?.expand((phone) {
          if (phone is Map<String, dynamic>) {
            final system = phone['system'];
            if (system is List) {
              return system;
            }
          }
          return [];
        }).toList();

        sheet.appendRow([
          info['name'] ?? 'غير متوفر',
          info['address'] ?? 'غير متوفر',
          info['national_id'] ?? 'غير متوفر',
          formatPhoneNumbers(phones),
          formatSystems(systems),
          formatArabicDate(info['expire_date']),
          formatArabicDate(info['created_at']),
        ]);
      }

      // Auto-size columns
      for (var i = 0; i < 7; i++) {
        sheet.setColWidth(i, 20);
      }

      final bytes = excel.encode()!;

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download',
              'بيانات_العملاء_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        await _saveFile(bytes);
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'حدث خطأ أثناء تصدير البيانات: $e';
      });
      debugPrint('Error generating Excel: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بيانات العملاء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchData,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: generateAndDownloadExcel,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'بحث',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: filterData,
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(child: Text(error!))
                    : filteredData.isEmpty
                        ? const Center(child: Text('لا توجد بيانات متاحة'))
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth,
                                    ),
                                    child: DataTable(
                                      showCheckboxColumn: false,
                                      dataRowHeight: 60,
                                      headingRowHeight: 50,
                                      horizontalMargin: 20,
                                      columnSpacing: 20,
                                      columns: [
                                        DataColumn(
                                          label: const Text('الاسم'),
                                          onSort: (columnIndex, ascending) =>
                                              sortData('name'),
                                        ),
                                        DataColumn(
                                          label: const Text('العنوان'),
                                          onSort: (columnIndex, ascending) =>
                                              sortData('address'),
                                        ),
                                        DataColumn(
                                          label: const Text('الرقم القومي'),
                                          onSort: (columnIndex, ascending) =>
                                              sortData('national_id'),
                                        ),
                                        const DataColumn(
                                            label: Text('أرقام الهاتف')),
                                        const DataColumn(
                                            label: Text('الأنظمة المرتبطة')),
                                        DataColumn(
                                          label:
                                              const Text('تاريخ انتهاء العرض'),
                                          onSort: (columnIndex, ascending) =>
                                              sortData('expire_date'),
                                        ),
                                      ],
                                      rows: List<DataRow>.generate(
                                        filteredData.length,
                                        (index) {
                                          final info = filteredData[index];
                                          final phones =
                                              info['phone'] as List<dynamic>?;
                                          final systems =
                                              phones?.expand((phone) {
                                            if (phone is Map<String, dynamic>) {
                                              final system = phone['system'];
                                              if (system is List) {
                                                return system;
                                              }
                                            }
                                            return [];
                                          }).toList();

                                          return DataRow(
                                            onSelectChanged: (selected) {
                                              // Handle row selection if needed
                                            },
                                            cells: [
                                              DataCell(
                                                Text(
                                                  info['name']?.toString() ??
                                                      'غير متوفر',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  info['address']?.toString() ??
                                                      'غير متوفر',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  info['national_id']
                                                          ?.toString() ??
                                                      'غير متوفر',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  formatPhoneNumbers(phones),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  formatSystems(systems),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  formatArabicDate(
                                                      info['expire_date']),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
