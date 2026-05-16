import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;

  const OnboardingPage({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large animated icon
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 100,
              color: iconColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXLarge),

          // Title
          Text(
            title,
            style: AppTheme.headingLarge.copyWith(
              color: AppTheme.primaryBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMedium),

          // Description
          Text(
            description,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
