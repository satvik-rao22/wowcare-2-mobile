import os
import glob

files = glob.glob('lib/presentation/features/reports/view/*_screen.dart')

target_classroom = """names: _selectedClassrooms.value.isEmpty
          ? widget.classrooms
          : _selectedClassrooms.value,"""
replacement_classroom = """names: (_selectedClassrooms.value.isEmpty
          ? widget.classrooms
          : _selectedClassrooms.value).toSet().toList(),"""

target_student = """names: _selectedStudents.value.isEmpty
          ? widget.students
          : _selectedStudents.value,"""
replacement_student = """names: (_selectedStudents.value.isEmpty
          ? widget.students
          : _selectedStudents.value).toSet().toList(),"""

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    
    new_content = content.replace(target_classroom, replacement_classroom)
    new_content = new_content.replace(target_student, replacement_student)
    
    if new_content != content:
        with open(f, 'w') as file:
            file.write(new_content)
        print(f"Patched {f}")
