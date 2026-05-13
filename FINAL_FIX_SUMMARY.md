# الحل النهائي لمشكلة Shorebird على GitHub Actions

## 📋 المشكلة الحالية
```
You must be logged in to run this command.
```

**السبب:** مفيش `SHOREBIRD_TOKEN` في GitHub Secrets!

---

## ✅ الحل الكامل (خطوة بخطوة)

### الخطوة 1: احصل على Shorebird Token

#### الطريقة الأولى: من Terminal (الأسهل)
```bash
# 1. سجل دخول
shorebird login

# 2. احصل على token
shorebird login:ci
```

**ملاحظة:** إذا فشل بسبب Java version، استخدم الطريقة الثانية ⬇️

#### الطريقة الثانية: من Shorebird Console
1. روح: https://console.shorebird.dev
2. سجل دخول
3. اضغط على اسمك (أعلى اليمين)
4. اختر "Account Settings"
5. اضغط "Generate CI Token"
6. انسخ الـ token

---

### الخطوة 2: أضف Token لـ GitHub Secrets

1. روح لـ repository على GitHub
2. اضغط **Settings** (في الأعلى)
3. من القائمة الجانبية: **Secrets and variables** → **Actions**
4. اضغط **New repository secret**
5. املأ:
   - **Name:** `SHOREBIRD_TOKEN`
   - **Secret:** [الصق الـ token اللي نسخته]
6. اضغط **Add secret**

---

### الخطوة 3: جرب الـ Workflow

```bash
# للـ Release الكامل (أول مرة)
git tag v0.1.0
git push origin v0.1.0

# أو للـ Patch (تحديث صغير)
git tag patch-006
git push origin patch-006
```

---

## 🔧 إصلاح مشكلة Java المحلية (اختياري)

إذا أردت تشغيل Shorebird على جهازك المحلي:

### المشكلة:
```
Unsupported class file major version 69
```
**السبب:** عندك Java 21، لكن Gradle يحتاج Java 17

### الحل:
```bash
# 1. نزّل Java 17 من:
# https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html

# 2. اضبط JAVA_HOME
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17"
[Environment]::SetEnvironmentVariable("JAVA_HOME", $env:JAVA_HOME, "User")

# 3. أعد تشغيل Terminal
# 4. تحقق من الإصدار
java -version  # يجب أن يظهر: java version "17.x.x"

# 5. جرب Shorebird مرة أخرى
shorebird init
```

---

## 📊 متطلبات Shorebird (من الـ Docs)

| Platform | Minimum Flutter Version | Minimum Shorebird Version |
|----------|------------------------|---------------------------|
| Android  | **3.24.0**             | 1.2.0                     |
| iOS      | 3.24.0                 | 1.2.0                     |

✅ **الـ workflow بتاعك يستخدم Flutter 3.24.0 - تمام!**

---

## 🎯 سير العمل الصحيح

### السيناريو 1: أول Release (مرة واحدة فقط)
```bash
# 1. عدّل الكود
# 2. اعمل tag
git tag v0.1.0
git push origin v0.1.0

# 3. GitHub Actions هيعمل:
#    ✅ يبني APK كامل (~80 MB)
#    ✅ يرفعه على GitHub Releases
#    ✅ يسجله في Shorebird Console
#    ✅ ينشئ app_id تلقائياً

# 4. نزّل الـ APK وابعته للعميل (مرة واحدة فقط!)
```

### السيناريو 2: تحديثات يومية (Patches)
```bash
# 1. عدّل الكود (Dart فقط)
# 2. اعمل patch tag
git tag patch-001
git push origin patch-001

# 3. GitHub Actions هيعمل:
#    ✅ يبني patch صغير (~2 MB)
#    ✅ يرفعه على Shorebird
#    ✅ التطبيق يحمّله تلقائياً

# 4. العميل يفتح التطبيق → يلاقي زر "تحديث" → يضغط عليه
```

---

## ⚠️ ملاحظات مهمة

### ✅ Shorebird يقدر يحدّث:
- كود Dart
- UI changes
- Bug fixes
- Colors, text, logic

### ❌ Shorebird مش هيقدر يحدّث:
- AndroidManifest.xml
- Permissions
- Native code (Java/Kotlin)
- Dependencies جديدة

**للتحديثات دي، لازم APK كامل (v0.2.0, v0.3.0, إلخ)**

---

## 🔍 التحقق من النجاح

### 1. GitHub Actions
```
GitHub → Actions → Shorebird Release → ✅ Success
```

### 2. Shorebird Console
```
https://console.shorebird.dev
→ شوف الـ releases/patches
→ شوف عدد المستخدمين اللي حملوا التحديث
```

### 3. GitHub Releases (للـ releases فقط)
```
GitHub → Releases → شوف الـ APK
```

---

## 🎉 الخلاصة

**المشكلة الوحيدة المتبقية:** مفيش `SHOREBIRD_TOKEN` في GitHub Secrets

**الحل:**
1. احصل على token من `shorebird login:ci` أو من Console
2. أضفه في GitHub Secrets
3. اعمل `git push origin v0.1.0`
4. خلاص! 🎉

**بعد كده:**
- كل تحديث صغير → `git push origin patch-XXX`
- كل تحديث كبير → `git push origin vX.X.X`

---

**آخر تحديث:** 2026-05-13  
**الحالة:** ✅ جاهز للاستخدام (بعد إضافة SHOREBIRD_TOKEN)  
**المرجع:** https://docs.shorebird.dev/getting-started/flutter-version/
