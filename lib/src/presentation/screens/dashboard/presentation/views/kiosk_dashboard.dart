// import 'dart:convert';
// import 'dart:io' show Platform;

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:schoolerp/core/common/app/providers/auth_providers.dart';
// import 'package:schoolerp/core/common/widgets/gradient_background.dart';
// import 'package:schoolerp/core/extentions/context_extentions.dart';
// import 'package:schoolerp/core/res/colors.dart';
// import 'package:schoolerp/core/util/core_utils.dart';
// import 'package:schoolerp/features/student/domain/entities/studentData.dart';
// import 'package:schoolerp/src/attendance/presentation/views/forms/staff_attendance_forms/staff_sign_in_form.dart';
// import 'package:schoolerp/src/attendance/presentation/views/forms/staff_attendance_forms/staff_sign_out_form.dart';
// import 'package:schoolerp/src/attendance/presentation/views/forms/student_attendance_forms/student_signIn_out_button.dart';
// import 'package:schoolerp/src/attendance/presentation/views/forms/student_attendance_forms/student_sign_in_form.dart';
// import 'package:schoolerp/src/attendance/presentation/views/forms/student_attendance_forms/student_sign_out_form.dart';
// import 'package:schoolerp/src/auth/presentation/views/auth_screen.dart';
// import 'package:schoolerp/src/documents/domain/entity/validate_user.dart';
// import 'package:schoolerp/src/documents/presentation/bloc/document_bloc.dart';

// class KioskDashboard extends StatefulWidget {
//   const KioskDashboard({super.key});

//   static const String routeName = '/kiosk-dashboard';

//   @override
//   State<KioskDashboard> createState() => _KioskDashboardState();
// }

// class _KioskDashboardState extends State<KioskDashboard> {
//   String pin = '';
//   final int maxPinLength = 6; // Changed from 4 to 6 digits
//   bool _isLoading = false;

//   void addDigit(String digit) {
//     if (pin.length < maxPinLength) {
//       setState(() {
//         pin += digit;
//       });
//     }
//   }

//   void removeDigit() {
//     if (pin.isNotEmpty) {
//       setState(() {
//         pin = pin.substring(0, pin.length - 1);
//       });
//     }
//   }

//   bool isIpad() {
//     // Simple check for iPad (iOS and larger screen)
//     return Platform.isIOS && (MediaQuery.of(context).size.shortestSide >= 600);
//   }

//   bool isAndroid() {
//     return Platform.isAndroid;
//   }

//   void _validateKioskPin() {
//     // Check if PIN is exactly 6 digits
//     if (pin.length == maxPinLength) {
//       setState(() {
//         _isLoading = true; // Show loading indicator
//       });

//       debugPrint('PIN IS $pin');

//       // Send the actual PIN value instead of the string 'pin'
//       context.read<DocumentBloc>().add(ValidateKioskPin(pin, true));

//       _resetPin();
//       // Note: You'll need to listen for the response in a BlocListener
//       // or handle the state changes in your build method
//     } else {
//       _resetPin();
//       // Show a snackbar if PIN is not 6 digits
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please enter a 6-digit PIN'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//     }
//   }

//   void _resetPin() {
//     setState(() {
//       pin = '';
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isTablet = isIpad();

//     return BlocListener<DocumentBloc, DocumentState>(
//       listener: (context, state) {
//         // Handle the response from ValidateKioskPin event
//         if (state is ValidatingKioskPin) {
//           setState(() {
//             _isLoading = true;
//           });
//         } else {
//           setState(() {
//             _isLoading = false;
//           });

//           // Check if PIN validation returned a SecurityUser
//           if (state is KioskValidated) {
//             debugPrint('kioskPinValidated');

//             UserResponse userResponse = state.securityUser;

//             String userType = userResponse.userType;
//             debugPrint('userType: $userType');

//             if (userType == 'Guardian') {
//               debugPrint('userType == Guardian');

//               List<StudentEntity> students = [];

