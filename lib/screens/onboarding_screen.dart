import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

/// مفتاح حفظ حالة مشاهدة شاشات التعريف.
const String kOnboardingSeenKey = 'onboarding_seen';

class _Page {
  const _Page({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;
}

const List<_Page> _pages = [
  _Page(
    title: 'مرحباً بك في دليلك',
    subtitle: 'كل محل أقرب إلك — دليلك الشامل للخدمات والمتاجر في مكان واحد.',
    icon: Icons.location_on,
  ),
  _Page(
    title: 'ابحث عن أي خدمة بسهولة',
    subtitle: 'تصفّح الأقسام والمدن وابحث عن أقرب محل أو خدمة تحتاجها بلمسة واحدة.',
    icon: Icons.search,
  ),
  _Page(
    title: 'احفظ وتواصل مباشرة',
    subtitle: 'احفظ مفضّلاتك وتواصل مع المحلات مباشرةً عبر الاتصال أو واتساب.',
    icon: Icons.favorite,
  ),
];

/// شاشات تعريفية تظهر مرّة واحدة عند أول تشغيل، وتطلب إذن الإشعارات في النهاية.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  /// يُستدعى بعد إنهاء الـ onboarding للانتقال إلى التطبيق.
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  bool _finishing = false;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    // طلب إذن الإشعارات (تحضير لميزة أصلية + إظهار استخدام الجهاز للمراجِع).
    try {
      await Permission.notification.request();
    } catch (_) {/* تجاهل أي خطأ في طلب الإذن */}

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingSeenKey, true);

    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // زر التخطّي
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: TextButton(
                onPressed: _finishing ? null : _finish,
                child: const Text('تخطّي',
                    style: TextStyle(color: kTextMuted, fontSize: 15)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _PageView(page: _pages[i], showLogo: i == 0),
              ),
            ),
            // مؤشّر الصفحات
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? kPrimary : kPrimary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // زر التالي / ابدأ
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: kBrandGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: _finishing ? null : _next,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: _finishing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            _isLast ? 'ابدأ الآن' : 'التالي',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page, required this.showLogo});
  final _Page page;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showLogo)
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/daleelak.jpg',
                width: 160,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _iconBadge(),
              ),
            )
          else
            _iconBadge(),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: kTextMuted,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBadge() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        gradient: kBrandGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(page.icon, color: Colors.white, size: 72),
    );
  }
}
