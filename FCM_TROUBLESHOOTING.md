# 🔧 حل مشكلة الإشعارات - دليل سريع

## 🎯 المشكلة
الإشعارات كانت شغالة قبل كده، دلوقتي مش شغالة خالص (لا جوا ولا برة التطبيق).

## ✅ الحل النهائي

### 1. تبسيط الكود
عملنا التالي:
- ✅ أزلنا `TransactionNotificationService` من `follow.dart` (كان بيتعارض مع FCM)
- ✅ خلينا FCM Service يتولى كل الإشعارات (foreground + background)
- ✅ بسطنا الـ Realtime subscription (بس للـ UI updates)

### 2. التأكد من FCM Token
```sql
-- في Supabase SQL Editor
SELECT * FROM fcm_tokens WHERE device = 'manager';
```

يجب أن يظهر:
```
id | device  | token                                    | created_at
3  | manager | dReGBfMsQYKd3MY1QSypx5:APA91bETdQd_d... | 2026-04-27 14:58:07
```

### 3. تحديث Edge Function

**المهم جداً:** Edge Function لازم يبعت **notification + data** مع بعض:

```typescript
const fcmResponse = await fetch(fcmUrl, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${accessToken}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    message: {
      token: tokenRow.token,
      // ✅ notification field - مهم جداً للـ background/terminated
      notification: {
        title: 'Phone System',
        body: `${typeName} - العميل: ${clientName} - المبلغ: ${record.price} جنيه`,
      },
      // ✅ android config - للتحكم في الشكل
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channel_id: 'fcm_channel',
          icon: 'launcher_icon',
          color: '#2196F3',
        },
      },
      // ✅ data field - للمعلومات الإضافية
      data: {
        clientId: String(record.client_id || ''),
        price: String(record.price || ''),
        type: String(record.transaction_type || ''),
      },
    },
  }),
});
```

### 4. خطوات التنفيذ

#### أ. حدّث Edge Function في Supabase
1. روح: https://supabase.com/dashboard
2. اختار مشروعك → Edge Functions → `notify-on-log`
3. انسخ الكود من `supabase_edge_function_notify_on_log.ts`
4. الصقه في الـ Editor
5. اضغط **Deploy**

#### ب. تأكد من Firebase Service Account
1. في Supabase Dashboard → Edge Functions → `notify-on-log` → Settings
2. تأكد من وجود Secret اسمه: `FIREBASE_SERVICE_ACCOUNT`
3. القيمة لازم تكون الـ JSON الكامل من Firebase Console

#### ج. ابني APK جديد
```bash
flutter clean
flutter pub get
flutter build apk --release
```

#### د. اختبر
1. ثبّت الـ APK على الموبايل
2. افتح التطبيق مرة واحدة (عشان يحفظ FCM token)
3. **اقفل التطبيق تماماً** (swipe من recent apps)
4. من حساب المساعد: اعمل معاملة (تسديد أو إضافة)
5. المفروض يظهر إشعار على الموبايل

---

## 🔍 التشخيص

### 1. فحص FCM Token على الموبايل
```bash
# على Windows
adb logcat | findstr "🔔 FCM Token"

# المفروض تشوف:
# 🔔 FCM Token: dReGBfMsQYKd3MY1QSypx5:APA91bETdQd_d...
# 🔔 FCM: Token saved successfully
```

### 2. فحص Edge Function Logs
في Supabase Dashboard → Edge Functions → `notify-on-log` → Logs

**Logs صحيحة:**
```
📥 Request received
📦 Payload: {...}
📝 Record creator: 2
👤 Client name: [اسم العميل]
🔑 FCM token found
📧 Preparing FCM message: Phone System ...
🔐 Got Firebase access token
✅ FCM sent successfully
```

**Errors محتملة:**
```
❌ No FCM token found → Token مش محفوظ في قاعدة البيانات
❌ FCM error: 401 → Firebase Service Account غلط
❌ FCM error: 404 → Token expired أو invalid
```

### 3. اختبار FCM مباشرة
استخدم Firebase Console لإرسال test notification:

1. روح: https://console.firebase.google.com
2. اختار مشروعك → Cloud Messaging
3. اضغط "Send your first message"
4. Title: `Test`
5. Body: `Testing FCM`
6. Target: Device → الصق الـ FCM token
7. اضغط Send

لو الإشعار ظهر → FCM شغال، المشكلة في Edge Function
لو مظهرش → المشكلة في Firebase setup أو Token

---

## 🐛 المشاكل الشائعة

### المشكلة 1: الإشعار بيظهر في foreground بس
**السبب:** Edge Function مش بيبعت `notification` field

**الحل:**
تأكد إن Edge Function فيه:
```typescript
notification: {
  title: 'Phone System',
  body: '...',
},
```

### المشكلة 2: الإشعار بيظهر بعنوان "Flutter"
**السبب:** AndroidManifest.xml مش مضبوط

**الحل:**
تأكد من وجود ده في `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="fcm_channel" />
```

### المشكلة 3: Token مش بيتحفظ
**السبب:** Supabase مش initialized صح أو RLS policies غلط

**الحل:**
```sql
-- تأكد من الـ RLS policy
CREATE POLICY "Allow all operations on fcm_tokens" 
ON fcm_tokens FOR ALL 
USING (true) 
WITH CHECK (true);
```

### المشكلة 4: Edge Function بيرجع 401
**السبب:** Firebase Service Account JSON غلط

**الحل:**
1. روح Firebase Console → Project Settings → Service accounts
2. اضغط "Generate new private key"
3. نزّل الملف JSON
4. انسخ **كل** محتوى الملف (من `{` لـ `}`)
5. حطه في Supabase Edge Function secret: `FIREBASE_SERVICE_ACCOUNT`

---

## 📊 الكود النهائي

### FCM Service (lib/services/fcm_service.dart)
```dart
// Foreground messages
FirebaseMessaging.onMessage.listen((message) {
  debugPrint('🔔 FCM: Foreground message received');
  
  final notification = message.notification;
  if (notification == null) return;
  
  _localNotifications.show(
    notification.hashCode,
    notification.title ?? 'Phone System',
    notification.body ?? 'معاملة جديدة',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'fcm_channel',
        'FCM Notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        playSound: true,
        enableVibration: true,
      ),
    ),
  );
  incrementBadge();
});
```

### Edge Function (supabase_edge_function_notify_on_log.ts)
```typescript
// Send FCM notification
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
        body: `${typeName} - العميل: ${clientName} - المبلغ: ${record.price} جنيه`,
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
      data: {
        clientId: String(record.client_id || ''),
        price: String(record.price || ''),
        type: String(record.transaction_type || ''),
      },
    },
  }),
});
```

---

## ✅ Checklist النهائي

قبل ما تختبر، تأكد من:

- [ ] FCM token موجود في جدول `fcm_tokens`
- [ ] Edge Function محدّث بالكود الجديد
- [ ] `FIREBASE_SERVICE_ACCOUNT` secret موجود وصحيح
- [ ] AndroidManifest.xml فيه FCM metadata
- [ ] APK جديد متبني ومثبت على الموبايل
- [ ] التطبيق اتفتح مرة واحدة على الأقل
- [ ] اختبرت من حساب المساعد (creator = 2)

---

**آخر تحديث:** 2026-04-27
**الحالة:** تم التبسيط والإصلاح
