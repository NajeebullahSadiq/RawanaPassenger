import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';

class _Slide {
  final String title;
  final String body;
  final IconData icon;
  final Color tint;
  const _Slide(this.title, this.body, this.icon, this.tint);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_Slide> _slides(AppLocalizations l10n) => [
        _Slide(l10n.onboardingSlide1Title, l10n.onboardingSlide1Body, LucideIcons.navigation, RawanaColors.primary),
        _Slide(l10n.onboardingSlide2Title, l10n.onboardingSlide2Body, LucideIcons.mapPin, RawanaColors.success),
        _Slide(l10n.onboardingSlide3Title, l10n.onboardingSlide3Body, LucideIcons.wallet, RawanaColors.accentDeep),
      ];

  void _goTo(int page) =>
      _pageController.animateToPage(page, duration: RawanaMotion.medium, curve: RawanaMotion.curve);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slides = _slides(l10n);
    final last = _page == slides.length - 1;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
              child: Row(
                children: [
                  const RawanaLogoRow(iconSize: 36),
                  const Spacer(),
                  if (!last) TextButton(onPressed: () => context.go('/language'), child: Text(l10n.skip)),
                ],
              ),
            ),
            Expanded(
              // PageView follows Directionality, so swiping matches reading order in Dari/Pashto.
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: slides.length,
                itemBuilder: (_, i) => _SlideView(slide: slides[i]),
              ),
            ),
            Semantics(
              label: '${_page + 1} / ${slides.length}',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                  (i) => AnimatedContainer(
                    duration: RawanaMotion.medium,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i ? RawanaColors.primary : RawanaColors.divider,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Row(
                children: [
                  if (_page > 0) ...[
                    RawanaCircleIconButton(
                      icon: RawanaIcons.back,
                      tooltip: l10n.back,
                      elevated: false,
                      background: RawanaColors.surfaceAlt,
                      size: RawanaSpacing.buttonHeight,
                      onPressed: () => _goTo(_page - 1),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: RawanaPrimaryButton(
                      label: last ? l10n.getStarted : l10n.next,
                      icon: RawanaIcons.forward,
                      onPressed: () => last ? context.go('/language') : _goTo(_page + 1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 460;
        final visualSize = compact ? 172.0 : 240.0;
        final innerSize = compact ? 92.0 : 124.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: visualSize,
                  height: visualSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [slide.tint.withValues(alpha: 0.18), slide.tint.withValues(alpha: 0.02)],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: innerSize,
                      height: innerSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: slide.tint.withValues(alpha: 0.18),
                            blurRadius: 36,
                            offset: const Offset(0, 20),
                            spreadRadius: -8,
                          ),
                        ],
                      ),
                      child: Icon(slide.icon, size: compact ? 42 : 54, color: slide.tint),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 24 : 36),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: compact ? context.text.headline : context.text.display,
                ),
                const SizedBox(height: 12),
                Text(
                  slide.body,
                  textAlign: TextAlign.center,
                  style: context.text.body.copyWith(color: RawanaColors.onSurfaceMuted, height: 1.55),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
