import 'dart:async';
import 'dart:math' as math;

import 'package:absensitoko/models/AttendanceModel.dart';
import 'package:absensitoko/models/CustomTimeModel.dart';
import 'package:absensitoko/provider/DataProvider.dart';
import 'package:absensitoko/provider/TimeProvider.dart';
import 'package:absensitoko/themes/fonts/Fonts.dart';
import 'package:absensitoko/utils/BaseState.dart';
import 'package:absensitoko/utils/DialogUtils.dart';
import 'package:absensitoko/utils/Helper.dart';
import 'package:absensitoko/utils/LoadingDialog.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
/// Fokus get data dulu, mau itu dari firestore ato dri googlesheets tujuannya ngambil data absensi karyawan yg login
/// Biar datanya klo udh absen ya udah absen, belum absen ya belum absen, untuk ini juga kalo misalnya kemarin udah absen
/// dan ternyata di esok harinya gak bisa absen alasan karena ceknya masih true, nah ini harus direset, begitupun
/// sebaliknya misal nya ternyata aplikasi keluar terus masuk lagi dan ternyata ke reset ya variabelnya maka kalo udh ada
/// data hasil absensi bisa menentukan ini udah absen apa belum biar menampilkan pesan yg sesuai (artinya check true bukan false
/// krn udh absen)
/// Load datanya bersamaan dengan load posisi dan load breaktime
/// Tombol refresh juga bisa untuk refresh load data dan informasi libur
/// (belum ada perbedaan hari disini, harunya hari ahad ato tanggal merah itu masuk toko jam 7.30 brt absen jam 7.20 - 7.80


/// Yang kurang dihalaman ini adalah :
/// @Timer waktu absen pagi dan siang, timer muncul ketika memasuki rentang waktu absen
/// @Tombol absen pagi dan siang hanya bisa di klik ketika memasuki rentang waktu absen
/// @Tombol absen pagi dan siang tidak bisa di klik ketika sudah absen
/// @Rentang waktu terbagi menjadi dua rentang waktu, yaitu waktu on off tombol absen sekitar 3 jam, dan waktu absen tepat waktu 30 menit (20 menit lebih awal dan 10 menit tambahan)
/// - Pengecekan lokasi absen menggunakan gps fake atau asli
/// - Tambahkan pengecekan ganda hanya bisa absen dengan hp sendiri, jadi pas login wajib catat tipe hp dan ini fixed
/// artinya ketika data hp ini udh ada maka gk akan bisa berubah lagi
/// @Kolom absensi T/L, 30 menit awal T, lewat dari itu L (absen pagi atau siang)
/// - Pembuatan akun admin yang dapat mengelola :
///     1. Data karyawan
///     2. Data absensi (ketika diabsenkan bos misalnya, tanpa waktu)
///     3. Penentuan hari libur
///     4. Penentuan jam break siang
///     5. Merubah absensi karyawan
///     6. Kontrol Absensi karyawan
/// - Refresh data (saat ini hanya bisa refresh data karyawan, dan posisi lokasi)(kurang: refresh init data absen untuk meload data hari ini dan data break dari bos untuk absensi siang)
/// - Akun admin bisa ngerubah hasil absensi karywan dihari yang sama (misal ada yg lupa absen)
/// - Pengaturan lat dan long toko disimpan di sharedpreference dengan opsi pilihan
/// - Pengeolaan absensi ketika ganti hari, misalnya data di provider udah terisi maka diesok hari akan ke reset (pakai shared preference)
/// - Ketika Sudah Absen diHome Akan muncul juga info udah absen dengan provider data yg sama seperti di Halaman Absen
/// - Init data absen
/// - Tidak ada pengecekan apakah sudah absen atau belum
/// - Log yang menyimpan semuanya dan lat long sekaligus (extend model dengan lat long)
///
/// - Fix Warna
/// - Cek pengelolaan atau handle izin
/// - Cek handle koneksi internet
///
/// - Jadi ntar pas masuk ke halaman Absen itu langsung auto load data absensi hari ini, break time dan posisi lokasi secara bersamaan
/// - BreakTime dan Keterangan libur disimpan pada firestore biar mudah proses ambilnya.
/// - Tanggal Merah jam masuk pagi berbeda

class AbsensiPage extends StatefulWidget {
  final String employeeName;

