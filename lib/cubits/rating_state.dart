part of 'rating_cubit.dart';

abstract class RatingState {}

class RatingInitial extends RatingState {}

class RatingLoading extends RatingState {}

class RatingLoaded extends RatingState {
  final List<dynamic> averages;
  RatingLoaded(this.averages);
}

class RatingError extends RatingState {
  final String message;
  RatingError(this.message);
}