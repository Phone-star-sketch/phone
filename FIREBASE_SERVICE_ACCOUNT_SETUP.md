# 🔥 إعداد Firebase Service Account - خطوة بخطوة

## المشكلة الحالية
```
❌ Error: Invalid signature for token
```

السبب: Firebase Service Account JSON مش صحيح أو الـ private key فيه مشكلة.

---

## ⚠️ تحديث مهم
Edge Function الآن يرسل إشعارات لـ **جميع المعاملات** (مش بس المساعد)، مع عرض اسم المستخدم اللي عمل المعاملة.

---

## ✅ الحل الصحيح

### الخطوة 1: احصل على Service Account JSON جديد

1. **روح Firebase Console:**
   ```
   https://console.firebase.google.com
   ```

2. **اختار مشروعك:** `phone-system-app`

3. **روح Project Settings:**
   - اضغط على الترس ⚙️ جنب "Project Overview"
   - اختار "Project settings"

4. **روح Service accounts tab:**
   - اضغط على تاب "Service accounts"

5. **Generate new private key:**
   - اضغط "Generate new private key"
   - اضغط "Generate key" في الـ dialog
   - هينزل ملف JSON (مثال: `phone-system-app-firebase-adminsdk-xxxxx.json`)

### الخطوة 2: انسخ محتوى الملف بالكامل

افتح الملف اللي نزل، المفروض يكون شكله كده:

```json
{
  "type": "service_account",
  "project_id": "phone-system-app",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@phone-system-app.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "..."
}
```

**⚠️ مهم جداً:**
- انسخ **كل** محتوى الملف من `{` لـ `}`
- لازم يكون فيه `\n` في الـ `private_key`
- ما تعدلش أي حاجة في الملف

### الخطوة 3: حط الـ JSON في Supabase

1. **روح Supabase Dashboard:**
   ```
   https://supabase.com/dashboard
   ```

2. **اختار مشروعك**

3. **روح Edge Functions:**
   - Edge Functions → `notify-on-log` → Settings

4. **أضف/حدّث الـ Secret:**
   - لو موجود: اضغط "Edit" جنب `FIREBASE_SERVICE_ACCOUNT`
   - لو مش موجود: اضغط "Add secret"
   
   - **Name:** `FIREBASE_SERVICE_ACCOUNT`
   - **Value:** الصق **كل** محتوى الـ JSON (من `{` لـ `}`)
   
5. **Save**

### الخطوة 4: اختبر

1. اعمل معاملة من حساب المساعد (creator = 2)
2. شوف الـ Logs في Supabase Dashboard → Edge Functions → notify-on-log → Logs

**المفروض تشوف:**
```
📥 Request received at: ...
✅ Transaction detected - proceeding with notification
👤 Client name: [اسم العميل]
👤 User name: [اسم المستخدم]
🔐 Getting Firebase access token...
🔐 Service account email: firebase-adminsdk-fbsvc@phone-system-app.iam.gserviceaccount.com
🔐 Got Firebase access token
📤 Sending FCM request to: ...
📥 FCM response status: 200
✅ FCM notification sent successfully!
```

---

## 🔍 التحقق من الـ JSON

قبل ما تحطه في Supabase، تأكد من:

### ✅ Checklist:

- [ ] الملف يبدأ بـ `{` وينتهي بـ `}`
- [ ] فيه `"type": "service_account"`
- [ ] فيه `"project_id": "phone-system-app"`
- [ ] فيه `"private_key"` وبيبدأ بـ `"-----BEGIN PRIVATE KEY-----\n"`
- [ ] الـ `private_key` فيه `\n` (backslash n) مش line breaks حقيقية
- [ ] فيه `"client_email"` بيحتوي على `@phone-system-app.iam.gserviceaccount.com`
- [ ] مفيش spaces أو characters زيادة في البداية أو النهاية

### ❌ أخطاء شائعة:

1. **نسخ جزء من الملف بس** - لازم تنسخ كل حاجة
2. **تعديل الـ private_key** - ما تحاولش تعدل أو تنظف الـ `\n`
3. **إضافة spaces** - ما تضيفش spaces في البداية أو النهاية
4. **استخدام ملف قديم** - لازم تولد ملف جديد

---

## 🎯 مثال صحيح

الـ Secret في Supabase لازم يكون بالشكل ده بالظبط:

```json
{"type":"service_account","project_id":"phone-system-app","private_key_id":"abc123...","private_key":"-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASC...\n-----END PRIVATE KEY-----\n","client_email":"firebase-adminsdk-fbsvc@phone-system-app.iam.gserviceaccount.com","client_id":"123456789","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40phone-system-app.iam.gserviceaccount.com"}
```

**ملاحظة:** ممكن يكون على سطر واحد أو formatted، المهم المحتوى يكون صحيح.

---

## 📝 ملاحظات إضافية

### لو لسه مش شغال بعد كده:

1. **تأكد من Firebase Project ID:**
   - في الـ JSON: `"project_id": "phone-system-app"`
   - في Edge Function: `https://fcm.googleapis.com/v1/projects/phone-system-app/messages:send`
   - لازم يكونوا نفس الاسم

2. **تأكد من Firebase Cloud Messaging API مفعّل:**
   - روح Firebase Console → Project Settings → Cloud Messaging
   - تأكد إن Cloud Messaging API enabled

3. **جرب Service Account جديد تماماً:**
   - احذف الـ Service Account القديم من Firebase
   - اعمل واحد جديد
   - نزّل الـ JSON
   - حطه في Supabase

---

**آخر تحديث:** 2026-04-27
**الحالة:** جاهز للتطبيق
