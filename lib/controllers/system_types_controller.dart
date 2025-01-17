import 'package:get/get.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';

class SystemTypeController extends GetxController {
  static final RxList<SystemType> types = <SystemType>[].obs;

  @override
  void onInit() async {
    super.onInit();
    types.value =
        await BackendServices.instance.systemTypeRepository.getAllTypes(true);
  }
}
