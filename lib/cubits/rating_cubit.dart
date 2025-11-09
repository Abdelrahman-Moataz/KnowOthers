import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'rating_state.dart';

class RatingCubit extends Cubit<RatingState> {
  RatingCubit() : super(RatingInitial());
  final _firestore = FirebaseFirestore.instance;

  Future<void> fetchAverages() async {
    emit(RatingLoading());
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final snap = await _firestore.collection('ratings').where('rateeId', isEqualTo: userId).get();

      final Map<String, List<int>> scores = {};
      for (var doc in snap.docs) {
        final data = doc.data();
        final cat = data['category'] as String;
        final score = data['score'] as int;
        scores.putIfAbsent(cat, () => []).add(score);
      }

      final averages = scores.entries.map((e) {
        final avg = e.value.reduce((a, b) => a + b) / e.value.length;
        return {'category': e.key, 'average': avg};
      }).toList();

      emit(RatingLoaded(averages));
    } catch (e) {
      emit(RatingError('Failed to load ratings'));
    }
  }
}