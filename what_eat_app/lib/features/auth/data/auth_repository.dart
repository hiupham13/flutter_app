import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/utils/logger.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth;

  AuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _facebookAuth = facebookAuth ?? FacebookAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred;
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      AppLogger.warning('Google sign-in cancelled by user');
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Người dùng đã huỷ đăng nhập Google',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithFacebook() async {
    final loginResult = await _facebookAuth.login();
    AppLogger.info('Facebook login status: ${loginResult.status}, message: ${loginResult.message}');

    if (loginResult.status != LoginStatus.success) {
      AppLogger.warning('Facebook login failed: ${loginResult.status} - ${loginResult.message}');
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: loginResult.message ?? 'Đăng nhập Facebook bị huỷ',
      );
    }
    final accessToken = loginResult.accessToken;
    if (accessToken == null) {
      AppLogger.error('Facebook access token is null');
      throw FirebaseAuthException(
        code: 'ERROR_MISSING_TOKEN',
        message: 'Không lấy được access token Facebook',
      );
    }
    AppLogger.info('Facebook token received: ${accessToken.toJson()}');
    final credential = FacebookAuthProvider.credential(accessToken.tokenString);
    return _auth.signInWithCredential(credential);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await _facebookAuth.logOut();
  }
}

