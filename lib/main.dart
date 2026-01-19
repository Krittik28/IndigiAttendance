import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
import 'controllers/auth_controller.dart';
import 'views/login_screen.dart';
import 'views/dashboard_screen.dart';
import 'controllers/attendance_controller.dart';
import 'controllers/leave_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthController()),
        ChangeNotifierProvider(create: (context) => AttendanceController()),
        ChangeNotifierProvider(create: (context) => LeaveController()),
      ],
      child: MaterialApp(
        title: 'Indigi Attendance',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: false,
          fontFamily: 'Roboto',
        ),
        home: UpgradeAlert(
          upgrader: Upgrader(
            durationUntilAlertAgain: Duration.zero,
          ),
          showIgnore: false,
          showLater: false,
          shouldPopScope: () => false,
          child: const AppLoader(),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    // Show loading screen while checking auto-login
    if (authController.isCheckingAutoLogin) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 200,
                width: 200,
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.business_center_rounded,
                      size: 60,
                      color: Colors.blue,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Indigi Attendance',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 10),
              const Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Redirect to appropriate screen based on login status
    if (authController.currentUser != null) {
      return const DashboardScreen();
    } else {
      return const LoginScreen();
    }
  }
}