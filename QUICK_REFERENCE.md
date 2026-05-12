# 🚀 مرجع سريع - Shorebird

## ✅ الحالة الحالية
**جاهز للاستخدام بالكامل** - لا توجد أخطاء

---

## 📋 الخطوات السريعة

### 1️⃣ احصل على Token
```bash
shorebird login:ci
```
أو من: https://console.shorebird.dev

### 2️⃣ أضف لـ GitHub Secrets
- Name: `SHOREBIRD_TOKEN`
- Value: [your token]

### 3️⃣ أنشئ Workflow
انسخ من: `SHOREBIRD_WINDOWS_WORKAROUND.md`

### 4️⃣ ارفع Release
```bash
# أول مرة
git tag v0.1.6
git push origin v0.1.6

# تحديثات صغيرة
git tag patch-001
git push origin patch-001
```

---

## 💻 استخدام في الكود

### Dialog تلقائي (موصى به)
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

### Banner
```dart
import 'package:phone_system_app/components/update_banner.dart';

Column(
  children: [
    const UpdateBanner(),
    Expanded(child: YourContent()),
  ],
)
```

### زر عائم
```dart
import 'package:phone_system_app/components/update_banner.dart';

Scaffold(
  floatingActionButton: const UpdateFloatingButton(),
)
```

---

## 📚 الملفات المهمة

### ابدأ من هنا:
- `CURRENT_STATUS.md` - الحالة الحالية
- `START_HERE.md` - دليل البداية
- `SHOREBIRD_WINDOWS_WORKAROUND.md` - حل Windows

### أمثلة:
- `lib/pages/update_example_page.dart` - مثال كامل

---

## ❓ أسئلة شائعة

**Q: هل له علاقة بـ Supabase؟**  
A: لا - مستقلان تماماً

**Q: كم التكلفة؟**  
A: مجاني (5000 installs/month)

**Q: متى Patch ومتى Release؟**  
A: Patch للكود Dart فقط، Release للـ native changes

---

**الحالة**: ✅ جاهز  
**آخر تحديث**: 2026-05-12
