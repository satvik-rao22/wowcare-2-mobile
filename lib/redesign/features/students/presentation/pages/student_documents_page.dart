import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/empty_state.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/students/cubit/student_documents_cubit.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/document_row.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/upload_document_card.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// 5f. A student's documents, and adding one.
///
/// Full screen from the Documents tab rather than a sheet, because an upload
/// outlives the moment: it has to survive a type being changed, a file being
/// re-chosen and a connection going, and a sheet is where that gets lost.
class StudentDocumentsPage extends StatelessWidget {
  const StudentDocumentsPage({required this.args, super.key});

  final StudentDocumentsArgs args;

  @override
  Widget build(BuildContext context) => BlocProvider<StudentDocumentsCubit>(
    create: (_) {
      final cubit = redesignLocator<StudentDocumentsCubit>(param1: args);
      unawaited(cubit.load());
      return cubit;
    },
    child: const _StudentDocumentsView(),
  );
}

class _StudentDocumentsView extends StatelessWidget {
  const _StudentDocumentsView();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<StudentDocumentsCubit, StudentDocumentsState>(
        builder: (context, state) => ScreenScaffold(
          header: _Header(state: state),
          bodyPadding: EdgeInsets.zero,
          body: _body(context, state),
        ),
      );

  Widget _body(BuildContext context, StudentDocumentsState state) {
    final cubit = context.read<StudentDocumentsCubit>();

    if (state.isLoading) return const LoadingState();
    if (state.isFailed) {
      return Center(
        child: ErrorState(
          message: StudentsStrings.loadError,
          onRetry: () => unawaited(cubit.load()),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      color: context.colours.pink,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: AppSizes.bodyPad,
        children: <Widget>[
          UploadDocumentCard(state: state),
          const SizedBox(height: AppSizes.cardGap),
          if (state.documents.isEmpty)
            const EmptyState(
              icon: AppIcons.fileText,
              title: StudentsStrings.noDocuments,
            )
          else ...<Widget>[
            SectionEyebrow(
              label: StudentsStrings.onFileEyebrow(state.documents.length),
            ),
            const SizedBox(height: AppSizes.sectionGap),
            for (final document in state.documents)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.cardGap),
                child: DocumentRow(
                  document: document,
                  onTap: () => showAppToast(context, StudentsStrings.viewSoon),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Back, the student's avatar, and what screen this is (5f).
class _Header extends StatelessWidget implements PreferredSizeWidget {
  const _Header({required this.state});

  final StudentDocumentsState state;

  @override
  Size get preferredSize =>
      const Size.fromHeight(AppSizes.avatar + AppSizes.space6);

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Padding(
      padding: StudentsSizes.profileHeaderPad,
      child: Row(
        spacing: StudentsSizes.profileHeaderGap,
        children: <Widget>[
          const BackKey(),
          AppAvatar(initials: state.initials),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSizes.rowTextGap,
              children: <Widget>[
                Text(
                  StudentsStrings.documentsTitle,
                  style: AppTextStyles.detailTitle.copyWith(color: c.ink),
                ),
                Text(
                  StudentsStrings.documentsSub(
                    state.studentName,
                    state.classroomName,
                  ),
                  style: AppTextStyles.rowSub.copyWith(color: c.ink3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
