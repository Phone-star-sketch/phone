# Requirements Document - App Performance Audit & Optimization

## Introduction

مراجعة شاملة للتطبيق من أول `main.dart` وتتبع كل الصفحات لتحسين الأداء وإزالة الكود الزائد وإصلاح المشاكل.

## Glossary

- **System**: التطبيق بالكامل
- **Performance**: سرعة التطبيق واستجابته
- **Code_Smell**: كود مش منطقي أو محتاج تحسين
- **Deprecated_API**: APIs قديمة محتاج نستبدلها
- **Unused_Code**: كود مش مستخدم ومحتاج نشيله
- **Animation_Controller**: Controllers للأنيميشنز
- **Memory_Leak**: تسريب في الذاكرة

## Requirements

### Requirement 1: تنظيف main.dart

**User Story:** كمطور، أريد main.dart نظيف ومحسّن، حتى يكون entry point التطبيق سريع وواضح.

#### Acceptance Criteria

1. WHEN التطبيق يبدأ THEN يجب إزالة كل الـ deprecated APIs (background, onBackground, withOpacity)
2. WHEN التطبيق يبدأ THEN يجب إزالة كل الـ unused imports
3. WHEN التطبيق يبدأ THEN يجب استخدام const حيثما أمكن للأداء
4. WHEN التطبيق يبدأ THEN يجب تبسيط الـ error handling في web initialization
5. WHEN التطبيق يبدأ THEN يجب إزالة الـ commented code الزائد

### Requirement 2: تحسين Backend Services Initialization

**User Story:** كمطور، أريد backend services initialization محسّن، حتى يكون التطبيق يبدأ أسرع.

#### Acceptance Criteria

1. WHEN الـ services تتهيأ THEN يجب إزالة كل الـ unused imports
2. WHEN الـ services تتهيأ THEN يجب إزالة الـ duplicate authentication initialization
3. WHEN الـ services تتهيأ THEN يجب استبدال print() بـ developer.log()
4. WHEN الـ services تتهيأ THEN يجب إضافة proper error messages
5. WHEN الـ services تتهيأ THEN يجب تحسين الـ timeout handling

### Requirement 3: تحسين Welcome Pages (Animations)

**User Story:** كمطور، أريد welcome pages محسّنة، حتى تكون الأنيميشنز smooth ومش بتستهلك موارد زيادة.

#### Acceptance Criteria

1. WHEN المستخدم يفتح welcome page THEN يجب تقليل عدد الـ AnimationControllers (حالياً 6 controllers)
2. WHEN المستخدم يفتح welcome page THEN يجب استبدال withOpacity بـ withValues
3. WHEN المستخدم يفتح welcome page THEN يجب استخدام const للـ widgets الثابتة
4. WHEN المستخدم يفتح welcome page THEN يجب تقليل عدد الـ floating orbs (حالياً 8 + 15 sparkles)
5. WHEN المستخدم يفتح welcome page THEN يجب إزالة الـ superman animation الزائدة
6. WHEN المستخدم يفتح welcome page THEN يجب تحسين الـ gradient animations
7. WHEN المستخدم يغادر الصفحة THEN يجب التأكد من dispose كل الـ controllers

### Requirement 4: تحسين Theme Management

**User Story:** كمطور، أريد theme management بسيط وفعال، حتى لا يؤثر على الأداء.

#### Acceptance Criteria

1. WHEN الـ theme يتغير THEN يجب تحميل الـ theme من SharedPreferences مرة واحدة فقط
2. WHEN الـ theme يتغير THEN يجب عدم إعادة بناء كل الـ widgets
3. WHEN الـ theme يتغير THEN يجب استخدام const للـ theme options
4. WHEN التطبيق يبدأ THEN يجب تحسين الـ theme loading

### Requirement 5: مراجعة Auth Flow

**User Story:** كمطور، أريد auth flow واضح ومباشر، حتى يكون المستخدم يسجل دخول بسرعة.

