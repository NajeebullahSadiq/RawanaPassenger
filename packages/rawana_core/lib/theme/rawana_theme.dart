import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Core brand color tokens. Designed for a premium ride-hailing experience
/// inspired by modern fintech and RideCap-style UI references.
class RawanaColors {
  // Primary brand — canonical tokens (see DESIGN.md)
  static const primary = Color(0xFF0058BC);
  static const primaryBright = Color(0xFF1877F2);
  static const primaryDeep = Color(0xFF062A4C);
  static const primaryGlow = Color(0xFF1877F2);
  static const secondary = Color(0xFF062A4C);

  // Accent (highlights / earnings / badges)
  static const accent = Color(0xFFFFC857);
  static const accentDeep = Color(0xFFE0A93B);

  // Neutrals
  static const ink = Color(0xFF062A4C);
  static const onSurface = Color(0xFF111C2D);
  static const onSurfaceMuted = Color(0xFF414754);
  static const onSurfaceVariant = Color(0xFF414754);
  static const onSurfaceFaint = Color(0xFF98A2B3);
  static const surface = Color(0xFFF9F9FF);
  static const surfaceAlt = Color(0xFFE8EEFF);
  static const surfaceElevated = Colors.white;
  static const cardBg = Colors.white;
  static const divider = Color(0xFFE8EEFF);
  static const outline = Color(0xFFC1C6D6);

  // Semantic
  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFE6F4EA);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFEF3C7);
  static const error = Color(0xFFDC2626);
  static const errorSoft = Color(0xFFFEE2E2);

  // Map / route
  static const routeLine = Color(0xFF0058BC);
  static const pickupPin = Color(0xFF16A34A);
  static const dropoffPin = Color(0xFFFFC857);

  /// Primary CTA gradient.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0058BC), Color(0xFF1877F2)],
  );

  /// Premium "ink" gradient for hero / splash backgrounds.
  static const LinearGradient inkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF062A4C), Color(0xFF0058BC)],
  );

  /// Accent gradient (used sparingly).
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC857), Color(0xFFE0A93B)],
  );
}

class RawanaSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  // Radii
  static const radiusSm = 12.0;
  static const radiusMd = 16.0;
  static const radius = 20.0; // legacy default
  static const radiusLg = 24.0;
  static const radiusXl = 32.0;
  static const radiusPill = 100.0;

  // Sizing
  static const buttonHeight = 56.0;
  static const buttonHeightCompact = 48.0;
  static const inputHeight = 56.0;
}

