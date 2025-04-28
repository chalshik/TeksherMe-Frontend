import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/firebase_auth.dart';
import '../service/firebaseService.dart';
import '../data/theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final firebaseService = FirebaseService();
        
        // Sign in with email and password
        final UserCredential credential = await authService.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        // Update user's last login timestamp
        if (credential.user != null) {
          await firebaseService.updateUserLastLogin(credential.user!.uid);
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          final authService = Provider.of<AuthService>(context, listen: false);
          _errorMessage = authService.getAuthErrorMessage(e);
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firebaseService = FirebaseService();
      
      // Sign in with Google
      final UserCredential? credential = await authService.signInWithGoogle();
      
      // Create or update user profile in Firestore
      if (credential?.user != null) {
        await firebaseService.createUserProfile(credential!.user!);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        final authService = Provider.of<AuthService>(context, listen: false);
        _errorMessage = authService.getAuthErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isLightMode 
                ? [
                    Theme.of(context).colorScheme.background,
                    Theme.of(context).colorScheme.background,
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  ]
                : [
                    Theme.of(context).colorScheme.background,
                    Theme.of(context).colorScheme.background.withOpacity(0.9),
                  ],
            ),
          ),
          child: SafeArea(
            child: Center(
        child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                    // Logo and App Name
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                'TeksherMe',
                textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 32,
                  fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
                    Text(
                'Sign in to continue',
                textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isLightMode ? Colors.black54 : Colors.white70,
                ),
              ),
                    const SizedBox(height: 40),
                    
                    // Login Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                          // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                        labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: Icon(
                                Icons.email_rounded,
                                color: isLightMode ? Colors.black45 : Colors.white60,
                              ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                          const SizedBox(height: 20),
                          
                          // Password field
                    TextFormField(
                      controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                        labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: Icon(
                                Icons.lock_rounded,
                                color: isLightMode ? Colors.black45 : Colors.white60,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword 
                                      ? Icons.visibility_rounded 
                                      : Icons.visibility_off_rounded,
                                  color: isLightMode ? Colors.black45 : Colors.white60,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                          
                          // Forgot password button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Handle forgot password
                          if (_emailController.text.isNotEmpty) {
                            final authService = Provider.of<AuthService>(context, listen: false);
                            authService.sendPasswordResetEmail(_emailController.text.trim());
                                  
                                  // Show snackbar with beautiful styling
                            ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Password reset email sent',
                                        style: TextStyle(
                                          color: isLightMode ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      backgroundColor: isLightMode 
                                          ? TeksherTheme.successLight 
                                          : TeksherTheme.successDark,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please enter your email first',
                                        style: TextStyle(
                                          color: isLightMode ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      backgroundColor: isLightMode 
                                          ? TeksherTheme.errorLight 
                                          : TeksherTheme.errorDark,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                            );
                          }
                        },
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                              ),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                          
                          // Error message
                    if (_errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(top: 8, bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: TeksherTheme.errorLight.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: TeksherTheme.errorLight.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: TeksherTheme.errorLight,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                        child: Text(
                          _errorMessage!,
                                      style: TextStyle(
                                        color: TeksherTheme.errorLight,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 20),
                          
                          // Sign In Button with loading indicator
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signInWithEmailAndPassword,
                      style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.0,
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Register option
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                              Text(
                                'Don\'t have an account?',
                                style: TextStyle(
                                  color: isLightMode ? Colors.black54 : Colors.white70,
                                ),
                              ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => 
                                        const RegisterScreen(),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        var begin = const Offset(1.0, 0.0);
                                        var end = Offset.zero;
                                        var curve = Curves.easeOutQuint;
                                        var tween = Tween(begin: begin, end: end).chain(
                                          CurveTween(curve: curve),
                                        );
                                        return SlideTransition(
                                          position: animation.drive(tween),
                                          child: child,
                                        );
                                      },
                                    ),
                            );
                          },
                          child: const Text('Register Now'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
                    
                    const SizedBox(height: 30),
                    
                    // Divider with "OR"
                    Row(
                children: [
                        Expanded(
                          child: Divider(
                            color: isLightMode ? Colors.black26 : Colors.white24,
                            thickness: 1,
                          ),
                        ),
                  Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: isLightMode ? Colors.black45 : Colors.white60,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isLightMode ? Colors.black26 : Colors.white24,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Google Sign In Button
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        minimumSize: const Size.fromHeight(56),
                        side: BorderSide(
                          color: isLightMode 
                              ? Colors.black12 
                              : Colors.white30,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                ),
                icon: Image.network(
                  'https://www.freepnglogos.com/uploads/google-logo-png/google-logo-png-suite-everything-you-need-know-about-google-newest-0.png',
                        height: 20,
                        width: 20,
                      ),
                      label: Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isLightMode ? Colors.black87 : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 