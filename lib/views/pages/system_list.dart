import 'dart:math';
import 'dart:ui';

import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get/get_core/get_core.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phone_system_app/ViewModels/system_list_vm.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SystemList extends StatelessWidget {
  final controller = Get.put(SystemListViewModel());

  final String? imageUri = '';
  final void Function()? onUpload = () {};

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Container(
              color: const Color(0xFF0d47a1),
              child: const TabBar(
                tabs: [
                  Tab(
                    icon: Icon(Icons.phone),
                    child: Text('أنظمة الفليكسات'),
                  ),
                  Tab(
                    icon: Icon(Icons.wifi),
                    child: Text(' انترنت ارضي و موبيل'),
                  ),
                  Tab(
                    icon: Icon(Icons.phone_android),
                    child: Text('خدمات أخري'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(children: [
                SystemListTab(
                  systemCategory: SystemCategory.mainPackage,
                ),
                SystemListTab(
                  systemCategory: SystemCategory.internetPackage,
                ),
                SystemListTab(
                  systemCategory: SystemCategory.mobileInternet,
                ),
              ]),
            )
          ],
        ));
  }
}

class SystemListTab extends StatelessWidget {
  SystemListViewModel controller = Get.put(SystemListViewModel());
  SystemCategory systemCategory;
  SystemListTab({
    super.key,
    required this.systemCategory,
    this.onUpload,
  });
  final void Function(String imageUrl)? onUpload;

