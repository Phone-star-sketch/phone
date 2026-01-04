# دليل مشروع نظام إدارة الهواتف (Phone System App)

## نظرة عامة

تطبيق Flutter لإدارة اشتراكات الهواتف والعملاء، يدعم الويب والموبايل، مع واجهة عربية.

---

## 🏗️ هيكل المشروع

```
lib/
├── main.dart                 # نقطة الدخول الرئيسية
├── models/                   # نماذج البيانات (Data Models)
│   ├── model.dart           # Base class لجميع النماذج
│   ├── client.dart          # نموذج العميل
│   ├── system.dart          # نموذج النظام/الباقة
│   ├── account.dart         # نموذج الحساب
│   ├── log.dart             # نموذج السجلات
│   └── ...
├── repositories/             # طبقة الوصول للبيانات (Repository Pattern)
│   ├── crud_mixin.dart      # Mixin للعمليات الأساسية
│   ├── client/              # مستودع العملاء
│   ├── account/             # مستودع الحسابات
│   └── ...
├── controllers/              # GetX Controllers
│   ├── account_client_info_data.dart
│   ├── account_view_controller.dart
│   └── ...
├── services/                 # الخدمات
│   ├── backend/             # خدمات Supabase
│   ├── pdf_service.dart     # توليد PDF
│   └── ...
├── views/                    # الصفحات والـ Widgets
│   ├── pages/               # الصفحات الرئيسية
│   ├── widgets/             # مكونات قابلة لإعادة الاستخدام
│   └── ...
├── pages/                    # صفحات الترحيب
├── components/               # مكونات UI
├── theme/                    # الألوان والثيمات
└── utils/                    # أدوات مساعدة
```

---

## 📐 أنماط التصميم المتبعة

### 1. Repository Pattern
كل كيان له:
- `abstract class` (Interface) في `*_repository.dart`
- Implementation في `supabase_*_repository.dart`

```dart
// مثال: lib/repositories/client/client_repository.dart
abstract class ClientRepository {
  Future<List<Client>> getAllClientsByAccount(Account account);
  Future<void> createClientWithPhoneNumber(Client client, String phoneNumber);
  // ...
}

// lib/repositories/client/supabase_client_repository.dart
class SupabaseClientRepository extends ClientRepository with CrudOperations<Client> {
  // التنفيذ الفعلي
}
```

### 2. Model Base Class
جميع النماذج ترث من `Model`:

```dart
class Client extends Model {
  static const String nameColumn = "name";
  // ...
  
  Client.fromJson(super.data) : /* ... */ super.fromJson();
  
  @override
  Map<String, dynamic> toJson() {
    return {...super.toJson(), /* ... */};
  }
}
```

### 3. GetX State Management
- استخدم `GetxController` للـ Controllers
- استخدم `.obs` للمتغيرات التفاعلية
- استخدم `Obx()` للـ Widgets التفاعلية

```dart
class AccountClientInfo extends GetxController {
  RxList<Client> clients = <Client>[].obs;
  RxBool isLoading = false.obs;
  
  static AccountClientInfo get to => Get.find<AccountClientInfo>();
}
```

### 4. Singleton Services
```dart
class BackendServices {
  static SupabaseBackendServices get instance => _instance!;
}
```

---

## 🎨 دليل التصميم (UI/UX)

### الألوان الأساسية
```dart
// الألوان الرئيسية
Color primaryBlue = Color(0xFF1a237e);      // أزرق داكن
Color accentBlue = Color(0xFF2196F3);       // أزرق فاتح
Color errorRed = Colors.red;                 // أحمر للأخطاء
Color successGreen = Color(0xFF66BB6A);     // أخضر للنجاح
Color warningOrange = Color(0xFFFFB74D);    // برتقالي للتحذير

// خلفيات
Color darkBackground = Color(0xFF0A0B0F);   // خلفية داكنة
Color lightBackground = Color(0xFFF8F9FA); // خلفية فاتحة
```

### التدرجات (Gradients)
```dart
// تدرج رئيسي
LinearGradient(
  colors: [Color(0xFF1a237e), Color(0xFF0d47a1)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
)

// تدرج Glass Effect
LinearGradient(
  colors: [
    Colors.white.withOpacity(0.1),
    Colors.white.withOpacity(0.05),
  ],
)
```

