# 📋 دليل سير العمل - Shorebird Updates

## 🎯 نظرة عامة

هناك **نوعين** من التحديثات:
1. **Patch** (تحديث صغير) - للتعديلات البسيطة في الكود
2. **Release** (إصدار كامل) - للتغييرات الكبيرة

---

## 📊 متى تستخدم أيهما؟

### ✅ استخدم Patch (تحديث صغير) لـ:
- تعديل UI (ألوان، نصوص، layouts)
- إصلاح bugs في الكود Dart
- إضافة features بسيطة (Dart فقط)
- تحديث logic في الكود
- **حجم التحديث**: 1-5 MB
- **الوقت**: 2-3 دقائق
- **المستخدم**: يحمّل تلقائياً

### ❌ استخدم Release (إصدار كامل) لـ:
- تغيير في `AndroidManifest.xml`
- إضافة/تعديل permissions
- إضافة packages جديدة في `pubspec.yaml`
- تحديث native dependencies
- إضافة native code (Java/Kotlin)
- **حجم التحديث**: 50-100 MB
- **الوقت**: 10-15 دقيقة
- **المستخدم**: يثبّت يدوياً

---

## 🚀 سير العمل الكامل

### السيناريو 1: تعديل بسيط (Patch)

#### مثال: تغيير لون زرار

```dart
// في lib/views/pages/login_page.dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green, // ✅ غيرت من blue لـ green
  ),
  child: Text('تسجيل الدخول'),
)
```

#### الخطوات:

```bash
# 1. عدّل الكود
# (عدلت اللون في الملف)

# 2. Commit التعديلات
git add .
git commit -m "Fix: تغيير لون زر تسجيل الدخول"
git push

# 3. أنشئ patch tag
git tag patch-001
git push origin patch-001

# 4. خلاص! GitHub Actions هيعمل كل حاجة تلقائياً
```

#### ماذا سيحدث؟
1. ✅ GitHub Actions يشتغل تلقائياً
2. ✅ يبني الـ patch (2-3 دقائق)
3. ✅ يرفعه على Shorebird
4. ✅ التطبيق عند المستخدم يحمّل التحديث تلقائياً
5. ✅ المستخدم يفتح التطبيق → يظهر dialog "تحديث متاح"
6. ✅ يضغط "تحديث الآن" → يحمّل (2 MB)
7. ✅ يغلق ويفتح التطبيق → التحديث يطبّق ✅

---

### السيناريو 2: إصدار كامل (Release)

#### مثال: إضافة permission جديدة

```xml
<!-- في android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
```

#### الخطوات:

```bash
# 1. عدّل الكود
# (أضفت permission في AndroidManifest.xml)

# 2. حدّث version في pubspec.yaml
# version: 0.1.7+7  (زود الرقم)

# 3. Commit التعديلات
git add .
git commit -m "Feature: إضافة دعم الكاميرا"
git push

# 4. أنشئ release tag
git tag v0.1.7
git push origin v0.1.7

# 5. خلاص! GitHub Actions هيعمل كل حاجة تلقائياً
```

#### ماذا سيحدث؟
1. ✅ GitHub Actions يشتغل تلقائياً
2. ✅ يبني APK كامل (10-15 دقيقة)
3. ✅ يرفعه على GitHub Releases
4. ✅ تنزّل APK من Releases
5. ✅ ترسله للعميل على الواتساب
6. ✅ العميل يثبّته يدوياً

---

## 📝 أمثلة عملية

### مثال 1: إصلاح bug في حساب المبلغ

```dart
// قبل (❌ خطأ)
double total = price + tax;

// بعد (✅ صح)
double total = (price * quantity) + tax;
```

**النوع**: Patch ✅

**الخطوات**:
```bash
git add lib/controllers/account_details_controller.dart
git commit -m "Fix: إصلاح حساب المبلغ الإجمالي"
git push
git tag patch-002
git push origin patch-002
```

---

### مثال 2: تحديث نص رسالة

```dart
// قبل
Text('مرحباً بك')

// بعد
Text('أهلاً وسهلاً بك في التطبيق')
```

