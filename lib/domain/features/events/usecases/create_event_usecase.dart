import '../entities/event.dart';
import '../repositories/event_repository.dart';

class CreateEventUseCase {
  CreateEventUseCase(this._repository);

  final EventRepository _repository;

  Future<Event> call(Event event, {List<String> assetCodes = const []}) {
    return _repository.createEvent(event, assetCodes: assetCodes);
  }
}
