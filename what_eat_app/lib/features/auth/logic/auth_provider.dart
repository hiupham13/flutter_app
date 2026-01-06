import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../data/auth_repository.dart';
import '../data/repositories/user_repository.dart';
import '../../../models/user_model.dart' as app_models;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

class AuthController extends StateNotifier<AsyncValue<User?>> {
  AuthController(this._repo, this._userRepo) : super(const AsyncValue.data(null));

  final AuthRepository _repo;
  final UserRepository _userRepo;

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final cred = await _repo.signInWithEmail(email: email, password: password);
      state = AsyncValue.data(cred.user);
    } on FirebaseAuthException catch (e, st) {
      // Gửi lỗi lên Crashlytics
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Email sign-in failed: ${e.code}',
        fatal: false,
      );
      state = AsyncValue.error(e.message ?? 'Đăng nhập thất bại', st);
    } catch (e, st) {
      // Gửi lỗi lên Crashlytics
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Email sign-in unexpected error',
        fatal: false,
      );
      state = AsyncValue.error('Đăng nhập thất bại', st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      debugPrint('🔵 [AuthController] Starting Google Sign In');
      final cred = await _repo.signInWithGoogle();
      debugPrint('✅ [AuthController] Got Firebase credential');
      debugPrint('   - User ID: ${cred.user?.uid}');
      debugPrint('   - Email: ${cred.user?.email}');
      debugPrint('   - Display Name: ${cred.user?.displayName}');
      
      // Create user profile if new user
      if (cred.user != null) {
        debugPrint('🔵 [AuthController] Ensuring user profile...');
        await _ensureUserProfile(cred.user!);
        debugPrint('✅ [AuthController] Profile check complete');
      }
      
      state = AsyncValue.data(cred.user);
      debugPrint('✅ [AuthController] Sign in complete!');
      
    } on FirebaseAuthException catch (e, st) {
      debugPrint('❌ [AuthController] FirebaseAuthException: ${e.code} - ${e.message}');
      
      // Gửi lỗi lên Crashlytics để theo dõi trên Play Store
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Google Sign-In failed in AuthController: ${e.code}',
        fatal: false,
        information: [
          'Error Code: ${e.code}',
          'Error Message: ${e.message}',
        ],
      );
      
      state = AsyncValue.error(e.message ?? 'Đăng nhập Google thất bại', st);
    } catch (e, st) {
      debugPrint('❌ [AuthController] Error: $e');
      
      // Gửi lỗi lên Crashlytics để theo dõi trên Play Store
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Google Sign-In unexpected error in AuthController',
        fatal: false,
        information: [
          'Error Type: ${e.runtimeType}',
          'Error Message: $e',
        ],
      );
      
      state = AsyncValue.error('Đăng nhập Google thất bại', st);
    }
  }

  Future<void> signInWithFacebook() async {
    state = const AsyncValue.loading();
    try {
      final cred = await _repo.signInWithFacebook();
      state = AsyncValue.data(cred.user);
    } on FirebaseAuthException catch (e, st) {
      // Gửi lỗi lên Crashlytics
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Facebook sign-in failed: ${e.code}',
        fatal: false,
      );
      state = AsyncValue.error(e.message ?? 'Đăng nhập Facebook thất bại', st);
    } catch (e, st) {
      // Gửi lỗi lên Crashlytics
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Facebook sign-in unexpected error',
        fatal: false,
      );
      state = AsyncValue.error('Đăng nhập Facebook thất bại', st);
    }
  }

  Future<void> sendResetEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repo.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e, st) {
      state = AsyncValue.error(e.message ?? 'Không gửi được email khôi phục', st);
    } catch (e, st) {
      state = AsyncValue.error('Không gửi được email khôi phục', st);
    }
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final cred = await _repo.signUpWithEmail(email: email, password: password);
      
      // Create user profile for new user
      if (cred.user != null) {
        await _ensureUserProfile(cred.user!);
      }
      
      state = AsyncValue.data(cred.user);
    } on FirebaseAuthException catch (e, st) {
      // Gửi lỗi lên Crashlytics
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Sign-up failed: ${e.code}',
        fatal: false,
      );
      state = AsyncValue.error(e.message ?? 'Đăng ký thất bại', st);
    } catch (e, st) {
      // Gửi lỗi lên Crashlytics
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Sign-up unexpected error',
        fatal: false,
      );
      state = AsyncValue.error('Đăng ký thất bại', st);
    }
  }
  
  Future<void> _ensureUserProfile(User user) async {
    try {
      debugPrint('🔍 [_ensureUserProfile] Checking profile for ${user.uid}');
      
      // Check if profile exists
      final existingProfile = await _userRepo.getUserProfile(user.uid);
      
      if (existingProfile == null) {
        debugPrint('📝 [_ensureUserProfile] Profile not found, creating...');
        debugPrint('   - UID: ${user.uid}');
        debugPrint('   - Email: ${user.email}');
        debugPrint('   - Display Name: ${user.displayName}');
        debugPrint('   - Photo URL: ${user.photoURL}');
        
        // Create new profile with user info from Firebase Auth
        final userInfo = app_models.UserInfo(
          displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
          email: user.email ?? '',
          avatarUrl: user.photoURL,
        );
        
        debugPrint('   - Final displayName: ${userInfo.displayName}');
        debugPrint('   - Final email: ${userInfo.email}');
        
        final settings = app_models.UserSettings(
          defaultBudget: 2,
          spiceTolerance: 2,
          isVegetarian: false,
          blacklistedFoods: const [],
          excludedAllergens: const [],
          favoriteCuisines: const [],
          onboardingCompleted: false,
        );
        
        await _userRepo.createUserProfile(
          uid: user.uid,
          info: userInfo,
          settings: settings,
        );
        
        debugPrint('✅ [_ensureUserProfile] Profile created successfully!');
      } else {
        debugPrint('✅ [_ensureUserProfile] Profile already exists');
        debugPrint('   - Existing Display Name: ${existingProfile.info.displayName}');
        debugPrint('   - Existing Email: ${existingProfile.info.email}');
        
        // Check if Firebase Auth has newer/better data
        final authEmail = user.email ?? '';
        final authDisplayName = user.displayName ?? user.email?.split('@').first ?? 'User';
        
        final needsUpdate =
          existingProfile.info.email != authEmail ||
          existingProfile.info.displayName == 'User' ||
          existingProfile.info.email == 'no-email@example.com';
        
        if (needsUpdate) {
          debugPrint('🔄 [_ensureUserProfile] Updating profile with Firebase Auth data...');
          debugPrint('   - New Email: $authEmail');
          debugPrint('   - New Display Name: $authDisplayName');
          
          final updatedInfo = app_models.UserInfo(
            displayName: authDisplayName,
            email: authEmail,
            avatarUrl: user.photoURL ?? existingProfile.info.avatarUrl,
          );
          
          await _userRepo.updateUserProfile(
            uid: user.uid,
            info: updatedInfo,
          );
          
          debugPrint('✅ [_ensureUserProfile] Profile updated successfully!');
        } else {
          debugPrint('✅ [_ensureUserProfile] Profile data is up-to-date');
        }
      }
    } catch (e, st) {
      // Log but don't throw - user can still use app
      debugPrint('❌ [_ensureUserProfile] Error: $e');
      debugPrint('   Stack trace: $st');
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final userRepo = UserRepository();
  return AuthController(repo, userRepo);
});

