import 'dart:async';
import 'dart:math' as math;

import 'package:absensitoko/AppRouter.dart';
import 'package:absensitoko/models/AttendanceModel.dart';
import 'package:absensitoko/models/CustomTimeModel.dart';
import 'package:absensitoko/provider/DataProvider.dart';
import 'package:absensitoko/provider/TimeProvider.dart';
import 'package:absensitoko/themes/fonts/Fonts.dart';
import 'package:absensitoko/utils/BaseState.dart';
import 'package:absensitoko/utils/CustomTextFormField.dart';
import 'package:absensitoko/utils/DialogUtils.dart';
import 'package:absensitoko/utils/Helper.dart';
import 'package:absensitoko/utils/LoadingDialog.dart';
import 'package:absensitoko/views/TestPage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fokus get data dulu, mau itu dari firestore ato dri googlesheets tujuannya ngambil data absensi karyawan yg login
/// Biar datanya klo udh absen ya udah absen, belum absen ya belum absen, untuk ini juga kalo misalnya kemarin udah absen
/// dan ternyata di esok harinya gak bisa absen alasan karena ceknya masih true, nah ini harus direset, begitupun
/// sebaliknya misal nya ternyata aplikasi keluar terus masuk lagi dan ternyata ke reset ya variabelnya maka kalo udh ada
/// data hasil absensi bisa menentukan ini udah absen apa belum biar menampilkan pesan yg sesuai (artinya check true bukan false
/// krn udh absen)

/// @ Tombol refresh jadinya untuk refresh lokasi (X-juga bisa untuk refresh load data dan informasi libur-X)
/// Load datanya bersamaan dengan load posisi dan load breaktime
/// (belum ada perbedaan hari disini, harunya hari ahad ato tanggal merah itu masuk toko jam 7.30 brt absen jam 7.20 - 7.80
/// Atasi penipuan dengan cara mendeteksi mock dan login perangkat, jadi nyimpen data perangkat di firestore, hanya bisa login di preangkat yg sama

/// Buat fitur keterangan
/// Buat fitur mocked
/// @ Buat fitur simpan data di firestore dengan tambahan gps dan nama perangkat
/// Buat fitur ambil data absen hari yg sama dulu

/// Kalau udah ada data sistem false cek absen di timeprovider diganti dengan cek ada data absennya gak
/// Waktu start absen khusus hari libur dan ahad yang berbeda
/// Kalau ada dua keterangan di pisah koma aja, artinya keterangan pagi dan siang ketika absen siang telat misal ada keterangan yg sudah terisi di gabung sama keterangan baru
/// Ketika pop dari map harusnya refresh lagi halaman absennya

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

/// - Fix Warna
/// - Cek pengelolaan atau handle izin
/// - Cek handle koneksi internet

/// - Jadi ntar pas masuk ke halaman Absen itu langsung auto load data absensi hari ini, break time dan posisi lokasi secara bersamaan
/// - BreakTime dan Keterangan libur disimpan pada firestore biar mudah proses ambilnya.
/// - Tanggal Merah jam masuk pagi berbeda

/// ----------------------------
/// @ attendanceLocationStatus disini pesan yang muncul ketika cek lokasi dan ketika memproses izin akses gps
/// * pengaturan izinnya belum disesuaikan
/// * absen pagi
/// * absen siang dan updateBreakTime
/// * Mbeneri Sistem Tombolnya kapan bisa diklik dan kapan tidak
/// * FireStore Update, field untuk waktu breaktime dan hari libur, lalu serta update
/// log firestore untuk informasi sudah absen atau belum yg disimpan pada data provider
/// kemudian dilanjutkan dengan update di sheets (saat ini masih update disheet aja)
/// * Keterangan Telat / tidak masuk
/// * Sistem Login dan Logout dengan Penambahan 3 field baru, nama perangkat, lokasi login, dan waktu login
/// untuk mengecek apakah login dari perangkat yang sama atau tidak, jika dari perangkat yang berbeda maka
/// akan di logout otomatis di perangkat sebelumnya (devicenya berbeda)
/// * Benerin nomor hp diprofil, kan hanya +62 yang bisa masuk artinya fixed aja gk ush pake dropdown

