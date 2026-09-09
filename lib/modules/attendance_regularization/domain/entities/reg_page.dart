/// One page of a paginated list (§9.3 staff, §9.5 admin).
///
/// Both list views scroll to load older records, so [hasMore] is what the
/// cubits drive their infinite scroll from rather than each re-deriving it
/// from page arithmetic.
class RegPage<T> {
  const RegPage({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  const RegPage.empty()
      : items = const [],
        page = 0,
        size = 0,
        total = 0;

  final List<T> items;

  /// Zero-based page index, as sent to the API.
  final int page;

  /// Requested page size.
  final int size;

  /// Total matching records across all pages — also what the admin badge
  /// reads from a `size: 1` request.
  final int total;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// True while older records remain to be loaded.
  ///
  /// Guarded on an empty page so a server that reports `total` inconsistently
  /// can never drive an endless "load more" loop.
  bool get hasMore => items.isNotEmpty && (page + 1) * size < total;

  /// The page index to request next.
  int get nextPage => page + 1;

  /// Appends [next]'s items to this page, keeping [next]'s cursor and total.
  /// Used when a cubit loads more rather than replacing the list.
  RegPage<T> append(RegPage<T> next) => RegPage<T>(
        items: [...items, ...next.items],
        page: next.page,
        size: next.size,
        total: next.total,
      );

  /// Replaces the items, keeping the cursor — for reconciling an optimistic
  /// removal or an in-place status change without refetching.
  RegPage<T> withItems(List<T> newItems) => RegPage<T>(
        items: newItems,
        page: page,
        size: size,
        total: total,
      );
}
