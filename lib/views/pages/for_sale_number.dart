import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/models/phone_number.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/widget_models/clientCreationModelSheet.dart';

class ForSaleController extends GetxController {
  RxList<PhoneNumber> _numbers = <PhoneNumber>[].obs;
  RxString _query = "".obs;
  RxBool isLoading = false.obs;

  List<PhoneNumber> getNumbers() {
    return _numbers;
  }

  @override
  void onInit() {
    super.onInit();
    loadPhoneNumbers();
  }

  void loadPhoneNumbers() {
    try {
      isLoading.value = true;
      BackendServices.instance.phoneRepository
          .bindStreamToForSaleNumbersChanges(
        (payload) {
          _numbers.clear();
          _numbers.addAll(payload
              .map((phoneJsonObject) => PhoneNumber.fromJson(phoneJsonObject))
              .toList());
          isLoading.value = false;
        },
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تحميل الأرقام: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void updateQuery(String value) {
    _query.value = value;
  }

  Future<void> addPhoneNumber(PhoneNumber newPhoneNumber) async {
    try {
      isLoading.value = true;
      await BackendServices.instance.phoneRepository.create(newPhoneNumber);
      Get.snackbar(
        'تم بنجاح',
        'تم إضافة الرقم بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء إضافة الرقم: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePhoneNumber(PhoneNumber updatedPhoneNumber) async {
    try {
      isLoading.value = true;
      await BackendServices.instance.phoneRepository.update(updatedPhoneNumber);
      Get.snackbar(
        'تم بنجاح',
        'تم تحديث الرقم بنجاح',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تحديث الرقم: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removePhoneNumber(PhoneNumber removed) async {
    try {
      isLoading.value = true;
      await BackendServices.instance.phoneRepository.delete(removed);
      Get.snackbar(
        'تم بنجاح',
        'تم حذف الرقم بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء حذف الرقم: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  String getQuery() {
    return _query.value;
  }

  Future<void> assignPhoneNumber(
      BuildContext context, PhoneNumber assigned) async {
    await clientEditModelSheet(
      context,
      initialPhoneNumber: assigned.phoneNumber,
      phonePrice: assigned.price, // Pass the phone price
      onSuccess: () async {
        try {
          isLoading.value = true;
          await BackendServices.instance.phoneRepository.delete(assigned);
          Get.back();
          Get.snackbar(
            'تم بنجاح',
            'تم تخصيص الرقم للعميل بنجاح',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar(
            'خطأ',
            'حدث خطأ أثناء تخصيص الرقم: ${e.toString()}',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        } finally {
          isLoading.value = false;
        }
      },
    );
  }
}

class ForSaleNumbers extends StatelessWidget {
  final controller = Get.put(ForSaleController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'أرقام للبيع',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            showNewNumberModalForm(context);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF667EEA),
              strokeWidth: 3,
            ),
          );
        }

        final allNumbers = controller.getNumbers();
        final query = controller.getQuery();
        final numbers = (query != "")
            ? allNumbers.where(
                (element) {
                  return element.phoneNumber!.contains(query);
                },
              ).toList()
            : allNumbers;

        return Column(
          children: [
            // Search Bar
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                ],
                onChanged: controller.updateQuery,
                decoration: InputDecoration(
                  hintText: "البحث عن رقم...",
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF667EEA),
                      size: 20,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
              ),
            ),

            // Numbers List
            Expanded(
              child: numbers.isNotEmpty
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        // Responsive grid based on screen width
                        int crossAxisCount = 1;
                        if (constraints.maxWidth > 1200) {
                          crossAxisCount = 3;
                        } else if (constraints.maxWidth > 800) {
                          crossAxisCount = 2;
                        }

                        if (crossAxisCount == 1) {
                          // Single column list view for mobile
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: numbers.length,
                            itemBuilder: (context, index) {
                              final phone = numbers[index];
                              return _buildPhoneCard(context, phone, false);
                            },
                          );
                        } else {
                          // Grid view for tablets/desktop
                          return GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              childAspectRatio: 1.5, // Adjusted ratio
                              crossAxisCount:
                                  MediaQuery.of(context).size.width > 800
                                      ? 4
                                      : 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                            ),
                            itemCount: numbers.length,
                            itemBuilder: (context, index) {
                              final phone = numbers[index];
                              return _buildPhoneCard(context, phone, true);
                            },
                          );
                        }
                      },
                    )
                  : _buildEmptyState(query),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPhoneCard(
      BuildContext context, PhoneNumber phone, bool isGridView) {
    final price = phone.price;
    final number = phone.phoneNumber!;

    return Container(
      margin: isGridView ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 30,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: isGridView
              ? _buildGridCardContent(context, phone, number, price ?? 0.0)
              : _buildListCardContent(context, phone, number, price ?? 0.0),
        ),
      ),
    );
  }

  Widget _buildListCardContent(
      BuildContext context, PhoneNumber phone, String number, double price) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phone Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.phone_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),

              // Number and Price Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF48BB78).withOpacity(0.1),
                            const Color(0xFF38A169).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF48BB78).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.monetization_on_rounded,
                            size: 18,
                            color: Color(0xFF48BB78),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$price جـ",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF48BB78),
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

