import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/controllers/client_bottom_sheet_controller.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';

class ExcludedSystemsManager extends GetxController {
  final RxList<System> _excludedSystems = <System>[].obs;

  List<System> get excludedSystems => _excludedSystems;

  void setExcludedSystems(List<System> systems) {
    _excludedSystems.value = systems;
  }

  List<System> getExcludedSystems() {
    return _excludedSystems;
  }

  bool isSystemExcluded(System system) {
    return _excludedSystems.any((excluded) => excluded.id == system.id);
  }

  bool isSystemTypeExcluded(String systemTypeName) {
    return _excludedSystems
        .any((excluded) => excluded.type?.name == systemTypeName);
  }

  void clearExclusions() {
    _excludedSystems.clear();
  }

  double calculateExcludedAmount() {
    double total = 0;
    for (var system in _excludedSystems) {
      if (system.type!.category == SystemCategory.mobileInternet) {
        bool isPaid = system.name?.contains('[مدفوع]') ?? false;
        if (!isPaid) {
          total += system.type!.price ?? 0;
        }
      }
    }
    return total;
  }
}

class OtherServicesExcludePriceController extends GetxController {
  final RxList<System> _excludedSystems = <System>[].obs;
  final RxList<System> _allOtherServices = <System>[].obs;
  final RxList<System> _allSystems = <System>[].obs;

  List<System> get excludedSystems => _excludedSystems;
  List<System> get allOtherServices => _allOtherServices;
  List<System> get allSystems => _allSystems;

  void setAllSystems(List<System> systems) {
    _allSystems.value = systems;
    _allOtherServices.value = systems
        .where((s) => s.type!.category == SystemCategory.mobileInternet)
        .toList();
  }

  void toggleSystemExclusion(System system) {
    if (_excludedSystems.contains(system)) {
      _excludedSystems.remove(system);
    } else {
      _excludedSystems.add(system);
    }
  }

  bool isExcluded(System system) {
    return _excludedSystems.contains(system);
  }

  double calculateTotalWithExclusions(List<System> allSystems) {
    double total = 0;
    for (var system in allSystems) {
      if (system.type!.category == SystemCategory.mobileInternet) {
        // Skip excluded systems
        if (_excludedSystems.contains(system)) continue;

        // Check if paid
        bool isPaid = system.name?.contains('[مدفوع]') ?? false;
        if (!isPaid) {
          total += system.type!.price ?? 0;
        }
      } else {
        // Always add flex systems
        total += system.type!.price ?? 0;
      }
    }
    return total;
  }

  double calculateExcludedAmount() {
    double total = 0;
    for (var system in _excludedSystems) {
      if (system.type!.category == SystemCategory.mobileInternet) {
        bool isPaid = system.name?.contains('[مدفوع]') ?? false;
        if (!isPaid) {
          total += system.type!.price ?? 0;
        }
      }
    }
    return total;
  }

  void clearExclusions() {
    _excludedSystems.clear();
  }

  void applyExclusions() {
    // Pass the excluded systems to the manager
    if (!Get.isRegistered<ExcludedSystemsManager>()) {
      Get.put(ExcludedSystemsManager());
    }
    Get.find<ExcludedSystemsManager>().setExcludedSystems(_excludedSystems);

    // Calculate and save the new total to database and update client's cash
    _saveCalculatedTotalToDatabase();
  }

