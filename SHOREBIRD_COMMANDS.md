# 📋 دليل أوامر Shorebird

## 🔐 التسجيل والمصادقة

### تسجيل الدخول (تفاعلي)
```bash
shorebird login
```
يفتح المتصفح لتسجيل الدخول

### تسجيل الدخول لـ CI/CD
```bash
shorebird login:ci
```
يعطيك token لاستخدامه في GitHub Actions

### تسجيل الخروج
```bash
shorebird logout
```

---

## 🚀 إدارة المشروع

### تهيئة مشروع جديد
```bash
shorebird init
```
ينشئ `shorebird.yaml` ويضيف app_id

### إنشاء مشروع Flutter جديد
```bash
shorebird create my_app
```

---

## 📦 الإصدارات (Releases)

### إنشاء release جديد (Android)
```bash
shorebird release android
```

### إنشاء release جديد (iOS)
```bash
shorebird release ios
```

### عرض كل الـ releases
```bash
shorebird releases list
```

### حذف release
```bash
shorebird releases delete <release-version>
```

---

## 🔄 التحديثات (Patches)

### إنشاء patch (Android)
```bash
shorebird patch android
```

### إنشاء patch (iOS)
```bash
shorebird patch ios
```

### إنشاء patch لـ release محدد
```bash
shorebird patch android --release-version=1.0.0+1
```

### عرض كل الـ patches
```bash
shorebird patches list
```

### حذف patch
```bash
shorebird patches delete <patch-number>
```

---

## 🔍 المعاينة والاختبار

### معاينة release على جهاز
```bash
shorebird preview
```

### معاينة release محدد
```bash
shorebird preview --release-version=1.0.0+1
```

### معاينة patch محدد
```bash
shorebird preview --release-version=1.0.0+1 --patch-number=1
```

---

## 🛠️ الأدوات والصيانة

### فحص التثبيت
```bash
shorebird doctor
```

### تحديث Shorebird
```bash
shorebird upgrade
```

### إدارة Flutter
```bash
# عرض إصدارات Flutter المتاحة
shorebird flutter versions list

# تغيير إصدار Flutter
shorebird flutter versions use 3.24.0
```

### إدارة الـ cache
```bash
# عرض معلومات الـ cache
shorebird cache

# مسح الـ cache
shorebird cache clean
```

---

## 📊 الأوامر المفيدة

### عرض المساعدة
```bash
shorebird --help
shorebird <command> --help
```

### عرض الإصدار
```bash
shorebird --version
```

### تفعيل الـ verbose logging
```bash
shorebird <command> --verbose
```

---

## 🎯 أمثلة عملية

### السيناريو 1: إصدار أول مرة

```bash
# 1. تسجيل الدخول
shorebird login

# 2. تهيئة المشروع
shorebird init

# 3. إنشاء release
shorebird release android

# 4. عرض الـ releases
shorebird releases list
```

### السيناريو 2: إصلاح bug سريع

```bash
# 1. عدّل الكود
# 2. أنشئ patch
shorebird patch android

# 3. عرض الـ patches
shorebird patches list
```

### السيناريو 3: معاينة قبل النشر

```bash
# 1. أنشئ patch
shorebird patch android --dry-run

# 2. عاين على جهاز
shorebird preview --release-version=1.0.0+1 --patch-number=1
```

---

## ⚠️ ملاحظات مهمة

### الأوامر المتوفرة فقط:
- ✅ `shorebird login` (تفاعلي)
- ✅ `shorebird login:ci` (للـ CI/CD)
- ✅ `shorebird logout`
- ✅ `shorebird init`
- ✅ `shorebird release`
- ✅ `shorebird patch`
- ✅ `shorebird preview`
- ✅ `shorebird doctor`
- ✅ `shorebird upgrade`

### الأوامر غير المتوفرة:
- ❌ `shorebird account` (غير موجود)
- ❌ `shorebird account token` (استخدم `login:ci` بدلاً منه)

---

## 🔗 روابط مفيدة

- **Dashboard**: https://console.shorebird.dev
- **Documentation**: https://docs.shorebird.dev
- **GitHub**: https://github.com/shorebirdtech/shorebird

---

**آخر تحديث**: 2026-05-12
