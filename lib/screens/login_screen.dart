import 'package:flutter/material.dart';
import 'package:strangr_app/core/theme.dart';
import 'package:strangr_app/core/auth_service.dart';
import 'dart:ui';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleGoogleLogin() async {
    setState(() { _isLoading = true; });
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null) {
         // Success logging in
         Navigator.pushReplacementNamed(context, '/search_hub');
      } else {
         // Fallback if login fails or is cancelled
         // Allows testing UI flow without configured Firebase
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Firebase not configured or login cancelled. Proceeding to Hub for demonstration.'))
         );
         Navigator.pushReplacementNamed(context, '/search_hub');
      }
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Sign-in Error: $e'))
      );
      // Wait a moment for the user to see the error, then navigate (optional, but good for demo)
      Future.delayed(const Duration(seconds: 2), () {
         if (mounted) Navigator.pushReplacementNamed(context, '/search_hub');
      });
    }
    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StrangRTheme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Radial Glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    Color(0xFF1E141E),
                    StrangRTheme.background,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  const Icon(Icons.link, color: StrangRTheme.primary, size: 60),
                  const SizedBox(height: 32),
                  Text(
                    'STRANGR',
                    style: StrangRTheme.textTheme.displayLarge?.copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'STEP INTO THE\nUNKNOWN.',
                    textAlign: TextAlign.center,
                    style: StrangRTheme.textTheme.displayLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connect instantly through secure matching.',
                    textAlign: TextAlign.center,
                    style: StrangRTheme.textTheme.bodyLarge,
                  ),
                  const Spacer(),
                  
                  // Login Button
                  GestureDetector(
                    onTap: _isLoading ? null : _handleGoogleLogin,
                    child: Container(
                      width: double.infinity,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: Colors.black,
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: StrangRTheme.primary.withOpacity(0.1),
                            blurRadius: 20,
                          )
                        ],
                      ),
                      child: Center(
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: StrangRTheme.primary)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.login, color: StrangRTheme.primary, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  'SIGN IN WITH GOOGLE',
                                  style: StrangRTheme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Text(
                    'BY CONTINUING, YOU ACCEPT OUR TERMS.',
                    style: StrangRTheme.textTheme.labelSmall?.copyWith(fontSize: 9),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
