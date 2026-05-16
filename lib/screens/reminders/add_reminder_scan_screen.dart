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
  File? _selectedImage;

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required to scan prescription'),
          backgroundColor: AppTheme.warningRed,
        ),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        await _requestCameraPermission();
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
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
    }
  }

  Future<void> _analyzePrescription() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);

    try {
      final medicines = await _geminiService.analyzePrescription(_selectedImage!);

      if (!mounted) return;

      if (medicines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No medicines found in prescription'),
            backgroundColor: AppTheme.cautionOrange,
          ),
        );
        return;
      }

      // Check drug interactions with previously scanned medicines
      final history = await _storage.getMedicineHistory();
      if (history.isNotEmpty && mounted) {
        final priorNames = history.map((m) => m.name).toList();
        final warning = await _geminiService.checkPrescriptionInteractions(
          newPrescription: medicines,
          priorMedicineNames: priorNames,
        );
        if (warning != null && warning.isNotEmpty && mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.medication_rounded,
                  color: Colors.orange, size: 48),
              title: const Text('Drug Interaction Warning'),
              content: SingleChildScrollView(child: Text(warning)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
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
