import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/reminder_card.dart';
import '../../widgets/streak_banner.dart';
import '../../models/medication_reminder.dart';
import '../../models/dose_record.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import 'add_reminder_manual_screen.dart';
import 'add_reminder_scan_screen.dart';
import 'streak_calendar_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final StorageService _storage = StorageService();
  final NotificationService _notificationService = NotificationService();
  List<MedicationReminder> _reminders = [];
  Map<String, bool> _takenToday = {};
  int _streakDays = 0;
  int _totalDoses = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    try {
      final reminders = await _storage.getReminders();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayRecords = await _storage.getDoseRecordsForDate(todayStr);

      // Build taken-today map
      final takenMap = <String, bool>{};
      for (final r in reminders) {
        final taken =
            todayRecords.any((d) => d.reminderId == r.id && d.taken);
        takenMap[r.id] = taken;
      }

      // Calculate streak
      final allRecords = await _storage.getDoseRecords();
      final activeReminders = reminders.where((r) => r.isActive).toList();
      int streak = 0;
      final totalDoses = allRecords.where((r) => r.taken).length;

      if (activeReminders.isNotEmpty) {
        for (int i = 1; i <= 365; i++) {
          final date = DateTime.now().subtract(Duration(days: i));
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          final dayRecords = allRecords
              .where((r) => r.scheduledDate == dateStr && r.taken)
              .toList();
          if (dayRecords.length >= activeReminders.length) {
            streak++;
          } else {
            break;
          }
        }
      }

      setState(() {
        _reminders = reminders;
        _takenToday = takenMap;
        _streakDays = streak;
        _totalDoses = totalDoses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading reminders: $e'),
          backgroundColor: AppTheme.warningRed,
        ),
      );
    }
  }

  Future<void> _markAsTaken(MedicationReminder reminder) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final record = DoseRecord(
      reminderId: reminder.id,
      medicineName: reminder.medicineName,
      scheduledDate: todayStr,
      takenAt: DateTime.now(),
      taken: true,
    );

    await _storage.recordDose(record);

    await _loadReminders();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${reminder.medicineName} marked as taken'),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _deleteReminder(MedicationReminder reminder) async {
    try {
      await _storage.deleteReminder(reminder.id);
      await _notificationService.cancelReminder(reminder);
      await _loadReminders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder deleted'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting reminder: $e'),
          backgroundColor: AppTheme.warningRed,
        ),
      );
    }
  }

  Future<void> _deleteAllReminders() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Reminders'),
        content: const Text(
          'Are you sure you want to delete all reminders? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    for (final reminder in _reminders) {
      await _storage.deleteReminder(reminder.id);
      await _notificationService.cancelReminder(reminder);
    }
    await _loadReminders();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All reminders deleted'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  Future<void> _toggleReminder(
      MedicationReminder reminder, bool isActive) async {
    try {
      final updatedReminder = reminder.copyWith(isActive: isActive);
      await _storage.updateReminder(updatedReminder);

      if (isActive) {
        final profile = await _storage.getUserProfile();
        if (profile != null) {
          await _notificationService.scheduleReminder(
            reminder: updatedReminder,
            userProfile: profile,
          );
        }
      } else {
        await _notificationService.cancelReminder(updatedReminder);
      }

      await _loadReminders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error toggling reminder: $e'),
          backgroundColor: AppTheme.warningRed,
        ),
      );
    }
  }

  void _showAddReminderOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.borderRadiusXLarge),
            ),
            border: Border.all(color: cs.outline.withOpacity(0.3)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outline.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  Text(
                    'Add New Reminder',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.paleBlue,
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusMedium),
                      ),
                      child:
                          const Icon(Icons.edit, color: AppTheme.primaryBlue),
                    ),
                    title: const Text('Manual Entry'),
                    subtitle: const Text('Add medicine details manually'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AddReminderManualScreen(),
                        ),
                      );
                      if (result == true) await _loadReminders();
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.paleBlue,
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusMedium),
                      ),
                      child: const Icon(Icons.document_scanner,
                          color: AppTheme.primaryBlue),
                    ),
                    title: const Text('Scan Prescription'),
                    subtitle:
                        const Text('Take a photo of your prescription'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AddReminderScanScreen(),
                        ),
                      );
                      if (result == true) await _loadReminders();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _reminders.isNotEmpty
          ? AppBar(
              title: const Text('Reminders'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.calendar_month_rounded),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StreakCalendarScreen(),
                      ),
                    );
                  },
                  tooltip: 'Streak Calendar',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete_all') _deleteAllReminders();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_rounded,
                              color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete All Reminders'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? _buildEmptyState()
              : _buildRemindersList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderOptions,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.paleBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 60,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXLarge),
            Text(
              'No Reminders Yet',
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              'Add your first medication reminder by tapping the + button below',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
      itemCount: _reminders.length + (_streakDays > 0 ? 1 : 0),
      itemBuilder: (context, index) {
        if (_streakDays > 0 && index == 0) {
          return StreakBanner(
            streakDays: _streakDays,
            totalDoses: _totalDoses,
          );
        }

        final reminderIndex = _streakDays > 0 ? index - 1 : index;
        final reminder = _reminders[reminderIndex];
        return ReminderCard(
          reminder: reminder,
          onDelete: () => _deleteReminder(reminder),
          onToggle: (isActive) => _toggleReminder(reminder, isActive),
          takenToday: _takenToday[reminder.id] ?? false,
          onMarkTaken: () => _markAsTaken(reminder),
        );
      },
    );
  }
}
