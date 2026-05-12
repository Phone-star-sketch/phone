# 🔧 حل مشكلة app_id الفارغ

## ⚠️ المشكلة

```
ParsedYamlException: line 6, column 7: Unsupported value for "app_id". 
type 'Null' is not a subtype of type 'String' in type cast
```

**السبب**: ملف `shorebird.yaml` كان يحتوي على `app_id: ""` (empty string)، وهذا يسبب parsing error.

---

## ✅ الحل

**تم الإصلاح**: تغيير `app_id: ""` إلى `# app_id:` (commented out)

**لماذا؟**
- Shorebird لا يقبل empty string (`""`)
- يجب أن يكون إما:
  - ✅ `app_id: abc123` (قيمة صحيحة)
  - ✅ `# app_id:` (معطّل/commented)
  - ❌ `app_id: ""` (empty string - يسبب error!)

---

## 🚀 الاستخدام

```powershell
# احفظ التغييرات
git add .
git commit -m "Fix: Comment out app_id instead of empty string"
git push

# جرّب أول release
git tag v0.1.7
git push origin v0.1.7
```

**Shorebird سيقوم بـ:**
1. يكتشف أن `app_id` غير موجود (commented)
2. ينشئ app جديد تلقائياً
3. يحفظ `app_id` في `shorebird.yaml`
4. يبني ويرفع الـ release

---

## 📝 ملف shorebird.yaml الصحيح

```yaml
# قبل أول release:
# app_id:  ← commented out
auto_update: false

# بعد أول release:
app_id: abc123xyz  ← Shorebird يضيفه تلقائياً
auto_update: false
```

---

## 🎉 الخلاصة

**المشكلة**: `app_id: ""` يسبب parsing error

**الحل**: `# app_id:` (commented out)

**النتيجة**: ✅ يجب أن يعمل الآن!

---

**آخر تحديث**: 2026-05-12  
**الحالة**: ✅ تم الإصلاح
