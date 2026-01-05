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

## 🔌 إعدادات Supabase و MCP

### ⚠️ ملاحظة مهمة: تعارض Project References
```
MCP Server يستخدم: yqlzxvzcjvzxneftqggn
الكود يستخدم: kmtimujsqhpltmzrycxw

يجب توحيد الـ project reference!
```

### معلومات الاتصال
```dart
// في lib/services/backend/supabase_backend_services.dart
url: 'https://kmtimujsqhpltmzrycxw.supabase.co'
anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```

### MCP Server Configuration
```json
// في C:/Users/Arabtech/.kiro/settings/mcp.json
{
  "mcpServers": {
    "Supabase": {
      "command": "npx",
      "args": [
        "-y",
        "@supabase/mcp-server-supabase@latest",
        "--read-only",
        "--project-ref",
        "yqlzxvzcjvzxneftqggn"
      ],
      "env": {
        "SUPABASE_ACCESS_TOKEN": "sbp_..."
      }
    }
  }
}
```

### خيارات التهيئة
```dart
authOptions: FlutterAuthClientOptions(
  authFlowType: AuthFlowType.pkce,  // PKCE للأمان
)

realtimeClientOptions: RealtimeClientOptions(
  logLevel: RealtimeLogLevel.info,  // للتحديثات الفورية
)

postgrestOptions: PostgrestClientOptions(
  schema: 'public',  // Schema الافتراضي
)
```

### Timeout
```dart
.timeout(
  const Duration(seconds: 30),
  onTimeout: () {
    throw Exception('Connection to Supabase timed out...');
  },
)
```

---

## 🗄️ هيكل قاعدة البيانات (Supabase)

### الجداول الرئيسية

| الجدول | الوصف | الحقول الرئيسية |
|--------|-------|-----------------|
| `client` | بيانات العملاء | id, name, national_id, address, account_id, total_cash, expire_date, discount_percentage, discount_end_date, notes, totalServicesPrice |
| `account` | الحسابات/الفروع | id, name, day (يوم التحصيل) |
| `phone` | أرقام الهواتف | id, phone_number, client_id, for_sale, price |
| `system` | الأنظمة/الباقات المشتركة | id, name, start_date, end_date, phone_id, type_id |
| `system_type` | أنواع الباقات المتاحة | id, name, description, price, category (0: mainPackage, 1: internetPackage, 2: mobileInternet), image |
| `log` | سجل المعاملات | id, price, year, month, paid, reminder, system_type, phone_id, client_id, account_id, creator, transaction_type |
| `month_profit` | الأرباح الشهرية | id, year, month, income, collected, expected, reminder, discount, account_id |
| `users` | المستخدمين | id, uid, name, role (0: admin, 1: manager, 2: assistant), secpass |
| `dues` | المستحقات | id, name, phone, amount |
| `images` | الصور | id, image_url |
| `info` | معلومات موحدة | id, name, national_id, address, phone_numbers[], system_names[], expire_date |

### تفاصيل الجداول

#### جدول `client`
```dart
- id: number (Primary Key)
- created_at: DateTime
- name: String
- national_id: String (الرقم القومي)
- address: String
- account_id: number (FK → account)
- total_cash: double (إجمالي المستحقات)
- expire_date: DateTime? (تاريخ انتهاء الاشتراك)
- discount_percentage: double? (نسبة الخصم)
- discount_end_date: DateTime? (تاريخ انتهاء الخصم)
- totalServicesPrice: double? (إجمالي سعر الخدمات)
- notes: String? (ملاحظات)

// Relations
- phone[] (One-to-Many)
- log[] (One-to-Many)
```

#### جدول `phone`
```dart
- id: number (Primary Key)
- created_at: DateTime
- phone_number: String
- client_id: number (FK → client)
- for_sale: bool (هل الرقم للبيع)
- price: double (سعر الرقم)

// Relations
- system[] (One-to-Many)
```

#### جدول `system`
```dart
- id: number (Primary Key)
- created_at: DateTime
- name: String
- start_date: DateTime
- end_date: DateTime
- phone_id: number (FK → phone)
- type_id: number (FK → system_type)

// Relations
- system_type (Many-to-One)
```

