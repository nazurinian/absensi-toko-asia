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

/*
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
