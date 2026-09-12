import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../trips/data/trip.dart';
import '../../data/booking.dart';
import '../../data/booking_api.dart';

class TripDetailsPage extends StatefulWidget {
  const TripDetailsPage({super.key, required this.trip});

  final Trip trip;

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  int _seats = 1;
  bool _refreshing = false;
  Timer? _pollTimer;
  Trip _trip = const Trip(
    id: 0,
    status: 'scheduled',
    driverName: 'Driver',
    driverPhone: null,
    vehicleName: 'Vehicle',
    departureTime: null,
    availableSeats: 0,
    totalCapacity: 0,
  );

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startPolling() async {
    _pollTimer?.cancel();
    if (_trip.status != 'started') return;

    await _refreshTripData();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      _refreshTripData();
    });
  }

  Future<void> _refreshTripData() async {
    final trip = _trip;
    final fromStopId = trip.fromStop?['id'];
    final toStopId = trip.toStop?['id'];
    if (fromStopId == null || toStopId == null) {
      return;
    }

    setState(() => _refreshing = true);

    try {
      final response = await DioClient.dio.get(
        '/passenger-trips',
        queryParameters: {'from_stop_id': fromStopId, 'to_stop_id': toStopId},
      );

      final rawTrips = response.data is Map ? response.data['data'] : null;
      if (rawTrips is! List) {
        return;
      }

      final nextTrip = rawTrips.whereType<Map>().firstWhere(
        (item) => (item['id'] as num?) == trip.id,
        orElse: () => <String, dynamic>{},
      );

      if (nextTrip.isEmpty) {
        return;
      }

      if (!mounted) return;
      setState(() {
        _trip = Trip.fromJson(Map<String, dynamic>.from(nextTrip));
        if (_trip.status != 'started') {
          _pollTimer?.cancel();
          _pollTimer = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    final maxSeats = trip.availableSeats.clamp(0, 4);
    final showBooking = trip.canBook;
    final showLiveNotice = trip.isLive && !trip.canBook;
    final hasRouteCoordinates = _hasCoordinates(trip);
    final hasDriverLocation = _hasDriverCoordinates(trip);
    final mapTarget = hasDriverLocation
        ? _driverCoordinate(trip)
        : hasRouteCoordinates
            ? _midpointCoordinate(trip)
            : const LatLng(0, 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip details'),
        actions: [
          if (trip.isLive)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    trip.statusLabel,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTripData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${trip.fromName} → ${trip.toName}',
                    style: AppTextStyles.heading,
                  ),
                ),
                if (_refreshing)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${trip.driverName} • ${trip.vehicleName}',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 20),
            if (hasRouteCoordinates)
              SizedBox(
                height: 260,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: mapTarget,
                      zoom: hasDriverLocation ? 12 : 10,
                    ),
                    markers: {
                      if (hasDriverLocation)
                        Marker(
                          markerId: const MarkerId('driver'),
                          position: _driverCoordinate(trip),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure,
                          ),
                          infoWindow: const InfoWindow(title: 'Driver live location'),
                        ),
                      Marker(
                        markerId: const MarkerId('origin'),
                        position: _coordinate(trip.fromStop),
                        infoWindow: const InfoWindow(title: 'Origin'),
                      ),
                      Marker(
                        markerId: const MarkerId('destination'),
                        position: _coordinate(trip.toStop),
                        infoWindow: const InfoWindow(title: 'Destination'),
                      ),
                    },
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId('journey'),
                        points: [
                          _coordinate(trip.fromStop),
                          _coordinate(trip.toStop),
                        ],
                        color: AppColors.primary,
                        width: 4,
                      ),
                    },
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Driver location unavailable',
                  style: AppTextStyles.body,
                ),
              ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _LiveStatRow(
                    label: 'Next stop',
                    value: trip.nextStop?['display_name'] ?? trip.currentLocation?['display_name'] ?? 'Waiting',
                  ),
                  _LiveStatRow(
                    label: 'ETA',
                    value: trip.etaToPassengerStopMinutes != null
                        ? '${trip.etaToPassengerStopMinutes} min'
                        : trip.etaToNextStop != null
                            ? '${trip.etaToNextStop} min'
                            : 'Unavailable',
                  ),
                  _LiveStatRow(
                    label: 'Distance',
                    value: trip.distanceToPassengerStopKm != null
                        ? '${trip.distanceToPassengerStopKm!.toStringAsFixed(1)} km'
                        : 'Unavailable',
                  ),
                  _LiveStatRow(
                    label: 'Speed',
                    value: trip.driverSpeedKmh != null
                        ? '${trip.driverSpeedKmh!.toStringAsFixed(1)} km/h'
                        : 'Speed unavailable',
                  ),
                  _LiveStatRow(
                    label: 'Last updated',
                    value: trip.lastUpdatedAt != null
                        ? _formatTime(trip.lastUpdatedAt)
                        : 'Not available',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (trip.driverPhone != null && trip.driverPhone!.trim().isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _callDriver(trip.driverPhone!),
                      icon: const Icon(Icons.phone_outlined),
                      label: const Text('Call driver'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _messageDriver(trip.driverPhone!),
                      icon: const Icon(Icons.message_outlined),
                      label: const Text('Message'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            _DetailRow(label: 'Departure', value: trip.departureTime ?? 'Not provided'),
            _DetailRow(label: 'Trip date', value: trip.tripDate ?? 'Not provided'),
            _DetailRow(label: 'Status', value: trip.statusLabel),
            _DetailRow(
              label: 'Capacity',
              value: '${trip.availableSeats} seats left / ${trip.totalCapacity}',
            ),
            _DetailRow(
              label: 'Passengers',
              value: '${trip.totalCapacity - trip.availableSeats} onboard',
            ),
            const SizedBox(height: 28),
            if (showLiveNotice)
              const _Notice(
                key: ValueKey('booking-closed-notice'),
                text: 'Booking is closed for this trip.',
              ),
            if (!showBooking && !showLiveNotice)
              _Notice(
                text: trip.availableSeats == 0
                    ? 'This trip is sold out.'
                    : 'This trip is no longer available for booking.',
              ),
            if (showBooking) ...[
              Text('Choose seats', style: AppTextStyles.title),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Remove a seat',
                    onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '$_seats',
                      key: const ValueKey('seat-count'),
                      style: AppTextStyles.heading,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add a seat',
                    onPressed: _seats < maxSeats
                        ? () => setState(() => _seats++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              Text(
                'Select 1 to $maxSeats seat${maxSeats == 1 ? '' : 's'}',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/booking-summary',
                    arguments: {'trip': trip, 'seats': _seats},
                  ),
                  icon: const Icon(Icons.event_seat_outlined),
                  label: const Text('Review booking'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasCoordinates(Trip trip) {
    return trip.fromStop?['latitude'] is num &&
        trip.fromStop?['longitude'] is num &&
        trip.toStop?['latitude'] is num &&
        trip.toStop?['longitude'] is num;
  }

  bool _hasDriverCoordinates(Trip trip) {
    return trip.driverLocation?['latitude'] is num &&
        trip.driverLocation?['longitude'] is num;
  }

  LatLng _coordinate(Map<String, dynamic>? stop) {
    return LatLng(
      (stop?['latitude'] as num? ?? 0).toDouble(),
      (stop?['longitude'] as num? ?? 0).toDouble(),
    );
  }

  LatLng _driverCoordinate(Trip trip) {
    return LatLng(
      (trip.driverLocation?['latitude'] as num).toDouble(),
      (trip.driverLocation?['longitude'] as num).toDouble(),
    );
  }

  LatLng _midpointCoordinate(Trip trip) {
    final from = _coordinate(trip.fromStop);
    final to = _coordinate(trip.toStop);
    return LatLng(
      (from.latitude + to.latitude) / 2,
      (from.longitude + to.longitude) / 2,
    );
  }

  Future<void> _callDriver(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber.trim());
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the phone dialer.')),
      );
    }
  }

  Future<void> _messageDriver(String phoneNumber) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat is available after your booking is confirmed.'),
      ),
    );
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Not available';
    }

    final date = DateTime.tryParse(value);
    if (date == null) return value;
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) {
      return 'just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }
    return '${difference.inHours} hr ago';
  }
}

