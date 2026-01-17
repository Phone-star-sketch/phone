import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/client_bottom_sheet_controller.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ModernSystemChoiceSheet extends StatefulWidget {
  final Client client;

  const ModernSystemChoiceSheet({super.key, required this.client});

  @override
  State<ModernSystemChoiceSheet> createState() =>
      _ModernSystemChoiceSheetState();
}

class _ModernSystemChoiceSheetState extends State<ModernSystemChoiceSheet> {
  final Map<Object, bool> _systemActiveStatus = {};
  final Map<Object, bool> _loadingStatus = {};
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    _checkAllSystemsStatus();
  }

  Future<void> _checkAllSystemsStatus() async {
    setState(() => _isCheckingStatus = true);
    try {
      final controller = Get.find<ClientBottomSheetController>();
      final systems = controller.getClientSystems() ?? [];
      for (var system in systems) {
        await _checkSystemStatus(system);
      }
    } catch (e) {
      debugPrint('Error checking systems status: $e');
    }
    setState(() => _isCheckingStatus = false);
  }

  Future<void> _checkSystemStatus(System system) async {
    try {
      final response = await Supabase.instance.client
          .from('system')
          .select('id')
          .eq('id', system.id)
          .maybeSingle();
      setState(() => _systemActiveStatus[system.id] = response != null);
    } catch (e) {
      setState(() => _systemActiveStatus[system.id] = false);
    }
  }

  Future<void> _deleteSystem(System system) async {
    setState(() => _loadingStatus[system.id] = true);
    try {
      await BackendServices.instance.systemRepository.delete(system);
      if (Get.isRegistered<ClientBottomSheetController>()) {
        Get.find<ClientBottomSheetController>().updateClient();
      }
      Get.snackbar('تم الحذف', 'تم حذف الباقة بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء حذف الباقة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red);
    }
    setState(() => _loadingStatus[system.id] = false);
  }

  void _showDeleteConfirmation(System system) {
    Get.dialog(AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.red),
        ),
        const SizedBox(width: 12),
        const Expanded(
            child: Text('حذف الباقة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ]),
      content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
                'هل أنت متأكد من حذف باقة "${system.type?.name ?? 'غير محددة'}"؟',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 15, color: Colors.grey[700])),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                    child: Text('سيتم حذف الباقة نهائياً',
                        style:
                            TextStyle(fontSize: 12, color: Colors.orange[700]),
                        textAlign: TextAlign.right)),
              ]),
            ),
          ]),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey[600]))),
        ElevatedButton(
          onPressed: () {
            Get.back();
            _deleteSystem(system);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          child: const Text('حذف', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: Column(children: [
        _buildHeader(),
        if (_isCheckingStatus)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
              Text('جاري التحقق من حالة الباقات...',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ]),
          ),

        // Total Cost Card
        GetBuilder<ClientBottomSheetController>(
          builder: (controller) {
            final clientSystems = controller.getClientSystems() ?? [];
            final totalCost = clientSystems.fold<double>(
              0,
              (sum, system) => sum + (system.type?.price ?? 0),
            );

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التكلفة الإجمالية',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            totalCost.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'جنيه',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${clientSystems.length} باقة',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        Expanded(
          child: GetBuilder<ClientBottomSheetController>(builder: (controller) {
            final clientSystems = controller.getClientSystems() ?? [];
            if (clientSystems.isEmpty) return _buildEmptyState();
            final grouped = _groupSystemsByCategory(clientSystems);
            return RefreshIndicator(
              onRefresh: _checkAllSystemsStatus,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: grouped.keys.length,
                itemBuilder: (context, index) {
                  final category = grouped.keys.elementAt(index);
                  return _buildCategorySection(category, grouped[category]!);
                },
              ),
            );
          }),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.blue[700]!, Colors.blue[900]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(children: [
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Row(children: [
          CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Text(widget.client.name?[0].toUpperCase() ?? '؟',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900]))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('الباقات المشترك بها',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text('${widget.client.name ?? 'غير محدد'} - اضغط مطولاً للحذف',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13)),
              ])),
          IconButton(
              onPressed: _checkAllSystemsStatus,
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'تحديث الحالة'),
          IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close, color: Colors.white)),
        ]),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
      const SizedBox(height: 16),
      Text('لا توجد باقات مشترك بها',
          style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Text('لم يتم إضافة أي باقات لهذا العميل بعد',
          style: TextStyle(fontSize: 14, color: Colors.grey[500])),
    ]));
  }

  Widget _buildCategorySection(SystemCategory category, List<System> systems) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: _getCategoryColor(category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(_getCategoryIcon(category),
                    color: _getCategoryColor(category), size: 20)),
            const SizedBox(width: 12),
            Expanded(
                child: Text(_getCategoryName(category),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold))),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: _getCategoryColor(category),
                    borderRadius: BorderRadius.circular(12)),
                child: Text('${systems.length} باقة',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold))),
          ])),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12),
        itemCount: systems.length,
        itemBuilder: (context, index) => _buildSystemCard(systems[index]),
      ),
      const SizedBox(height: 24),
    ]);
  }

  Widget _buildSystemCard(System system) {
    final systemType = system.type;
    final isActive = _systemActiveStatus[system.id] ?? true;
    final isLoading = _loadingStatus[system.id] ?? false;
    final statusColor = isActive ? Colors.green : Colors.red;

    return GestureDetector(
      onLongPress: () => _showDeleteConfirmation(system),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: statusColor, width: 2)),
        child: Stack(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(colors: [
                  statusColor.withValues(alpha: 0.1),
                  statusColor.withValues(alpha: 0.05)
                ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(25)),
                    child: systemType?.image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.network(systemType!.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Icon(
                                    _getCategoryIcon(systemType.category ??
                                        SystemCategory.mainPackage),
                                    color: statusColor,
                                    size: 25)))
                        : Icon(
                            _getCategoryIcon(systemType?.category ??
                                SystemCategory.mainPackage),
                            color: statusColor,
                            size: 25),
                  ),
                  const SizedBox(height: 8),
                  Text(systemType?.name ?? 'باقة غير محددة',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: statusColor.shade700),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (system.name != null && system.name!.isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(system.name!,
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  const SizedBox(height: 6),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(15)),
                      child: Text(
                          '${systemType?.price?.toStringAsFixed(0) ?? '0'} جنيه',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12))),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(isActive ? Icons.check_circle : Icons.cancel,
                          size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(isActive ? 'مفعّلة' : 'غير مفعّلة',
                          style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
          ),
          Positioned(
              top: 6,
              right: 6,
              child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(isActive ? Icons.check_circle : Icons.error,
                      color: Colors.white, size: 14))),
          Positioned(
              top: 6,
              left: 6,
              child: GestureDetector(
                  onTap: () => _showDeleteConfirmation(system),
                  child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.white, size: 14)))),
          if (isLoading)
            Positioned.fill(
                child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(15)),
                    child: const Center(
                        child:
                            CircularProgressIndicator(color: Colors.white)))),
        ]),
      ),
    );
  }

  Map<SystemCategory, List<System>> _groupSystemsByCategory(
      List<System> systems) {
    final Map<SystemCategory, List<System>> grouped = {};
    for (final system in systems) {
      final category = system.type?.category ?? SystemCategory.mainPackage;
      grouped.putIfAbsent(category, () => []).add(system);
    }
    return grouped;
  }

  Color _getCategoryColor(SystemCategory category) {
    switch (category) {
      case SystemCategory.mainPackage:
        return Colors.purple;
      case SystemCategory.internetPackage:
        return Colors.blue;
      case SystemCategory.mobileInternet:
        return Colors.orange;
    }
  }

  IconData _getCategoryIcon(SystemCategory category) {
    switch (category) {
      case SystemCategory.mainPackage:
        return Icons.wifi;
      case SystemCategory.internetPackage:
        return Icons.router;
      case SystemCategory.mobileInternet:
        return Icons.smartphone;
    }
  }

  String _getCategoryName(SystemCategory category) {
    switch (category) {
      case SystemCategory.mainPackage:
        return 'باقات الفليكس';
      case SystemCategory.internetPackage:
        return 'باقات الإنترنت';
      case SystemCategory.mobileInternet:
        return 'خدمات أخرى';
    }
  }
}

Future<void> showModernSystemChoiceSheet(
    BuildContext context, Client client) async {
  return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModernSystemChoiceSheet(client: client));
}
