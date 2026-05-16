import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/dose_record.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class StreakCalendarScreen extends StatefulWidget {
  const StreakCalendarScreen({Key? key}) : super(key: key);

  @override
  State<StreakCalendarScreen> createState() => _StreakCalendarScreenState();
}

class _StreakCalendarScreenState extends State<StreakCalendarScreen> {
  final StorageService _storage = StorageService();
  List<DoseRecord> _allRecords = [];
  int _totalReminders = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final records = await _storage.getDoseRecords();
    final reminders = await _storage.getReminders();
    if (mounted) {
      setState(() {
        _allRecords = records;
        _totalReminders = reminders.where((r) => r.isActive).length;
        _isLoading = false;
      });
    }
  }

  /// Returns status for a given date: 'all' | 'partial' | 'missed' | 'none'
  String _statusForDate(String dateStr) {
    final dayRecords =
        _allRecords.where((r) => r.scheduledDate == dateStr).toList();
    if (dayRecords.isEmpty) return 'none';
    final takenCount = dayRecords.where((r) => r.taken).length;
    if (takenCount >= _totalReminders && _totalReminders > 0) return 'all';
    if (takenCount > 0) return 'partial';
    return 'missed';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Streak Calendar')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Build last 30 days grid
    final today = DateTime.now();
    final days = List.generate(
      30,
      (i) => today.subtract(Duration(days: 29 - i)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Streak Calendar')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          children: [
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: Colors.green, label: 'All taken'),
                const SizedBox(width: AppTheme.spacingMedium),
                _LegendItem(
                    color: colorScheme.primary, label: 'Partial'),
                const SizedBox(width: AppTheme.spacingMedium),
                _LegendItem(color: Colors.red, label: 'Missed'),
                const SizedBox(width: AppTheme.spacingMedium),
                _LegendItem(
                    color: colorScheme.surfaceContainerHighest,
                    label: 'No data'),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLarge),

            // Calendar grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final dateStr = DateFormat('yyyy-MM-dd').format(day);
                  final isToday = dateStr ==
                      DateFormat('yyyy-MM-dd').format(today);
                  final status = _statusForDate(dateStr);

                  Color bgColor;
                  switch (status) {
                    case 'all':
                      bgColor = Colors.green;
                      break;
                    case 'partial':
                      bgColor = colorScheme.primary;
                      break;
                    case 'missed':
                      bgColor = Colors.red;
                      break;
                    default:
                      bgColor = isDark
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.surfaceContainerHighest;
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: bgColor.withOpacity(
                          status == 'none' ? 0.5 : 0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(
                              color: colorScheme.onSurface, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isToday
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: status == 'none'
                                  ? colorScheme.onSurfaceVariant
                                  : Colors.white,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(day),
                            style: TextStyle(
                              fontSize: 9,
                              color: status == 'none'
                                  ? colorScheme.onSurfaceVariant
                                      .withOpacity(0.7)
                                  : Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'Last 30 days',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
