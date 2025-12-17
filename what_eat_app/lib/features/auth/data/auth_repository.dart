import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
        _googleSignIn = googleSignIn ?? GoogleSignIn(
          // Web client ID từ google-services.json (client_type: 3)
          // Cần thiết để Firebase Authentication xác thực credential
          serverClientId: '55060102370-kv68udhnuvo0p4gjr2dt95paufck8iik.apps.googleusercontent.com',
        ),
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
    try {
      AppLogger.info('🔵 [GoogleSignIn] Starting Google Sign-In process...');
      AppLogger.info('   - serverClientId configured: ${_googleSignIn.serverClientId != null}');
      
      final googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        AppLogger.warning('❌ [GoogleSignIn] User cancelled sign-in');
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Người dùng đã huỷ đăng nhập Google',
        );
      }
      
      AppLogger.info('✅ [GoogleSignIn] Google user obtained');
      AppLogger.info('   - Email: ${googleUser.email}');
      AppLogger.info('   - Display Name: ${googleUser.displayName}');
      AppLogger.info('   - ID: ${googleUser.id}');
      
      AppLogger.info('🔵 [GoogleSignIn] Getting authentication tokens...');
      final googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        AppLogger.error('❌ [GoogleSignIn] idToken is NULL!');
        AppLogger.error('   - This usually means serverClientId is missing or incorrect');
        AppLogger.error('   - Current serverClientId: ${_googleSignIn.serverClientId}');
        throw FirebaseAuthException(
          code: 'ERROR_MISSING_ID_TOKEN',
          message: 'Không lấy được idToken từ Google. Vui lòng kiểm tra cấu hình serverClientId.',
        );
      }
      
      if (googleAuth.accessToken == null) {
        AppLogger.error('❌ [GoogleSignIn] accessToken is NULL!');
        throw FirebaseAuthException(
          code: 'ERROR_MISSING_ACCESS_TOKEN',
          message: 'Không lấy được accessToken từ Google.',
        );
      }
      
      AppLogger.info('✅ [GoogleSignIn] Authentication tokens obtained');
      AppLogger.info('   - idToken: ${googleAuth.idToken?.substring(0, 20)}...');
      AppLogger.info('   - accessToken: ${googleAuth.accessToken?.substring(0, 20)}...');
      
      AppLogger.info('🔵 [GoogleSignIn] Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      AppLogger.info('🔵 [GoogleSignIn] Signing in with Firebase...');
      final userCred = await _auth.signInWithCredential(credential);
      
      AppLogger.info('✅ [GoogleSignIn] Firebase sign-in successful!');
      AppLogger.info('   - Firebase UID: ${userCred.user?.uid}');
      AppLogger.info('   - Firebase Email: ${userCred.user?.email}');
      
      return userCred;
      
    } on FirebaseAuthException catch (e, st) {
      AppLogger.error('❌ [GoogleSignIn] FirebaseAuthException', e, st);
      AppLogger.error('   - Error Code: ${e.code}');
      AppLogger.error('   - Error Message: ${e.message}');
      AppLogger.error('   - Error Details: ${e.toString()}');
      
      // Gửi lỗi lên Crashlytics để theo dõi trên Play Store
      await FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Google Sign-In failed: ${e.code}',
        fatal: false,
        information: [
          'Error Code: ${e.code}',
          'Error Message: ${e.message}',
          'Server Client ID configured: ${_googleSignIn.serverClientId != null}',
        ],
      );
      
      rethrow;
    } catch (e, st) {
      AppLogger.error('❌ [GoogleSignIn] Unexpected error', e, st);
      AppLogger.error('   - Error Type: ${e.runtimeType}');
      AppLogger.error('   - Error Message: $e');
      
      // Gửi lỗi lên Crashlytics để theo dõi trên Play Store
      await FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Google Sign-In unexpected error: ${e.runtimeType}',
        fatal: false,
        information: [
          'Error Type: ${e.runtimeType}',
          'Error Message: $e',
        ],
      );
      
      rethrow;
    }
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
    try {
      await _auth.signOut();
    } catch (e, st) {
      AppLogger.error('❌ [signOut] Firebase Auth signOut failed', e, st);
      // Continue với các signOut khác
    }
    
    try {
      await _googleSignIn.signOut();
    } catch (e, st) {
      AppLogger.error('❌ [signOut] Google Sign-In signOut failed', e, st);
      // Continue với Facebook signOut
    }
    
    try {
      await _facebookAuth.logOut();
    } catch (e, st) {
      AppLogger.error('❌ [signOut] Facebook Auth logOut failed', e, st);
      // Log nhưng không throw - signOut vẫn thành công nếu Firebase Auth đã signOut
    }
  }
}

