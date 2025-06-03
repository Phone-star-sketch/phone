import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/phone_number.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:phone_system_app/controllers/client_bottom_sheet_controller.dart';

final accountController = Get.find<AccountClientInfo>();

Future clientEditModelSheet(
  BuildContext context, {
  Client? client,
  String? initialPhoneNumber,
  Function()? onSuccess,
}) async {
  final controller = Get.put(ClientBottomSheetController());
  final screenSize = MediaQuery.of(context).size;
  final formKey = GlobalKey<FormState>();
  final nameField = TextEditingController();
  final nationalIdField = TextEditingController();
  final addressField = TextEditingController();
  final phoneNumberField = TextEditingController(text: initialPhoneNumber);
  DateTime selectedDate = client?.createdAt ?? DateTime.now();

  // Pre-populate fields if client exists
  if (client != null) {
    nameField.text = client.name ?? '';
    nationalIdField.text = client.nationalId ?? '';
    addressField.text = client.address ?? '';
    if (client.numbers?.isNotEmpty ?? false) {
      phoneNumberField.text = client.numbers![0].phoneNumber ?? '';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      selectedDate = picked;
      controller.updateDate(picked);
    }
  }

  Future saveClientData() async {
    try {
      if (client == null) {
        final newClient = Client(
          id: -1,
          createdAt: selectedDate,
          totalCash: 0,
          name: nameField.text,
          nationalId: nationalIdField.text,
          address: addressField.text,
          accountId: accountController.currentAccount.id,
          numbers: [], // Initialize empty list
          logs: [], // Initialize empty list
        );

        final clientId =
            await BackendServices.instance.clientRepository.create(newClient);

        final phone = PhoneNumber(
          id: -1,
          createdAt: selectedDate,
          phoneNumber: phoneNumberField.text,
          clientId: clientId,
          systems: [],
        );

        await BackendServices.instance.phoneRepository.create(phone);

        print('Finished creating new client');
      } else {
        final updatedClient = Client(
          id: client.id,
          createdAt: selectedDate,
          totalCash: client.totalCash,
          name: nameField.text,
          nationalId: nationalIdField.text,
          address: addressField.text,
          accountId: client.accountId,
        );
        await BackendServices.instance.clientRepository.update(updatedClient);

        final hasExistingPhone = client.numbers?.isNotEmpty ?? false;

        if (hasExistingPhone) {
          final existingPhone = client.numbers![0];
          final updatedPhone = PhoneNumber(
            id: existingPhone.id,
            createdAt: selectedDate,
            phoneNumber: phoneNumberField.text,
            clientId: client.id,
            systems: existingPhone.systems ?? [],
          );

          await BackendServices.instance.phoneRepository.update(updatedPhone);
        } else {
          final newPhone = PhoneNumber(
            id: -1,
            createdAt: selectedDate,
            phoneNumber: phoneNumberField.text,
            clientId: client.id,
            systems: [],
          );
          await BackendServices.instance.phoneRepository.create(newPhone);
        }
      }

      if (onSuccess != null) {
        await onSuccess();
      }

      AccountClientInfo.to.updateCurrnetClinets();
      Get.back();
      Fluttertoast.showToast(
          msg: "تمت معالجة البيانات بنجاح",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0);
    } catch (e) {
      print('Error saving client data: $e');
      Fluttertoast.showToast(
          msg: "حدث خطأ أثناء معالجة البيانات",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  final loaders = Get.put(Loaders());

  return showModalBottomSheet(
    backgroundColor: Colors.blue[50],
    enableDrag: true,
    showDragHandle: true,
    isScrollControlled: true,
    barrierLabel: "بيانات العميل",
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    constraints: BoxConstraints(
      maxHeight: screenSize.height * 0.85,
      maxWidth: 600,
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 16,
          right: 16,
          top: 8,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: TextSelectionTheme(
              data: TextSelectionThemeData(
                selectionColor: Colors.blue.withOpacity(0.3),
                cursorColor: Colors.blue,
                selectionHandleColor: Colors.blue,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Text(
                      'بيانات العميل',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameField,
                    cursorWidth: 2,
                    showCursor: true,
                    selectionControls: MaterialTextSelectionControls(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'مطلوب' : null,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_4_outlined,
                          color: Colors.blue),
                      labelText: 'إسم العميل',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneNumberField,
                    cursorWidth: 2,
                    showCursor: true,
                    selectionControls: MaterialTextSelectionControls(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'رقم الهاتف مطلوب';
                      }
                      // Remove any whitespace and check if the number is empty
                      if (value.trim().isEmpty) {
                        return 'رقم الهاتف غير صالح';
                      }
                      // Check if the number contains valid digits
                      if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                        return 'يجب أن يحتوي رقم الهاتف على أرقام فقط';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                      labelText: 'رقم الهاتف',
                      hintText: 'أدخل رقم الهاتف',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nationalIdField,
                    cursorWidth: 2,
                    showCursor: true,
                    selectionControls: MaterialTextSelectionControls(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'مطلوب' : null,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.badge, color: Colors.blue),
                      labelText: 'الرقم القومي',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: addressField,
                    cursorWidth: 2,
                    showCursor: true,
                    selectionControls: MaterialTextSelectionControls(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'مطلوب' : null,
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.home_work, color: Colors.blue),
                      labelText: 'العنوان',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.blue),
                          const SizedBox(width: 12),
                          Text(
                            'تاريخ الأشتراك: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: loaders.clientCreationIsLoading.value
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                loaders.clientCreationIsLoading.value = true;
                                await saveClientData();
                                loaders.clientCreationIsLoading.value = false;
                              }
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'تأكيد',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (loaders.clientCreationIsLoading.value) ...[
                            const SizedBox(width: 12),
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
