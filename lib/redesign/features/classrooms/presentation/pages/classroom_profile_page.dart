import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/offline_banner.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/core/widgets/text_link.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/classroom_profile_cubit.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/center_ratio_card.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/day_breakdown_card.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/movements_card.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/photo_well.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/places_card.dart';

/// 7f. The classroom's own record, reached by tapping the header card.
///
/// Everything on it is already returned somewhere: the capacity and age band
/// from the classroom, today's four counts from the attendance summary, the
/// booked moves from Movements, and the school's places and FTE from their
/// own two readings.
class ClassroomProfilePage extends StatelessWidget {
  const ClassroomProfilePage({required this.classroomId, super.key});

  final String classroomId;

  @override
  Widget build(BuildContext context) {
    final persona = context.read<SessionCubit>().state.persona;

    return BlocProvider<ClassroomProfileCubit>(
      create: (_) {
        final cubit = redesignLocator<ClassroomProfileCubit>(
          param1: classroomId,
          param2: persona,
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  /// The upload's progress, which the design fixes at 62% while it runs.
  static const double _uploadProgress = .62;
  static const String _fileName = 'sunflower-corner.jpg';

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClassroomProfileCubit>();

    return BlocBuilder<ClassroomProfileCubit, ClassroomProfileState>(
      builder: (context, state) => ScreenScaffold(
        header: AppHeaderBar(
          title: ClassroomsStrings.classroomProfile,
          isDetail: true,
          leading: const BackKey(),
          actions: <Widget>[
            if (state.profile != null)
              SecondaryKey(
                label: ClassroomsStrings.editClassroom,
                expand: false,
                padding: ClassroomsSizes.headerKeyPad,
                onTap: () => state.canEdit
                    ? showAppToast(context, AppStrings.comingSoon)
                    : showAppToast(
                        context,
                        ClassroomsStrings.viewOnlyToast,
                        tone: ToastTone.error,
                      ),
              ),
          ],
        ),
        bodyPadding: EdgeInsets.zero,
        body: _body(context, state, cubit),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    ClassroomProfileState state,
    ClassroomProfileCubit cubit,
  ) {
    if (state.isLoading) {
      return const LoadingState(label: ClassroomsStrings.loadingClassroom);
    }
    final profile = state.profile;
    if (profile == null || state.isFailed) {
      return Padding(
        padding: AppSizes.bodyPad,
        child: Center(
          child: ErrorState(
            title: ClassroomsStrings.couldNotReachTitle,
            message: ClassroomsStrings.couldNotReachBodyNoCache,
            onRetry: () => unawaited(cubit.load()),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      color: context.colours.pink,
      backgroundColor: context.colours.card,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenGutter,
          AppSizes.space1,
          AppSizes.screenGutter,
          AppSizes.screenBottomPad,
        ),
        children: <Widget>[
          if (state.isCached) ...<Widget>[
            const OfflineBanner(),
            const SizedBox(height: AppSizes.cardGap),
          ],
          _IdentityCard(
            profile: profile,
            uploadStatus: state.upload,
            fileName: state.pendingFileName ?? profile.photo?.fileName,
            canEdit: state.canEdit,
            onUpload: () => unawaited(cubit.uploadPhoto(_fileName)),
            onRemove: () => unawaited(cubit.removePhoto()),
            onRetry: () => unawaited(cubit.retryUpload()),
          ),
          const SizedBox(height: AppSizes.cardGap),
          PlacesCard(summary: profile.summary),
          const SizedBox(height: AppSizes.cardGap),
          DayBreakdownCard(
            title: ClassroomsStrings.studentsExpectedToday,
            breakdown: profile.students,
            isStaff: false,
          ),
          const SizedBox(height: AppSizes.cardGap),
          DayBreakdownCard(
            title: ClassroomsStrings.staffExpectedToday,
            breakdown: profile.staff,
            isStaff: true,
          ),
          const SizedBox(height: AppSizes.cardGap),
          MovementsCard(
            movements: profile.movements,
            arriving: profile.arrivingCount,
            leaving: profile.leavingCount,
          ),
          const SizedBox(height: AppSizes.cardGap),
          CenterRatioCard(center: profile.center),
        ],
      ),
    );
  }
}

/// Who the classroom is, and its photo.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.profile,
    required this.uploadStatus,
    required this.fileName,
    required this.canEdit,
    required this.onUpload,
    required this.onRemove,
    required this.onRetry,
  });

  final ClassroomProfile profile;
  final PhotoUploadStatus uploadStatus;
  final String? fileName;
  final bool canEdit;

  final VoidCallback onUpload;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final summary = profile.summary;

    return AppCard(
      padding: ClassroomsSizes.profileCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ClassroomsSizes.profileHeadGap,
        children: <Widget>[
          Row(
            spacing: ClassroomsSizes.profileHeadGap,
            children: <Widget>[
              SurfaceBox(
                surface: AppSurfaces.avatar(
                  c,
                  fill: c.studentBg,
                  size: ClassroomsSizes.profileAvatar,
                ),
                width: ClassroomsSizes.profileAvatar,
                height: ClassroomsSizes.profileAvatar,
                alignment: Alignment.center,
                child: Text(
                  summary.initial,
                  style: ClassroomsTextStyles.profileInitial.copyWith(
                    color: c.student,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: ClassroomsSizes.headTextGap,
                  children: <Widget>[
                    Text(
                      summary.name,
                      style: ClassroomsTextStyles.stateTitle.copyWith(
                        color: c.ink,
                      ),
                    ),
                    Row(
                      spacing: ClassroomsSizes.agePillGap,
                      children: <Widget>[
                        _Tag(label: summary.ageBand, isStaff: false),
                        if (summary.leadName != null)
                          Flexible(
                            child: _Tag(
                              label: ClassroomsStrings.leads(summary.leadName!),
                              isStaff: true,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(height: AppSizes.hairline, color: c.divider),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: ClassroomsSizes.sheetFieldGap,
            children: <Widget>[
              SectionEyebrow(
                label: ClassroomsStrings.classroomPhoto,
                trailing: canEdit && uploadStatus == PhotoUploadStatus.idle
                    ? Flexible(
                        child: TextLink(
                          label: ClassroomsStrings.startUpload,
                          onTap: onUpload,
                          style: ClassroomsTextStyles.uploadAction,
                        ),
                      )
                    : null,
              ),
              PhotoWell(
                status: uploadStatus,
                fileName: fileName,
                progress: _ProfileView._uploadProgress,
                onRemove: canEdit ? onRemove : null,
                onRetry: canEdit ? onRetry : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small tinted tag beside the classroom's name.
class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.isStaff});

  final String label;
  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final (fill, ink) = isStaff
        ? (c.staffBg, c.staffFg)
        : (c.studentBg, c.student);

    return Container(
      padding: ClassroomsSizes.agePillPad,
      decoration: AppSurfaces.pill(fill: fill).decoration,
      child: Text(
        label,
        style: ClassroomsTextStyles.smallPill.copyWith(color: ink),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
