import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/models/phone_number.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/widget_models/clientCreationModelSheet.dart'; // Correct import

class ForSaleController extends GetxController {
  List<PhoneNumber> _numbers = <PhoneNumber>[].obs;

  RxString _query = "".obs;

  List<PhoneNumber> getNumbers() {
    return _numbers;
  }

  @override
  void onInit() {
    super.onInit();

    BackendServices.instance.phoneRepository.bindStreamToForSaleNumbersChanges(
      (payload) {
        _numbers.clear();

        _numbers.addAll(payload
            .map((phoneJsonObject) => PhoneNumber.fromJson(phoneJsonObject))
            .toList());
      },
    );
  }

  void updateQuery(String value) {
    _query.value = value;
  }

  void addPhoneNumber(PhoneNumber newPhoneNumber) async {
    await BackendServices.instance.phoneRepository.create(newPhoneNumber);
  }

  void removePhoneNumber(PhoneNumber removed) {
    try {
      BackendServices.instance.phoneRepository.delete(removed);
    } catch (e) {
      Get.snackbar(
          "Problem happend during removing phone number ", e.toString());
    }
  }

  String getQuery() {
    return _query.value;
  }

  Future<void> assignPhoneNumber(BuildContext context, PhoneNumber assigned) async {
    await clientEditModelSheet(
      context,
      initialPhoneNumber: assigned.phoneNumber,
      onSuccess: () async {
        try {
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
            'حدث خطأ أثناء تخصيص الرقم',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
    );
  }
}

class ForSaleNumbers extends StatelessWidget {
  final controller = Get.put(ForSaleController());
  @override
  Widget build(BuildContext context) {
    final colors = Get.theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
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
                  decoration: const InputDecoration(
                      hintText: "أبحث عن رقم",
                      hintStyle: TextStyle(color: Colors.black45),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)))),
                )),
            (numbers.isNotEmpty)
                ? Expanded(
                    child: ListView.separated(
                      itemCount: numbers.length,
                      itemBuilder: (context, index) {
                        final phone = numbers[index];

                        final price = phone.price;
                        final number = phone.phoneNumber!;

                        return Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Card(
                            color: Colors.red,
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(20)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    number,
                                    style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  // Left Part

                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "$price" "جـ",
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Column(
                                        children: [
                                          IconButton(
                                              onPressed: () async {
                                                await controller
                                                    .assignPhoneNumber(
                                                        context, phone);
                                              },
                                              tooltip: "بيع الرقم",
                                              icon: const Icon(
                                                Icons.assignment_ind_rounded,
                                                color: Colors.green,
                                              )),
                                          IconButton(
                                              onPressed: () async {
                                                controller
                                                    .removePhoneNumber(phone);
                                              },
                                              tooltip: "حذف الرقم",
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              )),
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => const Divider(
                        indent: 100,
                        endIndent: 100,
                      ),
                    ),
                  )
                : SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 0.7 * MediaQuery.of(context).size.height,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                            color: Colors.black12,
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                        child: SizedBox(
                          height: 200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  (query == "")
                                      ? Icons.heart_broken
                                      : Icons.search_off,
                                  size: 70,
                                  color: Colors.red),
                              const SizedBox(
                                height: 50,
                              ),
                              Text((query == "")
                                  ? "لا يوجد أرقام للبيع"
                                  : "لا توجد نتائج لهذا البحث"),
                            ],
                          ),
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
  if (value!.isEmpty) {
    return "لا يمكن تركه فارغ !!!";
  } else if (!value.isNumericOnly) {
    return "قيمة غير صالحة";
  }
  return null;
}

Future<void> showNewNumberModalForm(BuildContext context) {
  final controller = Get.put(ForSaleController());

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.blue[100],
    enableDrag: true,
    showDragHandle: true,
    isScrollControlled: true,
    barrierLabel: "اضافة رقم",
    builder: (context) {
      final phoneController = TextEditingController();
      final priceController = TextEditingController();
      final formKey = GlobalKey<FormState>();

      return Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "الرقم",
                    hintStyle: TextStyle(color: Colors.black38),
                    icon: Icon(Icons.phone)),
                validator: validator,
              ),
              const SizedBox(
                height: 50,
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  disabledBorder: OutlineInputBorder(),
                  border: OutlineInputBorder(),
                  hintText: "السعر",
                  hintStyle: TextStyle(color: Colors.black38),
                  icon: Icon(Icons.price_change),
                ),
                validator: validator,
              ),
              const SizedBox(
                height: 50,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final phoneValue = phoneController.text;
                    final priceValue = double.parse(priceController.text);
                    final phoneObject = PhoneNumber(
                      id: -1,
                      createdAt: DateTime.now(),
                      clientId: null,
                      phoneNumber: phoneValue,
                      price: priceValue,
                      forSale: true,
                    );
                    controller.addPhoneNumber(phoneObject);
                    Get.back();
                  }
                },
                child: const Text("أضافة"),
              )
            ],
          ),
        ),
      );
    },
  );
}
