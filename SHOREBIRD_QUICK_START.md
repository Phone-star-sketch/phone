# 🚀 دليل البدء السريع - Shorebird

## ✅ ما تم إنجازه

تم تطبيق نظام تحديثات Shorebird بالكامل في التطبيق:

### الملفات المضافة:
1. ✅ `lib/services/shorebird_update_service.dart` - خدمة التحديثات
2. ✅ `lib/controllers/update_controller.dart` - Controller إدارة الحالة
3. ✅ `lib/components/update_dialog.dart` - Dialog التحديث
4. ✅ `lib/components/update_banner.dart` - Banner وزر عائم
5. ✅ `lib/pages/update_example_page.dart` - مثال كامل
6. ✅ `shorebird.yaml` - إعدادات Shorebird
7. ✅ `pubspec.yaml` - تم إضافة `shorebird_code_push: ^1.1.5`
8. ✅ `lib/main.dart` - تم إضافة UpdateController

---

## 🎯 الخطوات التالية (يجب تنفيذها)

### ⚠️ ملاحظة مهمة للمستخدمين على Windows

إذا واجهت مشاكل مع `shorebird init` على Windows (Gradle timeout)، استخدم **GitHub Actions** بدلاً من ذلك.

اقرأ: `SHOREBIRD_WINDOWS_WORKAROUND.md` للحل الكامل.

---

### الطريقة 1: GitHub Actions (موصى به لـ Windows)

1. احصل على Shorebird Token:
```bash
shorebird login:ci
```
أو من: https://console.shorebird.dev → Settings → API Keys

2. أضف Token لـ GitHub Secrets:
   - Settings → Secrets → Actions → New secret
   - Name: `SHOREBIRD_TOKEN`
   - Value: [your token]

3. أنشئ workflow file (انظر `SHOREBIRD_WINDOWS_WORKAROUND.md`)

4. استخدم tags للإصدارات:
```bash
# Full release
git tag v0.1.6
git push origin v0.1.6

# Patch
git tag patch-001
git push origin patch-001
```

---

### الطريقة 2: محلياً (إذا نجح shorebird init)

### 1️⃣ تثبيت Shorebird CLI

```powershell
# في PowerShell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/shorebirdtech/install/main/install.ps1" -OutFile "install_shorebird.ps1"
.\install_shorebird.ps1

# أضف للـ PATH
$env:Path += ";$env:USERPROFILE\.shorebird\bin"

# أعد تشغيل Terminal
```

### 2️⃣ تسجيل الدخول

```bash
shorebird login
```

### 3️⃣ تهيئة المشروع

```bash
shorebird init
```

هذا سينشئ `app_id` في ملف `shorebird.yaml`

### 4️⃣ إنشاء أول Release

```bash
shorebird release android
```

الملف سيكون في: `build/app/outputs/bundle/release/app-release.aab`

**ملاحظة**: هذا الـ APK ترفعه على GitHub Releases **مرة واحدة فقط**.

---

## 📱 كيفية الاستخدام

### في أي صفحة تريد عرض إشعار التحديث:

#### الطريقة 1: Dialog تلقائي عند فتح الصفحة

```dart
import 'package:get/get.dart';
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const UpdateDialog(),
      );
    }
  }
}
```

#### الطريقة 2: Banner في أعلى الصفحة

```dart
import 'package:phone_system_app/components/update_banner.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        const UpdateBanner(), // ✅ يظهر تلقائياً عند وجود تحديث
        Expanded(child: YourContent()),
      ],
    ),
  );
}
```

#### الطريقة 3: زر عائم

```dart
import 'package:phone_system_app/components/update_banner.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: YourContent(),
    floatingActionButton: const UpdateFloatingButton(), // ✅
  );
}
```

---

## 🔄 سير العمل اليومي

### عند إصلاح Bug أو إضافة Feature:

```bash
# 1. عدّل الكود
# 2. اعمل patch

shorebird patch android

# 3. خلاص! التحديث سيصل للمستخدمين في دقائق
```

**الوقت**: 2-3 دقائق فقط!

### متى تستخدم Release كامل؟

```bash
shorebird release android
```

استخدمه فقط عند:
- تغيير `AndroidManifest.xml`
- إضافة permissions جديدة
- تحديث native dependencies
- إضافة packages في `pubspec.yaml`

---

## 🎯 تجربة المستخدم

### ماذا سيرى المستخدم؟

1. **يفتح التطبيق**
   - التطبيق يفحص التحديثات في الخلفية (صامت)

2. **إذا كان هناك تحديث:**
   - يظهر **Dialog** أو **Banner** أو **زر عائم**
   - رسالة: "تحديث جديد متاح - حجم صغير (1-5 MB)"

3. **يضغط "تحديث الآن":**
   - يبدأ التحميل مع progress bar
   - رسالة: "تم التحميل - سيطبق عند إعادة التشغيل"

4. **يغلق ويفتح التطبيق:**
   - التحديث يطبّق تلقائياً ✅

---

## ❓ الأسئلة الشائعة

### هل Shorebird له علاقة بـ Supabase؟

**لا، مفيش علاقة مباشرة.**

- Shorebird: نظام تحديثات مستقل
- Supabase: قاعدة بيانات

لكن يمكنك استخدام Supabase لـ:
- إرسال إشعارات FCM بوجود تحديث
- تتبع من حمّل التحديث
- التحكم في من يستقبل التحديث

### كم التكلفة؟

**مجاني تماماً!** ✅

- 5,000 patch installs/month
- Unlimited apps
- Unlimited releases

### هل يعمل مع Google Play Store؟

**نعم!** ✅ متوافق 100% مع:
- Google Play Store
- Apple App Store
- التوزيع المباشر (APK)

---

## 📊 المراقبة

### Shorebird Dashboard
زور: https://console.shorebird.dev

شوف:
- كام مستخدم حمّل التحديث
- نسبة النجاح
- Rollback لو حصلت مشكلة

### في الكود

```dart
final updateController = Get.find<UpdateController>();

// رقم الـ patch الحالي
print(updateController.currentPatchNumber.value);

// معلومات التحديث
print(updateController.getUpdateInfo());
```

---

## 🎉 الخلاصة

### قبل Shorebird:
- ❌ ترسل APK (100 MB) على الواتساب
- ❌ العميل يثبّت يدوياً
- ❌ وقت طويل (30+ دقيقة)

### بعد Shorebird:
- ✅ ترسل APK **مرة واحدة فقط**
- ✅ التحديثات تلقائية (1-5 MB)
- ✅ سريع جداً (2-3 دقائق)
- ✅ المستخدم يضغط زر واحد فقط!

---

## 📚 ملفات التوثيق

- `SHOREBIRD_USAGE.md` - دليل الاستخدام الكامل
- `lib/pages/update_example_page.dart` - مثال عملي كامل
- `.kiro/steering/shorebird-setup.md` - دليل الإعداد
- `.kiro/steering/shorebird-implementation.md` - دليل التطبيق

---

**آخر تحديث**: 2026-05-12
**الحالة**: ✅ جاهز للاستخدام
