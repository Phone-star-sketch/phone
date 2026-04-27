# 🔔 دليل إعداد الإشعارات الشامل

## 📋 نظرة عامة

النظام يدعم نوعين من الإشعارات:
1. **Realtime Notifications** - عندما التطبيق مفتوح (foreground)
2. **FCM Push Notifications** - عندما التطبيق مقفول أو في الخلفية (background/terminated)

---

## 🎯 متى تظهر الإشعارات؟

الإشعارات تظهر فقط للمعاملات من **المساعد** (creator = 2):
- ✅ تسديد نقدية (moneyAdded)
- ✅ إضافة مديونية (moneyDeducted)  
- ✅ دفع حساب الخدمات (transactionDone)

---

## 📁 الملفات المتعلقة بالإشعارات

### 1. خدمات الإشعارات (Services)
- `lib/services/fcm_service.dart` - خدمة Firebase Cloud Messaging
- `lib/services/transaction_notification_service.dart` - خدمة الإشعارات المحلية
- `lib/services/notification_service.dart` - خدمة الإشعارات العامة

### 2. واجهات المستخدم (UI)
- `lib/views/pages/follow.dart` - صفحة السجل (تعرض المعاملات)
- `lib/views/bottom_sheet_dialogs/show_client_info_sheet.dart` - نافذة معلومات العميل (أزرار التسديد/الإضافة)

### 3. المستودعات (Repositories)
- `lib/repositories/client/supabase_client_repository.dart` - يحتوي على دوال المعاملات المالية

### 4. Firebase & Supabase
- `lib/firebase_options.dart` - إعدادات Firebase
- `android/app/src/main/AndroidManifest.xml` - إعدادات Android للإشعارات
- `supabase_edge_function_notify_on_log.ts` - Edge Function لإرسال FCM

---

## 🔧 الإعداد الأولي

### 1. Firebase Setup

#### أ. إنشاء مشروع Firebase
1. روح https://console.firebase.google.com
2. اضغط "Add project" أو اختر مشروعك الموجود
3. اسم المشروع: `phone-system-app`

#### ب. إضافة Android App
1. في Firebase Console → Project Settings → Your apps
2. اضغط Android icon
3. Android package name: `com.foe.phone_system_app`
4. نزّل `google-services.json` وحطه في `android/app/`

#### ج. تفعيل Cloud Messaging
1. في Firebase Console → Build → Cloud Messaging
2. اضغط "Get started"
3. احفظ Server Key (هنحتاجه بعدين)

#### د. إنشاء Service Account
1. في Firebase Console → Project Settings → Service accounts
2. اضغط "Generate new private key"
3. نزّل الملف JSON (مثال: `phone-system-app-firebase-adminsdk-xxxxx.json`)
4. احفظ محتوى الملف - هنحتاجه في Supabase

### 2. Supabase Setup

#### أ. إنشاء جدول FCM Tokens
```sql
-- في Supabase SQL Editor
CREATE TABLE IF NOT EXISTS fcm_tokens (
  id BIGSERIAL PRIMARY KEY,
  device TEXT UNIQUE NOT NULL,
  token TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Policy للسماح بالقراءة والكتابة
CREATE POLICY "Allow all operations on fcm_tokens" 
ON fcm_tokens FOR ALL 
USING (true) 
WITH CHECK (true);
```

#### ب. تفعيل Realtime على جدول log
```sql
-- في Supabase SQL Editor
ALTER PUBLICATION supabase_realtime ADD TABLE log;
```

#### ج. إنشاء Edge Function
1. في Supabase Dashboard → Edge Functions
2. اضغط "Create a new function"
3. الاسم: `notify-on-log`
4. انسخ الكود من `supabase_edge_function_notify_on_log.ts`
5. Deploy

#### د. إضافة Firebase Service Account Secret
1. في Supabase Dashboard → Edge Functions → notify-on-log → Settings
2. اضغط "Add secret"
3. Name: `FIREBASE_SERVICE_ACCOUNT`
4. Value: انسخ **كل** محتوى ملف JSON اللي نزلته من Firebase (الملف الكامل)
5. Save

---

## 🚀 سير العمل (Workflow)

### السيناريو 1: المستخدم يسدد نقدية

