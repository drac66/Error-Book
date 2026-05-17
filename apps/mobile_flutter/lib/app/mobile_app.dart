import 'package:flutter/material.dart';

import '../pages/mobile_home.dart';
import '../services/app_services.dart';

class MobileApp extends StatelessWidget {
  final AppServices? services;

  const MobileApp({super.key, this.services});

  @override
  Widget build(BuildContext context) {
    const primaryInk = Color(0xFF1E3A5F);
    const accentCoral = Color(0xFFE76F51);
    const accentGold = Color(0xFFF2C46D);
    const paper = Color(0xFFF7F1E3);
    const mist = Color(0xFFE8EEF5);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryInk,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryInk,
      secondary: accentCoral,
      tertiary: accentGold,
      surface: const Color(0xFFFFFCF6),
    );

    const fieldRadius = Radius.circular(28);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '学无止境',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: paper,
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: const Color(0xFF243447),
              displayColor: const Color(0xFF243447),
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1C2A39),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFCF6),
          elevation: 0,
          margin: EdgeInsets.zero,
          shadowColor: const Color(0xFF86694D).withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(28)),
            side: BorderSide(
              color: const Color(0xFFDCC9A2).withValues(alpha: 0.95),
              width: 1.1,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return accentCoral.withValues(alpha: 0.92);
              }
              return accentCoral;
            }),
            foregroundColor: WidgetStateProperty.all(Colors.white),
            elevation: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.pressed) ? 8 : 0,
            ),
            shadowColor: WidgetStateProperty.all(
              accentCoral.withValues(alpha: 0.28),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(primaryInk),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return BorderSide(
                  color: accentGold.withValues(alpha: 0.95),
                  width: 1.3,
                );
              }
              return BorderSide(
                color: const Color(0xFFDCC9A2).withValues(alpha: 0.95),
                width: 1.2,
              );
            }),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color(0xFFFFF2D7);
              }
              return const Color(0xFFFFF9EE);
            }),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFCF6),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(fieldRadius),
            borderSide: BorderSide(
              color: const Color(0xFFD9C7A4).withValues(alpha: 0.8),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(fieldRadius),
            borderSide: BorderSide(
              color: const Color(0xFFD9C7A4).withValues(alpha: 0.8),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(fieldRadius),
            borderSide: BorderSide(
              color: accentCoral.withValues(alpha: 0.85),
              width: 1.4,
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryInk,
          foregroundColor: Colors.white,
          extendedTextStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          highlightElevation: 2,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF243447).withValues(alpha: 0.94),
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFFFF8EB),
          selectedColor: const Color(0xFFFCE4CB),
          side: BorderSide(
            color: const Color(0xFFD9C7A4).withValues(alpha: 0.85),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          labelStyle: const TextStyle(
            color: Color(0xFF45556C),
            fontWeight: FontWeight.w700,
          ),
          secondaryLabelStyle: const TextStyle(
            color: Color(0xFF1E3A5F),
            fontWeight: FontWeight.w800,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFFFFFBF4).withValues(alpha: 0.98),
          indicatorColor: const Color(0xFFFBE4D3),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: primaryInk,
                fontWeight: FontWeight.w800,
              );
            }
            return const TextStyle(
              color: Color(0xFF786D60),
              fontWeight: FontWeight.w600,
            );
          }),
        ),
        dividerTheme: const DividerThemeData(
          color: mist,
          thickness: 1,
          space: 1,
        ),
      ),
      home: MobileHome(services: services ?? AppServices.create()),
    );
  }
}
