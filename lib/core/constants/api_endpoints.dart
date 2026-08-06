class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/auth/login';
  static const String registerPassenger = '/auth/register/passenger';
  static const String logout = '/logout';
  static const String cities = '/cities';
  static const String cityStops = '/cities/{cityId}/stops';
  static const String passengerTrips = '/passenger-trips';
  static const String driverTripLocations = '/driver-trips/{tripId}/locations';
  static const String latestDriverTripLocation = '/driver-trips/{tripId}/locations/latest';
}
