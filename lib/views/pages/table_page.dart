import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';

class InfoTablePage extends StatefulWidget {
  const InfoTablePage({super.key});

  @override
  State<InfoTablePage> createState() => _InfoTablePageState();
}

class _InfoTablePageState extends State<InfoTablePage> {
  final supabaseClient = Supabase.instance.client;
  bool isLoading = true;
  String? error;
  List<Map<String, dynamic>> infoData = [];
  List<Map<String, dynamic>> filteredData = [];
  String searchQuery = '';

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

      setState(() {
        infoData = List<Map<String, dynamic>>.from(response);
        filteredData = infoData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'حدث خطأ أثناء تحميل البيانات';
        isLoading = false;
      });
    }
  }

  void filterData(String query) {
    setState(() {
      searchQuery = query;
      filteredData = infoData.where((item) {
        final name = item['name']?.toString().toLowerCase() ?? '';
        final address = item['address']?.toString().toLowerCase() ?? '';
        final nationalId = item['national_id']?.toString().toLowerCase() ?? '';
        final phoneNumbers = _formatPhoneNumbers(item['phone']).toLowerCase();
        return name.contains(query.toLowerCase()) ||
            address.contains(query.toLowerCase()) ||
            nationalId.contains(query.toLowerCase()) ||
            phoneNumbers.contains(query.toLowerCase());
      }).toList();
    });
  }

  String _formatPhoneNumbers(List<dynamic>? phones) {
    if (phones == null || phones.isEmpty) return 'غير متوفر';
    try {
      return phones
          .map((phone) => phone is Map<String, dynamic>
              ? phone['phone_number']?.toString() ?? ''
              : '')
          .where((number) => number.isNotEmpty)
          .join('، ');
    } catch (e) {
      return 'غير متوفر';
    }
  }

  String _formatSystems(List<dynamic>? systems) {
    if (systems == null || systems.isEmpty) return 'غير متوفر';
    try {
      return systems
          .map((system) => system is Map<String, dynamic>
              ? system['name']?.toString() ?? ''
              : '')
          .where((name) => name.isNotEmpty)
          .join('، ');
    } catch (e) {
      return 'غير متوفر';
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'غير متوفر';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('yyyy/MM/dd').format(parsedDate);
    } catch (e) {
      return 'غير متوفر';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Search
            _buildSearchBar(),

            // Stats
            _buildStats(),

            // Content
            Expanded(
              child: isLoading
                  ? _buildLoader()
                  : error != null
                      ? _buildError()
                      : filteredData.isEmpty
                          ? _buildEmpty()
                          : _buildClientsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'بيانات العملاء',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
          _buildHeaderButton(
            icon: Icons.refresh_rounded,
            onTap: fetchData,
          ),
          const SizedBox(width: 8),
          _buildHeaderButton(
            icon: Icons.download_rounded,
            color: const Color(0xFF10b981),
            onTap: _generateAndDownloadExcel,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (color ?? const Color(0xFF3b82f6)).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? const Color(0xFF3b82f6), size: 20),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: TextField(
          onChanged: filterData,
          style: TextStyle(color: Colors.grey[800], fontSize: 15),
          decoration: InputDecoration(
            hintText: 'بحث بالاسم، العنوان، الرقم القومي، أو رقم الهاتف...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon:
                Icon(Icons.search_rounded, color: Colors.grey[400], size: 22),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.people_rounded,
            label: 'إجمالي العملاء',
            value: '${infoData.length}',
            color: const Color(0xFF3b82f6),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.filter_list_rounded,
            label: 'نتائج البحث',
            value: '${filteredData.length}',
            color: const Color(0xFF10b981),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                Text(value,
                    style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w700,
                        fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child:
          CircularProgressIndicator(color: Color(0xFF3b82f6), strokeWidth: 2.5),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(error ?? 'حدث خطأ', style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3b82f6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('إعادة المحاولة',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('لا توجد بيانات', style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildClientsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        final client = filteredData[index];
        return _ClientInfoCard(
          client: client,
          formatPhoneNumbers: _formatPhoneNumbers,
          formatSystems: _formatSystems,
          formatDate: _formatDate,
        );
      },
    );
  }

  // Excel Export Functions
  Future<void> _generateAndDownloadExcel() async {
    try {
      setState(() => isLoading = true);

      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // Headers
      sheet.appendRow([
        'الاسم',
        'العنوان',
        'الرقم القومي',
        'أرقام الهاتف',
        'الأنظمة',
        'تاريخ انتهاء العرض',
        'تاريخ الإنشاء'
      ]);

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

      for (var info in infoData) {
        final phones = info['phone'] as List<dynamic>?;
        final systems = phones?.expand((phone) {
          if (phone is Map<String, dynamic>) {
            final system = phone['system'];
            if (system is List) return system;
          }
          return [];
        }).toList();

        sheet.appendRow([
          info['name'] ?? 'غير متوفر',
          info['address'] ?? 'غير متوفر',
          info['national_id'] ?? 'غير متوفر',
          _formatPhoneNumbers(phones),
          _formatSystems(systems),
          _formatDate(info['expire_date']),
          _formatDate(info['created_at']),
        ]);
      }

      for (var i = 0; i < 7; i++) {
        sheet.setColWidth(i, 20);
      }

      final bytes = excel.encode()!;

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download',
              'بيانات_العملاء_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        await _saveFile(bytes);
      }

      setState(() => isLoading = false);

      Get.snackbar(
        'نجاح',
        'تم تصدير البيانات بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10b981).withValues(alpha: 0.1),
        colorText: const Color(0xFF10b981),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'حدث خطأ أثناء تصدير البيانات';
      });
    }
  }

  Future<void> _saveFile(List<int> bytes) async {
    try {
      if (Platform.isAndroid) {
        final sdkVersion = await DeviceInfoPlugin().androidInfo;
        if (sdkVersion.version.sdkInt >= 30) {
          await Permission.manageExternalStorage.request();
        } else {
          await Permission.storage.request();
        }
      }

      final directory = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();

      if (directory == null) return;

      final downloadsDir = Directory('${directory.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${downloadsDir.path}/بيانات_العملاء_$timestamp.xlsx');
      await file.writeAsBytes(bytes);

      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint('Error saving file: $e');
    }
  }
}

// Client Info Card Widget
class _ClientInfoCard extends StatelessWidget {
  final Map<String, dynamic> client;
  final String Function(List<dynamic>?) formatPhoneNumbers;
  final String Function(List<dynamic>?) formatSystems;
  final String Function(String?) formatDate;

  const _ClientInfoCard({
    required this.client,
    required this.formatPhoneNumbers,
    required this.formatSystems,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final phones = client['phone'] as List<dynamic>?;
    final systems = phones?.expand((phone) {
      if (phone is Map<String, dynamic>) {
        final system = phone['system'];
        if (system is List) return system;
      }
      return <dynamic>[];
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3b82f6).withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3b82f6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      client['name']
                              ?.toString()
                              .substring(0, 1)
                              .toUpperCase() ??
                          '؟',
                      style: const TextStyle(
                        color: Color(0xFF3b82f6),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client['name']?.toString() ?? 'غير متوفر',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded,
                              size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              formatPhoneNumbers(phones),
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Copy Button
                GestureDetector(
                  onTap: () {
                    final phone = formatPhoneNumbers(phones);
                    if (phone != 'غير متوفر') {
                      Clipboard.setData(ClipboardData(text: phone));
                      Get.snackbar(
                        'تم النسخ',
                        'تم نسخ رقم الهاتف',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor:
                            const Color(0xFF10b981).withValues(alpha: 0.1),
                        colorText: const Color(0xFF10b981),
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3b82f6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.copy_rounded,
                        color: Color(0xFF3b82f6), size: 18),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.location_on_rounded, 'العنوان',
                    client['address']?.toString() ?? 'غير متوفر'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.badge_rounded, 'الرقم القومي',
                    client['national_id']?.toString() ?? 'غير متوفر'),
                const SizedBox(height: 12),
                _buildInfoRow(
                    Icons.apps_rounded, 'الأنظمة', formatSystems(systems)),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.event_rounded, 'تاريخ انتهاء العرض',
                    formatDate(client['expire_date'])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF64748B), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
