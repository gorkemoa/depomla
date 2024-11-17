import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  Future<User?> signInWithGoogle() async {
    try {
      // Google kullanıcıyı seçer
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // Kullanıcı oturumu iptal etti
        return null;
      }

      // Google kullanıcı kimlik doğrulama bilgilerini alır
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase için kimlik bilgilerini oluştur
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase'de oturum aç
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      print('Google Sign-In hatası: $e');
      rethrow;
    }
  }
}
