import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/phone_number.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:fluttertoast/fluttertoast.dart';

final accountController = Get.find<AccountClientInfo>();

Future clientEditModelSheet(
  BuildContext context, {
  Client? client,
  String? initialPhoneNumber,
  Function()? onSuccess,
}) async {
  final screenSize = MediaQuery.of(context).size;
  final formKey = GlobalKey<FormState>();
  final nameField = TextEditingController();
  final nationalIdField = TextEditingController();
  final addressField = TextEditingController();
  final phoneNumberField = TextEditingController(text: initialPhoneNumber);

  // Pre-populate fields if client exists
  if (client != null) {
    nameField.text = client.name ?? '';
    nationalIdField.text = client.nationalId ?? '';
    addressField.text = client.address ?? '';
    if (client.numbers?.isNotEmpty ?? false) {
      phoneNumberField.text = client.numbers![0].phoneNumber ?? '';
    }
  }

  Future saveClientData() async {
    try {
      if (client == null) {
        final newClient = Client(
          id: -1,
          createdAt: DateTime.now(),
          totalCash: 0,
          name: nameField.text,
          nationalId: nationalIdField.text,
          address: addressField.text,
          accountId: accountController.currentAccount.id,
        );

        final clientId =
            await BackendServices.instance.clientRepository.create(newClient);

        // Add phone number to the client
        final phone = PhoneNumber(
          id: -1,
          createdAt: DateTime.now(),
          phoneNumber: phoneNumberField.text,
          clientId: clientId,
          systems: [],
        );

        await BackendServices.instance.phoneRepository.create(phone);

        print('Finished creating new client');
      } else {
        // First update the client basic info
        final updatedClient = Client(
          id: client.id,
          createdAt: client.createdAt,
          totalCash: client.totalCash,
          name: nameField.text,
          nationalId: nationalIdField.text,
          address: addressField.text,
          accountId: client.accountId,
        );
        await BackendServices.instance.clientRepository.update(updatedClient);

        // Then handle phone number update
        final hasExistingPhone = client.numbers?.isNotEmpty ?? false;

        if (hasExistingPhone) {
          final existingPhone = client.numbers![0];
          final updatedPhone = PhoneNumber(
            id: existingPhone.id,
            createdAt: existingPhone.createdAt,
            phoneNumber: phoneNumberField.text,
            clientId: client.id,
            systems: existingPhone.systems ?? [],
          );

          // Update the existing phone number
          await BackendServices.instance.phoneRepository.update(updatedPhone);
        } else {
          // Create a new phone number if none exists
          final newPhone = PhoneNumber(
            id: -1,
            createdAt: DateTime.now(),
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
                  const Text(
                    'بيانات العميل',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'رقم الهاتف مطلوب' : null,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                      labelText: 'رقم الهاتف',
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
