import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut(); // Google hesabını temizle
      await _auth.signOut(); // Firebase oturumunu kapat
      print('Kullanıcı çıkış yaptı.');
    } catch (e) {
      print('Çıkış işlemi sırasında bir hata oluştu: $e');
    }
  }

  // Kullanıcı durum değişikliklerini dinle
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  // Mevcut kullanıcıyı al
  Future<User?> getCurrentUser() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        print('Kullanıcı giriş yapmış: ${user.uid}');
        return user; // Kullanıcı objesini döner
      } else {
        print('Kullanıcı giriş yapmamış.');
        return null; // Giriş yapmamış kullanıcı
      }
    } catch (e) {
      print('Mevcut kullanıcı bilgisi alınırken hata oluştu: $e');
      return null;
    }
  }

  // Kullanıcıyı Firestore'dan getir (Opsiyonel)
  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        print('Kullanıcı Firestore\'dan alındı: ${doc.data()}');
        return doc;
      } else {
        print('Kullanıcı Firestore\'da bulunamadı.');
        return null;
      }
    } catch (e) {
      print('Firestore\'dan kullanıcı alınırken hata oluştu: $e');
      return null;
    }
  }
    
  
 Future<void> updateLastSignIn(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastSignIn': FieldValue.serverTimestamp(),
      });
      print('lastSignIn güncellendi.');
    } catch (e) {
      print('lastSignIn güncellenirken hata: $e');
    }
  }

  // E-posta ve Şifre ile Kayıt Olma
  Future<User?> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;

      if (user != null) {
        // Kullanıcı adı güncelleme
        await user.updateDisplayName(displayName);
        await user.reload();
        user = _auth.currentUser;

        // Firestore'a kullanıcı ekleme
        await _firestore.collection('users').doc(user!.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      // Hata yönetimi
      print('FirebaseAuthException: ${e.message}');
      return null;
    } catch (e) {
      // Genel hata yönetimi
      print('Exception: $e');
      return null;
    }
  }

  // Google ile Giriş Yapma
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // Kullanıcı Google girişini iptal etti
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Firestore'da kullanıcı mevcut değilse ekle
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName ?? '',
            'photoURL': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // lastSignIn güncelleme
        await updateLastSignIn(user.uid);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      // Hata yönetimi
      print('FirebaseAuthException: ${e.message}');
      return null;
    } catch (e) {
      // Genel hata yönetimi
      print('Exception: $e');
      return null;
    }
  }

  // Diğer Auth metodları...
}
