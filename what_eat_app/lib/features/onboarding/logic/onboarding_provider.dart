import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../user/data/user_preferences_repository.dart';
import '../../../models/user_model.dart';
import '../../../core/utils/logger.dart';

class OnboardingState {
  final int step;
  final bool isSaving;
  final String? error;

  const OnboardingState({
    this.step = 0,
    this.isSaving = false,
    this.error,
  });

  OnboardingState copyWith({
    int? step,
    bool? isSaving,
    String? error,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._repo) : super(const OnboardingState());

  final UserPreferencesRepository _repo;

  final List<String> allergies = [];
  final List<String> cuisines = [];
  int budget = 2;
  int spiceTolerance = 2;

  void nextStep() => state = state.copyWith(step: state.step + 1);
  void prevStep() => state = state.copyWith(step: state.step - 1);

  Future<bool> save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      state = state.copyWith(error: 'Chưa đăng nhập');
      return false;
    }

    state = state.copyWith(isSaving: true, error: null);
    try {
      final settings = UserSettings(
        defaultBudget: budget,
        spiceTolerance: spiceTolerance,
        isVegetarian: false,
        blacklistedFoods: const [],
        excludedAllergens: List.from(allergies),
        favoriteCuisines: List.from(cuisines),
        onboardingCompleted: true,
      );

      await _repo.upsertUserSettings(uid, settings);
      return true;
    } catch (e, st) {
      AppLogger.error('Onboarding save failed: $e', e, st);
      state = state.copyWith(error: 'Lưu thất bại, thử lại sau');
      return false;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<void> markCompletedOnly() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.updateOnboardingCompletion(uid);
    } catch (e, st) {
      AppLogger.error('Skip onboarding failed: $e', e, st);
      state = state.copyWith(error: 'Không thể bỏ qua onboarding');
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  return OnboardingController(UserPreferencesRepository());
});