**النوع**: Patch ✅

**الخطوات**:
```bash
git add lib/pages/main_page.dart
git commit -m "Update: تحديث رسالة الترحيب"
git push
git tag patch-003
git push origin patch-003
```

---

### مثال 3: إضافة package جديد

```yaml
# في pubspec.yaml
dependencies:
  image_picker: ^1.0.0  # ✅ package جديد
```

**النوع**: Release ❌ (لازم APK كامل)

**الخطوات**:
```bash
# 1. حدّث version
# version: 0.1.8+8

git add pubspec.yaml
git commit -m "Feature: إضافة image picker"
git push
git tag v0.1.8
git push origin v0.1.8
```

---

## 🔄 سير العمل اليومي

### كل يوم:

```bash
# 1. صبح - تشتغل على التطبيق
# عدلت 5 ملفات Dart

# 2. ظهر - تعمل commit
git add .
git commit -m "Fix: إصلاحات متعددة"
git push

# 3. عايز ترسل التحديث للعميل؟
git tag patch-004
git push origin patch-004

# 4. خلاص! العميل هيستقبل التحديث تلقائياً
```

### كل أسبوع:

```bash
# لو عملت تغييرات كبيرة (permissions, packages, etc.)
# اعمل release كامل

git tag v0.1.9
git push origin v0.1.9

# نزّل APK من GitHub Releases
# ارسله للعميل
```

---

## 📊 جدول مقارنة سريع

| التعديل | النوع | الأمر | الوقت | حجم التحديث |
|---------|-------|-------|-------|-------------|
| تغيير لون | Patch | `git tag patch-001` | 2 دقيقة | 2 MB |
| إصلاح bug | Patch | `git tag patch-002` | 2 دقيقة | 2 MB |
| تحديث نص | Patch | `git tag patch-003` | 2 دقيقة | 2 MB |
| إضافة permission | Release | `git tag v0.1.7` | 15 دقيقة | 80 MB |
| إضافة package | Release | `git tag v0.1.8` | 15 دقيقة | 80 MB |

---

## 🎯 نصائح مهمة

### ✅ افعل:
- استخدم Patch للتعديلات اليومية
- اعمل commit بعد كل تعديل مهم
- استخدم أسماء واضحة للـ tags (patch-001, patch-002, etc.)
- اعمل Release كل أسبوع أو أسبوعين

### ❌ لا تفعل:
- لا تستخدم Patch للتغييرات الكبيرة
- لا تنسى تحديث version في pubspec.yaml للـ releases
- لا ترسل APK كامل للتعديلات البسيطة

---

## 🔍 كيف تعرف أي نوع تستخدم؟

### اسأل نفسك:

**هل عدلت أي من هذه الملفات؟**
- `AndroidManifest.xml` → Release
- `pubspec.yaml` (أضفت package) → Release
- `build.gradle` → Release
- Native code (Java/Kotlin) → Release

**إذا الإجابة لا:**
- عدلت Dart فقط → Patch ✅

---

## 📱 تجربة المستخدم

### مع Patch:
1. المستخدم يفتح التطبيق
2. يظهر dialog: "تحديث متاح (2 MB)"
3. يضغط "تحديث الآن"
4. يحمّل في 10 ثواني
5. يغلق ويفتح التطبيق
6. التحديث يطبّق ✅

### مع Release:
1. ترسل APK على الواتساب
2. المستخدم ينزّل (80 MB)
3. يثبّت يدوياً
4. يفتح التطبيق ✅

---

## 🎉 الخلاصة

### للتعديلات اليومية (90% من الوقت):
```bash
git add .
git commit -m "وصف التعديل"
git push
git tag patch-XXX
git push origin patch-XXX
```

### للتحديثات الكبيرة (10% من الوقت):
```bash
# حدّث version في pubspec.yaml أولاً
git add .
git commit -m "وصف التعديل"
git push
git tag v0.1.X
git push origin v0.1.X
```

---

**آخر تحديث**: 2026-05-12  
**الحالة**: ✅ جاهز للاستخدام
