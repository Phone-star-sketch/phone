import 'package:get/get.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/services/backend/backend_service_type.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';

class ClientBottomSheetController extends GetxController {
  //--------------------------------------

  //--------------------------------------
  late final Rx<Client> _client;
  final List<Log> _logs = <Log>[].obs;
  final List<System> _systems = <System>[].obs;

  List<SystemType> _types = <SystemType>[].obs;

  int _logsLength = 0;
  int _systemsLength = 0;

  void setClient(Client client) async {
    _client = client.obs;
    _client.value = client;

    _types =
        await BackendServices.instance.systemTypeRepository.getAllTypes(true);

    BackendServices.instance.clientRepository
        .bindStreamToClientLogsChanges(client, (data) {
      _logs.clear();
      _logs.addAll(
          data.map((logJsonObject) => Log.fromJson(logJsonObject)).toList());

      _logsLength = _logs.length;
    });

    BackendServices.instance.clientRepository
        .bindStreamToClientSystemsChanges(client, (data) async {
      try {
        final systems = (data as List).map((systemJsonObject) {
          SystemType t = _types.firstWhere(
              (type) => type.id == systemJsonObject['type_id'] as Object);
          systemJsonObject['system_type'] = t.toJson();
          return System.fromJson(systemJsonObject);
        }).toList();
        _systems.clear();
        _systems.addAll(systems);
        _systemsLength = _systems.length;
      } catch (e) {
        print(e);
      }
    });

    BackendServices.instance.clientRepository.bindStreamToClientChanges(
      client,
      (payload) {
        try {
          print(payload);

          final data = payload[0];
          _client.value.totalCash = data[Client.totalCashColumns];
        } catch (e) {
          Get.snackbar("مشكلة اثناء تحديث البيانات", e.toString());
        }
      },
    );
  }

  Client getClient() {
    return _client.value;
  }

  List<Log> getClientLogs() {
    return _logs;
  }

  List<System> getClientSystems() {
    return _systems;
  }

  int getLogLength() {
    return _logsLength;
  }

  int getSystemsLength() {
    return _systemsLength;
  }

  List<SystemType> getAllTypes() {
    return _types;
  }
}
