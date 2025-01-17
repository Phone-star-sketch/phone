import 'backend_service_type.dart';
import 'supabase_backend_services.dart';

class BackendServices {
  static SupabaseBackendServices? _instance;

  static SupabaseBackendServices get instance {
    _instance ??= SupabaseBackendServices();
    return _instance!;
  }
}