          const SizedBox(height: 16),

          // Bottom row with action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildModernActionButton(
                icon: Icons.edit_rounded,
                color: const Color(0xFF4299E1),
                onTap: () => showEditPriceModal(context, phone),
              ),
              const SizedBox(width: 8),
              _buildModernActionButton(
                icon: Icons.assignment_ind_rounded,
                color: const Color(0xFF48BB78),
                onTap: () => controller.assignPhoneNumber(context, phone),
              ),
              const SizedBox(width: 8),
              _buildModernActionButton(
                icon: Icons.delete_outline_rounded,
                color: const Color(0xFFE53E3E),
                onTap: () => _showDeleteConfirmation(context, phone),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridCardContent(
      BuildContext context, PhoneNumber phone, String number, double price) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Icon and Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667EEA),
                      Color(0xFF764BA2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.phone_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              // Mini action buttons for grid view
              Row(
                children: [
                  _buildMiniActionButton(
                    icon: Icons.edit_rounded,
                    color: const Color(0xFF4299E1),
                    onTap: () => showEditPriceModal(context, phone),
                  ),
                  _buildMiniActionButton(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFE53E3E),
                    onTap: () => _showDeleteConfirmation(context, phone),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Phone Number
          Text(
            number,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A202C),
            ),
          ),

          const SizedBox(height: 8),

          // Price Tag
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF48BB78).withOpacity(0.1),
                  const Color(0xFF38A169).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$price جـ",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF48BB78),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Assign Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.assignPhoneNumber(context, phone),
              icon: const Icon(Icons.assignment_ind_rounded, size: 18),
              label: const Text(
                'تخصيص',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF48BB78),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildMiniActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String query) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                query == ""
                    ? Icons.phone_disabled_rounded
                    : Icons.search_off_rounded,
                size: 40,
                color: const Color(0xFF667EEA),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              query == "" ? "لا يوجد أرقام للبيع" : "لا توجد نتائج لهذا البحث",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              query == "" ? "أضف أرقام جديدة للبدء" : "جرب البحث بكلمات مختلفة",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PhoneNumber phone) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'تأكيد الحذف',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          content: Text(
            'هل أنت متأكد من حذف الرقم ${phone.phoneNumber}؟',
            style: const TextStyle(
              color: Color(0xFF4A5568),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Color(0xFF4A5568)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.removePhoneNumber(phone);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'حذف',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

String? validator(String? value) {
  if (value == null || value.isEmpty) {
    return "لا يمكن تركه فارغ !!!";
  } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
    return "قيمة غير صالحة";
  }
  return null;
}

Future<void> showNewNumberModalForm(BuildContext context) {
  final controller = Get.find<ForSaleController>();
  final phoneController = TextEditingController();
  final priceController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final isSubmitting = false.obs;

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    showDragHandle: false,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    "إضافة رقم جديد",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Phone Number Field
                  _buildFormField(
                    controller: phoneController,
                    label: "رقم الهاتف",
                    hint: "أدخل رقم الهاتف",
                    icon: Icons.phone_rounded,
                    iconColor: const Color(0xFF667EEA),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Price Field
                  _buildFormField(
                    controller: priceController,
                    label: "السعر",
                    hint: "أدخل السعر",
                    icon: Icons.price_change_rounded,
                    iconColor: const Color(0xFF48BB78),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    suffix: "جـ",
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  Obx(() => Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF48BB78), Color(0xFF38A169)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF48BB78).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: isSubmitting.value
                              ? null
                              : () async {
                                  if (formKey.currentState?.validate() ??
                                      false) {
                                    try {
                                      isSubmitting.value = true;
                                      final phoneValue =
                                          phoneController.text.trim();
                                      final priceText =
                                          priceController.text.trim();
                                      final priceValue =
                                          double.tryParse(priceText);

                                      if (priceValue == null) {
                                        throw Exception("السعر غير صالح");
                                      }

                                      final phoneObject = PhoneNumber(
                                        id: -1,
                                        createdAt: DateTime.now(),
                                        clientId: null,
                                        phoneNumber: phoneValue,
                                        price: priceValue,
                                        forSale: true,
                                      );

                                      await controller
                                          .addPhoneNumber(phoneObject);
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    } catch (e) {
                                      Get.snackbar(
                                        'خطأ',
                                        'فشل في إضافة الرقم: ${e.toString()}',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    } finally {
                                      isSubmitting.value = false;
                                    }
                                  }
                                },
                          child: isSubmitting.value
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                              : const Text(
                                  "إضافة الرقم",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      )),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> showEditPriceModal(BuildContext context, PhoneNumber phone) {
  final controller = Get.find<ForSaleController>();
  final priceController = TextEditingController(text: phone.price.toString());
  final formKey = GlobalKey<FormState>();
  final isSubmitting = false.obs;

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    showDragHandle: false,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    "تعديل السعر",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone number display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone_rounded,
                          color: Color(0xFF667EEA),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          phone.phoneNumber!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Price Field
                  _buildFormField(
                    controller: priceController,
                    label: "السعر الجديد",
                    hint: "أدخل السعر الجديد",
                    icon: Icons.price_change_rounded,
                    iconColor: const Color(0xFF4299E1),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    suffix: "جـ",
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  Obx(() => Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4299E1), Color(0xFF3182CE)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4299E1).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: isSubmitting.value
                              ? null
                              : () async {
                                  if (formKey.currentState?.validate() ??
                                      false) {
                                    try {
                                      isSubmitting.value = true;
                                      final priceText =
                                          priceController.text.trim();
                                      final priceValue =
                                          double.tryParse(priceText);

                                      if (priceValue == null) {
                                        throw Exception("السعر غير صالح");
                                      }

                                      final updatedPhone = PhoneNumber(
                                        id: phone.id,
                                        createdAt: phone.createdAt,
                                        clientId: phone.clientId,
                                        phoneNumber: phone.phoneNumber,
                                        price: priceValue,
                                        forSale: phone.forSale,
                                      );

                                      await controller
                                          .updatePhoneNumber(updatedPhone);
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    } catch (e) {
                                      Get.snackbar(
                                        'خطأ',
                                        'فشل في تحديث السعر: ${e.toString()}',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    } finally {
                                      isSubmitting.value = false;
                                    }
                                  }
                                },
                          child: isSubmitting.value
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                              : const Text(
                                  "تحديث السعر",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      )),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildFormField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  required Color iconColor,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  String? suffix,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      prefixIcon: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: iconColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
    ),
    validator: validator,
  );
}
