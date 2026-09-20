/// Small date/time text helpers, so the app does not need the `intl` package.
class DateText {
  DateText._();

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String _two(int value) => value.toString().padLeft(2, '0');

  static int _hour12(DateTime d) => d.hour % 12 == 0 ? 12 : d.hour % 12;

  static String _period(DateTime d) => d.hour < 12 ? 'AM' : 'PM';

  /// 2026-09-07
  static String ymd(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  /// Monday
  static String weekday(DateTime d) => _weekdays[d.weekday - 1];

  /// Monday 2026-09-07
  static String weekdayYmd(DateTime d) => '${weekday(d)} ${ymd(d)}';

  /// Tuesday, September 26
  static String fullDate(DateTime d) =>
      '${weekday(d)}, ${_months[d.month - 1]} ${d.day}';

  /// 08 : 52 PM
  static String clock(DateTime d) =>
      '${_two(_hour12(d))} : ${_two(d.minute)} ${_period(d)}';

  /// 6/8/2026 7 : 43 : 11 AM
  static String stamp(DateTime d) =>
      '${d.month}/${d.day}/${d.year} ${_hour12(d)} : ${_two(d.minute)} : ${_two(d.second)} ${_period(d)}';
}
