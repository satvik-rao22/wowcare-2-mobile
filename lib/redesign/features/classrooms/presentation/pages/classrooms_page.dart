import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_chip.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/chip_row.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/offline_banner.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/search_field.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/classrooms_cubit.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/pages/classroom_page.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/classroom_card.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/classroom_state_view.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/dashed_panel.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/extended_fab.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/school_impact_card.dart';

/// M07's branch root.
///
/// An Admin gets the floor (7a), or the empty floor (7b). **A teacher never
/// sees this list**: the Classrooms slot opens their own classroom (7e),
/// which is the only one they work in.
class ClassroomsPage extends StatelessWidget {
  const ClassroomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCubit>().state;
    final own = session.user?.classroomName;

    if (session.persona == Persona.staff && own != null) {
      return ClassroomPage(classroomId: classroomIdFor(own), isOwn: true);
    }

    return BlocProvider<ClassroomsCubit>(
      create: (_) {
        final cubit = redesignLocator<ClassroomsCubit>();
        unawaited(cubit.load());
        return cubit;
      },
      child: const _ClassroomsView(),
    );
  }
}

/// The demo world keys a classroom by its lowercase name. Phase 5 carries the
/// real `CLS_*` code on the session instead, and this goes with it.
String classroomIdFor(String classroomName) => classroomName.toLowerCase();

class _ClassroomsView extends StatefulWidget {
  const _ClassroomsView();

  @override
  State<_ClassroomsView> createState() => _ClassroomsViewState();
}

class _ClassroomsViewState extends State<_ClassroomsView> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  ClassroomsCubit get _cubit => context.read<ClassroomsCubit>();

  void _open(ClassroomSummary classroom) =>
      unawaited(context.push(AppRoutes.classroom(classroom.id)));

  void _create() => unawaited(context.push(AppRoutes.addClassroom));

  void _refused() => showAppToast(
    context,
    ClassroomsStrings.viewOnlyToast,
    tone: ToastTone.error,
  );

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<SessionCubit, bool>(
      (cubit) => cubit.state.persona == Persona.admin,
    );

    return BlocBuilder<ClassroomsCubit, ClassroomsState>(
      builder: (context, state) => ScreenScaffold(
        header: AppHeaderBar(
          title: ClassroomsStrings.title,
          actions: <Widget>[_DateLabel(date: state.board.date)],
        ),
        bodyPadding: EdgeInsets.zero,
        fab: state.hasNoClassrooms
            ? null
            : ExtendedFab(
                label: ClassroomsStrings.createClassroom,
                isDead: !isAdmin,
                onTap: isAdmin ? _create : null,
              ),
        body: _body(context, state, isAdmin: isAdmin),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    ClassroomsState state, {
    required bool isAdmin,
  }) {
    if (state.isLoading) {
      return const LoadingState(label: ClassroomsStrings.loadingClassrooms);
    }
    if (state.isFailed) {
      return Padding(
        padding: AppSizes.bodyPad,
        child: Center(
          child: ErrorState(
            title: ClassroomsStrings.couldNotReachListTitle,
            message: ClassroomsStrings.couldNotReachBodyNoCache,
            onRetry: () => unawaited(_cubit.load()),
          ),
        ),
      );
    }

    if (state.hasNoClassrooms) {
      return Padding(
        padding: AppSizes.bodyPad,
        child: _EmptyFloor(onCreate: isAdmin ? _create : _refused),
      );
    }

    return RefreshIndicator(
      onRefresh: _cubit.refresh,
      color: context.colours.pink,
      backgroundColor: context.colours.card,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(
          top: AppSizes.screenTopPad,
          bottom: AppSizes.screenBottomPad,
        ),
        children: <Widget>[
          if (state.isCached) _gutter(_offlineBanner(state)),
          _gutter(SchoolImpactCard(board: state.board)),
          const SizedBox(height: AppSizes.cardGap),
          _gutter(
            SearchField(
              controller: _search,
              hintText: ClassroomsStrings.searchClassrooms,
              onChanged: _cubit.search,
              onClear: _cubit.clearSearch,
            ),
          ),
          const SizedBox(height: AppSizes.cardGap),
          _segments(state),
          const SizedBox(height: AppSizes.cardGap),
          if (state.hasNoMatches)
            _gutter(_noMatches(state))
          else
            for (final classroom in state.visible)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSizes.screenGutter,
                  right: AppSizes.screenGutter,
                  bottom: AppSizes.cardGap,
                ),
                child: ClassroomCard(
                  classroom: classroom,
                  onTap: () => _open(classroom),
                ),
              ),
        ],
      ),
    );
  }

  /// What is on screen is what was last reached, and the strip says when.
  Widget _offlineBanner(ClassroomsState state) {
    final at = state.board.date;
    return at == null
        ? const OfflineBanner()
        : OfflineBanner(
            message: ClassroomsStrings.offlineAsOf(
              ClassroomsStrings.timeOfDay(at),
            ),
          );
  }

  Widget _segments(ClassroomsState state) => ChipRow(
    children: <Widget>[
      for (final segment in ClassroomSegment.values)
        AppChip(
          label: _segmentLabel(segment),
          count: '${state.board.countFor(segment)}',
          selected: state.segment == segment,
          onTap: () => _cubit.selectSegment(segment),
        ),
    ],
  );

  Widget _noMatches(ClassroomsState state) {
    if (state.isSearching) {
      return DashedPanel(
        title: ClassroomsStrings.noClassroomMatches(state.query.trim()),
        message: ClassroomsStrings.noEmptyClassrooms,
      );
    }
    return DashedPanel(
      title: ClassroomsStrings.everyClassroomCovered,
      message: state.segment == ClassroomSegment.overRatio
          ? ClassroomsStrings.noClassroomOver
          : ClassroomsStrings.noEmptyClassrooms,
    );
  }

  static Widget _gutter(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenGutter),
    child: child,
  );

  static String _segmentLabel(ClassroomSegment segment) => switch (segment) {
    ClassroomSegment.all => ClassroomsStrings.chipAll,
    ClassroomSegment.overRatio => ClassroomsStrings.chipOverRatio,
    ClassroomSegment.empty => ClassroomsStrings.chipEmpty,
  };
}

/// Today's date, at the end of the header bar.
class _DateLabel extends StatelessWidget {
  const _DateLabel({required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) => Text(
    date == null ? '' : ClassroomsStrings.headerDate(date!),
    style: AppTextStyles.subLine.copyWith(
      color: context.colours.ink3,
      fontWeight: FontWeight.w700,
    ),
  );
}

/// 7b. Nothing has been set up yet, and the one key here makes the first one.
class _EmptyFloor extends StatelessWidget {
  const _EmptyFloor({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: ClassroomsSizes.bigEmptyGap,
        children: <Widget>[
          ClassroomStateView(
            icon: AppIcons.classrooms,
            title: ClassroomsStrings.noClassroomsTitle,
            message: ClassroomsStrings.noClassroomsBody,
            primaryLabel: ClassroomsStrings.createClassroom,
            onPrimary: onCreate,
            iconSize: ClassroomsSizes.bigEmptyIcon,
            glyphSize: ClassroomsSizes.bigEmptyGlyph,
          ),
          Text(
            ClassroomsStrings.noClassroomsHint,
            style: ClassroomsTextStyles.stateHint.copyWith(color: c.ink3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
