# 🔧 إصلاح مشكلة --force Flag في Shorebird

## 🔴 المشكلة

كان الـ GitHub Actions workflow بيحاول يستخدم `--force` flag مع `shorebird release`:

```bash
# ❌ الكود الغلط
if grep -q "PLACEHOLDER_APP_ID" shorebird.yaml; then
  EXTRA_FLAGS="--force"
fi

shorebird release android $EXTRA_FLAGS
```

**النتيجة:**
```
Could not find an option named "--force".
```

---

## ✅ الحل

بعد البحث في [Shorebird Documentation](https://docs.shorebird.dev), اتضح إن:

### 1. مفيش `--force` flag في Shorebird!

الـ flags المتاحة لـ `shorebird release android`:
- `--flutter-version` - تحديد نسخة Flutter
- `--artifact` - نوع الـ artifact (aab أو apk)
- `--flavor` - الـ flavor المطلوب
- `--build-name` / `--build-number` - معلومات الإصدار
- `--verbose` - عرض تفاصيل أكثر

**مفيش `--force` خالص!**

### 2. Shorebird بيتعامل مع أول release تلقائياً

من الـ [Initialize Documentation](https://docs.shorebird.dev/code-push/initialize/):

> When you run `shorebird init`, it creates a unique `app_id` for your app.
> When you run `shorebird release` for the first time, it automatically creates the release.

**يعني:**
- `shorebird init` → بيعمل app_id
- `shorebird release android` → بيعمل أول release تلقائي
- **مش محتاج أي flags إضافية!**

---

## 📝 الكود الصحيح

```yaml
- name: Shorebird Release
  run: |
    echo "🚀 Starting Shorebird Release..."
    
    # ✅ الطريقة الصحيحة - بدون --force
    shorebird release android \
      --flutter-version=3.24.0 \
      --verbose
  env:
    SHOREBIRD_TOKEN: ${{ secrets.SHOREBIRD_TOKEN }}
```

---

## 🎯 الخطوات الصحيحة للإعداد

### 1. Initialize Shorebird (مرة واحدة)
```bash
shorebird init
```

هذا الأمر:
- ✅ بيعمل app_id فريد
- ✅ بيعمل ملف `shorebird.yaml`
- ✅ بيضيف `shorebird.yaml` في `pubspec.yaml` assets

### 2. Create First Release
```bash
shorebird release android
```

**بدون أي flags إضافية!** Shorebird بيعرف إنها أول مرة ويتعامل معاها تلقائياً.

### 3. Create Patches (التحديثات)
```bash
shorebird patch android
```

---

## 🚀 استخدام GitHub Actions

### الطريقة الصحيحة:

```yaml
- name: Shorebird Login
  run: shorebird login:ci
  env:
    SHOREBIRD_TOKEN: ${{ secrets.SHOREBIRD_TOKEN }}

- name: Shorebird Release
  run: shorebird release android --flutter-version=3.24.0
  env:
    SHOREBIRD_TOKEN: ${{ secrets.SHOREBIRD_TOKEN }}
```

### ❌ الطريقة الغلط:

```yaml
# لا تستخدم --force (مش موجود!)
shorebird release android --force

# لا تحاول تكتشف إذا كان أول release
# Shorebird بيعمل ده تلقائياً
```

---

## 📚 مصادر

- [Shorebird Initialize Docs](https://docs.shorebird.dev/code-push/initialize/)
- [Shorebird Release Docs](https://docs.shorebird.dev/code-push/release/)
- [Shorebird CLI Reference](https://docs.shorebird.dev/cli/)

---

## ✅ التعديلات المطبقة

تم تعديل `.github/workflows/shorebird-release.yml`:
- ✅ إزالة محاولة استخدام `--force` flag
- ✅ تبسيط الكود ليستخدم `shorebird release android` مباشرة
- ✅ إضافة `--verbose` للحصول على معلومات أكثر عند الفشل

---

**آخر تحديث:** 2026-05-13  
**الحالة:** ✅ تم الإصلاح
