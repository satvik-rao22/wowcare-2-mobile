import '../repositories/event_repository.dart';

class DeleteEventUseCase {
  DeleteEventUseCase(this._repository);

  final EventRepository _repository;

  Future<void> call(String code) {
    return _repository.deleteEvent(code);
  }
}
