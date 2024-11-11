import 'package:absensitoko/core/constants/constants.dart';
import 'package:absensitoko/data/models/time_model.dart';
import 'package:intl/intl.dart';

import '../../core/constants/items_list.dart';

String formatPhoneNumber(String phoneNumber) {
  phoneNumber = phoneNumber
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[^0-9+]'), '');
  if (phoneNumber.startsWith('0')) {
    return phoneNumber.substring(1);
  }

  if (phoneNumber.startsWith('62')) {
    return phoneNumber.substring(2);
  }

  if (phoneNumber.startsWith('+62')) {
    return phoneNumber.substring(3);
  }

  return phoneNumber;
}

String capitalizeEachWord(String text) {
  if (text.isEmpty) return text;

  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

String? getCountryFromPhoneNumber(String phoneNumber) {
  // Urutkan kode negara berdasarkan panjangnya secara menurun
  final sortedCountryCodes = countryCodes.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length)); // Cascade Notation

  // Periksa apakah nomor telepon dimulai dengan salah satu kode negara
  for (String code in sortedCountryCodes) {
    if (phoneNumber.startsWith(code)) {
      // return countryCodes[code]; // Ini untuk dapetin nama negaranya
      return code; // Ini untuk dapetin kode negaranya
    }
  }

  return null; // Jika tidak ada yang cocok
}

String formatTime(DateTime dateTime) {
  return DateFormat('HH:mm', 'id_ID').format(dateTime);
}

String formatKeterangan(String kategoriUtama, {String? subKategori, required String detail}) {
  // Cek apakah kategori utama adalah pagi atau siang dan memiliki subkategori
  if ((kategoriUtama == 'Pagi' || kategoriUtama == 'Siang') && subKategori != null) {
    return '($kategoriUtama-$subKategori) $detail';
  } else {
    return '($kategoriUtama) $detail';
  }
}

bool isCurrentTimeWithinRange(DateTime now, String startTime, String endTime) {
  // Parse waktu mulai dan waktu akhir dari String ke DateTime dengan tanggal hari ini
  final start = DateTime(now.year, now.month, now.day,
      int.parse(startTime.split(':')[0]), int.parse(startTime.split(':')[1]));
  final end = DateTime(now.year, now.month, now.day,
      int.parse(endTime.split(':')[0]), int.parse(endTime.split(':')[1]));

  // Cek apakah waktu sekarang berada di antara start dan end
  // return now.isAfter(start) && now.isBefore(end);
  return (now.isAfter(start) || now.isAtSameMomentAs(start)) &&
      (now.isBefore(end) || now.isAtSameMomentAs(end));
}

String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$minutes:$seconds";
}

String calculateBreakTime(CustomTime currentTime, String? breakTime, int weekday) {
  if (breakTime?.isNotEmpty ?? false) {
    String breakEndTime = formatStringToDateTime(
      currentTime,
      breakTime!,
      addTime: afternoonPreparationMinutes,
    );
    return '$breakTime - $breakEndTime';
  }

  return weekday == DateTime.sunday
      ? '13:00 - 16.00'
      : weekday == DateTime.friday
      ? '11.15 - 14:00'
      : 'Belum diatur';
}

String setHolidayStatus(String? nationalHoliday, int weekday) {
  if (nationalHoliday?.isNotEmpty ?? false) {
    return nationalHoliday!;
  }

  return weekday == DateTime.sunday ? '(Hari Ahad)' : '(Hari Normal)';
}

String formatStringToDateTime(CustomTime now, String date, {int? addTime}) {
  List<String> breakTimeParts = date.split(':');
  int breakHour = int.parse(breakTimeParts[0]);
  int breakMinute = int.parse(breakTimeParts[1]);

  DateTime dateTime = DateTime(
    now.getYear(),
    now.getMonth(),
    now.getDay(),
    breakHour,
    breakMinute,
  );

  if (addTime != null) {
    dateTime = dateTime.add(Duration(minutes: addTime));
  }
  return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
}

Map<String, int> getBreakTime(int weekday, String? serverBreakTime) {
  int breakHour;
  int breakMinute;

  if (weekday == DateTime.friday) {
    breakHour = fridayAfternoonStartHour;
    breakMinute = fridayAfternoonStartMinute;
  } else if (weekday == DateTime.sunday) {
    breakHour = sundayAfternoonStartHour;
    breakMinute = sundayAfternoonStartMinute;
  } else {
    final defaultBreakTime = serverBreakTime?.isNotEmpty ?? false ? serverBreakTime! : '12:00';
    List<String> breakTimeParts = defaultBreakTime.split(':');
    breakHour = int.parse(breakTimeParts[0]);
    breakMinute = int.parse(breakTimeParts[1]);
  }

  return {'hour': breakHour, 'minute': breakMinute};
}

