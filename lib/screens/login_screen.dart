import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  final VoidCallback onSkip;
  const LoginScreen({super.key, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: NHRColors.milk,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NHRColors.milkDeep,
                  border: Border.all(color: NHRColors.fog, width: 2),
                ),
                child: Center(
                  child: Text('N', style: GoogleFonts.poppins(
                    fontSize: 36, fontWeight: FontWeight.w800,
                    color: NHRColors.charcoal, height: 1)),
                ),
              ).animate().scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOut),

              const SizedBox(height: 28),

              Text('NHR', style: GoogleFonts.poppins(
                fontSize: 42, fontWeight: FontWeight.w800,
                color: NHRColors.charcoal, letterSpacing: 6,
              )).animate().fadeIn(delay: 200.ms, duration: 500.ms),

              const SizedBox(height: 8),

              Text('Your personal productivity hub', style: GoogleFonts.inter(
                fontSize: 14, color: NHRColors.dusty, letterSpacing: 0.5,
              )).animate().fadeIn(delay: 400.ms, duration: 500.ms),

              const Spacer(flex: 2),

              // Sign in with Google button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : () async {
                    final success = await auth.signInWithGoogle();
                    if (success && context.mounted) {
                      // Will be handled by the router in main.dart
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NHRColors.charcoal,
                    foregroundColor: NHRColors.milk,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: NHRColors.milk))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google "G" icon
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(child: Text('G', style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: NHRColors.charcoal, height: 1.2))),
                            ),
                            const SizedBox(width: 12),
                            Text('Sign in with Google', style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 500.ms).slideY(begin: 0.1),

              if (auth.error != null) ...[
                const SizedBox(height: 12),
                Text(auth.error!, style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.red.shade400),
                  textAlign: TextAlign.center),
              ],

              const SizedBox(height: 16),

              // Skip button
              TextButton(
                onPressed: auth.isLoading ? null : onSkip,
                child: Text('Continue without signing in', style: GoogleFonts.inter(
                  fontSize: 13, color: NHRColors.dusty,
                  decoration: TextDecoration.underline,
                  decorationColor: NHRColors.fog)),
              ).animate().fadeIn(delay: 800.ms, duration: 500.ms),

              const Spacer(flex: 1),

              // Footer
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('Sign in to sync your data across devices',
                  style: GoogleFonts.inter(fontSize: 11, color: NHRColors.textMuted),
                  textAlign: TextAlign.center),
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }
}
