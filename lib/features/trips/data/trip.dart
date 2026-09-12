class Trip {
  const Trip({
    required this.id,
    required this.status,
    required this.driverName,
    required this.driverPhone,
    required this.vehicleName,
    required this.departureTime,
    required this.availableSeats,
    required this.totalCapacity,
    this.fromStop,
    this.toStop,
    this.tripDate,
    this.currentLocation,
    this.nextStop,
    this.driverLocation,
    this.distanceToPassengerStopKm,
    this.etaToPassengerStopMinutes,
    this.etaToNextStop,
    this.driverSpeedKmh,
    this.lastUpdatedAt,
    this.bookingOpen,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    final currentLocation = _asMap(json['current_location']);
    final nextStop = _asMap(json['next_stop']);
    final driverLocation = _asMap(json['driver_location']);

    return Trip(
      id: _asInt(json['id']) ?? 0,
      status: json['status']?.toString() ?? 'unknown',
      driverName: json['driver_name']?.toString() ?? 'Driver',
      driverPhone: json['driver_phone']?.toString(),
      vehicleName: json['vehicle_name']?.toString() ?? 'Vehicle',
      departureTime: json['departure_time']?.toString(),
      availableSeats: _asInt(json['available_seats']) ?? 0,
      totalCapacity: _asInt(json['total_capacity']) ?? 0,
      fromStop: _asMap(json['from_stop']),
      toStop: _asMap(json['to_stop']),
      tripDate: json['trip_date']?.toString(),
      currentLocation: currentLocation,
      nextStop: nextStop,
      driverLocation: driverLocation,
      distanceToPassengerStopKm: _asDouble(json['distance_to_passenger_stop_km']) ??
          _asDouble(json['distance_to_next_stop_km']) ??
          _asDouble(json['distance_km']),
      etaToPassengerStopMinutes: _asInt(json['eta_to_passenger_stop_minutes']) ??
          _asInt(json['eta_to_next_stop']),
      etaToNextStop: _asInt(json['eta_to_next_stop']) ??
          _asInt(json['eta_to_passenger_stop_minutes']),
      driverSpeedKmh: _asDouble(json['driver_speed_kmh']) ??
          _asDouble(json['speed_kmh']),
      lastUpdatedAt: json['last_updated_at']?.toString() ??
          driverLocation?['recorded_at']?.toString() ??
          currentLocation?['recorded_at']?.toString(),
        bookingOpen: json['can_book'] is bool ? json['can_book'] as bool : null,
    );
  }

  final int id;
  final String status;
  final String driverName;
  final String? driverPhone;
  final String vehicleName;
  final String? departureTime;
  final int availableSeats;
  final int totalCapacity;
  final Map<String, dynamic>? fromStop;
  final Map<String, dynamic>? toStop;
  final String? tripDate;
  final Map<String, dynamic>? currentLocation;
  final Map<String, dynamic>? nextStop;
  final Map<String, dynamic>? driverLocation;
  final double? distanceToPassengerStopKm;
  final int? etaToPassengerStopMinutes;
  final int? etaToNextStop;
  final double? driverSpeedKmh;
  final String? lastUpdatedAt;
  final bool? bookingOpen;

  String get fromName => _stopName(fromStop, 'Origin');
  String get toName => _stopName(toStop, 'Destination');
  String get statusLabel => isLive ? 'LIVE' : status.toUpperCase();
  bool get isLive => status == 'started';
  bool get canBook => (bookingOpen ?? status == 'scheduled') && availableSeats > 0;

  static Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static String _stopName(Map<String, dynamic>? stop, String fallback) {
    return stop?['display_name']?.toString() ??
        stop?['address']?.toString() ??
        stop?['city_name']?.toString() ??
        fallback;
  }
}
