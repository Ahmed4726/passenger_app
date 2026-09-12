import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppDesign {
  AppDesign._();

  static const double pagePadding = 16;
  static const double cardRadius = 22;

  static BoxDecoration cardDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A0F172A),
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  static Widget loadingState({String? label}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(label, style: AppTextStyles.body),
          ],
        ],
      ),
    );
  }

  static Widget errorState({
    required String message,
    String? actionLabel,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: cardDecoration(color: AppColors.surface),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center, style: AppTextStyles.title),
              if (actionLabel != null && onRetry != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(actionLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: cardDecoration(color: AppColors.surface),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(title, style: AppTextStyles.title, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(subtitle, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
