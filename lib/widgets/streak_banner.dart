import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StreakBanner extends StatelessWidget {
  final int streakDays;
  final int totalDoses;

  const StreakBanner({
    Key? key,
    required this.streakDays,
    required this.totalDoses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall + 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF2E1A00),
                  const Color(0xFF1A0A00),
                ]
              : [
                  const Color(0xFFFF9800),
                  const Color(0xFFFF5722),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: isDark
            ? Border.all(color: Colors.orange.withOpacity(0.3))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: AppTheme.spacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streakDays Day Streak!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.orange[200] : Colors.white,
                  ),
                ),
                Text(
                  '$totalDoses doses taken',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.orange[100]?.withOpacity(0.7)
                        : Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