### الخطوط
- **الخط الرئيسي:** Cairo
- **الأوزان:** Regular (400), Medium (500), SemiBold (600), Bold (700)

### أنماط الـ Widgets
```dart
// بطاقة حديثة
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    gradient: LinearGradient(...),
    boxShadow: [BoxShadow(...)],
  ),
)

// زر Glass
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    gradient: LinearGradient(colors: gradient),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
  ),
)
```

---

## 📝 قواعد الكود

### التسمية
- **الملفات:** snake_case (`client_repository.dart`)
- **الكلاسات:** PascalCase (`ClientRepository`)
- **المتغيرات:** camelCase (`totalCash`)
- **الثوابت:** SCREAMING_SNAKE_CASE أو camelCase

### أسماء الأعمدة في قاعدة البيانات
```dart
static const String nameColumn = "name";
static const String totalCashColumns = "total_cash";
```

### التعامل مع الأخطاء
```dart
try {
  // العملية
} catch (e) {
  Get.snackbar("عنوان الخطأ", e.toString());
  // أو استخدم ErrorHandler
  ErrorHandler.handleError(e, 'context');
}
```

### الرسائل للمستخدم
- **اللغة:** عربية دائماً
- **النمط:** واضحة ومختصرة

```dart
Get.snackbar("حالة الماليات", "تمت تعديل المستحقات");
```

---

## 🔧 إضافة ميزة جديدة

### 1. إضافة Model جديد
```dart
// lib/models/new_model.dart
class NewModel extends Model {
  static const String columnName = "column_name";
  
  String? field;
  
  NewModel({required super.id, super.createdAt, this.field});
  
  NewModel.fromJson(super.data)
      : field = data[columnName]?.toString(),
        super.fromJson();
  
  @override
  Map<String, dynamic> toJson() {
    return {...super.toJson(), columnName: field};
  }
}
```

### 2. إضافة Repository
```dart
// lib/repositories/new_model/new_model_repository.dart
abstract class NewModelRepository {
  Future<List<NewModel>> getAll();
  Future<void> create(NewModel item);
}

// lib/repositories/new_model/supabase_new_model_repository.dart
class SupabaseNewModelRepository extends NewModelRepository 
    with CrudOperations<NewModel> {
  final _client = Supabase.instance.client;
  static const String tableName = "new_model";
  
  @override
  Future<List<NewModel>> getAll() async {
    final data = await _client.from(tableName).select();
    return data.map((e) => NewModel.fromJson(e)).toList();
  }
}
```

### 3. إضافة Controller
```dart
// lib/controllers/new_model_controller.dart
class NewModelController extends GetxController {
  RxList<NewModel> items = <NewModel>[].obs;
  RxBool isLoading = false.obs;
  
  static NewModelController get to => Get.find();
  
  @override
  void onReady() async {
    super.onReady();
    await fetchItems();
  }
  
  Future<void> fetchItems() async {
    isLoading.value = true;
    items.value = await BackendServices.instance.newModelRepository.getAll();
    isLoading.value = false;
  }
}
```

### 4. إضافة صفحة
```dart
// lib/views/pages/new_page.dart
class NewPage extends StatelessWidget {
  final controller = Get.put(NewModelController());
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('العنوان')),
      body: Obx(() => controller.isLoading.value
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(...)),
    );
  }
}
```

---

## ⚠️ ملاحظات مهمة

### دعم الويب
```dart
if (kIsWeb) {
  // كود خاص بالويب
} else {
  // كود خاص بالموبايل
}
```

### الأداء
- استخدم `const` للـ Widgets الثابتة
- تجنب `print()` في الإنتاج، استخدم `developer.log()`
- استخدم `withValues()` بدلاً من `withOpacity()` (deprecated)

### الصلاحيات
```dart
if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index) {
  // محتوى للمدير فقط
}
```

---

## 🔗 التبعيات الرئيسية

- **supabase_flutter:** قاعدة البيانات والمصادقة
- **get:** إدارة الحالة والتنقل
- **pdf/printing:** توليد PDF
- **fl_chart:** الرسوم البيانية
- **audioplayers:** الأصوات
- **flutter_svg:** صور SVG


