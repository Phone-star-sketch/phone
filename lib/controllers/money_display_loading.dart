import 'package:get/get.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';

class Loaders extends GetxController {
  static Loaders get to => Get.put(Loaders());

  RxBool moneyIsLoading = false.obs;
  RxBool systemIsLoading = false.obs;
  RxBool clientCreationIsLoading = false.obs;
  RxBool profitLoader = false.obs;
  RxBool paymentIsLoading = false.obs;
  RxBool typesIsLoading = false.obs;
  RxBool logInIsLoading = false.obs;
  RxBool showPassword = true.obs;
  RxBool followLoading = true.obs;


  Future<void> manageSystemType(Client client, SystemType currentType) async {
    systemIsLoading.value = true;
    await BackendServices.instance.clientRepository
        .assignSystemToClient(client, currentType);
    systemIsLoading.value = false;
  }

  Future<void> changeMoneyValue(
      Client client, String textValue, bool adding) async {
    moneyIsLoading.value = true;

    await BackendServices.instance.clientRepository.addMoneyToClinet(
        client, double.parse(textValue) * ((adding) ? 1 : -1));

    moneyIsLoading.value = false;
  }
}
