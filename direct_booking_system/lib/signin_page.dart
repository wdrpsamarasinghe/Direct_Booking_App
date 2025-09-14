import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/firebase_service.dart';
import 'guide_home_page.dart';
import 'tourist_home_page.dart';
import 'admin_home_page.dart';
import 'theme/app_theme.dart';
import 'Signup_page.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({Key? key}) : super(key: key);

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
    _checkAuthState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Load remembered credentials from SharedPreferences
  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('remembered_email') ?? '';
        _passwordController.text = prefs.getString('remembered_password') ?? '';
      }
    });
  }

  // Save credentials to SharedPreferences
  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('remembered_email', _emailController.text.trim());
      await prefs.setString('remembered_password', _passwordController.text);
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('remembered_email');
      await prefs.remove('remembered_password');
    }
  }

  // Check if user is already authenticated
  Future<void> _checkAuthState() async {
    final user = _firebaseService.currentUser;
    if (user != null) {
      // User is already signed in, navigate to appropriate home page
      await _navigateToHomePage(user.uid);
    }
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back Button
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // App Logo/Icon
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.floatingShadow,
                  ),
                  child: const Icon(
                    Icons.explore,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Welcome Text
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Sign in to your account to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 50),
                
                // Signin Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  child: Column(
                    children: [
                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        labelText: "Email Address",
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Password Field
                      _buildPasswordField(),
                      
                      const SizedBox(height: 20),
                      
                      // (User role selection removed; role is derived from Firestore after sign-in)
                      const SizedBox(height: 16),
                      
                      // Remember Me & Forgot Password
                      Row(
                        children: [
                          // Remember Me Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: AppTheme.primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const Text(
                                'Remember me',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          
                          const Spacer(),
                          
                          // Forgot Password
                          GestureDetector(
                            onTap: () {
                              // Handle forgot password
                              ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Forgot password feature coming soon!'),
                                backgroundColor: AppTheme.primaryBlue,
                              ),
                              );
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Signin Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  "Sign In",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey[300],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Social Signin Buttons
                      _buildSocialButton(
                        icon: Icons.g_mobiledata,
                        text: 'Continue with Google',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Google sign-in coming soon!'),
                              backgroundColor: Color(0xFF667eea),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildSocialButton(
                        icon: Icons.facebook,
                        text: 'Continue with Facebook',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Facebook sign-in coming soon!'),
                              backgroundColor: Color(0xFF667eea),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Signup Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(
          prefixIcon,
          color: AppTheme.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: "Password",
        prefixIcon: Icon(
          Icons.lock_outline,
          color: AppTheme.textSecondary,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: AppTheme.textSecondary,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }

  // (Role dropdown removed)

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          side: const BorderSide(color: AppTheme.dividerBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  void _handleSignin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase sign in
      final credential = await _firebaseService
          .signInWithEmailAndPassword(email, password);

      final user = credential?.user;
      if (user == null) throw FirebaseAuthException(code: 'user-null', message: 'Failed to sign in.');

      // Save credentials if "Remember Me" is checked
      await _saveCredentials();

      // Navigate to appropriate home page
      await _navigateToHomePage(user.uid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Signed in successfully'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Authentication failed';
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
          message = 'Invalid email or password';
          break;
        case 'user-not-found':
          message = 'No user found for that email';
          break;
        case 'user-disabled':
          message = 'User account is disabled';
          break;
        default:
          message = e.message ?? message;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Navigate to appropriate home page based on user role
  Future<void> _navigateToHomePage(String userId) async {
    try {
      // Fetch user role from Firestore
      final doc = await _firebaseService.getUserData(userId);
      final data = doc.data() as Map<String, dynamic>?;
      final role = (data?['role'] as String?) ?? 'Tourist';

      // Debug logging
      print('DEBUG: User ID: $userId');
      print('DEBUG: User data: $data');
      print('DEBUG: Role from Firestore: $role');

      // Decide destination based on role (from Firestore)
      Widget targetPage;
      switch (role.toLowerCase()) {
        case 'tour guide':
          targetPage = const GuideHomePage();
          break;
        case 'admin':
          targetPage = const AdminHomePage();
          break;
        case 'tourist':
        default:
          targetPage = const TouristHomePage();
      }

      print('DEBUG: Navigating to: ${targetPage.runtimeType}');
      
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => targetPage),
        (route) => false,
      );
    } catch (e) {
      // If role fetch fails, default to Tourist home page
      print('DEBUG: Error fetching user role: $e');
      print('DEBUG: Defaulting to TouristHomePage');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const TouristHomePage()),
        (route) => false,
      );
    }
  }
}
