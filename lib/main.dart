import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/progress_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load saved theme
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('dark_mode') ?? false;
  
  runApp(MyApp(initialDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool initialDarkMode;

  const MyApp({super.key, required this.initialDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyAppState>();
  }
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
  }

  void setTheme(bool isDark) async {
    setState(() {
      _isDarkMode = isDark;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LearnIt',
      theme: ThemeData(
        // Light theme with deep purple seed
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
          primary: const Color(0xFF6750A4),
          secondary: const Color(0xFF625B71),
          tertiary: const Color(0xFF7D5260),
          surface: const Color(0xFFFFFBFF),
          background: const Color(0xFFFFFBFF),
        ),
        useMaterial3: true,
        // Card theme
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: const Color(0xFFFFFBFF),
          surfaceTintColor: const Color(0xFFFFFBFF),
        ),
        // AppBar theme
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        // Bottom navigation
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 8,
          backgroundColor: Color(0xFFFFFBFF),
          selectedItemColor: Color(0xFF6750A4),
          unselectedItemColor: Color(0xFF79747E),
          type: BottomNavigationBarType.fixed,
        ),
        // Scaffold background
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        // Input decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3EDF7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        // Switch theme
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF6750A4);
            }
            return const Color(0xFF79747E);
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFFD0BCFF);
            }
            return const Color(0xFFEADDFF);
          }),
        ),
        // Divider color
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE7E0EC),
        ),
      ),
      darkTheme: ThemeData(
        // Dark theme with deep purple seed
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          primary: const Color(0xFFD0BCFF),
          secondary: const Color(0xFFCCC2DC),
          tertiary: const Color(0xFFEFB8C8),
          surface: const Color(0xFF1C1B1F),
          background: const Color(0xFF1C1B1F),
          onSurface: const Color(0xFFE6E1E5),
          onBackground: const Color(0xFFE6E1E5),
          surfaceVariant: const Color(0xFF49454F),
        ),
        useMaterial3: true,
        // Card theme for dark mode
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: const Color(0xFF2B2930),
          surfaceTintColor: const Color(0xFF2B2930),
        ),
        // AppBar theme for dark
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Color(0xFF2B2930),
          foregroundColor: Color(0xFFE6E1E5),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        // Bottom navigation for dark
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 8,
          backgroundColor: Color(0xFF2B2930),
          selectedItemColor: Color(0xFFD0BCFF),
          unselectedItemColor: Color(0xFF938F99),
          type: BottomNavigationBarType.fixed,
        ),
        // Scaffold background for dark
        scaffoldBackgroundColor: const Color(0xFF1C1B1F),
        // Input decoration for dark
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2B2930),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        // Switch theme for dark
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFFD0BCFF);
            }
            return const Color(0xFF938F99);
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF6750A4);
            }
            return const Color(0xFF49454F);
          }),
        ),
        // Divider color for dark
        dividerTheme: const DividerThemeData(
          color: Color(0xFF3C373F),
        ),
        // Text theme for dark - ensure contrast
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE6E1E5)),
          bodyLarge: TextStyle(color: Color(0xFFE6E1E5)),
          titleMedium: TextStyle(color: Color(0xFFE6E1E5)),
          titleLarge: TextStyle(color: Color(0xFFE6E1E5)),
          labelLarge: TextStyle(color: Color(0xFFE6E1E5)),
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const ModernHomeScreen(),
        '/progress': (context) => const ProgressScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