  // Add method to save calculated total to database and update client cash
  Future<void> _saveCalculatedTotalToDatabase() async {
    try {
      if (Get.isRegistered<ClientBottomSheetController>()) {
        final clientController = Get.find<ClientBottomSheetController>();
        final client = clientController.getClient();

        if (client != null) {
          // Use all systems for calculation
          final newTotal = calculateTotalWithExclusions(_allSystems);
          final excludedAmount = calculateExcludedAmount();

          // Update client's total services price
          client.totalServicesPrice = newTotal;

          // Recalculate totalCash to reflect exclusions
          double otherTotal = 0;
          if (client.numbers != null && client.numbers!.isNotEmpty) {
            final systems = client.numbers![0].systems;
            if (systems != null) {
              for (var system in systems) {
                // Add non-mobileInternet systems (like mainPackage, internetPackage)
                if (system.type!.category != SystemCategory.mobileInternet) {
                  otherTotal += system.type!.price ?? 0;
                }
              }
            }
          }

          // Update totalCash with new calculation (negative because it's debt)
          client.totalCash = -(newTotal + otherTotal);

          await BackendServices.instance.clientRepository.update(client);

          // Update UI controllers
          clientController.updateClient();
          Get.find<AccountClientInfo>().updateCurrnetClinets();

          Get.snackbar(
            'تم التطبيق',
            'تم استبعاد ${excludedAmount.toStringAsFixed(0)} جنيهاً من إجمالي المستحقات\nسيتم تطبيق التغييرات في الفواتير المطبوعة',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green[100],
            colorText: Colors.green[900],
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تطبيق الاستبعادات: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    }
  }

  // Add method to permanently delete excluded systems from database
  Future<void> deleteExcludedSystemsFromDatabase() async {
    try {
      if (_excludedSystems.isEmpty) {
        Get.snackbar(
          'تنبيه',
          'لا توجد خدمات مختارة للحذف',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[900],
        );
        return;
      }

      final excludedAmount = calculateExcludedAmount();
      final deletedCount =
          _excludedSystems.length; // Store count before clearing

      if (Get.isRegistered<ClientBottomSheetController>()) {
        final clientController = Get.find<ClientBottomSheetController>();
        final client = clientController.getClient();

        if (client != null) {
          // Delete each excluded system from database
          for (var system in _excludedSystems) {
            await BackendServices.instance.systemRepository.delete(system);
          }

          // Remove excluded systems from the all systems list
          _allSystems
              .removeWhere((system) => _excludedSystems.contains(system));
          _allOtherServices
              .removeWhere((system) => _excludedSystems.contains(system));

          // Recalculate the total services price without excluded systems
          final newTotal = calculateTotalWithExclusions(_allSystems);
          client.totalServicesPrice = newTotal;

          // Update totalCash: reduce the debt by the excluded amount
          if (client.totalCash != null) {
            client.totalCash = client.totalCash! + excludedAmount;
          }

          await BackendServices.instance.clientRepository.update(client);

          // Update UI controllers
          clientController.updateClient();
          Get.find<AccountClientInfo>().updateCurrnetClinets();

          // Clear exclusions after successful deletion
          _excludedSystems.clear();

          Get.snackbar(
            'تم الحذف',
            'تم حذف $deletedCount خدمة وتقليل المستحقات بمقدار ${excludedAmount.toStringAsFixed(0)} جنيهاً',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green[100],
            colorText: Colors.green[900],
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء حذف الخدمات: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    }
  }

  // Show confirmation dialog before permanent deletion
  Future<void> showDeleteConfirmationDialog() async {
    if (_excludedSystems.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'لا توجد خدمات مختارة للحذف',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
      );
      return;
    }

    final excludedAmount = calculateExcludedAmount();

    await Get.defaultDialog(
      title: 'تأكيد الحذف',
      backgroundColor: Colors.white,
      titleStyle: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold,
      ),
      content: Column(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'هل أنت متأكد من حذف ${_excludedSystems.length} خدمة نهائياً؟',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              children: [
                Text(
                  'سيتم تقليل المستحقات بمقدار:',
                  style: TextStyle(
                    color: Colors.red[800],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${excludedAmount.toStringAsFixed(0)} جنيهاً',
                  style: TextStyle(
                    color: Colors.red[900],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'تحذير: هذا الإجراء لا يمكن التراجع عنه!',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[900],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        onPressed: () async {
          Get.back(); // Close dialog
          await deleteExcludedSystemsFromDatabase();
        },
        child: const Text(
          'تأكيد الحذف',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      cancel: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        onPressed: () => Get.back(),
        child: const Text('إلغاء'),
      ),
    );
  }
}

Future<void> showOtherServicesExcludeSheet(
  BuildContext context,
  List<System> systems,
) async {
  final controller = Get.put(OtherServicesExcludePriceController());
  controller.setAllSystems(systems);

  // Ensure ExcludedSystemsManager is registered
  if (!Get.isRegistered<ExcludedSystemsManager>()) {
    Get.put(ExcludedSystemsManager());
  }

  // Load existing exclusions from manager if available
  final existingExclusions =
      Get.find<ExcludedSystemsManager>().getExcludedSystems();
  for (var system in existingExclusions) {
    controller.toggleSystemExclusion(system);
  }

  final colors = Get.theme.colorScheme;
  double width = MediaQuery.of(context).size.width;

  return showModalBottomSheet(
    backgroundColor: Colors.white,
    enableDrag: true,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints.expand(
      width: width > 800 ? 800 : width,
      height: MediaQuery.of(context).size.height * 0.8,
    ),
    context: context,
    builder: (context) {
      return GetBuilder<OtherServicesExcludePriceController>(
        builder: (controller) => OtherServicesExcludeWidget(
          controller: controller,
          colors: colors,
          allSystems: systems,
        ),
      );
    },
  ).whenComplete(() {
    if (Get.isRegistered<OtherServicesExcludePriceController>()) {
      Get.delete<OtherServicesExcludePriceController>(force: true);
    }
  });
}

class OtherServicesExcludeWidget extends StatelessWidget {
  final OtherServicesExcludePriceController controller;
  final ColorScheme colors;
  final List<System> allSystems;

  const OtherServicesExcludeWidget({
    super.key,
    required this.controller,
    required this.colors,
    required this.allSystems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[700]!, Colors.orange[900]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.visibility_off,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'استبعاد خدمات من الحساب',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Total Display
          Obx(() {
            final originalTotal = _calculateOriginalTotal();
            final newTotal =
                controller.calculateTotalWithExclusions(controller.allSystems);
            final excludedAmount = controller.calculateExcludedAmount();

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  _buildTotalRow(
                      'التكلفة الأصلية:', originalTotal, Colors.grey[700]!),
                  const Divider(),
                  _buildTotalRow('المستبعد:', excludedAmount, Colors.red),
                  const Divider(),
                  _buildTotalRow(
                      'التكلفة النهائية:', newTotal, Colors.green[700]!,
                      isMain: true),
                  if (excludedAmount > 0) ...[
                    const Divider(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'سيتم تقليل المستحقات بمقدار ${excludedAmount.toStringAsFixed(0)} جنيهاً',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'وسيتم إخفاؤها من الفواتير المطبوعة',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          // Action Buttons
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        controller.clearExclusions();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة تعيين'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Apply exclusions and close
                        controller.applyExclusions();
                        Get.back();
                      },
                      icon: const Icon(Icons.visibility_off),
                      label: const Text('إخفاء مؤقت'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Add permanent deletion button
              Obx(() => controller.excludedSystems.isNotEmpty
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await controller.showDeleteConfirmationDialog();
                          Get.back(); // Close the bottom sheet after deletion
                        },
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('حذف نهائي من قاعدة البيانات'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),
            ],
          ),

          const SizedBox(height: 20),

          // Services List
          const Text(
            'اختر الخدمات المراد استبعادها:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: Obx(() {
              if (controller.allOtherServices.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد خدمات أخرى',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return ListView.builder(
                  itemCount: controller.allOtherServices.length,
                  itemBuilder: (context, index) {
                    final system = controller.allOtherServices[index];
                    final isExcluded = controller.isExcluded(system);
                    final isPaid = system.name?.contains('[مدفوع]') ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CheckboxListTile(
                        contentPadding: const EdgeInsets.all(16),
                        value: isExcluded,
                        onChanged: isPaid
                            ? null
                            : (value) {
                                controller.toggleSystemExclusion(system);
                              },
                        title: Row(
                          children: [
                            isPaid
                                ? const Icon(Icons.paid, color: Colors.green)
                                : const Icon(Icons.payment,
                                    color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              system.type!.name!,
                              style: TextStyle(
                                color: isPaid ? Colors.grey : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${system.type!.price!} جنيه',
                              style: TextStyle(
                                color: isPaid ? Colors.grey : Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (system.createdAt != null)
                              Text(
                                'تاريخ الإضافة: ${fullExpressionArabicDate(system.createdAt!)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            if (isPaid)
                              const Text(
                                'تم الدفع',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        checkColor: Colors.white,
                        activeColor: Colors.orange[700],
                        enabled: !isPaid,
                      ),
                    );
                  });
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, Color color,
      {bool isMain = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMain ? 16 : 14,
            fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(0)} جنيهاً',
          style: TextStyle(
            fontSize: isMain ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  double _calculateOriginalTotal() {
    double total = 0;

    for (var system in allSystems) {
      if (system.type!.category == SystemCategory.mobileInternet) {
        bool isPaid = system.name?.contains('[مدفوع]') ?? false;
        if (!isPaid) {
          total += system.type!.price ?? 0;
        }
      } else {
        total += system.type!.price ?? 0;
      }
    }

    return total;
  }
}
