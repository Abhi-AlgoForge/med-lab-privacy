import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rounded_button.dart';
import '../../models/user_profile.dart' as model;
import '../../services/storage_service.dart';
import '../home/home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storage = StorageService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  model.TimeOfDay _breakfastTime = model.TimeOfDay(hour: 8, minute: 0);
  model.TimeOfDay _lunchTime = model.TimeOfDay(hour: 13, minute: 0);
  model.TimeOfDay _dinnerTime = model.TimeOfDay(hour: 20, minute: 0);

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, String mealType) async {
    model.TimeOfDay currentTime;
    switch (mealType) {
      case 'breakfast':
        currentTime = _breakfastTime;
        break;
      case 'lunch':
        currentTime = _lunchTime;
        break;
      case 'dinner':
        currentTime = _dinnerTime;
        break;
      default:
        return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentTime.hour, minute: currentTime.minute),
    );

    if (picked != null) {
      setState(() {
        final modelTime = model.TimeOfDay(hour: picked.hour, minute: picked.minute);
        switch (mealType) {
          case 'breakfast':
            _breakfastTime = modelTime;
            break;
          case 'lunch':
            _lunchTime = modelTime;
            break;
          case 'dinner':
            _dinnerTime = modelTime;
            break;
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profile = model.UserProfile(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        weight: double.parse(_weightController.text.trim()),
        height: double.parse(_heightController.text.trim()),
        breakfastTime: _breakfastTime,
        lunchTime: _lunchTime,
        dinnerTime: _dinnerTime,
      );

      await _storage.saveUserProfile(profile);
      await _storage.setFirstLaunchComplete();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
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
        title: const Text('Set Up Your Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message
                Text(
                  'Welcome!',
                  style: AppTheme.headingLarge.copyWith(
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Text(
                  'Please provide some basic information to personalize your medication reminders.',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacingXLarge),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingMedium),

                // Age field
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your age';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 1 || age > 150) {
                      return 'Please enter a valid age';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingMedium),

                // Weight and Height in a row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          prefixIcon: Icon(Icons.monitor_weight),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null || weight <= 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMedium),
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                          prefixIcon: Icon(Icons.height),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final height = double.tryParse(value);
                          if (height == null || height <= 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXLarge),

                // Meal timings section
                Text(
                  'Meal Timings',
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: AppTheme.spacingMedium),

                // Breakfast time
                _buildTimeSelector(
                  context,
                  'Breakfast',
                  _breakfastTime,
                  Icons.wb_sunny,
                  () => _selectTime(context, 'breakfast'),
                ),
                const SizedBox(height: AppTheme.spacingMedium),

                // Lunch time
                _buildTimeSelector(
                  context,
                  'Lunch',
                  _lunchTime,
                  Icons.wb_twilight,
                  () => _selectTime(context, 'lunch'),
                ),
                const SizedBox(height: AppTheme.spacingMedium),

                // Dinner time
                _buildTimeSelector(
                  context,
                  'Dinner',
                  _dinnerTime,
                  Icons.nightlight_round,
                  () => _selectTime(context, 'dinner'),
                ),
                const SizedBox(height: AppTheme.spacingXLarge),

                // Save button
                RoundedButton(
                  text: 'Save Profile',
                  onPressed: _saveProfile,
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

  Widget _buildTimeSelector(
    BuildContext context,
    String label,
    model.TimeOfDay time,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(color: AppTheme.lightGray),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryBlue),
            const SizedBox(width: AppTheme.spacingMedium),
            Text(
              label,
              style: AppTheme.bodyLarge,
            ),
            const Spacer(),
            Text(
              time.toString(),
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            const Icon(Icons.chevron_right, color: AppTheme.mediumGray),
          ],
        ),
      ),
    );
  }
}
