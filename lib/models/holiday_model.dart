import 'package:intl/intl.dart';

class Holiday {
  final int? id;
  final DateTime date;
  final String name;
  final String? day;

  const Holiday({
    this.id,
    required this.date,
    required this.name,
    this.day,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final dateRaw = json['holiday_date'] ?? json['date'];
    if (dateRaw != null) {
      try {
        parsedDate = DateTime.parse(dateRaw.toString());
      } catch (_) {
        parsedDate = DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    final idVal = json['id'];
    int? parsedId;
    if (idVal is int) {
      parsedId = idVal;
    } else if (idVal != null) {
      parsedId = int.tryParse(idVal.toString());
    }

    return Holiday(
      id: parsedId,
      date: parsedDate,
      name: (json['holiday_name'] ?? json['name'] ?? '').toString(),
      day: json['day']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'holiday_date': DateFormat('yyyy-MM-dd').format(date),
      'holiday_name': name,
      if (day != null) 'day': day,
    };
  }
}

class HolidayResponse {
  final bool status;
  final String message;
  final int? year;
  final List<Holiday> data;

  HolidayResponse({
    required this.status,
    required this.message,
    this.year,
    required this.data,
  });

  factory HolidayResponse.fromJson(Map<String, dynamic> json) {
    final yearVal = json['year'];
    int? parsedYear;
    if (yearVal is int) {
      parsedYear = yearVal;
    } else if (yearVal != null) {
      parsedYear = int.tryParse(yearVal.toString());
    }

    final list = json['data'] as List<dynamic>?;

    return HolidayResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      year: parsedYear,
      data: list != null
          ? list.map((item) => Holiday.fromJson(item as Map<String, dynamic>)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      if (year != null) 'year': year,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}
