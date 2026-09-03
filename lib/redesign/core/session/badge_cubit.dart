import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The two unread counts the chrome shows: the Messages slot on the tab bar
/// and the bell in the dashboard header. M09 and M12 own the numbers; the
/// shell only draws them.
class BadgeCubit extends Cubit<BadgeState> {
  BadgeCubit({BadgeState initial = const BadgeState()}) : super(initial);

  void setMessages(int count) => emit(state.copyWith(messages: count));
  void setNotifications(int count) =>
      emit(state.copyWith(notifications: count));
  void clearNotifications() => emit(state.copyWith(notifications: 0));
}

@immutable
class BadgeState extends Equatable {
  const BadgeState({this.messages = 0, this.notifications = 0});

  final int messages;
  final int notifications;

  BadgeState copyWith({int? messages, int? notifications}) => BadgeState(
    messages: messages ?? this.messages,
    notifications: notifications ?? this.notifications,
  );

  @override
  List<Object?> get props => [messages, notifications];
}
