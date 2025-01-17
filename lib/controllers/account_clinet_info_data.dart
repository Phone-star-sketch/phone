import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/utils/string_utils.dart';

class AccountClinetInfo extends GetxController {
  Account currentAccount;
  TextEditingController searchController = TextEditingController();
  RxString query = "".obs;

  AccountClinetInfo({required this.currentAccount});

  

  RxList<Client> _clinets = <Client>[].obs;
  List<Client> _queryClinets = <Client>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onReady() async {
    isLoading.value = true;
    _clinets.value = await BackendServices.instance.clientRepository
        .getAllClientsByAccount(currentAccount);
    isLoading.value = false;
  }

  List<Client> getCurrentClients() {
    return _queryClinets;
  }

  void updateCurrnetClinets() async {
    final clinets = await BackendServices.instance.clientRepository
        .getAllClientsByAccount(currentAccount);
    _clinets.clear();
    _clinets.addAll(clinets);
    _queryClinets.clear();
    searchQueryChanged(searchController.text);
  }

  void searchQueryChanged(String newQuery) {
    query.value = newQuery;
    if (newQuery == "") {
      _queryClinets = [];
      return;
    }
    final results = _clinets
        .where((element) =>
            element.numbers![0].phoneNumber!.contains(newQuery) ||
            removeSpecialArabicChars(element.name!)
                .contains(removeSpecialArabicChars(newQuery)))
        .toList();
    _queryClinets.clear();
    _queryClinets.addAll(results);
  }

  List<Client> getClients() {
    return _clinets;
  }
}