#### Acceptance Criteria

1. WHEN المستخدم يسجل دخول THEN يجب إزالة الـ unnecessary animations
2. WHEN المستخدم يسجل دخول THEN يجب تحسين الـ navigation transitions
3. WHEN المستخدم يسجل دخول THEN يجب إزالة الـ audio player من welcome page
4. WHEN المستخدم يسجل دخول THEN يجب تبسيط الـ button animations

### Requirement 6: مراجعة Client List Performance

**User Story:** كمطور، أريد client list سريعة، حتى يكون المستخدم يشوف العملاء فوراً.

#### Acceptance Criteria

1. WHEN المستخدم يفتح client list THEN يجب استخدام الـ database function الجديدة
2. WHEN المستخدم يفتح client list THEN يجب تحسين الـ pagination
3. WHEN المستخدم يفتح client list THEN يجب تحسين الـ search
4. WHEN المستخدم يفتح client list THEN يجب تحسين الـ realtime updates

### Requirement 7: إزالة Unused Code

**User Story:** كمطور، أريد إزالة كل الكود الزائد، حتى يكون الـ codebase نظيف وسهل الصيانة.

#### Acceptance Criteria

1. WHEN أراجع الكود THEN يجب إزالة كل الـ commented imports
2. WHEN أراجع الكود THEN يجب إزالة كل الـ unused variables
3. WHEN أراجع الكود THEN يجب إزالة كل الـ duplicate code
4. WHEN أراجع الكود THEN يجب إزالة كل الـ unused methods

### Requirement 8: تحسين Memory Management

**User Story:** كمطور، أريد memory management محسّن، حتى لا يحصل memory leaks.

#### Acceptance Criteria

1. WHEN الـ controllers تتهيأ THEN يجب التأكد من dispose في onClose
2. WHEN الـ streams تتهيأ THEN يجب التأكد من cancel في onClose
3. WHEN الـ timers تتهيأ THEN يجب التأكد من cancel في onClose
4. WHEN الـ audio players تتهيأ THEN يجب التأكد من dispose في onClose

### Requirement 9: تحسين Build Performance

**User Story:** كمطور، أريد build performance محسّن، حتى يكون الـ UI يتحدث بسرعة.

#### Acceptance Criteria

1. WHEN الـ widgets تتبني THEN يجب استخدام const حيثما أمكن
2. WHEN الـ widgets تتبني THEN يجب تقليل عدد الـ rebuilds
3. WHEN الـ widgets تتبني THEN يجب استخدام RepaintBoundary للـ complex widgets
4. WHEN الـ widgets تتبني THEN يجب تحسين الـ AnimatedBuilder usage

### Requirement 10: تحسين Navigation

**User Story:** كمطور، أريد navigation سريع وسلس، حتى يكون المستخدم ينتقل بين الصفحات بسهولة.

#### Acceptance Criteria

1. WHEN المستخدم ينتقل بين الصفحات THEN يجب تقليل الـ transition duration
2. WHEN المستخدم ينتقل بين الصفحات THEN يجب استخدام الـ appropriate transition type
3. WHEN المستخدم ينتقل بين الصفحات THEN يجب إزالة الـ unnecessary animations
4. WHEN المستخدم ينتقل بين الصفحات THEN يجب تحسين الـ route management

### Requirement 11: مراجعة شاملة لكل الصفحات

**User Story:** كمطور، أريد مراجعة كل صفحات التطبيق، حتى أتأكد من عدم وجود مشاكل أداء.

#### Acceptance Criteria

