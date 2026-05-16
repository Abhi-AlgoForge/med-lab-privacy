import 'package:flutter/material.dart';
import '../models/medication_reminder.dart';
import '../theme/app_theme.dart';

class ReminderCard extends StatelessWidget {
  final MedicationReminder reminder;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggle;
  final bool takenToday;
  final VoidCallback? onMarkTaken;

  const ReminderCard({
    Key? key,
    required this.reminder,
    this.onTap,
    this.onDelete,
    this.onToggle,
    this.takenToday = false,
    this.onMarkTaken,
  }) : super(key: key);

  IconData _getTimingIcon() {
    switch (reminder.timing) {
      case MedicationTiming.morning:
        return Icons.wb_sunny;
      case MedicationTiming.afternoon:
        return Icons.wb_twilight;
      case MedicationTiming.night:
        return Icons.nightlight_round;
    }
  }

  Color _getTimingColor() {
    switch (reminder.timing) {
      case MedicationTiming.morning:
        return const Color(0xFFFFB74D);
      case MedicationTiming.afternoon:
        return const Color(0xFF64B5F6);
      case MedicationTiming.night:
        return const Color(0xFF7E57C2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingLarge),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 32,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
          vertical: AppTheme.spacingSmall,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Row(
              children: [
                // Timing icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getTimingColor().withOpacity(0.2),
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                  child: Icon(
                    _getTimingIcon(),
                    color: _getTimingColor(),
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMedium),

                // Medicine info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.medicineName,
                        style: AppTheme.headingSmall.copyWith(
                          color: reminder.isActive
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacingXSmall),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppTheme.spacingXSmall),
                          Text(
                            reminder.timing.displayName,
                            style: AppTheme.bodyMedium.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMedium),
                          Icon(
                            reminder.beforeEating
                                ? Icons.restaurant
                                : Icons.no_meals,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppTheme.spacingXSmall),
                          Text(
                            reminder.beforeEating
                                ? 'Before eating'
                                : 'After eating',
                            style: AppTheme.bodyMedium.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Mark as taken button
                if (onMarkTaken != null)
                  GestureDetector(
                    onTap: takenToday ? null : onMarkTaken,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: takenToday
                            ? Colors.green
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: takenToday
                              ? Colors.green
                              : colorScheme.onSurfaceVariant.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: takenToday
                            ? Colors.white
                            : colorScheme.onSurfaceVariant.withOpacity(0.4),
                      ),
                    ),
                  ),
                if (onMarkTaken != null)
                  const SizedBox(width: AppTheme.spacingSmall),

                // Active toggle
                Switch(
                  value: reminder.isActive,
                  onChanged: onToggle,
                  activeColor: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
