import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rounded_button.dart';
import '../../services/gemini_service.dart';
import '../../services/storage_service.dart';
import 'prescription_result_screen.dart';

class AddReminderScanScreen extends StatefulWidget {
  const AddReminderScanScreen({Key? key}) : super(key: key);

  @override
  State<AddReminderScanScreen> createState() => _AddReminderScanScreenState();
}

class _AddReminderScanScreenState extends State<AddReminderScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();
  final StorageService _storage = StorageService();
  bool _isLoading = false;
  bool _isPicking = false;
  File? _selectedImage;

  /// Returns true when the user grants (or has already granted) camera
  /// permission. Shows a friendly rationale before the system prompt.
  Future<bool> _requestCameraPermission() async {
    final current = await Permission.camera.status;
    if (current.isGranted || current.isLimited) return true;

    if (current.isPermanentlyDenied) {
      return _showOpenSettingsDialog(
        title: 'Camera access is off',
        message:
            'MedLab needs your camera to scan prescriptions. '
            'You can enable it in Settings.',
      );
    }

    final consented = await _showRationaleDialog(
      title: 'Use your camera?',
      message:
          'We use your camera only to scan your prescription. '
          'The photo is sent to Google Gemini for analysis and is not '
          'stored on our servers.',
    );
    if (!consented) return false;

    final status = await Permission.camera.request();
    if (!status.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required to scan prescription'),
          backgroundColor: AppTheme.warningRed,
        ),
      );
    }
    return status.isGranted;
  }

  Future<bool> _showRationaleDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<bool> _showOpenSettingsDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return false;
    final opened = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    if (opened == true) {
      await openAppSettings();
    }
    return false;
  }

  Future<void> _pickImage(ImageSource source) async {
    // Prevent double-tap from launching two pickers / two Gemini calls.
    if (_isPicking || _isLoading) return;
    _isPicking = true;
    try {
      if (source == ImageSource.camera) {
        final granted = await _requestCameraPermission();
        if (!granted) return;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        // Cap dimensions so a 50MP camera shot doesn't OOM low-end
        // devices and doesn't balloon the Gemini token bill.
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _analyzePrescription();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppTheme.warningRed,
        ),
      );
    } finally {
      _isPicking = false;
    }
  }

  Future<void> _showCouldNotRecognizeDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.image_search_rounded,
            color: colorScheme.primary, size: 48),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzePrescription() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);

    try {
      final medicines = await _geminiService.analyzePrescription(_selectedImage!);

      if (!mounted) return;

      // Gemini's "Not a Prescription" sentinel arrives as a single
      // medicine with that literal name — don't push it into the
      // result screen where it would render as a real reminder.
      final isNotPrescriptionSentinel = medicines.length == 1 &&
          medicines.first.medicineName == 'Not a Prescription';
      if (medicines.isEmpty || isNotPrescriptionSentinel) {
        await _showCouldNotRecognizeDialog(
          title: "Couldn't read this prescription",
          message:
              "We couldn't find any medications in that image. Try a clearer photo of the prescription — make sure the medicine names and timing are readable.",
        );
        return;
      }

      // Check drug interactions with previously scanned medicines
      final history = await _storage.getMedicineHistory();
      if (history.isNotEmpty && mounted) {
        final priorNames = history.map((m) => m.name).toList();
        final result = await _geminiService.checkPrescriptionInteractions(
          newPrescription: medicines,
          priorMedicineNames: priorNames,
        );
        if (result.hasWarning && mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.medication_rounded,
                  color: Colors.orange, size: 48),
              title: const Text('Drug Interaction Warning'),
              content: SingleChildScrollView(child: Text(result.warning!)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else if (!result.checked && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "Couldn't check drug interactions — review manually."),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PrescriptionResultScreen(medicines: medicines),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing prescription: $e'),
          backgroundColor: AppTheme.warningRed,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedImage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Prescription'),
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _buildInitialState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          Text(
            'Analyzing prescription...',
            style: AppTheme.headingSmall.copyWith(
              color: AppTheme.mediumGray,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            'This may take a few moments',
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: AppTheme.paleBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.document_scanner,
              size: 80,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXLarge),

          // Title
          Text(
            'Scan Prescription',
            style: AppTheme.headingLarge.copyWith(
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),

          // Description
          Text(
            'Take a photo of your prescription to automatically create medication reminders',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXLarge),

          // Camera button
          RoundedButton(
            text: 'Take Photo',
            onPressed: () => _pickImage(ImageSource.camera),
            icon: Icons.camera_alt,
          ),
          const SizedBox(height: AppTheme.spacingMedium),

          // Gallery button
          RoundedButton(
            text: 'Choose from Gallery',
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: Icons.photo_library,
            backgroundColor: AppTheme.darkBlue,
          ),
        ],
      ),
    );
  }
}
