import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';

class SystemListViewModel extends GetxController {
  RxInt editedCardIndex = (-1).obs;

  List<SystemType> _types = <SystemType>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onReady() async {
    await updateTypes(true);
  }

  List<SystemType> getAllTypes() {
    return _types;
  }

  Future<void> updateTypes(bool isAscending) async {
    isLoading.value = true;
    final types = await BackendServices.instance.systemTypeRepository
        .getAllTypes(isAscending);
    _types.clear();
    _types.addAll(types);
    isLoading.value = false;
  }

  //about the from
  final formKey = GlobalKey<FormState>();
  final systemName = TextEditingController();
  final systemDescription = TextEditingController();
  final systemPrice = TextEditingController();
}
