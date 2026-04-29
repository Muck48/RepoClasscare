import 'dart:async';

import 'package:flutter/material.dart';
import 'package:classcare_user/user/landing_page.dart';
import 'package:classcare_user/user/splash_screen.dart';
import 'package:classcare_user/theme/app_design_tokens.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://sqmsmeivqsnouoldurce.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNxbXNtZWl2cXNub3VvbGR1cmNlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxMjI4OTUsImV4cCI6MjA4NzY5ODg5NX0.ztYtSXT2GuLRELPBXk2Zzw6br9sOdO-UkowpSPofW0k',
    ).timeout(const Duration(seconds: 8));
  } on TimeoutException catch (error, stackTrace) {
    debugPrint('Supabase initialization timeout: $error');
    debugPrintStack(stackTrace: stackTrace);
  } catch (error, stackTrace) {
    debugPrint('Supabase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ClassCare',
      theme: _buildLightTheme(),
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
      routes: {
        LandingPage.routeName: (_) => const LandingPage(),
      },
    );
  }

  static ThemeData _buildLightTheme() {
    return ThemeData(
      fontFamily: 'DM Sans',
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        background: AppColors.bgLight,
        surface: AppColors.surfaceLight,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.bgLight,
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusXl,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgLight,
        disabledColor: AppColors.inputDisabledLight,
        selectedColor: AppColors.primary.withOpacity(0.12),
        secondarySelectedColor: AppColors.primary.withOpacity(0.16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: AppTypography.heading5.copyWith(
          color: AppColors.textPrimaryLight,
          fontFamily: 'DM Sans',
        ),
        secondaryLabelStyle: AppTypography.heading5.copyWith(
          color: AppColors.textPrimaryLight,
          fontFamily: 'DM Sans',
        ),
        side: BorderSide(color: AppColors.inputBorderLight),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusFull,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.displaySmall.copyWith(
          color: Colors.white,
          fontFamily: 'DM Sans',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.radiusMd,
          ),
          textStyle: AppTypography.heading5.copyWith(
            color: Colors.white,
            fontFamily: 'DM Sans',
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.radiusLg,
          ),
          textStyle: AppTypography.heading5.copyWith(
            color: Colors.white,
            fontFamily: 'DM Sans',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.borderLight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.radiusMd,
          ),
          textStyle: AppTypography.heading5.copyWith(
            color: AppColors.primary,
            fontFamily: 'DM Sans',
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF4B4B4B), size: 22),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: AppColors.primary,
        textColor: AppColors.textPrimaryLight,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: Color(0xFFE8E1E1),
        linearTrackColor: Color(0xFFE8E1E1),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusTopXxl,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusXxl,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.heading5.copyWith(
            color: AppColors.primary,
            fontFamily: 'DM Sans',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBgLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.radiusLg,
          borderSide: BorderSide(color: AppColors.inputBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.radiusLg,
          borderSide: BorderSide(color: AppColors.inputBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.radiusLg,
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        labelStyle: AppTypography.heading5.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.primary,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        headlineMedium: AppTypography.heading3.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        headlineSmall: AppTypography.heading4.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        titleLarge: AppTypography.heading5.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        titleMedium: AppTypography.bodyLarge.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.textTertiaryLight,
        ),
        labelLarge: AppTypography.bodyMedium.copyWith(
          color: AppColors.primary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: const TextStyle(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusMd,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    return ThemeData(
      fontFamily: 'DM Sans',
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        background: AppColors.bgDark,
        surface: AppColors.surfaceDark,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusXl,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSecondaryDark,
        disabledColor: AppColors.inputDisabledDark,
        selectedColor: AppColors.primary.withOpacity(0.12),
        secondarySelectedColor: AppColors.primary.withOpacity(0.16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: AppTypography.heading5.copyWith(
          color: AppColors.textPrimaryDark,
          fontFamily: 'DM Sans',
        ),
        secondaryLabelStyle: AppTypography.heading5.copyWith(
          color: AppColors.textPrimaryDark,
          fontFamily: 'DM Sans',
        ),
        side: BorderSide(color: AppColors.inputBorderDark),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusFull,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.displaySmall.copyWith(
          color: AppColors.textPrimaryDark,
          fontFamily: 'DM Sans',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.radiusMd,
          ),
          textStyle: AppTypography.heading5.copyWith(
            color: Colors.white,
            fontFamily: 'DM Sans',
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.radiusLg,
          ),
          textStyle: AppTypography.heading5.copyWith(
            color: Colors.white,
            fontFamily: 'DM Sans',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.borderDark),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.radiusMd,
          ),
          textStyle: AppTypography.heading5.copyWith(
            color: AppColors.primary,
            fontFamily: 'DM Sans',
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFFB0B0B0), size: 22),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: AppColors.primary,
        textColor: AppColors.textPrimaryDark,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: Color(0xFF3A3A3A),
        linearTrackColor: Color(0xFF3A3A3A),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusTopXxl,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusXxl,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.heading5.copyWith(
            color: AppColors.primary,
            fontFamily: 'DM Sans',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBgDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.radiusLg,
          borderSide: BorderSide(color: AppColors.inputBorderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.radiusLg,
          borderSide: BorderSide(color: AppColors.inputBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.radiusLg,
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        labelStyle: AppTypography.heading5.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.primary,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        headlineMedium: AppTypography.heading3.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        headlineSmall: AppTypography.heading4.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        titleLarge: AppTypography.heading5.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        titleMedium: AppTypography.bodyLarge.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.textTertiaryDark,
        ),
        labelLarge: AppTypography.bodyMedium.copyWith(
          color: AppColors.primary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: const TextStyle(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusMd,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
    );
  }
}
