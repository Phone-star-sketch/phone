# ⚡ دليل سريع - كل تعديل تعمل إيه؟

## 🎯 القاعدة الذهبية

**عدلت Dart فقط؟** → Patch ✅  
**عدلت حاجة تانية؟** → Release ❌

---

## 📋 الخطوات السريعة

### تعديل بسيط (Dart فقط):

```bash
# 1. عدّل الكود
# 2. اعمل commit
git add .
git commit -m "وصف التعديل"
git push

# 3. اعمل patch
git tag patch-001
git push origin patch-001

# ✅ خلاص! العميل هيستقبل التحديث تلقائياً
```

### تعديل كبير (Manifest, Permissions, Packages):

```bash
# 1. عدّل الكود
# 2. حدّث version في pubspec.yaml
# 3. اعمل commit
git add .
git commit -m "وصف التعديل"
git push

# 4. اعمل release
git tag v0.1.7
git push origin v0.1.7

# ✅ نزّل APK من GitHub Releases وارسله للعميل
```

---

## 🔍 أمثلة سريعة

| التعديل | الأمر |
|---------|-------|
| غيرت لون زرار | `git tag patch-001` |
| صلحت bug | `git tag patch-002` |
| حدثت نص | `git tag patch-003` |
| أضفت permission | `git tag v0.1.7` |
| أضفت package | `git tag v0.1.8` |

---

## 💡 نصيحة

**استخدم Patch للتعديلات اليومية** (90% من الوقت)  
**استخدم Release للتحديثات الكبيرة** (10% من الوقت)

---

**اقرأ التفاصيل في**: `WORKFLOW_GUIDE.md`