class _LiveStatRow extends StatelessWidget {
  const _LiveStatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTextStyles.subtitle),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class BookingSummaryPage extends StatefulWidget {
  const BookingSummaryPage({
    super.key,
    required this.trip,
    required this.seats,
  });

  final Trip trip;
  final int seats;

  @override
  State<BookingSummaryPage> createState() => _BookingSummaryPageState();
}

class _BookingSummaryPageState extends State<BookingSummaryPage> {
  bool _submitting = false;
  String? _error;

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final booking = await const BookingApi().createBooking(
        tripId: widget.trip.id,
        seats: widget.seats,
        fromStopId: _stopId(widget.trip.fromStop),
        toStopId: _stopId(widget.trip.toStop),
        fallbackTrip: widget.trip,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/booking-success',
        arguments: booking,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _friendlyMessage(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Network error. Check your connection and try again.';
      });
    }
  }

  int _stopId(Map<String, dynamic>? stop) {
    final value = stop?['id'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _friendlyMessage(ApiException error) {
    if (error.statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    final message = error.message.toLowerCase();
    if (message.contains('not enough seats')) {
      return 'Not enough seats are available. Please choose fewer seats or another trip.';
    }
    if (message.contains('already have')) {
      return 'You already have a booking for this trip.';
    }
    if (message.contains('started')) {
      return 'This trip has already started.';
    }
    if (message.contains('not available')) {
      return 'This trip is no longer available.';
    }
    return error.message;
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking summary')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Review your ride', style: AppTextStyles.heading),
          const SizedBox(height: 24),
          _DetailRow(label: 'From', value: trip.fromName),
          _DetailRow(label: 'To', value: trip.toName),
          _DetailRow(
            label: 'Departure',
            value: trip.departureTime ?? 'Not provided',
          ),
          _DetailRow(label: 'Seats', value: '${widget.seats}'),
          const SizedBox(height: 12),
          Text(
            'Status after confirmation: confirmed',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (_error != null) _Notice(text: _error!),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _confirm,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_submitting ? 'Confirming...' : 'Confirm booking'),
            ),
          ),
        ],
      ),
    );
  }
}

