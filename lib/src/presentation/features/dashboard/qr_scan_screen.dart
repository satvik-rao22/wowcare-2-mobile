// import 'dart:developer';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

// class QrScanScreen extends StatefulWidget {
//   const QrScanScreen({super.key});

//   static const routeName = '/qr-scanner';

//   @override
//   State<StatefulWidget> createState() => _QrScanScreenState();
// }

// class _QrScanScreenState extends State<QrScanScreen> {
//   Barcode? result;
//   QRViewController? controller;
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   bool isFlashOn = false; // Track flash state
//   bool isFrontCamera = false; // Track camera state

//   @override
//   void reassemble() {
//     super.reassemble();
//     if (Platform.isAndroid) {
//       controller!.pauseCamera();
//       Future.delayed(const Duration(milliseconds: 500), () {
//         controller!.resumeCamera();
//       });
//     } else {
//       controller!.resumeCamera();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<DocumentBloc, DocumentState>(
//       listener: (context, state) {
//         if (state is ScannerValidated) {
//           if (state.isValidated && context.isGuardian) {
//             List<StudentEntity> students =
//                 ModalRoute.of(context)!.settings.arguments
//                     as List<StudentEntity>;

//             // Check if all students are signed in
//             bool allSignedIn = students.every(
//               (student) => student.isSignedIn == true,
//             );

//             // Check if all students are signed out
//             bool allSignedOut = students.every(
//               (student) => student.isSignedIn == false,
//             );

//             if (allSignedIn) {
//               Navigator.pop(context);

//               // If all students are signed in, go to sign out form
//               Navigator.of(
//                 context,
//               ).pushNamed(StudentSignOutForm.routeName, arguments: students);
//             } else if (allSignedOut) {
//               Navigator.pop(context);

//               // If all students are signed out, go to sign in form
//               Navigator.of(
//                 context,
//               ).pushNamed(StudentSignInForm.routeName, arguments: students);
//             } else {
//               Navigator.pop(context);
//               // If mixed status (some in, some out), go to combined form
//               Navigator.of(context).pushNamed(
//                 StudentSignInOutButton.routeName,
//                 arguments: students,
//               );
//             }
//           }

//           if (state.isValidated && context.isPersonnel) {
//             if (state.isValidated && !context.currentStaff!.isSignedIn) {
//               // QR code is valid - navigate to target page
//               Navigator.pop(context);
//               Navigator.pushNamed(context, StaffSignInForm.routeName);
//             } else if (state.isValidated && context.currentStaff!.isSignedIn) {
//               Navigator.pop(context);
//               Navigator.pushNamed(context, StaffSignOutForm.routeName);
//             } else {
//               // QR code is invalid - show snackbar
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Invalid QR code. Please try again.'),
//                 ),
//               );

