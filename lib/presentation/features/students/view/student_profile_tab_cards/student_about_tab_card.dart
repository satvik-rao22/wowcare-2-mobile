import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/upcoming_move_widget.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';

import '../../../../../shared/common/widgets/profile_info_card.dart';
import '../../../../../shared/common/widgets/profile_show_widget.dart';
import '../edit_student_profile_details_screen.dart';

class StudentAboutTabCard extends StatefulWidget {
  const StudentAboutTabCard({
    required this.scrollController,
    required this.name,
    required this.classroom,
    required this.tags,
    required this.schedule,
    required this.sibling,
    this.onRefresh,
    this.studentProfile,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;
  final List<String> tags;
  final List<String> schedule;
  final Map<String, dynamic> sibling;
  final Future<void> Function()? onRefresh;
  final StudentProfileModel? studentProfile;

  @override
  State<StudentAboutTabCard> createState() => _StudentAboutTabCardState();
}

class _StudentAboutTabCardState extends State<StudentAboutTabCard> {
  @override
  void initState() {
    super.initState();
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getValueOrDash(String? value) {
    if (value == null || value.isEmpty) return '-';
    return value;
  }

  String _formatAddress(Map<String, dynamic> address) {
    final parts = <String>[];
    if (address['street'] != null && address['street'].toString().isNotEmpty) {
      parts.add(address['street'].toString());
    }
    if (address['city'] != null && address['city'].toString().isNotEmpty) {
      parts.add(address['city'].toString());
    }
    if (address['state'] != null && address['state'].toString().isNotEmpty) {
      parts.add(address['state'].toString());
    }
    if (address['country'] != null && address['country'].toString().isNotEmpty) {
      parts.add(address['country'].toString());
    }
    if (address['zipCode'] != null && address['zipCode'].toString().isNotEmpty) {
      parts.add(address['zipCode'].toString());
    }
    return parts.isEmpty ? '-' : parts.join(', ');
  }

  bool _hasTags() {
    // Check if we have tags from API or widget
    final apiTags = widget.studentProfile?.regularSchedules;
    final widgetTags = widget.tags;
    
    // For now, API doesn't have tags field, so check widget tags
    // If API has tags in future, check that first
    return widgetTags.isNotEmpty;
  }

  List<String> _getTagsList() {
    // Return tags from widget (API doesn't have tags field yet)
    return widget.tags;
  }

  Widget _buildUpcomingMove() {
    final upcomingMoveDate = widget.studentProfile?.importantDates?.upcomingMoveDate;
    
    if (upcomingMoveDate == null || upcomingMoveDate.isEmpty) {
      // Show "-" in ProfileField format to preserve UI
      return ProfileField(
        label: 'Upcoming move',
        value: '-',
        isStudentStyle: true,
      );
    }

    try {
      final date = DateTime.parse(upcomingMoveDate);
      final month = DateFormat('MMM').format(date);
      final day = DateFormat('dd').format(date);
      
      // Get current and next class from API if available
      final currentClass = widget.studentProfile?.classroom ?? widget.classroom;
      final nextClass = widget.studentProfile?.classroom ?? '-'; // API doesn't provide next class yet
      
      return UpcomingMoveWidget(
        month: month,
        day: day,
        currentClass: currentClass.isNotEmpty ? currentClass : '-',
        nextClass: nextClass.isNotEmpty ? nextClass : '-',
      );
    } catch (e) {
      // If date parsing fails, show "-"
      return ProfileField(
        label: 'Upcoming move',
        value: '-',
        isStudentStyle: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: () async {
        await widget.onRefresh?.call();
      },
      child: ProfileInfoCard(
        cardType: 'student',
        title: 'Profile Information',
        scrollController: widget.scrollController,
        studentFirstField:
            ProfileField(label: 'Name', value: widget.name, isStudentStyle: true),
        onEdit: () {
        if (widget.studentProfile == null) return;
        
        final profile = widget.studentProfile!;
        
        // Map status from API format (ACTIVE) to display format (Active)
        String statusDisplay = 'Active';
        final upperStatus = profile.status.toUpperCase();
        if (upperStatus == 'ACTIVE' || profile.status == 'A') {
          statusDisplay = 'Active';
        } else if (upperStatus == 'INACTIVE' || profile.status == 'I') {
          statusDisplay = 'Inactive';
        } else if (profile.status == 'Upcoming') {
          statusDisplay = 'Upcoming';
        } else if (upperStatus == 'WAITLIST') {
          statusDisplay = 'Waitlist';
        } else if (upperStatus == 'GRADUATED') {
          statusDisplay = 'Graduated';
        }
        
        // Parse birth date
        DateTime? birthDate;
        if (profile.dob != null && profile.dob!.isNotEmpty) {
          try {
            birthDate = DateTime.parse(profile.dob!);
          } catch (e) {
            birthDate = null;
          }
        }
        
        // Extract address fields
        final address = profile.address;
        final street = address?['street']?.toString() ?? '';
        final city = address?['city']?.toString() ?? '';
        final state = address?['state']?.toString() ?? '';
        final country = address?['country']?.toString() ?? '';
        final zipCode = address?['zipCode']?.toString() ?? address?['postalCode']?.toString() ?? '';
        
        // Extract tags (from widget tags for now)
        final tags = widget.tags.isNotEmpty
            ? List<String>.from(widget.tags)
            : const <String>[];
        
        // Extract siblings (from siblings map if available)
        final siblings = <String>[];
        if (profile.siblings != null) {
          // Assuming siblings is a map, extract names or codes
          // Adjust based on actual structure
          siblings.addAll([]); // TODO: Extract from siblings map structure
        }
        
        // Extract legal custodians
        final legalCustodians = <String>[];
        if (profile.legalCustodians.isNotEmpty) {
          for (final custodian in profile.legalCustodians) {
            if (custodian is String) {
              legalCustodians.add(custodian);
            } else if (custodian is Map) {
              // Extract name or code from map
              final name = custodian['name']?.toString() ?? custodian['code']?.toString() ?? '';
              if (name.isNotEmpty) legalCustodians.add(name);
            }
          }
        }
        
        ClassroomCubit? classroomCubit;
        try {
          classroomCubit = context.read<ClassroomCubit>();
        } catch (_) {
          classroomCubit = null;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              final screen = EditStudentProfileDetailsScreen(
                studentCode: profile.code,
                initialFirstName: profile.firstName,
                initialLastName: profile.lastName,
                initialStatus: statusDisplay,
                initialClassroom: profile.classroom ?? '',
                initialBirthDate: birthDate,
                initialNotes: profile.notes ?? '',
                initialFTE: profile.fte ?? '',
                initialStreet: street,
                initialCity: city,
                initialState: state,
                initialCountry: country,
                initialZipCode: zipCode,
                initialTags: tags,
                initialSiblings: siblings,
                initialLegalCustodians: legalCustodians,
                initialSubsidy: profile.subsidy,
              );

              // Preserve already-loaded classrooms when available; otherwise load fresh.
              if (classroomCubit != null) {
                return BlocProvider.value(value: classroomCubit, child: screen);
              }
              return BlocProvider(
                create: (_) => serviceLocator<ClassroomCubit>()..loadActiveClassrooms(),
                child: screen,
              );
            },
          ),
        );
      },
      children: [

        ProfileField(
          label: 'Status',
          valueWidget: _buildStatusChip(
            widget.studentProfile?.status ?? 'A',
          ),
          isStudentStyle: true,
        ),

        ProfileField(
          label: 'Classroom',
          value: _getValueOrDash(
            widget.studentProfile?.classroom ?? widget.classroom,
          ),
          isStudentStyle: true,
        ),

        ProfileField(
          label: 'Tags',
          valueWidget: _hasTags()
              ? _tags(tags: _getTagsList())
              : Text(
                  '-',
                  style: AppTextStyles.value.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.03 * 15,
                  ),
                ),
          isStudentStyle: true,
        ),

        ProfileField(
          label: 'Gender',
          value: '-',
          isStudentStyle: true,
        ),

        ProfileField(
          label: 'Birth Date',
          value: _formatDate(widget.studentProfile?.dob),
          isStudentStyle: true,
        ),

        ProfileField(
          label: 'Notes',
          value: _getValueOrDash(widget.studentProfile?.notes),
          isStudentStyle: true,
        ),

        ProfileField(
          label: 'Child Custody',
          value: "Child custody not selected",
          isStudentStyle: true,
        ),

        ProfileField(
          label: 'State Subsidy',
          value: widget.studentProfile != null
              ? (widget.studentProfile!.subsidy ? 'Yes' : 'No')
              : '-',
          isStudentStyle: true,
        ),

        if ((widget.sibling['name'] as List?)?.isNotEmpty == true)
          ProfileField(
            label: (widget.sibling['name'] as List).length == 1 ? 'Sibling' : 'Siblings',
            valueWidget: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (widget.sibling['name'] as List).asMap().entries.map((entry) {
                final index = entry.key;
                final name = widget.sibling['name'][index] as String;
                final relation = widget.sibling['relation'][index] as String;
                final status = widget.sibling['status'][index] as String;

                final color = status == 'upcoming'
                    ? const Color.fromARGB(255, 253, 205, 22)
                    : status == 'signedIn'
                    ? const Color.fromRGBO(0, 177, 21, 1)
                    : status == 'isAbsent'
                    ? const Color.fromRGBO(200, 32, 32, 1)
                    : Colors.white;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          DocumentImageWidget(
                            fileUuid: '',
                            name: name,
                            size: 45,
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$name ($relation)',
                        style: AppTextStyles.value.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.03 * 16,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            isStudentStyle: true,
          ),

        ProfileField(
          label: 'Address',
          value: widget.studentProfile?.address != null
              ? _formatAddress(widget.studentProfile!.address!)
              : '-',
          isStudentStyle: true,
        ),

        ProfileField(
          label: 'Schedule',
          valueWidget: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                  ].map((fullDay) {
                    const dayMap = {
                      'Monday': 'Mon',
                      'Tuesday': 'Tue',
                      'Wednesday': 'Wed',
                      'Thursday': 'Thu',
                      'Friday': 'Fri',
                    };
                    final shortDay = dayMap[fullDay]!;
                    final isAvailable = widget.schedule.contains(shortDay);
                    final timeText = '07:00AM–05:30PM';

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ScheduleChip(
                          width: 110,
                          label: fullDay,
                          labelColor: isAvailable
                              ? const Color.fromRGBO(27, 35, 126, 1)
                              : Colors.grey.shade700,
                          color: isAvailable
                              ? const Color(0x4DB1AFE9)
                              : const Color(0xFFF3F4FB),
                        ),
                        if (isAvailable) ...[
                          const SizedBox(height: 6),
                          _ScheduleChip(
                            width: 110,
                            label: timeText,
                            labelColor: const Color.fromRGBO(27, 35, 126, 1),
                            color: Colors.transparent,
                            isTimeChip: true,
                          ),
                        ],
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          isStudentStyle: true,
        ),

        ProfileField(
          label: 'School leaving Date',
          value: _formatDate(
            widget.studentProfile?.importantDates?.schoolLeavingDate,
          ),
          isStudentStyle: true,
        ),

        _buildUpcomingMove(),
      ],
      ),
    );
    // this was before using the reusable widget
    // return SingleChildScrollView(
    //   controller: widget.scrollController,
    //   child: Container(
    //     width: double.infinity,
    //     padding: const EdgeInsets.all(16),
    //     decoration: BoxDecoration(
    //       border: Border.all(color: AppColors.themeColor),
    //       borderRadius: const BorderRadius.only(
    //         topRight: Radius.circular(8),
    //         bottomLeft: Radius.circular(8),
    //         bottomRight: Radius.circular(8)
    //       ),
    //       color: Colors.white,
    //     ),
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         const SizedBox(height: 8),
    //         Row(
    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //           children: [
    //             _Field(label: 'Name', value: widget.name),
    //             GestureDetector(
    //               onTap: () {
    //                 Navigator.push(
    //                   context,
    //                   MaterialPageRoute(
    //                     builder: (context) => const EditStudentProfileDetailsScreen(
    //                       initialFirstName: 'Jessica',
    //                       initialLastName: 'Rhodes',
    //                       initialStatus: 'Active',
    //                       initialClassroom: '1-Blue D X',
    //                       initialBirthDate: null,
    //                       initialNotes: '',
    //                       initialFTE: '80',
    //                       initialStreet: '',
    //                       initialCity: '',
    //                       initialState: 'New Hampshire',
    //                       initialCountry: 'United States',
    //                       initialZipCode: '',
    //                     ),
    //                   ),
    //                 );
    //               },
    //               child: Container(
    //                 width: 38,
    //                 height: 38,
    //                 decoration: BoxDecoration(
    //                   gradient: AppColors.buildPrimaryGradient(),
    //                   borderRadius: BorderRadius.circular(8),
    //                 ),
    //                 alignment: Alignment.center,
    //                 child: const Icon(
    //                   Icons.edit,
    //                   size: 22,
    //                   color: Colors.white,
    //                 ),
    //               ),
    //             ),
    //           ],
    //         ),
    //         const SizedBox(height: 16),
    //         _Field(
    //           label: 'Status',
    //           value: null,
    //           trailing: _buildStatusChip('A'),
    //         ),
    //         const SizedBox(height: 16),
    //         _Field(label: 'Classroom', value: widget.classroom),
    //         const SizedBox(height: 16),
    //         _Field(label: 'Tags', value:null, trailing: _tags(tags: widget.tags,),),
    //         const SizedBox(height: 16),
    //         _Field(
    //             label: 'Gender',
    //             value: 'Male/Female'),
    //         const SizedBox(height: 16),
    //         _Field(
    //           label: 'Birth Date',
    //           value: 'Oct 29, 2001'),
    //         const SizedBox(height: 16),
    //         _Field(label: 'Notes', value: "- -"),
    //         const SizedBox(height: 16),
    //         _Field(label: 'Child Custody', value: "Child custody not selected"),
    //         const SizedBox(height: 16),
    //         _Field(label: 'State Subsidy', value: "No state subsidy"),
    //         if ((widget.sibling['name'] as List?)?.isNotEmpty == true) ...[
    //           const SizedBox(height: 16),
    //           _Field(
    //             label: (widget.sibling['name'] as List).length == 1 ? 'Sibling' : 'Siblings',
    //             value: null,
    //             trailing: Column(
    //               mainAxisSize: MainAxisSize.min,
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               children: (widget.sibling['name'] as List).asMap().entries.map((entry) {
    //                 final index = entry.key;
    //                 final name = widget.sibling['name'][index] as String;
    //                 final relation = widget.sibling['relation'][index] as String;
    //                 final status = widget.sibling['status'][index] as String;
    //
    //                 final color = status == 'upcoming'
    //                       ? const Color.fromARGB(255, 253, 205, 22)
    //                           : status == 'signedIn'
    //                       ? const Color.fromRGBO(0, 177, 21, 1)
    //                           : status == 'isAbsent'
    //                       ? const Color.fromRGBO(200, 32, 32, 1)
    //                           : Colors.white;
    //
    //                 return Padding(
    //                     padding: EdgeInsets.only(bottom: 12),
    //                     child: Row(
    //                       children: [
    //                         Stack(
    //                           children: [
    //                             DocumentImageWidget(
    //                               fileUuid: '',
    //                               name: name,
    //                               size: 45,
    //                             ),
    //                             Positioned(
    //                               right: 0,
    //                               top: 0,
    //                               child: Container(
    //                                 width: 12,
    //                                 height: 12,
    //                                 decoration: BoxDecoration(
    //                                   color: color,
    //                                   shape: BoxShape.circle,
    //                                   border: Border.all(color: Colors.white, width: 2),
    //                                 ),
    //                               ),
    //                             ),
    //                           ],
    //                         ),
    //                         const SizedBox(width: 12),
    //                         Text(
    //                           '$name ($relation)',
    //                           style: const TextStyle(
    //                             fontFamily: 'Manrope',
    //                             fontSize: 16,
    //                             color: Color(0xff573353),
    //                             fontWeight: FontWeight.w600,
    //                             letterSpacing: -0.03 * 16,
    //                           ),
    //                         ),
    //                       ],
    //                     ),
    //                 );
    //
    //               }).toList(),
    //             ),
    //
    //           ),
    //         ],
    //         const SizedBox(height: 16),
    //         _Field(
    //           label: 'Address',
    //           value: ('12, East Dunstable road, Nashua, NH, USA,\n03062'),
    //         ),
    //         const SizedBox(height: 16),
    //         _Field(
    //           label: 'Schedule',
    //           value: null,
    //           trailing: Row(
    //             children: [
    //               Expanded(
    //                 child: Wrap(
    //                   spacing: 8,
    //                   runSpacing: 8,
    //                   children: [
    //                     'Monday',
    //                     'Tuesday',
    //                     'Wednesday',
    //                     'Thursday',
    //                     'Friday',
    //                   ].map((fullDay) {
    //                     const dayMap = {
    //                       'Monday': 'Mon',
    //                       'Tuesday': 'Tue',
    //                       'Wednesday': 'Wed',
    //                       'Thursday': 'Thu',
    //                       'Friday': 'Fri',
    //                     };
    //
    //                     final shortDay = dayMap[fullDay]!;
    //                     final isAvailable = widget.schedule.contains(shortDay);
    //                     final timeText = '07:00AM–05:30PM'; // get the data from backend later
    //
    //                     return Column(
    //                       mainAxisSize: MainAxisSize.min,
    //                       children: [
    //                         _ScheduleChip(
    //                           width: 110,
    //                           label: fullDay,
    //                           labelColor: isAvailable
    //                               ? const Color.fromRGBO(27, 35, 126, 1)
    //                               : Colors.grey.shade700,
    //                           color: isAvailable
    //                               ? const Color(0x4DB1AFE9)
    //                               : const Color(0xFFF3F4FB),
    //                         ),
    //                         if (isAvailable) ...[
    //                           const SizedBox(height: 6),
    //                           _ScheduleChip(
    //                             width: 110,
    //                             label: timeText,
    //                             labelColor: const Color.fromRGBO(27, 35, 126, 1),
    //                             color: Colors.transparent,
    //                             isTimeChip: true,
    //                           ),
    //                         ],
    //                       ],
    //                     );
    //                   }).toList(),
    //                 ),
    //               ),
    //             ],
    //           ),
    //         ),
    //         const SizedBox(height: 16),
    //         _Field(
    //             label: 'School leaving Date',
    //             value: 'Oct 29, 2001'),
    //         const SizedBox(height: 16),
    //         UpcomingMoveWidget(month: 'Oct', day: '29', currentClass: '1-Blue-D', nextClass: '2-Green-D ')
    //         // _Field(
    //         //     label: 'Upcoming move',
    //         //     value: 'Oct 29, 2001')
    //       ],
    //     ),
    //   ),
    // );
  }

  Widget _buildStatusChip(String status) {
    final upperStatus = status.toUpperCase();
    final label = upperStatus == 'ACTIVE' || status == 'A'
        ? 'Active'
        : upperStatus == 'INACTIVE' || status == 'I'
        ? 'Inactive'
        : status == 'Upcoming'
        ? 'Upcoming'
        : 'Active';
    final labelColor = upperStatus == 'ACTIVE' || status == 'A'
        ? const Color.fromRGBO(56, 200, 32, 1)
        : status == 'Upcoming'
        ? const Color.fromARGB(255, 238, 223, 8)
        : const Color.fromRGBO(250, 65, 65, 1);
    final bgColor = upperStatus == 'ACTIVE' || status == 'A'
        ? const Color.fromRGBO(56, 200, 32, 0.1)
        : status == 'Upcoming'
        ? const Color.fromARGB(255, 242, 238, 176)
        : const Color.fromRGBO(250, 65, 65, 0.1);
    final icon = upperStatus == 'ACTIVE' || status == 'A'
        ? SvgPicture.asset(MediaRes.checkMarkIcon, height: 18)
        : null;

    return _Chip(
      label: label,
      labelColor: labelColor,
      color: bgColor,
      icon: icon,
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, this.value, this.trailing});
  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.value.copyWith(
            fontSize: 14,
            letterSpacing: -0.03 * 14,
            fontWeight: FontWeight.w400,
            color: AppColors.primaryColor.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 6),
        if (trailing == null)
          Text(
            value ?? '- -',
            style: AppTextStyles.value.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.03 * 15,
            ),
          )
        else
          trailing!,
      ],
    );
  }
}

class _tags extends StatelessWidget {
  const _tags({required this.tags});
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    // Use actual tags, don't show placeholder if empty
    final tagList = tags;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (tagList.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x4DB1AFE9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tagList[0],
              style: AppTextStyles.sectionHeader.copyWith(
                color: AppColors.secondaryColor.withOpacity(0.7),
              ),
            ),
          ),
        if (tagList.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x66CBF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tagList[1],
              style: AppTextStyles.sectionHeader.copyWith(
                color: AppColors.secondaryColor.withOpacity(0.7),
              ),
            ),
          ),
        if (tagList.length > 2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x66D9FFCB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tagList[1],
              style: AppTextStyles.sectionHeader.copyWith(
                color: AppColors.secondaryColor,
              ),
            ),
          ),
        // Tooltip(
        //   message: 'Edit tags',
        //   child: Container(
        //     padding: const EdgeInsets.symmetric(
        //       horizontal: 10,
        //       vertical: 4,
        //     ),
        //     decoration: BoxDecoration(
        //       color: Colors.transparent,
        //       borderRadius:
        //       BorderRadius.circular(8),
        //     ),
        //     child: Icon(
        //       Icons.mode_edit_outline_outlined,
        //       color: const Color(0xFFCECECE),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}

class _ScheduleChip extends StatelessWidget {
  const _ScheduleChip({
    required this.label,
    required this.labelColor,
    required this.color,
    required this.width,
    this.isTimeChip = false, // now required
  });

  final String label;
  final Color labelColor;
  final Color color;
  final double width;
  final bool isTimeChip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: isTimeChip
            ? Border.all(color: const Color(0x4DB1AFE9), width: 1.5)
            : null,
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            //child: FittedBox(
            //fit: isTimeChip ? BoxFit.contain : BoxFit.scaleDown, // scales down if too big, never overflows
            child: Text(
              label,
              style: AppTextStyles.value.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: labelColor,
              ),
              textAlign: TextAlign.center,
              maxLines: isTimeChip ? 2 : 1,
              overflow: TextOverflow.visible,
            ),
          ),
          //),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.labelColor,
    required this.color,
    this.icon,
  });
  final String label;
  final Color labelColor;
  final Color color;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 6)],
          Text(
            label,
            style: AppTextStyles.value.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
