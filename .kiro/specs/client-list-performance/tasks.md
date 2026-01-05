# Implementation Plan: تحسين أداء صفحة قائمة العملاء

## Overview

تنفيذ تحسينات الأداء على مراحل، بدءاً من الأساسيات (data loading) وصولاً للتحسينات المتقدمة (animations, caching).

## Tasks

- [x] 1. Phase 1: تحسين Data Loading
  - [x] 1.1 إضافة method جديد في Repository لجلب basic data فقط
    - إنشاء `getBasicClientsByAccount()` في `SupabaseClientRepository`
    - يجلب فقط: id, name, total_cash, account_id, expire_date
    - بدون nested relations (phone, system, logs)
    - _Requirements: 1.1, 7.2_
  
  - [x] 1.2 إضافة method جديد للـ Realtime stream بـ basic data
    - إنشاء `getBasicRealtimeClients()` في `SupabaseClientRepository`
    - Stream يرجع basic data فقط
    - بدون nested relations
    - _Requirements: 1.1_
  
  - [x] 1.3 تعديل Client model لدعم basic و full data
    - إضافة factory `Client.basic()` للـ basic data
    - إضافة factory `Client.full()` للـ full data
    - إضافة flag `_isFullDataLoaded`
    - _Requirements: 1.1, 1.2_
  
  - [x] 1.4 إضافة cache للـ full client data في Controller
    - إضافة `Map<int, Client> _fullDataCache`
    - إضافة method `getFullClientData(int clientId)`
    - تحديد حجم الـ cache بـ 50 item maximum
    - _Requirements: 1.2, 6.5_
  
  - [x] 1.5 تحديث Controller ليستخدم basic data في الـ initial load
    - تعديل `onReady()` لاستخدام `getBasicClientsByAccount()`
    - تعديل `setupRealtimeSubscription()` لاستخدام `getBasicRealtimeClients()`
    - _Requirements: 1.1, 7.2_

- [x] 2. Phase 2: تحسين Realtime Updates
  - [x] 2.1 إضافة throttling للـ Realtime updates
    - إضافة `_realtimeThrottle` Timer
    - إضافة `_lastRealtimeUpdate` DateTime
    - تحديد minimum 10 seconds بين updates
    - _Requirements: 1.5_
  
  - [x] 2.2 إضافة batching للـ multiple updates
    - تجميع updates اللي تحصل خلال 2 ثانية
    - تطبيق آخر update فقط
    - _Requirements: 1.3_
  
  - [x] 2.3 إيقاف Realtime updates أثناء bulk operations
    - إضافة flag `_isProcessingBulkOperation`
    - إيقاف updates في `automaticPaymentAtStartup()`
    - استئناف updates بعد انتهاء العملية
    - _Requirements: 1.4_

- [x] 3. Phase 3: إزالة Animation Controllers من الكاردات
  - [x] 3.1 إزالة AnimationController من ModernClientCard
    - حذف `_animationController` من `_ModernClientCardState`
    - حذف `_scaleAnimation` و `_fadeAnimation`
    - حذف `initState()` و `dispose()` المتعلقة بالـ animations
    - _Requirements: 2.1_
  
  - [x] 3.2 تحويل ModernClientCard لـ StatelessWidget
    - تحويل `ModernClientCard` من StatefulWidget لـ StatelessWidget
    - إزالة State class
    - _Requirements: 2.1, 8.3_
  
  - [x] 3.3 إبقاء animation واحدة للـ header فقط
    - الـ `_animationController` في `AllClientsPage` يبقى للـ header فقط
    - إزالة staggered animations من الكاردات
    - _Requirements: 2.4, 2.5_