//               // Reset scanner to allow for another scan
//               setState(() {
//                 result = null;
//               });
//               controller?.resumeCamera();
//             }
//           }
//         }
//       },
//       child: Scaffold(
//         body: Column(
//           children: <Widget>[
//             Expanded(flex: 4, child: _buildQrView(context)),
//             Expanded(
//               flex: 1,
//               child: FittedBox(
//                 fit: BoxFit.contain,
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: <Widget>[
//                     if (result != null)
//                       Text(' Data: ${result!.code}')
//                     else
//                       const Text('Scan a code'),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: <Widget>[
//                         Container(
//                           margin: const EdgeInsets.all(8),
//                           child: Row(
//                             children: [
//                               const Text('Flash:'),
//                               StatefulBuilder(
//                                 builder: (context, setState) {
//                                   return GestureDetector(
//                                     onTap: () async {
//                                       setState(() {
//                                         isFlashOn = !isFlashOn;
//                                       });
//                                       await controller?.toggleFlash();
//                                     },
//                                     child: Container(
//                                       width: 58,
//                                       height: 32,
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(15),
//                                         gradient: isFlashOn
//                                             ? null
//                                             : AppColors.buildPrimaryGradient()
//                                                   .withOpacity(0.4),
//                                         color: isFlashOn
//                                             ? const Color.fromRGBO(
//                                                 56,
//                                                 200,
//                                                 32,
//                                                 0.6,
//                                               )
//                                             : null,
//                                       ),
//                                       child: Stack(
//                                         children: [
//                                           AnimatedPositioned(
//                                             duration: const Duration(
//                                               milliseconds: 200,
//                                             ),
//                                             curve: Curves.easeInOut,
//                                             left: isFlashOn ? 26 : 2,
//                                             top: 4,
//                                             bottom: 4,
//                                             child: Container(
//                                               width: 30,
//                                               height: 30,
//                                               decoration: const BoxDecoration(
//                                                 shape: BoxShape.circle,
//                                                 color: Colors.white,
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                         Container(
//                           margin: const EdgeInsets.all(8),
//                           child: IconButton(
//                             icon: Icon(
//                               isFrontCamera
//                                   ? Icons.camera_front
//                                   : Icons.camera_rear,
//                               size: 30,
//                             ),
//                             onPressed: () async {
//                               isFrontCamera = !isFrontCamera;
//                               await controller?.flipCamera();
//                               setState(() {});
//                             },
//                           ),
//                         ),
//                         // Add a scan again button
//                         Container(
//                           margin: const EdgeInsets.all(8),
//                           child: ElevatedButton(
//                             onPressed: () async {
//                               setState(() {
//                                 result = null;
//                               });
//                               await controller?.resumeCamera();
//                             },
//                             child: const Text('Scan Again'),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildQrView(BuildContext context) {
//     var scanArea =
//         (MediaQuery.of(context).size.width < 400 ||
//             MediaQuery.of(context).size.height < 400)
//         ? 150.0
//         : 300.0;

//     return Stack(
//       children: [
//         QRView(
//           key: qrKey,
//           onQRViewCreated: _onQRViewCreated,
//           overlay: QrScannerOverlayShape(
//             borderColor: Colors.red,
//             borderRadius: 10,
//             borderLength: 30,
//             borderWidth: 10,
//             cutOutSize: scanArea,
//           ),
//           onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
//         ),

//         // ✅ Close button on top right of camera
//         SafeArea(
//           child: Align(
//             alignment: Alignment.topRight,
//             child: Padding(
//               padding: const EdgeInsets.only(top: 8, right: 12),
//               child: IconButton(
//                 icon: const Icon(Icons.close, color: Colors.white, size: 30),
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   void _onQRViewCreated(QRViewController controller) {
//     setState(() {
//       this.controller = controller;
//     });

//     controller.scannedDataStream.listen((scanData) async {
//       if (result == null && scanData.code != null) {
//         setState(() {
//           result = scanData;
//         });

//         // Pause the camera to prevent multiple scans
//         await controller.pauseCamera();

//         // Log the scanned data
//         log('Scanned QR Data: ${scanData.code}');

//         // Parse the QR code data
//         final parts = scanData.code!.split('|');

//         if (parts.length >= 3 && parts[0] == 'SCHOOL_SCANNER') {
//           final schoolId = parts[1]; // "1"
//           final scannerId = parts[2]; // "CF7018D40DED4E3481223131611593AC"

//           log('Extracted School ID: $schoolId');
//           log('Extracted Scanner ID: $scannerId');

//           // Call the ValidateScanner event with the extracted IDs
//           context.read<DocumentBloc>().add(
//             ValidateScanner(scannerId, schoolId),
//           );
//         } else {
//           // Handle invalid QR code format
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Invalid QR code format')),
//           );

//           // Resume camera to allow scanning another QR code
//           await controller.resumeCamera();
//         }
//       }
//     });
//   }

//   void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
//     log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
//     if (!p) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('No Permission')));
//     }
//   }
// }
