import '../../trips/data/trip.dart';

class Booking {
  const Booking({
    required this.id,
    required this.reference,
    required this.seats,
    required this.status,
    required this.trip,
    this.farePerSeat,
    this.totalFare,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final tripJson = json['trip'];
    return Booking(
      id: _asInt(json['id']) ?? 0,
      reference: json['booking_reference']?.toString() ?? '',
      seats: _asInt(json['seats']) ?? 0,
      status: json['status']?.toString() ?? 'unknown',
      trip: tripJson is Map
          ? Trip.fromJson(Map<String, dynamic>.from(tripJson))
          : null,
      farePerSeat: _asDouble(json['fare_per_seat']),
      totalFare: _asDouble(json['total_fare']),
    );
  }

  final int id;
  final String reference;
  final int seats;
  final String status;
  final Trip? trip;
  final double? farePerSeat;
  final double? totalFare;

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
