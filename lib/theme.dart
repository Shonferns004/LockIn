import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Colors ──
  static const Color background = Color(0xFFF9F9F9);
  static const Color onBackground = Color(0xFF1B1B1B);
  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceDim = Color(0xFFDADADA);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerLow = Color(0xFFF3F3F3);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);
  static const Color surfaceBright = Color(0xFFF9F9F9);
  static const Color surfaceVariant = Color(0xFFE2E2E2);
  static const Color onSurface = Color(0xFF1B1B1B);
  static const Color onSurfaceVariant = Color(0xFF444933);

  static const Color primary = Color(0xFF506600);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFCCFF00);
  static const Color onPrimaryContainer = Color(0xFF5B7300);
  static const Color primaryFixed = Color(0xFFC3F400);
  static const Color primaryFixedDim = Color(0xFFABD600);
  static const Color onPrimaryFixed = Color(0xFF161E00);
  static const Color onPrimaryFixedVariant = Color(0xFF3C4D00);
  static const Color inversePrimary = Color(0xFFABD600);

  static const Color secondary = Color(0xFF8D00D9);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFAA30FA);
  static const Color onSecondaryContainer = Color(0xFFFFFBFF);
  static const Color secondaryFixed = Color(0xFFF3DAFF);
  static const Color secondaryFixedDim = Color(0xFFE3B5FF);
  static const Color onSecondaryFixed = Color(0xFF2F004C);
  static const Color onSecondaryFixedVariant = Color(0xFF6E00AB);

  static const Color tertiary = Color(0xFF006A6A);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF8DFFFE);
  static const Color onTertiaryContainer = Color(0xFF007777);
  static const Color tertiaryFixed = Color(0xFF00FBFB);
  static const Color tertiaryFixedDim = Color(0xFF00DDDD);
  static const Color onTertiaryFixed = Color(0xFF002020);
  static const Color onTertiaryFixedVariant = Color(0xFF004F4F);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color outline = Color(0xFF747A60);
  static const Color outlineVariant = Color(0xFFC4C9AC);

  static const Color inverseSurface = Color(0xFF303030);
  static const Color inverseOnSurface = Color(0xFFF1F1F1);

  static const Color border = onBackground;
  static const Color black = Color(0xFF000000);

  // ── Typography ──
  static TextStyle _montserrat({double? fontSize, FontWeight? fontWeight, double? height, double? letterSpacing, FontStyle? fontStyle}) =>
      GoogleFonts.montserrat(fontSize: fontSize, fontWeight: fontWeight, height: height, letterSpacing: letterSpacing, fontStyle: fontStyle);

  static TextStyle _spaceGrotesk({double? fontSize, FontWeight? fontWeight, double? height, double? letterSpacing}) =>
      GoogleFonts.spaceGrotesk(fontSize: fontSize, fontWeight: fontWeight, height: height, letterSpacing: letterSpacing);

  static TextTheme get textTheme => TextTheme(
    displayLarge: _montserrat(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -0.02, height: 1.1),
    displayMedium: _montserrat(fontSize: 36, fontWeight: FontWeight.w900, height: 1.1),
    headlineLarge: _montserrat(fontSize: 32, fontWeight: FontWeight.w800, height: 1.2),
    headlineMedium: _montserrat(fontSize: 24, fontWeight: FontWeight.w800, height: 1.2),
    headlineSmall: _montserrat(fontSize: 18, fontWeight: FontWeight.w600, height: 1.5),
    bodyLarge: _montserrat(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5),
    bodyMedium: _montserrat(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
    bodySmall: _montserrat(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4),
    labelLarge: _spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, height: 1),
    labelMedium: _spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, height: 1),
    labelSmall: _spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700, height: 1),
  );

  // ── ThemeData ──
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainerHigh: surfaceContainerHigh,
      outline: outline,
      outlineVariant: outlineVariant,
      inverseSurface: inverseSurface,
      inversePrimary: inversePrimary,
      onInverseSurface: inverseOnSurface,
    ),
    textTheme: textTheme,
    fontFamily: GoogleFonts.montserrat().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: _montserrat(fontSize: 24, fontWeight: FontWeight.w800, height: 1.2).copyWith(color: onBackground),
    ),
    useMaterial3: true,
  );
}

// ── Neo-Brutalist Decoration Helpers ──

BoxDecoration neoBorder({Color? bg}) => BoxDecoration(
  color: bg ?? AppTheme.surface,
  border: Border.all(color: AppTheme.border, width: 4),
  borderRadius: BorderRadius.circular(4),
);

List<BoxShadow> neoShadow() => const [
  BoxShadow(
    color: AppTheme.black,
    offset: Offset(6, 6),
    blurRadius: 0,
    spreadRadius: 0,
  ),
];

List<BoxShadow> neoShadowSm() => const [
  BoxShadow(
    color: AppTheme.black,
    offset: Offset(4, 4),
    blurRadius: 0,
    spreadRadius: 0,
  ),
];

List<BoxShadow> neoActiveShadow() => const [
  BoxShadow(
    color: AppTheme.black,
    offset: Offset.zero,
    blurRadius: 0,
    spreadRadius: 0,
  ),
];

// ── Neo-Brutalist Card ──

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color? bg;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Color? borderColor;

  const NeoCard({
    super.key,
    required this.child,
    this.bg,
    this.padding,
    this.margin,
    this.onTap,
    this.width,
    this.height,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg ?? AppTheme.surface,
        border: Border.all(color: borderColor ?? AppTheme.border, width: 4),
        borderRadius: BorderRadius.circular(4),
        boxShadow: neoShadow(),
      ),
      child: child,
    );

    if (onTap == null) return card;

    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }
}

// ── Neo-Brutalist Button ──

class NeoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? bg;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final Widget? leading;

  const NeoButton({
    super.key,
    required this.label,
    this.onTap,
    this.bg,
    this.textColor,
    this.padding,
    this.width,
    this.leading,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null ? (_) {
        setState(() => _pressed = false);
        widget.onTap!();
      } : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: widget.bg ?? AppTheme.onBackground,
          border: Border.all(color: AppTheme.border, width: 4),
          borderRadius: BorderRadius.circular(4),
          boxShadow: _pressed ? neoActiveShadow() : neoShadow(),
        ),
        transform: _pressed ? Matrix4.translationValues(6, 6, 0) : Matrix4.identity(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: AppTheme.textTheme.labelLarge?.copyWith(color: widget.textColor ?? AppTheme.background),
            ),
          ],
        ),
      ),
    );
  }
}