#### جدول `system_type`
```dart
- id: number (Primary Key)
- created_at: DateTime
- name: String
- description: String
- price: double
- category: int (0: باقة رئيسية, 1: باقة إنترنت, 2: إنترنت موبايل)
- image: String?
```

#### جدول `log`
```dart
- id: number (Primary Key)
- created_at: DateTime
- price: double
- year: int
- month: int
- paid: double (المدفوع)
- reminder: double (المتبقي)
- system_type: String
- phone_id: number? (FK → phone)
- client_id: number? (FK → client)
- account_id: number (FK → account)
- creator: number (FK → users)
- transaction_type: int (0: moneyAdded, 1: moneyDeducted, 2: transactionDone, 3: deposit, 4: income, 5: expense, 6: transfer, 7: payment, 8: addition, 9: debt)
```

#### جدول `month_profit`
```dart
- id: number (Primary Key)
- created_at: DateTime
- year: int
- month: int
- income: double (الدخل)
- collected: double (المحصل)
- expected: double (المتوقع)
- reminder: double (المتبقي)
- discount: double (الخصومات)
- account_id: number (FK → account)
```

#### جدول `users`
```dart
- id: number (Primary Key)
- created_at: DateTime
- uid: String (Supabase Auth UID)
- name: String
- role: int (0: admin, 1: manager, 2: assistant)
- secpass: int? (كلمة سر ثانوية)
```

#### جدول `dues` (المستحقات)
```dart
- id: number (Primary Key)
- created_at: DateTime
- name: String (اسم الشخص)
- phone: String (رقم الهاتف)
- amount: double (المبلغ المستحق)
```

#### جدول `images`
```dart
- id: number (Primary Key)
- created_at: DateTime
- image_url: String (رابط الصورة)
```

#### جدول `info` (View أو جدول موحد)
```dart
- id: number (Primary Key)
- name: String
- national_id: String
- address: String
- phone_numbers: String[] (مصفوفة أرقام الهواتف)
- system_names: String[] (مصفوفة أسماء الأنظمة)
- expire_date: DateTime
```

### العلاقات (Relationships)
```
account (1) ──── (N) client
              └─ (N) month_profit

client (1) ──── (N) phone
           └─── (N) log

phone (1) ──── (N) system
          └─── (N) log

system (N) ──── (1) system_type

users (1) ──── (N) log (creator)

account (1) ──── (N) log
```

### Database Functions (الدوال المتاحة)
```sql
-- حذف مستخدم من Auth
delete_user(userid: string)

-- حذف مستخدم بالكامل (Auth + جدول users)
delete_user_complete(user_id: string)

-- ترحيل البيانات إلى جدول info
migrate_to_info()
```

### ملاحظات مهمة
- جميع الجداول تستخدم `id: number` (Auto-increment) وليس UUID
- جميع الجداول تحتوي على `created_at: DateTime`
- العلاقات تستخدم Foreign Keys
- الـ Realtime متاح على جميع الجداول
- Schema المستخدم: `public`
- جدول `info` يبدو أنه View أو جدول موحد لعرض البيانات
- جدول `dues` للمستحقات الخارجية
- جدول `images` لتخزين روابط الصور

### الأنواع والـ Enums

#### TransactionType (أنواع المعاملات)
```dart
enum TransactionType {
  moneyAdded,        // 0 - تم استلام نقدية (أخضر)
  moneyDeducted,     // 1 - تمت حذف نقدية (أزرق)
  transactionDone,   // 2 - تم دفع حساب الخدمات (أزرق فاتح)
  deposit,           // 3 - إيداع
  income,            // 4 - دخل
  expense,           // 5 - مصروف
  transfer,          // 6 - تحويل
  payment,           // 7 - دفع
  addition,          // 8 - إضافة
  debt,              // 9 - دين (شراء هاتف)
}
```

#### SystemCategory (فئات الباقات)
```dart
enum SystemCategory {
  mainPackage,       // 0 - باقة رئيسية (Flex)
  internetPackage,   // 1 - باقة إنترنت (DSL)
  mobileInternet,    // 2 - إنترنت موبايل (Vodafone)
}
```

#### UserRoles (أدوار المستخدمين)
```dart
enum UserRoles {
  admin,      // 0 - مدير النظام
  manager,    // 1 - مدير الفرع
  assistant   // 2 - مساعد
}
```

### استعلامات شائعة

