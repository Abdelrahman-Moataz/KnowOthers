part of 'user_cubit.dart';

abstract class UserState {}

class UserInitial extends UserState {}
class UserLoading extends UserState {}
class UserLoaded extends UserState {
  final List<dynamic> users;
  UserLoaded(this.users);
}
class UserRated extends UserState {}
class UserProfileUpdated extends UserState {
  final String profilePicUrl;
  UserProfileUpdated(this.profilePicUrl);
}
class UserError extends UserState {
  final String message;
  UserError(this.message);
}