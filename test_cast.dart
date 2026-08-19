void main() {
  Map<String, int> myMap = {'timestamp': 1234567890};
  try {
    final extra = myMap as Map<String, dynamic>?;
    print('Success: $extra');
  } catch (e) {
    print('Error: $e');
  }
}
