// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:schoolerp/core/util/core_utils.dart';
// import 'package:schoolerp/features/guardian/data/model/guardianDataModel.dart';
// import 'package:schoolerp/features/user/data/model/StaffModel.dart';
// import 'package:schoolerp/src/documents/presentation/bloc/document_bloc.dart';

// class ProfilePhotoProvider extends ChangeNotifier {
//   Uint8List? _profilePhoto;
//   bool _isLoading = false;
//   String? _error;
//   Uint8List? get profilePhoto => _profilePhoto;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   Future<void> loadProfilePhoto({
//     required DocumentBloc documentBloc,
//     required bool isStaff,
//     required StaffModel? staff,
//     required GuardianDataModel? guardian,
//     context,
//   }) async {
//     if (_profilePhoto != null) return;
//     try {
//       _isLoading = true;
//       _error = null;
//       notifyListeners();
//       documentBloc.add(DownloadDocument({
//         'refTable.equals': '${isStaff ? 'Staff' : 'Guardian'}',
//         'refTableId.equals': '${isStaff ? staff!.id : guardian!.id}',
//         'docType.equals': 'PROFILE',
//         'status.equals': 'A'
//       }));
//       await for (final state in documentBloc.stream) {
//         if (state is DownloadingDocument) {
//           _isLoading = true;
//         } else if (state is DocumentDownloaded) {
//           _profilePhoto = state.fileData;
//           _isLoading = false;
//           notifyListeners();
//           return;
//         } else if (state is DocumentDownloadError) {
//           _isLoading = false;
//           CoreUtils.showTopSnackBar(
//             context: context,
//             isError: true,
//             isWarning: false,
//             isSuccess: false,
//             isAdjust: false,
//             message: 'Error Loading Profile Photo',
//           );
//           notifyListeners();
//           return;
//         }
//       }
//     } catch (e) {
//       _error = 'Failed to load profile photo: $e';
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   void setProfilePhoto(Uint8List photo, BuildContext context) {
//     _profilePhoto = photo;
//     _error = null;
//     if (context.mounted) {
//       precacheImage(MemoryImage(photo), context);
//     }
//     notifyListeners();
//   }

//   void updateProfilePhoto(Uint8List photo, BuildContext context) {
//   setProfilePhoto(photo, context);
// }

//   void clearPhoto() {
//     _profilePhoto = null;
//     _error = null;
//     notifyListeners();
//   }
// }
