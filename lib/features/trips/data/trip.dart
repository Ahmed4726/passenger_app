class Trip {
  const Trip({
    required this.id,
    required this.status,
    required this.driverName,
    required this.vehicleName,
    required this.departureTime,
    required this.availableSeats,
    required this.totalCapacity,
    this.fromStop,
    this.toStop,
    this.tripDate,
    this.currentLocation,
    this.etaToNextStop,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: _asInt(json['id']) ?? 0,
      status: json['status']?.toString() ?? 'unknown',
      driverName: json['driver_name']?.toString() ?? 'Driver',
      vehicleName: json['vehicle_name']?.toString() ?? 'Vehicle',
      departureTime: json['departure_time']?.toString(),
      availableSeats: _asInt(json['available_seats']) ?? 0,
      totalCapacity: _asInt(json['total_capacity']) ?? 0,
      fromStop: _asMap(json['from_stop']),
      toStop: _asMap(json['to_stop']),
      tripDate: json['trip_date']?.toString(),
      currentLocation: _asMap(json['current_location']),
      etaToNextStop: _asInt(json['eta_to_next_stop']),
    );
  }

  final int id;
  final String status;
  final String driverName;
  final String vehicleName;
  final String? departureTime;
  final int availableSeats;
  final int totalCapacity;
  final Map<String, dynamic>? fromStop;
  final Map<String, dynamic>? toStop;
  final String? tripDate;
  final Map<String, dynamic>? currentLocation;
  final int? etaToNextStop;

  String get fromName => _stopName(fromStop, 'Origin');
  String get toName => _stopName(toStop, 'Destination');
  bool get canBook => status == 'scheduled' && availableSeats > 0;

  static Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _stopName(Map<String, dynamic>? stop, String fallback) {
    return stop?['display_name']?.toString() ??
        stop?['address']?.toString() ??
        fallback;
  }
}