```
1. المستخدم يفتح صفحة العميل
   ↓
2. يضغط زر "تسديد" 
   ↓
3. يدخل المبلغ ويضغط "تأكيد"
   ↓
4. الكود في `show_client_info_sheet.dart` ينادي:
   `loaders.changeMoneyValue(client, amount, true)`
   ↓
5. الكود في `supabase_client_repository.dart` ينفذ:
   - يحدث رصيد العميل في قاعدة البيانات
   - ينشئ سجل معاملة جديد في جدول `log`
   - ينادي `_notifyPushNotification()` لإرسال إشعار FCM
   ↓
6. Edge Function `notify-on-log` يستقبل البيانات:
   - يتحقق إن المعاملة من المساعد (creator = 2)
   - يجيب اسم العميل من قاعدة البيانات
   - يجيب FCM token من جدول `fcm_tokens`
   - يرسل إشعار FCM عبر Firebase API
   ↓
7. الإشعار يظهر على الجهاز:
   - إذا التطبيق مفتوح: يظهر كـ local notification
   - إذا التطبيق مقفول: يظهر كـ push notification
```

### السيناريو 2: المستخدم يضيف مديونية

نفس الخطوات، لكن:
- `adding = false` في `changeMoneyValue()`
- `transaction_type = 1` (moneyDeducted)

---

## 🔍 التشخيص والاختبار

### 1. فحص FCM Token

```dart
// في lib/services/fcm_service.dart
// الكود بيطبع:
debugPrint('🔔 FCM Token: $token');
debugPrint('🔔 FCM: Token saved successfully');
```

**كيف تشوف الـ Logs:**
```bash
# على Windows
adb logcat | findstr "🔔"

# على Linux/Mac
adb logcat | grep "🔔"
```

**تحقق من الـ Token في Supabase:**
```sql
SELECT * FROM fcm_tokens WHERE device = 'manager';
```

### 2. فحص Edge Function

في Supabase Dashboard → Edge Functions → notify-on-log → Logs

**Logs المتوقعة:**
```
📥 Request received
📦 Payload: {...}
📝 Record creator: 2
👤 Client name: [اسم العميل]
🔑 FCM token found
📧 Preparing FCM message: Phone System ...
🔐 Got Firebase access token
✅ FCM sent successfully: {...}
```

**Errors محتملة:**
```
❌ No FCM token found
❌ FCM error: {...}
❌ Error: [error message]
```

### 3. اختبار يدوي

#### أ. اختبار FCM Token
1. افتح التطبيق
2. شوف الـ logs: `adb logcat | findstr "🔔 FCM Token"`
3. تأكد إن Token موجود في Supabase

#### ب. اختبار Realtime (التطبيق مفتوح)
1. افتح التطبيق على جهازين
2. من جهاز المساعد: اعمل معاملة
3. على جهاز المدير: المفروض يظهر إشعار فوراً

#### ج. اختبار FCM Push (التطبيق مقفول)
1. افتح التطبيق مرة واحدة (عشان يحفظ Token)
2. اقفل التطبيق تماماً
3. من جهاز المساعد: اعمل معاملة
4. المفروض يظهر إشعار على جهاز المدير

---

## 🐛 حل المشاكل الشائعة

### المشكلة 1: الإشعارات مش شغالة خالص

**الحل:**
1. تأكد إن Firebase مضبوط صح:
   ```bash
   # تحقق من وجود google-services.json
   ls android/app/google-services.json
   ```

2. تأكد إن FCM Token بيتحفظ:
   ```sql
   SELECT * FROM fcm_tokens;
   ```

3. تأكد إن Edge Function شغال:
   - روح Supabase Dashboard → Edge Functions
   - شوف الـ Logs

### المشكلة 2: الإشعارات شغالة جوا التطبيق بس

**السبب:** FCM مش مضبوط أو Edge Function مش شغال

**الحل:**
1. تأكد إن `FIREBASE_SERVICE_ACCOUNT` secret موجود في Edge Function
2. تأكد إن الـ secret فيه الـ JSON الكامل (مش جزء منه)
3. شوف Edge Function logs عشان تشوف الـ errors

### المشكلة 3: الإشعارات بتظهر بعنوان "Flutter"

**السبب:** AndroidManifest.xml مش مضبوط