#### الحصول على عميل مع كل بياناته
```dart
final client = await Supabase.instance.client
  .from('client')
  .select('*, phone(*, system(*, system_type(*))), log(*)')
  .eq('id', clientId)
  .single();
```

#### الحصول على الأرباح الشهرية لحساب معين
```dart
final profits = await Supabase.instance.client
  .from('month_profit')
  .select('*')
  .eq('account_id', accountId)
  .order('year', ascending: false)
  .order('month', ascending: false);
```

#### البحث عن عميل برقم الهاتف
```dart
final client = await Supabase.instance.client
  .from('client')
  .select('*, phone!inner(*)')
  .eq('phone.phone_number', phoneNumber)
  .single();
```

---

## 🔐 نظام الصلاحيات والمصادقة

### الأدوار المتاحة
```dart
enum UserRoles { 
  admin,      // 0 - مدير النظام
  manager,    // 1 - مدير الفرع
  assistant   // 2 - مساعد
}
```

### تسجيل الدخول
```dart
// في lib/services/backend/auth.dart
await SupabaseAuthentication().signIn(username, password);

// يتم التحقق من:
// 1. بيانات الاعتماد (email/password)
// 2. وجود بيانات المستخدم في الجدول
// 3. وجود secpass (كلمة سر ثانوية)
```

### الجلسة الحالية
```dart
// الوصول للجلسة
SupabaseAuthentication.userSession.value

// الوصول للمستخدم الحالي
SupabaseAuthentication.myUser

// الوصول لجميع المستخدمين
SupabaseAuthentication.allUser
```

### تسجيل الخروج
```dart
await SupabaseAuthentication().signOut();
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

### 6. التعامل مع المصادقة
```dart
// التحقق من تسجيل الدخول
if (SupabaseAuthentication.userSession.value.user.id.isNotEmpty) {
  // المستخدم مسجل دخول
}

// التحقق من الصلاحيات
if (SupabaseAuthentication.myUser?.role == UserRoles.admin.index) {
  // صلاحيات المدير
}
```

---

## 🔧 مشاكل شائعة وحلولها

### 1. مشاكل الاتصال بـ Supabase
```dart
// المشكلة: Connection timeout
// الحل: تحقق من الإنترنت والـ URL

// المشكلة: Auth error
// الحل: تحقق من صحة البيانات ووجود secpass
```

### 2. مشاكل الـ Imports
```dart
// ⚠️ تحذير: Unused imports
// احذف الـ imports غير المستخدمة

// ❌ خطأ
import 'package:phone_system_app/repositories/client/client_repository.dart';

// ✅ صحيح - استخدم فقط ما تحتاجه
import 'package:phone_system_app/repositories/client/supabase_client_repository.dart';
```

### 3. استخدام print()
```dart
// ❌ خطأ - في الإنتاج
print('Debug message');

// ✅ صحيح
import 'dart:developer' as developer;
developer.log('Debug message', name: 'MyApp');
```

### 4. Null Safety
```dart
// ❌ خطأ - force unwrap بدون تحقق
final name = client.name!;

// ✅ صحيح
final name = client.name ?? 'غير معروف';

// أو
if (client.name != null) {
  final name = client.name!;
}
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


---

## 🔧 مشاكل شائعة وحلولها

### 1. مشاكل الاتصال بـ Supabase
```dart
// المشكلة: Connection timeout
// الحل: تحقق من الإنترنت والـ URL

// المشكلة: Auth error
// الحل: تحقق من صحة البيانات ووجود secpass
```

### 2. مشاكل الـ Imports
```dart
// ⚠️ تحذير: Unused imports
// احذف الـ imports غير المستخدمة

// ❌ خطأ
import 'package:phone_system_app/repositories/client/client_repository.dart';

// ✅ صحيح - استخدم فقط ما تحتاجه
import 'package:phone_system_app/repositories/client/supabase_client_repository.dart';
```

### 3. استخدام print()
```dart
// ❌ خطأ - في الإنتاج
print('Debug message');

// ✅ صحيح
import 'dart:developer' as developer;
developer.log('Debug message', name: 'MyApp');
```

### 4. Null Safety
```dart
// ❌ خطأ - force unwrap بدون تحقق
final name = client.name!;

// ✅ صحيح
final name = client.name ?? 'غير معروف';

// أو
if (client.name != null) {
  final name = client.name!;
}
```

