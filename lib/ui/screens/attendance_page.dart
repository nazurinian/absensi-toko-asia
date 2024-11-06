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
import 'package:absensitoko/ui/widgets/custom_list_tile.dart';
import 'package:absensitoko/utils/base/base_state.dart';
import 'package:absensitoko/ui/widgets/custom_text_form_field.dart';
import 'package:absensitoko/utils/base/location_service.dart';
import 'package:absensitoko/utils/dialogs/dialog_utils.dart';
import 'package:absensitoko/utils/display_size_util.dart';
import 'package:absensitoko/utils/helpers/general_helper.dart';
import 'package:absensitoko/utils/popup_util.dart';
import 'package:absensitoko/utils/dialogs/loading_dialog_util.dart';
import 'package:absensitoko/ui/widgets/network_connectivity.dart';
import 'package:absensitoko/utils/helpers/network_helper.dart';
import 'package:absensitoko/ui/test/data_provider_test_page.dart';
import 'package:absensitoko/ui/test/keterangan_test_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// - Antrian 2 :
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
/// - Akun admin bisa ngasih izin atau akses super user terbatas seperti untuk nginput breaktime siang, tambah properti model ini

/// - Antrian 1 :
/// - Gabungkan keterangan
/// - Kalau ada dua keterangan di pisah koma aja, artinya keterangan pagi dan siang ketika absen siang telat misal ada keterangan yg sudah terisi di gabung sama keterangan baru
/// - Pengeolaan absensi ketika ganti hari, misalnya data di provider udah terisi maka diesok hari akan ke reset (pakai shared preference)
/// - Custom Dialog untuk menampilkan keterangan absen
/// - menerapkan sistem penulisan keterangan pada kondisi late
/// - Penerapan history ketika klik tombol absen untuk pencatatan di google sheets dan history
/// - bisa buat absen sehari sebelum ganti bulan

/// ---------------------------- (FOKUS) ----------------------------
/// * FOKUS FIRESTORE DAN SHEETS, GET DATA UNTUK INFORMASI UDAH ABSENNYA APA BELUM
/// * kemudian dilanjutkan dengan update di sheets (saat ini masih update disheet aja)
/// * Keterangan Telat / tidak masuk
/// * Cara update otomatis seperti initial data otomatis, atau update info absen holiday dengan menyimpan waktu kemarin di shared preference lalu mencocokkannya dengan waktu saat ini di halaman home
/// * Bagian terakhir dari data provider, yaitu :
///   * getData, dan autogetdata after update data
///   * Create new sheet for absensi bulan baru
/// * Tambahkan SessionService untuk nyimpen tanggalnya, perangkat dll
/// * Dafta kelas yg blom dipakek : CustomDropDownMenu

/// * urutan sistem otomatis reset data dan init data hari baru adalah:
///   @ Jika belum diinit maka init data
///   - Jika pathnya sudah ada(sudah diinit), maka simpan tanggal hari ini dishared preference
///   - ketika data udah ada dan tanggal udah ada berati lanjut ke cek tanggal yg udh disimpan sama tgl saat ini
///   - ketika ganti hari cek tanggal hari ini dengan tanggal yang disimpan di shared preference
///   - kalau masih sama artinya belum ganti hari, kalau berbeda udh ganti hari maka reset data
///   - lalu kembali ke awal inti data dulu baru save tanggal hari baru.

/// Fokus baru :
/// * Tombol untuk membuat sheet baru
/// * Sistem Keterangan
/// * Buat logo aplikasi
/// * Buat splash screen
/// * Melakukan update sheet dan history bersamaan
/// * Rapih-rapih halaman absensi
/// * Popup update datanya belum di uncomment
/// * Cek _attendanceProcess dan attendanceStatus (SEBLUM TIDUR ANE AKTIFKAN DIALOGNYA SAMA BALIKIN WAKTU NTP)
/// * Cek kalau gagal ambil wakut dr ntp gimana?

class AttendancePage extends StatefulWidget {
  final String employeeName;
  final String deviceName;

