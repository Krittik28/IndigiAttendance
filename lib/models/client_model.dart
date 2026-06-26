class Client {
  final int id;
  final String customerName;
  final String? clientShortName;
  final String label;

  Client({
    required this.id,
    required this.customerName,
    this.clientShortName,
    required this.label,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      customerName: json['customer_name'] ?? '',
      clientShortName: json['client_short_name'],
      label: json['label'] ?? '',
    );
  }
}
