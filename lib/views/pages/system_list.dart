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
                color: Colors.red,
                child: const TabBar(
                  tabs: [
                    Tab(
                      icon: Icon(Icons.phone),
                      child: Text('فليكسات'),
                    ),
                    Tab(
                      icon: Icon(Icons.wifi),
                      child: Text('إنترنت أرضي'),
                    ),
                    Tab(
                      icon: Icon(Icons.phone_android),
                      child: Text('إنترنت موبايل'),
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
      {super.key, required this.systemCategory, required this.allSystems, this.onUpload});
  List<SystemType> allSystems;
  final void Function(String imageUrl)? onUpload;

  @override
  Widget build(BuildContext context) {
    double maxWidth = 600;

    double width = MediaQuery.of(context).size.width;
    int numberOfElements = max(width ~/ maxWidth, 1);

    /*
    final allSystems = controller
        .getAllTypes()
        .where((element) => element.category == systemCategory)
        .toList();*/
    return Obx(() {
      int editedCard = controller.editedCardIndex.value;
      return Scaffold(
        floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.red,
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            onPressed: () {
              allSystems.add(SystemType(id: -1, category: systemCategory));
              controller.editedCardIndex.value = allSystems.length;
            }),
        backgroundColor: Colors.white,
        body: GestureDetector(
          onTap: () {
            controller.editedCardIndex.value = -1;
          },
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1 / 1.4,
                crossAxisCount: numberOfElements),
            itemBuilder: (context, index) {
              SystemType currentSystem = allSystems[index];
              return Stack(
                children: [
                  Container(
                    decoration:
                        const BoxDecoration(color: Colors.white, boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        spreadRadius: 5,
                      ),
                    ]),
                    margin: const EdgeInsets.all(0),
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: currentSystem.image != null
                                      ? Image.network(
                                          currentSystem.image!,
                                          fit: BoxFit.contain,
                                          colorBlendMode: BlendMode.dstOut,
                                        )
                                      : Image.asset(
                                          currentSystem.category!.icon(),
                                          fit: BoxFit.contain,
                                          colorBlendMode: BlendMode.dstOut,
                                        ),
                                ),
                                Container(
                                  constraints: const BoxConstraints.expand(),
                                  decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                        Colors.black45,
                                        Colors.transparent
                                      ])),
                                )
                              ],
                            ),
                          ),
                          Container(
                            height: 100,
                            width: double.maxFinite,
                            margin: const EdgeInsets.all(10),
                            child: editedCard == index
                                ? SystemCardEditor(
                                    currentSystem: currentSystem,
                                  )
                                : Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currentSystem.name?.trim() ??
                                                'غير متوفر',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "${currentSystem.price ?? '0'} ج",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 25,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(currentSystem.description
                                                  ?.toString()
                                                  .trim() ??
                                              'غير متوفر'),
                                        ],
                                      )
                                    ],
                                  ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                      visible: editedCard != index,
                      child: Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              controller.editedCardIndex.value = index;
                              // await showBottomSheetForEditingSystemType(
                              //     context, currentSystem);
                            },
                          ),
                        ),
                      )),
                  Visibility(
                      visible: editedCard == index,
                      child: Positioned(
                          top: 20,
                          right: 00,
                          child: Container(
                            width: 75,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.fromRGBO(68, 138, 255, 1)),
                            child: IconButton(
                                onPressed: () async {
                                  if (controller.formKey.currentState!
                                      .validate()) {
                                    if (currentSystem.id == -1) {
                                      await BackendServices
                                          .instance.systemTypeRepository
                                          .create(SystemType(
                                              id: currentSystem.id,
                                              createdAt: DateTime.now(),
                                              name: controller.systemName.text,
                                              description: controller
                                                  .systemDescription.text,
                                              price: double.parse(
                                                  controller.systemPrice.text),
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
                                              name: controller.systemName.text,
                                              description: controller
                                                  .systemDescription.text,
                                              price: double.parse(
                                                  controller.systemPrice.text),
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
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                )),
                          ))),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IconButton(
                        onPressed: () async {
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
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              title: "حذف باقة",
                              content: Center(
                                  child: Text(
                                      "هل أنت متأكد من أنك تريد حذف هذه باقة : ${currentSystem.name} مع حذف الاشتراكات المرتبطة بها ان وجد ؟")));
                        },
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        )),
                  ),
                  Positioned(
                    top: 80,
                    right: 10,
                    child: IconButton(
                        onPressed: () async {
                          try {
                            ImagePicker imagePicker = ImagePicker();
                            final image = await imagePicker.pickImage(
                                source: ImageSource.gallery);
                            if (image == null) return;
                            
                            final imageBytes = await image.readAsBytes();
                            final timestamp = DateTime.now().millisecondsSinceEpoch;
                            final fileName = '${timestamp}_${image.name}';
                            
                            // Upload image with correct path format
                            await supabase.storage
                                .from('system_images')
                                .uploadBinary(
                                  fileName,  // Remove the 'systems/' prefix
                                  imageBytes,
                                  fileOptions: const FileOptions(
                                    contentType: 'image/jpeg',
                                    upsert: true  // Add this to allow overwriting existing files
                                  ),
                                );
                            
                            // Get public URL
                            final imageUrl = supabase.storage
                                .from('system_images')
                                .getPublicUrl(fileName);

                            // Update system type with new image URL
                            currentSystem.image = imageUrl;
                            await BackendServices.instance.systemTypeRepository
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
                            print('Error uploading image: $e'); // For debugging
                            Get.snackbar(
                              'Error',
                              'Failed to upload image: ${e.toString()}',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 5),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.red,
                        )),
                  ),
                ],
              );
            },
            padding: const EdgeInsets.all(10),
            itemCount: allSystems.length,
          ),
        ),
      );
    });
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
    return Form(
      key: controller.formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: AutoSizeTextField(
                  cursorColor: Colors.red,
                  controller: controller.systemName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 1,
                ),
              ),
              const SizedBox(
                width: 30,
              ),
              Expanded(
                flex: 2,
                child: AutoSizeTextField(
                  cursorColor: Colors.red,
                  controller: controller.systemPrice,
                  style: const TextStyle(
                      fontSize: 25, fontWeight: FontWeight.bold),
                  maxLines: 1,
                ),
              ),
              const Expanded(
                  flex: 1,
                  child: Text(
                    'ج',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                  ))
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AutoSizeTextField(
                  cursorColor: Colors.red,
                  controller: controller.systemDescription,
                  maxLines: 1,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
