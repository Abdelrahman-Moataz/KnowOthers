// lib/cubits/auth_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // ---------- EMAIL / PASSWORD ----------
  Future<void> signUp(String email, String password, String name) async {
    emit(AuthLoading());
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      await _saveUserProfile(cred.user!, name: name);
      emit(AuthSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Signup failed'));
    }
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      emit(AuthSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Sign-in failed'));
    }
  }

  // ---------- GOOGLE SIGN-IN ----------
  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        emit(AuthError('Google sign-in cancelled'));
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      await _saveUserProfile(
        userCred.user!,
        name: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
      );

      emit(AuthSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Google sign-in failed'));
    } catch (e) {
      emit(AuthError('Unexpected error: $e'));
    }
  }

  // ---------- COMMON PROFILE SAVE ----------
  Future<void> _saveUserProfile(User user,
      {String? name, String? photoUrl}) async {
    await _firestore.collection('users').doc(user.uid).set({
      'name': name ?? user.displayName ?? 'Anonymous',
      'email': user.email ?? '',
      'photoUrl': photoUrl ?? user.photoURL ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    emit(AuthInitial());
  }
}