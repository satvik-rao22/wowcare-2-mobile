import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';

/// Loading placeholder grid shown while a selection form's list is still
/// loading — shared by student_selection_transfer_form.dart and
/// student_selection_mark_absent_form.dart, was an identical private
/// `_buildShimmerGrid` method in both.
class AttendanceSelectionShimmerGrid extends StatelessWidget {
  const AttendanceSelectionShimmerGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 69,
      ),
      itemCount: 8,
      itemBuilder: (context, index) =>
          const ShimmerLoaderCard(child: SizedBox()),
    );
  }
}
