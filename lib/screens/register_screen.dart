import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/firebase_auth.dart';
import '../service/firebaseService.dart';
import 'home_page.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Step 1: Create Firebase Auth Account
        final authService = Provider.of<AuthService>(context, listen: false);
        final firebaseService = FirebaseService();
        
        // Get input values and trim them
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();
        final displayName = _nameController.text.trim();
        
        // Register with email and password
        UserCredential? credential;
        try {
          credential = await authService.signUp(email, password);
        } catch (e) {
          print('Error during signUp: $e');
          // Check if error is the known PigeonUserDetails type cast error
          // but the account was actually created
          if (e.toString().contains('PigeonUserDetails')) {
            // Continue with the registration process despite the error
            // since this is a known issue with the Firebase Auth plugin
            print('Ignoring PigeonUserDetails error and continuing registration');
          } else {
            // For other errors, rethrow to be handled by the outer catch
            rethrow;
          }
        }
        
        // If we couldn't get a credential but there was no error thrown above,
        // try to sign in directly since the account was likely created
        if (credential == null) {
          try {
            credential = await authService.signIn(email, password);
            print('Successfully signed in after registration');
          } catch (e) {
            print('Error signing in after registration: $e');
            // If even this fails, continue anyway to try to create the profile
          }
        }

        // Get the user either from credential or current user
        User? user = credential?.user ?? FirebaseAuth.instance.currentUser;
        
        if (user == null) {
          // If we still don't have a user, show a specific error
          throw FirebaseAuthException(
            code: 'user-creation-failed',
            message: 'Failed to create account. Please try again.'
          );
        }
        
        // Step 2: Create user profile in Firestore even if we encountered errors
        try {
          await firebaseService.createUserProfile(
            user,
            displayName: displayName,
          );
        } catch (e) {
          print('Error creating profile: $e');
          // If profile creation fails, we continue anyway
        }
        
        // Step 3: Update display name in Firebase Auth
        try {
          await user.updateDisplayName(displayName);
        } catch (e) {
          print('Error updating display name: $e');
          // Continue even if this fails
        }
        
        // Successfully created account, now navigate to home
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        print('Firebase Auth Error: ${e.code} - ${e.message}');
        setState(() {
          final authService = Provider.of<AuthService>(context, listen: false);
          _errorMessage = authService.getAuthErrorMessage(e);
        });
      } catch (e) {
        print('Registration error: $e');
        
        // Check if it's the PigeonUserDetails error that we want to ignore
        if (e.toString().contains('PigeonUserDetails')) {
          // Try to sign in directly since the account was likely created
          try {
            final authService = Provider.of<AuthService>(context, listen: false);
            final email = _emailController.text.trim();
            final password = _passwordController.text.trim();
            
            await authService.signIn(email, password);
            
            // If successful, navigate to home
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
              return;
            }
          } catch (signInError) {
            print('Error signing in after PigeonUserDetails error: $signInError');
            // If sign-in fails, show the original error
          }
        }
        
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Join TeksherMe',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create an account to get started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
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
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _registerWithEmailAndPassword,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Register'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 