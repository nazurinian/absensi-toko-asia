import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import 'ListItem.dart';

enum ToastStatus { success, error, warning }

class ToastUtil {
  static void showToast(String message, ToastStatus status) {
    Color backgroundColor;
    switch (status) {
      case ToastStatus.success:
        backgroundColor = Colors.green;
        break;
      case ToastStatus.error:
        backgroundColor = Colors.red;
        break;
      case ToastStatus.warning:
        backgroundColor = Colors.yellow;
        break;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: backgroundColor,
      textColor: Colors.blueAccent,
    );
  }
}

class SnackbarUtil {
  static void showSnackbar({
    required BuildContext context,
    required String message,
    // Color backgroundColor = Colors.black87,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // backgroundColor: backgroundColor,
      ),
    );
  }
}

String formatPhoneNumber(String phoneNumber) {
  phoneNumber = phoneNumber
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[^0-9+]'), '');
  if (phoneNumber.startsWith('0')) {
    return phoneNumber.substring(1);
    // return '+62' + phoneNumber.substring(1);
  }

  if (phoneNumber.startsWith('62')) {
    return phoneNumber.substring(2);
    // return '+62' + phoneNumber.substring(2);
  }

  if (phoneNumber.startsWith('+62')) {
    return phoneNumber.substring(3);
    // return '+62' + phoneNumber;
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

/*
String formatRupiah(int number) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatter.format(number);
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
