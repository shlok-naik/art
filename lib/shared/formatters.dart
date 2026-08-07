/// Shared display-formatting helpers. These were previously copy-pasted as
/// private helpers in half a dozen screens (feed, posts, projects, league,
/// profile) — keep any new formatting rule here so every context renders the
/// same value the same way.
library;

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "7 August 2026" — the app-wide date style for posts and sessions.
String formatMonthDayYear(DateTime date) =>
    '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

/// [formatMonthDayYear] for a raw row value that may be null or unparseable.
String formatDateValue(dynamic value) {
  if (value == null) return '—';
  final date = DateTime.tryParse(value.toString());
  if (date == null) return value.toString();
  return formatMonthDayYear(date);
}

/// "01:23:45" — elapsed-time format used by the session timer and session
/// lists.
String formatDurationHms(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

/// "1.2K" / "3.4M" count compaction used for views, reactions, followers and
/// post counts.
String formatCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
}
