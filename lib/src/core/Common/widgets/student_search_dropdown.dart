// import 'package:flutter/material.dart';
// import 'package:schoolerp/core/res/colors.dart';
// import 'package:schoolerp/core/res/fonts.dart';
// import 'package:schoolerp/src/billing/data/services/students_dropdown_service.dart';

// class StudentSearchDropdown extends StatefulWidget {
//   final String hintText;
//   final StudentDropdownItem? selectedStudent;
//   final Function(StudentDropdownItem?) onSelect;
//   final bool isLoading;

//   const StudentSearchDropdown({
//     Key? key,
//     required this.hintText,
//     this.selectedStudent,
//     required this.onSelect,
//     this.isLoading = false,
//   }) : super(key: key);

//   @override
//   State<StudentSearchDropdown> createState() => _StudentSearchDropdownState();
// }

// class _StudentSearchDropdownState extends State<StudentSearchDropdown> {
//   final StudentsDropdownService _studentsService = StudentsDropdownService();
//   final TextEditingController _searchController = TextEditingController();
//   final FocusNode _searchFocusNode = FocusNode();

//   List<StudentDropdownItem> _allStudents = [];
//   List<StudentDropdownItem> _filteredStudents = [];
//   bool _isLoadingStudents = false;
//   bool _isSearching = false;
//   bool _isDropdownOpen = false;
//   OverlayEntry? _overlayEntry;
//   final GlobalKey _buttonKey = GlobalKey();

//   @override
//   void initState() {
//     super.initState();
//     _loadStudents();
//     _searchController.addListener(_onSearchChanged);
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _searchFocusNode.dispose();
//     _hideOverlay();
//     super.dispose();
//   }

//   Future<void> _loadStudents() async {
//     if (_isLoadingStudents) return;

//     setState(() {
//       _isLoadingStudents = true;
//     });

//     try {
//       final students = await _studentsService.getAllStudents();
//       setState(() {
//         _allStudents = students;
//         _filteredStudents = students;
//         _isLoadingStudents = false;
//       });
//     } catch (e) {
//       print('Error loading students: $e');
//       setState(() {
//         _isLoadingStudents = false;
//       });
//     }
//   }

//   void _onSearchChanged() {
//     final query = _searchController.text.trim();

//     if (query.isEmpty) {
//       setState(() {
//         _filteredStudents = _allStudents;
//         _isSearching = false;
//       });
//     } else {
//       setState(() {
//         _isSearching = true;
//       });

//       // Filter locally first for immediate response
//       final localFiltered = _allStudents
//           .where((student) =>
//               student.fullName.toLowerCase().contains(query.toLowerCase()))
//           .toList();

//       setState(() {
//         _filteredStudents = localFiltered;
//       });

//       // Then search on server for more comprehensive results
//       _performServerSearch(query);
//     }
//   }

//   Future<void> _performServerSearch(String query) async {
//     try {
//       final serverResults = await _studentsService.searchStudents(query);

//       // Merge server results with local results, avoiding duplicates
//       final existingIds = _filteredStudents.map((s) => s.id).toSet();
//       final newResults =
//           serverResults.where((s) => !existingIds.contains(s.id)).toList();

//       setState(() {
//         _filteredStudents = [..._filteredStudents, ...newResults];
//         _isSearching = false;
//       });
//     } catch (e) {
//       print('Error searching students on server: $e');
//       setState(() {
//         _isSearching = false;
//       });
//     }
//   }

//   void _showOverlay() {
//     if (_overlayEntry != null) return;

//     // Get the position and size of the button
//     final RenderBox renderBox =
//         _buttonKey.currentContext!.findRenderObject() as RenderBox;
//     final buttonSize = renderBox.size;
//     final buttonPosition = renderBox.localToGlobal(Offset.zero);

//     // Calculate available space
//     final screenSize = MediaQuery.of(context).size;
//     final availableHeightBelow =
//         screenSize.height - buttonPosition.dy - buttonSize.height;
//     final availableHeightAbove = buttonPosition.dy;

//     // Determine dropdown dimensions
//     final dropdownWidth = buttonSize.width;

//     // Check if there's enough space below (considering bottom navigation)
//     final hasEnoughSpaceBelow =
//         availableHeightBelow > 300; // Minimum height needed
//     final hasEnoughSpaceAbove = availableHeightAbove > 300;

//     // Determine if dropdown should open above or below
//     final openBelow = hasEnoughSpaceBelow;
//     final openAbove = !hasEnoughSpaceBelow && hasEnoughSpaceAbove;

//     // Calculate dropdown position
//     double dropdownTop;
//     double maxDropdownHeight;

