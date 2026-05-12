# 🚀 ابدأ من هنا - Shorebird Setup

## ✅ ما تم إنجازه

تم تطبيق نظام **Shorebird** الكامل مع **زر تحديث يدوي** للمستخدم.

---

## 📋 الخطوات السريعة

### 1. احصل على Shorebird Token

```bash
shorebird login:ci
```

أو من: https://console.shorebird.dev → Settings → API Keys

انسخ الـ token

---

### 2. أضف Token لـ GitHub Secrets

1. روح: `Settings` → `Secrets and variables` → `Actions`
2. اضغط `New repository secret`
3. Name: `SHOREBIRD_TOKEN`
4. Value: [الـ token اللي نسخته]

---

### 3. أنشئ GitHub Actions Workflow

أنشئ ملف: `.github/workflows/shorebird-release.yml`

انسخ المحتوى من: `SHOREBIRD_WINDOWS_WORKAROUND.md` (القسم: "أنشئ GitHub Actions Workflow")

---

### 4. استخدم Tags للإصدارات

#### للإصدار الأول:
```bash
git tag v0.1.6
git push origin v0.1.6
```

#### للتحديثات الصغيرة:
```bash
git tag patch-001
git push origin patch-001
```

---

## 📱 كيف يعمل؟

### للمستخدم:

1. **يفتح التطبيق**
   - التطبيق يفحص التحديثات تلقائياً

2. **إذا كان هناك تحديث:**
   - يظهر **Dialog** مع زر "تحديث الآن"

3. **يضغط "تحديث الآن":**
   - يحمّل التحديث (1-5 MB فقط)
   - رسالة: "سيطبق عند إعادة التشغيل"

4. **يغلق ويفتح التطبيق:**
   - التحديث يطبّق تلقائياً ✅

---

## 📚 الملفات المرجعية

### الأساسيات:
- `SHOREBIRD_SUMMARY.md` - ملخص شامل
- `SHOREBIRD_COMMANDS.md` - دليل الأوامر
- `SHOREBIRD_WINDOWS_WORKAROUND.md` - حل مشاكل Windows

### للمطورين:
- `lib/services/shorebird_update_service.dart` - API
- `lib/controllers/update_controller.dart` - State
- `lib/components/update_dialog.dart` - UI
- `lib/pages/update_example_page.dart` - مثال كامل

---

## 🎯 الاستخدام في الكود

### الطريقة 1: Dialog تلقائي

```dart
import 'package:get/get.dart';
import 'package:phone_system_app/components/update_dialog.dart';
import 'package:phone_system_app/controllers/update_controller.dart';

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
      builder: (context) => const UpdateDialog(),
    );
  }
}
```

### الطريقة 2: Banner

```dart
import 'package:phone_system_app/components/update_banner.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        const UpdateBanner(), // يظهر تلقائياً
        Expanded(child: YourContent()),
      ],
    ),
  );
}
```

### الطريقة 3: زر عائم

```dart
import 'package:phone_system_app/components/update_banner.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: YourContent(),
    floatingActionButton: const UpdateFloatingButton(),
  );
}
```

---

## ❓ الأسئلة الشائعة

### هل Shorebird له علاقة بـ Supabase؟
**لا** - مستقلان تماماً. لكن يمكنك استخدام Supabase لإرسال إشعارات (اختياري).

### لماذا لا يعمل `shorebird init` على Windows؟
مشكلة معروفة مع Gradle. الحل: استخدم GitHub Actions.

### كم التكلفة؟
**مجاني تماماً!** 5,000 patch installs/month.

### متى أستخدم Patch ومتى أستخدم Release؟
- **Patch**: تعديلات Dart فقط (UI, logic, bug fixes)
- **Release**: تغييرات native (permissions, dependencies, manifest)

---

## 🎉 الخلاصة

### قبل Shorebird:
- ❌ ترسل APK (100 MB) كل مرة
- ❌ العميل يثبّت يدوياً
- ❌ وقت طويل (30+ دقيقة)

### بعد Shorebird:
- ✅ ترسل APK **مرة واحدة فقط**
- ✅ التحديثات تلقائية (1-5 MB)
- ✅ سريع جداً (2-3 دقائق)
- ✅ زر واحد للمستخدم!

---

**الخطوة التالية**: اقرأ `SHOREBIRD_WINDOWS_WORKAROUND.md` وأنشئ GitHub Actions workflow!

**آخر تحديث**: 2026-05-12
