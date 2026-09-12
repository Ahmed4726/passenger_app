// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:passenger_app/features/bookings/data/booking.dart';
import 'package:passenger_app/features/bookings/presentation/pages/booking_flow_pages.dart';
import 'package:passenger_app/features/trips/data/trip.dart';

void main() {
  final trip = Trip.fromJson({
    'id': 12,
    'status': 'scheduled',
    'driver_name': 'Driver',
    'vehicle_name': 'Van',
    'available_seats': 2,
    'total_capacity': 4,
    'from_stop': {'display_name': 'Stop A'},
    'to_stop': {'display_name': 'Stop B'},
  });

  test('scheduled trip remains bookable and exposes trip data', () {
    expect(trip.canBook, isTrue);
    expect(trip.status, 'scheduled');
    expect(trip.departureTime, isNull);
    expect(trip.fromName, 'Stop A');
    expect(trip.toName, 'Stop B');
  });

  test('started trip parses live driver data and marks live status', () {
    final liveTrip = Trip.fromJson({
      'id': 21,
      'status': 'started',
      'driver_name': 'Driver',
      'vehicle_name': 'Van',
      'available_seats': 1,
      'total_capacity': 4,
      'from_stop': {'id': 1, 'display_name': 'Origin', 'latitude': 31.5, 'longitude': 74.3},
      'to_stop': {'id': 2, 'display_name': 'Destination', 'latitude': 31.6, 'longitude': 74.4},
      'departure_time': '08:00',
      'trip_date': '2026-09-11',
      'driver_location': {'latitude': 31.52, 'longitude': 74.32, 'recorded_at': '2026-09-11T08:05:00Z'},
      'next_stop': {'display_name': 'Midtown'},
      'eta_to_passenger_stop_minutes': 4,
      'distance_to_passenger_stop_km': 2.4,
      'driver_speed_kmh': 32.5,
    });

    expect(liveTrip.isLive, isTrue);
    expect(liveTrip.statusLabel, 'LIVE');
    expect(liveTrip.driverSpeedKmh, 32.5);
    expect(liveTrip.etaToPassengerStopMinutes, 4);
    expect(liveTrip.distanceToPassengerStopKm, 2.4);
  });

  test('booking parses null fare fields without failing', () {
    final booking = Booking.fromJson({
      'id': 1,
      'booking_reference': 'TE-TEST',
      'seats': 1,
      'status': 'confirmed',
      'fare_per_seat': null,
      'total_fare': null,
      'trip': <String, dynamic>{
        'id': 12,
        'status': 'scheduled',
        'driver_name': 'Driver',
        'vehicle_name': 'Van',
        'available_seats': 2,
        'total_capacity': 4,
      },
    });

    expect(booking.farePerSeat, isNull);
    expect(booking.totalFare, isNull);
  });
}
