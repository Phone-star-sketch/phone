import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/repositories/crud_mixin.dart';

abstract class SystemTypeRepository {
  Future<List<SystemType>> getAllTypes(bool isAscending);
}
