import os
import re

files = [
    "lib/presentation/features/reports/view/staff_absent_report_screen.dart",
    "lib/presentation/features/reports/view/staff_details_report_screen.dart",
    "lib/presentation/features/reports/view/staff_attendance_per_week_report_screen.dart",
    "lib/presentation/features/reports/view/staff_schedule_report_screen.dart"
]

for file_path in files:
    with open(file_path, "r") as f:
        content = f.read()

    # Match: _selectedClassrooms.value = List<String>.from(names);
    content = re.sub(
        r"_selectedClassrooms\.value\s*=\s*List<String>\.from\(names\);",
        "_selectedClassrooms.value = <String>[];",
        content
    )
    # Match: _selectedClassrooms = List<String>.from(names);
    content = re.sub(
        r"_selectedClassrooms\s*=\s*List<String>\.from\(names\);",
        "_selectedClassrooms = <String>[];",
        content
    )

    with open(file_path, "w") as f:
        f.write(content)

print("Done")
