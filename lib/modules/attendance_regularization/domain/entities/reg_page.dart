/// One page of `GET /`.
class RegPage<T> {
  const RegPage({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
    required this.hasMore,
  });

  const RegPage.empty()
      : items = const [],
        page = 0,
        size = 0,
        total = 0,
        hasMore = false;

  final List<T> items;
  final int page;
  final int size;
  final int total;

  /// The server's `hasNext`.
  final bool hasMore;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  int get nextPage => page + 1;

  RegPage<T> append(RegPage<T> next) => RegPage<T>(
        items: [...items, ...next.items],
        page: next.page,
        size: next.size,
        total: next.total,
        hasMore: next.hasMore,
      );

  RegPage<T> withItems(List<T> newItems) => RegPage<T>(
        items: newItems,
        page: page,
        size: size,
        total: total,
        hasMore: hasMore,
      );
}
