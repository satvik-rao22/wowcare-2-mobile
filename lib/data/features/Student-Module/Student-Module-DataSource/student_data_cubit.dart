import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/features/Student-Module/entities/Student-Entity.dart';
import '../Student-Module-Models/student_view_model.dart';
import '../Students-Modeule-Repository/student_repository.dart';

abstract class StudentDataState {}

class StudentDataInitial extends StudentDataState {}

class GettingAllStudentsData extends StudentDataState {}

class AllStudentsDataLoaded extends StudentDataState {
  final List<StudentEntity> students;
  AllStudentsDataLoaded(this.students);
}

class StudentDataError extends StudentDataState {
  final String message;
  StudentDataError(this.message);
}

class GettingAllDocuments extends StudentDataState {}

class AllDocumentsLoaded extends StudentDataState {
  final List<Document> documents;
  AllDocumentsLoaded(this.documents);
}

class DocumentError extends StudentDataState {
  final String message;
  DocumentError(this.message);
}

class GettingAllPhysicians extends StudentDataState {}

class AllPhysiciansDataLoaded extends StudentDataState {
  final List<PhysiciansEntity> physicians;
  AllPhysiciansDataLoaded(this.physicians);
}

class PhysiciansError extends StudentDataState {
  final String message;
  PhysiciansError(this.message);
}

class GettingAllPhysicalTrackerData extends StudentDataState {}

class AllPhysicalTrackerDataLoaded extends StudentDataState {
  final List<PhysicalTrackerEntity> physicalTrackers;
  AllPhysicalTrackerDataLoaded(this.physicalTrackers);
}

class PhysicalTrackerError extends StudentDataState {
  final String message;
  PhysicalTrackerError(this.message);
}

class GettingAllImmunizations extends StudentDataState {}

// class AllImmunizationLoaded extends StudentDataState {
//   final List<ImmunizationEntity> immunizationEntity;
//   AllImmunizationLoaded(this.immunizationEntity);
// }

class ImmunizationError extends StudentDataState {
  final String message;
  ImmunizationError(this.message);
}

class GettingAllVaccines extends StudentDataState {}

// class AllVaccineLoaded extends StudentDataState {
//   final List<VaccineEntity> vaccines;
//   AllVaccineLoaded(this.vaccines);
// }

class VaccineError extends StudentDataState {
  final String message;
  VaccineError(this.message);
}

class GettingAllScheduleDoses extends StudentDataState {}

// class AllScheduleDosesLoaded extends StudentDataState {
//   final List<ScheduleDoseEntity> scheduleDoses;
//   AllScheduleDosesLoaded(this.scheduleDoses);
// }

class ScheduleDoseError extends StudentDataState {
  final String message;
  ScheduleDoseError(this.message);
}

class StudentDataCubit extends Cubit<StudentDataState> {
  final StudentViewModel _viewModel;

  StudentDataCubit(this._viewModel) : super(StudentDataInitial());

  Future<void> getAllStudents(int id) async {
    try {
      emit(GettingAllStudentsData());
      final students = await _viewModel.getStudent(id);
      emit(AllStudentsDataLoaded(students));
    } catch (e) {
      emit(StudentDataError(e.toString()));
    }
  }

  Future<void> getAllDocuments(int studentId, int schoolId) async {
    try {
      emit(GettingAllDocuments());
      final documents = await _viewModel.getDocuments(studentId, schoolId);
      emit(AllDocumentsLoaded(documents));
    } catch (e) {
      emit(DocumentError(e.toString()));
    }
  }

  Future<void> getAllPhysicians(int studentId, int schoolId) async {
    try {
      emit(GettingAllPhysicians());
      final physicians = await _viewModel.getPhysicians(studentId, schoolId);
      emit(AllPhysiciansDataLoaded(physicians));
    } catch (e) {
      emit(PhysiciansError(e.toString()));
    }
  }

  Future<void> getAllPhysicalTrackerData(int studentId, int schoolId) async {
    try {
      emit(GettingAllPhysicalTrackerData());
      final trackers = await _viewModel.getPhysicalTrackers(
        studentId,
        schoolId,
      );
      emit(AllPhysicalTrackerDataLoaded(trackers));
    } catch (e) {
      emit(PhysicalTrackerError(e.toString()));
    }
  }

  Future<void> getAllImmunizations(int studentId, int schoolId) async {
    try {
      emit(GettingAllImmunizations());
      final immunizations = await _viewModel.getImmunizations(
        studentId,
        schoolId,
      );
      // emit(AllImmunizationLoaded(immunizations));
    } catch (e) {
      emit(ImmunizationError(e.toString()));
    }
  }

  Future<void> getAllVaccines(int studentId, int schoolId) async {
    try {
      emit(GettingAllVaccines());
      final vaccines = await _viewModel.getVaccines(studentId, schoolId);
      // emit(AllVaccineLoaded(vaccines));
    } catch (e) {
      emit(VaccineError(e.toString()));
    }
  }

  Future<void> getAllScheduleDoses(
    int immunizationId,
    int studentId,
    int schoolId,
  ) async {
    try {
      emit(GettingAllScheduleDoses());
      final doses = await _viewModel.getScheduleDoses(
        immunizationId,
        studentId,
        schoolId,
      );
      // emit(AllScheduleDosesLoaded(doses));
    } catch (e) {
      emit(ScheduleDoseError(e.toString()));
    }
  }
}