// Fungsi untuk menentukan target bulan (bulan ini atau bulan berikutnya)
String getTargetMonth(DateTime today) {
  final lastDayOfMonth = DateTime(today.year, today.month + 1, 0).day;
  final nextMonth = today.month == 12 ? 1 : today.month + 1;
  final nextYear = today.month == 12 ? today.year + 1 : today.year;

  // Tentukan target bulan berdasarkan H-3 dan H+3
  if (today.day >= lastDayOfMonth - 2) {
    // Jika H-3, target bulan berikutnya
    return '${nextYear}${nextMonth.toString().padLeft(2, '0')}';
  } else if (today.day <= 3) {
    // Jika H+3, target bulan ini
    return '${today.year}${today.month.toString().padLeft(2, '0')}';
  } else {
    return ''; // Tidak dalam rentang
  }
}

// Fungsi untuk mengecek apakah tanggal berada dalam rentang H-3 atau H+3
bool isStartAndLastMonthWithinRange(DateTime today) {
  final lastDayOfMonth = DateTime(today.year, today.month + 1, 0).day;

  // Cek H-3 (3 hari terakhir bulan sebelumnya) dan H+3 (3 hari pertama bulan ini)
  return (today.day >= lastDayOfMonth - 2) || (today.day <= 3);
}

// Fungsi untuk mengecek apakah targetMonth belum ada dalam sheetList
bool isSheetNotExist(String targetMonth, List<String> sheetList) {
  if (sheetList.isEmpty) {
    return false;
  }
  return targetMonth.isNotEmpty && !sheetList.contains(targetMonth);
  // return targetMonth.isNotEmpty && sheetList.isNotEmpty && !sheetList.contains(targetMonth);
}

/*
// Cek apakah bulan target belum ada dalam sheet
bool isSheetNotExist(String targetMonth, List<String> sheetList) {
  return !sheetList.contains(targetMonth);
}

// Cek apakah tanggal saat ini berada di H-3 atau H+3 dan sheet belum ada
bool canActivateButton(DateTime today, List<String> sheetList) {
  final lastDayOfMonth = DateTime(today.year, today.month + 1, 0).day;
  bool isInLast3Days = today.day >= lastDayOfMonth - 2;
  bool isInFirst3Days = today.day <= 3;

  // Tentukan bulan target berdasarkan kondisi H-3 atau H+3
  final nextMonth = today.month == 12 ? 1 : today.month + 1;
  final nextYear = today.month == 12 ? today.year + 1 : today.year;
  String targetMonth;

  if (isInLast3Days) {
    // Jika H-3, gunakan bulan berikutnya
    targetMonth = '${nextYear}${nextMonth.toString().padLeft(2, '0')}';
  } else if (isInFirst3Days) {
    // Jika H+3, gunakan bulan ini
    targetMonth = '${today.year}${today.month.toString().padLeft(2, '0')}';
  } else {
    return false; // Tidak memenuhi syarat tanggal
  }

  // Cek apakah targetMonth belum ada dalam daftar sheet
  return isSheetNotExist(targetMonth, sheetList);
}

bool isStartAndLastMonthWithinRange(DateTime today) {
  final lastDayOfMonth = DateTime(today.year, today.month + 1, 0).day;
  bool isInLast3Days = today.day >= lastDayOfMonth - 2;
  bool isInFirst3Days = today.day <= 3;
  return isInLast3Days || isInFirst3Days;
}
*/

/*
String formatStringToDateTime (CustomTime now, String date, {int? addTime}) {
  List<String> breakTimeParts = date.split(':');
  int breakHour = int.parse(breakTimeParts[0]);
  int breakMinute = int.parse(breakTimeParts[1]);
  DateTime dateTime = DateTime(now.getYear(), now.getMonth(), now.getDay(),
    breakHour,
    breakMinute,
  );
  if(addTime != null) {
    dateTime = dateTime.add(Duration(minutes: addTime));
  }
  return "$dateTime.minutes:$dateTime.seconds";
}

String getListSheet(String dateString) {
  // Parsing string 'yyyyMM' ke dalam DateTime
  int year = int.parse(dateString.substring(0, 4));
  int month = int.parse(dateString.substring(4, 6));

  // Membuat objek DateTime dengan tanggal 1 pada bulan yang ditentukan
  DateTime dateTime = DateTime(year, month, 1);

  // Format untuk nama bulan dan tahun
  String formattedDate = DateFormat('MMMM yyyy', 'id_ID').format(dateTime);

  return formattedDate;
}

String getListValue(String formattedDate) {
  // Menentukan format untuk parsing bulan dan tahun
  DateFormat inputFormat = DateFormat('MMMM yyyy', 'id_ID');
  DateFormat outputFormat = DateFormat('yyyyMM');

  // Parsing string formattedDate ke DateTime
  DateTime dateTime = inputFormat.parse(formattedDate);

  // Format ulang DateTime menjadi string 'yyyyMM'
  String formattedDateString = outputFormat.format(dateTime);

  return formattedDateString;
}*/
