part of 'ratio_monitoring_cubit.dart';

enum RatioMonitoringStatus { initial, loading, loaded, error }

class RatioMonitoringState extends Equatable {
  const RatioMonitoringState({
    required this.status,
    required this.schoolCode,
    required this.classrooms,
    this.errorMessage,
  });

  const RatioMonitoringState.initial()
    : status = RatioMonitoringStatus.initial,
      schoolCode = '',
      classrooms = const [],
      errorMessage = null;

  const RatioMonitoringState.loaded({
    required String schoolCode,
    required List<RatioMonitoringClassroom> classrooms,
  }) : status = RatioMonitoringStatus.loaded,
       schoolCode = schoolCode,
       classrooms = classrooms,
       errorMessage = null;

  final RatioMonitoringStatus status;
  final String schoolCode;
  final List<RatioMonitoringClassroom> classrooms;
  final String? errorMessage;

  bool get isInitial => status == RatioMonitoringStatus.initial;
  bool get isLoading => status == RatioMonitoringStatus.loading;
  bool get isLoaded => status == RatioMonitoringStatus.loaded;
  bool get isError => status == RatioMonitoringStatus.error;

  RatioMonitoringState copyWith({
    RatioMonitoringStatus? status,
    String? schoolCode,
    List<RatioMonitoringClassroom>? classrooms,
    String? errorMessage,
  }) {
    return RatioMonitoringState(
      status: status ?? this.status,
      schoolCode: schoolCode ?? this.schoolCode,
      classrooms: classrooms ?? this.classrooms,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, schoolCode, classrooms, errorMessage];
}
