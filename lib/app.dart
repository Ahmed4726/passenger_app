import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/bookings/data/booking.dart';
import 'features/bookings/presentation/pages/booking_flow_pages.dart';
import 'features/bookings/presentation/pages/my_bookings_page.dart';
import 'features/trips/data/trip.dart';

class PassengerApp extends StatelessWidget {
  const PassengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transport Ease Passenger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.white,
          secondary: AppColors.info,
          background: AppColors.background,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 18,
          ),
        ),
        textTheme: const TextTheme(
          headlineSmall: AppTextStyles.heading,
          titleLarge: AppTextStyles.title,
          titleMedium: AppTextStyles.subtitle,
          bodyMedium: AppTextStyles.body,
          labelLarge: AppTextStyles.button,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            side: const BorderSide(color: AppColors.primary),
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const HomePage(),
        '/my-bookings': (_) => const MyBookingsPage(),
        '/booking-details': (context) => BookingDetailsPage(
          booking: ModalRoute.of(context)!.settings.arguments as Booking,
        ),
        '/trip-details': (context) => TripDetailsPage(
          trip: ModalRoute.of(context)!.settings.arguments is Trip
              ? ModalRoute.of(context)!.settings.arguments as Trip
              : Trip.fromJson(
                  Map<String, dynamic>.from(
                    ModalRoute.of(context)!.settings.arguments as Map,
                  ),
                ),
        ),
        '/booking-summary': (context) {
          final arguments = ModalRoute.of(context)!.settings.arguments as Map;
          return BookingSummaryPage(
            trip: arguments['trip'] as Trip,
            seats: arguments['seats'] as int,
          );
        },
        '/booking-success': (context) => BookingSuccessPage(
          booking: ModalRoute.of(context)!.settings.arguments as Booking,
        ),
      },
    );
  }
}