- [x] 4. Phase 4: تحسين Widget Rebuilds
  - [x] 4.1 استبدال Obx() بـ GetBuilder مع ids محددة
    - استبدال `Obx()` في `AllClientsPage.build()`
    - إضافة `GetBuilder` مع id: 'client-list'
    - إضافة `GetBuilder` مع id: 'toolbar'
    - _Requirements: 3.1_
  
  - [x] 4.2 إضافة targeted rebuild لكل كارد
    - إضافة `GetBuilder` مع id: 'client-${client.id}' لكل كارد
    - تحديث `_handleSelection()` لاستخدام `update(['client-${client.id}'])`
    - _Requirements: 3.2_
  
  - [x] 4.3 فصل Header لـ const widget
    - إنشاء `_ClientPageHeader` كـ const StatelessWidget
    - نقل كل الـ header content للـ widget الجديد
    - _Requirements: 3.4, 3.5_
  
  - [x] 4.4 فصل Toolbar لـ widget منفصل
    - إنشاء `_ClientToolbar` كـ StatelessWidget
    - نقل كل الـ toolbar content للـ widget الجديد
    - _Requirements: 3.3, 3.5_
  
  - [x] 4.5 إضافة RepaintBoundary لكل كارد
    - لف كل كارد بـ `RepaintBoundary`
    - _Requirements: 8.2_

- [x] 5. Phase 5: تحسين البحث
  - [x] 5.1 إضافة search caching في Controller
    - إضافة `Map<String, List<Client>> _searchCache`
    - إضافة `Timer? _searchCacheCleanup`
    - _Requirements: 4.4_
  
  - [x] 5.2 تنفيذ optimized search method
    - إنشاء `searchClients(String query)` method
    - استخدام الـ cache للـ repeated queries
    - استخدام normalized Arabic text
    - _Requirements: 4.2, 4.3_
  
  - [x] 5.3 إضافة cache cleanup بعد 5 دقائق
    - إضافة `_scheduleCacheCleanup()` method
    - تنظيف الـ cache بعد 5 دقائق من آخر استخدام
    - _Requirements: 6.4_
  
  - [x] 5.4 تحديث search debouncing لـ 300ms
    - تعديل `searchQueryChanged()` لاستخدام 300ms delay
    - _Requirements: 4.1_
  
  - [x] 5.5 استخدام الـ optimized search في الصفحة
    - استبدال `_getSmartFilteredClients()` بـ `controller.searchClients()`
    - _Requirements: 4.3_

- [x] 6. Phase 6: تحسين ListView Performance
  - [x] 6.1 إنشاء OptimizedClientListView widget
    - إنشاء `_OptimizedClientListView` StatelessWidget
    - استخدام `ListView.builder` مع optimizations
    - _Requirements: 5.1_
  
  - [x] 6.2 إضافة ListView optimizations
    - `cacheExtent: 800`
    - `addAutomaticKeepAlives: false`
    - `addRepaintBoundaries: true`
    - `itemExtentBuilder: (index, dimensions) => 140.0`
    - _Requirements: 5.2, 5.3, 5.4_
  
  - [x] 6.3 استبدال ListView الحالي بالـ optimized version
    - استبدال `ModernClientListView` بـ `_OptimizedClientListView`
    - _Requirements: 5.1_

- [x] 7. Phase 7: تحسين Client Card Widget
  - [x] 7.1 إنشاء OptimizedClientCard widget
    - إنشاء `_OptimizedClientCard` StatelessWidget
    - استخدام `RepaintBoundary`
    - استخدام `GetBuilder` مع id محدد
    - _Requirements: 8.1, 8.2, 8.3_
  
  - [x] 7.2 فصل Card Content لـ widget منفصل
    - إنشاء `_ClientCardContent` StatelessWidget
    - نقل كل الـ UI logic للـ widget الجديد
    - _Requirements: 8.3_
  
  - [x] 7.3 استخدام const للـ decorations والـ styles
    - تحويل كل الـ static decorations لـ const
    - تحويل كل الـ TextStyle لـ const
    - _Requirements: 8.4_
  
  - [x] 7.4 تحسين Color calculations
    - cache الـ base colors في static list
    - حساب الـ gradient colors مرة واحدة
    - _Requirements: 8.4_
  
  - [x] 7.5 تقليل استخدام Opacity و ClipRRect
    - استبدال `withOpacity()` بـ `withValues(alpha:)`
    - تقليل استخدام `ClipRRect` حيث ممكن
    - _Requirements: 8.5_
  
  - [x] 7.6 تحديث card tap handler لجلب full data
    - تعديل `_handleTap()` لاستخدام `getFullClientData()`
    - جلب full data قبل فتح الـ details sheet
    - _Requirements: 1.2, 10.2_