1. WHEN أراجع account_view.dart THEN يجب تقليل عدد الـ floating particles (حالياً 15 + 25 = 40)
2. WHEN أراجع account_details.dart THEN يجب تحسين الـ navigation bar animations
3. WHEN أراجع all_clinets_page.dart THEN يجب التأكد من استخدام الـ optimized client list
4. WHEN أراجع profit_management_page.dart THEN يجب تحسين الـ chart rendering
5. WHEN أراجع dues_management.dart THEN يجب تحسين الـ search performance
6. WHEN أراجع clients_recets.dart THEN يجب تحسين الـ PDF generation
7. WHEN أراجع follow.dart THEN يجب تحسين الـ realtime updates
8. WHEN أراجع system_list.dart THEN يجب تحسين الـ image loading
9. WHEN أراجع offers.dart THEN يجب تحسين الـ expired systems detection
10. WHEN أراجع login_page.dart THEN يجب تبسيط الـ animations

### Requirement 12: إصلاح Deprecated APIs في كل الملفات

**User Story:** كمطور، أريد إزالة كل الـ deprecated APIs، حتى يكون الكود متوافق مع أحدث إصدار من Flutter.

#### Acceptance Criteria

1. WHEN أراجع الكود THEN يجب استبدال كل withOpacity() بـ withValues(alpha:) (200+ مكان)
2. WHEN أراجع الكود THEN يجب استبدال كل MaterialStateProperty بـ WidgetStateProperty
3. WHEN أراجع الكود THEN يجب استبدال كل background بـ surface
4. WHEN أراجع الكود THEN يجب استبدال كل onBackground بـ onSurface

### Requirement 13: تحسين Logging في كل الملفات

**User Story:** كمطور، أريد logging محسّن، حتى أقدر أتتبع المشاكل بسهولة.

#### Acceptance Criteria

1. WHEN أراجع الكود THEN يجب استبدال كل print() بـ developer.log() (65+ مكان)
2. WHEN أراجع الكود THEN يجب إضافة proper error context
3. WHEN أراجع الكود THEN يجب استخدام kDebugMode للـ debug logs
4. WHEN أراجع الكود THEN يجب إزالة الـ debug prints من production code

### Requirement 14: تحسين الصفحات الإضافية

**User Story:** كمطور، أريد تحسين الصفحات الإضافية المكتشفة، حتى يكون التطبيق متسق ومحسّن بالكامل.

#### Acceptance Criteria

1. WHEN أراجع user_management_page.dart THEN يجب إزالة print() واستبدالها بـ developer.log()
2. WHEN أراجع notification_settings_page.dart THEN يجب إصلاح deprecated APIs (background, activeColor)
3. WHEN أراجع main_page.dart THEN يجب إصلاح withOpacity() وإضافة const
4. WHEN أراجع client_list_view.dart THEN يجب إزالة unused imports (6 imports) وإصلاح immutable class
5. WHEN أراجع print_clients_receipts.dart THEN يجب إزالة unused imports (4 imports) وunused variables
6. WHEN أراجع sheet_of_recets.dart THEN يجب تحسين Excel generation performance
7. WHEN أراجع stats_view.dart THEN يجب إصلاح async context usage
8. WHEN أراجع account_management.dart THEN يجب إضافة const وkey parameter

### Requirement 15: إصلاح مشاكل Immutable Classes

**User Story:** كمطور، أريد إصلاح مشاكل immutable classes، حتى يكون الكود متوافق مع best practices.

#### Acceptance Criteria

1. WHEN أراجع ClientListView THEN يجب جعل الـ fields final أو إزالة @immutable
2. WHEN أراجع الكود THEN يجب إضافة key parameters للـ constructors
3. WHEN أراجع الكود THEN يجب استخدام super parameters حيثما أمكن

### Requirement 16: إصلاح مشاكل Async Context

**User Story:** كمطور، أريد إصلاح مشاكل async context، حتى لا يحصل crashes عند استخدام BuildContext.

#### Acceptance Criteria

1. WHEN أستخدم BuildContext في async method THEN يجب إضافة mounted check
2. WHEN أراجع stats_view.dart THEN يجب إصلاح BuildContext usage across async gap
3. WHEN أراجع الكود THEN يجب مراجعة كل async methods التي تستخدم BuildContext