//     if (openBelow) {
//       // Open below with 4px gap
//       dropdownTop = buttonPosition.dy + buttonSize.height + 4;
//       // Reserve space for bottom navigation (assuming ~80px height)
//       maxDropdownHeight =
//           availableHeightBelow - 100; // 100px buffer for bottom nav
//     } else if (openAbove) {
//       // Open above with 4px gap
//       dropdownTop = buttonPosition.dy - 4;
//       maxDropdownHeight = availableHeightAbove - 20;
//     } else {
//       // Not enough space in either direction, open below with limited height
//       dropdownTop = buttonPosition.dy + buttonSize.height + 4;
//       maxDropdownHeight = availableHeightBelow - 100;
//     }

//     // Ensure minimum and maximum height constraints
//     maxDropdownHeight = maxDropdownHeight.clamp(200.0, 400.0);

//     // Ensure dropdown doesn't go off-screen horizontally
//     final dropdownLeft = buttonPosition.dx;

//     _overlayEntry = OverlayEntry(
//       builder: (context) => Stack(
//         children: [
//           // Invisible overlay to detect taps outside dropdown
//           Positioned.fill(
//             child: GestureDetector(
//               onTap: () {
//                 _hideOverlay();
//               },
//               child: Container(
//                 color: Colors.transparent,
//               ),
//             ),
//           ),
//           // Your original dropdown positioned exactly where it should be
//           Positioned(
//             top: dropdownTop,
//             left: dropdownLeft,
//             child: Material(
//               elevation: 8,
//               borderRadius: BorderRadius.circular(8),
//               child: Container(
//                 width: dropdownWidth,
//                 height:
//                     maxDropdownHeight, // Fixed height instead of constraints
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: AppColors.cardBorderColor),
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Search field
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: const BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.only(
//                           topLeft: Radius.circular(8),
//                           topRight: Radius.circular(8),
//                         ),
//                       ),
//                       child: TextField(
//                         controller: _searchController,
//                         focusNode: _searchFocusNode,
//                         decoration: InputDecoration(
//                           hintText: 'Search students...',
//                           prefixIcon: const Icon(Icons.search,
//                               size: 20, color: Colors.grey),
//                           suffixIcon: _isSearching
//                               ? const SizedBox(
//                                   width: 16,
//                                   height: 16,
//                                   child:
//                                       CircularProgressIndicator(strokeWidth: 2),
//                                 )
//                               : null,
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                             borderSide:
//                                 BorderSide(color: AppColors.cardBorderColor),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                             borderSide: const BorderSide(
//                                 color: AppColors.primaryColor, width: 2),
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 12, vertical: 8),
//                           filled: true,
//                           fillColor: Colors.grey[50],
//                         ),
//                         style: const TextStyle(fontSize: 14),
//                         onTap: () {
//                           // Keep dropdown open when tapping search field
//                         },
//                       ),
//                     ),
//                     // Results count
//                     if (_filteredStudents.isNotEmpty)
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 12, vertical: 8),
//                         decoration: BoxDecoration(
//                           color: AppColors.cardColor,
//                           border: Border(
//                             top: BorderSide(
//                                 color:
//                                     AppColors.cardBorderColor.withOpacity(0.3)),
//                           ),
//                         ),
//                         child: Text(
//                           '${_filteredStudents.length} student${_filteredStudents.length == 1 ? '' : 's'} found',
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: AppColors.primaryColor,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     // Divider
//                     if (_filteredStudents.isNotEmpty)
//                       Divider(
//                           height: 1,
//                           color: AppColors.cardBorderColor.withOpacity(0.3)),
//                     // Student list with scrollbar
//                     Expanded(
//                       child: _filteredStudents.isEmpty &&
//                               !_isLoadingStudents &&
//                               _searchController.text.isNotEmpty
//                           ? const Padding(
//                               padding: EdgeInsets.all(16),
//                               child: Center(
//                                 child: Text(
//                                   'No students found',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: Colors.grey,
//                                     fontStyle: FontStyle.italic,
//                                   ),
//                                 ),
//                               ),
//                             )
//                           : _isLoadingStudents
//                               ? const Padding(
//                                   padding: EdgeInsets.all(16),
//                                   child: Center(
//                                     child: Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         SizedBox(
//                                           width: 16,
//                                           height: 16,
//                                           child: CircularProgressIndicator(
//                                               strokeWidth: 2),
//                                         ),
//                                         SizedBox(width: 12),
//                                         Text(
//                                           'Loading students...',
//                                           style: TextStyle(
//                                               fontSize: 14, color: Colors.grey),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 )
//                               : Scrollbar(
//                                   thumbVisibility: true,
//                                   thickness: 6,
//                                   radius: const Radius.circular(3),
//                                   child: ListView.builder(
//                                     shrinkWrap: true,
//                                     padding:
//                                         const EdgeInsets.symmetric(vertical: 4),
//                                     itemCount: _filteredStudents.length,
//                                     itemBuilder: (context, index) {
//                                       final student = _filteredStudents[index];
//                                       return InkWell(
//                                         onTap: () {
//                                           widget.onSelect(student);
//                                           _hideOverlay();
//                                         },
//                                         child: Container(
//                                           padding: const EdgeInsets.symmetric(
//                                               horizontal: 12, vertical: 10),
//                                           child: Row(
//                                             children: [
//                                               // Student avatar/initials
//                                               Container(
//                                                 width: 36,
//                                                 height: 36,
//                                                 decoration: BoxDecoration(
//                                                   color: AppColors.primaryColor
//                                                       .withOpacity(0.1),
//                                                   borderRadius:
//                                                       BorderRadius.circular(18),
//                                                 ),
//                                                 child: Center(
//                                                   child: Text(
//                                                     _getInitials(
//                                                         student.fullName),
//                                                     style: const TextStyle(
//                                                       fontSize: 13,
//                                                       fontWeight:
//                                                           FontWeight.w600,
//                                                       color: AppColors
//                                                           .primaryColor,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ),
//                                               const SizedBox(width: 12),
//                                               // Student name and room
//                                               Expanded(
//                                                 child: Column(
//                                                   crossAxisAlignment:
//                                                       CrossAxisAlignment.start,
//                                                   children: [
//                                                     Text(
//                                                       student.fullName,
//                                                       style: const TextStyle(
//                                                         fontSize: 14,
//                                                         fontWeight:
//                                                             FontWeight.w500,
//                                                         color: AppColors
//                                                             .primaryColor,
//                                                       ),
//                                                       maxLines: 1,
//                                                       overflow:
//                                                           TextOverflow.ellipsis,
//                                                     ),
//                                                     if (student.roomName !=
//                                                             null &&
//                                                         student.roomName!
//                                                             .isNotEmpty)
//                                                       Text(
//                                                         student.roomName!,
//                                                         style: TextStyle(
//                                                           fontSize: 12,
//                                                           color: AppColors
//                                                               .primaryColor
//                                                               .withOpacity(0.7),
//                                                         ),
//                                                         maxLines: 1,
//                                                         overflow: TextOverflow
//                                                             .ellipsis,
//                                                       ),
//                                                   ],
//                                                 ),
//                                               ),
//                                               // Check icon for selected student
//                                               if (widget.selectedStudent?.id ==
//                                                   student.id)
//                                                 Container(
//                                                   padding:
//                                                       const EdgeInsets.all(4),
//                                                   decoration: BoxDecoration(
//                                                     gradient: AppColors
//                                                         .buildPrimaryGradient(),
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                             12),
//                                                   ),
//                                                   child: const Icon(
//                                                     Icons.check,
//                                                     size: 14,
//                                                     color: Colors.white,
//                                                   ),
//                                                 ),
//                                             ],
//                                           ),
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                 ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );

