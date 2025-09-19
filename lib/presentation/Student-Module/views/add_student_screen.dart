// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:schoolerp/core/common/widgets/custom_app_bar.dart';
// import 'package:schoolerp/core/res/colors.dart';
// import 'package:schoolerp/core/res/media_res.dart';
// import 'package:schoolerp/core/util/core_utils.dart';
// import 'package:schoolerp/core/util/responsive_helper.dart';

// import 'Classroom-Repository/classroom.dart';
// import 'Classroom-Repository/sibling-student.dart';

// class AddStudentScreen extends StatefulWidget {
//   const AddStudentScreen({super.key});
//   static const String routeName = '/add-student';

//   @override
//   _AddStudentScreenState createState() => _AddStudentScreenState();
// }

// class _AddStudentScreenState extends State<AddStudentScreen> {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   final TextEditingController _firstNameController = TextEditingController();
//   final TextEditingController _lastNameController = TextEditingController();
//   String? _selectedClassroom;
//   List<Classroom> _classrooms = [];
//   String? _selectedStatus;
//   final List<String> _statuses = ['Active', 'Inactive'];
//   bool _isSubmitting = false;
//   bool _isLoading = true;
//   OverlayEntry? _overlayEntry;
//   OverlayEntry? _popupOverlay;
//   bool _isCheckingSurname = false;
//   Timer? _debounce;

//   @override
//   void initState() {
//     super.initState();
//     _fetchClassrooms();
//     _lastNameController.addListener(_onSurnameChanged);
//   }

//   @override
//   void dispose() {
//     _removeDropdownOverlay();
//     _removePopupOverlay();
//     _debounce?.cancel();
//     _firstNameController.dispose();
//     _lastNameController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchClassrooms() async {
//     setState(() {
//       _isLoading = true;
//     });

//     final classrooms = await ClassroomService.fetchClassrooms(context);
//     setState(() {
//       _classrooms = classrooms;
//       _isLoading = false;
//     });
//   }

//   void _onSurnameChanged() {
//     if (_debounce?.isActive ?? false) _debounce?.cancel();
//     _debounce = Timer(const Duration(milliseconds: 500), () {
//       _checkSurname();
//     });
//   }

//   Future<void> _checkSurname() async {
//     final surname = _lastNameController.text.trim();
//     if (surname.length < 2 || _isCheckingSurname) return;

//     setState(() {
//       _isCheckingSurname = true;
//     });

//     final students = await StudentService.fetchStudentsBySurname(
//       context,
//       Uri.encodeComponent(surname),
//     );
//     if (mounted) {
//       _showSiblingPopup(students);
//     }

//     setState(() {
//       _isCheckingSurname = false;
//     });
//   }

//   void _showSiblingPopup(List<Student> students) {
//     _removePopupOverlay();

//     _popupOverlay = OverlayEntry(
//       builder: (context) => Stack(
//         children: [
//           Positioned.fill(
//             child: GestureDetector(
//               onTap: _removePopupOverlay,
//               child: Container(color: Colors.black54),
//             ),
//           ),
//           Center(
//             child: Material(
//               elevation: 4,
//               borderRadius: BorderRadius.circular(12),
//               child: Container(
//                 width: MediaQuery.of(context).size.width * 0.8,
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Text(
//                       'API Response for Surname',
//                       style: TextStyle(
//                         fontFamily: 'Manrope',
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xff573353),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     ...students.map((student) => Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Student ID: ${student.id}',
//                               style: const TextStyle(
//                                 fontFamily: 'Manrope',
//                                 fontSize: 16,
//                                 color: Colors.black,
//                               ),
//                             ),
//                             Text(
//                               'Full Name: ${student.fullName}',
//                               style: const TextStyle(
//                                 fontFamily: 'Manrope',
//                                 fontSize: 16,
//                                 color: Colors.black,
//                               ),
//                             ),
//                             if (student.siblings.isNotEmpty)
//                               Padding(
//                                 padding: const EdgeInsets.only(left: 16),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: student.siblings
//                                       .map((sibling) => Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               Text(
//                                                 'Sibling ID: ${sibling.id}',
//                                                 style: const TextStyle(
//                                                   fontFamily: 'Manrope',
//                                                   fontSize: 14,
//                                                   color: Colors.grey,
//                                                 ),
//                                               ),
//                                               Text(
//                                                 'Sibling Name: ${sibling.fullName}',
//                                                 style: const TextStyle(
//                                                   fontFamily: 'Manrope',
//                                                   fontSize: 14,
//                                                   color: Colors.grey,
//                                                 ),
//                                               ),
//                                             ],
//                                           ))
//                                       .toList(),
//                                 ),
//                               ),
//                             const SizedBox(height: 8),
//                           ],
//                         )),
//                     const SizedBox(height: 16),
//                     TextButton(
//                       onPressed: _removePopupOverlay,
//                       child: const Text(
//                         'Close',
//                         style: TextStyle(
//                           fontFamily: 'Manrope',
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: AppColors.primaryColor,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );

