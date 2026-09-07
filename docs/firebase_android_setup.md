# دليل الإعداد اليدوي لـ Firebase على نظام Android (MoviesApp)

يوثق هذا الدليل الخطوات اليدوية الفعلية المطلوبة لتهيئة وتفعيل خدمات Firebase (المصادقة Authentication وقاعدة بيانات Cloud Firestore) لمنصة Android في تطبيق **MoviesApp**.

> [!IMPORTANT]
> **تنبيه سياسة التنفيذ البرمجي الصارم (Strict Code-Only):**
> تم إعداد وتحديث ملفات البناء البرمجية محلياً داخل المشروع. جميع الخطوات التالية يتم تنفيذها يدوياً بواسطة المطور عبر لوحة تحكم Firebase Console وبيئة Android Studio، دون تشغيل أوامر تلقائية.

---

## 1. معلومات التطبيق المؤكدة من الشيفرة المصدرية

تم تأكيد المعرفات التالية من ملف البناء [`android/app/build.gradle.kts`](../android/app/build.gradle.kts):
- **معرف الحزمة (Application ID):** `com.route.movies_app`
- **نطاق الحزمة (Namespace):** `com.route.movies_app`
- **المسار المستهدف لملف الإعدادات:** `android/app/google-services.json`

> [!WARNING]
> لا تقم بتغيير `applicationId` في ملفات المشروع لمطابقة مشروع Firebase غير متعلق. يجب أن يُسجل التطبيق في Firebase بنفس المعرف المذكور أعلاه حصراً (`com.route.movies_app`).

---

## 2. الخطوات اليدوية المطلوبة في Firebase Console

