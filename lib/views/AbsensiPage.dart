import 'package:absensitoko/models/AttendanceModel.dart';
import 'package:absensitoko/provider/DataProvider.dart';
import 'package:absensitoko/provider/TimeProvider.dart';
import 'package:absensitoko/themes/fonts/Fonts.dart';
import 'package:absensitoko/utils/BaseState.dart';
import 'package:absensitoko/utils/Helper.dart';
import 'package:absensitoko/utils/LoadingDialog.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

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

  // Jarak maksimal dalam meter
  final double maxDistance = 10.0;

  String status = 'Lokasi belum diperiksa';

  @override
  void initState() {
    super.initState();
    _cekIzinLokasi();
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

  Future<void> _prosesAbsenPagi(Attendance attendance) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    LoadingDialog.show(context);
    try {
      final message = await dataProvider.updateAttendance(attendance);

      safeContext(
            (context) => LoadingDialog.hide(context),
      );

      if (message.status == 'success') {
        ToastUtil.showToast(
            'Berhasil mencatat kehadiran', ToastStatus.success);
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
              'Gagal absen.\nAnda terlalu jauh, jarak: \n${jarak.toStringAsFixed(2)} meter.';
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
    final dateTime = Provider.of<TimeProvider>(context).currentTime;

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
                body: SingleChildScrollView(
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
                                arguments:
                                    LatLng(absensiLatitude, absensiLongitude));
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
                        Text(
                          'Absen pagi',
                          style: FontTheme.bodyMedium(context,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text('Waktu masuk: '),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text('Status: '),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text('Point: '),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text('Lat: | Long: '),
                        const SizedBox(
                          height: 10,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final attendanceData = Data(
                              // tanggal: dateTime.getIdnDate(),
                              // hari: dateTime.getIdnDayName().toUpperCase(),
                              tLPagi: 'T',
                              hadirPagi: dateTime.getIdnTime(),
                              pointPagi: '0',
                              // tLSiang: 'L',
                              // pulangSiang: '12:00',
                              // hadirSiang: dateTime.getIdnTime(),
                              // pointSiang: '5',
                              keterangan: 'x',
                            );
                            final attendance = Attendance(
                              action: 'update', // create_attendance
                              tahunBulan: dateTime.getYearMonth(),
                              tanggal: dateTime.getIdnDate(),
                              namaKaryawan: "SADIQ",
                              // namaKaryawan: widget.employeeName,
                              data: attendanceData,
                            );
                            // ToastUtil.showToast(
                            //     'Dalam Pengembangan', ToastStatus.warning);
                            _prosesAbsenPagi(attendance);
                          },
                          child: const Text('Absen Pagi'),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          'Absen siang',
                          style: FontTheme.bodyMedium(context,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text('Waktu istirahat: '),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text('Waktu masuk: '),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text('Status: '),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text('Point: '),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text('Lat: | Long: '),
                        const SizedBox(
                          height: 10,
                        ),
                        FilledButton(
                          onPressed: () {
                            ToastUtil.showToast(
                                'Dalam Pengembangan', ToastStatus.warning);
                          },
                          child: const Text('Absen Siang'),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const Divider(),
                        const SizedBox(
                          height: 20,
                        ),
                        const Text('Keterangan: '),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text('Izin / Sakit / Terlambat Tidak bisa absen lagi'),
                        const SizedBox(
                          height: 10,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
