import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rounded_button.dart';
import '../../models/medication_reminder.dart';
import '../../services/gemini_service.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';

class PrescriptionResultScreen extends StatefulWidget {
  final List<PrescriptionMedicine> medicines;

  const PrescriptionResultScreen({
    Key? key,
    required this.medicines,
  }) : super(key: key);

  @override
  State<PrescriptionResultScreen> createState() => _PrescriptionResultScreenState();
}

class _PrescriptionResultScreenState extends State<PrescriptionResultScreen> {
  final StorageService _storage = StorageService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  late List<PrescriptionMedicine> _editableMedicines;

  @override
  void initState() {
    super.initState();
    _editableMedicines = List.from(widget.medicines);
  }

  MedicationTiming _stringToTiming(String timing) {
    switch (timing.toLowerCase()) {
      case 'morning':
        return MedicationTiming.morning;
      case 'afternoon':
        return MedicationTiming.afternoon;
      case 'night':
        return MedicationTiming.night;
      default:
        return MedicationTiming.morning;
    }
  }

  Future<void> _saveAllReminders() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _storage.getUserProfile();

      // Save prescription to history
      final scanData = {
        'scanId': DateTime.now().millisecondsSinceEpoch.toString(),
        'scannedAt': DateTime.now().toIso8601String(),
        'medicines': _editableMedicines.map((m) => m.toJson()).toList(),
      };
      await _storage.addPrescriptionScan(scanData);

      for (final medicine in _editableMedicines) {
        final reminder = MedicationReminder(
          id: DateTime.now().millisecondsSinceEpoch.toString() +
              _editableMedicines.indexOf(medicine).toString(),
          medicineName: medicine.medicineName,
          timing: _stringToTiming(medicine.timing),
          beforeEating: medicine.beforeEating,
          isActive: true,
        );

        await _storage.addReminder(reminder);

        // Schedule notification
        if (profile != null) {
          await _notificationService.scheduleReminder(
            reminder: reminder,
            userProfile: profile,
          );
        }
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving reminders: $e'),
          backgroundColor: AppTheme.warningRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Prescription'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              itemCount: _editableMedicines.length,
              itemBuilder: (context, index) {
                final medicine = _editableMedicines[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine.medicineName,
                          style: AppTheme.headingSmall.copyWith(
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMedium),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppTheme.mediumGray,
                            ),
                            const SizedBox(width: AppTheme.spacingXSmall),
                            Text(
                              _stringToTiming(medicine.timing).displayName,
                              style: AppTheme.bodyMedium,
                            ),
                            const SizedBox(width: AppTheme.spacingLarge),
                            Icon(
                              medicine.beforeEating
                                  ? Icons.restaurant
                                  : Icons.no_meals,
                              size: 16,
                              color: AppTheme.mediumGray,
                            ),
                            const SizedBox(width: AppTheme.spacingXSmall),
                            Text(
                              medicine.beforeEating
                                  ? 'Before eating'
                                  : 'After eating',
                              style: AppTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Save button
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: RoundedButton(
                text: 'Save All Reminders (${_editableMedicines.length})',
                onPressed: _saveAllReminders,
                isLoading: _isLoading,
                icon: Icons.check,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
