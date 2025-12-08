import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

class AuthController extends StateNotifier<AsyncValue<User?>> {
  AuthController(this._repo) : super(const AsyncValue.data(null));

  final AuthRepository _repo;

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

  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final cred = await _repo.signUpWithEmail(email: email, password: password);
      state = AsyncValue.data(cred.user);
    } on FirebaseAuthException catch (e, st) {
      state = AsyncValue.error(e.message ?? 'Đăng ký thất bại', st);
    } catch (e, st) {
      state = AsyncValue.error('Đăng ký thất bại', st);
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
  return AuthController(repo);
});

