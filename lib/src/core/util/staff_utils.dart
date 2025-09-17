// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:schoolerp/core/extentions/context_extentions.dart';
// import 'package:schoolerp/features/user/data/model/StaffModel.dart';
// import 'package:schoolerp/features/user/presentation/cubit/staff_cubit.dart';

// class StaffUtils {
//   static Future<void> refreshCurrentStaff(BuildContext context) async {
//     final staff = await context
//         .read<StaffCubit>()
//         .getSingleStaff(id: context.currentStaff!.id);
//     final staffModel = StaffModel.fromMap((staff as StaffModel).toMap());
//     context.staffProviders.employee = staffModel;
//   }
// }
