import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class FeatureTourOverlay {
  static Future<void> showIfNeeded(BuildContext context) async {
    final storage = StorageService();
    final isComplete = await storage.isFeatureTourComplete();
    if (isComplete) return;

    if (!context.mounted) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => _FeatureTourScreen(
          onComplete: () async {
            await storage.setFeatureTourComplete();
          },
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

class _FeatureTourScreen extends StatefulWidget {
  final Future<void> Function() onComplete;

  const _FeatureTourScreen({required this.onComplete});

  @override
  State<_FeatureTourScreen> createState() => _FeatureTourScreenState();
}

class _FeatureTourScreenState extends State<_FeatureTourScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _illustrationController;
  late Animation<double> _illustrationScale;
  late Animation<double> _illustrationOpacity;

  final List<_TourPageData> _pages = const [
    _TourPageData(
      title: 'Scan & Identify',
      subtitle: 'Your AI-powered medicine companion',
      description:
          'Point your camera at any medicine to instantly identify it, check expiry dates, and get warnings about harmful ingredients.',
      gradient: [Color(0xFF1A73E8), Color(0xFF00ACC1)],
      illustrationType: _IllustrationType.scanner,
      features: ['Medicine identification', 'Expiry date check', 'Drug interaction alerts'],
    ),
    _TourPageData(
      title: 'Smart Reminders',
      subtitle: 'Never miss a dose again',
      description:
          'Set up medication schedules, get timely notifications, and track your medication streaks to build healthy habits.',
      gradient: [Color(0xFFE65100), Color(0xFFBF360C)],
      illustrationType: _IllustrationType.reminders,
      features: ['Daily notifications', 'Streak tracking', 'Dose logging'],
    ),
    _TourPageData(
      title: 'History & Reports',
      subtitle: 'Everything in one place',
      description:
          'View your complete scan history, analyze medical bills for overcharges, and share detailed reports with your doctor.',
      gradient: [Color(0xFF7B1FA2), Color(0xFFE91E63)],
      illustrationType: _IllustrationType.history,
      features: ['Scan history', 'Bill analysis', 'Share reports'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _illustrationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _illustrationScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _illustrationController, curve: Curves.elasticOut),
    );
    _illustrationOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _illustrationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _illustrationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _illustrationController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _illustrationController.reset();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    _illustrationController.forward();
  }

  Future<void> _complete() async {
    await widget.onComplete();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = _currentPage == _pages.length - 1;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient that shifts with page
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        _pages[_currentPage].gradient[0].withOpacity(0.15),
                        colorScheme.surface,
                        colorScheme.surface,
                      ]
                    : [
                        _pages[_currentPage].gradient[0].withOpacity(0.08),
                        Colors.white,
                        _pages[_currentPage].gradient[1].withOpacity(0.04),
                      ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    child: TextButton(
                      onPressed: _complete,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                      _illustrationController.reset();
                      _illustrationController.forward();
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingLarge,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: screenHeight * 0.02),

                            // Illustration
                            AnimatedBuilder(
                              animation: _illustrationController,
                              builder: (_, child) => Opacity(
                                opacity: _illustrationOpacity.value,
                                child: Transform.scale(
                                  scale: _illustrationScale.value,
                                  child: child,
                                ),
                              ),
                              child: SizedBox(
                                height: screenHeight * 0.35,
                                child: _TourIllustration(
                                  type: page.illustrationType,
                                  gradient: page.gradient,
                                  isDark: isDark,
                                ),
                              ),
                            ),

                            const Spacer(),

                            // Title
                            Text(
                              page.title,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),

                            // Subtitle
                            Text(
                              page.subtitle,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: page.gradient[0],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppTheme.spacingMedium),

                            // Description
                            Text(
                              page.description,
                              style: TextStyle(
                                fontSize: 15,
                                color: colorScheme.onSurfaceVariant,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppTheme.spacingLarge),

                            // Feature chips
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: page.features.map((f) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: page.gradient[0].withOpacity(isDark ? 0.15 : 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: page.gradient[0].withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 16,
                                        color: page.gradient[0],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        f,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: page.gradient[0],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                            const Spacer(),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom section: indicators + button
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLarge,
                    0,
                    AppTheme.spacingLarge,
                    AppTheme.spacingLarge,
                  ),
                  child: Column(
                    children: [
                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == i ? 32 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? _pages[_currentPage].gradient[0]
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),

                      // Action button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _pages[_currentPage].gradient,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _pages[_currentPage].gradient[0]
                                    .withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: isLast
                                  ? _complete
                                  : () => _goToPage(_currentPage + 1),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isLast ? 'Get Started' : 'Continue',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isLast
                                          ? Icons.check_rounded
                                          : Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingSmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Tour page data
// ============================================================
class _TourPageData {
  final String title;
  final String subtitle;
  final String description;
  final List<Color> gradient;
  final _IllustrationType illustrationType;
  final List<String> features;

  const _TourPageData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradient,
    required this.illustrationType,
    required this.features,
  });
}

enum _IllustrationType { scanner, reminders, history }

// ============================================================
// Custom illustrations using Flutter widgets
// ============================================================
class _TourIllustration extends StatefulWidget {
  final _IllustrationType type;
  final List<Color> gradient;
  final bool isDark;

  const _TourIllustration({
    required this.type,
    required this.gradient,
    required this.isDark,
  });

  @override
  State<_TourIllustration> createState() => _TourIllustrationState();
}

class _TourIllustrationState extends State<_TourIllustration>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case _IllustrationType.scanner:
        return _buildScannerIllustration();
      case _IllustrationType.reminders:
        return _buildRemindersIllustration();
      case _IllustrationType.history:
        return _buildHistoryIllustration();
    }
  }

  Widget _buildScannerIllustration() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (_, __) {
        final float = Tween<double>(begin: -8, end: 8)
            .animate(CurvedAnimation(
                parent: _floatController, curve: Curves.easeInOut))
            .value;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            _buildPulsingRing(140, 0.06),
            _buildPulsingRing(110, 0.1),

            // Phone frame
            Transform.translate(
              offset: Offset(0, float),
              child: Container(
                width: 160,
                height: 220,
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: widget.gradient[0].withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient[0].withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Scan viewfinder
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.gradient[0],
                          width: 2.5,
                        ),
                      ),
                      child: Icon(
                        Icons.medication_rounded,
                        size: 40,
                        color: widget.gradient[0],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Scan line animation
                    Container(
                      width: 100,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.gradient[0].withOpacity(0),
                            widget.gradient[0],
                            widget.gradient[1],
                            widget.gradient[1].withOpacity(0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Result preview lines
                    for (int i = 0; i < 3; i++) ...[
                      Container(
                        width: 60.0 + (i * 15),
                        height: 6,
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: widget.gradient[0]
                              .withOpacity(0.12 + (i * 0.04)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Floating badge - checkmark
            Positioned(
              right: 40,
              top: 30,
              child: Transform.translate(
                offset: Offset(0, -float * 0.5),
                child: _buildFloatingBadge(
                  Icons.verified_rounded,
                  const Color(0xFF4CAF50),
                ),
              ),
            ),

            // Floating badge - warning
            Positioned(
              left: 40,
              bottom: 50,
              child: Transform.translate(
                offset: Offset(0, float * 0.7),
                child: _buildFloatingBadge(
                  Icons.shield_rounded,
                  widget.gradient[1],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRemindersIllustration() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (_, __) {
        final float = Tween<double>(begin: -6, end: 6)
            .animate(CurvedAnimation(
                parent: _floatController, curve: Curves.easeInOut))
            .value;

        return Stack(
          alignment: Alignment.center,
          children: [
            _buildPulsingRing(130, 0.06),

            // Notification cards stack
            Transform.translate(
              offset: Offset(0, float),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bell icon with glow
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradient[0].withOpacity(0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mini notification cards
                  for (int i = 0; i < 3; i++) ...[
                    Transform.translate(
                      offset: Offset(
                        (i == 1 ? 20 : i == 2 ? -15 : 0).toDouble(),
                        float * (0.3 + i * 0.15),
                      ),
                      child: Container(
                        width: 200,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: widget.gradient[0]
                                .withOpacity(0.15 + (i * 0.05)),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.gradient[0]
                                  .withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: widget.gradient[0].withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                i == 0
                                    ? Icons.wb_sunny_rounded
                                    : i == 1
                                        ? Icons.restaurant_rounded
                                        : Icons.nightlight_rounded,
                                size: 18,
                                color: widget.gradient[0],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: widget.gradient[0]
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 50,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: widget.gradient[0]
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: const Color(0xFF4CAF50)
                                  .withOpacity(i == 0 ? 1.0 : 0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i < 2) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),

            // Streak badge
            Positioned(
              right: 30,
              top: 20,
              child: Transform.translate(
                offset: Offset(0, -float * 0.6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE65100), Color(0xFFBF360C)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE65100).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🔥', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 4),
                      Text(
                        '7 days',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryIllustration() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (_, __) {
        final float = Tween<double>(begin: -8, end: 8)
            .animate(CurvedAnimation(
                parent: _floatController, curve: Curves.easeInOut))
            .value;

        return Stack(
          alignment: Alignment.center,
          children: [
            _buildPulsingRing(130, 0.06),

            Transform.translate(
              offset: Offset(0, float),
              child: Container(
                width: 200,
                height: 240,
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.gradient[0].withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient[0].withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(Icons.history_rounded,
                              size: 20, color: widget.gradient[0]),
                          const SizedBox(width: 8),
                          Container(
                            width: 80,
                            height: 8,
                            decoration: BoxDecoration(
                              color: widget.gradient[0].withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // History items
                      for (int i = 0; i < 3; i++) ...[
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.gradient[0].withOpacity(0.15),
                                    widget.gradient[1].withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                i % 2 == 0
                                    ? Icons.medication_rounded
                                    : Icons.receipt_long_rounded,
                                size: 18,
                                color: widget.gradient[i % 2 == 0 ? 0 : 1],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 70.0 + (i * 10),
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: widget.gradient[0]
                                          .withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 45,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: widget.gradient[0]
                                          .withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: widget.gradient[0].withOpacity(0.3),
                            ),
                          ],
                        ),
                        if (i < 2) ...[
                          const SizedBox(height: 4),
                          Divider(
                            color: widget.gradient[0].withOpacity(0.08),
                            height: 12,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Share badge
            Positioned(
              right: 25,
              bottom: 40,
              child: Transform.translate(
                offset: Offset(0, float * 0.6),
                child: _buildFloatingBadge(
                  Icons.share_rounded,
                  widget.gradient[1],
                ),
              ),
            ),

            // Chart badge
            Positioned(
              left: 30,
              top: 30,
              child: Transform.translate(
                offset: Offset(0, -float * 0.5),
                child: _buildFloatingBadge(
                  Icons.analytics_rounded,
                  widget.gradient[0],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingBadge(IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }

  Widget _buildPulsingRing(double size, double opacity) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        final scale = 1.0 + (_pulseController.value * 0.08);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: size * 2,
            height: size * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.gradient[0].withOpacity(opacity),
                width: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }
}
