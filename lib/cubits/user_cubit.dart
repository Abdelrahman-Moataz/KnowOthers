// lib/cubits/user_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';

part 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  UserCubit() : super(UserInitial());
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  // Removed unused _messaging

  Future<void> fetchAllUsers() async {
    emit(UserLoading());
    try {
      final snap = await _firestore.collection('users').get();
      final users = snap.docs.map((e) => {...e.data(), 'id': e.id}).toList();
      emit(UserLoaded(users));
    } catch (e) {
      emit(UserError('Failed to load users'));
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) return fetchAllUsers();
    emit(UserLoading());
    try {
      final snap = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      final users = snap.docs.map((e) => {...e.data(), 'id': e.id}).toList();
      emit(UserLoaded(users));
    } catch (e) {
      emit(UserError('Search failed'));
    }
  }

  Future<void> rateUser(String rateeId, Map<String, double> ratings) async {
    final raterId = _auth.currentUser!.uid;
    if (raterId == rateeId) {
      emit(UserError('Cannot rate yourself'));
      return;
    }
    emit(UserLoading());
    try {
      final batch = _firestore.batch();
      for (var e in ratings.entries) {
        final ref = _firestore.collection('ratings').doc('${raterId}_${e.key}');
        batch.set(ref, {
          'raterId': raterId,
          'rateeId': rateeId,
          'category': e.key,
          'score': e.value.toInt(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // === CORRECT FCM NOTIFICATION (via Cloud Function or Admin SDK) ===
      // You CANNOT send FCM from client directly like this.
      // Instead, save a "notification" document to trigger a Cloud Function.

      await _firestore.collection('notifications').add({
        'toUserId': rateeId,
        'fromUserId': raterId,
        'title': 'New Rating!',
        'body': 'You received a new rating!',
        'timestamp': FieldValue.serverTimestamp(),
      });

      emit(UserRated());
    } catch (e) {
      emit(UserError('Rating failed: $e'));
    }
  }

  Future<void> uploadProfilePic(XFile image) async {
    emit(UserLoading());
    try {
      final userId = _auth.currentUser!.uid;
      final ref = _storage.ref().child('profile_pics/$userId.jpg');
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'profilePic': url});
      emit(UserProfileUpdated(url));
    } catch (e) {
      emit(UserError('Upload failed: $e'));
    }
  }
}
