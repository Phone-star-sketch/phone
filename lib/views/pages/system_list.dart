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
import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/repositories/system_type/supabase_system_type_repository.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SystemList extends StatelessWidget {
  final controller = Get.put(SystemListViewModel());

  final String? imageUri = '';
  final void Function()? onUpload = () {};

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allSystems = controller.getAllTypes();

      return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                color:const Color(0xFF00BFFF),
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
                    allSystems: allSystems
                        .where((element) =>
                            element.category == SystemCategory.mainPackage)
                        .toList(),
                  ),
                  SystemListTab(
                    systemCategory: SystemCategory.internetPackage,
                    allSystems: allSystems
                        .where((element) =>
                            element.category == SystemCategory.internetPackage)
                        .toList(),
                  ),
                  SystemListTab(
                    systemCategory: SystemCategory.mobileInternet,
                    allSystems: allSystems
                        .where((element) =>
                            element.category == SystemCategory.mobileInternet)
                        .toList(),
                  ),
                ]),
              )
            ],
          ));
    });
  }
}

class SystemListTab extends StatelessWidget {
  SystemListViewModel controller = Get.put(SystemListViewModel());
  SystemCategory systemCategory;
  SystemListTab(
      {super.key,
      required this.systemCategory,
      required this.allSystems,
      this.onUpload});
  List<SystemType> allSystems;
  final void Function(String imageUrl)? onUpload;

