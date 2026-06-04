# دليلك — تطبيق Flutter (WebView + مزايا أصلية)

تطبيق Flutter يعرض موقع `https://daleelak.site/daleelak.html`، لكنه **ليس مجرد غلاف**:
فيه شريط تنقّل سفلي أصلي ومزايا حقيقية تساعد على تجاوز قاعدة آبل **4.2 (Minimum Functionality)**.

## المزايا الأصلية المضمّنة
| الميزة | الملف | الوصف |
|--------|-------|-------|
| 🏠 الرئيسية (WebView) | `lib/screens/web_screen.dart` | الموقع + شاشة بداية + شاشة عدم اتصال + زر حفظ |
| ⭐ المفضّلة | `lib/screens/favorites_screen.dart` | شاشة أصلية، حفظ محلي يعمل دون إنترنت |
| ⚙️ المزيد | `lib/screens/more_screen.dart` | مشاركة، تقييم، تواصل، خصوصية |
| 🧭 شريط تنقّل سفلي | `lib/main.dart` | واجهة أصلية تحيط بالـ WebView |

> ملاحظة: تمّت إزالة الإشعارات (Firebase) بناءً على الطلب — التطبيق يبني ويعمل
> دون أي إعداد Firebase.

---

## 1) المتطلبات
- تثبيت **Flutter SDK** (إصدار **3.27 أو أحدث**): https://docs.flutter.dev/get-started/install
- لا تحتاج Mac إن كنت ستبني عبر **Codemagic** (انظر الأسفل).

## 2) توليد ملفات المنصّات (مرّة واحدة)
هذا المجلد يحتوي الكود فقط. لإنشاء مجلدّي `android/` و`ios/`:

```bash
cd daleelak_flutter
flutter create --org site.daleelak --project-name daleelak --platforms=android,ios .
flutter pub get
```

> `--org site.daleelak` يجعل معرّف الحزمة `site.daleelak.daleelak`
> (طابقه مع `site.daleelak.app` يدوياً إن أردت — انظر الخطوة 4).

## 3) الأيقونة وشاشة الإقلاع
ضع أيقونة مربعة 1024×1024 في `assets/icon.png` ثم:

```bash
flutter pub run flutter_native_splash:create
flutter pub run flutter_launcher_icons
```

## 4) الأذونات (مهم — وإلا يتعطّل أو يُرفض)

### أندرويد — `android/app/src/main/AndroidManifest.xml`
أضف داخل وسم `<manifest>` (قبل `<application>`):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### iOS — `ios/Runner/Info.plist`
أضف داخل `<dict>` الرئيسي:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>يستخدم تطبيق دليلك موقعك لعرض المحلات والخدمات الأقرب إليك.</string>
<key>NSCameraUsageDescription</key>
<string>يحتاج تطبيق دليلك إلى الكاميرا لرفع الصور داخل الخدمات.</string>
<key>NSMicrophoneUsageDescription</key>
<string>يحتاج تطبيق دليلك إلى الميكروفون عند استخدام المزايا الصوتية.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>يحتاج تطبيق دليلك إلى الصور لرفعها داخل الخدمات.</string>
```
اسم العرض: غيّر `CFBundleDisplayName` إلى `دليلك`.

## 5) التشغيل والاختبار
```bash
flutter run            # على جهاز/محاكي أندرويد متصل
flutter build apk      # ينتج APK للتجربة
```

---

## 6) البناء بدون Mac عبر Codemagic ☁️
1. ارفع المشروع كاملاً على **GitHub** أو **GitLab**.
2. أنشئ حساباً على https://codemagic.io وأضف المستودع.
3. Codemagic سيكتشف ملف `codemagic.yaml` الموجود هنا.
4. **أندرويد**: شغّل `Daleelak Android` → تحصل على APK + AAB فوراً (يبنى على Linux).
5. **iOS**: في إعدادات Codemagic اربط **App Store Connect** (Integrations)، فعّل
   **Automatic code signing**، ثم شغّل `Daleelak iOS` → تحصل على ملف `.ipa`
   ويمكن رفعه مباشرة للـ App Store من Codemagic. كل ذلك على أجهزة Mac سحابية —
   **بدون أن تملك Mac**.

---

## ما الذي يقابل ملفات النسخة القديمة؟
| النسخة القديمة (Capacitor) | هذه النسخة (Flutter) |
|---|---|
| `www/index.html` (الغلاف) | `lib/main.dart` |
| `capacitor.config.json` | `pubspec.yaml` + إعدادات المنصّات |
| `SplashScreen` plugin | `_SplashScreen` + `flutter_native_splash` |
| شاشة الأوفلاين في HTML | `_OfflineScreen` + `connectivity_plus` |
| `allow="geolocation; camera"` | أذونات Android/iOS + `permission_handler` |
