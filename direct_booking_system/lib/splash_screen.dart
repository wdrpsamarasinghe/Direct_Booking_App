import 'package:flutter/material.dart';
import 'signin_page.dart';
import 'theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _fadeController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Logo scale and rotation animations
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Text slide animation
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Start logo animation
    _logoController.forward();
    
    // Wait a bit then start text animation
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();
    
    // Wait a bit then start fade animation
    await Future.delayed(const Duration(milliseconds: 600));
    _fadeController.forward();
    
    // Navigate to signin page after animations complete
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SigninPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.secondaryOrange,
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final Size screenSize = Size(constraints.maxWidth, constraints.maxHeight);
            final double shortestSide = screenSize.shortestSide;
            final double longestSide = screenSize.longestSide;
            final bool isLandscape = constraints.maxWidth > constraints.maxHeight;
            
            // Responsive sizing based on screen dimensions and orientation
            final double logoContainerSize = _getResponsiveSize(
              shortestSide * (isLandscape ? 0.25 : 0.35),
              isLandscape ? 80.0 : 110.0,
              isLandscape ? 150.0 : 200.0,
            );
            
            final double appTitleSize = _getResponsiveSize(
              shortestSide * (isLandscape ? 0.06 : 0.09),
              isLandscape ? 20.0 : 26.0,
              isLandscape ? 32.0 : 42.0,
            );
            
            final double taglineSize = _getResponsiveSize(
              shortestSide * (isLandscape ? 0.035 : 0.04),
              isLandscape ? 10.0 : 12.0,
              isLandscape ? 14.0 : 18.0,
            );
            
            final double loadingSize = _getResponsiveSize(
              shortestSide * (isLandscape ? 0.08 : 0.1),
              isLandscape ? 30.0 : 40.0,
              isLandscape ? 50.0 : 60.0,
            );
            
            // Dynamic spacing based on screen size
            final double verticalSpacing = _getResponsiveSize(
              screenSize.height * (isLandscape ? 0.02 : 0.03),
              isLandscape ? 8.0 : 12.0,
              isLandscape ? 20.0 : 30.0,
            );
            
            final double bottomPadding = _getResponsiveSize(
              screenSize.height * (isLandscape ? 0.03 : 0.07),
              isLandscape ? 20.0 : 36.0,
              isLandscape ? 40.0 : 80.0,
            );
            
            // Handle safe area for notched devices
            final EdgeInsets safeAreaPadding = MediaQuery.of(context).padding;
            final double topPadding = safeAreaPadding.top;
            final double bottomSafePadding = safeAreaPadding.bottom;
            
            return Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.only(
                top: topPadding,
                bottom: bottomSafePadding,
                left: safeAreaPadding.left,
                right: safeAreaPadding.right,
              ),
              child: Column(
                children: [
                  SizedBox(height: isLandscape ? verticalSpacing * 2 : verticalSpacing * 3),
                  
                  // Logo with animations
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: Transform.rotate(
                          angle: _logoRotationAnimation.value * 2 * 3.14159,
                          child: Container(
                            height: logoContainerSize,
                            width: logoContainerSize,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(logoContainerSize * 0.2),
                              boxShadow: AppTheme.floatingShadow,
                            ),
                            child: Icon(
                              Icons.explore,
                              color: Colors.white,
                              size: logoContainerSize * 0.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: verticalSpacing * 2),
                  
                  // App name with slide animation
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: Text(
                      'Guide Pro',
                      style: TextStyle(
                        fontSize: appTitleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: isLandscape ? 0.8 : 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  SizedBox(height: verticalSpacing * 0.5),
                  
                  // Tagline with fade animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Manage Your Tours with Ease',
                      style: TextStyle(
                        fontSize: taglineSize,
                        color: Colors.white70,
                        letterSpacing: isLandscape ? 0.3 : 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Loading indicator
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        SizedBox(
                          width: loadingSize,
                          height: loadingSize,
                          child: CircularProgressIndicator(
                            strokeWidth: isLandscape ? 2.5 : 3.0,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(height: verticalSpacing),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: taglineSize * 0.8,
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: isLandscape ? 0.3 : 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: bottomPadding),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  /// Helper method to get responsive size with min/max constraints
  double _getResponsiveSize(double baseSize, double minSize, double maxSize) {
    return baseSize.clamp(minSize, maxSize);
  }
}

