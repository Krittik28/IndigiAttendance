class ClientVisit {
  final int id;
  final String employeeCode;
  final int clientId;
  final String clientName;
  final String? clientShortName;
  final String checkinTime;
  final String? checkoutTime;
  final String checkinLatitude;
  final String checkinLongitude;
  final String checkinLocation;
  final String? checkoutLatitude;
  final String? checkoutLongitude;
  final String? checkoutLocation;

  ClientVisit({
    required this.id,
    required this.employeeCode,
    required this.clientId,
    required this.clientName,
    this.clientShortName,
    required this.checkinTime,
    this.checkoutTime,
    required this.checkinLatitude,
    required this.checkinLongitude,
    required this.checkinLocation,
    this.checkoutLatitude,
    this.checkoutLongitude,
    this.checkoutLocation,
  });

  factory ClientVisit.fromJson(Map<String, dynamic> json) {
    return ClientVisit(
      id: json['id'],
      employeeCode: json['employee_code'].toString(),
      clientId: json['client_id'] is String ? int.parse(json['client_id']) : json['client_id'],
      clientName: json['client_name'] ?? json['customer_name'] ?? '',
      clientShortName: json['client_short_name'],
      checkinTime: json['checkin_time'],
      checkoutTime: json['checkout_time'],
      checkinLatitude: json['checkin_latitude'].toString(),
      checkinLongitude: json['checkin_longitude'].toString(),
      checkinLocation: json['checkin_location'] ?? '',
      checkoutLatitude: json['checkout_latitude']?.toString(),
      checkoutLongitude: json['checkout_longitude']?.toString(),
      checkoutLocation: json['checkout_location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_code': employeeCode,
      'client_id': clientId,
      'client_name': clientName,
      'client_short_name': clientShortName,
      'checkin_time': checkinTime,
      'checkout_time': checkoutTime,
      'checkin_latitude': checkinLatitude,
      'checkin_longitude': checkinLongitude,
      'checkin_location': checkinLocation,
      'checkout_latitude': checkoutLatitude,
      'checkout_longitude': checkoutLongitude,
      'checkout_location': checkoutLocation,
    };
  }
}
