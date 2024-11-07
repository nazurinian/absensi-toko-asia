import 'package:intl/intl.dart';

class CustomTime {
  late int _year;
  late int _month;
  late int _day;
  late int _hours;
  late int _minutes;
  late int _seconds;
  late int _weekday;
  late String _dayName;

  CustomTime({
    required int year,
    required int month,
    required int day,
    required int hours,
    required int minutes,
    required int seconds,
    required int weekday,
    required String dayName,
  }) {
    _year = year;
    _month = month;
    _day = day;
    _hours = hours;
    _minutes = minutes;
    _seconds = seconds;
    _weekday = weekday;
    _dayName = dayName;
  }

  // Fungsi untuk get default time phone
  // Function to get the current time in WITA (GMT+8)
  factory CustomTime.getCurrentTime() {
    DateTime now = DateTime.now().toUtc();
    DateTime witaTime = now.add(const Duration(hours: 14, minutes: 90, seconds: 0)); // GMT+8 (WITA)
    String formattedDayName = DateFormat('EEEE', 'id_ID').format(witaTime);
    return CustomTime(
      year: witaTime.year,
      month: witaTime.month,
      day: witaTime.day,
      hours: witaTime.hour,
      minutes: witaTime.minute,
      seconds: witaTime.second,
      weekday: witaTime.weekday,
      dayName: formattedDayName,
    );
  }

  // Function to get the current time in WITA (GMT+8)
  factory CustomTime.getInitialTime() {
    DateTime now = DateTime.now().toUtc();
    DateTime witaTime = now.add(const Duration(hours: 8, minutes: 0)); // GMT+8 (WITA)
    String formattedDayName = DateFormat('EEEE', 'id_ID').format(witaTime);
    return CustomTime(
      year: witaTime.year,
      month: witaTime.month,
      day: witaTime.day,
      hours: witaTime.hour,
      minutes: witaTime.minute,
      seconds: witaTime.second,
      weekday: witaTime.weekday,
      dayName: formattedDayName,
    );
  }

  // Parse server time (UTC) and convert it to local WITA time
  factory CustomTime.fromServerTime(String serverTime) {
    DateTime utcTime = DateTime.parse(serverTime).toUtc();
    DateTime witaTime = utcTime.add(const Duration(hours: 8, minutes: 0)); // GMT+8 (WITA)
    String formattedDayName = DateFormat('EEEE', 'id_ID').format(witaTime);
    return CustomTime(
      year: witaTime.year,
      month: witaTime.month,
      day: witaTime.day,
      hours: witaTime.hour,
      minutes: witaTime.minute,
      seconds: witaTime.second,
      weekday: witaTime.weekday,
      dayName: formattedDayName,
    );
  }

  // Parse NTP server time (UTC) and convert it to local WITA time
  factory CustomTime.fromDateTime(DateTime dateTime) {
    String formattedDayName = DateFormat('EEEE', 'id_ID').format(dateTime);
    return CustomTime(
      year: dateTime.year,
      month: dateTime.month,
      day: dateTime.day,
      hours: dateTime.hour,
      minutes: dateTime.minute,
      seconds: dateTime.second,
      weekday: dateTime.weekday,
      dayName: formattedDayName,
    );
  }

  // Get formatted day name in Indonesian for current time
  String getIdnDayName() {
    return _dayName; // Use the stored day name in Indonesian
  }

  // Get formatted date in Indonesian (dd-MM-yyyy)
  String getIdnDate() {
    DateTime time = DateTime(_year, _month, _day);
    return DateFormat('dd-MM-yyyy', 'id_ID').format(time);
  }

  // Get formatted time in Indonesian (HH:mm:ss)
  String getIdnTime() {
    DateTime time = DateTime(_year, _month, _day, _hours, _minutes, _seconds);
    return DateFormat('HH:mm:ss', 'id_ID').format(time);
  }

  // Get full formatted date and time in Indonesian
  String getIdnAllTime() {
    DateTime time = DateTime(_year, _month, _day, _hours, _minutes, _seconds);
    return DateFormat('EEEE, dd-MM-yyyy | HH:mm:ss', 'id_ID').format(time);
  }

  // Get default date and time
  DateTime getDefaultDateTime() {
    DateTime time = DateTime(_year, _month, _day, _hours, _minutes, _seconds);
    return time;
  }

  // Post time in specific format (yyyy-MM-dd HH:mm:ss)
  String postTime() {
    DateTime time = DateTime(_year, _month, _day, _hours, _minutes, _seconds);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(time);
  }

  // Get formatted time without seconds (yyyy-MM-dd | HH:mm)
  String getFormattedTime() {
    DateTime time = DateTime(_year, _month, _day, _hours, _minutes);
    return DateFormat('yyyy-MM-dd | HH:mm').format(time);
  }

  // Get year and month in format (yyyyMM)
  String getYearMonth() {
    DateTime time = DateTime(_year, _month);
    return DateFormat('yyyyMM').format(time);
  }

  // Get previous month in format (yyyyMM)
  String getLastMonthYearMonth() {
    DateTime time = DateTime(_year, _month);
    DateTime lastMonthDate;

    if (time.month == 1) {
      lastMonthDate = DateTime(time.year - 1, 12);
    } else {
      lastMonthDate = DateTime(time.year, time.month - 1);
    }

    return DateFormat('yyyyMM').format(lastMonthDate);
  }

  // Getters for year, month, day, hour, minute, second, day name, weekday
  int getYear() => _year;

  int getMonth() => _month;

  int getDay() => _day;

  int getHour() => _hours;

  int getMinute() => _minutes;

  int getSecond() => _seconds;

  String getDayName() => _dayName;

  int getWeekday() => _weekday;
}

// 1 -> Senin
// 2 -> Selasa
// 3 -> Rabu
// 4 -> Kamis
// 5 -> Jumat
// 6 -> Sabtu
// 7 -> Minggu
