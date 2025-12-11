import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/user_preferences_repository.dart';
import '../../auth/data/repositories/user_repository.dart';
import '../../../models/user_model.dart' as app_models;
import '../../../core/utils/logger.dart';

final userPreferencesRepositoryProvider =
    Provider<UserPreferencesRepository>((ref) {
  return UserPreferencesRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final userSettingsProvider = FutureProvider<app_models.UserSettings?>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
  final repo = ref.watch(userPreferencesRepositoryProvider);
  return repo.fetchUserSettings(uid);
});

final userProfileStreamProvider = StreamProvider<app_models.UserModel?>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    return const Stream<app_models.UserModel?>.empty();
  }
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchUserProfile(uid);
});

class UserProfileController extends StateNotifier<AsyncValue<app_models.UserModel?>> {
  UserProfileController(this._userRepo) : super(const AsyncValue.loading()) {
    _load();
  }

  final UserRepository _userRepo;

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final user = await _userRepo.getUserProfile(uid);
      state = AsyncValue.data(user);
    } catch (e, st) {
      AppLogger.error('Load user profile failed: $e', e, st);
      state = AsyncValue.error('Không tải được hồ sơ người dùng', st);
    }
  }

  Future<void> refresh() async => _load();

  Future<void> updateInfo({
    String? displayName,
    String? email,
    String? avatarUrl,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final current = state.value;
    final info = app_models.UserInfo(
      displayName: displayName ?? current?.info.displayName ?? '',
      email: email ?? current?.info.email ?? '',
      avatarUrl: avatarUrl ?? current?.info.avatarUrl,
    );

    state = const AsyncValue.loading();
    try {
      await _userRepo.updateUserProfile(uid: uid, info: info);
      await _load();
    } catch (e, st) {
      AppLogger.error('Update info failed: $e', e, st);
      state = AsyncValue.error('Không cập nhật được hồ sơ', st);
    }
  }

  Future<void> updateSettings(app_models.UserSettings settings) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    state = const AsyncValue.loading();
    try {
      await _userRepo.updateUserProfile(uid: uid, settings: settings);
      await _load();
    } catch (e, st) {
      AppLogger.error('Update settings failed: $e', e, st);
      state = AsyncValue.error('Không cập nhật được thiết lập', st);
    }
  }

  Future<void> updatePreferences({
    List<String>? favoriteCuisines,
    List<String>? excludedAllergens,
    List<String>? blacklistedFoods,
    int? defaultBudget,
    int? spiceTolerance,
    bool? isVegetarian,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final current = state.value?.settings;
    final updated = app_models.UserSettings(
      defaultBudget: defaultBudget ?? current?.defaultBudget ?? 2,
      spiceTolerance: spiceTolerance ?? current?.spiceTolerance ?? 2,
      isVegetarian: isVegetarian ?? current?.isVegetarian ?? false,
      blacklistedFoods: blacklistedFoods ?? current?.blacklistedFoods ?? const [],
      excludedAllergens:
          excludedAllergens ?? current?.excludedAllergens ?? const [],
      favoriteCuisines: favoriteCuisines ?? current?.favoriteCuisines ?? const [],
      onboardingCompleted: current?.onboardingCompleted ?? true,
    );

    await updateSettings(updated);
  }
}

final userProfileControllerProvider =
    StateNotifierProvider<UserProfileController, AsyncValue<app_models.UserModel?>>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return UserProfileController(repo);
});

