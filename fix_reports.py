import os
import re

files = [
    "lib/presentation/features/reports/view/student_absent_report_screen.dart",
    "lib/presentation/features/reports/view/student_attendance_per_student_report_screen.dart",
    "lib/presentation/features/reports/view/student_daily_attendance_report_screen.dart",
    "lib/presentation/features/reports/view/student_emergency_contact_report_screen.dart",
    "lib/presentation/features/reports/view/student_immunization_report_screen.dart",
    "lib/presentation/features/reports/view/student_incident_report_screen.dart",
    "lib/presentation/features/reports/view/students_and_family_report_screen.dart",
    "lib/presentation/features/reports/view/staff_absent_report_screen.dart",
    "lib/presentation/features/reports/view/staff_attendance_per_week_report_screen.dart",
    "lib/presentation/features/reports/view/staff_details_report_screen.dart",
    "lib/presentation/features/reports/view/staff_schedule_report_screen.dart"
]

for file_path in files:
    with open(file_path, "r") as f:
        content = f.read()

    # 1. Fix initState pre-selection
    # Match: _selectedClassrooms = ValueNotifier<List<String>>(List<String>.from(widget.classrooms));
    content = re.sub(
        r"_selectedClassrooms\s*=\s*ValueNotifier<List<String>>\(\s*List<String>\.from\(widget\.classrooms\),\s*\);",
        "_selectedClassrooms = ValueNotifier<List<String>>([]);",
        content
    )
    # Match: _selectedClassrooms.value = List<String>.from(widget.classrooms);
    content = re.sub(
        r"_selectedClassrooms\.value\s*=\s*List<String>\.from\(widget\.classrooms\);",
        "",
        content
    )
    # Match: _selectedClassrooms = List<String>.from(widget.classrooms);
    # Avoid commenting out lines like `// _selectedClassrooms = List<String>.from(widget.classrooms);`
    content = re.sub(
        r"(?<!// )_selectedClassrooms\s*=\s*List<String>\.from\(widget\.classrooms\);",
        "",
        content
    )
    # 2. Fix resolveReportCodes
    content = re.sub(
        r"names:\s*_selectedClassrooms\.value,",
        "names: _selectedClassrooms.value.isEmpty ? widget.classrooms : _selectedClassrooms.value,",
        content
    )
    content = re.sub(
        r"names:\s*_selectedClassrooms,",
        "names: _selectedClassrooms.isEmpty ? widget.classrooms : _selectedClassrooms,",
        content
    )

    with open(file_path, "w") as f:
        f.write(content)

print("Done")
