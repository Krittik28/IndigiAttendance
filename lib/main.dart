import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:indigi_attendance/controllers/auth_controller.dart';
import 'package:indigi_attendance/controllers/attendance_controller.dart';
import 'package:indigi_attendance/controllers/leave_controller.dart';
import 'package:indigi_attendance/controllers/client_visit_controller.dart';
import 'package:indigi_attendance/controllers/holiday_controller.dart';
import 'package:indigi_attendance/views/login_screen.dart';
import 'package:indigi_attendance/widgets/app_shell.dart';
import 'package:indigi_attendance/views/tabs/home_tab.dart';
import 'package:indigi_attendance/views/tabs/history_tab.dart';
import 'package:indigi_attendance/views/tabs/leave_tab.dart';
import 'package:indigi_attendance/views/tabs/more_tab.dart';
import 'package:indigi_attendance/views/tabs/profile_tab.dart';
import 'package:indigi_attendance/firebase_options.dart';
import 'package:indigi_attendance/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for consistent mobile experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const IndigiHRMApp());
}

class IndigiHRMApp extends StatelessWidget {
  const IndigiHRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => AttendanceController()),
        ChangeNotifierProvider(create: (_) => LeaveController()),
        ChangeNotifierProvider(create: (_) => ClientVisitController()),
        ChangeNotifierProvider(create: (_) => HolidayController()),
      ],
      child: MaterialApp(
        title: 'Indigi HRM',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const _AppLoader(),
      ),
    );
  }
}

class _AppLoader extends StatelessWidget {
  const _AppLoader();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);

    if (auth.isCheckingAutoLogin) {
      return const _SplashScreen();
    }

    if (auth.currentUser != null) {
      return const _MainShell();
    }

    return const LoginScreen();
  }
}

// ─── Splash Screen ────────────────────────────────────────────────────────────
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 104,
                    height: 104,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.coral.withValues(alpha: 0.35),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.business_center_rounded,
                        size: 46,
                        color: AppColors.coral,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // App Name
                  const Text(
                    'Indigi HRM',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Human Resource Management',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Loading indicator
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.coral.withValues(alpha: 0.8),
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

// ─── Main Shell ───────────────────────────────────────────────────────────────
class _MainShell extends StatelessWidget {
  const _MainShell();

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: Upgrader(durationUntilAlertAgain: Duration.zero),
      showIgnore: false,
      showLater: false,
      shouldPopScope: () => false,
      child: AppShell(
        destinations: const [
          AppShellDestination(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
            page: HomeTab(),
            activeColor: AppColors.emerald,
          ),
          AppShellDestination(
            icon: Icons.history_outlined,
            activeIcon: Icons.history_rounded,
            label: 'History',
            page: HistoryTab(),
            activeColor: AppColors.tealAccent,
          ),
          AppShellDestination(
            icon: Icons.event_note_outlined,
            activeIcon: Icons.event_note_rounded,
            label: 'Leave',
            page: LeaveTab(),
            activeColor: AppColors.purpleAccent,
          ),
          AppShellDestination(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: 'More',
            page: MoreTab(),
            activeColor: AppColors.amberAccent,
          ),
          AppShellDestination(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
            page: ProfileTab(),
            activeColor: AppColors.emerald,
          ),
        ],
      ),
    );
  }
}
