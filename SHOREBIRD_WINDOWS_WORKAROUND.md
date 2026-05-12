# 🔧 حل مشكلة Shorebird على Windows

## ⚠️ المشكلة

`shorebird init` يتعطل على Windows بسبب مشكلة في Gradle.

## ✅ الحل البديل (موصى به)

بدلاً من استخدام `shorebird init` محلياً، استخدم **GitHub Actions** لعمل الـ releases والـ patches.

---

## 📋 الخطوات

### 1. الكود جاهز ✅

تم إضافة كل الكود المطلوب:
- ✅ `shorebird_code_push` package
- ✅ Services, Controllers, Components
- ✅ `shorebird.yaml` file

### 2. استخدم GitHub Actions للـ Release الأول

بدلاً من `shorebird init` و `shorebird release` محلياً، استخدم GitHub Actions:

#### أ. احصل على Shorebird Token

الطريقة الأفضل هي استخدام `login:ci` للحصول على token:

```bash
# في PowerShell
shorebird login:ci
```

هذا سيعطيك token يمكنك استخدامه في GitHub Actions.

**بديل**: يمكنك الحصول على token من Shorebird Console:
1. زور: https://console.shorebird.dev
2. اذهب إلى Settings → API Keys
3. انسخ الـ token

#### ب. أضف Token لـ GitHub Secrets

1. روح: `Settings` → `Secrets and variables` → `Actions`
2. اضغط `New repository secret`
3. Name: `SHOREBIRD_TOKEN`
4. Value: [الـ token اللي نسخته]

#### ج. أنشئ GitHub Actions Workflow

أنشئ ملف: `.github/workflows/shorebird-release.yml`

```yaml
name: Shorebird Release

on:
  push:
    tags:
      - 'v*'  # للـ releases الكاملة
      - 'patch-*'  # للـ patches

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - name: Setup Shorebird
        uses: shorebirdtech/setup-shorebird@v1
        with:
          cache: true
      
      - name: Verify Shorebird Installation
        run: shorebird --version
      
      - name: Shorebird Login
        run: shorebird login:ci
        env:
          SHOREBIRD_TOKEN: ${{ secrets.SHOREBIRD_TOKEN }}
      
      - name: Get dependencies
        run: flutter pub get
      
      # Check if it's a patch or full release
      - name: Determine build type
        id: build_type
        run: |
          if [[ $GITHUB_REF == refs/tags/patch-* ]]; then
            echo "type=patch" >> $GITHUB_OUTPUT
          else
            echo "type=release" >> $GITHUB_OUTPUT
          fi
      
      # Full release
      - name: Shorebird Release
        if: steps.build_type.outputs.type == 'release'
        run: shorebird release android --force
      
      # Patch
      - name: Shorebird Patch
        if: steps.build_type.outputs.type == 'patch'
        run: shorebird patch android --force
      
      # Upload APK (only for full releases)
      - name: Upload APK
        if: steps.build_type.outputs.type == 'release'
        uses: actions/upload-artifact@v4
        with:
          name: app-release
          path: build/app/outputs/flutter-apk/app-release.apk
      
      # Create GitHub Release (only for full releases)
      - name: Create Release
        if: steps.build_type.outputs.type == 'release'
        uses: softprops/action-gh-release@v1
        with:
          files: build/app/outputs/flutter-apk/app-release.apk
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 🚀 الاستخدام

### للإصدار الأول (Full Release):

```bash
# 1. عدّل version في pubspec.yaml
version: 0.1.6

# 2. Commit وpush
git add .
git commit -m "Release v0.1.6"
git push

# 3. أنشئ tag
git tag v0.1.6
git push origin v0.1.6

# 4. GitHub Actions سيبني ويرفع APK تلقائياً!
```

### للتحديثات الصغيرة (Patches):

```bash
# 1. عدّل الكود (Dart فقط)
# 2. Commit وpush
git add .
git commit -m "Fix: حل مشكلة في الحساب"
git push

# 3. أنشئ patch tag
git tag patch-001
git push origin patch-001

# 4. GitHub Actions سيرسل الـ patch تلقائياً!
```

---

## 🎯 الفوائد

### مقارنة مع الطريقة المحلية:

| الميزة | محلياً (Windows) | GitHub Actions |
|--------|------------------|----------------|
| مشاكل Gradle | ❌ كثيرة | ✅ لا توجد |
| السرعة | ⏰ بطيء | ⚡ سريع |
| الموثوقية | ⚠️ متوسطة | ✅ عالية |
| التكلفة | مجاني | مجاني |
| الأتمتة | يدوي | تلقائي |

---

## 📱 تجربة المستخدم

### ماذا سيحدث؟

1. **أول مرة:**
   - ترفع tag: `v0.1.6`
   - GitHub Actions يبني APK
   - ترسل APK للعميل (مرة واحدة فقط)

2. **التحديثات:**
   - ترفع tag: `patch-001`
   - GitHub Actions يرسل patch
   - التطبيق يحمّل التحديث تلقائياً (1-5 MB)
   - العميل يفتح التطبيق → يظهر dialog "تحديث متاح"
   - يضغط "تحديث الآن" → يحمّل → يغلق ويفتح → التحديث يطبّق ✅

---

## 💡 نصائح

### 1. استخدم Semantic Versioning

```bash
v0.1.0  # إصدار أول
v0.1.1  # تحديث صغير
v0.2.0  # تحديث كبير
v1.0.0  # إصدار رسمي
```

### 2. استخدم Patch Tags للتحديثات الصغيرة

```bash
patch-001  # أول patch
patch-002  # ثاني patch
patch-003  # ثالث patch
```

### 3. راقب التحديثات من Shorebird Dashboard

زور: https://console.shorebird.dev

---

## ❓ الأسئلة الشائعة

### هل أحتاج لتثبيت Shorebird محلياً؟

**لا!** فقط احصل على الـ token مرة واحدة، وبعدها استخدم GitHub Actions.

### هل يمكنني استخدام الطريقتين معاً؟

**نعم!** يمكنك استخدام GitHub Actions للـ releases، والطريقة المحلية للـ patches (إذا نجحت).

### ماذا لو فشل GitHub Actions؟

تحقق من:
1. الـ token صحيح في GitHub Secrets
2. الـ Flutter version متوافق (3.24.0)
3. الـ logs في GitHub Actions

---

## 🎉 الخلاصة

**لا تقلق من مشاكل Windows!**

استخدم GitHub Actions وستحصل على:
- ✅ بناء موثوق
- ✅ أتمتة كاملة
- ✅ لا مشاكل Gradle
- ✅ مجاني تماماً

---

**آخر تحديث**: 2026-05-12
**الحالة**: ✅ جاهز للاستخدام