  const AbsensiPage({super.key, required this.employeeName});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends BaseState<AbsensiPage>
    with SingleTickerProviderStateMixin {
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isStreaming = false; // untuk switch status

  // Titik absensi yang ditentukan
  // final double absensiLatitude = -7.219761201843603; Rumah SBY
  // final double absensiLongitude = 112.74985720321837;
  final double absensiLatitude = -8.5404;
  final double absensiLongitude = 118.4611;
  double? posisiPenggunaLatitude;
  double? posisiPenggunaLongitude;

  // Jarak maksimal dalam meter
  final double maxDistance = 10.0;
  bool attendancePermission = false;
  String status = 'Lokasi belum diperiksa';

  late AnimationController _controller;
  bool _isLoading = false;

  // Minta izin akses lokasi
  Future<void> _cekIzinLokasi() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          status = 'Izin lokasi ditolak';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        status = 'Izin lokasi permanen ditolak';
      });
      return;
    }

    // Jika izin diberikan, lanjutkan cek lokasi
    await _cekLokasiSekali();
  }

  Future<void> _prosesAbsen(String waktuAbsensi, Attendance attendance) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    LoadingDialog.show(context);
    try {
      final message =
          await dataProvider.updateAttendance(waktuAbsensi, attendance);

      safeContext(
        (context) => LoadingDialog.hide(context),
      );

      if (message.status == 'success') {
        ToastUtil.showToast('Berhasil mencatat kehadiran', ToastStatus.success);
      } else {
        print("tai babi: $message");
        ToastUtil.showToast(message.message ?? '', ToastStatus.error);
      }

      // await Future.wait([
      //   dataProvider.fetchData(_currentTime.getYearMonth()),
      //   dataProvider.fetchCurrentAndLastMonthData(
      //       _currentTime.getYearMonth(), _currentTime.getLastMonthYearMonth()),
      // ]);
    } catch (e) {
      safeContext(
        (context) => LoadingDialog.hide(context),
      );
      ToastUtil.showToast('Gagal memproses kehadiran', ToastStatus.error);
    }
  }

  // Cek apakah pengguna berada dalam radius absensi
  Future<void> _cekLokasiSekali() async {
    try {
      safeContext((context) => LoadingDialog.show(context));
      Position posisiPengguna = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        posisiPenggunaLatitude = posisiPengguna.latitude;
        posisiPenggunaLongitude = posisiPengguna.longitude;
      });

      _cekJarak(posisiPengguna); // Cek jarak sekali

      safeContext((context) => LoadingDialog.hide(context));
    } catch (e) {
      setState(() {
        status = 'Terjadi kesalahan: $e';
      });
      safeContext((context) => LoadingDialog.hide(context));
    }
  }

  // Fungsi untuk cek jarak dari posisi pengguna ke titik absensi
  void _cekJarak(Position posisiPengguna) {
    double jarak = Geolocator.distanceBetween(
      absensiLatitude,
      absensiLongitude,
      posisiPengguna.latitude,
      posisiPengguna.longitude,
    );

    if (jarak <= maxDistance) {
      setState(() {
        attendancePermission = true;
        status =
            'Dapat mengisi absen.\nAnda berada dalam radius absensi toko ${jarak.toStringAsFixed(2)} meter.';
      });
    } else {
      setState(() {
        attendancePermission = false;
        status =
            'Tidak dapat mengisi absen.\nAnda terlalu jauh dari Toko,\nJarak ke Toko: ${jarak.toStringAsFixed(2)} meter.';
      });
    }
  }

  // Fungsi untuk memulai stream
  void _startListeningLocationUpdates() {
    if (_positionStreamSubscription != null) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position posisiPengguna) {
      setState(() {
        posisiPenggunaLatitude = posisiPengguna.latitude;
        posisiPenggunaLongitude = posisiPengguna.longitude;
      });

      _cekJarak(posisiPengguna); // Cek jarak setiap kali posisi berubah
    });
  }

