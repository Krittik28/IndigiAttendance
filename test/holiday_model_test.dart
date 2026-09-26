import 'package:flutter_test/flutter_test.dart';
import 'package:indigi_attendance/models/holiday_model.dart';
import 'package:indigi_attendance/controllers/holiday_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Holiday and HolidayResponse Model Tests', () {
    final sampleJson = {
      "status": true,
      "message": "Holiday list fetched successfully",
      "year": 2026,
      "data": [
        {
          "id": 3,
          "holiday_date": "2026-01-14",
          "day": "Wednesday",
          "holiday_name": "Magh Bihu & Tusu Puja"
        },
        {
          "id": 4,
          "holiday_date": "2026-01-15",
          "day": "Thursday",
          "holiday_name": "Magh Bihu"
        },
        {
          "id": 5,
          "holiday_date": "2026-01-26",
          "day": "Monday",
          "holiday_name": "Republic Day"
        },
        {
          "id": 17,
          "holiday_date": "2026-12-25",
          "day": "Friday",
          "holiday_name": "Christmas"
        }
      ]
    };

    test('Holiday.fromJson parses item correctly', () {
      final list = sampleJson['data'] as List<dynamic>;
      final item = list[0] as Map<String, dynamic>;
      final holiday = Holiday.fromJson(item);

      expect(holiday.id, 3);
      expect(holiday.name, "Magh Bihu & Tusu Puja");
      expect(holiday.day, "Wednesday");
      expect(holiday.date.year, 2026);
      expect(holiday.date.month, 1);
      expect(holiday.date.day, 14);
    });

    test('HolidayResponse.fromJson parses full response correctly', () {
      final response = HolidayResponse.fromJson(sampleJson);

      expect(response.status, true);
      expect(response.message, "Holiday list fetched successfully");
      expect(response.year, 2026);
      expect(response.data.length, 4);
      expect(response.data[0].name, "Magh Bihu & Tusu Puja");
      expect(response.data[3].name, "Christmas");
      expect(response.data[3].date.month, 12);
      expect(response.data[3].date.day, 25);
    });

    test('Holiday.toJson produces correct structure', () {
      final holiday = Holiday(
        id: 10,
        date: DateTime(2026, 8, 15),
        name: "Independence Day",
        day: "Saturday",
      );

      final jsonMap = holiday.toJson();
      expect(jsonMap['id'], 10);
      expect(jsonMap['holiday_date'], '2026-08-15');
      expect(jsonMap['holiday_name'], 'Independence Day');
      expect(jsonMap['day'], 'Saturday');
    });
  });

  group('HolidayController Helper Methods Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Grouping, upcoming, today, and isHoliday logic works properly', () {
      final controller = HolidayController();

      final testHolidays = [
        Holiday(
          id: 1,
          date: DateTime.now(),
          name: "Today Holiday",
          day: "Today",
        ),
        Holiday(
          id: 2,
          date: DateTime.now().add(const Duration(days: 3)),
          name: "Upcoming Holiday",
          day: "In 3 Days",
        ),
        Holiday(
          id: 3,
          date: DateTime(2026, 12, 25),
          name: "Christmas",
          day: "Friday",
        ),
      ];

      // Inject test holidays directly to test controller helper methods
      controller.holidays.addAll(testHolidays);

      // Check today holiday
      final todayHoliday = controller.getTodayHoliday();
      expect(todayHoliday, isNotNull);
      expect(todayHoliday!.name, "Today Holiday");

      // Check upcoming holidays (within 7 days)
      final upcoming = controller.getUpcomingHolidays(days: 7);
      expect(upcoming.any((h) => h.name == "Upcoming Holiday"), isTrue);

      // Check isHoliday
      expect(controller.isHoliday(DateTime.now()), isTrue);
      expect(controller.isHoliday(DateTime(2026, 12, 25)), isTrue);
      expect(controller.isHoliday(DateTime(2026, 7, 4)), isFalse);

      // Check getGroupedHolidays
      final grouped = controller.getGroupedHolidays();
      expect(grouped.containsKey(12), isTrue);
      expect(grouped[12]!.any((h) => h.name == "Christmas"), isTrue);
    });
  });
}
