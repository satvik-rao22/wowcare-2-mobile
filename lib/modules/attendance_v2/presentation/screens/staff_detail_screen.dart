import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';

import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';
import '../controllers/av2_period.dart';
import '../cubit/staff_detail_cubit.dart';
import '../cubit/staff_detail_state.dart';
import '../widgets/av2_detail_scaffold.dart';
import 'staff_detail_view.dart';

/// Entry point for the staff attendance & overtime detail. Given a [staffCode],
/// it loads the profile via [StaffDetailCubit] and renders loading / error /
/// loaded states inside the shared chrome.
class StaffDetailScreen extends StatefulWidget {
  const StaffDetailScreen({
    super.key,
    required this.staffCode,
    this.staffName = '',
  });

  final String staffCode;
  final String staffName;

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  late final StaffDetailCubit _cubit;
  late Av2Period _period;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _period = Av2Period.month(DateTime(now.year, now.month, 1));
    _cubit = serviceLocator<StaffDetailCubit>();
    _fetch();
  }

  void _fetch() {
    unawaited(
      _cubit.load(
        staffCode: widget.staffCode,
        staffName: widget.staffName,
        from: _period.start,
        to: _period.end,
      ),
    );
  }

  void _onPeriodChanged(Av2Period period) {
    setState(() => _period = period);
    _fetch();
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Av2DetailScaffold(
      onExport: () {},
      body: BlocBuilder<StaffDetailCubit, StaffDetailState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state.isError) {
            return _ErrorState(message: state.errorMessage, onRetry: _fetch);
          }
          if (state.isLoaded) {
            return StaffDetailView(
              profile: state.profile!,
              period: _period,
              loadDetail: _cubit.dayDetail,
              onPeriodChanged: _onPeriodChanged,
            );
          }
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(Av2Spacing.xl),
              child: CircularProgressIndicator(color: Av2Colors.theme),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Av2Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 34, color: Av2Colors.textTertiary),
            const SizedBox(height: Av2Spacing.sm),
            Text(
              message?.trim().isNotEmpty == true
                  ? message!
                  : 'Unable to load attendance data.',
              style: Av2Text.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Av2Spacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18, color: Av2Colors.theme),
              label: Text('Retry',
                  style: Av2Text.bodyMedium.copyWith(color: Av2Colors.theme)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Av2Colors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
