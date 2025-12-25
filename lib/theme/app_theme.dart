import 'package:flutter/material.dart';
import 'dart:ui';

class AppTheme {
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color samsungBlack = Color(0xFF000000);
  static const Color googleDarkGrey = Color(0xFF1A1C1E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        surface: const Color(0xFFFBFBFF),
      ),
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withAlpha(200),
        indicatorColor: primaryBlue.withAlpha(40),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        color: Colors.white.withAlpha(240),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        surface: const Color(0xFF121212),
      ),
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: samsungBlack,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Colors.white.withAlpha(200),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.black.withAlpha(200),
        indicatorColor: primaryBlue.withAlpha(60),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        color: const Color(0xFF2A2A2A),
      ),
    );
  }
}

// Glassmorphic container widget
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withAlpha(15) 
                  : Colors.white.withAlpha(180),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withAlpha(20) 
                    : Colors.white.withAlpha(100),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
