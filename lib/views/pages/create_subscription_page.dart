import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/views/pages/system_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/phone_number.dart';
import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';

class CreateSubscriptionPage extends StatefulWidget {
  const CreateSubscriptionPage({Key? key}) : super(key: key);

  @override
  State<CreateSubscriptionPage> createState() => _CreateSubscriptionPageState();
}

class _CreateSubscriptionPageState extends State<CreateSubscriptionPage> {
  final systems = <Map<String, dynamic>>[].obs;
  final selectedSystem = Rxn<Map<String, dynamic>>();
  final startDate = Rx<DateTime>(DateTime.now());
  final endDate = Rx<DateTime>(DateTime.now());
  final calculatedPrice = 0.0.obs;
  bool isLoading = true;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final nationalIdController = TextEditingController();
  final addressController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchSystems();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    nationalIdController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> fetchSystems() async {
    try {
      setState(() => isLoading = true);
      final response = await Supabase.instance.client
          .from('system_type')
          .select()
          .order('name');
      systems.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحميل الأنظمة المتاحة');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void calculatePrice() {
    if (selectedSystem.value == null) return;

    final systemPrice = (selectedSystem.value!['price'] as num).toDouble();
    final monthlyPrice = systemPrice;

    // Calculate days between start and end date
    final days = endDate.value.difference(startDate.value).inDays + 1;

    // Calculate daily rate
    final dailyRate = monthlyPrice / 30;

    // Calculate total price based on days
    calculatedPrice.value = dailyRate * days;
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate.value : endDate.value,
      firstDate: isStart ? DateTime.now() : startDate.value,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      if (isStart) {
        startDate.value = picked;
        if (endDate.value.isBefore(picked)) {
          endDate.value = picked;
        }
      } else {
        endDate.value = picked;
      }
      calculatePrice();
    }
  }

  Future<void> createSubscription() async {
    if (!formKey.currentState!.validate() || selectedSystem.value == null) {
      Get.snackbar(
        'خطأ',
        'الرجاء إكمال جميع البيانات المطلوبة',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      // Create new client with totalCash from calculated price
      final client = Client(
        id: -1,
        name: nameController.text,
        nationalId: nationalIdController.text,
        address: addressController.text,
        createdAt: startDate.value,
        accountId: AccountClientInfo.to.currentAccount.id,
        numbers: [],
        totalCash:
            calculatedPrice.value, // Add the calculated price as totalCash
      );

      final clientId =
          await BackendServices.instance.clientRepository.create(client);
      client.id = clientId;

      // Create phone number
      final phone = PhoneNumber(
        id: -1,
        phoneNumber: phoneController.text,
        clientId: clientId,
        createdAt: startDate.value,
        systems: [],
      );

      final phoneId =
          await BackendServices.instance.phoneRepository.create(phone);
      phone.id = phoneId;

      // Create system using the correct model structure
      final system = System(
        id: -1,
        createdAt: DateTime.now(),
        startDate: startDate.value,
        endDate: endDate.value,
        phoneID: phoneId as int,
        typeId: selectedSystem.value!['id'],
        name: selectedSystem.value!['name'],
      );

      await BackendServices.instance.systemRepository.create(system);

      // Update UI
      AccountClientInfo.to.updateCurrnetClinets();

      // Show success dialog with client info
      if (context.mounted) {
        await showSuccessDialog(context, client);
      }

      // Clear form
      nameController.clear();
      phoneController.clear();
      nationalIdController.clear();
      addressController.clear();
      selectedSystem.value = null;
      startDate.value = DateTime.now();
      endDate.value = DateTime.now();
      calculatedPrice.value = 0.0;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء إنشاء الاشتراك: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> showSuccessDialog(BuildContext context, Client client) async {
    await Get.defaultDialog(
      title: 'تم إنشاء الاشتراك بنجاح',
      content: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 50),
          const SizedBox(height: 16),
          const Text('تم إنشاء الاشتراك بنجاح'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Get.back();
              showClientInfoSheet(context, client);
            },
            child: const Text('عرض بيانات العميل'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء اشتراك جديد'),
        backgroundColor: Colors.lightBlue[300],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client Information Section
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'بيانات العميل',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'اسم العميل',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) =>
                                  value?.isEmpty == true ? 'مطلوب' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: phoneController,
                              decoration: const InputDecoration(
                                labelText: 'رقم الهاتف',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              validator: (value) =>
                                  value?.isEmpty == true ? 'مطلوب' : null,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: nationalIdController,
                              decoration: const InputDecoration(
                                labelText: 'الرقم القومي',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge),
                              ),
                              validator: (value) =>
                                  value?.isEmpty == true ? 'مطلوب' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: addressController,
                              decoration: const InputDecoration(
                                labelText: 'العنوان',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              validator: (value) =>
                                  value?.isEmpty == true ? 'مطلوب' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Systems Grid
                    const Text(
                      'اختر النظام',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: systems.length,
                      itemBuilder: (context, index) {
                        final system = systems[index];
                        return Obx(() {
                          final isSelected = selectedSystem.value == system;
                          return InkWell(
                            onTap: () {
                              selectedSystem.value = system;
                              calculatePrice();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    system['name'] ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${system['price']} جنيه',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Date Selection
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'تاريخ البداية',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Obx(() => Text(
                                        DateFormat('yyyy-MM-dd')
                                            .format(startDate.value),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'تاريخ النهاية',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Obx(() => Text(
                                        DateFormat('yyyy-MM-dd')
                                            .format(endDate.value),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Price Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'السعر المحسوب',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Obx(() => Text(
                                '${calculatedPrice.value.toStringAsFixed(2)} جنيه',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: createSubscription,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'تأكيد الاشتراك',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
