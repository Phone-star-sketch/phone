# 🔧 حل مشكلة PLACEHOLDER_APP_ID في Shorebird

## 🔴 المشكلة

الـ `shorebird.yaml` كان فيه:
```yaml
app_id: PLACEHOLDER_APP_ID
```

وده كان بيسبب فشل الـ GitHub Actions workflow.

---

## ✅ الحل المطبق

تم تعديل الـ workflow ليعمل **automatic initialization** للـ Shorebird app:

### الخطوات التلقائية:

1. **Check shorebird.yaml** - يفحص إذا كان فيه `PLACEHOLDER_APP_ID`

2. **Run `shorebird init --force`** - يعمل app جديد على Shorebird تلقائياً
   ```bash
   shorebird init --force <<EOF
   phone_system_app
   EOF
   ```

3. **Commit the new app_id** - يحفظ الـ app_id الجديد في الـ repo
   ```bash
   git add shorebird.yaml
   git commit -m "chore: Update shorebird.yaml with real app_id [skip ci]"
   git push
   ```

4. **Continue with release** - يكمل الـ release عادي

---

## 🎯 الفوائد

✅ **تلقائي بالكامل** - مش محتاج تعمل حاجة يدوي  
✅ **يشتغل من أول مرة** - الـ workflow يعمل كل حاجة  
✅ **يحفظ الـ app_id** - بيعمل commit تلقائي للـ repo  
✅ **مفيش تكرار** - لو الـ app_id موجود، بيستخدمه مباشرة  

---

## 📝 الكود المضاف

```yaml
- name: Initialize Shorebird App
  run: |
    if grep -q "PLACEHOLDER_APP_ID" shorebird.yaml; then
      echo "🔧 First time setup - creating Shorebird app..."
      
      # Create app automatically
      shorebird init --force <<EOF
      phone_system_app
      EOF
      
      # Commit back to repo
      git config user.name "github-actions[bot]"
      git config user.email "github-actions[bot]@users.noreply.github.com"
      git add shorebird.yaml
      git commit -m "chore: Update shorebird.yaml with real app_id [skip ci]"
      git push
      
      echo "✅ shorebird.yaml updated in repository"
    else
      APP_ID=$(grep "^app_id:" shorebird.yaml | cut -d' ' -f2)
      echo "✅ Using existing app_id: $APP_ID"
    fi
  env:
    SHOREBIRD_TOKEN: ${{ secrets.SHOREBIRD_TOKEN }}
```

---

## 🚀 الاستخدام

### أول مرة (مع PLACEHOLDER_APP_ID):
```bash
git tag v0.1.9
git push origin v0.1.9
```

**النتيجة:**
1. ✅ الـ workflow يعمل `shorebird init`
2. ✅ يحصل على app_id جديد
3. ✅ يحفظه في `shorebird.yaml`
4. ✅ يعمل commit ويرفعه على الـ repo
5. ✅ يكمل الـ release

### المرات الجاية (مع app_id حقيقي):
```bash
git tag v0.2.0
git push origin v0.2.0
```

**النتيجة:**
1. ✅ الـ workflow يشوف الـ app_id موجود
2. ✅ يستخدمه مباشرة
3. ✅ يكمل الـ release

---

## 📋 ملاحظات مهمة

### `[skip ci]` في الـ commit message

```bash
git commit -m "chore: Update shorebird.yaml with real app_id [skip ci]"
```

الـ `[skip ci]` ده مهم عشان:
- ✅ يمنع infinite loop (الـ commit الجديد مش هيشغل الـ workflow تاني)
- ✅ يوفر resources على GitHub Actions
- ✅ يخلي الـ workflow يكمل بدون مشاكل

### الـ `--force` flag في `shorebird init`

```bash
shorebird init --force
```

الـ `--force` هنا **مختلف** عن `shorebird release --force`:
- ✅ `shorebird init --force` - **موجود** ويستخدم لإعادة الـ initialization
- ❌ `shorebird release --force` - **مش موجود** ومش مطلوب

---

## ✅ الحالة النهائية

بعد التعديلات:
- ✅ الـ workflow يعمل `shorebird init` تلقائياً
- ✅ الـ app_id يتحفظ في الـ repo
- ✅ الـ release يشتغل من أول مرة
- ✅ مفيش حاجة يدوية مطلوبة

---

**آخر تحديث:** 2026-05-13  
**الحالة:** ✅ تم الإصلاح والتطبيق
