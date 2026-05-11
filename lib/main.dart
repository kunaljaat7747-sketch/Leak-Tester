// ============================================================
// main.dart — Entry point + AppTheme design tokens
// CosmoLogo now supports real image asset (cosmo_logo.png)
// with fallback to CustomPainter if asset not found
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/calculator_screen.dart';
import 'screens/manual_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Status bar: transparent so white appbar shows through, dark icons for contrast
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:          Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness:     Brightness.light,
  ));
  runApp(const CosmoCalculatorApp());
}

class CosmoCalculatorApp extends StatelessWidget {
  const CosmoCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cosmo Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeShell(),
    );
  }
}

// ── HomeShell ─────────────────────────────────────────────────
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [CalculatorScreen(), ManualScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12),
              blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor:   AppTheme.primaryBlue,
          unselectedItemColor: AppTheme.iconGrey,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.calculate_outlined),
                activeIcon: Icon(Icons.calculate),
                label: 'Calculate'),
            BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book),
                label: 'Manual'),
          ],
        ),
      ),
    );
  }
}

// ── AppTheme ──────────────────────────────────────────────────
class AppTheme {
  AppTheme._();
  static const Color primaryBlue   = Color(0xFF1565C0);
  static const Color accentBlue    = Color(0xFF1E88E5);
  static const Color lightBlue     = Color(0xFFE3F2FD);
  static const Color darkBlue      = Color(0xFF0D47A1);
  static const Color successGreen  = Color(0xFF2E7D32);
  static const Color warningOrange = Color(0xFFE65100);
  static const Color errorRed      = Color(0xFFC62828);
  static const Color cardWhite     = Color(0xFFFFFFFF);
  static const Color bgGrey        = Color(0xFFF4F6FA);
  static const Color dividerGrey   = Color(0xFFE0E0E0);
  static const Color textDark      = Color(0xFF1A237E);
  static const Color textBody      = Color(0xFF37474F);
  static const Color textHint      = Color(0xFF90A4AE);
  static const Color iconGrey      = Color(0xFF78909C);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
    scaffoldBackgroundColor: bgGrey,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dividerGrey)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dividerGrey, width: 1.2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentBlue, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: errorRed, width: 1.5)),
      labelStyle: const TextStyle(color: textHint, fontSize: 14),
      hintStyle: const TextStyle(color: textHint, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: cardWhite,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}
