# تحسين الأداء - قائمة العملاء

## المشكلة الأصلية
عند فتح صفحة العملاء، كان التطبيق يعمل مئات الـ queries للحصول على:
- بيانات العملاء
- أرقام الهواتف لكل عميل
- الأنظمة لكل رقم
- أنواع الأنظمة
- السجلات

**النتيجة:** بطء شديد (5-10 ثواني أو أكثر)

---

## الحل المطبق

### 1. Database Function
تم إنشاء function في Supabase اسمها `get_clients_summary`:
- تجمع كل البيانات المطلوبة في **query واحدة**
- ترجع البيانات بشكل محسّن (arrays للهواتف والأنظمة)
- **النتيجة:** أقل من ثانية

### 2. Model جديد: ClientSummary
```dart
class ClientSummary {
  int? id;
  String? name;
  double? totalCash;
  DateTime? expireDate;
  List<String>? phoneNumbers;  // مصفوفة الهواتف
  List<String>? systemNames;   // مصفوفة الأنظمة
  double? totalServicesPrice;
  int? accountId;
}
```

### 3. Repository Method
```dart
Future<List<ClientSummary>> getClientsSummary({int? accountId}) async {
  final response = await _clinet.rpc(
    'get_clients_summary',
    params: {'p_account_id': accountId},
  );
  return (response as List)
      .map((e) => ClientSummary.fromJson(e))
      .toList();
}
```

### 4. Controller Update
الـ Controller دلوقتي بيستخدم الـ function الجديدة في:
- `onReady()` - التحميل الأولي
- `_refreshClientsAfterBulkOperation()` - التحديث بعد العمليات الكبيرة

---

## الفرق في الأداء

| الطريقة | عدد الـ Queries | الوقت المتوقع |
|---------|----------------|---------------|
| القديمة | 440+ queries | 5-10 ثواني |
| الجديدة | 1 query | < 1 ثانية |

---

## Lazy Loading للبيانات الكاملة

لو محتاج البيانات الكاملة لعميل معين (مع كل الـ relations):
```dart
final fullClient = await AccountClientInfo.to.getFullClientData(clientId);
```

هذا يحمل البيانات فقط عند الحاجة ويخزنها في cache.

---

## كيفية التراجع

لو حصلت أي مشكلة، يمكن حذف الـ function:
```sql
DROP FUNCTION IF EXISTS get_clients_summary(INTEGER);
```

وتعديل الـ Controller ليستخدم الطريقة القديمة:
```dart
clinets.value = await repository.getBasicClientsByAccount(currentAccount);
```

---

## الملفات المعدلة

1. **Database:** Function جديدة `get_clients_summary`
2. **lib/models/client_summary.dart** - Model جديد
3. **lib/repositories/client/supabase_client_repository.dart** - Method جديدة
4. **lib/controllers/account_client_info_data.dart** - استخدام الـ function الجديدة

---

## ملاحظات

- الـ Function **read-only** - لا تعدل أي بيانات
- البيانات المرجعة هي نفسها، فقط الطريقة أسرع
- الـ Realtime updates لا تزال تعمل بشكل طبيعي
- الـ Pagination والبحث يعملان بدون تغيير
