import 'dart:ui';
import 'package:flutter/material.dart';

// --- GLOBAL THEME NOTIFIER ---
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

// --- DESIGN TOKENS ---
class AppColors {
  // Gradients
  static const Color purple = Color(0xFF667EEA);
  static const Color violet = Color(0xFF764BA2);
  static const Color cyan = Color(0xFF00D4FF);
  static const Color pink = Color(0xFFFF6B9D);
  static const Color orange = Color(0xFFFF8C42);

  // Dark mode
  static const Color darkBg = Color(0xFF0D0D1E);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);

  // Light mode
  static const Color lightBg = Color(0xFFF0EFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF8F7FF);

  static const List<Color> primaryGradient = [purple, violet];
  static const List<Color> cyanGradient = [cyan, purple];
  static const List<Color> pinkGradient = [pink, orange];

  static const List<Color> darkBgGradient = [Color(0xFF0D0D1E), Color(0xFF1A0D2E)];
  static const List<Color> lightBgGradient = [Color(0xFFF0EFFF), Color(0xFFE8E4FF)];
}

// --- LIGHT THEME ---
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.purple,
    brightness: Brightness.light,
    primary: AppColors.purple,
    secondary: AppColors.cyan,
    surface: AppColors.lightSurface,
  ),
  scaffoldBackgroundColor: AppColors.lightBg,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: Color(0xFF1A1A2E),
    titleTextStyle: TextStyle(
      color: Color(0xFF1A1A2E),
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(color: Color(0xFF2D2D2D)),
    bodyMedium: TextStyle(color: Color(0xFF555555)),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white.withAlpha(230),
    indicatorColor: AppColors.purple.withAlpha(30),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  ),
);

// --- DARK THEME ---
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.purple,
    brightness: Brightness.dark,
    primary: AppColors.purple,
    secondary: AppColors.cyan,
    surface: AppColors.darkSurface,
  ),
  scaffoldBackgroundColor: AppColors.darkBg,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(color: Colors.white70),
    bodyMedium: TextStyle(color: Colors.white60),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.black.withAlpha(180),
    indicatorColor: AppColors.purple.withAlpha(60),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
    ),
  ),
);

// --- GRADIENT BACKGROUND ---
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? AppColors.darkBgGradient : AppColors.lightBgGradient,
        ),
      ),
      child: child,
    );
  }
}

// --- GLASS CARD ---
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 12,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(20);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null
                ? (isDark
                    ? Colors.white.withAlpha(18)
                    : Colors.white.withAlpha(180))
                : null,
            borderRadius: radius,
            border: Border.all(
              color: borderColor ??
                  (isDark
                      ? Colors.white.withAlpha(30)
                      : Colors.white.withAlpha(200)),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// --- GRADIENT BUTTON ---
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final List<Color> colors;
  final bool isLoading;
  final double height;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.colors = AppColors.primaryGradient,
    this.isLoading = false,
    this.height = 56,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.first.withAlpha(100),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// --- GLASS TEXT FIELD ---
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onTogglePassword;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Color accentColor;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onTogglePassword,
    this.validator,
    this.keyboardType,
    this.accentColor = AppColors.purple,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54, fontSize: 14),
        prefixIcon: Icon(icon, color: accentColor, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 20,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: isDark ? Colors.white.withAlpha(15) : Colors.white.withAlpha(200),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withAlpha(30)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.white.withAlpha(25) : Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}

// --- DARK MODE TOGGLE BUTTON ---
class DarkModeToggle extends StatelessWidget {
  const DarkModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        final isDark = mode == ThemeMode.dark;
        return GestureDetector(
          onTap: () {
            themeNotifier.value =
                isDark ? ThemeMode.light : ThemeMode.dark;
          },
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            borderRadius: BorderRadius.circular(30),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: isDark ? AppColors.cyan : AppColors.orange,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isDark ? 'Dark' : 'Light',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
