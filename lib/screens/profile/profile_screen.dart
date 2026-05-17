import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/storage_service.dart';
import '../../services/subscription_service.dart';
import '../../models/user_profile.dart' as model;
import '../history/history_screen.dart';
import '../paywall/paywall_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storage = StorageService();
  final SubscriptionService _subscription = SubscriptionService();
  model.UserProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isPro = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _heightCtrl;
  model.TimeOfDay? _editBreakfast;
  model.TimeOfDay? _editLunch;
  model.TimeOfDay? _editDinner;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _ageCtrl = TextEditingController();
    _weightCtrl = TextEditingController();
    _heightCtrl = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await _storage.getUserProfile();
    final isPro = await _storage.isProUser();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isPro = isPro;
        _isLoading = false;
      });
    }
  }

  void _startEditing() {
    if (_profile == null) return;
    setState(() {
      _isEditing = true;
      _nameCtrl.text = _profile!.name;
      _ageCtrl.text = _profile!.age.toString();
      _weightCtrl.text = _profile!.weight.toString();
      _heightCtrl.text = _profile!.height.toString();
      _editBreakfast = _profile!.breakfastTime;
      _editLunch = _profile!.lunchTime;
      _editDinner = _profile!.dinnerTime;
    });
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  Future<void> _pickTime(String meal) async {
    final current = meal == 'breakfast'
        ? _editBreakfast!
        : meal == 'lunch'
            ? _editLunch!
            : _editDinner!;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked == null) return;
    setState(() {
      final t = model.TimeOfDay(hour: picked.hour, minute: picked.minute);
      if (meal == 'breakfast') {
        _editBreakfast = t;
      } else if (meal == 'lunch') {
        _editLunch = t;
      } else {
        _editDinner = t;
      }
    });
  }

  Future<void> _saveEdits() async {
    final name = _nameCtrl.text.trim();
    final age = int.tryParse(_ageCtrl.text.trim());
    final weight = double.tryParse(_weightCtrl.text.trim());
    final height = double.tryParse(_heightCtrl.text.trim());

    if (name.isEmpty || age == null || weight == null || height == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
      return;
    }

    final updated = model.UserProfile(
      name: name,
      age: age,
      weight: weight,
      height: height,
      breakfastTime: _editBreakfast!,
      lunchTime: _editLunch!,
      dinnerTime: _editDinner!,
    );

    try {
      await _storage.saveUserProfile(updated);
      setState(() {
        _profile = updated;
        _isEditing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppTheme.successGreen,
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
    }
  }

  void _showAboutDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A73E8), Color(0xFF00ACC1)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_pharmacy_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text('Med Lab',
                style: TextStyle(color: colorScheme.onSurface)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0',
                style: TextStyle(
                    color: colorScheme.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 12),
            Text(
              'Med Lab uses AI to help you identify medicines, analyze medical bills, and manage medication reminders.',
              style: TextStyle(
                  color: colorScheme.onSurface, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Powered by Google Gemini AI',
              style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(color: colorScheme.onSurface)),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: TextStyle(
                color: colorScheme.onSurface, fontSize: 14, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spacingSmall),

            // Pro status / upgrade
            if (!_isPro)
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                  if (result == true) _loadProfile();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7B1FA2).withOpacity(isDark ? 0.2 : 0.1),
                        const Color(0xFFE91E63).withOpacity(isDark ? 0.1 : 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                    border: Border.all(
                      color: const Color(0xFF7B1FA2).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B1FA2), Color(0xFFE91E63)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.workspace_premium_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upgrade to Pro',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Unlimited scans, no ads',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 15, color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppTheme.spacingMedium),

            // Personal Data
            if (_profile != null) ...[
              Row(
                children: [
                  const Expanded(child: _SectionTitle(title: 'Personal Data')),
                  if (!_isEditing)
                    GestureDetector(
                      onTap: _startEditing,
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppTheme.spacingSmall),
                        child: Icon(Icons.edit_rounded,
                            size: 18, color: colorScheme.primary),
                      ),
                    )
                  else ...[
                    GestureDetector(
                      onTap: _cancelEditing,
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppTheme.spacingSmall),
                        child: Icon(Icons.close_rounded,
                            size: 20, color: colorScheme.error),
                      ),
                    ),
                    GestureDetector(
                      onTap: _saveEdits,
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppTheme.spacingSmall),
                        child: Icon(Icons.check_rounded,
                            size: 20, color: AppTheme.successGreen),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              _InfoCard(
                children: _isEditing
                    ? [
                        _EditRow(icon: Icons.person_rounded, label: 'Name', controller: _nameCtrl),
                        _EditRow(icon: Icons.cake_rounded, label: 'Age', controller: _ageCtrl, keyboardType: TextInputType.number),
                        _EditRow(icon: Icons.monitor_weight_rounded, label: 'Weight', controller: _weightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                        _EditRow(icon: Icons.height_rounded, label: 'Height', controller: _heightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      ]
                    : [
                        _InfoRow(icon: Icons.person_rounded, label: 'Name', value: _profile!.name),
                        _InfoRow(icon: Icons.cake_rounded, label: 'Age', value: '${_profile!.age} years'),
                        _InfoRow(icon: Icons.monitor_weight_rounded, label: 'Weight', value: '${_profile!.weight} kg'),
                        _InfoRow(icon: Icons.height_rounded, label: 'Height', value: '${_profile!.height} cm'),
                      ],
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              _InfoCard(
                children: _isEditing
                    ? [
                        _TimeRow(icon: Icons.wb_sunny_rounded, label: 'Breakfast', time: _editBreakfast!, onTap: () => _pickTime('breakfast')),
                        _TimeRow(icon: Icons.wb_twilight_rounded, label: 'Lunch', time: _editLunch!, onTap: () => _pickTime('lunch')),
                        _TimeRow(icon: Icons.nightlight_rounded, label: 'Dinner', time: _editDinner!, onTap: () => _pickTime('dinner')),
                      ]
                    : [
                        _InfoRow(icon: Icons.wb_sunny_rounded, label: 'Breakfast', value: _profile!.breakfastTime.toString()),
                        _InfoRow(icon: Icons.wb_twilight_rounded, label: 'Lunch', value: _profile!.lunchTime.toString()),
                        _InfoRow(icon: Icons.nightlight_rounded, label: 'Dinner', value: _profile!.dinnerTime.toString()),
                      ],
              ),
              const SizedBox(height: AppTheme.spacingLarge),
            ],

            // App Settings
            _SectionTitle(title: 'App'),
            const SizedBox(height: AppTheme.spacingSmall),
            _InfoCard(
              children: [
                _MenuRow(
                  icon: Icons.history_rounded,
                  label: 'Scan History',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
                _MenuRow(
                  icon: Icons.restore_rounded,
                  label: 'Restore Purchases',
                  onTap: () async {
                    final outcome = await _subscription.restorePurchases();
                    if (!mounted) return;
                    await _loadProfile();
                    if (!mounted) return;
                    final granted = outcome == PurchaseOutcome.success ||
                        _subscription.isPro;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(granted
                            ? 'Pro subscription restored!'
                            : 'No active subscription found'),
                        backgroundColor:
                            granted ? AppTheme.successGreen : null,
                      ),
                    );
                  },
                ),
                _MenuRow(
                  icon: Icons.privacy_tip_rounded,
                  label: 'Privacy Policy',
                  onTap: () => _showInfoDialog(
                    'Privacy Policy',
                    'Med Lab respects your privacy.\n\n'
                        '• We collect basic health profile data (name, age, weight, height, meal times) to personalize your medication reminders.\n\n'
                        '• Medicine images are processed via Google Gemini AI for analysis. Images are not stored on our servers.\n\n'
                        '• Your data is stored securely on your device.\n\n'
                        '• We do not sell or share your personal data with third parties.\n\n'
                        '• You can clear your data at any time from the app settings.',
                  ),
                ),
                _MenuRow(
                  icon: Icons.info_rounded,
                  label: 'About',
                  onTap: _showAboutDialog,
                ),
                _MenuRow(
                  icon: Icons.gavel_rounded,
                  label: 'Legal',
                  onTap: () => _showInfoDialog(
                    'Legal',
                    'DISCLAIMER\n\n'
                        'Med Lab is an informational tool and is NOT a substitute for professional medical advice, diagnosis, or treatment.\n\n'
                        '• The AI-based medicine identification is for reference only. Always consult a healthcare professional for medical decisions.\n\n'
                        '• Bill analysis results are estimates based on general pricing and may vary by region and provider.\n\n'
                        '• Medication reminder functionality is provided as-is. Always follow your doctor\'s instructions.\n\n'
                        '© 2025 Med Lab. All rights reserved.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXLarge),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Section Title
// ============================================================
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: AppTheme.spacingSmall),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Info Card (container for rows)
// ============================================================
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                indent: AppTheme.spacingMedium,
                endIndent: AppTheme.spacingMedium,
                color: colorScheme.outline.withOpacity(0.2),
              ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// Info Row (label + value)
// ============================================================
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: 14,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Edit Row (inline text field)
// ============================================================
class _EditRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _EditRow({
    required this.icon,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: 8,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Time Row (tappable time picker)
// ============================================================
class _TimeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final model.TimeOfDay time;
  final VoidCallback onTap;

  const _TimeRow({
    required this.icon,
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.primary.withOpacity(0.4)),
                color: colorScheme.primary.withOpacity(0.06),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.access_time_rounded,
                      size: 14, color: colorScheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Menu Row (tappable, with arrow)
// ============================================================
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuRow(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
