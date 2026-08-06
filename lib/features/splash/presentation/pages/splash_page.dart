import 'package:flutter/material.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
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
