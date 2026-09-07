import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_client.dart';
import '../../trips/data/trip.dart';
import 'booking.dart';

class BookingApi {
  const BookingApi();

  Future<List<Booking>> listBookings() async {
    try {
      final response = await (await _authenticated()).get(
        '/passenger/bookings',
      );
      final data = response.data is Map ? response.data['data'] : null;
      if (data is! List) {
        throw ApiException(message: 'The bookings response was invalid.');
      }
      return data
          .whereType<Map>()
          .map((item) => Booking.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Booking> getBooking(int bookingId) async {
    try {
      final response = await (await _authenticated()).get(
        '/passenger/bookings/$bookingId',
      );
      return _parseBooking(response);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Booking> cancelBooking(int bookingId) async {
    try {
      final response = await (await _authenticated()).post(
        '/passenger/bookings/$bookingId/cancel',
      );
      return _parseBooking(response);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Booking> createBooking({
    required int tripId,
    required int seats,
    required int fromStopId,
    required int toStopId,
    Trip? fallbackTrip,
  }) async {
    try {
      final response = await (await _authenticated()).post(
        '/passenger/bookings',
        data: {
          'trip_id': tripId,
          'from_stop_id': fromStopId,
          'to_stop_id': toStopId,
          'seats': seats,
        },
      );
      final data = response.data is Map ? response.data['data'] : null;
      if (data is! Map) {
        throw ApiException(message: 'The booking response was invalid.');
      }
      final booking = Booking.fromJson(Map<String, dynamic>.from(data));
      return Booking(
        id: booking.id,
        reference: booking.reference,
        seats: booking.seats,
        status: booking.status,
        trip: fallbackTrip ?? booking.trip,
        farePerSeat: booking.farePerSeat,
        totalFare: booking.totalFare,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Dio> _authenticated() async {
    final token = await DioClient.getStoredToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        message: 'Your session has expired. Please sign in again.',
        statusCode: 401,
      );
    }
    await DioClient.setAuthToken(token);
    return DioClient.dio;
  }

  Booking _parseBooking(Response<dynamic> response) {
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map) {
      throw ApiException(message: 'The booking response was invalid.');
    }
    return Booking.fromJson(Map<String, dynamic>.from(data));
  }
}
