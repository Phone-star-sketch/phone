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
      onSuccess: () async {
        try {
          isLoading.value = true;
          // Delete the phone number from for_sale after successful client creation
          await BackendServices.instance.phoneRepository.delete(assigned);
          Get.back(); // Close the current view
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
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showNewNumberModalForm(context);
        },
        backgroundColor: Colors.red,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 40,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.red,
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
            Container(
              padding: const EdgeInsets.all(20),
              child: TextField(
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                ],
                onChanged: controller.updateQuery,
                decoration: InputDecoration(
                  hintText: "أبحث عن رقم",
                  hintStyle: const TextStyle(color: Colors.black45),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search, color: Colors.red),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            Expanded(
              child: numbers.isNotEmpty
                  ? ListView.separated(
                      itemCount: numbers.length,
                      itemBuilder: (context, index) {
                        final phone = numbers[index];
                        final price = phone.price;
                        final number = phone.phoneNumber!;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red[100]!,
                                    Colors.red[50]!,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.red[200],
                                  child: const Icon(
                                    Icons.phone,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                title: Text(
                                  number,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  "$price جـ",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                                trailing: SizedBox(
                                  width: 70,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () async {
                                          await controller.assignPhoneNumber(
                                              context, phone);
                                        },
                                        child: const Icon(
                                          Icons.assignment_ind_rounded,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      InkWell(
                                        onTap: () async {
                                          await controller
                                              .removePhoneNumber(phone);
                                        },
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => const SizedBox(
                        height: 10,
                      ),
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (query == "")
                                  ? Icons.heart_broken
                                  : Icons.search_off,
                              size: 70,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              (query == "")
                                  ? "لا يوجد أرقام للبيع"
                                  : "لا توجد نتائج لهذا البحث",
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        );
      }),
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
    backgroundColor: Colors.blue[50],
    enableDrag: true,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 10,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "إضافة رقم جديد",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: InputDecoration(
                    labelText: "الرقم",
                    hintText: "أدخل الرقم",
                    prefixIcon: const Icon(Icons.phone, color: Colors.red),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: validator,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: "السعر",
                    hintText: "أدخل السعر",
                    prefixIcon:
                        const Icon(Icons.price_change, color: Colors.green),
                    suffixText: "جـ",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.green),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: validator,
                ),
                const SizedBox(height: 30),
                Obx(() => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isSubmitting.value
                          ? null
                          : () async {
                              if (formKey.currentState?.validate() ?? false) {
                                try {
                                  isSubmitting.value = true;
                                  final phoneValue =
                                      phoneController.text.trim();
                                  final priceText = priceController.text.trim();
                                  final priceValue = double.tryParse(priceText);

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

                                  await controller.addPhoneNumber(phoneObject);
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
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "إضافة الرقم",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    )),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    },
  );
}
