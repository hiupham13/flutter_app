import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      state = AsyncValue.error(e.message ?? 'Đăng nhập thất bại', st);
    } catch (e, st) {
      state = AsyncValue.error('Đăng nhập thất bại', st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      print('🔵 [AuthController] Starting Google Sign In');
      final cred = await _repo.signInWithGoogle();
      print('✅ [AuthController] Got Firebase credential');
      print('   - User ID: ${cred.user?.uid}');
      print('   - Email: ${cred.user?.email}');
      print('   - Display Name: ${cred.user?.displayName}');
      
      // Create user profile if new user
      if (cred.user != null) {
        print('🔵 [AuthController] Ensuring user profile...');
        await _ensureUserProfile(cred.user!);
        print('✅ [AuthController] Profile check complete');
      }
      
      state = AsyncValue.data(cred.user);
      print('✅ [AuthController] Sign in complete!');
      
    } on FirebaseAuthException catch (e, st) {
      print('❌ [AuthController] FirebaseAuthException: ${e.code} - ${e.message}');
      state = AsyncValue.error(e.message ?? 'Đăng nhập Google thất bại', st);
    } catch (e, st) {
      print('❌ [AuthController] Error: $e');
      state = AsyncValue.error('Đăng nhập Google thất bại', st);
    }
  }

  Future<void> signInWithFacebook() async {
    state = const AsyncValue.loading();
    try {
      final cred = await _repo.signInWithFacebook();
      state = AsyncValue.data(cred.user);
    } on FirebaseAuthException catch (e, st) {
      state = AsyncValue.error(e.message ?? 'Đăng nhập Facebook thất bại', st);
    } catch (e, st) {
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
      state = AsyncValue.error(e.message ?? 'Đăng ký thất bại', st);
    } catch (e, st) {
      state = AsyncValue.error('Đăng ký thất bại', st);
    }
  }
  
  Future<void> _ensureUserProfile(User user) async {
    try {
      print('🔍 [_ensureUserProfile] Checking profile for ${user.uid}');
      
      // Check if profile exists
      final existingProfile = await _userRepo.getUserProfile(user.uid);
      
      if (existingProfile == null) {
        print('📝 [_ensureUserProfile] Profile not found, creating...');
        print('   - UID: ${user.uid}');
        print('   - Email: ${user.email}');
        print('   - Display Name: ${user.displayName}');
        print('   - Photo URL: ${user.photoURL}');
        
        // Create new profile with user info from Firebase Auth
        final userInfo = app_models.UserInfo(
          displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
          email: user.email ?? '',
          avatarUrl: user.photoURL,
        );
        
        print('   - Final displayName: ${userInfo.displayName}');
        print('   - Final email: ${userInfo.email}');
        
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
        
        print('✅ [_ensureUserProfile] Profile created successfully!');
      } else {
        print('✅ [_ensureUserProfile] Profile already exists');
        print('   - Existing Display Name: ${existingProfile.info.displayName}');
        print('   - Existing Email: ${existingProfile.info.email}');
        
        // Check if Firebase Auth has newer/better data
        final authEmail = user.email ?? '';
        final authDisplayName = user.displayName ?? user.email?.split('@').first ?? 'User';
        
        final needsUpdate =
          existingProfile.info.email != authEmail ||
          existingProfile.info.displayName == 'User' ||
          existingProfile.info.email == 'no-email@example.com';
        
        if (needsUpdate) {
          print('🔄 [_ensureUserProfile] Updating profile with Firebase Auth data...');
          print('   - New Email: $authEmail');
          print('   - New Display Name: $authDisplayName');
          
          final updatedInfo = app_models.UserInfo(
            displayName: authDisplayName,
            email: authEmail,
            avatarUrl: user.photoURL ?? existingProfile.info.avatarUrl,
          );
          
          await _userRepo.updateUserProfile(
            uid: user.uid,
            info: updatedInfo,
          );
          
          print('✅ [_ensureUserProfile] Profile updated successfully!');
        } else {
          print('✅ [_ensureUserProfile] Profile data is up-to-date');
        }
      }
    } catch (e, st) {
      // Log but don't throw - user can still use app
      print('❌ [_ensureUserProfile] Error: $e');
      print('   Stack trace: $st');
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

