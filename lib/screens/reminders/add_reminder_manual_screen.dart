import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rounded_button.dart';
import '../../models/medication_reminder.dart';
import '../../services/gemini_service.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';

class AddReminderManualScreen extends StatefulWidget {
  const AddReminderManualScreen({Key? key}) : super(key: key);

  @override
  State<AddReminderManualScreen> createState() => _AddReminderManualScreenState();
}

class _AddReminderManualScreenState extends State<AddReminderManualScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _medicineController = TextEditingController();
  final StorageService _storage = StorageService();
  final NotificationService _notificationService = NotificationService();

  MedicationTiming _selectedTiming = MedicationTiming.morning;
  bool _beforeEating = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _medicineController.dispose();
    super.dispose();
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final reminder = MedicationReminder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        medicineName: _medicineController.text.trim(),
        timing: _selectedTiming,
        beforeEating: _beforeEating,
        isActive: true,
      );

      await _storage.addReminder(reminder);

      // Schedule notification
      final profile = await _storage.getUserProfile();
      if (profile != null) {
        await _notificationService.scheduleReminder(
          reminder: reminder,
          userProfile: profile,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving reminder: $e'),
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
        title: const Text('Add Reminder'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medicine name field
                TextFormField(
                  controller: _medicineController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name',
                    prefixIcon: Icon(Icons.medication),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter medicine name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingXLarge),

                // Timing selection
                Text(
                  'When to take',
                  style: AppTheme.headingSmall,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Wrap(
                  spacing: AppTheme.spacingSmall,
                  children: MedicationTiming.values.map((timing) {
                    final isSelected = _selectedTiming == timing;
                    return ChoiceChip(
                      label: Text(timing.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedTiming = timing);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.spacingXLarge),

                // Before/After eating toggle
                Text(
                  'Eating preference',
                  style: AppTheme.headingSmall,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    border: Border.all(color: AppTheme.lightGray),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      _beforeEating ? 'Before Eating' : 'After Eating',
                      style: AppTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      _beforeEating
                          ? '30 minutes before meal'
                          : '30 minutes after meal',
                      style: AppTheme.bodyMedium,
                    ),
                    value: _beforeEating,
                    onChanged: (value) {
                      setState(() => _beforeEating = value);
                    },
                    activeColor: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXLarge),

                // Save button
                RoundedButton(
                  text: 'Save Reminder',
                  onPressed: _saveReminder,
                  isLoading: _isLoading,
                  icon: Icons.check,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
