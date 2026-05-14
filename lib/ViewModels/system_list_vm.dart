import 'package:get/get.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';

class SystemListViewModel extends GetxController {
  // Observable list of system types
  final RxList<SystemType> _types = <SystemType>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onReady() async {
    super.onReady();
    await updateTypes(true);
  }

  List<SystemType> getAllTypes() => _types;

  /// Update types with loading indicator
  Future<void> updateTypes(bool isAscending) async {
    isLoading.value = true;
    try {
      final types = await BackendServices.instance.systemTypeRepository
          .getAllTypes(isAscending);
      _types.clear();
      _types.addAll(types);
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل تحميل البيانات: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Update types silently (without loading indicator)
  Future<void> updateTypesSilently(bool isAscending) async {
    try {
      final types = await BackendServices.instance.systemTypeRepository
          .getAllTypes(isAscending);
      _types.clear();
      _types.addAll(types);
    } catch (e) {
      // Silent failure - could log to analytics
    }
  }

  /// Refresh the observable list
  void refreshTypes() {
    _types.refresh();
  }

  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}
