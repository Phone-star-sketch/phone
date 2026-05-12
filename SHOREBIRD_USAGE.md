# 🚀 دليل استخدام Shorebird للتحديثات التلقائية

## 📋 نظرة عامة

تم تطبيق نظام تحديثات **Shorebird** في التطبيق بحيث:
- ✅ يفحص التحديثات تلقائياً عند فتح التطبيق
- ✅ يعرض **زر تحديث** للمستخدم عند وجود تحديث
- ✅ يسمح للمستخدم بالتحديث يدوياً
- ✅ **مستقل تماماً عن Supabase** (لا علاقة بينهم)

---

## 🎯 الملفات المضافة

### 1. Services
- `lib/services/shorebird_update_service.dart` - خدمة إدارة التحديثات

### 2. Controllers
- `lib/controllers/update_controller.dart` - Controller لإدارة حالة التحديثات

### 3. Components
- `lib/components/update_dialog.dart` - Dialog التحديث
- `lib/components/update_banner.dart` - Banner وزر عائم للتحديث

### 4. Examples
- `lib/pages/update_example_page.dart` - مثال كامل للاستخدام

### 5. Configuration
- `shorebird.yaml` - إعدادات Shorebird
- `pubspec.yaml` - تم إضافة `shorebird_code_push: ^1.1.5`

---

## 🔧 خطوات الإعداد الأولية

### 1. تثبيت Shorebird CLI

```powershell
# Download installer
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/shorebirdtech/install/main/install.ps1" -OutFile "install_shorebird.ps1"

# Run installer
.\install_shorebird.ps1

# Add to PATH
$env:Path += ";$env:USERPROFILE\.shorebird\bin"

# Restart terminal
```

### 2. تسجيل الدخول

```bash
shorebird login
```

### 3. تهيئة المشروع

```bash
# في مجلد المشروع
shorebird init
```

هذا سينشئ `app_id` في ملف `shorebird.yaml`

### 4. إنشاء أول Release

```bash
# Build first release
shorebird release android

# الملف سيكون في:
# build/app/outputs/bundle/release/app-release.aab
```

**ملاحظة**: هذا الـ APK ترفعه على GitHub Releases **مرة واحدة فقط**.

---

## 📱 كيفية الاستخدام في التطبيق

### الطريقة 1: عرض Dialog تلقائياً عند فتح الصفحة

```dart
import 'package:phone_system_app/components/update_dialog.dart';
import 'package:phone_system_app/controllers/update_controller.dart';

class MyPage extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    final updateController = Get.find<UpdateController>();
    final hasUpdate = await updateController.checkForUpdate();
    
    if (hasUpdate && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const UpdateDialog(),
      );
    }
  }
}
```

### الطريقة 2: إضافة Banner في أعلى الصفحة

```dart
import 'package:phone_system_app/components/update_banner.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // ✅ البانر يظهر تلقائياً عند وجود تحديث
        const UpdateBanner(),
        
        Expanded(
          child: YourPageContent(),
        ),
      ],
    ),
  );
}
```

### الطريقة 3: إضافة زر عائم

```dart
import 'package:phone_system_app/components/update_banner.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: YourPageContent(),
    
    // ✅ زر عائم يظهر عند وجود تحديث
    floatingActionButton: const UpdateFloatingButton(),
  );
}
```

### الطريقة 4: زر يدوي للتحقق من التحديثات

```dart
import 'package:phone_system_app/controllers/update_controller.dart';

ElevatedButton(
  onPressed: () async {
    final updateController = Get.find<UpdateController>();
    final hasUpdate = await updateController.checkForUpdate();
    
    if (hasUpdate) {
      // عرض dialog
      showDialog(
        context: context,
        builder: (context) => const UpdateDialog(),
      );
    } else {
      Get.snackbar('لا توجد تحديثات', 'التطبيق محدث');
    }
  },
  child: const Text('التحقق من التحديثات'),
)
```

---

## 🔄 سير العمل اليومي

### عند إصلاح Bug أو إضافة Feature:

