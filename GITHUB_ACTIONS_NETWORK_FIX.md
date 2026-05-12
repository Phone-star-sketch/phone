# 🔧 حل مشكلة الشبكة في GitHub Actions

## ⚠️ المشكلة

```
error: RPC failed; curl 56 Recv failure: Connection reset by peer
error: 2319 bytes of body are still expected
fetch-pack: unexpected disconnect while reading sideband packet
fatal: early EOF
fatal: fetch-pack: invalid index-pack output
Error: Process completed with exit code 128.
```

**السبب**: مشكلة عشوائية في الاتصال بين GitHub Actions وخوادم GitHub عند تحميل Shorebird.

---

## ✅ الحلول المطبقة

### الحل 1: Retry Logic (الأساسي)

تم تحديث `.github/workflows/shorebird-release.yml` ليحاول 3 مرات:

```yaml
- name: Setup Shorebird
  uses: shorebirdtech/setup-shorebird@v1
  with:
    cache: true
  continue-on-error: true
  id: shorebird_setup_attempt1

- name: Retry Setup Shorebird (if first attempt failed)
  if: steps.shorebird_setup_attempt1.outcome == 'failure'
  uses: shorebirdtech/setup-shorebird@v1
  with:
    cache: true
  continue-on-error: true
  id: shorebird_setup_attempt2

- name: Final Retry Setup Shorebird (if second attempt failed)
  if: steps.shorebird_setup_attempt2.outcome == 'failure'
  uses: shorebirdtech/setup-shorebird@v1
  with:
    cache: true
```

**الفائدة**: إذا فشلت المحاولة الأولى، يحاول مرة ثانية وثالثة تلقائياً.

---

### الحل 2: Manual Installation (البديل)

تم إنشاء `.github/workflows/shorebird-release-alternative.yml` مع:

1. **Git Configuration** لتحسين الاتصال:
```yaml
- name: Configure Git
  run: |
    git config --global http.postBuffer 524288000
    git config --global http.lowSpeedLimit 0
    git config --global http.lowSpeedTime 999999
    git config --global core.compression 0
```

2. **Manual Installation مع Retry**:
```yaml
- name: Install Shorebird (with retry)
  run: |
    max_attempts=3
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
      echo "Attempt $attempt of $max_attempts..."
      
      if curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash; then
        echo "✅ Shorebird installed successfully!"
        break
      else
        echo "❌ Attempt $attempt failed"
        if [ $attempt -eq $max_attempts ]; then
          echo "Failed after $max_attempts attempts"
          exit 1
        fi
        attempt=$((attempt + 1))
        echo "Waiting 10 seconds before retry..."
        sleep 10
      fi
    done
```

---

## 🚀 كيفية الاستخدام

### الطريقة 1: استخدم الـ Workflow الأساسي (موصى به)

```bash
# للإصدار الكامل
git tag v0.1.6
git push origin v0.1.6

# للـ patch
git tag patch-001
git push origin patch-001
```

**الآن مع retry logic، يجب أن ينجح!**

---

### الطريقة 2: استخدم الـ Workflow البديل (إذا فشل الأساسي)

#### أ. تشغيل يدوي:

1. روح: https://github.com/Phone-star-sketch/phone/actions
2. اختر: "Shorebird Release (Alternative)"
3. اضغط: "Run workflow"
4. اختر branch: `ramy/newdesign`
5. اضغط: "Run workflow"

#### ب. باستخدام Tags:

```bash
# للإصدار الكامل
git tag v0.1.6-alt
git push origin v0.1.6-alt

# للـ patch
git tag patch-001-alt
git push origin patch-001-alt
```

---

## 📊 المقارنة

| الميزة | Workflow الأساسي | Workflow البديل |
|--------|------------------|------------------|
| السرعة | ⚡ أسرع | ⏰ أبطأ قليلاً |
| الموثوقية | ✅ عالية (مع retry) | ✅ عالية جداً |
| Git Config | ❌ لا | ✅ نعم |
| Retry Logic | ✅ 3 محاولات | ✅ 3 محاولات + انتظار |
| التشغيل اليدوي | ❌ لا | ✅ نعم |

---

## 🔍 فهم المشكلة

### لماذا تحدث؟

1. **Network Timeout**: GitHub Actions أحياناً يواجه timeout عند git clone
2. **Large Repository**: Shorebird repository كبير نسبياً
3. **GitHub Server Load**: الخوادم أحياناً مشغولة

### لماذا الحل يعمل؟

1. **Retry**: معظم المشاكل عشوائية - المحاولة الثانية تنجح
2. **Git Config**: يزيد buffer size ويقلل timeout restrictions
3. **Sleep Between Retries**: يعطي الشبكة وقت للاستقرار

---

## 📝 ملاحظات مهمة

### ✅ افعل:
- استخدم الـ workflow الأساسي أولاً
- إذا فشل 2-3 مرات، استخدم البديل
- راقب الـ logs لفهم المشكلة

### ❌ لا تفعل:
- لا تقلق إذا فشلت المحاولة الأولى
- لا تلغي الـ workflow بسرعة - انتظر الـ retries
- لا تحاول تشغيل الاتنين في نفس الوقت

---

## 🆘 إذا استمرت المشكلة

### الحل 1: انتظر وحاول مرة أخرى

أحياناً المشكلة من GitHub نفسه. انتظر 30 دقيقة وحاول مرة أخرى.

### الحل 2: استخدم Manual Trigger

```bash
# بدل ما تعمل tag، استخدم manual trigger:
# 1. روح GitHub Actions
# 2. اختر "Shorebird Release (Alternative)"
# 3. اضغط "Run workflow"
```

### الحل 3: تواصل مع Shorebird

إذا استمرت المشكلة لأكثر من يوم:
- Discord: https://discord.gg/shorebird
- GitHub Issues: https://github.com/shorebirdtech/shorebird/issues

---

## 📚 المصادر

- [Shorebird Issue #2397](https://github.com/shorebirdtech/shorebird/issues/2397)
- [Install Issue #34](https://github.com/shorebirdtech/install/issues/34)
- [Git Clone Network Issues](https://stackoverflow.com/questions/66366582/github-unexpected-disconnect-while-reading-sideband-packet)

---

## 🎉 الخلاصة

**المشكلة**: network timeout عشوائي من GitHub

**الحل**: retry logic + git configuration

**النتيجة**: ✅ يجب أن يعمل الآن!

---

**آخر تحديث**: 2026-05-12  
**الحالة**: ✅ تم تطبيق الحلول
