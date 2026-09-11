import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/communication/usecases/toggle_private_mode_usecase.dart';
import 'package:wowcare/presentation/features/communication/view_model/private_mode_toggle_cubit.dart';
import 'package:wowcare/domain/features/communication/policies/room_chat_privacy_helper.dart';

/// DI wiring for [PrivateModeToggleCubit], kept OUT of the presentation layer
/// (Mandate 5: views reference no `serviceLocator`).
///
/// This cubit depends on screen-resolved state ([viewerRole]/[currentUserCode]
/// are read lazily from the screen), so it can't move to a route builder — the
/// screen still constructs and owns it, but via this builder so the
/// `serviceLocator` call for [TogglePrivateModeUseCase]'s repository lives in
/// the app DI layer. Same construction, same behaviour.
PrivateModeToggleCubit buildPrivateModeToggleCubit({
  required String conversationCode,
  required RoomChatViewerRole Function() viewerRole,
  required String Function() currentUserCode,
}) {
  return PrivateModeToggleCubit(
    togglePrivateModeUseCase: TogglePrivateModeUseCase(serviceLocator()),
    conversationCode: conversationCode,
    viewerRole: viewerRole,
    currentUserCode: currentUserCode,
  );
}