```bash
# 1. عدّل الكود في Dart
# 2. اعمل patch

shorebird patch android

# 3. خلاص! التحديث سيصل للمستخدمين
```

**الوقت**: 2-3 دقائق فقط!

### متى تستخدم APK كامل؟

استخدم `shorebird release android` (APK كامل) فقط عند:
- تغيير في `AndroidManifest.xml`
- إضافة/تعديل permissions
- تحديث native dependencies
- إضافة packages جديدة في `pubspec.yaml`

---

## 🎯 تجربة المستخدم

### السيناريو الكامل:

1. **المستخدم يفتح التطبيق**
   - التطبيق يفحص التحديثات في الخلفية (صامت)

2. **إذا كان هناك تحديث:**
   - يظهر **Banner** في أعلى الشاشة
   - أو يظهر **Dialog** تلقائياً
   - أو يظهر **زر عائم**

3. **المستخدم يضغط "تحديث الآن":**
   - يبدأ التحميل (1-5 MB فقط)
   - يظهر progress bar
   - رسالة نجاح: "سيتم تطبيق التحديث عند إعادة التشغيل"

4. **المستخدم يغلق ويفتح التطبيق:**
   - التحديث يطبّق تلقائياً ✅
   - التطبيق يعمل بأحدث إصدار!

---

## 🔗 هل Shorebird له علاقة بـ Supabase؟

**لا، مفيش علاقة مباشرة.**

لكن يمكنك استخدام Supabase لـ:

### 1. إرسال إشعارات بوجود تحديث

```dart
// في Supabase Edge Function
import { createClient } from '@supabase/supabase-js'

Deno.serve(async (req) => {
  const supabase = createClient(...)
  
  // إرسال إشعار FCM لكل المستخدمين
  const { data: tokens } = await supabase
    .from('fcm_tokens')
    .select('token')
  
  // إرسال إشعار: "تحديث جديد متاح!"
  // ...
})
```

### 2. تتبع من حمّل التحديث

```dart
// بعد تحميل التحديث
await supabase.from('update_logs').insert({
  'user_id': userId,
  'patch_number': patchNumber,
  'downloaded_at': DateTime.now(),
});
```

### 3. التحكم في من يستقبل التحديث

```dart
// فحص إذا كان المستخدم مسموح له بالتحديث
final { data } = await supabase
  .from('users')
  .select('allow_updates')
  .eq('id', userId)
  .single();

if (data.allow_updates) {
  // عرض dialog التحديث
}
```

---

## 📊 المراقبة

### Shorebird Dashboard
- زور: https://console.shorebird.dev
- شوف كام مستخدم حمّل التحديث
- شوف نسبة النجاح
- Rollback لو حصلت مشكلة

### في التطبيق

```dart
final updateController = Get.find<UpdateController>();

// رقم الـ patch الحالي
print(updateController.currentPatchNumber.value);

// معلومات التحديث
print(updateController.getUpdateInfo());
```

---

## 💰 التكلفة

### Free Tier (مجاني):
- 5,000 patch installs/month
- Unlimited apps
- Unlimited releases

**لحالتك**: مجاني تماماً! ✅

---

## 🎉 الخلاصة

### قبل Shorebird:
- ترسل APK (100 MB) على الواتساب كل مرة
- العميل يثبّت يدوياً
- وقت طويل وجهد كبير

### بعد Shorebird:
- ترسل APK **مرة واحدة فقط** (أول مرة)
- كل التحديثات بعد كده **تلقائية**
- العميل يضغط زر واحد فقط!
- حجم صغير (1-5 MB)
- سريع جداً (دقائق)

---

## 📚 مصادر إضافية

- [Shorebird Documentation](https://docs.shorebird.dev)
- [Update Strategies](https://docs.shorebird.dev/code-push/update-strategies/)
- [FreeCodeCamp Tutorial](https://freecodecamp.org/news/how-to-push-silent-updates-in-flutter-using-shorebird)

---

**آخر تحديث**: 2026-05-12
