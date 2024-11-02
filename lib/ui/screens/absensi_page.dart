import 'dart:async';
import 'dart:math' as math;

import 'package:absensitoko/core/constants/constants.dart';
import 'package:absensitoko/data/models/attendance_info_model.dart';
import 'package:absensitoko/data/models/history_model.dart';
import 'package:absensitoko/locator.dart';
import 'package:absensitoko/routes.dart';
import 'package:absensitoko/data/models/attendance_model.dart';
import 'package:absensitoko/data/models/time_model.dart';
import 'package:absensitoko/data/providers/data_provider.dart';
import 'package:absensitoko/data/providers/time_provider.dart';
import 'package:absensitoko/core/themes/fonts/fonts.dart';
import 'package:absensitoko/ui/widgets/CustomListTile.dart';
import 'package:absensitoko/utils/base/base_state.dart';
import 'package:absensitoko/ui/widgets/custom_text_form_field.dart';
import 'package:absensitoko/utils/base/location_service.dart';
import 'package:absensitoko/utils/dialogs/dialog_utils.dart';
import 'package:absensitoko/utils/helpers/general_helper.dart';
import 'package:absensitoko/utils/popup_util.dart';
import 'package:absensitoko/utils/dialogs/loading_dialog_util.dart';
import 'package:absensitoko/ui/widgets/network_connectivity.dart';
import 'package:absensitoko/utils/helpers/network_helper.dart';
import 'package:absensitoko/ui/test/data_provider_test_page.dart';
import 'package:absensitoko/ui/test/keterangan_test_page.dart';
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

/// - Antrian 3 :
/// - Pembuatan akun admin yang dapat mengelola :
///     1. Data karyawan (Get all user)
///     2. Data absensi (ketika diabsenkan bos misalnya, tanpa waktu) (update by admin)
///     3. Penentuan hari libur (admin only)
///     4. Penentuan jam break siang (admin only)
///     5. Merubah absensi karyawan (update by admin)
///     6. Kontrol Absensi karyawan (Get all user, get all complete data)
///     7. Pembuatan sheet bulan baru (new sheets)
///     8. Sistem reset password dan sistem register by admin aja kaya najwa
/// - Akun admin bisa ngerubah hasil absensi karywan dihari yang sama (misal ada yg lupa absen)

/// - Antrian 2 :
/// - Load datanya bersamaan dengan load posisi dan load breaktime
/// - (belum ada perbedaan hari disini, harunya hari ahad ato tanggal merah itu masuk toko jam 7.30 brt absen jam 7.20 - 7.80
/// - Buat fitur ambil data absen hari yg sama dulu
/// - Kalau udah ada data sistem false cek absen di timeprovider diganti dengan cek ada data absennya gak
/// - Waktu start absen khusus hari libur dan ahad yang berbeda
/// - Kalau ada dua keterangan di pisah koma aja, artinya keterangan pagi dan siang ketika absen siang telat misal ada keterangan yg sudah terisi di gabung sama keterangan baru
/// - Ketika pop dari map harusnya refresh lagi halaman absennya
/// - Pengeolaan absensi ketika ganti hari, misalnya data di provider udah terisi maka diesok hari akan ke reset (pakai shared preference)
/// - Ketika Sudah Absen diHome Akan muncul juga info udah absen dengan provider data yg sama seperti di Halaman Absen
/// - Init data absen dengan firestore dan sheets
/// - Tidak ada pengecekan apakah sudah absen atau belum
/// - Log yang menyimpan semuanya dan lat long sekaligus (extend model dengan lat long)

/// - Antrian 1 :
/// - Jadi ntar pas masuk ke halaman Absen itu langsung auto load data absensi hari ini, break time dan posisi lokasi secara bersamaan
/// - BreakTime dan Keterangan libur disimpan pada firestore biar mudah proses ambilnya.
/// - Tanggal Merah jam masuk pagi berbeda
/// (LEBIH LENGKAPNYA CEK NOTE NGOBROL DGN ABI)

/// ---------------------------- (FOKUS) ----------------------------
/// * Percobaan awal get data dari firestore adalah data breaktime dan holiday
/// * FOKUS FIRESTORE DAN SHEETS, GET DATA UNTUK INFORMASI UDAH ABSENNYA APA BELUM
/// * log firestore untuk informasi sudah absen atau belum yg disimpan pada data FirestoreService dan DataProvider
/// * absen pagi
/// * absen siang dan updateBreakTime
/// * Mbeneri Sistem Tombolnya kapan bisa diklik dan kapan tidak
/// * kemudian dilanjutkan dengan update di sheets (saat ini masih update disheet aja)
/// * Keterangan Telat / tidak masuk
/// * Tambahkan timeout popup absensi, kalo bisa ada timernya juga

