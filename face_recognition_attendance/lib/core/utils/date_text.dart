import 'package:get/get.dart';

/// Small date/time text helpers with multilingual support (Khmer and English).
class DateText {
  DateText._();

  static bool get _isKhmer => Get.locale?.languageCode == 'km';

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _kmWeekdays = [
    'ច័ន្ទ',
    'អង្គារ',
    'ពុធ',
    'ព្រហស្បតិ៍',
    'សុក្រ',
    'សៅរ៍',
    'អាទិត្យ',
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

  static const List<String> _kmMonths = [
    'មករា',
    'កុម្ភៈ',
    'មីនា',
    'មេសា',
    'ឧសភា',
    'មិថុនា',
    'កក្កដា',
    'សីហា',
    'កញ្ញា',
    'តុលា',
    'វិច្ឆិកា',
    'ធ្នូ',
  ];

  /// Cambodia timezone is Indochina Time (ICT, UTC+7), with no daylight saving time.
  static const Duration cambodiaOffset = Duration(hours: 7);

  /// Converts any [DateTime] into a Cambodia wall-clock [DateTime] (UTC+7).
  static DateTime toCambodia(DateTime d) {
    final utc = d.toUtc().add(cambodiaOffset);
    return DateTime(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
      utc.millisecond,
      utc.microsecond,
    );
  }

  /// Parses an ISO-8601 string or date string directly into Cambodia wall-clock [DateTime].
  static DateTime parseCambodia(String isoString) {
    final parsed = DateTime.parse(isoString);
    return toCambodia(parsed);
  }

  /// Returns current wall-clock date and time in Cambodia (UTC+7).
  static DateTime nowCambodia() => toCambodia(DateTime.now());

  static String _two(int value) => value.toString().padLeft(2, '0');

  static int _hour12(DateTime d) => d.hour % 12 == 0 ? 12 : d.hour % 12;

  static String _period(DateTime d) {
    if (_isKhmer) {
      return d.hour < 12 ? 'ព្រឹក' : 'រសៀល';
    }
    return d.hour < 12 ? 'AM' : 'PM';
  }

  /// Month name (month is 1-12)
  static String monthName(int month) {
    if (month < 1 || month > 12) return '';
    return _isKhmer ? _kmMonths[month - 1] : _months[month - 1];
  }

  /// 2026-09-07
  static String ymd(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  /// Monday or ថ្ងៃច័ន្ទ
  static String weekday(DateTime d) {
    final idx = d.weekday - 1;
    if (idx < 0 || idx >= 7) return '';
    return _isKhmer ? 'ថ្ងៃ${_kmWeekdays[idx]}' : _weekdays[idx];
  }

  /// Mon or ច័ន្ទ
  static String weekdayShort(int weekday) {
    final idx = weekday - 1;
    if (idx < 0 || idx >= 7) return '';
    return _isKhmer ? _kmWeekdays[idx] : _weekdays[idx].substring(0, 3);
  }

  /// September 2026 or ខែកញ្ញា ឆ្នាំ2026
  static String monthYear(DateTime d) {
    if (_isKhmer) {
      return 'ខែ${_kmMonths[d.month - 1]} ឆ្នាំ${d.year}';
    }
    return '${_months[d.month - 1]} ${d.year}';
  }

  /// Monday 2026-09-07
  static String weekdayYmd(DateTime d) => '${weekday(d)} ${ymd(d)}';

  /// Tuesday, September 26 or ថ្ងៃអង្គារ ទី26 ខែកញ្ញា
  static String fullDate(DateTime d) {
    if (_isKhmer) {
      return 'ថ្ងៃ${_kmWeekdays[d.weekday - 1]} ទី${d.day} ខែ${_kmMonths[d.month - 1]}';
    }
    return '${weekday(d)}, ${_months[d.month - 1]} ${d.day}';
  }

  /// 08 : 52 PM or 08 : 52 រសៀល
  static String clock(DateTime d) =>
      '${_two(_hour12(d))} : ${_two(d.minute)} ${_period(d)}';

  /// 05:00 PM or 05:00 រសៀល
  static String time(DateTime d) =>
      '${_two(_hour12(d))}:${_two(d.minute)} ${_period(d)}';

  /// Fri Sep 11 2026
  static String monthShortDay(DateTime d) {
    if (_isKhmer) {
      return '${_kmWeekdays[d.weekday - 1]} ${_kmMonths[d.month - 1]} ${_two(d.day)} ${d.year}';
    }
    return '${_weekdays[d.weekday - 1].substring(0, 3)} ${_months[d.month - 1].substring(0, 3)} ${_two(d.day)} ${d.year}';
  }

  /// 6/8/2026 7 : 43 : 11 AM
  static String stamp(DateTime d) =>
      '${d.month}/${d.day}/${d.year} ${_hour12(d)} : ${_two(d.minute)} : ${_two(d.second)} ${_period(d)}';
}
