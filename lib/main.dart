import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz_lib;
import 'theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/profile/profile_setup_screen.dart';
import 'screens/home/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/storage_service.dart';
import 'services/subscription_service.dart';
import 'services/gemini_service.dart';
import 'services/ad_service.dart';

// ============================================================
// Theme state management
// ============================================================
class ThemeNotifier extends ChangeNotifier {
  static const String _keyThemeMode = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  /// Load saved theme from SharedPreferences
  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyThemeMode);
    if (saved != null) {
      switch (saved) {
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
      notifyListeners();
    }
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = _themeMode == ThemeMode.dark
        ? 'dark'
        : _themeMode == ThemeMode.light
            ? 'light'
            : 'system';
    await prefs.setString(_keyThemeMode, value);
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _saveTheme();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveTheme();
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone — fall back to UTC if the device reports an
  // unknown zone, which can happen on stripped emulator images and
  // some rooted ROMs.
  tz.initializeTimeZones();
  try {
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz_lib.setLocalLocation(tz_lib.getLocation(timeZoneName));
  } catch (_) {
    tz_lib.setLocalLocation(tz_lib.getLocation('UTC'));
  }

  // Initialize Firebase & Remote Config
  await Firebase.initializeApp();
  await GeminiService.initialize();

  // Initialize monetization services
  await AdService().initialize();
  await SubscriptionService().initialize();

  // Load saved theme preference
  final themeNotifier = ThemeNotifier();
  await themeNotifier.loadSavedTheme();

  runApp(
    ChangeNotifierProvider.value(
      value: themeNotifier,
      child: const MedLabApp(),
    ),
  );
}

class MedLabApp extends StatelessWidget {
  const MedLabApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return MaterialApp(
      title: 'Med Lab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.themeMode,
      home: const SplashScreen(),
      builder: (context, child) {
        // Fix status bar colors globally based on current theme
        final isDark = Theme.of(context).brightness == Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor:
                isDark ? AppTheme.darkSurface : AppTheme.surfaceColor,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
        );
        return child!;
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _animController.forward();

    // Force light status bar icons on blue splash
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _checkFirstLaunch();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstLaunch() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final onboardingDone = await _storage.isOnboardingComplete();
    final userProfile = await _storage.getUserProfile();

    final Widget nextScreen;
    if (!onboardingDone) {
      nextScreen = const OnboardingScreen();
    } else if (userProfile == null) {
      nextScreen = const ProfileSetupScreen();
    } else {
      nextScreen = const HomeScreen();
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextScreen,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A73E8),
                Color(0xFF0D47A1),
                Color(0xFF1557B0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App icon — matches launcher icon
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A73E8), Color(0xFF00ACC1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_pharmacy_rounded,
                        size: 54,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXLarge),

                  // App name
                  const Text(
                    'Med Lab',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),

                  const Text(
                    'Your AI Medicine Companion',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXLarge * 2),

                  // Loading indicator
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white.withOpacity(0.8),
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
