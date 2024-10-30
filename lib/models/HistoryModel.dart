import 'dart:convert';

class HistoryModel {
  final String? userName; // Nama pengguna
  final Map<String, HistoryData>? historyData; // Data history berdasarkan tanggal

  HistoryModel({this.userName, this.historyData});

  // Fungsi untuk mengubah dari Map ke HistoryModel
  factory HistoryModel.fromMap(String userName, Map<String, dynamic> map) {
    return HistoryModel(
      userName: userName,
      historyData: map.map((key, value) => MapEntry(key, HistoryData.fromMap(value))),
    );
  }

  // Fungsi untuk mengubah dari HistoryModel ke Map
  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'historyData': historyData?.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  // Fungsi untuk mengubah HistoryModel menjadi JSON
  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return toJson();
  }
}

class HistoryData {
  final String? tanggal;
  final String? hari;
  final String? tLPagi;
  final String? hadirPagi;
  final String? pointPagi;
  final String? tLSiang;
  final String? pulangSiang;
  final String? hadirSiang;
  final String? pointSiang;
  final String? keterangan;
  final double? lat;
  final double? lang;
  final String? deviceInfo;

  HistoryData({
    this.tanggal,
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
    this.lang,
    this.deviceInfo,
  });

  // Fungsi untuk mengubah dari Map ke HistoryData
  factory HistoryData.fromMap(Map<String, dynamic> map) {
    return HistoryData(
      tanggal: map['tanggal'] as String?,
      hari: map['hari'] as String?,
      tLPagi: map['tLPagi'] as String?,
      hadirPagi: map['hadirPagi'] as String?,
      pointPagi: map['pointPagi'] as String?,
      tLSiang: map['tLSiang'] as String?,
      pulangSiang: map['pulangSiang'] as String?,
      hadirSiang: map['hadirSiang'] as String?,
      pointSiang: map['pointSiang'] as String?,
      keterangan: map['keterangan'] as String?,
      lat: map['lat'] != null ? (map['lat'] is int ? (map['lat'] as int).toDouble() : map['lat'] as double) : null,
      lang: map['lang'] != null ? (map['lang'] is int ? (map['lang'] as int).toDouble() : map['lang'] as double) : null,
      deviceInfo: map['deviceInfo'] as String?,
    );
  }

  // Fungsi untuk mengubah dari HistoryData ke Map
  Map<String, dynamic> toMap() {
    return {
      'tanggal': tanggal ?? '',
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
      'lang': lang ?? 0.0,
      'deviceInfo': deviceInfo ?? '',
    };
  }
}