---

## 🛠️ أدوات التطوير

### MCP Tools المتاحة
عند استخدام Kiro، يمكنك الوصول لأدوات Supabase MCP:
- `mcp_Supabase_list_tables` - عرض الجداول
- `mcp_Supabase_execute_sql` - تنفيذ SQL
- `mcp_Supabase_apply_migration` - تطبيق Migration
- `mcp_Supabase_get_logs` - عرض السجلات
- `mcp_Supabase_get_advisors` - فحص الأمان والأداء

### الوصول للـ Backend
```dart
// Singleton pattern
BackendServices.instance.clientRepository.getAll();
BackendServices.instance.supabaseAuthentication.signIn(...);
```

### Realtime Updates
```dart
// الاستماع للتغييرات
Supabase.instance.client
  .from('client')
  .stream(primaryKey: ['id'])
  .listen((data) {
    // تحديث البيانات
  });
```

---

## 📚 مراجع مفيدة

- **Supabase Docs:** https://supabase.com/docs
- **GetX Docs:** https://pub.dev/packages/get
- **Flutter Docs:** https://flutter.dev/docs
- **Cairo Font:** https://fonts.google.com/specimen/Cairo

---

## 🎯 نصائح للتطوير

1. **ابدأ بالـ Model** - حدد البيانات أولاً
2. **ثم الـ Repository** - حدد كيفية الوصول للبيانات
3. **ثم الـ Controller** - أضف المنطق
4. **أخيراً الـ View** - صمم الواجهة

5. **استخدم MCP Tools** - للتحقق من قاعدة البيانات
6. **اختبر على الويب والموبايل** - دائماً
7. **راجع الـ Advisors** - للأمان والأداء

---

## ✅ قائمة التحقق المحدثة قبل الـ Commit

- [ ] لا يوجد `print()` statements (استخدم `developer.log()`)
- [ ] استخدام `const` حيث أمكن
- [ ] التعامل مع الأخطاء بشكل صحيح
- [ ] الرسائل بالعربية
- [ ] اتباع نمط التسمية
- [ ] لا يوجد imports غير مستخدمة
- [ ] اختبار على الويب والموبايل
- [ ] استخدام `withValues()` بدلاً من `withOpacity()`
- [ ] التحقق من null safety
- [ ] استخدام `rethrow` بدلاً من `throw e`


---

## 📊 إحصائيات قاعدة البيانات (حالية)

### نظرة عامة على البيانات

#### الحسابات والعملاء
- **عدد الحسابات (Accounts):** 2
  - شركة مواهب حسن (يوم التحصيل: 7)
  - شركة محمد السيد (يوم التحصيل: 11)
- **عدد العملاء (Clients):** 440 عميل
- **عدد أرقام الهواتف:** 441 رقم
  - أرقام للبيع: 1 رقم (سعر: 65 جنيه)

#### الأنظمة والباقات
- **عدد الأنظمة النشطة:** 459 نظام
- **عدد أنواع الباقات:** 22 نوع مقسمة كالتالي:
  - **باقات رئيسية (Flex):** 14 باقة (0 - 198 جنيه)
  - **باقات إنترنت (DSL):** 16 باقة (57 - 925 جنيه)
  - **إنترنت موبايل:** 9 باقات (2 - 85 جنيه)

#### أمثلة على الباقات الشائعة
```
فليكس 45: 58 جنيه (900 فليكس)
فليكس 52: 73 جنيه (1400 فليكس)
فليكس 60: 79 جنيه (2000 فليكس)
فليكس 65: 85 جنيه (2500 فليكس)
فليكس 70 الجديد: 97 جنيه (3000 فليكس)
باقة نت 18000 ميجا: 338 جنيه
```

#### السجلات المالية
- **عدد السجلات (Logs):** 13,599 سجل
- **إجمالي المبالغ:** 1,483,221 جنيه
- **إجمالي المدفوع:** 15,287 جنيه
- **إجمالي المتبقي:** 759,803 جنيه

#### توزيع أنواع المعاملات
- **استلام نقدية (moneyAdded):** 6,115 معاملة
- **حذف نقدية (moneyDeducted):** 544 معاملة
- **دفع حساب (transactionDone):** 6,940 معاملة

