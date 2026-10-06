import 'package:flutter/widgets.dart';

import 'app_permission.dart';
import 'permission_manager.dart';

/// Rebuilds with the live status of [permission] — for UI that should look
/// disabled until a permission is granted, without blocking the whole screen.
///
/// Re-checks when the app returns to the foreground (the user may have just
/// changed it in Settings) and after any `PermissionManager.request`, so the
/// UI turns itself back on with no extra code at the call site.
///
/// ```dart
/// PermissionBuilder(
///   permission: AppPermission.camera,
///   builder: (context, status) {
///     final allowed = status?.isGranted ?? false;
///     return Opacity(
///       opacity: allowed ? 1 : 0.5, // looks disabled…
///       child: ListTile(
///         title: const Text('Scan QR code'),
///         // …but stays tappable, to explain why and offer the fix.
///         onTap: allowed
///             ? openScanner
///             : () => PermissionPrompt.ensure(context, AppPermission.camera),
///       ),
///     );
///   },
/// )
/// ```
///
/// Don't disable the control outright (`enabled: false`, `onTap: null`): a
/// dead tap gives the user no way to find out what's wrong.
class PermissionBuilder extends StatefulWidget {
  const PermissionBuilder({
    required this.permission,
    required this.builder,
    super.key,
  });

  final AppPermission permission;

  /// `status` is null only during the first check, which takes a few ms.
  final Widget Function(BuildContext context, AppPermissionStatus? status)
  builder;

  @override
  State<PermissionBuilder> createState() => _PermissionBuilderState();
}

class _PermissionBuilderState extends State<PermissionBuilder> {
  AppPermissionStatus? _status;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    PermissionManager.changes.addListener(_refresh);
    _refresh();
  }

  @override
  void didUpdateWidget(PermissionBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.permission != widget.permission) _refresh();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    PermissionManager.changes.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    final permission = widget.permission;
    final status = await PermissionManager.status(permission);
    // Drop a stale answer if the widget moved on while we were waiting.
    if (!mounted || permission != widget.permission || status == _status) {
      return;
    }
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _status);
}
