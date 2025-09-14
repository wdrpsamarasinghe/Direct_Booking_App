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
    final Size screenSize = MediaQuery.of(context).size;
    final double shortestSide = screenSize.shortestSide;
    // Responsive sizing based on device size
    final double logoContainerSize = (shortestSide * 0.35).clamp(110.0, 200.0);
    final double logoIconSize = (logoContainerSize * 0.53).clamp(60.0, 120.0);
    final double appTitleSize = (shortestSide * 0.09).clamp(26.0, 42.0);
    final double taglineSize = (shortestSide * 0.04).clamp(12.0, 18.0);
    final double bottomSpace = (screenSize.height * 0.07).clamp(36.0, 80.0);

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
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              
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
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: AppTheme.floatingShadow,
                        ),
                        child: const Icon(
                          Icons.explore,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // App name with slide animation
              SlideTransition(
                position: _textSlideAnimation,
                child: Text(
                  'Guide Pro',
                  style: TextStyle(
                    fontSize: appTitleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Tagline with fade animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Manage Your Tours with Ease',
                  style: TextStyle(
                    fontSize: taglineSize,
                    color: Colors.white70,
                    letterSpacing: 0.5,
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
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: bottomSpace),
            ],
          ),
        ),
      ),
    );
  }
}