//     Overlay.of(context).insert(_popupOverlay!);
//   }

//   void _removePopupOverlay() {
//     _popupOverlay?.remove();
//     _popupOverlay = null;
//   }

//   void _addStudent() {
//     if (_firstNameController.text.isEmpty) {
//       CoreUtils.showTopSnackBar(
//           context: context, message: 'First name is required', isError: true);
//       return;
//     }
//     if (_lastNameController.text.isEmpty) {
//       CoreUtils.showTopSnackBar(
//           context: context, message: 'Last name is required', isError: true);
//       return;
//     }
//     if (_selectedClassroom == null) {
//       CoreUtils.showTopSnackBar(
//           context: context,
//           message: 'Please select a classroom',
//           isError: true);
//       return;
//     }
//     if (_selectedStatus == null) {
//       CoreUtils.showTopSnackBar(
//           context: context, message: 'Please select a status', isError: true);
//       return;
//     }

//     setState(() {
//       _isSubmitting = true;
//     });

//     // Mock API call
//     Future.delayed(const Duration(seconds: 2), () {
//       setState(() {
//         _isSubmitting = false;
//       });
//       CoreUtils.showTopSnackBar(
//           context: context,
//           message: 'Student created successfully',
//           isSuccess: true);
//       Navigator.pop(context);
//     });
//   }

//   void _removeDropdownOverlay() {
//     _overlayEntry?.remove();
//     _overlayEntry = null;
//   }

//   void _showDropdown(
//     BuildContext context,
//     List<String> items,
//     String? selectedValue,
//     Function(String) onSelected,
//     GlobalKey key,
//   ) {
//     if (_overlayEntry != null) {
//       _removeDropdownOverlay();
//       return;
//     }

//     final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
//     if (renderBox == null) return;
//     final size = renderBox.size;
//     final position = renderBox.localToGlobal(Offset.zero);

//     _overlayEntry = OverlayEntry(
//       builder: (context) => Stack(
//         children: [
//           Positioned.fill(
//             child: GestureDetector(
//               onTap: _removeDropdownOverlay,
//               child: Container(color: Colors.transparent),
//             ),
//           ),
//           Positioned(
//             top: position.dy + size.height,
//             left: position.dx,
//             width: size.width,
//             child: Material(
//               elevation: 4,
//               borderRadius: BorderRadius.circular(8),
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(
//                   maxHeight: 200,
//                 ),
//                 child: ListView.builder(
//                   padding: EdgeInsets.zero,
//                   shrinkWrap: true,
//                   itemCount: items.length,
//                   itemBuilder: (context, index) {
//                     final item = items[index];
//                     return ListTile(
//                       title: Text(item),
//                       onTap: () {
//                         onSelected(item);
//                         _removeDropdownOverlay();
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );

//     Overlay.of(context).insert(_overlayEntry!);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final responsive = ResponsiveHelper(context);
//     final bottomPadding = MediaQuery.of(context).padding.bottom;
//     final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

