/// Every word M12 Notifications says. Shared vocabulary (Notifications, Try
/// again, the offline banner, "This screen is being rebuilt.") stays in
/// `AppStrings`.
///
/// The module's own rule: a notification is described by what it is about, so
/// nothing here names a role. Students, never children.
abstract final class NotificationsStrings {
  // --- 12a · the center -----------------------------------------------------

  static const String title = 'Notifications';

  static String unread(int n) => n == 1 ? '1 unread' : '$n unread';
  static const String allRead = 'All read';

  static const String markAllRead = 'Mark all as read';
  static const String onlyShowUnread = 'Only Show Unread';

  /// The day bands over the rows.
  static const String today = 'Today';
  static const String yesterday = 'Yesterday';
  static const String earlier = 'Earlier';

  /// The unread dot on a row, for assistive tech.
  static const String unreadRow = 'Unread';

  // --- How old a row is -----------------------------------------------------

  static const String justNow = 'Just now';
  static String minsAgo(int n) => n == 1 ? '1 min ago' : '$n mins ago';
  static String hoursAgo(int n) => n == 1 ? '1 hr ago' : '$n hrs ago';
  static String daysAgo(int n) => n == 1 ? '1 day ago' : '$n days ago';

  // --- 12b · the states -----------------------------------------------------

  static const String loadingFeed = 'Loading your notifications…';
  static const String loadingMore = 'Loading more';

  static const String emptyTitle = "You're all caught up";
  static const String emptyBody = 'No notifications to show';

  static const String filteredEmptyTitle = 'Nothing under that filter';
  static const String filteredEmptyBody = 'Tap All to see everything again';

  static const String errorTitle = "Couldn't load notifications";
  static const String errorBody =
      'The center asked twice and got nothing back. Nothing was lost, so pull '
      'down or try again.';

  /// A push landed while the list was open and the list reloaded itself.
  static const String arrived = 'One arrived while you were reading';

  // --- What a write reports -------------------------------------------------

  static const String markedAllRead = 'Everything is marked as read.';
  static const String markFailed = "That didn't save. Try again.";
}
