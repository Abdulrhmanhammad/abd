import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'constants.dart';
import 'screens/more_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/web_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: kPrimary,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool(kOnboardingSeenKey) ?? false;

  runApp(DaleelakApp(showOnboarding: !seenOnboarding));
}

class DaleelakApp extends StatefulWidget {
  const DaleelakApp({super.key, required this.showOnboarding});

  final bool showOnboarding;

  @override
  State<DaleelakApp> createState() => _DaleelakAppState();
}

class _DaleelakAppState extends State<DaleelakApp> {
  late bool _showOnboarding = widget.showOnboarding;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دليلك',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: kPrimary,
      ),
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: _showOnboarding
          ? OnboardingScreen(
              onDone: () => setState(() => _showOnboarding = false),
            )
          : const RootShell(),
    );
  }
}

/// الهيكل الرئيسي: شريط تنقّل سفلي أصلي بأربعة تبويبات.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  // متحكّم WebView لكل تبويب من تبويبات الويب الثلاثة.
  late final List<WebViewController> _controllers;
  int _index = 0;
  bool _isArabic = true;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (_) => _buildController());
  }

  WebViewController _buildController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white);

    // إعدادات أندرويد: الموقع + أذونات الوسائط
    if (controller.platform is AndroidWebViewController) {
      final android = controller.platform as AndroidWebViewController;
      android.setMediaPlaybackRequiresUserGesture(false);
      android.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          final status = await Permission.location.request();
          return GeolocationPermissionsResponse(
              allow: status.isGranted, retain: false);
        },
      );
      android.setOnPlatformPermissionRequest((request) async {
        await Permission.camera.request();
        await Permission.microphone.request();
        request.grant();
      });
    }
    return controller;
  }

  void _onTab(int i) => setState(() => _index = i);

  Future<void> _onBack(bool didPop) async {
    if (didPop) return;
    if (_index != 0) {
      setState(() => _index = 0); // أي تبويب آخر → ارجع للرئيسية
      return;
    }
    final web = _controllers[0];
    if (await web.canGoBack()) {
      await web.goBack();
    } else {
      await SystemNavigator.pop();
    }
  }

  /// تبديل لغة الواجهة الأصلية + مزامنة لغة الموقع داخل كل WebView.
  void _toggleLanguage() {
    setState(() => _isArabic = !_isArabic);
    for (final c in _controllers) {
      c
          .runJavaScript(
              "if (typeof dlkToggleLang === 'function') { dlkToggleLang(); }")
          .catchError((_) {});
    }
  }

  List<String> get _labels => _isArabic
      ? const ['الرئيسية', 'الأقسام', 'المدن', 'المزيد']
      : const ['Home', 'Categories', 'Cities', 'More'];

  @override
  Widget build(BuildContext context) {
    final labels = _labels;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _onBack(didPop),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: IndexedStack(
            index: _index,
            children: [
              WebScreen(controller: _controllers[0], url: kHomeUrl),
              WebScreen(controller: _controllers[1], url: kCategoriesUrl),
              WebScreen(controller: _controllers[2], url: kCitiesUrl),
              MoreScreen(
                isArabic: _isArabic,
                onToggleLanguage: _toggleLanguage,
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onTab,
          backgroundColor: Colors.white,
          indicatorColor: kPrimary.withValues(alpha: 0.12),
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home, color: kPrimary),
                label: labels[0]),
            NavigationDestination(
                icon: const Icon(Icons.grid_view_outlined),
                selectedIcon: const Icon(Icons.grid_view, color: kPrimary),
                label: labels[1]),
            NavigationDestination(
                icon: const Icon(Icons.location_city_outlined),
                selectedIcon: const Icon(Icons.location_city, color: kPrimary),
                label: labels[2]),
            NavigationDestination(
                icon: const Icon(Icons.more_horiz),
                selectedIcon: const Icon(Icons.more_horiz, color: kPrimary),
                label: labels[3]),
          ],
        ),
      ),
    );
  }
}
