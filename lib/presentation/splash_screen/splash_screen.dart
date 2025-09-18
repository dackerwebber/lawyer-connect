import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _backgroundFadeAnimation;

  bool _isInitializing = true;
  double _initializationProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade animation controller
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Logo scale animation
    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Logo fade animation
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.easeInOut,
    ));

    // Background fade animation
    _backgroundFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _fadeAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _logoAnimationController.forward();
      }
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Simulate authentication check
      await _updateProgress(0.2, "Checking authentication...");
      await Future.delayed(const Duration(milliseconds: 400));

      // Simulate loading user preferences
      await _updateProgress(0.4, "Loading preferences...");
      await Future.delayed(const Duration(milliseconds: 400));

      // Simulate fetching lawyer availability
      await _updateProgress(0.6, "Fetching lawyer availability...");
      await Future.delayed(const Duration(milliseconds: 500));

      // Simulate preparing cached case information
      await _updateProgress(0.8, "Preparing case data...");
      await Future.delayed(const Duration(milliseconds: 400));

      // Complete initialization
      await _updateProgress(1.0, "Ready!");
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });

        // Navigate after splash display
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _navigateToNextScreen();
          }
        });
      }
    } catch (e) {
      // Handle initialization error
      if (mounted) {
        _showRetryOption();
      }
    }
  }

  Future<void> _updateProgress(double progress, String status) async {
    if (mounted) {
      setState(() {
        _initializationProgress = progress;
      });
    }
  }

  void _navigateToNextScreen() {
    // After splash, navigate to login
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _showRetryOption() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Connection Error',
          style: AppTheme.lightTheme.textTheme.titleMedium,
        ),
        content: Text(
          'Unable to initialize the app. Please check your internet connection and try again.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isInitializing = true;
                _initializationProgress = 0.0;
              });
              _initializeApp();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppTheme.lightTheme.primaryColor,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: AnimatedBuilder(
          animation: _backgroundFadeAnimation,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.lightTheme.primaryColor.withValues(
                      alpha: _backgroundFadeAnimation.value,
                    ),
                    AppTheme.lightTheme.colorScheme.primaryContainer.withValues(
                      alpha: _backgroundFadeAnimation.value * 0.8,
                    ),
                    AppTheme.lightTheme.colorScheme.secondary.withValues(
                      alpha: _backgroundFadeAnimation.value * 0.6,
                    ),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Spacer to push content to center
                    const Spacer(flex: 2),

                    // Logo section
                    AnimatedBuilder(
                      animation: _logoAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: Opacity(
                            opacity: _logoFadeAnimation.value,
                            child: _buildLogo(),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 4.h),

                    // App name
                    AnimatedBuilder(
                      animation: _logoFadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoFadeAnimation.value,
                          child: Text(
                            'LawyerConnect',
                            style: AppTheme.lightTheme.textTheme.headlineLarge
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 1.h),

                    // Tagline
                    AnimatedBuilder(
                      animation: _logoFadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoFadeAnimation.value * 0.9,
                          child: Text(
                            'Connect with Verified Legal Experts',
                            style: AppTheme.lightTheme.textTheme.bodyLarge
                                ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 1),

                    // Loading section
                    if (_isInitializing) _buildLoadingSection(),

                    const Spacer(flex: 1),

                    // Footer
                    AnimatedBuilder(
                      animation: _logoFadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoFadeAnimation.value * 0.7,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'security',
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      size: 16,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'SSL Secured',
                                      style: AppTheme
                                          .lightTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    CustomIconWidget(
                                      iconName: 'verified',
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      size: 16,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Verified Lawyers',
                                      style: AppTheme
                                          .lightTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '© 2025 LawyerConnect. All rights reserved.',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 25.w,
      height: 25.w,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background legal pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CustomPaint(
                painter: _LegalPatternPainter(),
              ),
            ),
          ),

          // Main legal icon
          CustomIconWidget(
            iconName: 'gavel',
            color: Colors.white,
            size: 12.w,
          ),

          // Accent elements
          Positioned(
            top: 2.w,
            right: 2.w,
            child: Container(
              width: 3.w,
              height: 3.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.tertiary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection() {
    return AnimatedBuilder(
      animation: _logoFadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _logoFadeAnimation.value,
          child: Column(
            children: [
              // Progress indicator
              Container(
                width: 60.w,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _initializationProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 2.h),

              // Loading dots animation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    margin: EdgeInsets.symmetric(horizontal: 1.w),
                    width: 2.w,
                    height: 2.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: _initializationProgress > (index * 0.33)
                            ? 0.8
                            : 0.3,
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LegalPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw subtle legal-themed pattern
    final path = Path();

    // Scale pattern
    for (int i = 0; i < 3; i++) {
      final y = size.height * 0.2 + (i * size.height * 0.2);
      path.moveTo(size.width * 0.2, y);
      path.lineTo(size.width * 0.8, y);
    }

    // Balance scales pattern
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.3;

    // Left scale
    path.moveTo(centerX - size.width * 0.15, centerY);
    path.lineTo(centerX - size.width * 0.05, centerY - size.height * 0.1);

    // Right scale
    path.moveTo(centerX + size.width * 0.15, centerY);
    path.lineTo(centerX + size.width * 0.05, centerY - size.height * 0.1);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