class RawanaShadows {
  /// Soft shadow for cards floating over the map.
  static List<BoxShadow> floating = [
    BoxShadow(
      color: const Color(0xFF062A4C).withValues(alpha: 0.10),
      blurRadius: 32,
      offset: const Offset(0, 12),
      spreadRadius: -8,
    ),
    BoxShadow(
      color: const Color(0xFF062A4C).withValues(alpha: 0.05),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// Subtle elevation for nav bars, app bars, etc.
  static List<BoxShadow> low = [
    BoxShadow(
      color: const Color(0xFF062A4C).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Card / sheet shadow.
  static List<BoxShadow> sheet = [
    BoxShadow(
      color: const Color(0xFF062A4C).withValues(alpha: 0.14),
      blurRadius: 40,
      offset: const Offset(0, -12),
      spreadRadius: -8,
    ),
  ];

  /// CTA / floating button glow.
  static List<BoxShadow> ctaGlow = [
    BoxShadow(
      color: RawanaColors.primary.withValues(alpha: 0.32),
      blurRadius: 28,
      offset: const Offset(0, 14),
      spreadRadius: -8,
    ),
  ];
}

class RawanaTextStyles {
  static TextTheme build(TextTheme base, {bool isRtl = false}) {
    // Negative tracking collides Arabic-script glyphs in Dari/Pashto.
    final displayTracking = isRtl ? 0.0 : -1.0;
    final titleTracking = isRtl ? 0.0 : -0.3;
    final labelTracking = isRtl ? 0.0 : 0.6;

    TextStyle merge(TextStyle? a, TextStyle? b) =>
        (a ?? const TextStyle()).copyWith(
          fontFamily: b?.fontFamily,
          fontFamilyFallback: b?.fontFamilyFallback,
        );

    return base.copyWith(
      displayLarge: merge(base.displayLarge, base.displayLarge)
          .copyWith(fontWeight: FontWeight.w800, letterSpacing: isRtl ? 0 : -1.5, color: RawanaColors.onSurface),
      displayMedium: merge(base.displayMedium, base.displayMedium)
          .copyWith(fontWeight: FontWeight.w800, letterSpacing: isRtl ? 0 : -1.2, color: RawanaColors.onSurface),
      displaySmall: merge(base.displaySmall, base.displaySmall)
          .copyWith(fontWeight: FontWeight.w800, letterSpacing: displayTracking, color: RawanaColors.onSurface),
      headlineLarge: merge(base.headlineLarge, base.headlineLarge)
          .copyWith(fontWeight: FontWeight.w800, letterSpacing: displayTracking, color: RawanaColors.onSurface),
      headlineMedium: merge(base.headlineMedium, base.headlineMedium)
          .copyWith(fontWeight: FontWeight.w800, letterSpacing: isRtl ? 0 : -0.8, color: RawanaColors.onSurface),
      headlineSmall: merge(base.headlineSmall, base.headlineSmall)
          .copyWith(fontWeight: FontWeight.w700, letterSpacing: isRtl ? 0 : -0.5, color: RawanaColors.onSurface),
      titleLarge: merge(base.titleLarge, base.titleLarge)
          .copyWith(fontWeight: FontWeight.w700, letterSpacing: titleTracking, color: RawanaColors.onSurface),
      titleMedium: merge(base.titleMedium, base.titleMedium)
          .copyWith(fontWeight: FontWeight.w700, color: RawanaColors.onSurface),
      titleSmall: merge(base.titleSmall, base.titleSmall)
          .copyWith(fontWeight: FontWeight.w600, color: RawanaColors.onSurface),
      bodyLarge: merge(base.bodyLarge, base.bodyLarge)
          .copyWith(fontSize: 16, height: 1.45, color: RawanaColors.onSurface),
      bodyMedium: merge(base.bodyMedium, base.bodyMedium)
          .copyWith(fontSize: 14, height: 1.45, color: RawanaColors.onSurface),
      bodySmall: merge(base.bodySmall, base.bodySmall)
          .copyWith(fontSize: 12, height: 1.4, color: RawanaColors.onSurfaceMuted),
      labelLarge: merge(base.labelLarge, base.labelLarge)
          .copyWith(fontWeight: FontWeight.w600, color: RawanaColors.onSurface),
      labelMedium: merge(base.labelMedium, base.labelMedium)
          .copyWith(fontWeight: FontWeight.w600, color: RawanaColors.onSurface),
      labelSmall: merge(base.labelSmall, base.labelSmall)
          .copyWith(fontWeight: FontWeight.w600, letterSpacing: labelTracking, color: RawanaColors.onSurfaceMuted),
    );
  }
}

class RawanaTheme {
  static ThemeData light({bool isRtl = false}) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    final colorScheme = ColorScheme.fromSeed(
      seedColor: RawanaColors.primary,
      primary: RawanaColors.primary,
      onPrimary: Colors.white,
      secondary: RawanaColors.accent,
      onSecondary: RawanaColors.primaryDeep,
      tertiary: RawanaColors.primaryDeep,
      surface: RawanaColors.surfaceElevated,
      onSurface: RawanaColors.onSurface,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: RawanaColors.surface,
      surfaceContainer: RawanaColors.surface,
      surfaceContainerHigh: RawanaColors.surfaceAlt,
      surfaceContainerHighest: RawanaColors.surfaceAlt,
      outline: RawanaColors.outline,
      outlineVariant: RawanaColors.divider,
      error: RawanaColors.error,
      onError: Colors.white,
      brightness: Brightness.light,
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: RawanaColors.surface,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    // Bahij Zar (Bahij Virtual Academy) for Dari (fa) and Pashto (ps).
    // Family string includes the package prefix so glyphs resolve from rawana_core.
    const bahijFamily = 'packages/rawana_core/Bahij Zar';
    final scriptTheme = isRtl
        ? baseTheme.textTheme.apply(
            fontFamily: bahijFamily,
            fontFamilyFallback: const ['Tahoma'],
          )
        : GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
            fontFamilyFallback: const [bahijFamily, 'Tahoma'],
          );
    final scriptPrimary = isRtl
        ? baseTheme.primaryTextTheme.apply(
            fontFamily: bahijFamily,
            fontFamilyFallback: const ['Tahoma'],
          )
        : GoogleFonts.interTextTheme(baseTheme.primaryTextTheme).apply(
            fontFamilyFallback: const [bahijFamily, 'Tahoma'],
          );
    final latinFamily = GoogleFonts.inter().fontFamily;

    TextStyle script({
      Color? color,
      double? fontSize,
      FontWeight? fontWeight,
      double? letterSpacing,
      double? height,
    }) {
      return TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        fontFamily: isRtl ? bahijFamily : latinFamily,
        fontFamilyFallback: isRtl ? const ['Tahoma'] : const [bahijFamily, 'Tahoma'],
      );
    }

    return baseTheme.copyWith(
      textTheme: RawanaTextStyles.build(scriptTheme, isRtl: isRtl),
      primaryTextTheme: RawanaTextStyles.build(scriptPrimary, isRtl: isRtl),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        foregroundColor: RawanaColors.onSurface,
        iconTheme: const IconThemeData(color: RawanaColors.onSurface, size: 22),
        titleTextStyle: script(
          color: RawanaColors.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: isRtl ? 0 : -0.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return RawanaColors.outline;
            return RawanaColors.primary;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.08)),
          elevation: WidgetStateProperty.all(0),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          minimumSize: WidgetStateProperty.all(
            const Size(double.infinity, RawanaSpacing.buttonHeight),
          ),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
          )),
          textStyle: WidgetStateProperty.all(script(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: isRtl ? 0 : -0.2,
          )),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: RawanaColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, RawanaSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
          ),
          textStyle: script(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: isRtl ? 0 : -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RawanaColors.onSurface,
          backgroundColor: Colors.white,
          elevation: 0,
          side: const BorderSide(color: RawanaColors.divider, width: 1.4),
          minimumSize: const Size(double.infinity, RawanaSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
          ),
          textStyle: script(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: isRtl ? 0 : -0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: RawanaColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: script(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: isRtl ? 0 : -0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
          borderSide: const BorderSide(color: RawanaColors.divider, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
          borderSide: const BorderSide(color: RawanaColors.divider, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
          borderSide: const BorderSide(color: RawanaColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
          borderSide: const BorderSide(color: RawanaColors.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
          borderSide: const BorderSide(color: RawanaColors.error, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: script(color: RawanaColors.onSurfaceFaint, fontSize: 15),
        labelStyle: script(color: RawanaColors.onSurfaceMuted, fontSize: 14, fontWeight: FontWeight.w500),
        floatingLabelStyle: script(color: RawanaColors.primary, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: RawanaColors.cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
          side: const BorderSide(color: RawanaColors.divider, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(RawanaSpacing.radiusXl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
        ),
        titleTextStyle: script(
          fontSize: 18, fontWeight: FontWeight.w700, color: RawanaColors.onSurface,
        ),
        contentTextStyle: script(
          fontSize: 14, color: RawanaColors.onSurfaceMuted, height: 1.5,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: RawanaColors.surfaceAlt,
        selectedColor: RawanaColors.primary,
        labelStyle: script(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: RawanaColors.onSurface,
        ),
        secondaryLabelStyle: script(
          fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        checkmarkColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(
        color: RawanaColors.divider,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: RawanaColors.primary.withValues(alpha: 0.12),
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return script(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? RawanaColors.primary : RawanaColors.onSurfaceMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? RawanaColors.primary : RawanaColors.onSurfaceMuted,
            size: 22,
          );
        }),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: RawanaColors.onSurfaceMuted,
        textColor: RawanaColors.onSurface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return RawanaColors.success;
          return RawanaColors.outline;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: RawanaColors.primary,
        linearTrackColor: RawanaColors.divider,
        circularTrackColor: RawanaColors.divider,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: RawanaColors.ink,
        contentTextStyle: script(color: Colors.white, fontWeight: FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd)),
        actionTextColor: RawanaColors.accent,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: RawanaColors.primary,
        unselectedLabelColor: RawanaColors.onSurfaceMuted,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: RawanaColors.primary,
        dividerColor: Colors.transparent,
        labelStyle: script(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: isRtl ? 0 : -0.2),
        unselectedLabelStyle: script(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: isRtl ? 0 : -0.2),
      ),
    );
  }
}
