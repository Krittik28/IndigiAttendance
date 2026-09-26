import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indigi_attendance/controllers/holiday_controller.dart';
import 'package:indigi_attendance/models/holiday_model.dart';
import 'package:indigi_attendance/views/holiday_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HolidayScreen renders holidays correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final holidayController = HolidayController();
    holidayController.holidays.addAll([
      Holiday(
        id: 1,
        date: DateTime(2026, 1, 26),
        name: 'Republic Day',
        day: 'Monday',
      ),
      Holiday(
        id: 2,
        date: DateTime(2026, 8, 15),
        name: 'Independence Day',
        day: 'Saturday',
      ),
    ]);

    await tester.pumpWidget(
      ChangeNotifierProvider<HolidayController>.value(
        value: holidayController,
        child: const MaterialApp(
          home: HolidayScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify app bar title
    expect(find.text('Holidays'), findsOneWidget);
    // Verify holiday items rendered
    expect(find.text('Republic Day'), findsOneWidget);
    expect(find.text('Independence Day'), findsOneWidget);
  });
}