//               userResponse.guardian!.students.forEach((studentModel) {
//                 // Convert StudentModel to StudentEntity
//                 final studentEntity = StudentEntity(
//                   id: studentModel.id,
//                   fullName: studentModel.fullName,
//                   photoUuid: studentModel.photoUuid,
//                   gender: studentModel.gender,
//                   bloodGroup: studentModel.bloodGroup,
//                   studentUniqueId: studentModel.studentUniqueId,
//                   dateOfBirth: studentModel.dateOfBirth,
//                   isSignedIn: studentModel.isSignedIn, // Assuming default value
//                   isAbsent: studentModel.isAbsent, // Assuming default value
//                   isExpectedToday:
//                       studentModel.isExpectedToday, // Assuming default value
//                   isPresentToday: false,
//                   napStartOrEnd:'',
//                   movementDate:
//                       studentModel.movementDate, // Assuming default value
//                   studentFte: studentModel.studentFte, // Assuming default value
//                   foodProgram: studentModel.foodProgram,
//                   isPhotoPermission: false, // Assuming default value
//                   registrationDate: studentModel.registrationDate,
//                   leavingDate: studentModel.leavingDate,
//                   roomStartDate: studentModel.roomStartDate,
//                   profileStatus: studentModel.profileStatus,
//                   allergies: studentModel.allergies,
//                   medications: studentModel.medications,
//                   dietRestriction: studentModel.dietRestriction,
//                   note: studentModel.note,
//                   roomId: studentModel.roomId,
//                   status: studentModel.status,
//                   schoolId: studentModel.schoolId,
//                   lastModified: studentModel.lastModified,
//                   lastModifiedBy: studentModel.lastModifiedBy,
//                   hasPrivateChat: studentModel.hasPrivateChat,
//                   isTagRemoved: studentModel.isTagRemoved,
//                   privatedByGuardian: studentModel.privatedByGuardian,
//                   subsidyInvoiced: studentModel.subsidyInvoiced,
//                   subsidyBalance: studentModel.subsidyBalance,
//                   subsidyReceived: studentModel.subsidyReceived,
//                   childCustody: studentModel.childCustody,
//                   startDate: studentModel.startDate,
//                   expectedMoveDate: studentModel.expectedMoveDate,
//                   isStateSubsidyAllowed: studentModel.isStateSubsidyAllowed,
//                   tags: [], // Assuming tags are compatible
//                   siblings:
//                       studentModel.siblings, // Assuming siblings are compatible
//                   activities: [], // Assuming activities are compatible
//                   schedule:
//                       studentModel.schedule, // Assuming schedule is compatible
//                   transactions: studentModel
//                       .transactions, // Assuming transactions are compatible
//                   programRoom: studentModel.programRoom,
//                   openBalance: studentModel.openBalance,
//                   roomName: studentModel.roomName,
//                   invoice:
//                       studentModel.invoice, // Assuming invoice is compatible
//                   students:
//                       studentModel.students, // Assuming students is compatible
//                   recurringPlan: studentModel
//                       .recurringPlan, // Assuming recurringPlan is compatible
//                 );

//                 // Add the converted StudentEntity to currentStudents
//                 students.add(studentEntity);
//               });

//               // Check if all students are signed in
//               bool allSignedIn =
//                   students.every((student) => student.isSignedIn == true);

//               // Check if all students are signed out
//               bool allSignedOut =
//                   students.every((student) => student.isSignedIn == false);

//               if (allSignedIn) {
//                 // If all students are signed in, go to sign out form
//                 Navigator.of(context).pushNamed(
//                   StudentSignOutForm.routeName,
//                   arguments: students,
//                 );
//               } else if (allSignedOut) {
//                 // If all students are signed out, go to sign in form
//                 Navigator.of(context).pushNamed(
//                   StudentSignInForm.routeName,
//                   arguments: students,
//                 );
//               } else {
//                 // If mixed status (some in, some out), go to combined form
//                 Navigator.of(context).pushNamed(
//                   StudentSignInOutButton.routeName,
//                   arguments: students,
//                 );
//               }

//               // Reset PIN after navigation
//               setState(() {
//                 pin = '';
//               });
//             } else if (userType == 'Staff') {
//               debugPrint('userType == Staff');

//               if (userResponse.staff!.isSignedIn) {
//                 Navigator.of(context).pushNamed(
//                   StaffSignOutForm.routeName,
//                   arguments: userResponse.staff,
//                 );
//               } else {
//                 Navigator.of(context).pushNamed(
//                   StaffSignInForm.routeName,
//                   arguments: userResponse.staff,
//                 );
//               }
//             }