/// Yang kurang dihalaman ini adalah : -------------- (FOKUS) --------------
/// @Timer waktu absen pagi dan siang, timer muncul ketika memasuki rentang waktu absen
/// @Tombol absen pagi dan siang hanya bisa di klik ketika memasuki rentang waktu absen
/// @Tombol absen pagi dan siang tidak bisa di klik ketika sudah absen
/// @Rentang waktu terbagi menjadi dua rentang waktu, yaitu waktu on off tombol absen sekitar 3 jam, dan waktu absen tepat waktu 30 menit (20 menit lebih awal dan 10 menit tambahan)
/// @Kolom absensi T/L, 30 menit awal T, lewat dari itu L (absen pagi atau siang)

/// Lengkapi sisa yg kemarin : -------------- (FOKUS) --------------
/// * Cara update otomatis seperti initial data otomatis, atau update info absen holiday dengan menyimpan waktu kemarin di shared preference lalu mencocokkannya dengan waktu saat ini di halaman home
/// * Bagian terakhir dari data provider, yaitu :
///   * getData, dan autogetdata after update data
///   * Create new sheet for absensi bulan baru
/// * Otak atik UserProvider biar simple kaya DataProvider
/// * Tambahkan SessionService untuk nyimpen tanggalnya, perangkat dll
/// * Dafta kelas yg blom dipakek : UpdatePage, TimePicker, PermissionHandler, ListItem, DialogManager, CustomDropDownMenu
/// * Stop Timer Provider Setiap pindah2 halaman (mungkin atau tetap seperti ini?)
/// * Buat logo aplikasi
/// * Buat splash screen
/// * Memulai pengelolaan versi
/// * Contoh timeout itu ada dihalaman login tombol login, kalo misalnya 10 detik gak ada respon auto batal login
/// * urutan sistem otomatis reset data dan init data hari baru adalah:
///   - Cek data apakah sudah diinit atau belum?
///   - Jika belum diinit maka init data
///   - Jika pathnya sudah ada(sudah diinit), maka simpan tanggal hari ini dishared preference
///   - ketika data udah ada dan tanggal udah ada berati lanjut ke cek tanggal yg udh disimpan sama tgl saat ini
///   - ketika ganti hari cek tanggal hari ini dengan tanggal yang disimpan di shared preference
///   - kalau masih sama artinya belum ganti hari, kalau berbeda udh ganti hari maka reset data
///   - lalu kembali ke awal inti data dulu baru save tanggal hari baru.
/// (Mocked masih gak berfungsi ya)

class AbsensiPage extends StatefulWidget {
  final String employeeName;

