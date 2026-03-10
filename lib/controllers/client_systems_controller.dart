import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';

class ClientSystemController extends GetxController {
  static final RxList<System> systems = <System>[].obs;
  static final RxList<Map<String,dynamic>> allTypesId = <Map<String,dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      allTypesId.value =
          await BackendServices.instance.systemRepository.getAll("type_id");
    } catch (e) {
      debugPrint('Error loading system type IDs: $e');
    }
  }
}