//     Overlay.of(context).insert(_overlayEntry!);
//     setState(() {
//       _isDropdownOpen = true;
//     });

//     // Focus the search field when dropdown opens
//     // WidgetsBinding.instance.addPostFrameCallback((_) {
//     //   _searchFocusNode.requestFocus();
//     // });
//   }

//   void _hideOverlay() {
//     _overlayEntry?.remove();
//     _overlayEntry = null;
//     setState(() {
//       _isDropdownOpen = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       key: _buttonKey,
//       onTap: () {
//         if (_isDropdownOpen) {
//           _hideOverlay();
//         } else {
//           _showOverlay();
//         }
//       },
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//         decoration: BoxDecoration(
//           color: AppColors.cardColor,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: AppColors.cardBorderColor),
//         ),
//         child: Row(
//           children: [
//             // Student avatar/initials
//             if (widget.selectedStudent != null) ...[
//               Container(
//                 width: 32,
//                 height: 32,
//                 decoration: BoxDecoration(
//                   color: AppColors.primaryColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Center(
//                   child: Text(
//                     _getInitials(widget.selectedStudent!.fullName),
//                     style: const TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.primaryColor,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//             ],
//             // Text
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     widget.selectedStudent?.fullName ?? widget.hintText,
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: widget.selectedStudent != null
//                           ? AppColors.primaryColor
//                           : AppColors.primaryColor.withOpacity(0.6),
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   if (widget.selectedStudent?.roomName != null &&
//                       widget.selectedStudent!.roomName!.isNotEmpty)
//                     Text(
//                       widget.selectedStudent!.roomName!,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: AppColors.primaryColor.withOpacity(0.7),
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                 ],
//               ),
//             ),
//             // Dropdown arrow
//             Icon(
//               _isDropdownOpen
//                   ? Icons.keyboard_arrow_up
//                   : Icons.keyboard_arrow_down,
//               color: AppColors.primaryColor,
//               size: 20,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _getInitials(String name) {
//     final parts = name.trim().split(RegExp(r'\s+'));
//     if (parts.isEmpty) return '';
//     if (parts.length == 1) return parts[0][0].toUpperCase();
//     return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
//   }
// }
