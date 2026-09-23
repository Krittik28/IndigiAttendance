import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:indigi_attendance/main.dart';
import 'package:indigi_attendance/controllers/auth_controller.dart';
import 'package:indigi_attendance/models/user_model.dart';
import 'package:indigi_attendance/models/attendance_model.dart';

class MockAuthController extends ChangeNotifier implements AuthController {
  @override
  bool get isLoading => false;

  @override
  bool get isCheckingAutoLogin => true;

  @override
  String get errorMessage => '';

  @override
  User? get currentUser => null;

  @override
  List<Attendance> get attendanceHistory => [];

  @override
  bool get isRefreshingHistory => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('AppLoader shows loading screen when checking auto-login', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthController>(
          create: (_) => MockAuthController(),
          child: const AppLoader(),
        ),
      ),
    );

    // Verify that the loading indicator and app title are displayed.
    expect(find.text('Indigi'), findsOneWidget);
    expect(find.text('Attendance & HR Suite'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}