//     return GestureDetector(
//       onTap: () {
//         FocusManager.instance.primaryFocus?.unfocus();
//         _removeDropdownOverlay();
//         _removePopupOverlay();
//       },
//       child: Scaffold(
//         key: _scaffoldKey,
//         backgroundColor: Colors.white,
//         body: Stack(
//           children: [
//             Positioned.fill(
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: AppColors.buildScaffoldGradient(),
//                 ),
//                 child: Image.asset(
//                   MediaRes.wowcareMobileBg,
//                   fit: BoxFit.cover,
//                   alignment: Alignment.topCenter,
//                 ),
//               ),
//             ),
//             NestedScrollView(
//               headerSliverBuilder: (context, innerBoxIsScrolled) {
//                 return [
//                   const CustomAppBar(
//                     hasBackButton: true,
//                   ),
//                 ];
//               },
//               body: _isLoading
//                   ? const Center(child: CircularProgressIndicator())
//                   : Column(
//                       children: [
//                         const SizedBox(height: 16),
//                         Padding(
//                           padding: EdgeInsets.symmetric(
//                               horizontal: responsive.horizontalSpacing),
//                           child: Align(
//                             alignment: Alignment.centerLeft,
//                             child: Text(
//                               "Add Student",
//                               style: TextStyle(
//                                 fontFamily: "Manrope",
//                                 fontSize: responsive.titleFontSize,
//                                 fontWeight: FontWeight.w600,
//                                 color: const Color(0xff573353),
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
//                         Expanded(
//                           child: Container(
//                             width: responsive.containerWidth,
//                             margin: EdgeInsets.symmetric(
//                                 horizontal: responsive.horizontalSpacing),
//                             padding: EdgeInsets.all(
//                                 responsive.isTablet ? 32.0 : 16.0),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.all(
//                                 Radius.circular(
//                                     responsive.isTablet ? 40.0 : 24.0),
//                               ),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.05),
//                                   blurRadius: 8,
//                                   offset: const Offset(0, 2),
//                                 ),
//                               ],
//                             ),
//                             child: Column(
//                               children: [
//                                 _buildRowInputs(
//                                   context,
//                                   "First Name",
//                                   "Last Name",
//                                 ),
//                                 SizedBox(height: responsive.verticalSpacing),
//                                 _buildDropdown(
//                                   "Classroom",
//                                   _selectedClassroom,
//                                   _classrooms.map((c) => c.name).toList(),
//                                   (val) {
//                                     setState(() {
//                                       _selectedClassroom = val;
//                                     });
//                                   },
//                                 ),
//                                 SizedBox(height: responsive.verticalSpacing),
//                                 _buildDropdown(
//                                     "Status", _selectedStatus, _statuses,
//                                     (val) {
//                                   setState(() {
//                                     _selectedStatus = val;
//                                   });
//                                 }),
//                                 const SizedBox(height: 12),
//                               ],
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                       ],
//                     ),
//             ),
//           ],
//         ),
//         bottomNavigationBar: Container(
//           padding: EdgeInsets.only(
//               bottom: safeAreaBottom, left: 16, right: 16, top: 8),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 offset: const Offset(0, -4),
//                 blurRadius: 16,
//               ),
//             ],
//             borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
//               topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
//             ),
//           ),
//           child: Container(
//             height: responsive.buttonHeight,
//             decoration: BoxDecoration(
//               gradient: _isSubmitting ? null : AppColors.buildPrimaryGradient(),
//               color: _isSubmitting ? Colors.grey[300] : null,
//               borderRadius:
//                   BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
//             ),
//             child: TextButton(
//               onPressed: _isSubmitting ? null : _addStudent,
//               child: Text(
//                 'Save',
//                 style: TextStyle(
//                   fontFamily: 'Manrope',
//                   fontSize: responsive.buttonFontSize,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildRowInputs(BuildContext context, String label1, String label2) {
//     final responsive = ResponsiveHelper(context);
//     return Row(
//       children: [
//         Expanded(
//           child: _buildInputField(
//             label1,
//             "E.g. John",
//             _firstNameController,
//           ),
//         ),
//         SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
//         Expanded(
//           child: _buildInputField(
//             label2,
//             "E.g. Smith",
//             _lastNameController,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInputField(
//       String label, String hint, TextEditingController controller) {
//     final responsive = ResponsiveHelper(context);
//     final labelStyle = TextStyle(
//       fontSize: responsive.labelFontSize,
//       fontFamily: "Manrope",
//       fontWeight: FontWeight.w400,
//       color: const Color(0xff573353),
//     );

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         RichText(
//           text: TextSpan(
//             style: labelStyle,
//             children: [
//               TextSpan(text: label),
//               const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
//             ],
//           ),
//         ),
//         SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
//         Container(
//           constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             border: Border.all(color: const Color(0x66573353)),
//             borderRadius:
//                 BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
//           ),
//           child: TextField(
//             controller: controller,
//             decoration: InputDecoration(
//               hintText: hint,
//               hintStyle: labelStyle.copyWith(color: Colors.grey),
//               border: InputBorder.none,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: responsive.isTablet ? 16.0 : 12.0,
//                 vertical: responsive.isTablet ? 16.0 : 12.0,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDropdown(
//     String label,
//     String? selectedValue,
//     List<String> items,
//     Function(String) onSelected,
//   ) {
//     final responsive = ResponsiveHelper(context);
//     final key = GlobalKey();
//     return Column(
//       key: key,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         RichText(
//           text: TextSpan(
//             style: TextStyle(
//               fontSize: responsive.labelFontSize,
//               fontFamily: "Manrope",
//               fontWeight: FontWeight.w400,
//               color: AppColors.primaryColor,
//             ),
//             children: [
//               TextSpan(text: label),
//               const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
//             ],
//           ),
//         ),
//         SizedBox(height: responsive.isTablet ? 8.0 : 4.0),
//         GestureDetector(
//           onTap: () =>
//               _showDropdown(context, items, selectedValue, onSelected, key),
//           child: Container(
//             height: responsive.inputFieldHeight,
//             padding: EdgeInsets.symmetric(
//               horizontal: responsive.isTablet ? 20.0 : 16.0,
//             ),
//             decoration: BoxDecoration(
//               border: Border.all(color: const Color(0x66573353)),
//               borderRadius:
//                   BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
//               color: Colors.white,
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     selectedValue ?? 'Select',
//                     style: TextStyle(
//                       color: selectedValue == null ? Colors.grey : Colors.black,
//                       fontSize: responsive.inputFontSize,
//                       fontFamily: 'Manrope',
//                     ),
//                   ),
//                 ),
//                 Icon(
//                   Icons.keyboard_arrow_down_rounded,
//                   color: const Color(0xff573353),
//                   size: responsive.isTablet ? 28.0 : 24.0,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