//             CoreUtils.showTopSnackBar(
//                 context: context,
//                 isAdjust: false,
//                 isError: false,
//                 isSuccess: true,
//                 isWarning: false,
//                 message: "Pin is Validated",
//                 duration: const Duration(seconds: 2));
//           } else if (state is ScannerError) {
//             // Show error message
//             CoreUtils.showTopSnackBar(
//                 context: context,
//                 isAdjust: false,
//                 isError: true,
//                 isSuccess: false,
//                 isWarning: false,
//                 message: "Pin is Invalid",
//                 duration: const Duration(seconds: 2));
//           }
//         }
//       },
//       child: Scaffold(
//         body: GradientBackground(
//           child: Center(
//             child: SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                     vertical: 20.0, horizontal: 16.0),
//                 child: isTablet ? _buildTabletLayout(context) : _buildPhoneLayout(),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPhoneLayout() {
//     // Android/phone layout - Vertical arrangement
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         const SizedBox(height: 20),
//         Text(
//           AuthProvider.userSchool.name,
//           style: TextStyle(
//             fontSize: 28,
//             fontWeight: FontWeight.w500,
//             color: Colors.blue[300],
//           ),
//         ),
//         const SizedBox(height: 10),
//         const Text(
//           'Scan the QR Code',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(height: 20),
//         if (isAndroid())
//           Container(
//             height: context.height / 3,
//             width: context.width * 0.75,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border.all(color: Colors.black, width: 2),
//             ),
//             child: !AuthProvider.userSchool.isWebScanner
//                 ? (AuthProvider.userSchool.base64QRCode.isNotEmpty
//                     ? Image.memory(
//                         base64Decode(AuthProvider.userSchool.base64QRCode),
//                         fit: BoxFit.cover,
//                       )
//                     : const Center(
//                         child: Text(
//                           'Please generate QR from Web app first',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color: Colors.black,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ))
//                 : const Center(
//                     child: Text(
//                       'Please generate QR from Web app first',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: Colors.black,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//           ),
//         const SizedBox(height: 30),
//         const Text(
//           'Enter your Sign-In/out Pin',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(height: 20),
//         // PIN dots - updated for 6 digits
//         _buildPinDots(),
//         const SizedBox(height: 30),
//         // Keypad - vertical arrangement
//         _buildKeypad(),
//         const SizedBox(height: 30),
//         // Bottom buttons
//         Row(
//           children: [
//             Expanded(
//                 child: Container(
//               height: 48,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(8),
//                 gradient: AppColors.buildSecondaryGradient(),
//               ),
//               padding: const EdgeInsets.all(1),
//               child: TextButton(
//                 onPressed: () {
//                   Navigator.pushReplacementNamed(context, AuthScreen.routName);
//                 },
//                 style: TextButton.styleFrom(
//                   backgroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 10),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: ShaderMask(
//                   shaderCallback: (Rect bounds) =>
//                       AppColors.buildSecondaryGradient().createShader(bounds),
//                   blendMode: BlendMode.srcIn,
//                   child: const Text(
//                     'Cancel',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w700,
//                       letterSpacing: 16 * (-3 / 100),
//                     ),
//                   ),
//                 ),
//               ),
//             )),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(8),
//                   gradient: AppColors.buildSecondaryGradient(),
//                 ),
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.transparent,
//                     padding: const EdgeInsets.symmetric(vertical: 10),
//                     shadowColor: Colors.transparent,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   onPressed: () {
//                     _validateKioskPin();
//                   },
//                   child: _isLoading
//                       ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor:
//                                 AlwaysStoppedAnimation<Color>(Colors.white),
//                           ),
//                         )
//                       : const Text(
//                           'Next',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w700,
//                             letterSpacing: 16 * (-3 / 100),
//                           ),
//                         ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildTabletLayout(BuildContext context) {
//     final isLandscape =
//         MediaQuery.of(context).orientation == Orientation.landscape;
//     final qrSize = isLandscape ? context.height / 3 : context.width * 0.3;

