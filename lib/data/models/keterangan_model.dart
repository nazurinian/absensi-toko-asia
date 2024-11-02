class KeteranganAbsen {
  String kategoriUtama; // "pagi", "siang", "libur", atau "cuti"
  String subKategori;   // "telat", "izin", "sakit", atau "-"
  String detail;        // Keterangan tambahan (misalnya, alasan)

  KeteranganAbsen({
    required this.kategoriUtama,
    this.subKategori = "-", // Default ke "-" jika tidak ada subkategori
    required this.detail,
  });

  // Mengonversi ke Map untuk digunakan dalam API
  Map<String, dynamic> toJson() {
    return {
      'kategoriUtama': kategoriUtama,
      'subKategori': subKategori,
      'detail': detail,
    };
  }

  // Membuat objek dari Map
  factory KeteranganAbsen.fromJson(Map<String, dynamic> json) {
    return KeteranganAbsen(
      kategoriUtama: json['kategoriUtama'],
      subKategori: json['subKategori'] ?? "-",
      detail: json['detail'],
    );
  }

  // Fungsi untuk memparsing dari string keterangan
  static List<KeteranganAbsen> parseKeterangan(String keterangan) {
    RegExp exp = RegExp(r'\((.*?)\)'); // Mencari teks di dalam tanda kurung
    Iterable<RegExpMatch> matches = exp.allMatches(keterangan);

    List<KeteranganAbsen> resultList = [];

    for (var match in matches) {
      String kategoriDanSub = match.group(1) ?? ""; // Ambil teks di dalam kurung
      List<String> kategoriSplit = kategoriDanSub.split('-'); // Pisah berdasarkan tanda "-"
      String kategori = kategoriSplit[0].trim(); // Kategori utama
      String subKategori = kategoriSplit.length > 1 ? kategoriSplit[1].toLowerCase().trim() : "-"; // Subkategori (jika ada)

      int startIndex = match.end; // Posisi setelah tanda kurung
      int nextParenIndex = keterangan.indexOf('(', startIndex); // Cari kurung buka berikutnya
      String detail = (nextParenIndex == -1)
          ? keterangan.substring(startIndex).trim() // Jika tidak ada kurung lain, ambil sampai akhir
          : keterangan.substring(startIndex, nextParenIndex).trim(); // Ambil teks sampai kurung berikutnya

      if (kategori.toLowerCase() == "pagi" || kategori.toLowerCase() == "siang") {
        // Cek apakah ada subkategori dalam detail
        if (detail.contains("telat")) {
          subKategori = "Telat";
        } else if (detail.contains("izin")) {
          subKategori = "Izin";
        } else if (detail.contains("sakit")) {
          subKategori = "Sakit";
        }
      }

      // Buat objek dan tambahkan ke daftar hasil
      resultList.add(KeteranganAbsen(
        kategoriUtama: kategori,
        subKategori: subKategori,
        detail: detail,
      ));
    }

    return resultList;
  }

  @override
  String toString() {
    return toJson().toString();
  }
}
