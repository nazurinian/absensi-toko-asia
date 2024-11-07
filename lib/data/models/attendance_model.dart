import 'dart:convert';

class Attendance {
  String? action;
  String? tahunBulan;
  String? tanggal;
  String? namaKaryawan;
  dynamic data;

  Attendance({
    this.action,
    this.tahunBulan,
    this.tanggal,
    this.namaKaryawan,
    this.data,
  });

  factory Attendance.fromJson(String str) => Attendance.fromMap(json.decode(str));

  factory Attendance.fromMap(Map<String, dynamic> json) => Attendance(
    action: json["action"],
    tahunBulan: json["tahunBulan"],
    tanggal: json["tanggal"],
    namaKaryawan: json["namaKaryawan"],
    data: json["data"] is List
        ? List<Data>.from(json["data"].map((x) => Data.fromMap(x)))
        : json["data"] != null
        ? Data.fromMap(json["data"])
        : null,
  );

  Map<String, dynamic> toMap() => {
    "action": action,
    "tahunBulan": tahunBulan,
    "tanggal": tanggal,
    "namaKaryawan": namaKaryawan,
    "data": data is List
        ? List<dynamic>.from((data as List<Data>).map((x) => x.toMap()))
        : (data as Data?)?.toMap(),
  };

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return toJson().toString();
  }
}

class Data {
  // DateTime? tanggal;
  String? tanggal;
  String? hari;
  String? tLPagi;
  String? hadirPagi;
  String? pointPagi;
  String? tLSiang;
  String? pulangSiang;
  String? hadirSiang;
  String? pointSiang;
  String? keterangan;

  Data({
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
  });

  factory Data.fromJson(String str) => Data.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Data.fromMap(Map<String, dynamic> json) => Data(
    // tanggal: json["Tanggal"] == null ? null : DateTime.parse(json["Tanggal"]),
    tanggal: json["Tanggal"].toString(),
    hari: json["Hari"].toString(),
    tLPagi: json["T/L Pagi"].toString(),
    hadirPagi: json["Hadir Pagi"],
    pointPagi: json["Point Pagi"].toString(),
    tLSiang: json["T/L Siang"].toString(),
    pulangSiang: json["Pulang Siang"],
    hadirSiang: json["Hadir Siang"],
    pointSiang: json["Point Siang"].toString(),
    keterangan: json["Keterangan"].toString(),
  );

  Map<String, dynamic> toMap() => {
    // "Tanggal": tanggal?.toIso8601String(),
    "Tanggal": tanggal,
    "Hari": hari,
    "T/L Pagi": tLPagi,
    "Hadir Pagi": hadirPagi,
    "Point Pagi": pointPagi,
    "T/L Siang": tLSiang,
    "Pulang Siang": pulangSiang,
    "Hadir Siang": hadirSiang,
    "Point Siang": pointSiang,
    "Keterangan": keterangan,
  };

  @override
  String toString() {
    return toJson().toString();
  }
}

// Mengubah JSON menjadi List<Attendance>
List<Attendance> attendanceListFromJson(String str) =>
    List<Attendance>.from(json.decode(str).map((x) => Attendance.fromMap(x)));

// Mengubah List<Attendance> menjadi JSON
String attendanceListToJson(List<Attendance> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));