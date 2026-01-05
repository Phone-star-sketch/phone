# Requirements Document: تحسين أداء صفحة قائمة العملاء

## Introduction

تحسين أداء صفحة قائمة العملاء (All Clients Page) التي تعاني من بطء وتهنيج عند عرض 440+ عميل. المشكلة الرئيسية هي في:
- Realtime updates المكلفة
- Animation controllers لكل كارد
- Rebuilds غير ضرورية
- البحث البطيء

## Glossary

- **Client_List**: قائمة العملاء المعروضة في الصفحة
- **Realtime_Stream**: البث المباشر من Supabase للتحديثات
- **Animation_Controller**: المتحكم في الحركات (animations) للكاردات
- **GetBuilder**: Widget من GetX لإعادة البناء عند تغيير البيانات
- **Obx**: Widget تفاعلي من GetX
- **Debounce**: تأخير تنفيذ عملية لتقليل عدد المرات
- **Throttle**: تحديد معدل تنفيذ عملية
- **ListView_Builder**: Widget لبناء قوائم كبيرة بكفاءة
- **Pagination**: تقسيم البيانات لصفحات
- **Lazy_Loading**: تحميل البيانات عند الحاجة فقط

## Requirements

### Requirement 1: تحسين Realtime Updates

**User Story:** كمطور، أريد تقليل تكلفة Realtime updates، حتى لا تؤثر على أداء التطبيق.

#### Acceptance Criteria

1. WHEN realtime update يحدث THEN THE System SHALL fetch only basic client data (id, name, total_cash, account_id) without nested relations
2. WHEN user opens client details THEN THE System SHALL fetch full nested data (phone, system, logs) for that specific client only
3. WHEN multiple updates happen within 2 seconds THEN THE System SHALL batch them into single update
4. WHEN bulk operation is running THEN THE System SHALL pause realtime updates completely
5. THE System SHALL use throttling of minimum 10 seconds between full data fetches

### Requirement 2: تحسين Animation Performance

**User Story:** كمستخدم، أريد أن تكون الحركات سلسة بدون تهنيج، حتى أتمكن من التصفح بسهولة.

#### Acceptance Criteria

1. THE System SHALL use single shared AnimationController for all cards instead of individual controllers
2. WHEN list is scrolled THEN THE System SHALL animate only visible cards
3. WHEN card enters viewport THEN THE System SHALL use simple fade-in animation (max 200ms duration)
4. THE System SHALL remove staggered animation delays that create 440 animation controllers
5. WHEN page loads THEN THE System SHALL animate header only, not individual cards

### Requirement 3: تحسين Widget Rebuilds

**User Story:** كمطور، أريد تقليل عدد rebuilds الغير ضرورية، حتى يكون الأداء أفضل.

#### Acceptance Criteria

1. THE System SHALL replace Obx() with GetBuilder with specific ids for targeted updates
2. WHEN client selection changes THEN THE System SHALL rebuild only affected card, not entire list
3. WHEN search query changes THEN THE System SHALL rebuild only filtered list, not header
4. THE System SHALL use const constructors for all static widgets
5. THE System SHALL extract static widgets to separate const widgets

### Requirement 4: تحسين البحث

**User Story:** كمستخدم، أريد أن يكون البحث سريعاً، حتى أجد العملاء بسرعة.

#### Acceptance Criteria

1. WHEN user types in search THEN THE System SHALL debounce input with 300ms delay
2. THE System SHALL use indexed search on normalized Arabic text
3. WHEN search query is empty THEN THE System SHALL return cached full list without filtering
4. THE System SHALL cache search results for repeated queries
5. THE System SHALL search in parallel (name and phone) using efficient string matching

### Requirement 5: تحسين ListView Performance

**User Story:** كمستخدم، أريد أن يكون التمرير سلساً، حتى أتصفح القائمة بسهولة.

#### Acceptance Criteria

1. THE System SHALL use ListView.builder with proper itemExtent or prototypeItem
2. THE System SHALL set cacheExtent to reasonable value (500-1000 pixels)
3. THE System SHALL use addAutomaticKeepAlives: false to reduce memory
4. THE System SHALL use addRepaintBoundaries: true for better painting performance
5. WHEN list has more than 100 items THEN THE System SHALL consider pagination or infinite scroll

### Requirement 6: تحسين Memory Usage

**User Story:** كمطور، أريد تقليل استهلاك الذاكرة، حتى يعمل التطبيق بكفاءة على أجهزة ضعيفة.

#### Acceptance Criteria

1. THE System SHALL dispose all controllers and streams properly in onClose()
2. THE System SHALL cancel all timers and debounce operations on dispose
3. THE System SHALL use weak references for cached data
4. THE System SHALL clear unused cached search results after 5 minutes
5. THE System SHALL limit maximum cached items to 50 clients with full data

### Requirement 7: تحسين Initial Load

**User Story:** كمستخدم، أريد أن تحمل الصفحة بسرعة، حتى أبدأ العمل فوراً.

#### Acceptance Criteria

1. WHEN page loads THEN THE System SHALL show skeleton loaders for cards
2. THE System SHALL load first 50 clients immediately
3. THE System SHALL lazy-load remaining clients in background
4. WHEN initial load fails THEN THE System SHALL show retry button with error message
5. THE System SHALL cache last loaded data for offline viewing

### Requirement 8: تحسين Card Widget

**User Story:** كمطور، أريد تبسيط Card widget، حتى يكون rendering أسرع.

#### Acceptance Criteria

1. THE System SHALL remove unnecessary Container wrappers
2. THE System SHALL use RepaintBoundary for each card
3. THE System SHALL extract card to separate StatelessWidget when possible
4. THE System SHALL use const for all static decorations and styles
5. THE System SHALL minimize use of Opacity and ClipRRect (expensive operations)

### Requirement 9: Monitoring والقياس

**User Story:** كمطور، أريد قياس الأداء، حتى أتأكد من التحسينات.

#### Acceptance Criteria

1. THE System SHALL log initial load time
2. THE System SHALL log scroll performance (FPS)
3. THE System SHALL log search performance
4. THE System SHALL log memory usage
5. THE System SHALL provide performance metrics in debug mode

### Requirement 10: Progressive Enhancement

**User Story:** كمستخدم، أريد أن يعمل التطبيق بشكل تدريجي، حتى أرى البيانات بسرعة.

#### Acceptance Criteria

1. WHEN page loads THEN THE System SHALL show basic client info first (name, phone, balance)
2. THE System SHALL load additional details (systems, logs) on demand
3. WHEN user scrolls THEN THE System SHALL prioritize loading visible items
4. THE System SHALL show loading indicators for items being loaded
5. THE System SHALL cache loaded details for quick re-access
