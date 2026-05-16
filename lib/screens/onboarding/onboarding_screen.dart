import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rounded_button.dart';
import 'onboarding_page.dart';
import '../profile/profile_setup_screen.dart';
import '../../services/storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final StorageService _storage = StorageService();

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.camera_alt,
      'iconColor': AppTheme.primaryBlue,
      'title': 'Scan Medicine',
      'description':
          'Take a picture of any medicine or tablet to instantly identify it and get detailed information about its contents and uses.',
    },
    {
      'icon': Icons.notifications_active,
      'iconColor': const Color(0xFFFF9800),
      'title': 'Never Miss a Dose',
      'description':
          'Set up medication reminders by manually adding medicines or scanning prescriptions. Get timely notifications before or after meals.',
    },
    {
      'icon': Icons.health_and_safety,
      'iconColor': const Color(0xFF4CAF50),
      'title': 'Stay Safe',
      'description':
          'Get warnings about harmful contents and age-specific precautions to keep you and your loved ones safe.',
    },
    {
      'icon': Icons.auto_awesome,
      'iconColor': const Color(0xFF9C27B0),
      'title': 'Smart Health Assistant',
      'description':
          'Check expiry dates automatically, get drug interaction warnings, track your medication streaks, and share reports with your doctor.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _skipOrContinue() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    await _storage.setOnboardingComplete();
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const ProfileSetupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'Skip',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return OnboardingPage(
                    icon: page['icon'] as IconData,
                    iconColor: page['iconColor'] as Color,
                    title: page['title'] as String,
                    description: page['description'] as String,
                  );
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXSmall,
                  ),
                  width: _currentPage == index ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.primaryBlue
                        : AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: RoundedButton(
                text: _currentPage == _pages.length - 1
                    ? 'Get Started'
                    : 'Next',
                onPressed: _skipOrContinue,
                icon: _currentPage == _pages.length - 1
                    ? Icons.check
                    : Icons.arrow_forward,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
