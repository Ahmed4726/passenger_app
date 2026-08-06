import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _permissionDenied = false;
  bool _permissionPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await _startAppFlow();
  }

  Future<void> _startAppFlow() async {
    if (!mounted) return;

    final permissionGranted = await _requestLocationPermission();
    if (!permissionGranted) return;

    final token = await DioClient.getStoredToken();
    if (token != null && token.isNotEmpty) {
      await DioClient.setAuthToken(token);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<bool> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.locationWhenInUse.request();
    if (result.isGranted) {
      return true;
    }

    if (!mounted) return false;
    setState(() {
      _permissionDenied = true;
      _permissionPermanentlyDenied = result.isPermanentlyDenied;
    });
    return false;
  }

  Future<void> _retryPermission() async {
    if (!mounted) return;
    setState(() {
      _permissionDenied = false;
      _permissionPermanentlyDenied = false;
    });

    if (await _requestLocationPermission()) {
      await _startAppFlow();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(Icons.location_on, size: 90, color: AppColors.white),
                  ),
                  const SizedBox(height: 28),
                  Text('Location permission required', style: AppTextStyles.heading.copyWith(color: AppColors.white)),
                  const SizedBox(height: 10),
                  Text(
                    _permissionPermanentlyDenied
                        ? 'Location permission is permanently denied. Open settings, then restart the app to continue.'
                        : 'Location access is required for the app to function correctly. Please grant permission to continue.',
                    style: AppTextStyles.subtitle.copyWith(color: AppColors.white.withOpacity(0.85)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _permissionPermanentlyDenied
                        ? () async {
                            await openAppSettings();
                          }
                        : _retryPermission,
                    child: Text(_permissionPermanentlyDenied ? 'Open settings' : 'Grant location access'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(Icons.route_outlined, size: 90, color: AppColors.white),
                ),
                const SizedBox(height: 28),
                Text('Transport Ease', style: AppTextStyles.heading.copyWith(color: AppColors.white)),
                const SizedBox(height: 10),
                Text('Your journey starts here', style: AppTextStyles.subtitle.copyWith(color: AppColors.white.withOpacity(0.85))),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
