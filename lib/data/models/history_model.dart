import 'dart:convert';

// Struktur Model untuk Tiga Turunan
// 1. HistoryModel: Model utama yang menyimpan data history per pengguna (userName).
// 2. MonthlyHistory: Menyimpan semua data untuk tiap bulan (tahunBulan) dari seorang pengguna.
// 3. DailyHistory: Menyimpan semua data untuk tiap (tanggal) hari di bulan tertentu dari seorang pengguna.
// 4. HistoryData: Menyimpan data detail per tanggal.

class HistoryModel {
  final Map<String, MonthlyHistory>
      allUsersHistory; // userName -> MonthlyHistory

  HistoryModel({required this.allUsersHistory});

  factory HistoryModel.fromJson(String str) =>
      HistoryModel.fromMap(json.decode(str));

  factory HistoryModel.fromMap(Map<String, dynamic> json) {
    return HistoryModel(
      allUsersHistory: json
          .map((key, value) => MapEntry(key, MonthlyHistory.fromMap(value))),
    );
  }

  Map<String, dynamic> toMap() {
    return allUsersHistory.map((key, value) => MapEntry(key, value.toMap()));
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => toJson();
}

class MonthlyHistory {
  final Map<String, DailyHistory>? dayHistory; // tahunBulan -> DayHistory

  MonthlyHistory({required this.dayHistory});

  factory MonthlyHistory.fromJson(String str) =>
      MonthlyHistory.fromMap(json.decode(str));

  factory MonthlyHistory.fromMap(Map<String, dynamic> json) {
    return MonthlyHistory(
      dayHistory:
          json.map((key, value) => MapEntry(key, DailyHistory.fromMap(value))),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayHistory':
          dayHistory?.map((key, value) => MapEntry(key, value.toMap()))
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => toJson();
}

class DailyHistory {
  final Map<String, HistoryData>? historyData; // tanggal -> HistoryData

  DailyHistory({required this.historyData});

  factory DailyHistory.fromJson(String str) =>
      DailyHistory.fromMap(json.decode(str));

  // Menggunakan Map.from() jika Anda memerlukan salinan yang independen dari data sumber untuk menghindari efek samping dari modifikasi data asli.
  factory DailyHistory.fromMap(Map<String, dynamic> json) {
    return DailyHistory(
      historyData:
          json.map((key, value) => MapEntry(key, HistoryData.fromMap(value))),
      // historyData: Map.from(json["historyData"]!).map((key, value) => MapEntry<String, HistoryData>(key, HistoryData.fromMap(value))),  // ini dr quicktype
    );
  }

  // Jika tidak ada kebutuhan untuk salinan terpisah, cukup gunakan map.map() tanpa Map.from() karena lebih efisien.
  Map<String, dynamic> toMap() {
    return {
      'historyData':
          historyData?.map((key, value) => MapEntry(key, value.toMap())),
      // "historyData": Map.from(historyData!).map((key, value) => MapEntry<String, dynamic>(key, value.toMap())),
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => toJson();
}

class HistoryData {
  String? tanggalCreate;
  String? tanggalUpdate;
  String? hari;
  String? tLPagi;
  String? hadirPagi;
  String? pointPagi;
  String? tLSiang;
  String? pulangSiang;
  String? hadirSiang;
  String? pointSiang;
  String? keterangan;
  double? lat;
  double? long;
  String? deviceInfo;

  HistoryData({
    this.tanggalCreate,
    this.tanggalUpdate,
    this.hari,
    this.tLPagi,
    this.hadirPagi,
    this.pointPagi,
    this.tLSiang,
    this.pulangSiang,
    this.hadirSiang,
    this.pointSiang,
    this.keterangan,
    this.lat,
    this.long,
    this.deviceInfo,
  });

  factory HistoryData.fromJson(String str) =>
      HistoryData.fromMap(json.decode(str));

  // Fungsi untuk mengubah dari Map ke HistoryData
  factory HistoryData.fromMap(Map<String, dynamic> json) {
    return HistoryData(
      tanggalCreate: json['tanggal'] as String?,
      tanggalUpdate: json['tanggal'] as String?,
      hari: json['hari'] as String?,
      tLPagi: json['tLPagi'] as String?,
      hadirPagi: json['hadirPagi'] as String?,
      pointPagi: json['pointPagi'] as String?,
      tLSiang: json['tLSiang'] as String?,
      pulangSiang: json['pulangSiang'] as String?,
      hadirSiang: json['hadirSiang'] as String?,
      pointSiang: json['pointSiang'] as String?,
      keterangan: json['keterangan'] as String?,
      lat: json['lat'] != null
          ? (json['lat'] is int
              ? (json['lat'] as int).toDouble()
              : json['lat'] as double)
          : null,
      long: json['lang'] != null
          ? (json['lang'] is int
              ? (json['lang'] as int).toDouble()
              : json['lang'] as double)
          : null,
      deviceInfo: json['deviceInfo'] as String?,
    );
  }

  // Fungsi untuk mengubah dari HistoryData ke Map
  Map<String, dynamic> toMap() {
    return {
      'tanggalCreate': tanggalCreate ?? '',
      'tanggalUpdate': tanggalUpdate ?? '',
      'hari': hari ?? '',
      'tLPagi': tLPagi ?? '',
      'hadirPagi': hadirPagi ?? '',
      'pointPagi': pointPagi ?? '',
      'tLSiang': tLSiang ?? '',
      'pulangSiang': pulangSiang ?? '',
      'hadirSiang': hadirSiang ?? '',
      'pointSiang': pointSiang ?? '',
      'keterangan': keterangan ?? '',
      'lat': lat ?? 0.0,
      'lang': long ?? 0.0,
      'deviceInfo': deviceInfo ?? '',
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => toJson();
}
