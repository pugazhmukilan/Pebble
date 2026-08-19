import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has completed onboarding.
/// State is a simple bool: true = onboarded, false = not yet.
class OnboardingCubit extends Cubit<bool> {
  OnboardingCubit() : super(false);

  static const _key = 'has_onboarded';

  /// Check if onboarding was already completed.
  Future<void> checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    emit(prefs.getBool(_key) ?? false);
  }

  /// Mark onboarding as completed — sets the flag so it never shows again.
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    emit(true);
  }
}
