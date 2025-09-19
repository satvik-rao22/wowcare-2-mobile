import '../Student-Module-Models/student_data_model.dart';

class StudentRepository {
  Future<List<StudentDataModel>> getStudentById(int id) async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    return [StudentDataModel.demo];
  }

  Future<List<Document>> getDocuments(int studentId, int schoolId) async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    return [Document.demo];
  }

  Future<List<GuardianEntity>> getGuardians(int studentId, int schoolId) async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    return [GuardianEntity.demo];
  }

  Future<List<Staff>> getStaff(int roomId, int schoolId) async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    return [Staff.demo];
  }

  Future<List<PhysiciansEntity>> getPhysicians(
    int studentId,
    int schoolId,
  ) async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    return [PhysiciansEntity.demo];
  }

  Future<List<PhysicalTrackerEntity>> getPhysicalTrackers(
    int studentId,
    int schoolId,
  ) async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    return [PhysicalTrackerEntity.demo];
  }

  Future<List<ImmunizationEntity>> getImmunizations(
    int studentId,
    int schoolId,
  ) async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    return [ImmunizationEntity.demo];
  }

  Future<List<VaccineEntity>> getVaccines(int studentId, int schoolId) async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    return [VaccineEntity.demo];
  }

  Future<List<ScheduleDoseEntity>> getScheduleDoses(
    int studentId,
    int schoolId,
  ) async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    return [ScheduleDoseEntity.demo];
  }

  Future<Future<List<Staff>>> getStaffByRoomId(int roomId, int schoolId) async {
    throw UnimplementedError();
  }
}

class Document {
  final String documentId;
  final String name;

  const Document({required this.documentId, required this.name});

  static const empty = Document(documentId: '', name: '');

  static const demo = Document(documentId: 'DOC001', name: 'Birth Certificate');
}

class GuardianEntity {
  final int id;
  final String fullName;
  final String relation;
  final String email;
  final String phoneNumber;
  final int signInPin;
  final String photoUuid;

  const GuardianEntity({
    required this.id,
    required this.fullName,
    required this.relation,
    required this.email,
    required this.phoneNumber,
    required this.signInPin,
    required this.photoUuid,
  });

  static const empty = GuardianEntity(
    id: 0,
    fullName: '',
    relation: '',
    email: '',
    phoneNumber: '',
    signInPin: 0,
    photoUuid: '',
  );

  static const demo = GuardianEntity(
    id: 1,
    fullName: 'Jane Doe',
    relation: 'Mother',
    email: 'jane.doe@example.com',
    phoneNumber: '123-456-7890',
    signInPin: 1234,
    photoUuid: 'photo-uuid-guardian1',
  );
}

class Staff {
  final int id;
  final String name;

  const Staff({required this.id, required this.name});

  static const empty = Staff(id: 0, name: '');

  static const demo = Staff(id: 101, name: 'Teacher Jane');
}

class PhysiciansEntity {
  final int id;
  final String name;

  const PhysiciansEntity({required this.id, required this.name});

  static const empty = PhysiciansEntity(id: 0, name: '');

  static const demo = PhysiciansEntity(id: 201, name: 'Dr. Smith');
}

class PhysicalTrackerEntity {
  final int id;
  final String type;
  final String value;

  const PhysicalTrackerEntity({
    required this.id,
    required this.type,
    required this.value,
  });

  static const empty = PhysicalTrackerEntity(id: 0, type: '', value: '');

  static const demo = PhysicalTrackerEntity(
    id: 301,
    type: 'Height',
    value: '120 cm',
  );
}

class ImmunizationEntity {
  final int id;
  final String name;

  const ImmunizationEntity({required this.id, required this.name});

  static const empty = ImmunizationEntity(id: 0, name: '');

  static const demo = ImmunizationEntity(id: 401, name: 'MMR Vaccine');
}

class VaccineEntity {
  final int id;
  final String name;

  const VaccineEntity({required this.id, required this.name});

  static const empty = VaccineEntity(id: 0, name: '');

  static const demo = VaccineEntity(id: 501, name: 'Polio Vaccine');
}

class ScheduleDoseEntity {
  final int id;
  final String date;

  const ScheduleDoseEntity({required this.id, required this.date});

  static const empty = ScheduleDoseEntity(id: 0, date: '');

  static const demo = ScheduleDoseEntity(id: 601, date: '2025-09-18');
}
