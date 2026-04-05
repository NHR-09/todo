import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around Firebase Auth + Google Sign-In.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Current Firebase user (null if signed out).
  static User? get currentUser => _auth.currentUser;

  /// Whether user is currently signed in.
  static bool get isSignedIn => _auth.currentUser != null;

  /// Stream of auth state changes.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// User display name (fallback to email, then 'Hero').
  static String get displayName =>
      _auth.currentUser?.displayName ??
      _auth.currentUser?.email?.split('@').first ??
      'Hero';

  /// User photo URL.
  static String? get photoUrl => _auth.currentUser?.photoURL;

  /// User email.
  static String? get email => _auth.currentUser?.email;

  /// User UID.
  static String? get uid => _auth.currentUser?.uid;

  /// Sign in with Google.
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out from both Firebase and Google.
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
