import 'package:flutter/material.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../data/booking.dart';
import '../../data/booking_api.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final BookingApi _bookingApi = const BookingApi();
  List<Booking> _bookings = [];
  bool _loading = true;
  String? _error;
  int _category = 0;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings({bool refreshing = false}) async {
    if (!refreshing) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final bookings = await _bookingApi.listBookings();
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load bookings. Please try again.';
      });
    }
  }

  String _friendlyError(ApiException error) {
    if (error.statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    return 'Unable to load bookings. Please try again.';
  }

  List<Booking> get _visibleBookings {
    return _bookings.where((booking) {
      final past = const {
        'cancelled',
        'completed',
        'no_show',
      }.contains(booking.status);
      return _category == 0 ? !past : past;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My bookings')),
      body: RefreshIndicator(
        onRefresh: () => _loadBookings(refreshing: true),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 90),
          const Icon(
            Icons.cloud_off_outlined,
            size: 52,
            color: AppColors.danger,
          ),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.body),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _loadBookings,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    final bookings = _visibleBookings;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 0,
              label: Text('Upcoming'),
              icon: Icon(Icons.upcoming_outlined),
            ),
            ButtonSegment(
              value: 1,
              label: Text('Past'),
              icon: Icon(Icons.history),
            ),
          ],
          selected: {_category},
          onSelectionChanged: (selection) =>
              setState(() => _category = selection.first),
        ),
        const SizedBox(height: 16),
        if (bookings.isEmpty)
          _EmptyBookings(category: _category)
        else
          ...bookings.map(_buildBookingCard),
      ],
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final trip = booking.trip;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          '/booking-details',
          arguments: booking,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.reference.isEmpty ? 'Booking' : booking.reference,
                      style: AppTextStyles.title,
                    ),
                  ),
                  _StatusPill(status: booking.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${_stopName(trip?.fromStop, 'Origin unavailable')} to ${_stopName(trip?.toStop, 'Destination unavailable')}',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 8),
              Text(
                'Departure: ${trip?.departureTime ?? 'Not provided'}  •  Seats: ${booking.seats}',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (booking.totalFare != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Total fare: ${booking.totalFare!.toStringAsFixed(2)}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _stopName(Map<String, dynamic>? stop, String fallback) {
    return stop?['display_name']?.toString() ??
        stop?['address']?.toString() ??
        fallback;
  }
}

class BookingDetailsPage extends StatefulWidget {
  const BookingDetailsPage({super.key, required this.booking});

  final Booking booking;

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  final BookingApi _bookingApi = const BookingApi();
  late Booking _booking = widget.booking;
  bool _loading = true;
  bool _cancelling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final booking = await _bookingApi.getBooking(_booking.id);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.statusCode == 401
            ? 'Your session has expired. Please sign in again.'
            : 'Unable to load booking details.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load booking details.';
      });
    }
  }

  Future<void> _confirmCancellation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _cancelBooking();
  }

  Future<void> _cancelBooking() async {
    if (_cancelling) return;
    setState(() {
      _cancelling = true;
      _error = null;
    });
    try {
      final booking = await _bookingApi.cancelBooking(_booking.id);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _cancelling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _cancelling = false;
        _error = _friendlyCancellationError(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cancelling = false;
        _error = 'Network error. Your booking was not changed.';
      });
    }
  }

  String _friendlyCancellationError(ApiException error) {
    final message = error.message.toLowerCase();
    if (message.contains('started')) {
      return 'This booking can no longer be cancelled because the trip has started.';
    }
    if (message.contains('cancel')) {
      return 'This booking can no longer be cancelled.';
    }
    if (error.statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    return 'Unable to cancel this booking. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final trip = _booking.trip;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_error != null) _Notice(text: _error!),
                Text(
                  _booking.reference.isEmpty ? 'Booking' : _booking.reference,
                  style: AppTextStyles.heading,
                ),
                const SizedBox(height: 8),
                _StatusPill(status: _booking.status),
                const SizedBox(height: 24),
                _DetailRow(
                  label: 'From',
                  value: _stopName(trip?.fromStop, 'Origin unavailable'),
                ),
                _DetailRow(
                  label: 'To',
                  value: _stopName(trip?.toStop, 'Destination unavailable'),
                ),
                _DetailRow(
                  label: 'Departure',
                  value: trip?.departureTime ?? 'Not provided',
                ),
                _DetailRow(
                  label: 'Trip status',
                  value: _humanStatus(trip?.status ?? 'unknown'),
                ),
                _DetailRow(label: 'Seats', value: '${_booking.seats}'),
                if (_booking.farePerSeat != null)
                  _DetailRow(
                    label: 'Fare per seat',
                    value: _booking.farePerSeat!.toStringAsFixed(2),
                  ),
                if (_booking.totalFare != null)
                  _DetailRow(
                    label: 'Total fare',
                    value: _booking.totalFare!.toStringAsFixed(2),
                  ),
                const SizedBox(height: 28),
                if (_booking.status == 'confirmed') ...[
                  FilledButton.icon(
                    onPressed: _cancelling ? null : _confirmCancellation,
                    icon: _cancelling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cancel_outlined),
                    label: Text(
                      _cancelling ? 'Cancelling...' : 'Cancel booking',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if ((_booking.trip?.driverPhone ?? '').trim().isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(booking: _booking),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Message driver'),
                  ),
                ],
              ],
            ),
    );
  }

  static String _stopName(Map<String, dynamic>? stop, String fallback) {
    return stop?['display_name']?.toString() ??
        stop?['address']?.toString() ??
        fallback;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'confirmed' || status == 'boarded'
        ? AppColors.success
        : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _humanStatus(status),
        style: AppTextStyles.body.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
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
      margin: const EdgeInsets.only(bottom: 20),
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

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings({required this.category});

  final int category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Column(
        children: [
          const Icon(
            Icons.event_note_outlined,
            size: 56,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            category == 0 ? 'No upcoming bookings' : 'No past bookings',
            style: AppTextStyles.title,
          ),
          const SizedBox(height: 10),
          Text(
            category == 0
                ? 'Find a trip when you are ready to travel.'
                : 'Your completed and cancelled bookings will appear here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          if (category == 0) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.search),
              label: const Text('Find a trip'),
            ),
          ],
        ],
      ),
    );
  }
}

String _humanStatus(String status) {
  switch (status) {
    case 'confirmed':
      return 'Confirmed';
    case 'cancelled':
      return 'Cancelled';
    case 'boarded':
      return 'Boarded';
    case 'completed':
      return 'Completed';
    case 'no_show':
      return 'No Show';
    default:
      return status.isEmpty ? 'Unknown' : status;
  }
}