  const AttendancePage(
      {super.key, required this.employeeName, required this.deviceName});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends BaseState<AttendancePage>
    with TickerProviderStateMixin {
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
  bool _fabLoading = false;
  bool _stopLoading = false;
  late ScrollController _scrollController;
  late AnimationController _opacityController;
  late AnimationController _rotationController;
  bool _showFab = false; // Awalnya FAB tidak tampak

  // Data Absensi
  late String _employeeName;
  late CustomTime _currentTime;
  late int _weekday;
  bool _isLoadingGetBreakTime = false;

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
      if (mounted) {
        if (posisiPengguna.isMocked) {
          setState(() {
            _attendanceLocationStatus = 'Lokasi palsu terdeteksi!';
            _statusWithDots = '';
            _attendancePermission = false;
          });
        } else {
          setState(() {
            _userPositionLatitude = posisiPengguna.position!.latitude;
            _userPositionLongitude = posisiPengguna.position!.longitude;
            _attendanceLocationStatus = 'Lokasi asli terdeteksi.';
          });

          _cekJarak(posisiPengguna.position!);
        }

        if (!_stopLoading) {
          LoadingDialog.hide(context);
        }
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
    setState(() => _stopLoading = false);
    _rotationController.repeat();
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      LoadingDialog.show(context, onPopInvoked: () {
        LoadingDialog.hide(context);
        setState(() => _stopLoading = true);
      });
    }
    await _cekIzinLokasi('oneTimeCheck');
    setState(() => _fabLoading = false);
    await _rotationController.animateTo(1.0,
        duration: const Duration(milliseconds: 500));
    _rotationController.reset();
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
      setState(() => _stopLoading = false);
      safeContext((context) => LoadingDialog.show(context, onPopInvoked: () {
            LoadingDialog.hide(context);
            setState(() => _stopLoading = true);
          }));
      _cekIzinLokasi('oneTimeCheck');
    }
  }

  Future<void> _updateBreakTime({bool isRefresh = false}) async {
    if (_dataProvider.isAttendanceInfoAvailable && !isRefresh) {
      print('Informasi Absen sudah ada');
      ToastUtil.showToast('Informasi Absen sudah ada', ToastStatus.success);
      return;
    }

    String action = isRefresh ? 'Memperbarui' : 'Mendapatkan';
    print('$action waktu break siang');

    final result = await _dataProvider.getAttendanceInfo(isRefresh: isRefresh);
    if (result.status == 'success') {
      String breakTime = '12:00';
      String nationalHoliday =
          _dataProvider.attendanceInfoData?.nationalHoliday ?? '';
      bool isHoliday =
          nationalHoliday.isNotEmpty || _weekday == DateTime.sunday;

      if (_weekday == DateTime.friday) {
        breakTime = '$fridayAfternoonStartHour:$fridayAfternoonStartMinute';
      } else if (_weekday == DateTime.sunday) {
        breakTime = '$sundayAfternoonStartHour:$sundayAfternoonStartMinute';
      } else {
        // Default Break Time Sama kek di timeProvider
        final serverBreakTime =
            _dataProvider.attendanceInfoData?.breakTime ?? '12:00';
        breakTime = serverBreakTime.isEmpty ? '12:00' : serverBreakTime;
      }

      print('Waktu break siang: $breakTime');

      List<String> breakTimeParts = breakTime.split(':');
      int breakHour = int.parse(breakTimeParts[0]);
      int breakMinute = int.parse(breakTimeParts[1]);

      _timeProvider.updateBreakTime(breakHour, breakMinute);
      _timeProvider.setHolidayStatus(isHoliday);
      setState(() => _isLoadingGetBreakTime = false);
      ToastUtil.showToast(
          'Berhasil $action waktu break siang', ToastStatus.success);
    } else {
      print('Gagal $action waktu break siang');
      ToastUtil.showToast('Gagal $action waktu break siang', ToastStatus.error);
    }
  }

  void _updateAttendanceStatus() {
    final historyData = _dataProvider.selectedDateHistory!;
    if (historyData.tLPagi!.isNotEmpty) {
      bool onTime = historyData.tLPagi! == 'T';
      print('Status Absen Pagi: $onTime');
      _timeProvider.updateAttendanceCheck(true, isOnTime: onTime);
    }
    if (historyData.tLSiang!.isNotEmpty) {
      bool onTime = historyData.tLSiang! == 'T';
      print('Status Absen Siang: $onTime');
      _timeProvider.updateAttendanceCheck(false, isOnTime: onTime);
    }
  }

  Future<void> _getAttendanceHistory({bool isRefresh = false}) async {
    if (_dataProvider.isSelectedDateHistoryAvailable && !isRefresh) {
      _updateAttendanceStatus();
      print('Data absensi sudah ada');
      ToastUtil.showToast('Data absensi sudah ada', ToastStatus.success);
      return;
    }

    String action = isRefresh ? 'Memperbarui' : 'Mendapatkan';
    print('$action data absensi');

    final result = await _dataProvider.getThisDayHistory(
        _employeeName, _currentTime.postTime(),
        isRefresh: isRefresh);
    if (result.status == 'success') {
      _updateAttendanceStatus();
      ToastUtil.showToast('Berhasil $action data absensi', ToastStatus.success);
    } else {
      print('Gagal $action data absensi');
      ToastUtil.showToast(
          'Gagal $action data absensi' ?? '', ToastStatus.error);
    }
  }

  Future<void> _initData() async {
    _employeeName = widget.employeeName;
    _dataProvider = Provider.of<DataProvider>(context, listen: false);
    _timeProvider = Provider.of<TimeProvider>(context, listen: false);
    _currentTime = _timeProvider.currentTime;
    _weekday = _currentTime.getWeekday();

    final initHistoryData = HistoryData(
      tanggalCreate: _currentTime.postTime(),
      hari: _currentTime.getDayName(),
      deviceInfo: widget.deviceName,
    );

    await _dataProvider.initializeHistory(_employeeName, initHistoryData);
    await _getAttendanceHistory();
  }

  @override
  void initState() {
    super.initState();
    _loadLocationState();

    _initData();
    _updateBreakTime();

    _initFabAnimation();
  }

  @override
  void dispose() {
    _opacityController.dispose();
    _rotationController.dispose();
    _stopListeningLocationUpdates();
    _coordinateCheckTimer?.cancel();
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
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(seconds: 1));
                  await _getAttendanceHistory(isRefresh: true);
                  // await _updateBreakTime(isRefresh: true);
                },
                child: SizedBox(
                  height: screenHeight(context) - statusBarHeight(context) - 13,
                  width: MediaQuery.of(context).size.width,
                  child: Scaffold(
                    appBar: AppBar(
                      title: const Text('Absensi Online'),
                    ),
                    body: ConnectionChecker(
                      connectedWidget: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
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
                                              historyData,
                                              infoAttendance.nationalHoliday ??
                                                  '');
                                      final afternoonAttendanceState =
                                          timeProvider
                                              .isSiangButtonActive(historyData);
                                      final isBreakTime =
                                          isCurrentTimeWithinRange(
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
                                                _buildCountdownText(
                                                  timeProvider,
                                                ),
                                                AttendanceCard(
                                                  title: 'Absen Pagi',
                                                  buttonText: 'Absen Pagi',
                                                  buttonActive: true,
                                                  // buttonActive:
                                                  // morningAttendanceState &&
                                                  //     _attendancePermission,
                                                  onButtonPressed: () {
                                                    _onAttendanceButtonPressed(
                                                      isPagi: true,
                                                      attendanceStatus: timeProvider
                                                          .morningAttendanceStatus,
                                                      attendancePoint:
                                                          timeProvider
                                                              .attendancePoint,
                                                      dateTime: dateTime,
                                                      employeeName:
                                                          _employeeName,
                                                    );
                                                  },
                                                  attendanceStatus:
                                                      attendanceStatus(
                                                    dataProvider,
                                                    attendance: 'pagi',
                                                  ),
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
                                                      isPagi: false,
                                                      attendanceStatus: timeProvider
                                                          .afternoonAttendanceStatus,
                                                      attendancePoint:
                                                          timeProvider
                                                              .attendancePoint,
                                                      dateTime: dateTime,
                                                      employeeName:
                                                          _employeeName,
                                                      breakTime: infoAttendance
                                                          .breakTime,
                                                    );
                                                  },
                                                  attendanceStatus:
                                                      attendanceStatus(
                                                          dataProvider,
                                                          attendance: 'siang'),
                                                  message: timeProvider
                                                      .afternoonAttendanceMessage,
                                                ),
                                                const SizedBox(height: 10),
                                                if (isBreakTime)
                                                  Text(
                                                    breakTimeStart,
                                                    style: const TextStyle(
                                                      fontFamily: 'Mulish',
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                const SizedBox(height: 10),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    print(
                                                        'Pagi: $morningAttendanceState');
                                                    print(
                                                        'Siang: $afternoonAttendanceState');
                                                    print(
                                                        'Permission: $_attendancePermission');
                                                    print(
                                                        'Status point: ${timeProvider.attendancePoint}');
                                                  },
                                                  child: const Text(
                                                      'Check Attendance State'),
                                                ),
                                                const SizedBox(height: 10),
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
                                title:
                                    'Aktifkan atau Nonaktifkan Lokasi Real-time',
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
                                  icon: _isLoadingGetBreakTime
                                      ? const CircularProgressIndicator()
                                      : const Icon(Icons.dining_outlined),
                                  iconSize: 40,
                                  onPressed: () async {
                                    setState(
                                        () => _isLoadingGetBreakTime = true);
                                    await _updateBreakTime(isRefresh: true);
                                  },
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
                    floatingActionButton: FadeTransition(
                      opacity: _opacityController,
                      child: FloatingActionButton(
                        onPressed: !_showFab
                            ? null
                            : () async {
                                bool isConnected =
                                    await NetworkHelper.hasInternetConnection();
                                if (!isConnected) {
                                  // Tampilkan pesan jika tidak ada koneksi internet
                                  ToastUtil.showToast(
                                      'Koneksi internet bermasalah',
                                      ToastStatus.error);
                                  return;
                                }
                                _fabUpdateLocation();
                              },
                        child: AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationController.value * 2.0 * math.pi,
                              child: const Icon(Icons.refresh),
                            );
                          },
                        ),
                      ),
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

  Future<void> _attendanceProcess(
      String waktuAbsensi, Attendance attendance) async {
    LoadingDialog.show(context);
    try {
      final message =
      await _dataProvider.updateAttendance(waktuAbsensi, attendance);
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

  Future<void> _updateDataHistory(String employeeName, String date, HistoryData pushDataHistory, bool isPagi) async {
    final result = await _dataProvider.updateThisDayHistory(
      employeeName,
      date,
      pushDataHistory,
    );

    if (result.status == 'success') {
      print('Berhasil update history');
      ToastUtil.showToast(result.message!, ToastStatus.success);
      _timeProvider.updateAttendanceCheck(isPagi);
      safeContext((context) => LoadingDialog.hide(context));
    } else {
      print('Gagal update history');
      ToastUtil.showToast(result.message!, ToastStatus.error);
      safeContext((context) => LoadingDialog.hide(context));
    }
  }

  Future<void> _onAttendanceButtonPressed({
    required bool isPagi,
    required String attendanceStatus, // Status T/L
    required String attendancePoint, // Point
    required CustomTime dateTime, // Waktu saat ini
    required String employeeName,
    String? breakTime,
  }) async {
    final attendanceData = Data(
      tLPagi: isPagi ? attendanceStatus : null,
      hadirPagi: isPagi ? dateTime.postTime() : null,
      pointPagi: isPagi ? attendancePoint : null,
      tLSiang: !isPagi ? attendanceStatus : null,
      pulangSiang: !isPagi ? breakTime ?? '' : null,
      hadirSiang: !isPagi ? dateTime.postTime() : null,
      pointSiang: !isPagi ? attendancePoint : null,
    );

    final pushAttendance = Attendance(
      action: 'update',
      tahunBulan: dateTime.getYearMonth(),
      tanggal: dateTime.getIdnDate(),
      namaKaryawan: employeeName.toUpperCase(),
      data: attendanceData,
    );

    final pushDataHistory = HistoryData(
      tanggalUpdate: dateTime.postTime(),
      lat: _userPositionLatitude,
      long: _userPositionLongitude,
      tLPagi: isPagi ? attendanceStatus : null,
      hadirPagi: isPagi ? dateTime.getIdnTime() : null,
      pointPagi: isPagi ? attendancePoint : null,
      tLSiang: !isPagi ? attendanceStatus : null,
      pulangSiang: !isPagi ? breakTime : null,
      hadirSiang: !isPagi ? dateTime.getIdnTime() : null,
      pointSiang: !isPagi ? attendancePoint : null,
      keterangan: '', // Belum ada keterangannya
    );

    print(attendanceData);
    print(pushAttendance);
    print(pushDataHistory);

    LoadingDialog.show(context);
    try {
      DialogUtils.showConfirmationDialog(
        context: context,
        title: 'Absen ${isPagi ? 'Pagi' : 'Siang'}',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Lakukan Absen Sekarang?'),
            const SizedBox(height: 10),
            Text('Anda akan melakukan mengisi presensi waktu ${isPagi ? 'Pagi' : 'Siang'} di jam :\n${dateTime.getIdnAllTime()}'),
          ],
        ),
        onConfirm: () async {
          // _attendanceProcess(attendanceType, attendance); // Ini update sheets
          await _updateDataHistory(employeeName, dateTime.postTime(), pushDataHistory, isPagi);
        },
        onCancel: () {
          safeContext((context) => LoadingDialog.hide(context));
        },
      );
    } catch (e) {
      print(e);
      safeContext((context) => LoadingDialog.hide(context));
      ToastUtil.showToast('Gagal memproses kehadiran', ToastStatus.error);
    }
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

  void _initFabAnimation() {
    _scrollController = ScrollController();

    // Kontrol animasi opacity FAB
    _opacityController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    // Listener yang mendeteksi scroll up dan down untuk menampilkan dan menyembunyikan FAB
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        // Jika scroll ke atas, sembunyikan FAB
        if (!_showFab) {
          setState(() {
            _showFab = true;
          });
          _opacityController
              .forward(); // Memulai animasi opacity untuk menyembunyikan
        }
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        // Jika scroll ke bawah, tampilkan FAB
        if (_showFab) {
          setState(() {
            _showFab = false;
          });
          _opacityController
              .reverse(); // Memulai animasi opacity untuk menampilkan
        }
      }
    });

    // Kontrol animasi rotasi FAB
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
    super.key,
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
