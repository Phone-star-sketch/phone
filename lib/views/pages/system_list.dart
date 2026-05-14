import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phone_system_app/ViewModels/system_list_vm.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SystemList extends StatelessWidget {
  const SystemList({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Material(
            color: const Color(0xFF1E88E5),
            elevation: 4,
            child: const TabBar(
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
              labelColor: Colors.white,
              unselectedLabelColor: Color(0xB3FFFFFF),
              dividerColor: Colors.transparent,
              padding: EdgeInsets.zero,
              labelPadding: EdgeInsets.symmetric(horizontal: 8),
              tabs: [
                Tab(icon: Icon(Icons.phone, size: 18), text: 'أنظمة الفليكسات'),
                Tab(icon: Icon(Icons.wifi, size: 18), text: 'إنترنت أرضي'),
                Tab(
                    icon: Icon(Icons.phone_android, size: 18),
                    text: 'إنترنت موبايل'),
                Tab(
                    icon: Icon(Icons.miscellaneous_services, size: 18),
                    text: 'خدمات أخرى'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                SystemListTab(systemCategory: SystemCategory.mainPackage),
                SystemListTab(systemCategory: SystemCategory.dslInternet),
                SystemListTab(systemCategory: SystemCategory.mobileInternet),
                SystemListTab(systemCategory: SystemCategory.otherServices),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SystemListTab extends StatelessWidget {
  final SystemCategory systemCategory;

  const SystemListTab({super.key, required this.systemCategory});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SystemListViewModel());
    final width = MediaQuery.of(context).size.width;
    // تحسين الـ responsive: موبايل = 2 أعمدة دائماً
    final crossAxisCount = width > 1200 ? 4 : (width > 800 ? 3 : 2);

    return Obx(() {
      final currentSystems = controller
          .getAllTypes()
          .where((element) => element.category == systemCategory)
          .toList();

      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddEditDialog(context, null, systemCategory),
          backgroundColor: const Color(0xFF1E88E5),
          elevation: 4,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('إضافة باقة',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        body: currentSystems.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: () => controller.updateTypes(true),
                color: const Color(0xFF1E88E5),
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.72, // نسبة أفضل للموبايل
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: currentSystems.length,
                  itemBuilder: (context, index) {
                    return SystemCard(
                      system: currentSystems[index],
                      systemCategory: systemCategory,
                      onEdit: () => _showAddEditDialog(
                        context,
                        currentSystems[index],
                        systemCategory,
                      ),
                      onDelete: () => _showDeleteDialog(
                        context,
                        currentSystems[index],
                      ),
                    );
                  },
                ),
              ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد باقات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على الزر لإضافة باقة جديدة',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(
    BuildContext context,
    SystemType? system,
    SystemCategory category,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SystemEditDialog(
        system: system,
        systemCategory: category,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, SystemType system) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Color(0xFFE53935),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'حذف الباقة',
              style: TextStyle(
                color: Color(0xFF212121),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من حذف "${system.name}"؟',
              style: const TextStyle(
                color: Color(0xFF424242),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Color(0xFFFF9800), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم حذف جميع الاشتراكات المرتبطة',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Color(0xFF757575)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _performDelete(context, system);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(BuildContext context, SystemType system) async {
    final controller = Get.find<SystemListViewModel>();

    try {
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري الحذف...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      await BackendServices.instance.systemTypeRepository.delete(system);
      await controller.updateTypesSilently(true);

      Get.back(); // Close loading dialog

      Get.snackbar(
        'نجح',
        'تم حذف الباقة بنجاح',
        backgroundColor: const Color(0xFF43A047),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء الحذف: ${e.toString()}',
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }
}

class SystemCard extends StatelessWidget {
  final SystemType system;
  final SystemCategory systemCategory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SystemCard({
    super.key,
    required this.system,
    required this.systemCategory,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: system.image != null
                        ? Image.network(
                            system.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultImage();
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: const Color(0xFF1E88E5),
                                ),
                              );
                            },
                          )
                        : _buildDefaultImage(),
                  ),
                  // Subtle Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                  ),
                  // Action Buttons
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Row(
                      children: [
                        _buildIconButton(
                          icon: Icons.edit_outlined,
                          color: const Color(0xFF1E88E5),
                          onPressed: onEdit,
                        ),
                        const SizedBox(width: 4),
                        _buildIconButton(
                          icon: Icons.delete_outline,
                          color: const Color(0xFFE53935),
                          onPressed: onDelete,
                        ),
                        const SizedBox(width: 4),
                        _buildIconButton(
                          icon: Icons.image_outlined,
                          color: const Color(0xFF43A047),
                          onPressed: () => _uploadImage(context),
                        ),
                      ],
                    ),
                  ),
                  // Recurring Badge
                  if (system.isRecurring)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF43A047),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.repeat, size: 10, color: Colors.white),
                            SizedBox(width: 3),
                            Text(
                              'شهري',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Details Section
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    system.name ?? 'غير محدد',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    system.description ?? 'لا يوجد وصف',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          size: 12,
                          color: Color(0xFF1E88E5),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${system.price} ج',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE3F2FD),
            const Color(0xFFBBDEFB),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Image.asset(
          systemCategory.icon(),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 14, color: color),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _uploadImage(BuildContext context) async {
    try {
      final imagePicker = ImagePicker();
      final image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) return;

      final imageBytes = await image.readAsBytes();
      if (imageBytes.length > 10 * 1024 * 1024) {
        Get.snackbar(
          'خطأ',
          'حجم الصورة كبير جداً. الرجاء اختيار صورة أصغر.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري رفع الصورة...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${image.name}';

      await supabase.storage.from('system_images').uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final imageUrl =
          supabase.storage.from('system_images').getPublicUrl(fileName);

      system.image = imageUrl;
      await BackendServices.instance.systemTypeRepository.update(system);

      Get.back(); // Close loading dialog

      Get.snackbar(
        'نجح',
        'تم رفع الصورة بنجاح',
        backgroundColor: const Color(0xFF43A047),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // Refresh the list
      final controller = Get.find<SystemListViewModel>();
      await controller.updateTypesSilently(true);
    } catch (e) {
      Get.back(); // Close loading dialog if open
      Get.snackbar(
        'خطأ',
        'فشل رفع الصورة: ${e.toString()}',
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }
}

class SystemEditDialog extends StatefulWidget {
  final SystemType? system;
  final SystemCategory systemCategory;

  const SystemEditDialog({
    super.key,
    this.system,
    required this.systemCategory,
  });

  @override
  State<SystemEditDialog> createState() => _SystemEditDialogState();
}

class _SystemEditDialogState extends State<SystemEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late bool _isRecurring;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.system?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.system?.description ?? '');
    _priceController = TextEditingController(
      text: widget.system?.price.toString() ?? '0',
    );
    _isRecurring = widget.system?.isRecurring ??
        (widget.systemCategory != SystemCategory.mobileInternet);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSaving) return false;
        return await _showDiscardDialog() ?? false;
      },
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            widget.system == null
                                ? Icons.add_circle_outline
                                : Icons.edit_outlined,
                            color: const Color(0xFF1E88E5),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.system == null
                                ? 'إضافة باقة جديدة'
                                : 'تعديل الباقة',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  if (await _showDiscardDialog() ?? false) {
                                    Navigator.pop(context);
                                  }
                                },
                          icon:
                              const Icon(Icons.close, color: Color(0xFF757575)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Color(0xFF212121)),
                      decoration: InputDecoration(
                        labelText: 'اسم الباقة *',
                        labelStyle: const TextStyle(color: Color(0xFF757575)),
                        hintText: 'مثال: باقة 100 دقيقة',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon:
                            const Icon(Icons.label, color: Color(0xFF1E88E5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF1E88E5), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرجاء إدخال اسم الباقة';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    // Price Field
                    TextFormField(
                      controller: _priceController,
                      style: const TextStyle(color: Color(0xFF212121)),
                      decoration: InputDecoration(
                        labelText: 'السعر *',
                        labelStyle: const TextStyle(color: Color(0xFF757575)),
                        hintText: '0.00',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.payments_outlined,
                            color: Color(0xFF1E88E5)),
                        suffixText: 'ج',
                        suffixStyle: const TextStyle(
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF1E88E5), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرجاء إدخال السعر';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price < 0) {
                          return 'الرجاء إدخال سعر صحيح';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Color(0xFF212121)),
                      decoration: InputDecoration(
                        labelText: 'الوصف',
                        labelStyle: const TextStyle(color: Color(0xFF757575)),
                        hintText: 'وصف تفصيلي للباقة',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.description_outlined,
                            color: Color(0xFF1E88E5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF1E88E5), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 16),
                    // Recurring Checkbox (only for mobileInternet)
                    if (widget.systemCategory == SystemCategory.mobileInternet)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                const Color(0xFF43A047).withValues(alpha: 0.3),
                          ),
                        ),
                        child: CheckboxListTile(
                          title: const Text(
                            'خدمة متكررة شهرياً',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212121),
                            ),
                          ),
                          subtitle: const Text(
                            'سيتم احتساب هذه الخدمة في الفواتير الشهرية',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF757575),
                            ),
                          ),
                          value: _isRecurring,
                          onChanged: (value) {
                            setState(() {
                              _isRecurring = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF43A047),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    if (await _showDiscardDialog() ?? false) {
                                      Navigator.pop(context);
                                    }
                                  },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: const Color(0xFF757575),
                              side: const BorderSide(color: Color(0xFFE0E0E0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveSystem,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF1E88E5),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('حفظ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDiscardDialog() async {
    // Check if any field has been modified
    final hasChanges =
        _nameController.text.trim() != (widget.system?.name ?? '').trim() ||
            _descriptionController.text.trim() !=
                (widget.system?.description ?? '').trim() ||
            _priceController.text != (widget.system?.price.toString() ?? '0') ||
            _isRecurring != (widget.system?.isRecurring ?? true);

    if (!hasChanges) return true;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'تجاهل التغييرات؟',
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'هل تريد تجاهل التغييرات التي قمت بها؟',
          style: TextStyle(
            color: Color(0xFF424242),
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'متابعة التعديل',
              style: TextStyle(color: Color(0xFF1E88E5)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('تجاهل'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSystem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final controller = Get.find<SystemListViewModel>();

      final systemType = SystemType(
        id: widget.system?.id ?? -1,
        createdAt: widget.system?.createdAt ?? DateTime.now(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        category: widget.systemCategory,
        isRecurring: widget.systemCategory == SystemCategory.mobileInternet
            ? _isRecurring
            : true,
        image: widget.system?.image,
      );

      if (widget.system == null) {
        // Create new
        await BackendServices.instance.systemTypeRepository.create(systemType);
      } else {
        // Update existing
        await BackendServices.instance.systemTypeRepository.update(systemType);
      }

      await controller.updateTypesSilently(true);

      Navigator.pop(context);

      Get.snackbar(
        'نجح',
        widget.system == null
            ? 'تم إضافة الباقة بنجاح'
            : 'تم تحديث الباقة بنجاح',
        backgroundColor: const Color(0xFF43A047),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ: ${e.toString()}',
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