**الحل:**
تأكد إن الكود ده موجود في `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="fcm_channel" />

<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@mipmap/launcher_icon" />
```

### المشكلة 4: Edge Function بيرجع "No FCM token found"

**السبب:** Token مش محفوظ في قاعدة البيانات

**الحل:**
1. افتح التطبيق مرة واحدة
2. انتظر 5-10 ثواني
3. تحقق من الـ logs: `adb logcat | findstr "Token saved"`
4. تحقق من قاعدة البيانات:
   ```sql
   SELECT * FROM fcm_tokens WHERE device = 'manager';
   ```

### المشكلة 5: Edge Function بيرجع "FCM error: 401"

**السبب:** Firebase Service Account مش صحيح

**الحل:**
1. تأكد إن نزلت الـ Service Account JSON من Firebase Console
2. تأكد إن نسخت **كل** محتوى الملف (مش جزء منه)
3. تأكد إن الـ secret اسمه `FIREBASE_SERVICE_ACCOUNT` بالظبط

---

## 📊 الكود المهم

### 1. إرسال إشعار من Repository

```dart
// في lib/repositories/client/supabase_client_repository.dart

void _notifyPushNotification(Map<String, dynamic> payment) {
  Future.microtask(() async {
    try {
      debugPrint('🔔 Preparing push notification payload...');
      
      final payload = {
        'type': 'INSERT',
        'table': 'log',
        'record': {
          'client_id': payment['client_id'],
          'creator': SupabaseAuthentication.myUser!.id,
          'price': payment['bills'],
          'transaction_type': payment['transaction_type'],
          'system_type': payment['system_type'],
          'account_id': AccountClientInfo.to.currentAccount.id,
          'phone_id': payment['phone_id'],
        },
      };
      
      final response = await _clinet.functions.invoke(
        'notify-on-log',
        body: payload,
      );
      
      debugPrint('🔔 Edge Function response: ${response.data}');
    } catch (e) {
      debugPrint('🔔 ❌ Push notification error: $e');
    }
  });
}
```

### 2. Edge Function (TypeScript)

```typescript
// في supabase_edge_function_notify_on_log.ts

Deno.serve(async (req: Request) => {
  const payload = await req.json();
  const record = payload.record;

  // Only notify for assistant transactions
  if (record.creator !== 2) {
    return new Response(JSON.stringify({ skipped: true }));
  }

  // Get FCM token
  const { data: tokenRow } = await supabase
    .from('fcm_tokens')
    .select('token')
    .eq('device', 'manager')
    .single();

  if (!tokenRow?.token) {
    return new Response(JSON.stringify({ error: 'no token' }));
  }

  // Send FCM notification
  const accessToken = await getFirebaseAccessToken();
  const fcmResponse = await fetch(fcmUrl, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token: tokenRow.token,
        notification: {
          title: 'Phone System',
          body: `معاملة جديدة...`,
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channel_id: 'fcm_channel',
            icon: 'launcher_icon',
            color: '#2196F3',
          },
        },
      },
    }),
  });

  return new Response(JSON.stringify({ success: true }));
});
```

---

## ✅ Checklist النهائي

قبل ما تبني APK، تأكد من:

- [ ] Firebase project مضبوط
- [ ] `google-services.json` موجود في `android/app/`
- [ ] جدول `fcm_tokens` موجود في Supabase
- [ ] Realtime مفعّل على جدول `log`
- [ ] Edge Function `notify-on-log` deployed
- [ ] `FIREBASE_SERVICE_ACCOUNT` secret موجود في Edge Function
- [ ] AndroidManifest.xml فيه FCM metadata
- [ ] الكود في `supabase_client_repository.dart` بينادي `_notifyPushNotification()`

---

## 🎉 الخلاصة

النظام دلوقتي يدعم:
- ✅ إشعارات فورية عند فتح التطبيق (Realtime)
- ✅ إشعارات push عند إغلاق التطبيق (FCM)
- ✅ Badge counter على أيقونة التطبيق
- ✅ إشعارات مخصصة بعنوان "Phone System" وأيقونة التطبيق
- ✅ إشعارات فقط لمعاملات المساعد (creator = 2)

**آخر تحديث:** 2026-04-27
