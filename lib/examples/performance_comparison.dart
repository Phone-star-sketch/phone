/// مثال على الفرق في الأداء بين الطريقة القديمة والجديدة
/// 
/// الطريقة القديمة:
/// - تجيب كل عميل مع كل الـ relations (phone, system, system_type, log)
/// - لو عندك 440 عميل = مئات الـ queries
/// - الوقت: 5-10 ثواني أو أكثر
/// 
/// الطريقة الجديدة (Database Function):
/// - Query واحدة فقط بترجع كل البيانات المطلوبة
/// - الوقت: أقل من ثانية
/// 
/// مثال الاستخدام:

import 'package:phone_system_app/repositories/client/supabase_client_repository.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';

void performanceExample() async {
  final repository = BackendServices.instance.clientRepository 
      as SupabaseClientRepository;
  
  // ❌ الطريقة القديمة (بطيئة)
  // final clients = await repository.getAllClientsByAccount(account);
  // الوقت: 5-10 ثواني
  
  // ✅ الطريقة الجديدة (سريعة)
  final summaries = await repository.getClientsSummary(accountId: 1);
  // الوقت: أقل من ثانية
  
  print('عدد العملاء: ${summaries.length}');
  
  // عرض البيانات
  for (final summary in summaries.take(5)) {
    print('الاسم: ${summary.name}');
    print('الهواتف: ${summary.phoneNumbers?.join(", ")}');
    print('الأنظمة: ${summary.systemNames?.join(", ")}');
    print('المستحقات: ${summary.totalCash}');
    print('---');
  }
}

/// لو محتاج البيانات الكاملة لعميل معين:
/// استخدم getFullClientData() في الـ Controller
/// 
/// مثال:
/// final fullClient = await AccountClientInfo.to.getFullClientData(clientId);
/// 
/// هذا يحمل البيانات الكاملة فقط عند الحاجة (lazy loading)
