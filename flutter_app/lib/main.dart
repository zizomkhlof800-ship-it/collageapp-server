import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(
    () {
      runApp(
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      // handle error silently in production
      debugPrint("Uncaught error: $error");
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'EduPorta',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F3C66),
              primary: const Color(0xFF0F3C66),
              secondary: const Color(0xFF1D4ED8),
              surface: Colors.white,
              surfaceContainerHighest: const Color(0xFFF1F5F9),
              onSurfaceVariant: const Color(0xFF64748B),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            textTheme: GoogleFonts.cairoTextTheme(),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1D1D1D),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: GoogleFonts.cairo(
                color: const Color(0xFF1D1D1D),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              labelStyle: GoogleFonts.cairo(color: const Color(0xFF64748B)),
              hintStyle: GoogleFonts.cairo(color: const Color(0xFF94A3B8)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0F3C66)),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              titleTextStyle: GoogleFonts.cairo(
                color: const Color(0xFF1D1D1D),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              contentTextStyle: GoogleFonts.cairo(
                color: const Color(0xFF1F2937),
              ),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Colors.white,
              modalBackgroundColor: Colors.white,
            ),
            dropdownMenuTheme: DropdownMenuThemeData(
              textStyle: GoogleFonts.cairo(color: const Color(0xFF1F2937)),
            ),
            dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0)),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F3C66),
              primary: const Color(0xFF3B82F6),
              secondary: const Color(0xFF60A5FA),
              surface: const Color(0xFF1E293B),
              surfaceContainerHighest: const Color(0xFF334155),
              onSurface: Colors.white,
              onSurfaceVariant: const Color(0xFFCBD5E1),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            textTheme: GoogleFonts.cairoTextTheme(
              ThemeData.dark().textTheme,
            ).apply(bodyColor: Colors.white, displayColor: Colors.white),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E293B),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              labelStyle: GoogleFonts.cairo(color: const Color(0xFFCBD5E1)),
              hintStyle: GoogleFonts.cairo(color: const Color(0xFF94A3B8)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF60A5FA)),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF1E293B),
              titleTextStyle: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              contentTextStyle: GoogleFonts.cairo(
                color: const Color(0xFFCBD5E1),
              ),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Color(0xFF1E293B),
              modalBackgroundColor: Color(0xFF1E293B),
            ),
            dropdownMenuTheme: DropdownMenuThemeData(
              textStyle: GoogleFonts.cairo(color: Colors.white),
            ),
            dividerTheme: const DividerThemeData(color: Color(0xFF334155)),
          ),
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child,
            );
          },
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar', '')],
          locale: const Locale('ar', ''),
          home: const SplashScreen(),
        );
      },
    );
  }
}