/// ----------------------------
/// Update Selanjutnya:
/// * Lengkapi Aplikasi Admin
/// * Sistem Dashboard atau statistik dari log absensi
/// * Tambahkan data login user dengan lokasi tempat dan nama perangkat login

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
  // bool _isAbsenPagi = false;
  // bool _isAbsenSiang = false;

  // Titik absensi yang ditentukan
  final double _storeLatitude = -8.5404;
  final double _storeLongitude = 118.4611;
  double? _userPositionLatitude;
  double? _userPositionLongitude;

  // Jarak maksimal dalam meter
  final double _maxDistance = 8.0;
  bool _attendancePermission = false;
  String _attendanceLocationStatus = 'Mengecek lokasi absen';
  String _statusWithDots = '';
  Timer? _coordinateCheckTimer;
  int _dotCount = 1;

  late AnimationController _controller;
  bool _fabLoading = false;
  bool _permissionGranted = false;

  // Minta izin akses lokasi
  Future<void> _cekIzinLokasi(String check, {bool? switchValue}) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      setState(() {
        _permissionGranted = false;
        _attendanceLocationStatus = 'Izin lokasi belum diberikan';
      });
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _permissionGranted = false;
          _attendanceLocationStatus =
              'Izin lokasi ditolak, harap berikan izin lokasi';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _permissionGranted = false;
        _attendanceLocationStatus =
            'Izin lokasi ditolak permanen, harap berikan izin lokasi di pengaturan';
      });
      openAppSettings();
      return;
    }

    _permissionGranted = true;
    // Jika izin diberikan, lanjutkan cek lokasi
    if (check == 'oneTimeCheck') {
      _loadCoordinateLocation();
      await _cekLokasiSekali();
    } else if (check == 'realTimeCheck') {
      _toggleStreaming(switchValue!);
    } else if (check == 'mapCheck') {
      Navigator.pushNamed(
        context,
        '/map',
        arguments: MapPageArguments(
          storeLocation: LatLng(_storeLatitude, _storeLongitude),
          storeRadius: _maxDistance,
        ),
      );
    }
  }

  // Animasi pesan status pada saat loading cek lokasi
  void _loadCoordinateLocation() {
    setState(() {
      _attendanceLocationStatus = 'Mengecek lokasi absen';
      _dotCount = 1;
    });
    _coordinateCheckTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_dotCount == 6) {
        setState(() {
          _dotCount = 1;
        });
      }
      setState(() {
        _statusWithDots = '.' * _dotCount;
        // attendanceLocationStatus = '$statusWithDots${'.' * _dotCount}';
      });
      _dotCount++;
      print(_attendanceLocationStatus + _statusWithDots);
    });
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
        _userPositionLatitude = posisiPengguna.latitude;
        _userPositionLongitude = posisiPengguna.longitude;
      });

      _cekJarak(posisiPengguna); // Cek jarak sekali

      safeContext((context) => LoadingDialog.hide(context));
    } catch (e) {
      setState(() {
        _attendanceLocationStatus = 'Terjadi kesalahan: $e';
      });
      safeContext((context) => LoadingDialog.hide(context));
    } finally {
      _coordinateCheckTimer?.cancel();
    }
  }

  // Fungsi untuk cek jarak dari posisi pengguna ke titik absensi
  void _cekJarak(Position posisiPengguna) {
    double jarak = Geolocator.distanceBetween(
      _storeLatitude,
      _storeLongitude,
      posisiPengguna.latitude,
      posisiPengguna.longitude,
    );

    if (jarak <= _maxDistance) {
      setState(() {
        _statusWithDots = '';
        _attendancePermission = true;
        _attendanceLocationStatus =
            'Dapat mengisi absen.\nAnda berada dalam radius absensi toko ${jarak.toStringAsFixed(2)} meter.';
      });
    } else {
      setState(() {
        _statusWithDots = '';
        _attendancePermission = false;
        _attendanceLocationStatus =
            'Tidak dapat mengisi absen.\nAnda terlalu jauh dari Toko,\nJarak ke Toko: ${jarak.toStringAsFixed(2)} meter.';
      });
    }
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
        _userPositionLatitude = posisiPengguna.latitude;
        _userPositionLongitude = posisiPengguna.longitude;
      });

      _cekJarak(posisiPengguna); // Cek jarak setiap kali posisi berubah
    });
  }

  // Fungsi untuk menghentikan stream
  void _stopListeningLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  // Memuat status Switch Stream Lokasi dari SharedPreferences
  Future<void> _loadSwitchState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isStreaming =
          prefs.getBool('isStreaming') ?? false; // Default false jika belum ada
    });
  }

  // Mengubah status Switch Stream Lokasi dan menyimpannya ke SharedPreferences
  Future<void> _toggleSwitch(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isStreaming = value;
    });
    await prefs
        .setBool('isStreaming', _isStreaming)
        .then((_) => _cekIzinLokasi('realTimeCheck', switchValue: value));
  }

  void _updateLocation() {
    setState(() {
      _fabLoading = true;
    });
    _controller.repeat();
    Future.delayed(const Duration(seconds: 3), () async {
      await _cekIzinLokasi('oneTimeCheck');
      setState(() {
        _fabLoading = false;
      });
      // Hentikan animasi secara halus dan kembalikan ke posisi awal
      await _controller.animateTo(1.0,
          duration: const Duration(milliseconds: 500));
      _controller.reset();
    });
  }

  void _updateBreakTime() {
    ToastUtil.showToast('Masih dalam pengembangan', ToastStatus.warning);
    // onPressed: () {
    //   Provider.of<TimeProvider>(context, listen: false)
    //       .updateBreakTime(15, 10);
    // },
    // child: const Icon(Icons.refresh),
  }

  Future<void> _attendanceProcess(
      String waktuAbsensi, Attendance attendance) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    LoadingDialog.show(context);
    try {
      final message =
          await dataProvider.updateAttendance(waktuAbsensi, attendance);

      safeContext(
        (context) => LoadingDialog.hide(context),
      );

      print("Status and Message: $message");
      if (message.status == 'success') {
        ToastUtil.showToast('Berhasil mencatat kehadiran', ToastStatus.success);
      } else {
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

  @override
  void initState() {
    super.initState();
    _loadSwitchState();
    _cekIzinLokasi('oneTimeCheck');

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
                body: Consumer<DataProvider>(
                    builder: (context, dataProvider, child) {
                  final pagiAttendanceStatus = dataProvider.statusAbsensiPagi;
                  final siangAttendanceStatus = dataProvider.statusAbsensiSiang;

                  return Consumer<TimeProvider>(
                      builder: (context, timeProvider, child) {
                    final dateTime = timeProvider.currentTime;
                    final morningAttendanceState =
                        timeProvider.isPagiButtonActive();
                    final afternoonAttendanceState =
                        timeProvider.isSiangButtonActive();
                    final statusAttendance =
                        timeProvider.attendanceStatus == 'T'
                            ? 'Tepat Waktu'
                            : 'Lewat Waktu';
                    final keterangan = "";

                    return SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 20, left: 4, right: 4),
                              child: Text.rich(
                                style: const TextStyle(fontSize: 18),
                                TextSpan(
                                  text: _attendanceLocationStatus,
                                  // Teks tetap
                                  children: [
                                    TextSpan(
                                      text:
                                          _statusWithDots, // Titik yang bergerak
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
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
                                              onPressed: !pagiAttendanceStatus ||
                                                      (morningAttendanceState &&
                                                          _attendancePermission)
                                                  ? () {
                                                      print(
                                                          'taekkkkk bdm pea: ${dateTime.postTime()}');
                                                      print(
                                                          'taekkkkk ayam pea: ${timeProvider.attendanceStatus}');
                                                      final attendanceData =
                                                          Data(
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
                                                        tanggal: dateTime
                                                            .getIdnDate(),
                                                        // namaKaryawan: 'SADIQ',
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
                                                          _attendanceProcess(
                                                                  'pagi',
                                                                  attendance)
                                                              .then((_) => timeProvider
                                                                  .onButtonClick(
                                                                      'pagi'));
                                                        },
                                                      );
                                                    }
                                                  : null,
                                              child: const Text('Absen Pagi'),
                                            ),
                                            attendanceStatus(
                                              dataProvider,
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
                                                  (afternoonAttendanceState &&
                                                          _attendancePermission)
                                                      ? () {
                                                          print(
                                                              'taekkkkk bdm pea: ${dateTime.postTime()}');
                                                          print(
                                                              'taekkkkk ayam pea: ${timeProvider.attendanceStatus}');
                                                          final attendanceData =
                                                              Data(
                                                            tLSiang: timeProvider
                                                                .attendanceStatus,
                                                            pulangSiang:
                                                                dateTime
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
                                                            namaKaryawan: widget
                                                                .employeeName
                                                                .toUpperCase(),
                                                            data:
                                                                attendanceData,
                                                          );
                                                          DialogUtils
                                                              .showConfirmationDialog(
                                                            context: context,
                                                            title:
                                                                "Absen Siang",
                                                            content: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                const Text(
                                                                    'Absen Sekarang?'),
                                                                const SizedBox(
                                                                  height: 10,
                                                                ),
                                                                CustomTextFormField(
                                                                  hintText:
                                                                      'Keterangan',
                                                                  labelText:
                                                                      'Keterangan',
                                                                  onChanged:
                                                                      (value) {
                                                                    attendanceData
                                                                            .keterangan =
                                                                        value;
                                                                  },
                                                                  maxLines: 3,
                                                                  autoValidate:
                                                                      true,
                                                                  validator:
                                                                      (value) {
                                                                    if (value!
                                                                        .isEmpty) {
                                                                      return 'Keterangan tidak boleh kosong';
                                                                    }
                                                                    return null;
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                            onConfirm: () {
                                                              _attendanceProcess(
                                                                      'siang',
                                                                      attendance)
                                                                  .then(
                                                                (_) => timeProvider
                                                                    .onButtonClick(
                                                                        'siang'),
                                                              );
                                                            },
                                                          );
                                                        }
                                                      : null,
                                              child: const Text('Absen Siang'),
                                            ),
                                            attendanceStatus(
                                              dataProvider,
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
                            const Divider(
                              thickness: 3,
                            ),
                            // Switch untuk mengaktifkan dan menonaktifkan stream
                            ListTile(
                              title: Text(
                                  '${!_isStreaming ? 'Aktifkan' : 'Nonaktifkan'} Lokasi Real-time'),
                              trailing: Switch(
                                value: _isStreaming,
                                onChanged: _permissionGranted ? _toggleSwitch : null,
                              ),
                              onTap: null,
                            ),
                            ListTile(
                              title: const Text('Cek Lokasi Anda dan Toko'),
                              trailing: IconButton(
                                icon: const Icon(Icons.map),
                                iconSize: 40,
                                onPressed: () => _cekIzinLokasi('mapCheck'),
                              ),
                              onTap: null,
                            ),
                            ListTile(
                              title: const Text('Perbarui Waktu Break Siang'),
                              subtitle: Text('(Mulai pukul 12.00 WITA)'),
                              trailing: IconButton(
                                icon: const Icon(Icons.dining_outlined),
                                iconSize: 40,
                                onPressed: _updateBreakTime,
                              ),
                            ),
                            ListTile(
                              title: const Text('Testing Page'),
                              subtitle: Text('(Tes Sistem Keterangan)'),
                              trailing: IconButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TestPage(),
                                    )),
                                iconSize: 40,
                                icon: const Icon(Icons.telegram),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            const Divider(),
                            const SizedBox(
                              height: 10,
                            ),
                            const Text(
                              'Keterangan: ',
                              style: TextStyle(
                                fontFamily: 'Mulish',
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            const Text(
                              'Izin / Sakit / Terlambat',
                              style: TextStyle(
                                fontFamily: 'Mulish',
                                fontSize: 20,
                              ),
                            ),
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
                  });
                }),
                floatingActionButton: FloatingActionButton(
                  onPressed: _fabLoading ? null : _updateLocation,
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

  Widget attendanceStatus(
    DataProvider dataProvider, {
    String? attendance,
    String? attendanceTime,
    String? breakTime,
    String? status,
    String? point,
    String? lat,
    String? long,
  }) {
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
        lat = _userPositionLatitude.toString();
        long = _userPositionLongitude.toString();
      }
    }

    if (attendance == 'siang') {
      if (attendanceData.hadirSiang == null ||
          attendanceData.hadirSiang!.isEmpty) {
        return const SizedBox();
      } else {
        breakTime =
            CustomTime.fromServerTime(attendanceData.pulangSiang!).getIdnTime();
        attendanceTime =
            CustomTime.fromServerTime(attendanceData.hadirSiang!).getIdnTime();

        status = attendanceData.tLSiang == 'T' ? 'Tepat Waktu' : 'Lewat Waktu';
        point = attendanceData.pointSiang ?? '-';
        // lat = attendanceData.latSiang! ?? '-';
        // long = attendanceData.longSiang! ?? '-';
        lat = _userPositionLatitude.toString();
        long = _userPositionLongitude.toString();
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
        Text('Keterangan: ${attendanceData.keterangan ?? '-'}'),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }
}

// SwitchListTile(
//   title: Text('${!_isStreaming ? 'Aktifkan' : 'Nonaktifkan'} Lokasi Real-time'),
//   value: _isStreaming,
//   onChanged: (bool value) {
//     _toggleStreaming(value);
//   },
// ),
// const SizedBox(height: 20),
// Row(
//   mainAxisAlignment: MainAxisAlignment.center,
//   children: [
//     ElevatedButton(
//       onPressed: _cekLokasiSekali,
//       child: const Text('Cek Lokasi'),
//     ),
//     IconButton(
//         onPressed: () => Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => TestPage(),
//             )),
//         icon:
//             const Icon(Icons.check_circle_outline)),
//   ],
// ),
// FilledButton(
//   onPressed: () {
//     Navigator.pushNamed(
//       context,
//       '/map',
//       arguments: MapPageArguments(
//         storeLocation:
//             LatLng(_storeLatitude, _storeLongitude),
//         storeRadius: _maxDistance,
//       ),
//     );
//   },
//   child: const Text('Lihat Posisi'),
// ),
// const SizedBox(
//   height: 20,
// ),
