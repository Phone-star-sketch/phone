import 'package:get/get.dart';
import 'package:phone_system_app/controllers/client_bottom_sheet_controller.dart';

class ClientBottomSheetBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ClientBottomSheetController());
  }
}