  @override
  Widget build(BuildContext context) {
    double maxWidth = 600;

    double width = MediaQuery.of(context).size.width;
    int numberOfElements = max(width ~/ maxWidth, 1);

    return Obx(() {
      final currentSystems = controller
          .getAllTypes()
          .where((element) => element.category == systemCategory)
          .toList();

      int editedCard = controller.editedCardIndex.value;
      return Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF00BFFF),
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            bool defaultIsRecurring =
                systemCategory == SystemCategory.mobileInternet ? false : true;

            final newSystem = SystemType(
              id: -1,
              category: systemCategory,
              isRecurring: defaultIsRecurring,
            );

            controller.getAllTypes().add(newSystem);
            controller.refreshTypes();

            controller.editedCardIndex.value = currentSystems.length;
            controller.isRecurring.value = defaultIsRecurring;
          },
        ),
        backgroundColor: Colors.grey[100],
        body: GestureDetector(
          onTap: () => controller.editedCardIndex.value = -1,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: numberOfElements,
              childAspectRatio: 0.85,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              SystemType currentSystem = currentSystems[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                transform: Matrix4.identity()
                  ..scale(editedCard == index ? 1.02 : 1.0),
                child: Card(
                  elevation: editedCard == index ? 8 : 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          editedCard == index
                              ? Colors.blue.shade50
                              : Colors.grey.shade50,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Main Content
                        Column(
                          children: [
                            // Image Section
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.blue.shade50,
                                      Colors.white,
                                    ],
                                  ),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      child: currentSystem.image != null
                                          ? Image.network(
                                              currentSystem.image!,
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.asset(
                                                  currentSystem.category!
                                                      .icon(),
                                                  fit: BoxFit.contain,
                                                );
                                              },
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    value: loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                            )
                                          : Image.asset(
                                              currentSystem.category!.icon(),
                                              fit: BoxFit.contain,
                                            ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.3),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Details Section
                            Container(
                              height: 120,
                              padding: const EdgeInsets.all(16),
                              child: editedCard == index
                                  ? SystemCardEditor(
                                      currentSystem: currentSystem,
                                      systemCategory: systemCategory,
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                currentSystem.name?.trim() ??
                                                    'غير متوفر',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: Text(
                                                "${currentSystem.price ?? '0'} ج",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          currentSystem.description
                                                  ?.toString()
                                                  .trim() ??
                                              'غير متوفر',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                        // Action Buttons
                        if (editedCard != index)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () =>
                                  controller.editedCardIndex.value = index,
                            ),
                          ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (editedCard == index)
                                _buildActionButton(
                                  visible: true,
                                  icon: Icons.check,
                                  color: Colors.green,
                                  onPressed: () async {
                                    if (controller.formKey.currentState!
                                        .validate()) {
                                      if (controller.isSaving.value) return;

                                      try {
                                        controller.isSaving.value = true;

                                        bool isRecurringValue;
                                        if (systemCategory ==
                                            SystemCategory.mobileInternet) {
                                          isRecurringValue =
                                              controller.isRecurring.value;
                                        } else {
                                          isRecurringValue = true;
                                        }

                                        final systemType = SystemType(
                                          id: currentSystem.id,
                                          createdAt: currentSystem.id == -1
                                              ? DateTime.now()
                                              : currentSystem.createdAt,
                                          name: controller.systemName.text,
                                          description:
                                              controller.systemDescription.text,
                                          price: double.parse(
                                              controller.systemPrice.text),
                                          category: systemCategory,
                                          isRecurring: isRecurringValue,
                                        );

                                        if (currentSystem.id == -1) {
                                          await BackendServices
                                              .instance.systemTypeRepository
                                              .create(systemType);
                                          await controller
                                              .updateTypesSilently(true);
                                        } else {
                                          await BackendServices
                                              .instance.systemTypeRepository
                                              .update(systemType);

                                          final allTypes =
                                              controller.getAllTypes();
                                          final typeIndex = allTypes.indexWhere(
                                              (t) => t.id == systemType.id);
                                          if (typeIndex != -1) {
                                            allTypes[typeIndex] = systemType;
                                            controller.refreshTypes();
                                          }
                                        }

                                        controller.editedCardIndex.value = -1;

                                        Get.showSnackbar(const GetSnackBar(
                                          message: 'تم حفظ البيانات بنجاح',
                                          duration: Duration(seconds: 2),
                                          backgroundColor: Color(0xFF10b981),
                                          borderRadius: 10,
                                          margin: EdgeInsets.all(12),
                                        ));
                                      } catch (e) {
                                        Get.showSnackbar(GetSnackBar(
                                          message:
                                              'حدث خطأ أثناء الحفظ: ${e.toString()}',
                                          duration: const Duration(seconds: 3),
                                          backgroundColor:
                                              const Color(0xFFef4444),
                                          borderRadius: 10,
                                          margin: const EdgeInsets.all(12),
                                        ));
                                      } finally {
                                        controller.isSaving.value = false;
                                      }
                                    }
                                  },
                                ),
                              const SizedBox(width: 4),
                              _buildActionButton(
                                visible: true,
                                icon: Icons.delete,
                                color: Colors.red,
                                onPressed: () => _showDeleteDialog(
                                    context, currentSystem, index),
                              ),
                              const SizedBox(width: 4),
                              _buildActionButton(
                                visible: true,
                                icon: Icons.image,
                                color: Colors.blue,
                                onPressed: () async {
                                  try {
                                    ImagePicker imagePicker = ImagePicker();
                                    final image = await imagePicker.pickImage(
                                        source: ImageSource.gallery,
                                        maxWidth: 1200,
                                        maxHeight: 1200,
                                        imageQuality: 85);
                                    if (image == null) return;

                                    final imageBytes =
                                        await image.readAsBytes();
                                    if (imageBytes.length > 10 * 1024 * 1024) {
                                      Get.snackbar(
                                        'Error',
                                        'Image size too large. Please select a smaller image.',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }

                                    final timestamp =
                                        DateTime.now().millisecondsSinceEpoch;
                                    final fileName =
                                        '${timestamp}_${image.name}';

                                    // ✅ استخدام showDialog بدل Get.dialog
                                    BuildContext? uploadDialogContext;
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (ctx) {
                                        uploadDialogContext = ctx;
                                        return const PopScope(
                                          canPop: false,
                                          child: Center(
                                            child:
                                                CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                    );

                                    try {
                                      await supabase.storage
                                          .from('system_images')
                                          .uploadBinary(
                                            fileName,
                                            imageBytes,
                                            fileOptions: const FileOptions(
                                                contentType: 'image/jpeg',
                                                upsert: true),
                                          );

                                      final imageUrl = supabase.storage
                                          .from('system_images')
                                          .getPublicUrl(fileName);

                                      currentSystem.image = imageUrl;
                                      await BackendServices
                                          .instance.systemTypeRepository
                                          .update(currentSystem);

                                      controller.update();

                                      // ✅ إغلاق loading dialog بـ context خاصه
                                      if (uploadDialogContext != null &&
                                          Navigator.of(uploadDialogContext!)
                                              .canPop()) {
                                        Navigator.of(uploadDialogContext!)
                                            .pop();
                                      }

                                      Get.snackbar(
                                        'Success',
                                        'تم رفع الصورة بنجاح',
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                      );
                                    } catch (uploadError) {
                                      if (uploadDialogContext != null &&
                                          Navigator.of(uploadDialogContext!)
                                              .canPop()) {
                                        Navigator.of(uploadDialogContext!)
                                            .pop();
                                      }
                                      throw uploadError;
                                    }
                                  } catch (e) {
                                    print('Error uploading image: $e');
                                    Get.snackbar(
                                      'Error',
                                      'Failed to upload image. Please try again.',
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                      duration: const Duration(seconds: 5),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            itemCount: currentSystems.length,
          ),
        ),
      );
    });
  }

  Widget _buildActionButton({
    required bool visible,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Visibility(
      visible: visible,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 20),
          color: Colors.white,
          onPressed: onPressed,
        ),
      ),
    );
  }

  // ✅ استخدام showDialog بدل Get.dialog
  void _showDeleteDialog(
      BuildContext context, SystemType currentSystem, int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text(
          'حذف باقة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Text(
          'هل أنت متأكد من حذف "${currentSystem.name}"؟\n\nسيتم حذف جميع الاشتراكات المرتبطة بها.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Color(0xFF6b7280), fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // ✅ إغلاق dialog التأكيد
              await _performDelete(context, currentSystem); // ✅ تمرير context
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'حذف',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ تمرير context وإدارة loading dialog بـ context صريح
  Future<void> _performDelete(
      BuildContext context, SystemType currentSystem) async {
    BuildContext? loadingDialogContext;

    try {
      // ✅ Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          loadingDialogContext = ctx;
          return const PopScope(
            canPop: false,
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF3b82f6)),
                      SizedBox(height: 16),
                      Text('جاري الحذف...'),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

      // Delete from database
      await BackendServices.instance.systemTypeRepository.delete(currentSystem);

      controller.editedCardIndex.value = -1;
      await controller.updateTypesSilently(true);

      // ✅ إغلاق loading dialog بـ context خاصه
      if (loadingDialogContext != null &&
          Navigator.of(loadingDialogContext!).canPop()) {
        Navigator.of(loadingDialogContext!).pop();
      }

      Get.showSnackbar(const GetSnackBar(
        message: 'تم حذف الباقة بنجاح',
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF10b981),
        borderRadius: 10,
        margin: EdgeInsets.all(12),
      ));
    } catch (e) {
      // ✅ إغلاق loading dialog في حالة الخطأ
      if (loadingDialogContext != null &&
          Navigator.of(loadingDialogContext!).canPop()) {
        Navigator.of(loadingDialogContext!).pop();
      }

      Get.showSnackbar(GetSnackBar(
        message: 'حدث خطأ أثناء الحذف: ${e.toString()}',
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFFef4444),
        borderRadius: 10,
        margin: const EdgeInsets.all(12),
      ));
    }
  }

  Future<void> showBottomSheetForEditingSystemType(
      BuildContext context, SystemType type) async {
    return showModalBottomSheet(
      context: context,
      constraints:
          BoxConstraints.expand(width: MediaQuery.of(context).size.width * 0.7),
      builder: (context) {
        return Container(
          child: Column(),
        );
      },
    );
  }
}

class SystemCardEditor extends StatelessWidget {
  SystemCardEditor(
      {super.key, required this.currentSystem, required this.systemCategory});
  final SystemType currentSystem;
  final SystemCategory systemCategory;
  SystemListViewModel controller = Get.put(SystemListViewModel());

  @override
  Widget build(BuildContext context) {
    controller.systemName.text = currentSystem.name?.trim() ?? '';
    controller.systemDescription.text = currentSystem.description?.trim() ?? '';
    controller.systemPrice.text = currentSystem.price?.toString() ?? '0';
    controller.isRecurring.value = currentSystem.isRecurring;

    return Container(
      height: systemCategory == SystemCategory.mobileInternet ? 110 : 85,
      child: Form(
        key: controller.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 6,
                    child: AutoSizeTextField(
                      cursorColor: Colors.red,
                      controller: controller.systemName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      minFontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: AutoSizeTextField(
                      cursorColor: Colors.red,
                      controller: controller.systemPrice,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      minFontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'ج',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: AutoSizeTextField(
                cursorColor: Colors.red,
                controller: controller.systemDescription,
                maxLines: 1,
                minFontSize: 10,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            if (systemCategory == SystemCategory.mobileInternet)
              Obx(() => SizedBox(
                    height: 25,
                    child: CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      title: const Text(
                        'خدمة متكررة شهرياً',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: controller.isRecurring.value,
                      onChanged: (value) {
                        controller.isRecurring.value = value ?? false;
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}