  const AbsensiPage({super.key, required this.employeeName});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends BaseState<AbsensiPage>
    with SingleTickerProviderStateMixin {
  final locationService = locator<LocationService>();
  late DataProvider _dataProvider;
  late TimeProvider _timeProvider;

  // Titik absensi yang ditentukan
  final double _storeLatitude = -8.5404;
  final double _storeLongitude = 118.4611;
  final double _maxDistance = 8.0;
  double? _userPositionLatitude;
  double? _userPositionLongitude;

  // Pengecek izin absen yang dibolehkan
  bool _permissionGranted = false;
  bool _attendancePermission = false;
  String _attendanceLocationStatus = 'Mengecek lokasi absen';
  Timer? _coordinateCheckTimer;
  String _statusWithDots = '';
  int _dotCount = 1;

  // Stream lokasi pengguna
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isStreaming = false; // untuk switch status
  bool _initStreamLocation = true;

  // Animasi FAB
  late AnimationController _controller;
  bool _fabLoading = false;

  // Data Absensi
  late String _employeeName;
  late String _currentTime;
  late int _weekday;

  // Minta izin akses lokasi
  Future<void> _cekIzinLokasi(String check, {bool? switchValue}) async {
    PermissionStatusResult permissionResult =
        await locationService.cekIzinLokasi();
    print(permissionResult.statusMessage);

    setState(() => _permissionGranted = permissionResult.isGranted);

    if (!_permissionGranted) {
      return; // Jika izin tidak diberikan, keluar dari fungsi
    }

    switch (check) {
      case 'oneTimeCheck':
        _loadingGetCoordinateLocation();
        await _cekLokasiSekali();
        break;
      case 'realTimeCheck':
        _toggleStreaming(switchValue!);
        break;
      case 'mapCheck':
        _navigateToMap();
        break;
    }
  }

  void _navigateToMap() {
    Navigator.pushNamed(
      context,
      '/map',
      arguments: MapPageArguments(
        storeLocation: LatLng(_storeLatitude, _storeLongitude),
        storeRadius: _maxDistance,
      ),
    );
  }

  void _cekJarak(Position posisiPengguna) {
    double jarak = Geolocator.distanceBetween(
      _storeLatitude,
      _storeLongitude,
      posisiPengguna.latitude,
      posisiPengguna.longitude,
    );

    if (_initStreamLocation) {
      _coordinateCheckTimer?.cancel();
      setState(() => _initStreamLocation = false);
    }

    setState(() {
      _statusWithDots = '';
      _attendancePermission = jarak <= _maxDistance;
      _attendanceLocationStatus = _attendancePermission
          ? 'Dapat mengisi absen.\nAnda berada dalam radius absensi toko ${jarak.toStringAsFixed(2)} meter.'
          : 'Tidak dapat mengisi absen.\nAnda terlalu jauh dari Toko,\nJarak ke Toko: ${jarak.toStringAsFixed(2)} meter.';
    });
  }

  Future<void> _cekLokasiSekali() async {
    await locationService.cekLokasiSekali().then((posisiPengguna) {
      if (posisiPengguna.isMocked) {
        setState(() {
          _attendanceLocationStatus = 'Lokasi palsu terdeteksi!';
          _attendancePermission = false;
        });
      } else {
        setState(() {
          _userPositionLatitude = posisiPengguna.position!.latitude;
          _userPositionLongitude = posisiPengguna.position!.longitude;
          _attendanceLocationStatus = 'Lokasi asli terdeteksi.';
        });

        _cekJarak(posisiPengguna.position!);

        safeContext((context) => LoadingDialog.hide(context));
        _coordinateCheckTimer?.cancel();
      }
    });
  }

  void _loadingGetCoordinateLocation() {
    setState(() {
      _attendanceLocationStatus = 'Mengecek lokasi absen';
      _dotCount = 1;
    });
    _coordinateCheckTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        setState(() {
          _dotCount = (_dotCount % 6) + 1;
          _statusWithDots = '.' * _dotCount;
        });
        print(_attendanceLocationStatus + _statusWithDots);
      },
    );
  }

  void _fabUpdateLocation() async {
    setState(() => _fabLoading = true);
    _controller.repeat();
    await Future.delayed(const Duration(seconds: 1));
    await _cekIzinLokasi('oneTimeCheck');
    setState(() => _fabLoading = false);
    await _controller.animateTo(1.0,
        duration: const Duration(milliseconds: 500));
    _controller.reset();
  }

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

  void _startListeningLocationUpdates() {
    if (_positionStreamSubscription != null) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position posisiPengguna) {
      if (posisiPengguna.isMocked) {
        setState(() {
          _attendanceLocationStatus =
              'Lokasi palsu terdeteksi! Tidak dapat mengisi absen.';
          _attendancePermission = false;
        });
      } else {
        setState(() {
          _userPositionLatitude = posisiPengguna.latitude;
          _userPositionLongitude = posisiPengguna.longitude;
        });
        _cekJarak(posisiPengguna);
      }
    });
  }

  void _stopListeningLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  Future<void> _toggleSwitch(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isStreaming = value);
    await prefs.setBool('isStreaming', _isStreaming);
    await _cekIzinLokasi('realTimeCheck', switchValue: value);
  }

  Future<void> _loadLocationState() async {
    final prefs = await SharedPreferences.getInstance();
    bool isStreaming = prefs.getBool('isStreaming') ?? false;
    setState(() => _isStreaming = isStreaming);

    if (_isStreaming) {
      _loadingGetCoordinateLocation();
      _cekIzinLokasi('realTimeCheck', switchValue: _isStreaming);
    } else {
      _cekIzinLokasi('oneTimeCheck');
    }
  }

  Future<void> _attendanceProcess(
      String waktuAbsensi, Attendance attendance) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    LoadingDialog.show(context);
    try {
      final message =
          await dataProvider.updateAttendance(waktuAbsensi, attendance);
      safeContext((context) => LoadingDialog.hide(context));

      print("Status and Message: $message");
      if (message.status == 'success') {
        ToastUtil.showToast('Berhasil mencatat kehadiran', ToastStatus.success);
      } else {
        ToastUtil.showToast(message.message ?? '', ToastStatus.error);
      }
    } catch (e) {
      safeContext((context) => LoadingDialog.hide(context));
      ToastUtil.showToast('Gagal memproses kehadiran', ToastStatus.error);
    }
  }

  Future<void> _updateBreakTime(bool refresh) async {
    if (!_dataProvider.isAttendanceInfoAvailable || refresh) {
      print('${!refresh ? 'Mendapatkan' : 'Memperbarui'} Waktu Break Siang');
      final result = await _dataProvider.getAttendanceInfo(isRefresh: refresh);
      if (result.status == 'success') {
        // final info = dataProvider.attendanceInfoData!;
        String breakTime = '12:00';

        if(_weekday == DateTime.friday){
          breakTime = '$fridayAfternoonStartHour:$fridayAfternoonStartMinute';
        } else if (_weekday == DateTime.sunday) {
          breakTime = '$sundayAfternoonStartHour:$sundayAfternoonStartMinute';
        } else {
          // Default Break Time Sama kek di timeProvider
          breakTime = _dataProvider.attendanceInfoData?.breakTime ?? '12:00';
        }
        List<String> breakTimeParts = breakTime.split(':');
        int breakHour = int.parse(breakTimeParts[0]);
        int breakMinute = int.parse(breakTimeParts[1]);

        _timeProvider.updateBreakTime(breakHour, breakMinute);
        ToastUtil.showToast(
            'Berhasil ${!refresh ? 'Mendapatkan' : 'Memperbarui'} Waktu Break Siang', ToastStatus.success);
      } else {
        ToastUtil.showToast(result.message ?? '', ToastStatus.error);
      }
    } else {
      ToastUtil.showToast('Informasi Absen sudah ada', ToastStatus.success);
      print('Informasi Absen sudah ada');
    }
  }

  Future<void> getAttendanceHistory(bool refresh) async {
    if (!_dataProvider.isSelectedDateHistoryAvailable || refresh) {
      print('${!refresh ? 'Mendapatkan' : 'Memperbarui'} Data Absensi');
      final result = await _dataProvider
          .getThisDayHistory(_employeeName, _currentTime, isRefresh: refresh);
      if (result.status == 'success') {
        ToastUtil.showToast(
            'Berhasil mendapatkan data absensi', ToastStatus.success);
      } else {
        ToastUtil.showToast(result.message ?? '', ToastStatus.error);
      }
    } else {
      print('Data Absensi sudah ada');
    }
  }

  Future<void> _initData() async {
    _employeeName = widget.employeeName;
    _dataProvider = Provider.of<DataProvider>(context, listen: false);
    _timeProvider = Provider.of<TimeProvider>(context, listen: false);
    _currentTime = _timeProvider.currentTime.postHistory();
    _weekday = _timeProvider.currentTime.getWeekday();
    _dataProvider.initializeHistory(_employeeName, _currentTime);
    getAttendanceHistory(false);
  }

  @override
  void initState() {
    super.initState();
    _initData();

    _loadLocationState();
    _updateBreakTime(false);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
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
                body: ConnectionChecker(
                  connectedWidget: SingleChildScrollView(
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
                                    text: _statusWithDots,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Consumer<DataProvider>(
                            builder: (context, dataProvider, child) {
                              if (!dataProvider.isAttendanceInfoAvailable) {
                                return const SizedBox.shrink();
                              }

                              if (!dataProvider
                                  .isSelectedDateHistoryAvailable) {
                                return const SizedBox.shrink();
                              }

                              final infoAttendance =
                                  dataProvider.attendanceInfoData!;
                              final breakTimeStart = infoAttendance
                                      .breakTime!.isNotEmpty
                                  ? 'Waktu break mulai jam : ${infoAttendance.breakTime}'
                                  : 'Waktu break belum diperbarui';
                              // final pagiAttendanceStatus =
                              //     dataProvider.statusAbsensiPagi;
                              // final siangAttendanceStatus =
                              //     dataProvider.statusAbsensiSiang;

                              HistoryData historyData =
                                  dataProvider.selectedDateHistory ??
                                      HistoryData();

                              return Consumer<TimeProvider>(
                                builder: (context, timeProvider, child) {
                                  final dateTime = timeProvider.currentTime;
                                  final morningAttendanceState =
                                      timeProvider.isPagiButtonActive(
                                          historyData, infoAttendance.nationalHoliday ?? '');
                                  final afternoonAttendanceState =
                                      timeProvider.isSiangButtonActive(
                                          historyData);
                                  final isBreakTime = isCurrentTimeWithinRange(
                                    dateTime.getDefaultDateTime(),
                                    '12:00',
                                    '17:30',
                                  );

                                  return Card(
                                    color: Colors.blue,
                                    child: Stack(
                                      children: [
                                        Column(
                                          children: [
                                            _buildCountdownText(timeProvider),
                                            AttendanceCard(
                                              title: 'Absen Pagi',
                                              buttonText: 'Absen Pagi',
                                              buttonActive:
                                                  morningAttendanceState &&
                                                      _attendancePermission,
                                              onButtonPressed: () {
                                                _onAttendanceButtonPressed(
                                                  context,
                                                  timeProvider,
                                                  'pagi',
                                                  dateTime,
                                                  widget.employeeName,
                                                );
                                              },
                                              attendanceStatus:
                                                  attendanceStatus(dataProvider,
                                                      attendance: 'pagi'),
                                              message: timeProvider
                                                  .morningAttendanceMessage,
                                            ),
                                            AttendanceCard(
                                              title: 'Absen Siang',
                                              buttonText: 'Absen Siang',
                                              buttonActive:
                                                  afternoonAttendanceState &&
                                                      _attendancePermission,
                                              onButtonPressed: () {
                                                _onAttendanceButtonPressed(
                                                  context,
                                                  timeProvider,
                                                  'siang',
                                                  dateTime,
                                                  widget.employeeName,
                                                );
                                              },
                                              attendanceStatus:
                                                  attendanceStatus(dataProvider,
                                                      attendance: 'siang'),
                                              message: timeProvider
                                                  .afternoonAttendanceMessage,
                                            ),
                                            if (isBreakTime)
                                              Text(
                                                breakTimeStart,
                                                style: const TextStyle(
                                                  fontFamily: 'Mulish',
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ElevatedButton(onPressed: () {
                                              print('Pagi: $morningAttendanceState');
                                              print('Siang: $afternoonAttendanceState');
                                              print('Permission: $_attendancePermission');
                                            }, child: Text('Check')),
                                          ],
                                        ),
                                        if (dataProvider.isLoading)
                                          const Positioned.fill(
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          const SizedBox(
                            height: 10,
                          ),
                          const Divider(
                            thickness: 3,
                          ),
                          CustomListTile(
                            title: 'Aktifkan atau Nonaktifkan Lokasi Real-time',
                            trailing: Switch(
                              value: _isStreaming,
                              onChanged:
                                  _permissionGranted ? _toggleSwitch : null,
                            ),
                          ),
                          // Switch untuk mengaktifkan dan menonaktifkan stream
                          CustomListTile(
                            title: 'Cek Lokasi Anda dan Toko',
                            trailing: IconButton(
                              icon: const Icon(Icons.map),
                              iconSize: 40,
                              onPressed: () => _cekIzinLokasi('mapCheck'),
                            ),
                          ),
                          CustomListTile(
                            title: 'Perbarui Waktu Break Siang',
                            subtitle: '(Mulai pukul 12.00 WITA)',
                            trailing: IconButton(
                              icon: const Icon(Icons.dining_outlined),
                              iconSize: 40,
                              onPressed: () async => _updateBreakTime(true),
                            ),
                          ),
                          CustomListTile(
                            title: 'Testing Page',
                            subtitle: '(Tes Sistem Keterangan)',
                            trailing: IconButton(
                              icon: const Icon(Icons.telegram),
                              iconSize: 40,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TestPage(),
                                ),
                              ),
                            ),
                          ),
                          CustomListTile(
                            title: 'Testing Page 2',
                            subtitle: '(Tes Sistem Data Provider)',
                            trailing: IconButton(
                              icon: const Icon(Icons.telegram),
                              iconSize: 40,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TestDataProviderPage(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                          const SizedBox(height: 10),
                          const Text(
                            'Keterangan: ',
                            style: TextStyle(
                              fontFamily: 'Mulish',
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Izin / Sakit / Terlambat',
                            style: TextStyle(
                              fontFamily: 'Mulish',
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: _fabLoading
                      ? null
                      : () async {
                          bool isConnected =
                              await NetworkHelper.hasInternetConnection();
                          if (!isConnected) {
                            ToastUtil.showToast('Tidak ada koneksi internet',
                                ToastStatus.error);
                            return;
                          }
                          _fabUpdateLocation();
                        },
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

  Widget _buildCountdownText(TimeProvider timeProvider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        timeProvider.countDownText,
        style: const TextStyle(
          fontFamily: 'Digital7',
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _onAttendanceButtonPressed(
    BuildContext context,
    TimeProvider timeProvider,
    String attendanceType,
    CustomTime dateTime,
    String employeeName,
  ) {
    final attendanceData = Data(
      tLPagi: timeProvider.attendanceStatus,
      hadirPagi: dateTime.postTime(),
      pointPagi: '0',
    );
    final attendance = Attendance(
      action: 'update',
      tahunBulan: dateTime.getYearMonth(),
      tanggal: dateTime.getIdnDate(),
      namaKaryawan: employeeName.toUpperCase(),
      data: attendanceData,
    );

    DialogUtils.showConfirmationDialog(
      context: context,
      title: 'Absen $attendanceType',
      content: const Text('Absen Sekarang?'),
      onConfirm: () {
        _attendanceProcess(attendanceType, attendance).then(
          (_) => timeProvider.onButtonClick(attendanceType),
        );
      },
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
    final attendanceData = dataProvider.dataAbsensi!;
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
      if (attendanceData!.hadirSiang == null ||
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
        Text('Keterangan: ${attendanceData!.keterangan ?? '-'}'),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }
}

class AttendanceCard extends StatelessWidget {
  final String title;
  final String buttonText;
  final bool buttonActive;
  final VoidCallback onButtonPressed;
  final Widget attendanceStatus;
  final String message;

  const AttendanceCard({
    required this.title,
    required this.buttonText,
    required this.buttonActive,
    required this.onButtonPressed,
    required this.attendanceStatus,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const SizedBox(height: 10),
              Text(
                title,
                style: FontTheme.bodyMedium(
                  context,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: buttonActive ? onButtonPressed : null,
                child: Text(buttonText),
              ),
              attendanceStatus,
              if (message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: 18,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// Cek izin pengguna untuk mengakses lokasi
/*
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
*/

// Cek apakah pengguna berada dalam radius absensi
/*
  Future<void> _cekLokasiSekali() async {
    try {
      safeContext((context) => LoadingDialog.show(context));
      Position posisiPengguna = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // setState(() {
      //   _userPositionLatitude = posisiPengguna.latitude;
      //   _userPositionLongitude = posisiPengguna.longitude;
      // });

      // Lokasi menggunakan mock atau fake GPS
      if (posisiPengguna.isMocked) {
        setState(() {
          _attendanceLocationStatus = 'Lokasi palsu terdeteksi!';
          _attendancePermission = false;
        });
      } else {
        setState(() {
          _userPositionLatitude = posisiPengguna.latitude;
          _userPositionLongitude = posisiPengguna.longitude;
          _attendanceLocationStatus = 'Lokasi asli terdeteksi.';
        });

        _cekJarak(posisiPengguna); // Cek jarak sekali
      }

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
*/

// Button Backup
/*
SwitchListTile(
  title: Text('${!_isStreaming ? 'Aktifkan' : 'Nonaktifkan'} Lokasi Real-time'),
  value: _isStreaming,
  onChanged: (bool value) {
    _toggleStreaming(value);
  },
),
const SizedBox(height: 20),
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    ElevatedButton(
      onPressed: _cekLokasiSekali,
      child: const Text('Cek Lokasi'),
    ),
    IconButton(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TestPage(),
            )),
        icon:
            const Icon(Icons.check_circle_outline)),
  ],
),
FilledButton(
  onPressed: () {
    Navigator.pushNamed(
      context,
      '/map',
      arguments: MapPageArguments(
        storeLocation:
            LatLng(_storeLatitude, _storeLongitude),
        storeRadius: _maxDistance,
      ),
    );
  },
  child: const Text('Lihat Posisi'),
),
const SizedBox(
  height: 20,
),
*/
