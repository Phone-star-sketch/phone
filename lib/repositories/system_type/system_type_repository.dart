import 'package:phone_system_app/models/system_type.dart';

abstract class SystemTypeRepository {
  Future<List<SystemType>> getAllTypes(bool isAscending);
}