//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         // Left side - QR Code and title
//         Expanded(
//           flex: 1,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Text(
//                 AuthProvider.userSchool.name,
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.blue[300],
//                 ),
//               ),
//               const SizedBox(height: 10),
//               const Text(
//                 'Scan the QR Code',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Container(
//                 height: qrSize,
//                 width: qrSize,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   border: Border.all(color: Colors.black, width: 2),
//                 ),
//                 child: !AuthProvider.userSchool.isWebScanner
//                     ? (AuthProvider.userSchool.base64QRCode.isNotEmpty
//                         ? Image.memory(
//                             base64Decode(AuthProvider.userSchool.base64QRCode),
//                             fit: BoxFit.cover,
//                           )
//                         : const Center(
//                             child: Text(
//                               'Please generate QR from Web app first',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ))
//                     : const Center(
//                         child: Text(
//                           'Please generate QR from Web app first',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color: Colors.black,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//               ),
//             ],
//           ),
//         ),

//         // Right side - PIN entry
//         Expanded(
//           flex: 1,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const Text(
//                 'Enter your Sign-In/out Pin',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               // PIN dots - updated for 6 digits
//               _buildPinDots(),
//               const SizedBox(height: 30),
//               // Keypad
//               _buildKeypad(),
//               const SizedBox(height: 30),
//               // Bottom buttons
//               Row(
//                 children: [
//                   Expanded(
//                       child: Container(
//                     height: 48,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(8),
//                       gradient: AppColors.buildSecondaryGradient(),
//                     ),
//                     padding: const EdgeInsets.all(1),
//                     child: TextButton(
//                       onPressed: () {
//                         Navigator.pushReplacementNamed(
//                             context, AuthScreen.routName);
//                       },
//                       style: TextButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 10),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: ShaderMask(
//                         shaderCallback: (Rect bounds) =>
//                             AppColors.buildSecondaryGradient()
//                                 .createShader(bounds),
//                         blendMode: BlendMode.srcIn,
//                         child: const Text(
//                           'Cancel',
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w700,
//                             letterSpacing: 16 * (-3 / 100),
//                           ),
//                         ),
//                       ),
//                     ),
//                   )),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(8),
//                         gradient: AppColors.buildSecondaryGradient(),
//                       ),
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.transparent,
//                           padding: const EdgeInsets.symmetric(vertical: 10),
//                           shadowColor: Colors.transparent,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         onPressed: () {
//                           _validateKioskPin();
//                         },
//                         child: _isLoading
//                             ? const SizedBox(
//                                 height: 20,
//                                 width: 20,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   valueColor: AlwaysStoppedAnimation<Color>(
//                                       Colors.white),
//                                 ),
//                               )
//                             : const Text(
//                                 'Next',
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w700,
//                                   letterSpacing: 16 * (-3 / 100),
//                                 ),
//                               ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   // Extracted the PIN dots to a separate widget for better reuse
//   Widget _buildPinDots() {
//     return Wrap(
//       alignment: WrapAlignment.center,
//       spacing: 16,
//       runSpacing: 10,
//       children: List.generate(
//         maxPinLength,
//         (index) => Container(
//           width: 12,
//           height: 12,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: index < pin.length ? Colors.blue[400] : Colors.grey[300],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildKeypad() {
//     return Container(
//       alignment: Alignment.center,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _buildKeypadButton('1'),
//               _buildKeypadButton('2'),
//               _buildKeypadButton('3'),
//             ],
//           ),
//           const SizedBox(height: 10),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _buildKeypadButton('4'),
//               _buildKeypadButton('5'),
//               _buildKeypadButton('6'),
//             ],
//           ),
//           const SizedBox(height: 10),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _buildKeypadButton('7'),
//               _buildKeypadButton('8'),
//               _buildKeypadButton('9'),
//             ],
//           ),
//           const SizedBox(height: 10),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const SizedBox(width: 90), // Empty space
//               _buildKeypadButton('0'),
//               Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 10),
//                 width: 70,
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: removeDigit,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey[200],
//                     foregroundColor: Colors.black,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     elevation: 0,
//                   ),
//                   child: const Icon(Icons.backspace_outlined, size: 20),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildKeypadButton(String number) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 10),
//       width: 70,
//       height: 50,
//       child: ElevatedButton(
//         onPressed: () => addDigit(number),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.grey[200],
//           foregroundColor: Colors.black,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//           elevation: 0,
//         ),
//         child: Center(
//           child: Text(
//             number,
//             style: const TextStyle(fontSize: 20),
//             textAlign: TextAlign.center,
//           ),
//         ),
//       ),
//     );
//   }
// }