#### الأرباح الشهرية
- **عدد السجلات:** 8 أشهر
- **إجمالي الدخل:** 251,575 جنيه
- **إجمالي المحصل:** 3,259 جنيه
- **إجمالي المتبقي:** 277,771 جنيه

#### آخر الأرباح الشهرية
```
فبراير 2025: دخل 60,000 | محصل 1,510 | متبقي 47,309
يناير 2025: دخل 71,652 | محصل 651 | متبقي 50,402
ديسمبر 2024: دخل 39,618 | محصل 1,098 | متبقي 53,042
```

#### المستخدمين
- **عدد المستخدمين:** 4 مستخدمين
  - **Managers (مدراء):** 2 (كابتن/ إسلام النني، mohamed)
  - **Assistants (مساعدين):** 2 (المساعد، ahmed)
  - **لا يوجد Admin حالياً**

#### المستحقات الخارجية (Dues)
- **عدد المستحقات:** 3 مستحقات
- **إجمالي المبلغ:** 4,085 جنيه
  - احمد جميل السلطيسي: 560 جنيه
  - محمد سامي صدقه: 3,300 جنيه
  - مازن: 225 جنيه

#### جدول Info (معلومات موحدة)
- **عدد السجلات:** 484 سجل
- يحتوي على بيانات موحدة للعملاء مع مصفوفات الهواتف والأنظمة

#### الصور
- **عدد الصور:** 0 (الجدول فارغ حالياً)

---

## 🔍 استعلامات مفيدة للتحليل

### الحصول على العملاء مع أنظمتهم النشطة
```sql
SELECT 
  c.name as client_name,
  p.phone_number,
  s.name as system_name,
  st.name as system_type_name,
  st.price,
  s.end_date
FROM client c
JOIN phone p ON p.client_id = c.id
JOIN system s ON s.phone_id = p.id
JOIN system_type st ON st.id = s.type_id
WHERE s.end_date > CURRENT_DATE
ORDER BY s.end_date;
```

### إحصائيات الباقات حسب الفئة
```sql
SELECT 
  category,
  COUNT(*) as count,
  MIN(price) as min_price,
  MAX(price) as max_price,
  AVG(price) as avg_price
FROM system_type
GROUP BY category
ORDER BY category;
```

### المعاملات الشهرية
```sql
SELECT 
  year,
  month,
  COUNT(*) as transactions,
  SUM(price) as total_amount,
  SUM(paid) as total_paid
FROM log
GROUP BY year, month
ORDER BY year DESC, month DESC;
```

### العملاء مع أعلى مستحقات
```sql
SELECT 
  name,
  total_cash,
  expire_date
FROM client
WHERE total_cash > 0
ORDER BY total_cash DESC
LIMIT 10;
```


---

## 🔥 Hot Reload والتطوير على الموبايل

### USB Debugging (الطريقة الموصى بها)

1. **تفعيل USB Debugging:**
   - Settings → About Phone → اضغط Build Number 7 مرات
   - Developer Options → فعّل USB Debugging

2. **التشغيل:**
```bash
flutter devices  # تحقق من الأجهزة المتصلة
flutter run      # شغل التطبيق
```

3. **Hot Reload:**
   - اضغط `r` للـ Hot Reload (سريع)
   - اضغط `R` للـ Hot Restart (إعادة تشغيل)
   - اضغط `q` للخروج

### Wireless Debugging (بدون كابل)

```bash
# المرة الأولى (بالكابل)
adb tcpip 5555

# اعرف IP الموبايل من Settings → About → Status
adb connect 192.168.1.100:5555

# افصل الكابل وشغل
flutter run
```

### ما يشتغل مع Hot Reload
- ✅ تغيير UI والألوان
- ✅ تعديل النصوص العربية
- ✅ إضافة Widgets
- ✅ تعديل GetX Controllers

### ما يحتاج Hot Restart (R)
- 🔄 تغيير State الأولي
- 🔄 تعديل main()
- 🔄 تغيير Enums

### ما يحتاج إعادة تشغيل كاملة
- 🔴 تعديل pubspec.yaml
- 🔴 إضافة Assets
- 🔴 تغيير Native Code

### حل المشاكل
```bash
# الموبايل مش ظاهر
adb kill-server
adb start-server
adb devices

# Hot Reload مش شغال
# اضغط R للـ Hot Restart
```
