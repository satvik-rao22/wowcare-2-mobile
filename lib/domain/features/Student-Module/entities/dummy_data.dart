import 'Student-Entity.dart';

final List<StudentEntity> dummyStudents = [
  StudentEntity.demo,
  StudentEntity.demo.copyWith(
    id: 2,
    fullName: 'Emma Watson',
    studentUniqueId: 'STU002',
    roomName: 'Kindergarten B',
    gender: 'Female',
    bloodGroup: 'B+',
    photoUuid: 'photo-uuid-456',
    allergies: 'None',
    medications: 'Asthma Inhaler',
    dietRestriction: 'Gluten Free',
    profileStatus: 'Upcoming',
  ),
  StudentEntity.demo.copyWith(
    id: 3,
    fullName: 'Liam Johnson',
    studentUniqueId: 'STU003',
    roomName: 'Preschool A',
    gender: 'Male',
    bloodGroup: 'O-',
    photoUuid: 'photo-uuid-789',
    allergies: 'Milk',
    medications: 'None',
    dietRestriction: '',
    profileStatus: 'Active',
  ),
];
