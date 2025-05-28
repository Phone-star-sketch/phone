import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class FilterSystemsPage extends StatefulWidget {
  const FilterSystemsPage({Key? key}) : super(key: key);

  @override
  _FilterSystemsPageState createState() => _FilterSystemsPageState();
}

class _FilterSystemsPageState extends State<FilterSystemsPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  String? selectedSystem;
  List<Map<String, dynamic>> systems = [];
  List<Map<String, dynamic>> filteredClients = [];
  String searchQuery = '';
  String? error;
  bool _initialized = false;

  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initializePage());
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    if (!mounted) return;
    await fetchSystems();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_hasMoreData && !isLoading) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (!_hasMoreData || isLoading) return;

    _currentPage++;
    await fetchClientsBySystem(selectedSystem!, isLoadMore: true);
  }

  Future<void> fetchSystems() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await supabase
          .from('system_type')
          .select()
          .order('name')
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          systems = List<Map<String, dynamic>>.from(response ?? []);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'حدث خطأ في تحميل البيانات: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchClientsBySystem(String systemId,
      {bool isLoadMore = false}) async {
    try {
      if (!isLoadMore) {
        setState(() {
          isLoading = true;
          error = null;
          _currentPage = 0;
          _hasMoreData = true;
          filteredClients = [];
        });
      }

      final response = await supabase
          .from('client')
          .select('''
            *,
            phone!inner(
              phone_number,
              system!inner(
                id,
                name,
                start_date,
                end_date,
                system_type!inner(
                  id,
                  name,
                  price
                )
              )
            )
          ''')
          .eq('phone.system.system_type.id', systemId)
          .range(_currentPage * _pageSize, (_currentPage + 1) * _pageSize - 1)
          .order('name')
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          if (isLoadMore) {
            filteredClients
                .addAll(List<Map<String, dynamic>>.from(response ?? []));
          } else {
            filteredClients = List<Map<String, dynamic>>.from(response ?? []);
          }
          _hasMoreData = (response as List).length == _pageSize;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'حدث خطأ في تحميل بيانات العملاء: $e';
          isLoading = false;
        });
      }
    }
  }

  void filterData(String query) {
    if (mounted) {
      setState(() {
        searchQuery = query.toLowerCase();
      });
    }
  }

  Future<void> _downloadWebFile(List<int> bytes) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download',
          'بيانات_العملاء_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _saveFile(List<int> bytes) async {
    try {
      // Get the app's internal documents directory (no permissions needed)
      final directory = await getApplicationSupportDirectory();
      if (directory == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم العثور على مجلد التخزين')),
          );
        }
        return;
      }

      // Create a subdirectory for Excel files if it doesn't exist
      final excelDir = Directory('${directory.path}/SystemReports');
      if (!await excelDir.exists()) {
        await excelDir.create(recursive: true);
      }

      // Generate unique filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${excelDir.path}/عملاء_النظام_$timestamp.xlsx');

      // Save the file asynchronously
      await file.writeAsBytes(bytes);

      if (mounted) {
        // Show success message with open option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الملف في ${file.path}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'فتح',
              onPressed: () async {
                try {
                  await OpenFile.open(file.path);
                } catch (e) {
                  debugPrint('Error opening file: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('فشل في فتح الملف')),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
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

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      if (await Permission.manageExternalStorage.status.isDenied) {
        await Permission.manageExternalStorage.request();
      }
    } else if (Platform.isIOS) {
      await Permission.storage.request();
    }
  }

  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      final sdkVersion = await DeviceInfoPlugin().androidInfo;
      if (sdkVersion.version.sdkInt >= 30) {
        return await Permission.manageExternalStorage.status.isGranted;
      }
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

  Future<void> exportToExcel() async {
    if (filteredClients.isEmpty) return;

    try {
      setState(() {
        isLoading = true;
      });

      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      final headers = [
        'الاسم',
        'العنوان',
        'الرقم القومي',
        'رقم الهاتف',
        'نوع النظام',
        'تاريخ البداية',
        'تاريخ الانتهاء',
        'السعر'
      ];

      sheet.appendRow(headers);

      final headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Right,
        backgroundColorHex: '#4CAF50',
        fontColorHex: '#FFFFFF',
      );

      for (var i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .cellStyle = headerStyle;
      }

      for (var client in filteredClients) {
        final phones = client['phone'] as List;
        if (phones.isNotEmpty) {
          final phone = phones.first;
          final systems = phone['system'] as List;
          if (systems.isNotEmpty) {
            final system = systems[0];
            final systemType = system['system_type'];

            sheet.appendRow([
              client['name'] ?? '',
              client['address'] ?? '',
              client['national_id'] ?? '',
              phone['phone_number'] ?? '',
              systemType['name'] ?? '',
              _formatDate(system['start_date']),
              _formatDate(system['end_date']),
              systemType['price']?.toString() ?? ''
            ]);
          }
        }
      }

      for (var i = 0; i < headers.length; i++) {
        sheet.setColWidth(i, 20);
      }

      final bytes = excel.encode()!;

      if (kIsWeb) {
        _downloadWebFile(bytes);
      } else {
        await _saveFile(bytes);
      }
    } catch (e) {
      debugPrint('Error exporting to Excel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تصدير البيانات')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '';
    try {
      final parsed = DateTime.parse(date);
      return DateFormat.yMd('ar').format(parsed);
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> displayedClients = [];

    try {
      displayedClients = searchQuery.isEmpty
          ? filteredClients
          : filteredClients.where((client) {
              final name = client['name']?.toString().toLowerCase() ?? '';
              final address = client['address']?.toString().toLowerCase() ?? '';
              final nationalId =
                  client['national_id']?.toString().toLowerCase() ?? '';

              String phone = '';
              try {
                if (client['phone'] != null &&
                    (client['phone'] as List).isNotEmpty) {
                  phone = (client['phone'] as List)
                      .first['phone_number']
                      .toString()
                      .toLowerCase();
                }
              } catch (e) {
                debugPrint('Error accessing phone: $e');
              }

              return name.contains(searchQuery) ||
                  address.contains(searchQuery) ||
                  nationalId.contains(searchQuery) ||
                  phone.contains(searchQuery);
            }).toList();
    } catch (e) {
      debugPrint('Error filtering clients: $e');
      displayedClients = [];
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[300],
        title: const Text('تصفية حسب النظام'),
        actions: [
          if (selectedSystem != null &&
              !isLoading &&
              filteredClients.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: exportToExcel,
            ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'اختر النظام',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    value: selectedSystem,
                    items: systems.isEmpty
                        ? []
                        : systems.map((system) {
                            return DropdownMenuItem(
                              value: system['id'].toString(),
                              child: Text(system['name'] ?? ''),
                            );
                          }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedSystem = value;
                        });
                        fetchClientsBySystem(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'بحث',
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.lightBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.lightBlue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Colors.lightBlue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: filterData,
                  ),
                ],
              ),
            ),
            Expanded(
              child: error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (selectedSystem != null) {
                                fetchClientsBySystem(selectedSystem!);
                              } else {
                                fetchSystems();
                              }
                            },
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    )
                  : isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : systems.isEmpty && !selectedSystem!._isNotEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('لا توجد أنظمة متاحة'),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: fetchSystems,
                                    child: const Text('إعادة المحاولة'),
                                  ),
                                ],
                              ),
                            )
                          : displayedClients.isEmpty
                              ? const Center(child: Text('لا توجد بيانات'))
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    child: _buildDataTable(displayedClients),
                                  ),
                                ),
            ),
            if (selectedSystem != null && !isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'إجمالي العملاء: ${displayedClients.length}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(List<dynamic> displayedClients) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo is ScrollEndNotification &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _loadMoreData();
        }
        return true;
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            DataTable(
              columns: const [
                DataColumn(label: Text('الاسم')),
                DataColumn(label: Text('العنوان')),
                DataColumn(label: Text('الرقم القومي')),
                DataColumn(label: Text('رقم الهاتف')),
                DataColumn(label: Text('نوع النظام')),
                DataColumn(label: Text('تاريخ البداية')),
                DataColumn(label: Text('تاريخ الانتهاء')),
                DataColumn(label: Text('السعر')),
              ],
              rows: displayedClients.map<DataRow>((client) {
                String phoneName = '';
                String systemName = '';
                String startDate = '';
                String endDate = '';
                String price = '';

                try {
                  final phones = client['phone'] as List;
                  if (phones.isNotEmpty) {
                    final phone = phones.first;
                    phoneName = phone['phone_number'] ?? '';

                    final systems = phone['system'] as List;
                    if (systems.isNotEmpty) {
                      final system = systems[0];
                      startDate = _formatDate(system['start_date']);
                      endDate = _formatDate(system['end_date']);

                      final systemType = system['system_type'];
                      systemName = systemType['name'] ?? '';
                      price = systemType['price']?.toString() ?? '';
                    }
                  }
                } catch (e) {
                  debugPrint('Error building row: $e');
                }

                return DataRow(
                  cells: [
                    DataCell(Text(client['name'] ?? '')),
                    DataCell(Text(client['address'] ?? '')),
                    DataCell(Text(client['national_id'] ?? '')),
                    DataCell(Text(phoneName)),
                    DataCell(Text(systemName)),
                    DataCell(Text(startDate)),
                    DataCell(Text(endDate)),
                    DataCell(Text(price)),
                  ],
                );
              }).toList(),
            ),
            if (_hasMoreData && !isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Extension to safely check if a String is not empty
extension StringExtension on String? {
  bool get _isNotEmpty {
    return this != null && this!.isNotEmpty;
  }
}

// Custom Exception class
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
