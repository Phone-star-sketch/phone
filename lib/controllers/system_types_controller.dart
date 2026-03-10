import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';

class SystemTypeController extends GetxController {
  static final RxList<SystemType> types = <SystemType>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      types.value =
          await BackendServices.instance.systemTypeRepository.getAllTypes(true);
    } catch (e) {
      debugPrint('Error loading system types: $e');
    }
  }
}
