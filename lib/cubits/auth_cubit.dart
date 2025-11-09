import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      emit(AuthError('Fill all fields'));
      return;
    }
    emit(AuthLoading());
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
      emit(AuthSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Sign in failed'));
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      emit(AuthError('All fields required'));
      return;
    }
    emit(AuthLoading());
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password.trim());
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'profilePic': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      emit(AuthSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Signup failed'));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        emit(AuthError('Cancelled'));
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);
      await _firestore.collection('users').doc(userCred.user!.uid).set({
        'name': googleUser.displayName,
        'email': googleUser.email,
        'profilePic': googleUser.photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      emit(AuthSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Google sign-in failed'));
    }
  }

  Future<void> resetPassword(String email) async {
    if (email.isEmpty) {
      emit(AuthError('Email required'));
      return;
    }
    emit(AuthLoading());
    try {
      await _auth.sendPasswordResetEmail(email: email.trim()); // FIXED
      emit(AuthSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Reset failed'));
    }
  }

  Future<void> updatePassword(String newPassword) async {
    if (newPassword.isEmpty) {
      emit(AuthError('Password required'));
      return;
    }
    emit(AuthLoading());
    try {
      await _auth.currentUser!.updatePassword(newPassword.trim());
      emit(AuthSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Update failed'));
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    await _auth.signOut();
    emit(AuthInitial());
  }
}