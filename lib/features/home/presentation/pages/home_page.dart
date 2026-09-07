import 'package:flutter/material.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/trips/presentation/pages/trip_search_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await DioClient.dio.post('/logout');
    } catch (_) {}
    await DioClient.clearSession();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transport Ease'),
        actions: [
          IconButton(
            tooltip: 'My bookings',
            onPressed: () => Navigator.pushNamed(context, '/my-bookings'),
            icon: const Icon(Icons.confirmation_number_outlined),
          ),
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: const [
              SizedBox(height: 12),
              Expanded(child: TripSearchPage()),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to ride?',
            style: AppTextStyles.heading.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 10),
          Text(
            'Search live trips, pick your stop, and book a ride in seconds.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              _InfoChip(text: 'Live routes'),
              SizedBox(width: 10),
              _InfoChip(text: 'Easy pickup'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(color: AppColors.white),
      ),
    );
  }
}
