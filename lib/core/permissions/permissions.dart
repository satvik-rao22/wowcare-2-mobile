/// Runtime permissions: import this one file.
///
/// - [PermissionManager] — check / request, no UI (cubits, repositories).
/// - [PermissionPrompt] — the full explain → ask → Settings flow (screens).
/// - [PermissionBuilder] — UI that greys itself out until granted.
library;

export 'app_permission.dart';
export 'permission_builder.dart';
export 'permission_manager.dart';
export 'permission_prompt.dart';
