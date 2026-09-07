import 'package:flutter/material.dart';

import '../../../../core/api/api_exception.dart';
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

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final maxSeats = trip.availableSeats.clamp(0, 4);
    final soldOut = !trip.canBook;
    return Scaffold(
      appBar: AppBar(title: const Text('Trip details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '${trip.fromName} to ${trip.toName}',
            style: AppTextStyles.heading,
          ),
          const SizedBox(height: 8),
          Text(
            '${trip.driverName} • ${trip.vehicleName}',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 24),
          _DetailRow(
            label: 'Departure',
            value: trip.departureTime ?? 'Not provided',
          ),
          _DetailRow(
            label: 'Trip date',
            value: trip.tripDate ?? 'Not provided',
          ),
          _DetailRow(label: 'Status', value: trip.status),
          _DetailRow(
            label: 'Available seats',
            value: '${trip.availableSeats} / ${trip.totalCapacity}',
          ),
          if (trip.etaToNextStop != null)
            _DetailRow(
              label: 'ETA to next stop',
              value: '${trip.etaToNextStop} min',
            ),
          const SizedBox(height: 28),
          if (soldOut)
            _Notice(
              text: trip.availableSeats == 0
                  ? 'This trip is sold out.'
                  : 'This trip is no longer available for booking.',
            ),
          if (!soldOut) ...[
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
                  child: Text('$_seats', style: AppTextStyles.heading),
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
  const _Notice({required this.text});

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