### الخطوة 1: فتح أو إنشاء مشروع Firebase
1. انتقل إلى [Firebase Console](https://console.firebase.google.com/).
2. افتح مشروعك الحالي المخصص للتطبيق أو أنشئ مشروعاً جديداً باسم (مثل `MoviesApp`).

---

### الخطوة 2: تسجيل تطبيق Android
1. من الصفحة الرئيسية للمشروع (Project Overview)، اضغط على أيقونة **Android** لإضافة تطبيق جديد (أو من **Project Settings** > قسم **Your apps** > **Add app**).
2. في حقل **Android package name**، أدخل بدقة:
   ```
   com.route.movies_app
   ```
3. في حقل **App nickname** (اختياري)، يمكنك كتابة: `Movies App Android`.

---

### الخطوة 3: استخراج وإضافة بصمة شهادة التوقيع (Debug SHA-1) لـ Google Sign-In
تتطلب خدمة تسجيل الدخول بواسطة جوجل (Google Sign-In) وجود بصمة شهادة التوقيع الرقمية `SHA-1` مسجلة في التطبيق على Firebase Console:

#### استخراج البصمة عبر Android Studio:
1. افتح مشروع `MoviesApp` في **Android Studio**.
2. من اللوحة الجانبية اليمنى، افتح شريط **Gradle**.
3. انتقل إلى: `movies_app` > `app` > `Tasks` > `android`.
4. اضغط نقراً مزدوجاً على مهمة **`signingReport`**.
5. ستفتح نافذة **Run / Gradle Console** في الأسفل وتطبع بصمات الشهادات.
6. انسخ قيمة **SHA-1** المقابلة لـ `Variant: debugAndroidTest / debug` و `Config: debug` (وكذلك **SHA-256** إن أردت).

> **طريقة بديلة عبر سطر الأوامر الخاص بك (خارج بيئة الوكيل):**
> ```bash
> keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
> ```
> *(على نظام Windows المسار عادةً يكون: `%USERPROFILE%\.android\debug.keystore`)*

#### إضافة البصمة في Firebase Console:
- الصق بصمة `SHA-1` في حقل **Debug signing certificate SHA-1** أثناء التسجيل، أو لاحقاً من **Project Settings** > التطبيق `com.route.movies_app` > قسم **SHA certificate fingerprints** > **Add fingerprint**.

---

### الخطوة 4: تفعيل موفري المصادقة (Authentication Sign-in Providers)
1. من القائمة الجانبية في Firebase Console، انتقل إلى **Build** > **Authentication**.
2. إذا لم تكن الخدمة مفعلة، اضغط **Get Started**.
3. انتقل إلى تبويب **Sign-in method**:
   - **Email/Password:**
     - اضغط على `Email/Password`.
     - فعّل خيار `Enable`. (اترك خيار `Email link` غير مفعل).
     - اضغط **Save**.
   - **Google:**
     - اضغط على `Google`.
     - فعّل خيار `Enable`.
     - حدد بريد الدعم الخاص بالمشروع (`Project support email`).
     - اضغط **Save**.

---

### الخطوة 5: تنزيل ملف `google-services.json` ووضعه في مكانه المحدد
1. بعد تسجيل التطبيق وإضافة بصمة `SHA-1` وتفعيل Google Sign-In، قم بتنزيل ملف **`google-services.json`** المحدث من إعدادات المشروع في Firebase Console.
2. ضع الملف المحمّل في المسار المخصص له تماماً:
   ```
   android/app/google-services.json
   ```

> [!CAUTION]
> - تم تطبيق إضافة Google Services Plugin (`com.google.gms.google-services`) في إعدادات Gradle. إذا حاولت بناء التطبيق دون وجود ملف `google-services.json` الفعلي في مسار `android/app/`، فسيتوقف بناء Gradle برسالة خطأ تفيد بغياب الملف.
> - ملف `google-services.json` مستبعد تلقائياً من نظام Git ضمن ملف [`.gitignore`](../.gitignore) لحماية مفاتيح الاعتماد الحساسة.

---

### الخطوة 6: إنشاء قاعدة بيانات Cloud Firestore
1. من القائمة الجانبية، انتقل إلى **Build** > **Firestore Database**.
2. اضغط **Create database**.
3. اختر موقع الخادم (Database location) الأقرب لجمهورك (مثل `europe-west1` أو `us-central1`).
4. اختر وضع الأمان المبدئي (Start in production mode أو Test mode).
5. اضغط **Enable**.

---

### الخطوة 7: مراجعة ونشر قواعد الأمان (Security Rules)
يحتوي المشروع محلياً على ملف القواعد الجاهز والمكتوب بأعلى درجات الأمان وحماية الخصوصية: [`firestore.rules`](../firestore.rules).

1. في Firebase Console، ضمن صفحة **Firestore Database**، افتح تبويب **Rules**.
2. استبدل محتوى المحرر بالكامل بمحتوى الملف المحلي [`firestore.rules`](../firestore.rules):
   ```javascript
   rules_version = '2';

   service cloud.firestore {
     match /databases/{database}/documents {

       function isAuthenticated() {
         return request.auth != null;
       }

       function isOwner(uid) {
         return isAuthenticated() && request.auth.uid == uid;
       }

       match /users/{uid} {
         allow read: if isOwner(uid);
         allow create, update: if isOwner(uid)
           && (request.resource.data.uid == uid || !('uid' in request.resource.data));
         allow delete: if isOwner(uid);

         match /watchlist/{movieId} {
           allow read: if isOwner(uid);
           allow create, update: if isOwner(uid)
             && request.resource.data.movieId is int
             && string(request.resource.data.movieId) == movieId;
           allow delete: if isOwner(uid);
         }

         match /history/{movieId} {
           allow read: if isOwner(uid);
           allow create, update: if isOwner(uid)
             && request.resource.data.movieId is int
             && string(request.resource.data.movieId) == movieId;
           allow delete: if isOwner(uid);
         }
       }

       match /{document=**} {
         allow read, write: if false;
       }
     }
   }
   ```
3. اضغط **Publish**.

> [!WARNING]
> لا تقم أبداً بوضع قواعد عامة مفتوحة (`allow read, write: if true;`)؛ فالقواعد أعلاه تضمن عزل بيانات كل مستخدم (`users/{uid}`) وقوائم مشاهدته وتاريخه بحيث لا يمكن لأي شخص غير صاحب الحساب قراءتها أو تعديلها أو حذفها.

---

## 3. التحقق اليدوي اللاحق بواسطة المطور (USER-PERFORMED VALIDATION)

بعد إتمام الخطوات أعلاه ووضع الملف في مكانه:
1. **جلب الحزم والتحقق:**
   - افتح الطرفية وشغّل:
     ```bash
     flutter pub get
     flutter analyze
     ```
2. **تشغيل الاختبارات البرمجية:**
   ```bash
   flutter test
   ```
3. **التشغيل على جهاز حقيقي أو محاكي:**
   ```bash
   flutter run
   ```
4. **التحقق الوظيفي:**
   - تجربة تسجيل مستخدم جديد بالبريد وكلمة المرور.
   - تجربة تسجيل الدخول بحساب Google.
   - حفظ أفلام في قائمة المشاهدة ومراجعة انعكاسها في Firestore Console تحت المجموعة الفرعية `users/{uid}/watchlist`.
   - تجربة حذف الحساب مع اختبار إدخال كلمة مرور تحتوي على مسافات أولية أو نهائية للتأكد من وصولها سليمة لـ Firebase Auth.
