import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/widgets/selected_student_tile.dart';
import 'package:wowcare/presentation/features/attendance/widgets/upload_photo_video.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class NapStartScreen extends StatefulWidget {
  const NapStartScreen({
    super.key,
    required this.selectedStudents,
    this.isEdit = false
  });
  final List<String> selectedStudents;
  final bool isEdit;

  @override
  State<NapStartScreen> createState() => _NapStartScreenState();
}

class _NapStartScreenState extends State<NapStartScreen> {
  late final List<String> _selectedStudents;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the incoming list
    _selectedStudents = List.from(widget.selectedStudents);
  }

  void _removeStudent(String name) {
    setState(() {
      _selectedStudents.remove(name);

      // If no students left, go back to previous screen
      if (_selectedStudents.isEmpty) {
        Navigator.of(context).pop();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
        body: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalSpacing,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nap',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: responsive.titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff573353),
                  ),
                ),
              ),
            ),
            SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
            Expanded(
                child: Container(
                  width: responsive.containerWidth,
                  margin: EdgeInsets.symmetric(
                      horizontal: responsive.horizontalSpacing
                  ),
                  padding: EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(responsive.isTablet ? 30.0 : 20.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10,),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: responsive.isTablet ? 3 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: responsive.isTablet ? 3.8 : 3.0,
                          ),
                          itemCount: _selectedStudents.length,
                          itemBuilder: (context, index) {
                            final String name = _selectedStudents[index];

                            return SelectedStudentTile(
                              name: name,
                              onTap: () => _removeStudent(name),
                            );
                          },
                        ),
                      ),
                      UploadPhotoVideo()

                    ],
                  ),
                )
            ),
          ],
        )
    );
  }
}
