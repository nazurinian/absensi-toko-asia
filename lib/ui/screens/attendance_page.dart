import 'dart:async';
import 'dart:math' as math;

import 'package:absensitoko/core/constants/constants.dart';
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
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // bool _fabLoading = false;
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
      },
    );
  }

  void _fabUpdateLocation() async {
    // setState(() => _fabLoading = true);
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
    // setState(() => _fabLoading = false);
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
      ToastUtil.showToast('Informasi Absen sudah ada', ToastStatus.success);
      return;
    }

    String action = isRefresh ? 'Memperbarui' : 'Mendapatkan';

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


      List<String> breakTimeParts = breakTime.split(':');
      int breakHour = int.parse(breakTimeParts[0]);
      int breakMinute = int.parse(breakTimeParts[1]);

      _timeProvider.updateBreakTime(breakHour, breakMinute);
      _timeProvider.setHolidayStatus(isHoliday);
      setState(() => _isLoadingGetBreakTime = false);
      ToastUtil.showToast(
          'Berhasil $action waktu break siang', ToastStatus.success);
    } else {
      ToastUtil.showToast('Gagal $action waktu break siang', ToastStatus.error);
    }
  }

  void _updateAttendanceStatus() {
    final historyData = _dataProvider.selectedDateHistory!;
    if (historyData.tLPagi!.isNotEmpty) {
      bool onTime = historyData.tLPagi! == 'T';
      _timeProvider.updateAttendanceCheck(true, isOnTime: onTime);
    }
    if (historyData.tLSiang!.isNotEmpty) {
      bool onTime = historyData.tLSiang! == 'T';
      _timeProvider.updateAttendanceCheck(false, isOnTime: onTime);
    }
  }

  Future<void> _getAttendanceHistory({bool isRefresh = false}) async {
    if (_dataProvider.isSelectedDateHistoryAvailable && !isRefresh) {
      _updateAttendanceStatus();
      ToastUtil.showToast('Data absensi sudah ada', ToastStatus.success);
      return;
    }

    String action = isRefresh ? 'Memperbarui' : 'Mendapatkan';

    final result = await _dataProvider.getThisDayHistory(
        _employeeName, _currentTime.postTime(),
        isRefresh: isRefresh);
    if (result.status == 'success') {
      _updateAttendanceStatus();
      ToastUtil.showToast('Berhasil $action data absensi', ToastStatus.success);
    } else {
      ToastUtil.showToast(
          'Gagal $action data absensi', ToastStatus.error);
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
                                      timeProvider.isPagiButtonActive(
                                              historyData,
                                              infoAttendance.nationalHoliday ??
                                                  '');
                                      final morningAttendanceState = timeProvider
                                          .isPagiButtonActive(historyData,
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
                                                  // buttonActive: true,
                                                  buttonActive:
                                                  morningAttendanceState &&
                                                      _attendancePermission,
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
      ToastUtil.showToast(result.message!, ToastStatus.success);
      _timeProvider.updateAttendanceCheck(isPagi);
      safeContext((context) => LoadingDialog.hide(context));
    } else {
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
