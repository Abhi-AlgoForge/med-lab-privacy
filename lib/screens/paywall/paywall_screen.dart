import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/subscription_service.dart';
import '../../services/storage_service.dart';

// Inline legal copy shown on the paywall. Replace these with hosted-URL
// launches (url_launcher → https://yourdomain/terms etc.) once the
// production policy pages are live; Play and App Store require the
// links to be present and functional on any subscription paywall.
const String _kTermsBody = '''
MedLab Pro Subscription Terms

By subscribing to MedLab Pro you agree to the following:

• Billing — Your subscription is billed monthly through Google Play (or the App Store on iOS) at the price shown on this screen. Prices may vary by region.

• Auto-renewal — Your subscription renews automatically at the end of each billing period unless cancelled at least 24 hours before the renewal date.

• Cancellation — You can cancel any time from your Google Play (or App Store) account settings. Cancellation takes effect at the end of the current billing period; partial-period refunds are not provided.

• Refunds — Refund requests are handled by Google Play / App Store per their respective policies.

• Service — MedLab Pro unlocks unlimited scans and removes ads. Features may evolve over time. We may modify or discontinue Pro features with reasonable notice.

• Medical disclaimer — MedLab is an informational tool. It does not provide medical advice, diagnosis, or treatment. Always consult a licensed healthcare professional before making medical decisions.

These terms are governed by the laws of your country of residence to the extent required by local consumer-protection law. For questions, contact us via the email listed in the Play Store / App Store listing.
''';

const String _kPrivacyBody = '''
MedLab Privacy Summary

Data collected on-device only (never leaves your phone):
• Your profile — name, age, weight, height, meal times.
• Medication reminders and dose history.
• Scan history (medicines, prescriptions, bills) and previews.

Data sent to third parties:
• Photos you scan are sent to Google Gemini for AI analysis. Google's terms apply to that processing. We do not store these images on our own servers.
• Google AdMob may collect your advertising ID to show ads (Pro users see no ads).
• Google Play Billing handles your purchase securely; we receive only the subscription status.
• Firebase Remote Config fetches configuration values from Google.

What we don't do:
• We do not require an account or collect your email.
• We do not sell your data to third parties.

You can clear all locally stored data from your device's Settings → Apps → MedLab → Storage.

For the full policy, see the link in our Play Store / App Store listing.
''';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({Key? key}) : super(key: key);

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final SubscriptionService _subscription = SubscriptionService();
  bool _isLoading = false;
  bool _isRestoring = false;

  Future<void> _purchase() async {
    setState(() => _isLoading = true);
    final outcome = await _subscription.buyMonthly();
    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (outcome) {
      case PurchaseOutcome.success:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Pro!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.of(context).pop(true);
        break;
      case PurchaseOutcome.alreadyOwned:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You already own Pro — tap "Restore Purchases" to activate.'),
          ),
        );
        break;
      case PurchaseOutcome.cancelled:
        // User backed out of the Play sheet — no feedback needed.
        break;
      case PurchaseOutcome.unavailable:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Subscription is unavailable right now. Please try again later.'),
          ),
        );
        break;
      case PurchaseOutcome.timeout:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "The store didn't respond. If you were charged, tap Restore Purchases."),
            duration: Duration(seconds: 5),
          ),
        );
        break;
      case PurchaseOutcome.error:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase failed. Please try again.')),
        );
        break;
    }
  }

  void _showLegalDoc(BuildContext context,
      {required String title, required String body}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: Text(body)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _restore() async {
    setState(() => _isRestoring = true);
    final outcome = await _subscription.restorePurchases();
    if (!mounted) return;
    setState(() => _isRestoring = false);

    if (outcome == PurchaseOutcome.success || _subscription.isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pro subscription restored!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      Navigator.of(context).pop(true);
    } else if (outcome == PurchaseOutcome.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore failed. Please try again.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active subscription found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = StorageService.freeDailyLimit;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1A1A2E),
                    colorScheme.surface,
                  ]
                : [
                    const Color(0xFFF8F0FF),
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: Icon(Icons.close_rounded,
                        color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // Pro badge
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B1FA2), Color(0xFFE91E63)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7B1FA2).withOpacity(0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Upgrade to Pro',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unlock unlimited scans & remove ads',
                        style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Feature list
                      _ProFeature(
                        icon: Icons.all_inclusive_rounded,
                        title: 'Unlimited Scans',
                        subtitle: 'Free tier: $remaining scans/day',
                        color: const Color(0xFF1A73E8),
                      ),
                      const SizedBox(height: 14),
                      _ProFeature(
                        icon: Icons.block_rounded,
                        title: 'No Ads',
                        subtitle: 'Clean, uninterrupted experience',
                        color: const Color(0xFFE91E63),
                      ),
                      const SizedBox(height: 14),
                      _ProFeature(
                        icon: Icons.bolt_rounded,
                        title: 'Priority AI',
                        subtitle: 'Faster analysis & responses',
                        color: const Color(0xFFFF9800),
                      ),
                      const SizedBox(height: 14),
                      _ProFeature(
                        icon: Icons.favorite_rounded,
                        title: 'Support Development',
                        subtitle: 'Help us keep improving Med Lab',
                        color: const Color(0xFF4CAF50),
                      ),

                      const Spacer(flex: 2),

                      // Price + subscribe button
                      Text(
                        _subscription.priceString,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'per month',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Subscribe button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7B1FA2), Color(0xFFE91E63)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7B1FA2).withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _isLoading ? null : _purchase,
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Subscribe Now',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Restore purchases
                      TextButton(
                        onPressed: _isRestoring ? null : _restore,
                        child: _isRestoring
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: colorScheme.onSurfaceVariant,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Restore Purchases',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Cancel anytime. Subscription auto-renews monthly.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),

                      // Required by Play / App Store on any subscription
                      // paywall. Tappable links to the legal policies.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => _showLegalDoc(
                              context,
                              title: 'Terms of Service',
                              body: _kTermsBody,
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.onSurfaceVariant,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Terms of Service',
                              style: TextStyle(
                                  fontSize: 11,
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                          Text(
                            ' · ',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  colorScheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showLegalDoc(
                              context,
                              title: 'Privacy Policy',
                              body: _kPrivacyBody,
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.onSurfaceVariant,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Privacy Policy',
                              style: TextStyle(
                                  fontSize: 11,
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ProFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.check_circle_rounded, color: color, size: 22),
      ],
    );
  }
}