---

## 🗄️ هيكل قاعدة البيانات (Supabase)

### الجداول الرئيسية

| الجدول | الوصف |
|--------|-------|
| `client` | بيانات العملاء |
| `account` | الحسابات/الفروع |
| `phone` | أرقام الهواتف |
| `system` | الأنظمة/الباقات المشتركة |
| `system_type` | أنواع الباقات المتاحة |
| `log` | سجل المعاملات |
| `month_profit` | الأرباح الشهرية |
| `users` | المستخدمين |

### العلاقات
```
account (1) ──── (N) client
client (1) ──── (N) phone
phone (1) ──── (N) system
system (N) ──── (1) system_type
client (1) ──── (N) log
```

---

## 🔐 نظام الصلاحيات

```dart
enum UserRoles { 
  admin,      // 0 - مدير النظام
  manager,    // 1 - مدير الفرع
  assistant   // 2 - مساعد
}
```

### صلاحيات كل دور

| الميزة | Admin | Manager | Assistant |
|--------|-------|---------|-----------|
| عرض العملاء | ✅ | ✅ | ✅ |
| تعديل العملاء | ✅ | ✅ | ❌ |
| إدارة الأرباح | ✅ | ✅ | ❌ |
| إدارة المستخدمين | ✅ | ✅ | ❌ |
| المستحقات | ✅ | ✅ | ✅ |

---

## 📱 الثيمات المتاحة

```dart
enum WelcomeTheme {
  ramadan,  // ثيم رمضان - ألوان خضراء وذهبية
  eid,      // ثيم العيد - ألوان احتفالية
  general,  // ثيم عام - ألوان زرقاء
}
```

### تغيير الثيم
```dart
WelcomeThemeController.to.setTheme(WelcomeTheme.general);
```

---

## 🧪 أفضل الممارسات

### 1. التعامل مع البيانات
```dart
// ✅ صحيح - استخدم null safety
final name = client.name ?? 'غير معروف';

// ❌ خطأ - تجنب force unwrap بدون تحقق
final name = client.name!;
```

### 2. الـ Widgets
```dart
// ✅ صحيح - استخدم const
const SizedBox(height: 20),
const EdgeInsets.all(16),

// ❌ خطأ - بدون const للقيم الثابتة
SizedBox(height: 20),
```

### 3. الألوان مع الشفافية
```dart
// ✅ صحيح (Flutter 3.18+)
color.withValues(alpha: 0.5)

// ⚠️ قديم (deprecated)
color.withOpacity(0.5)
```

### 4. التنقل
```dart
// للانتقال مع إمكانية الرجوع
Get.to(() => NewPage());

// للانتقال مع حذف الصفحة السابقة
Get.off(() => NewPage());

// للانتقال مع حذف كل الصفحات
Get.offAll(() => NewPage());
```

### 5. إظهار الرسائل
```dart
// Snackbar
Get.snackbar(
  'العنوان',
  'الرسالة',
  backgroundColor: Colors.green,
  colorText: Colors.white,
);

// Toast (للرسائل السريعة)
Fluttertoast.showToast(msg: "تم بنجاح");
```

---

## 🔄 دورة حياة البيانات

### تحميل البيانات
```dart
@override
void onReady() async {
  super.onReady();
  isLoading.value = true;
  try {
    data.value = await repository.getAll();
  } catch (e) {
    ErrorHandler.handleError(e, 'fetchData');
  } finally {
    isLoading.value = false;
  }
}
```

### الاستماع للتغييرات (Realtime)
```dart
repository.getRealtimeStream().listen((updatedData) {
  data.value = updatedData;
});
```

---

## 📋 قائمة التحقق قبل الـ Commit

- [ ] لا يوجد `print()` statements
- [ ] استخدام `const` حيث أمكن
- [ ] التعامل مع الأخطاء بشكل صحيح
- [ ] الرسائل بالعربية
- [ ] اتباع نمط التسمية
- [ ] لا يوجد imports غير مستخدمة
- [ ] اختبار على الويب والموبايل
