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

/// Yang kurang dihalaman ini adalah :
/// - Timer waktu absen pagi dan siang, timer muncul ketika memasuki rentang waktu absen
/// - Tombol absen pagi dan siang hanya bisa di klik ketika memasuki rentang waktu absen
/// - Tombol absen pagi dan siang tidak bisa di klik ketika sudah absen
/// - Rentang waktu terbagi menjadi dua rentang waktu, yaitu waktu on off tombol absen sekitar 3 jam, dan waktu absen tepat waktu 30 menit (20 menit lebih awal dan 10 menit tambahan)
/// - Pengecekan lokasi absen menggunakan gps fake atau asli
/// - Kolom absensi T/L, 30 menit awal T, lewat dari itu L (absen pagi atau siang)
/// - Pembuatan akun admin yang dapat mengelola :
///     1. Data karyawan
///     2. Data absensi (ketika diabsenkan bos misalnya, tanpa waktu)
///     3. Penentuan hari libur
///     4. Penentuan jam break siang
///     5. Merubah absensi karyawan
///     6. Kontrol Absensi karyawan
/// - Refresh data (saat ini hanya bisa refresh data karyawan, dan posisi lokasi)(kurang: refresh init data absen untuk meload data hari ini dan data break dari bos untuk absensi siang)
/// - Akun admin bisa ngerubah hasil absensi karywan dihari yang sama (misal ada yg lupa absen)
/// - Pengaturan lat dan long disimpan di sharedpreference dengan opsi pilihan
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

class AbsensiPage extends StatefulWidget {
  final String employeeName;

  const AbsensiPage({super.key, required this.employeeName});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends BaseState<AbsensiPage> {
  // Titik absensi yang ditentukan
  final double absensiLatitude = -7.219761201843603;
  final double absensiLongitude = 112.74985720321837;
  double? posisiPenggunaLatitude;
  double? posisiPenggunaLongitude;

  // Jarak maksimal dalam meter
  final double maxDistance = 10.0;

  String status = 'Lokasi belum diperiksa';

  @override
  void initState() {
    super.initState();
    _cekIzinLokasi();
  }

  @override
  void dispose() {
    // if(!mounted){
    //   Provider.of<TimeProvider>(context, listen: false).stopUpdatingTime();
    // }
    super.dispose();
  }

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
    await _cekLokasi();
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
  Future<void> _cekLokasi() async {
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

      double jarak = Geolocator.distanceBetween(
        absensiLatitude,
        absensiLongitude,
        posisiPengguna.latitude,
        posisiPengguna.longitude,
      );

      if (jarak <= maxDistance) {
        setState(() {
          status =
              'Dapat mengisi absen.\nAnda berada dalam radius ${jarak.toStringAsFixed(2)} meter.';
        });
      } else {
        setState(() {
          status =
              'Tidak dapat mengisi absen.\nAnda terlalu jauh dari Toko,\nJarak ke Toko: ${jarak.toStringAsFixed(2)} meter.';
        });
      }
      safeContext((context) => LoadingDialog.hide(context));
    } catch (e) {
      setState(() {
        status = 'Terjadi kesalahan: $e';
      });
      safeContext((context) => LoadingDialog.hide(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    // final dateTime = Provider.of<TimeProvider>(context).currentTime;
    // final morningAttendanceState =
    //     Provider.of<TimeProvider>(context).isPagiButtonActive();
    // final afternoonAttendanceState =
    //     Provider.of<TimeProvider>(context).isSiangButtonActive();

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
                          ElevatedButton(
                            onPressed: _cekLokasi,
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
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 20),
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
                                            onPressed: morningAttendanceState
                                                ? () {
                                                    final attendanceData = Data(
                                                      tLPagi: 'T',
                                                      hadirPagi:
                                                          dateTime.postTime(),
                                                      pointPagi: '0',
                                                      keterangan: 'Yanto',
                                                    );
                                                    final attendance =
                                                        Attendance(
                                                      action: 'update',
                                                      // create_attendance
                                                      tahunBulan: dateTime
                                                          .getYearMonth(),
                                                      tanggal:
                                                          dateTime.getIdnDate(),
                                                      namaKaryawan: widget
                                                          .employeeName
                                                          .toUpperCase(),
                                                      data: attendanceData,
                                                    );
                                                    DialogUtils
                                                        .showConfirmationDialog(
                                                      context: context,
                                                      title: "Absen Pagi",
                                                      content: const Text(
                                                          'Absen Sekarang?'),
                                                      onConfirm: () {
                                                        _prosesAbsen(
                                                            'pagi', attendance).then((_) =>
                                                            timeProvider.onButtonClick('pagi'));
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
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 20),
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
                                            onPressed: afternoonAttendanceState
                                                ? () {
                                                    print(
                                                        'taekkkkk bdm pea: ${dateTime.postTime()}');
                                                    final attendanceData = Data(
                                                      tLSiang: 'L',
                                                      pulangSiang:
                                                          dateTime.postTime(),
                                                      hadirSiang:
                                                          dateTime.postTime(),
                                                      pointSiang: '5',
                                                      // keterangan: 'Anto',
                                                    );
                                                    final attendance =
                                                        Attendance(
                                                      action: 'update',
                                                      // create_attendance
                                                      tahunBulan: dateTime
                                                          .getYearMonth(),
                                                      tanggal:
                                                          dateTime.getIdnDate(),
                                                      namaKaryawan: widget
                                                          .employeeName
                                                          .toUpperCase(),
                                                      data: attendanceData,
                                                    );
                                                    DialogUtils
                                                        .showConfirmationDialog(
                                                      context: context,
                                                      title: "Absen Siang",
                                                      content: const Text(
                                                          'Absen Sekarang?'),
                                                      onConfirm: () {
                                                        _prosesAbsen('siang',
                                                            attendance).then((_) => timeProvider.onButtonClick('siang'));
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
                                Text(timeProvider.countDownText),
                                Text(timeProvider.morningAttendanceMessage),
                                Text(timeProvider.afternoonAttendanceMessage),
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
                  onPressed: () {
                    Provider.of<TimeProvider>(context, listen: false)
                        .updateBreakTime(15, 10);
                  },
                  child: const Icon(Icons.refresh),
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