  @override
  Widget build(BuildContext context) {
    double maxWidth = 600;

    double width = MediaQuery.of(context).size.width;
    int numberOfElements = max(width ~/ maxWidth, 1);

    return Obx(() {
      int editedCard = controller.editedCardIndex.value;
      return Scaffold(
        floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF00BFFF),
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            allSystems.add(SystemType(id: -1, category: systemCategory));
            controller.editedCardIndex.value = allSystems.length;
          },
        ),
        backgroundColor: Colors.grey[100],
        body: GestureDetector(
          onTap: () => controller.editedCardIndex.value = -1,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1 / 1.4,
              crossAxisCount: numberOfElements,
            ),
            itemBuilder: (context, index) {
              SystemType currentSystem = allSystems[index];
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
                                    // System Image
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      child: currentSystem.image != null
                                          ? Image.network(
                                              currentSystem.image!,
                                              fit: BoxFit.contain,
                                            )
                                          : Image.asset(
                                              currentSystem.category!.icon(),
                                              fit: BoxFit.contain,
                                            ),
                                    ),
                                    // Gradient Overlay
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
                                      currentSystem: currentSystem)
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
                        // Replace the individual action buttons with this Row container
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
                                      // ...existing save logic...
                                      if (currentSystem.id == -1) {
                                        await BackendServices
                                            .instance.systemTypeRepository
                                            .create(SystemType(
                                                id: currentSystem.id,
                                                createdAt: DateTime.now(),
                                                name:
                                                    controller.systemName.text,
                                                description: controller
                                                    .systemDescription.text,
                                                price: double.parse(controller
                                                    .systemPrice.text),
                                                category: systemCategory));
                                        allSystems[index].name =
                                            controller.systemName.text;
                                        allSystems[index].description =
                                            controller.systemDescription.text;
                                        allSystems[index].price = double.parse(
                                            controller.systemPrice.text);
                                        controller.editedCardIndex.value = -1;
                                      } else {
                                        await BackendServices
                                            .instance.systemTypeRepository
                                            .update(SystemType(
                                                id: currentSystem.id,
                                                createdAt:
                                                    currentSystem.createdAt,
                                                name:
                                                    controller.systemName.text,
                                                description: controller
                                                    .systemDescription.text,
                                                price: double.parse(controller
                                                    .systemPrice.text),
                                                category: systemCategory));
                                        allSystems[index].name =
                                            controller.systemName.text;
                                        allSystems[index].description =
                                            controller.systemDescription.text;
                                        allSystems[index].price = double.parse(
                                            controller.systemPrice.text);
                                        controller.editedCardIndex.value = -1;
                                      }
                                    }
                                  },
                                ),
                              const SizedBox(width: 4),
                              _buildActionButton(
                                visible: true,
                                icon: Icons.delete,
                                color: Colors.red,
                                onPressed: () async {
                                  // ...existing delete logic...
                                  await Get.defaultDialog(
                                      backgroundColor: Colors.white,
                                      confirm: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            shape: const StadiumBorder(),
                                            backgroundColor: Colors.red[900],
                                            padding: const EdgeInsets.all(10)),
                                        onPressed: () async {
                                          await BackendServices
                                              .instance.systemTypeRepository
                                              .delete(currentSystem);
                                          Get.back();
                                          allSystems.removeWhere((system) =>
                                              system.id == currentSystem.id);
                                          controller.editedCardIndex.value = -1;
                                        },
                                        child: const Text("تأكيد",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      title: "حذف باقة",
                                      content: Center(
                                          child: Text(
                                              "هل أنت متأكد من أنك تريد حذف هذه باقة : ${currentSystem.name} مع حذف الاشتراكات المرتبطة بها ان وجد ؟")));
                                },
                              ),
                              const SizedBox(width: 4),
                              _buildActionButton(
                                visible: true,
                                icon: Icons.image,
                                color: Colors.blue,
                                onPressed: () async {
                                  // ...existing image upload logic...
                                  try {
                                    ImagePicker imagePicker = ImagePicker();
                                    final image = await imagePicker.pickImage(
                                        source: ImageSource.gallery);
                                    if (image == null) return;

                                    final imageBytes =
                                        await image.readAsBytes();
                                    final timestamp =
                                        DateTime.now().millisecondsSinceEpoch;
                                    final fileName =
                                        '${timestamp}_${image.name}';

                                    // Upload image with correct path format
                                    await supabase.storage
                                        .from('system_images')
                                        .uploadBinary(
                                          fileName, // Remove the 'systems/' prefix
                                          imageBytes,
                                          fileOptions: const FileOptions(
                                              contentType: 'image/jpeg',
                                              upsert:
                                                  true // Add this to allow overwriting existing files
                                              ),
                                        );

                                    // Get public URL
                                    final imageUrl = supabase.storage
                                        .from('system_images')
                                        .getPublicUrl(fileName);

                                    // Update system type with new image URL
                                    currentSystem.image = imageUrl;
                                    await BackendServices
                                        .instance.systemTypeRepository
                                        .update(currentSystem);

                                    // Force UI refresh
                                    controller.update();

                                    Get.snackbar(
                                      'Success',
                                      'تم رفع الصورة بنجاح',
                                      backgroundColor: Colors.green,
                                      colorText: Colors.white,
                                    );
                                  } catch (e) {
                                    print(
                                        'Error uploading image: $e'); // For debugging
                                    Get.snackbar(
                                      'Error',
                                      'Failed to upload image: ${e.toString()}',
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
            itemCount: allSystems.length,
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
        height: 36, // Increased from 32
        width: 36, // Increased from 32
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
          icon: Icon(icon, size: 20), // Increased from 16
          color: Colors.white,
          onPressed: onPressed,
        ),
      ),
    );
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
  SystemCardEditor({super.key, required this.currentSystem});
  final SystemType currentSystem;
  SystemListViewModel controller = Get.put(SystemListViewModel());

  @override
  Widget build(BuildContext context) {
    controller.systemName.text = currentSystem.name?.trim() ?? '';
    controller.systemDescription.text = currentSystem.description?.trim() ?? '';
    controller.systemPrice.text = currentSystem.price?.toString().trim() ?? '0';

    return Container(
      height: 85, // Fixed height
      child: Form(
        key: controller.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // First row with name and price
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            // Description field
            Expanded(
              child: AutoSizeTextField(
                cursorColor: Colors.red,
                controller: controller.systemDescription,
                maxLines: 1,
                minFontSize: 10,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