- [x] 8. Phase 8: Memory Management
  - [x] 8.1 تحسين Controller disposal
    - التأكد من cancel كل الـ timers في `onClose()`
    - التأكد من cancel كل الـ streams في `onClose()`
    - التأكد من clear كل الـ caches في `onClose()`
    - _Requirements: 6.1, 6.2_
  
  - [x] 8.2 إضافة cache size limiting
    - تحديد maximum 50 items في `_fullDataCache`
    - إزالة أقدم item عند تجاوز الحد
    - _Requirements: 6.5_
  
  - [x] 8.3 إضافة weak references للـ cached data
    - استخدام `WeakReference` للـ cached clients (optional)
    - _Requirements: 6.3_

- [x] 9. Checkpoint - اختبار الأداء الأولي
  - تشغيل التطبيق وقياس:
    - Initial load time
    - Scroll FPS
    - Search response time
    - Memory usage
  - مقارنة بالـ performance targets
  - إذا في مشاكل، اسأل المستخدم

- [x] 10. Phase 9: Error Handling
  - [x] 10.1 إضافة error handling للـ network requests
    - إضافة timeout 20 seconds
    - إضافة retry button
    - إضافة clear error messages
    - _Requirements: 7.4_
  
  - [x] 10.2 إضافة error handling للـ realtime connection
    - Graceful degradation لـ manual refresh
    - Connection status indicator
    - Auto-reconnect مع exponential backoff
    - _Requirements: Error Handling_
  
  - [x] 10.3 إضافة error handling للـ search
    - Handle invalid input
    - Handle Arabic normalization errors
    - Clear cache on errors
    - _Requirements: Error Handling_

- [x] 11. Phase 10: Loading States
  - [x] 11.1 إضافة skeleton loaders للـ cards
    - إنشاء `_SkeletonCard` widget
    - عرض skeleton loaders أثناء initial load
    - _Requirements: 7.1_
  
  - [x] 11.2 إضافة loading indicators للـ lazy-loaded data
    - عرض loading indicator عند فتح client details
    - عرض loading indicator في الـ card عند الحاجة
    - _Requirements: 10.4_

- [x] 12. Phase 11: Progressive Enhancement
  - [x] 12.1 تنفيذ lazy loading للـ full data
    - جلب full data فقط عند فتح client details
    - _Requirements: 10.2_
  
  - [x] 12.2 إضافة prioritization للـ visible items
    - تحميل visible items أولاً
    - تحميل off-screen items في الخلفية
    - _Requirements: 10.3_
  
  - [x] 12.3 إضافة caching للـ loaded details
    - cache الـ full data بعد تحميله
    - استخدام الـ cache للـ quick re-access
    - _Requirements: 10.5_

- [x] 13. Final Checkpoint - اختبار شامل
  - تشغيل كل الـ tests
  - قياس الأداء النهائي
  - مقارنة بالـ performance targets
  - التأكد من عدم وجود memory leaks
  - اسأل المستخدم إذا كل شيء يعمل بشكل صحيح

## Notes

- كل phase مستقل ويمكن اختباره بشكل منفصل
- ابدأ بالـ phases الأساسية (1-3) قبل الانتقال للـ advanced optimizations
- اختبر الأداء بعد كل phase للتأكد من التحسين
- استخدم performance profiler في Flutter DevTools
- راقب memory usage أثناء التطوير
- Tasks marked with `*` are optional for MVP but recommended for production