class BookingSuccessPage extends StatelessWidget {
  const BookingSuccessPage({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final trip = booking.trip;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking confirmed')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 72),
          const SizedBox(height: 16),
          Text(
            'Booking confirmed',
            style: AppTextStyles.heading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            booking.reference,
            style: AppTextStyles.title.copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your ride has been confirmed.',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (trip != null) ...[
            _DetailRow(label: 'From', value: trip.fromName),
            _DetailRow(label: 'To', value: trip.toName),
            _DetailRow(
              label: 'Departure',
              value: trip.departureTime ?? 'Not provided',
            ),
          ],
          _DetailRow(label: 'Seats', value: '${booking.seats}'),
          _DetailRow(label: 'Status', value: booking.status),
          if (booking.farePerSeat != null)
            _DetailRow(
              label: 'Fare per seat',
              value: booking.farePerSeat!.toStringAsFixed(2),
            ),
          if (booking.totalFare != null)
            _DetailRow(
              label: 'Total fare',
              value: booking.totalFare!.toStringAsFixed(2),
            ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/my-bookings',
              ModalRoute.withName('/home'),
            ),
            icon: const Icon(Icons.route_outlined),
            label: const Text('View my bookings'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () =>
                Navigator.popUntil(context, ModalRoute.withName('/home')),
            icon: const Icon(Icons.route_outlined),
            label: const Text('Back to trips'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AppTextStyles.subtitle),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          color: AppColors.danger,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
