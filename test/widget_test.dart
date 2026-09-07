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

  testWidgets('seat selector starts at one and respects availability', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: TripDetailsPage(trip: trip)));

    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.byTooltip('Add a seat'));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.byTooltip('Add a seat'));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
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
