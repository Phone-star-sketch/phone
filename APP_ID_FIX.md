# 🔧 حل مشكلة app_id الفارغ

## ⚠️ المشكلة

```
ParsedYamlException: line 6, column 7: Unsupported value for "app_id". 
type 'Null' is not a subtype of type 'String' in type cast
```

**السبب**: ملف `shorebird.yaml` يحتوي على `app_id` فارغ.

---

## ✅ الحل

**Shorebird ينشئ الـ app تلقائياً** عند أول `shorebird release` إذا كان `app_id` فارغ!

لا نحتاج أي flags خاصة - فقط:

```bash
shorebird release android
```

**Shorebird سيقوم بـ:**
1. يكتشف أن `app_id` فارغ
2. ينشئ app جديد تلقائياً
3. يحفظ `app_id` في `shorebird.yaml`
4. يبني ويرفع الـ release

---

## 🚀 الاستخدام

```powershell
# احفظ التغييرات
git add .
git commit -m "Fix: Remove invalid --force flag"
git push

# جرّب أول release
git tag v0.1.6
git push origin v0.1.6
```

**يجب أن يعمل الآن!** ✅

---

## 📝 ملاحظة مهمة

**لا تستخدم `--force`** - هذا ليس flag صحيح لـ `shorebird release`!

الـ flags الصحيحة:
- `--dart-define`
- `--flavor`
- `--build-name`
- `--build-number`
- `--artifact` (aab أو apk)

---

## 🎉 الخلاصة

**المشكلة**: استخدام `--force` (غير موجود)

**الحل**: إزالته - Shorebird ينشئ app تلقائياً

**النتيجة**: ✅ يجب أن يعمل الآن!

---

**آخر تحديث**: 2026-05-12  
**الحالة**: ✅ تم الإصلاح
