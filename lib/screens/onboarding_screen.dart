import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/onboarding/onboarding_cubit.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'home_screen.dart';

/// Single-page onboarding — shown only on first launch (§5).
/// Content: app name, value prop, "Get Started" button.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),
              // App logo
              Image.asset(
                'assets/images/pebble_logo.png',
                width: 96,
                height: 96,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              Text('Pebble', style: styles.onboardingTitle),
              const SizedBox(height: 12),
              Text(
                'Manual-only expense tracking.\n'
                'Private. Local. Fast entry.\n'
                'Your data never leaves your device.',
                style: styles.onboardingBody,
              ),
              const Spacer(flex: 4),
              // Get Started button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<OnboardingCubit>().completeOnboarding();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.textPrimary,
                    foregroundColor: colors.surfaceRaised,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text('Get Started', style: styles.button),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}