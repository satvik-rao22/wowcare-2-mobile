import '../../../../domain/features/Student-Module/entities/Student-Entity.dart';
import '../Students-Modeule-Repository/student_repository.dart';

class StudentViewModel {
  final StudentRepository _repository;

  StudentViewModel(this._repository);

  Future<List<StudentEntity>> getStudent(int id) async {
    return await _repository.getStudentById(id);
  }

  Future<List<Document>> getDocuments(int studentId, int schoolId) async {
    return await _repository.getDocuments(studentId, schoolId);
  }

  Future<List<GuardianEntity>> getGuardians(int studentId, int schoolId) async {
    return await _repository.getGuardians(studentId, schoolId);
  }

  Future<List<Staff>> getStaff(int roomId, int schoolId) async {
    return await _repository.getStaffByRoomId(roomId, schoolId);
  }

  Future<List<PhysiciansEntity>> getPhysicians(
    int studentId,
    int schoolId,
  ) async {
    return await _repository.getPhysicians(studentId, schoolId);
  }

  Future<List<PhysicalTrackerEntity>> getPhysicalTrackers(
    int studentId,
    int schoolId,
  ) async {
    return await _repository.getPhysicalTrackers(studentId, schoolId);
  }

  Future<List<ImmunizationEntity>> getImmunizations(
    int studentId,
    int schoolId,
  ) async {
    return await _repository.getImmunizations(studentId, schoolId);
  }

  Future<List<VaccineEntity>> getVaccines(int studentId, int schoolId) async {
    return await _repository.getVaccines(studentId, schoolId);
  }

  Future<List<ScheduleDoseEntity>> getScheduleDoses(
    int immunizationId,
    int studentId,
    int schoolId,
  ) async {
    return await _repository.getScheduleDoses(
      immunizationId,
      studentId,
      // schoolId,
    );
  }
}
