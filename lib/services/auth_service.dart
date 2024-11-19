// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı durum değişikliklerini dinle
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  // Mevcut kullanıcıyı al
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
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
        UserModel newUser = UserModel(
          uid: user!.uid,
          email: user.email!,
          displayName: displayName,
          photoURL: user.photoURL ?? '',
          lastSignIn: FieldValue.serverTimestamp() as Timestamp?,
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      }

      return user;
    } on FirebaseAuthException catch (e) {
      // Hata yönetimi
      print('FirebaseAuthException: ${e.message}');
      rethrow;
    } catch (e) {
      // Genel hata yönetimi
      print('Exception: $e');
      rethrow;
    }
  }

  // E-posta ve Şifre ile Giriş Yapma
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;

      if (user != null) {
        // Firestore'da lastSignIn güncelle
        await _firestore.collection('users').doc(user.uid).update({
          'lastSignIn': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      // Hata yönetimi
      print('FirebaseAuthException: ${e.message}');
      rethrow;
    } catch (e) {
      // Genel hata yönetimi
      print('Exception: $e');
      rethrow;
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
        DocumentSnapshot<Map<String, dynamic>> userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          UserModel newUser = UserModel(
            uid: user.uid,
            email: user.email!,
            displayName: user.displayName ?? '',
            photoURL: user.photoURL ?? '',
            lastSignIn: FieldValue.serverTimestamp() as Timestamp?,
          );

          await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        } else {
          // Mevcut kullanıcının lastSignIn alanını güncelle
          await _firestore.collection('users').doc(user.uid).update({
            'lastSignIn': FieldValue.serverTimestamp(),
          });
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      // Hata yönetimi
      print('FirebaseAuthException: ${e.message}');
      rethrow;
    } catch (e) {
      // Genel hata yönetimi
      print('Exception: $e');
      rethrow;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut(); // Google hesabını temizle
      await _auth.signOut(); // Firebase oturumunu kapat
      print('Kullanıcı çıkış yaptı.');
    } catch (e) {
      print('Çıkış işlemi sırasında bir hata oluştu: $e');
      rethrow;
    }
  }

  // Firestore'da lastSignIn güncelleme
  Future<void> updateLastSignIn(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastSignIn': FieldValue.serverTimestamp(),
      });
      print('lastSignIn güncellendi.');
    } catch (e) {
      print('lastSignIn güncellenirken hata: $e');
      rethrow;
    }
  }
}