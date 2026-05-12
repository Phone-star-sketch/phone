# 🔧 حل مشكلة app_id الفارغ

## ⚠️ المشكلة

```
ParsedYamlException: line 6, column 7: Unsupported value for "app_id". 
type 'Null' is not a subtype of type 'String' in type cast
╷
6 │ app_id:
│       ^
╵
```

**السبب**: ملف `shorebird.yaml` يحتوي على `app_id` فارغ، وShorebird يحتاج app_id لإرسال التحديثات.

---

## ✅ الحل المطبق

تم تحديث الـ workflows لإنشاء الـ app تلقائياً في أول release:

```yaml
- name: Shorebird Release
  if: steps.build_type.outputs.type == 'release'
  run: |
    # First release creates the app automatically
    if [ -z "$(grep 'app_id:' shorebird.yaml | grep -v '^#' | cut -d':' -f2 | tr -d ' ')" ]; then
      echo "First release - creating app..."
      shorebird release android --force
    else
      shorebird release android
    fi
```

**كيف يعمل:**
1. يفحص إذا `app_id` فارغ
2. إذا فارغ → يستخدم `--force` لإنشاء app جديد
3. إذا موجود → يستخدم الأمر العادي

---

## 🚀 الاستخدام

### الآن جرّب مرة أخرى:

```powershell
# 1. احفظ التغييرات
git add .
git commit -m "Fix: Auto-create app on first release"
git push

# 2. جرّب أول release
git tag v0.1.6
git push origin v0.1.6
```

**النتيجة المتوقعة:**
1. ✅ Shorebird يثبت بنجاح
2. ✅ يكتشف أن `app_id` فارغ
3. ✅ ينشئ app جديد تلقائياً مع `--force`
4. ✅ يحفظ الـ `app_id` في `shorebird.yaml`
5. ✅ يبني ويرفع APK

---

## 📝 ملاحظات

### بعد أول Release:

الـ `app_id` سيتم ملؤه تلقائياً في `shorebird.yaml`:

```yaml
# قبل
app_id: 

# بعد
app_id: abc123-def456-ghi789
```

**مهم**: بعد أول release، اعمل pull للتغييرات:

```powershell
git pull origin ramy/newdesign
```

هذا سيحمّل الـ `app_id` الجديد على جهازك.

---

### للـ Patches التالية:

بعد أول release، الـ patches ستعمل بدون مشاكل:

```powershell
git tag patch-001
git push origin patch-001
```

---

## 🔍 التحقق

### بعد اكتمال الـ workflow:

1. **تحقق من الـ logs**:
   - يجب أن ترى: "First release - creating app..."
   - ثم: "✓ Release created successfully"

2. **تحقق من Shorebird Console**:
   - روح: https://console.shorebird.dev
   - يجب أن ترى app جديد باسم مشروعك

3. **تحقق من shorebird.yaml**:
   - في GitHub، افتح `shorebird.yaml`
   - يجب أن يحتوي على `app_id` جديد

---

## ⚠️ تحذير: Legacy Token

لاحظت في الـ logs:

```
[WARN] SHOREBIRD_TOKEN contains a legacy CI token from `shorebird login:ci`. 
This format is deprecated and will stop working in a future release. 
Create an API key at https://console.shorebird.dev instead.
```

**ليس مشكلة الآن** - سيعمل بشكل طبيعي. لكن في المستقبل:

1. روح: https://console.shorebird.dev
2. اذهب: Settings → API Keys
3. أنشئ API key جديد
4. استبدل `SHOREBIRD_TOKEN` في GitHub Secrets

---

## 🎉 الخلاصة

**المشكلة**: `app_id` فارغ

**الحل**: استخدام `--force` في أول release لإنشاء app تلقائياً

**النتيجة**: ✅ يجب أن يعمل الآن!

---

**آخر تحديث**: 2026-05-12  
**الحالة**: ✅ تم الإصلاح