// Fungsi untuk toggle stream saat switch diaktifkan/dinonaktifkan
  void _toggleStreaming(bool isStreaming) {
    setState(() {
      _isStreaming = isStreaming;
      if (_isStreaming) {
        _startListeningLocationUpdates();
      } else {
        _stopListeningLocationUpdates();
      }
    });
  }

  void _startLoading() {
    setState(() {
      _isLoading = true;
    });
    _controller.repeat(); // Mulai animasi berulang
    Future.delayed(const Duration(seconds: 5), () async {
      await _cekLokasiSekali();
      setState(() {
        _isLoading = false;
      });
      // Hentikan animasi secara halus dan kembalikan ke posisi awal
      await _controller.animateTo(1.0,
          duration: const Duration(milliseconds: 500));
      _controller.reset(); // Reset animasi ke posisi awal

      // onPressed: () {
      //   Provider.of<TimeProvider>(context, listen: false)
      //       .updateBreakTime(15, 10);
      // },
      // child: const Icon(Icons.refresh),
    });
  }

  // Fungsi untuk menghentikan stream
  void _stopListeningLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  @override
  void initState() {
    super.initState();
    _cekIzinLokasi();
    // Inisialisasi AnimationController
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    // if(!mounted){
    //   Provider.of<TimeProvider>(context, listen: false).stopUpdatingTime();
    // }
    _controller.dispose();
    _stopListeningLocationUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: double.infinity,
          width: double.infinity,
          color: Colors.brown,
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Absensi Online'),
                ),
                body: Consumer<TimeProvider>(
                    builder: (context, timeProvider, child) {
                  final dateTime = timeProvider.currentTime;
                  final morningAttendanceState =
                      timeProvider.isPagiButtonActive();
                  final afternoonAttendanceState =
                      timeProvider.isSiangButtonActive();

                  return SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            status,
                            style: const TextStyle(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          // Switch untuk mengaktifkan dan menonaktifkan stream
                          SwitchListTile(
                            title: const Text('Aktifkan Lokasi Real-time'),
                            value: _isStreaming,
                            onChanged: (bool value) {
                              _toggleStreaming(value);
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _cekLokasiSekali,
                            child: const Text('Cek Lokasi'),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/map',
                                  arguments: LatLng(
                                      absensiLatitude, absensiLongitude));
                            },
                            child: const Text('Lihat Posisi'),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Divider(),
                          const SizedBox(
                            height: 20,
                          ),
                          Card(
                            color: Colors.blue,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    timeProvider.countDownText,
                                    style: TextStyle(
                                      fontFamily: 'Digital7',
                                      fontSize: 48,
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Card(
                                    color: Colors.green,
                                    elevation: 5,
                                    shadowColor: Colors.white,
                                    surfaceTintColor: Colors.greenAccent,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        children: [
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Text(
                                            'Absen Pagi',
                                            style: FontTheme.bodyMedium(
                                              context,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          ElevatedButton(
                                            onPressed: morningAttendanceState &&
                                                    attendancePermission
                                                ? () {
                                                    print(
                                                        'taekkkkk bdm pea: ${dateTime.postTime()}');
                                                    print(
                                                        'taekkkkk ayam pea: ${timeProvider.attendanceStatus}');
                                                    final attendanceData = Data(
                                                      tLPagi: timeProvider
                                                          .attendanceStatus,
                                                      hadirPagi:
                                                          dateTime.postTime(),
                                                      pointPagi: '0',
                                                      // keterangan: 'Yanto',
                                                    );
                                                    final attendance =
                                                        Attendance(
                                                      action: 'update',
                                                      // create_attendance
                                                      tahunBulan: dateTime
                                                          .getYearMonth(),
                                                      tanggal:
                                                          dateTime.getIdnDate(),
                                                      namaKaryawan: 'SADIQ',
                                                      // namaKaryawan: widget
                                                      //     .employeeName
                                                      //     .toUpperCase(),
                                                      data: attendanceData,
                                                    );
                                                    DialogUtils
                                                        .showConfirmationDialog(
                                                      context: context,
                                                      title: "Absen Pagi",
                                                      content: const Text(
                                                          'Absen Sekarang?'),
                                                      onConfirm: () {
                                                        _prosesAbsen('pagi',
                                                                attendance)
                                                            .then((_) =>
                                                                timeProvider
                                                                    .onButtonClick(
                                                                        'pagi'));
                                                      },
                                                    );
                                                  }
                                                : null,
                                            child: const Text('Absen Pagi'),
                                          ),
                                          attendanceStatus(
                                            attendance: 'pagi',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Text(
                                    timeProvider.morningAttendanceMessage,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Mulish',
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Card(
                                    color: Colors.red,
                                    elevation: 5,
                                    shadowColor: Colors.white,
                                    surfaceTintColor: Colors.redAccent,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        children: [
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Text(
                                            'Absen Siang',
                                            style: FontTheme.bodyMedium(
                                              context,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          FilledButton(
                                            onPressed:
                                                afternoonAttendanceState &&
                                                        attendancePermission
                                                    ? () {
                                                        print(
                                                            'taekkkkk bdm pea: ${dateTime.postTime()}');
                                                        print(
                                                            'taekkkkk ayam pea: ${timeProvider.attendanceStatus}');
                                                        final attendanceData =
                                                            Data(
                                                          tLSiang: timeProvider
                                                              .attendanceStatus,
                                                          pulangSiang: dateTime
                                                              .postTime(),
                                                          hadirSiang: dateTime
                                                              .postTime(),
                                                          pointSiang: '5',
                                                          // keterangan: 'Anto',
                                                        );
                                                        final attendance =
                                                            Attendance(
                                                          action: 'update',
                                                          // create_attendance
                                                          tahunBulan: dateTime
                                                              .getYearMonth(),
                                                          tanggal: dateTime
                                                              .getIdnDate(),
                                                          namaKaryawan: 'SADIQ',
                                                          // namaKaryawan: widget
                                                          //     .employeeName
                                                          //     .toUpperCase(),
                                                          data: attendanceData,
                                                        );
                                                        DialogUtils
                                                            .showConfirmationDialog(
                                                          context: context,
                                                          title: "Absen Siang",
                                                          content: const Text(
                                                              'Absen Sekarang?'),
                                                          onConfirm: () {
                                                            _prosesAbsen(
                                                                    'siang',
                                                                    attendance)
                                                                .then((_) =>
                                                                    timeProvider
                                                                        .onButtonClick(
                                                                            'siang'));
                                                          },
                                                        );
                                                      }
                                                    : null,
                                            child: const Text('Absen Siang'),
                                          ),
                                          attendanceStatus(
                                            attendance: 'siang',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (timeProvider
                                    .afternoonAttendanceMessage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      timeProvider.afternoonAttendanceMessage,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Mulish',
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                const SizedBox(
                                  height: 10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          const Divider(),
                          const SizedBox(
                            height: 20,
                          ),
                          const Text('Keterangan: '),
                          const SizedBox(
                            height: 10,
                          ),
                          const Text(
                              'Izin / Sakit / Terlambat Tidak bisa absen lagi'),
                          const SizedBox(
                            height: 10,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                floatingActionButton: FloatingActionButton(
                  onPressed: _isLoading ? null : _startLoading,
                  // Disable button saat loading
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _controller.value * 2.0 * math.pi,
                        child: const Icon(Icons.refresh),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget attendanceStatus({
    String? attendance,
    String? attendanceTime,
    String? breakTime,
    String? status,
    String? point,
    String? lat,
    String? long,
  }) {
    return Consumer<DataProvider>(builder: (context, dataProvider, child) {
      final attendanceData = dataProvider.dataAbsensi;
      if (attendance == 'pagi') {
        if (attendanceData.hadirPagi == null ||
            attendanceData.hadirPagi!.isEmpty) {
          return const SizedBox();
        } else {
          attendanceTime =
              CustomTime.fromServerTime(attendanceData.hadirPagi!).getIdnTime();
          status = attendanceData.tLPagi == 'T' ? 'Tepat Waktu' : 'Lewat Waktu';
          point = attendanceData.pointPagi ?? '-';
          // lat = attendanceData.latPagi! ?? '-';
          // long = attendanceData.longPagi! ?? '-';
          lat = posisiPenggunaLatitude.toString();
          long = posisiPenggunaLongitude.toString();
        }
      }

      if (attendance == 'siang') {
        if (attendanceData.hadirSiang == null ||
            attendanceData.hadirSiang!.isEmpty) {
          return const SizedBox();
        } else {
          breakTime = CustomTime.fromServerTime(attendanceData.pulangSiang!)
              .getIdnTime();
          attendanceTime = CustomTime.fromServerTime(attendanceData.hadirSiang!)
              .getIdnTime();

          status =
              attendanceData.tLSiang == 'T' ? 'Tepat Waktu' : 'Lewat Waktu';
          point = attendanceData.pointSiang ?? '-';
          // lat = attendanceData.latSiang! ?? '-';
          // long = attendanceData.longSiang! ?? '-';
          lat = posisiPenggunaLatitude.toString();
          long = posisiPenggunaLongitude.toString();
        }
      }

      return Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          Text('Waktu istirahat: ${attendanceTime ?? '-'}'),
          const SizedBox(
            height: 10,
          ),
          if (attendance == 'siang') ...[
            Text('Waktu masuk: ${breakTime ?? '-'}'),
            const SizedBox(
              height: 10,
            ),
          ],
          Text('Status: ${status ?? '-'}'),
          const SizedBox(
            height: 10,
          ),
          Text('Point: ${point ?? '-'}'),
          const SizedBox(
            height: 10,
          ),
          Text('Lat: | Long: ${lat ?? '-'} | ${long ?? '-'}'),
          const SizedBox(
            height: 10,
          ),
        ],
      );
    });
  }
}
