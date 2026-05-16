import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_theme.dart';
import '../../services/gemini_service.dart';
import '../../services/storage_service.dart';
import '../../services/ad_service.dart';
import '../bill_scanner/bill_result_screen.dart';
import '../paywall/paywall_screen.dart';
import 'medicine_result_screen.dart';

class MedicineScannerScreen extends StatefulWidget {
  const MedicineScannerScreen({Key? key}) : super(key: key);

  @override
  State<MedicineScannerScreen> createState() => _MedicineScannerScreenState();
}

class _MedicineScannerScreenState extends State<MedicineScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();
  final StorageService _storage = StorageService();
  final AdService _adService = AdService();
  bool _isLoading = false;
  bool _isCancelled = false;
  File? _selectedImage;
  String _loadingTitle = 'Analyzing...';
  String _loadingSubtitle = 'This may take a few moments';

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required to scan'),
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
        // Check scan limit before proceeding
        final canScan = await _storage.canScan();
        if (!canScan && mounted) {
          final upgraded = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          );
          if (upgraded != true) return;
        }

        setState(() {
          _selectedImage = File(image.path);
        });
        // Show scan type selection after image is picked
        if (mounted) {
          _showScanTypeSheet();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showScanTypeSheet() {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.borderRadiusXLarge),
          ),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.4),
            width: 1,
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppTheme.spacingLarge,
          AppTheme.spacingMedium,
          AppTheme.spacingLarge,
          AppTheme.spacingLarge +
              MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),

            Text(
              'What would you like to scan?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose the type of analysis for your image',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),

            // Medicine option
            _ScanTypeOption(
              icon: Icons.medication_rounded,
              title: 'Scan Medicine',
              description:
                  'Identify medicine, active ingredients, uses & safety warnings',
              color: colorScheme.primary,
              onTap: () {
                Navigator.pop(sheetContext);
                _analyzeMedicine();
              },
            ),
            const SizedBox(height: AppTheme.spacingSmall),

            // Bill option
            _ScanTypeOption(
              icon: Icons.receipt_long_rounded,
              title: 'Analyze Medical Bill',
              description:
                  'Detect overcharging, double billing & unusual charges',
              color: colorScheme.tertiary,
              onTap: () {
                Navigator.pop(sheetContext);
                _analyzeBill();
              },
            ),
            const SizedBox(height: AppTheme.spacingMedium),

            // Cancel
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  setState(() => _selectedImage = null);
                },
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingSmall),
                ),
                child: const Text('Cancel',
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _stopAnalysis() {
    setState(() {
      _isCancelled = true;
      _isLoading = false;
      _selectedImage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analysis stopped')),
    );
  }

  Future<void> _analyzeMedicine() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _isCancelled = false;
      _loadingTitle = 'Analyzing medicine...';
      _loadingSubtitle = 'Identifying ingredients & safety info';
    });

    try {
      var medicine =
          await _geminiService.analyzeMedicineImage(_selectedImage!);

      if (!mounted || _isCancelled) return;

      // Skip saving if it's a "Not a Medicine" result
      if (medicine.name != 'Not a Medicine') {
        // Save to history
        await _storage.addMedicineToHistory(medicine);

        // Check drug interactions
        if (!mounted || _isCancelled) return;
        setState(() {
          _loadingSubtitle = 'Checking drug interactions...';
        });
        final history = await _storage.getMedicineHistory();
        // Exclude the just-scanned medicine from history for comparison
        final priorMedicines = history.where((m) => m.id != medicine.id).toList();
        if (priorMedicines.isNotEmpty) {
          final warning = await _geminiService.checkDrugInteractions(
            newMedicine: medicine,
            history: priorMedicines,
          );
          if (warning != null && warning.isNotEmpty) {
            medicine = medicine.copyWith(interactionWarning: warning);
          }
        }
      }

      if (!mounted || _isCancelled) return;

      // Increment scan count & show ad for free users
      await _storage.incrementScanCount();
      await _adService.showInterstitialIfFree();

      if (!mounted || _isCancelled) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MedicineResultScreen(medicine: medicine),
        ),
      );
    } catch (e) {
      if (!mounted || _isCancelled) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing medicine: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted && !_isCancelled) {
        setState(() {
          _isLoading = false;
          _selectedImage = null;
        });
      }
    }
  }

  Future<void> _analyzeBill() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _isCancelled = false;
      _loadingTitle = 'Analyzing bill...';
      _loadingSubtitle = 'Checking for irregularities & overcharges';
    });

    try {
      final billAnalysis = await _geminiService.analyzeBill(_selectedImage!);

      if (!mounted || _isCancelled) return;

      // Increment scan count & show ad for free users
      await _storage.incrementScanCount();
      await _adService.showInterstitialIfFree();

      if (!mounted || _isCancelled) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BillResultScreen(billAnalysis: billAnalysis),
        ),
      );
    } catch (e) {
      if (!mounted || _isCancelled) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing bill: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted && !_isCancelled) {
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
      body: SafeArea(
        child: _isLoading ? _buildLoadingState() : _buildInitialState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie animation
            Lottie.asset(
              'assets/animations/scanning.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            Text(
              _loadingTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              _loadingSubtitle,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXLarge),

            // Stop button
            OutlinedButton.icon(
              onPressed: _stopAnalysis,
              icon: const Icon(Icons.stop_rounded, size: 20),
              label: const Text('Stop'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLarge,
                  vertical: AppTheme.spacingSmall,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Background decorative circles
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withOpacity(isDark ? 0.06 : 0.07),
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          left: -60,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.secondary.withOpacity(isDark ? 0.06 : 0.07),
            ),
          ),
        ),

        // Main content
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLarge,
            vertical: AppTheme.spacingMedium,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Hero icon with gradient
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusXLarge + 8),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  size: 72,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXLarge),

              // Title
              Text(
                'Smart Scanner',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),

              // Subtitle
              Text(
                'Scan medicines for ingredients & warnings,\nor analyze medical bills for irregularities',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // Feature pills
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FeaturePill(
                    icon: Icons.medication_rounded,
                    label: 'Medicine',
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  _FeaturePill(
                    icon: Icons.receipt_long_rounded,
                    label: 'Bill Check',
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  _FeaturePill(
                    icon: Icons.security_rounded,
                    label: 'AI Powered',
                    color: colorScheme.secondary,
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingXLarge),

              // Camera button
              _ScanButton(
                icon: Icons.camera_alt_rounded,
                title: 'Take Photo',
                subtitle: 'Use camera to capture',
                primaryColor: colorScheme.primary,
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: AppTheme.spacingSmall),

              // Gallery button
              _ScanButton(
                icon: Icons.photo_library_rounded,
                title: 'Choose from Gallery',
                subtitle: 'Pick an existing image',
                primaryColor: colorScheme.secondary,
                onTap: () => _pickImage(ImageSource.gallery),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Reusable widgets
// ============================================================

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeaturePill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color primaryColor;
  final VoidCallback onTap;

  const _ScanButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  State<_ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<_ScanButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 120), vsync: this);
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingMedium,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(isDark ? 0.4 : 0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.primaryColor.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Icon(widget.icon, color: widget.primaryColor, size: 24),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Scan type option in bottom sheet
// ============================================================
class _ScanTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ScanTypeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius:
                    BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_rounded, color: color, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
