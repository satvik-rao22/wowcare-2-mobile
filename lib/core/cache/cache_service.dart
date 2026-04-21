abstract class CacheService {
  Future<void> put<T>(T item);
  Future<void> putAll<T>(List<T> items);
  Future<T?> get<T>(dynamic id);
  Future<List<T>> getAll<T>();
  Future<List<T>> getByField<T>(String fieldName, dynamic value);
  Future<void> delete<T>(dynamic id);
  Future<void> clear<T>();
}
