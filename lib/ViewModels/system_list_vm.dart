import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';

class SystemListViewModel extends GetxController {
  RxInt editedCardIndex = (-1).obs;

  // ✅ استخدام RxList بدل List عادي
  RxList<SystemType> _types = <SystemType>[].obs;
  RxBool isLoading = false.obs;
  RxBool isSaving = false.obs; // ✅ إضافة loading للتعديل

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

  // ✅ دالة للتحديث بدون loading indicator (للاستخدام بعد الحذف/الإضافة)
  Future<void> updateTypesSilently(bool isAscending) async {
    final types = await BackendServices.instance.systemTypeRepository
        .getAllTypes(isAscending);
    _types.clear();
    _types.addAll(types);
  }

  // ✅ دالة للتحديث المباشر
  void refreshTypes() {
    _types.refresh();
  }

  //about the from
  final formKey = GlobalKey<FormState>();
  final systemName = TextEditingController();
  final systemDescription = TextEditingController();
  final systemPrice = TextEditingController();
  final RxBool isRecurring =
      false.obs; // خدمة متكررة شهرياً - الافتراضي false للخدمات الأخرى

  // تحديث القيمة عند التعديل
  void setCurrentSystem(SystemType system) {
    systemName.text = system.name ?? '';
    systemDescription.text = system.description ?? '';
    systemPrice.text = system.price.toString();
    isRecurring.value = system.isRecurring;
  }
}
