import 'package:absensitoko/core/constants/constants.dart';
import 'package:absensitoko/core/constants/items_list.dart';
import 'package:absensitoko/data/models/attendance_model.dart';
import 'package:absensitoko/data/models/history_model.dart';
import 'package:absensitoko/data/models/attendance_info_model.dart';
import 'package:absensitoko/data/models/keterangan_model.dart';
import 'package:absensitoko/data/models/time_model.dart';
import 'package:absensitoko/data/models/user_model.dart';
import 'package:absensitoko/data/providers/data_provider.dart';
import 'package:absensitoko/data/providers/time_provider.dart';
import 'package:absensitoko/data/providers/user_provider.dart';
import 'package:absensitoko/core/themes/fonts/fonts.dart';
import 'package:absensitoko/locator.dart';
import 'package:absensitoko/routes.dart';
import 'package:absensitoko/ui/widgets/breaktime_field.dart';
import 'package:absensitoko/ui/widgets/custom_list_tile.dart';
import 'package:absensitoko/ui/widgets/short_attendance_info.dart';
import 'package:absensitoko/utils/base/base_state.dart';
import 'package:absensitoko/utils/base/location_service.dart';
import 'package:absensitoko/utils/base/version_checker.dart';
import 'package:absensitoko/utils/dialogs/dialog_utils.dart';
import 'package:absensitoko/utils/display_size_util.dart';
import 'package:absensitoko/utils/helpers/general_helper.dart';
import 'package:absensitoko/utils/popup_util.dart';
import 'package:absensitoko/core/constants/options_menu.dart';
import 'package:absensitoko/utils/dialogs/loading_dialog_util.dart';
import 'package:absensitoko/utils/helpers/network_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/helpers/general_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends BaseState<HomePage> with WidgetsBindingObserver {
  late TimeProvider _timeProvider;
  late DataProvider _dataProvider;
  late UserProvider _userProvider;

  final TextEditingController _breaktimeController = TextEditingController();
  final TextEditingController _nationalHolidayController =
      TextEditingController();
  final FocusNode _breaktimeFocus = FocusNode();
  final FocusNode _nationalHolidayFocus = FocusNode();
  final GlobalKey<FormState> _breaktimeFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _nationalHolidayFormKey = GlobalKey<FormState>();

  UserModel? _user;
  String _userName = "";
  final String _holiday = 'Libur ';
  String _displayMessage = 'Data belum diperoleh';
  bool _isLoadingGetInfo = false;
  bool _isLogout = false;
  String? _deviceName;

  AttendanceInfoModel? _attendanceInfo;
  bool _enableUpdateHoliday = true;
  bool _enableUpdateBreakTime = true;

  Map<String, bool> _temporaryAdmin = {};
  List<String> _sheetNames = [];
  bool _sheetButtonActive = false;
  String? _infoRole = '';

  // bool _lockAccess = false;

  Future<void> _fetchUserData({bool isRefresh = false}) async {
    if (_userProvider.userDataIsLoaded && !isRefresh) {
      _updateUser(_userProvider.currentUser);
      return;
    }

    await _loadAndVerifyUserSession(_userProvider, isRefresh);
  }

  Future<void> _loadAndVerifyUserSession(
      UserProvider userProvider, bool isRefresh) async {
    await userProvider.loadUserSession();
    final userDataSession = userProvider.currentUserSession;
    setState(() => _deviceName = userProvider.deviceID!);

    safeContext((context) => LoadingDialog.show(context));
    try {
      final result = await userProvider.getUser(userDataSession!.uid,
          isRefresh: isRefresh);
      await _handleFetchResult(result, userProvider, _deviceName!);
    } catch (e) {
      _showErrorSnackbar(e.toString());
    }
  }

  Future<void> _handleFetchResult(
      result, UserProvider userProvider, String deviceName) async {
    if (result.status != 'success') {
      ToastUtil.showToast(result.message ?? '', ToastStatus.error);
      LoadingDialog.hide(context);
      return;
    }

    final userData = userProvider.currentUser;
    if (userData!.loginDevice != deviceName) {
      await _showSessionExpiredDialog();
      setState(() => _isLogout = true);
    } else {
      _updateUser(userData);
      ToastUtil.showToast(
          'Berhasil memperoleh data profil', ToastStatus.success);
    }

    if (mounted) LoadingDialog.hide(context);
  }

  Future<void> _updateUser(UserModel? userData) async {
    setState(() {
      _user = userData;
      _userName = _user?.displayName?.toUpperCase() ?? '';
      _infoRole = _user?.role;
    });
  }

  Future<void> _showSessionExpiredDialog() async {
    final shouldLogout = await DialogUtils.showExpiredDialog(context,
        title: 'Sesi Berakhir',
        content: 'Sesi login telah berakhir. Silakan login kembali.');
    if (shouldLogout ?? false) {
      _handleLogout(sessionExpired: true);
    }
  }

  void _showErrorSnackbar(String message) {
    SnackbarUtil.showSnackbar(context: context, message: message);
    LoadingDialog.hide(context);
  }

  void _handleLogout({bool sessionExpired = false}) async {
    final userDataSession = _userProvider.currentUserSession!.uid;
    final currentTime = _timeProvider.currentTime.postTime();

    UserModel user = UserModel(
      uid: userDataSession,
      logoutTimestamp: currentTime,
      loginTimestamp: '',
      loginLat: '',
      loginLong: '',
      loginDevice: '',
    );

    LoadingDialog.show(context);
    try {
      final message = await _userProvider.signOut(user, sessionExpired);
      await _handleLogoutResult(message);
    } catch (e) {
      _showErrorSnackbar(e.toString());
      safeContext((context) => LoadingDialog.hide(context));
    }
  }

  Future<void> _handleLogoutResult(result) async {
    if (result.status == 'success') {
      await Future.delayed(const Duration(seconds: 1));
      safeContext((context) => SnackbarUtil.showSnackbar(
          context: context, message: 'Anda telah logout'));
      _clearDataAndNavigate();
    } else {
      SnackbarUtil.showSnackbar(
          context: context, message: result.message ?? 'Error');
    }
  }

  void _clearDataAndNavigate() {
    _userProvider.clearAccountData();
    _dataProvider.clearData();
    LoadingDialog.hide(context);
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _getInfo({bool isRefresh = false}) async {
    final weekday = _timeProvider.currentTime.getWeekday();
    final response =
        await _dataProvider.getAttendanceInfo(isRefresh: isRefresh);

    if (response.status == 'success') {
      final data = _dataProvider.attendanceInfoData!;

/*
      String breakTime = data.breakTime!;
      String nationalHoliday = data.nationalHoliday!;

      bool isNormalDays = data.breakTime!.isNotEmpty && data.breakTime != null;
      bool isHoliday =
          data.nationalHoliday!.isNotEmpty && data.nationalHoliday != null;

      print('normalDays: $isNormalDays');
      print('isHoliday: $isHoliday');

      if (isNormalDays) {
        String breakEndTime = formatStringToDateTime(
            _timeProvider.currentTime, breakTime,
            addTime: afternoonPreparationMinutes);

        breakTime = '$breakTime - $breakEndTime';
      }

      breakTime = isNormalDays
          ? breakTime
          : weekday == DateTime.sunday
              ? '13:00 - 16.00'
              : weekday == DateTime.friday
                  ? '11.15 - 14:00'
                  : 'Belum diatur';
      nationalHoliday = isHoliday
          ? nationalHoliday
          : weekday == DateTime.sunday
              ? '(Hari Ahad)'
              : '(Hari Normal)';
*/

      final String breakTime = calculateBreakTime(
          _timeProvider.currentTime, data.breakTime, weekday);
      final String nationalHoliday =
          setHolidayStatus(data.nationalHoliday, weekday);
      bool isHoliday =
          data.nationalHoliday!.isNotEmpty || weekday == DateTime.sunday;
      bool specificBreakTime = data.breakTime!.isNotEmpty ||
          weekday == DateTime.friday ||
          weekday == DateTime.sunday;

      if (isHoliday) {
        setState(() => _enableUpdateHoliday = false);
      }
      if (specificBreakTime) {
        setState(() => _enableUpdateBreakTime = false);
      }

      setState(() {
        _displayMessage =
            'Data berhasil diperoleh:\nWaktu ISHOMA > $breakTime\nLibur Nasional > $nationalHoliday';
        _attendanceInfo = data;
        _breaktimeController.text = data.breakTime ?? '';
        _nationalHolidayController.text = data.nationalHoliday ?? '';
        _isLoadingGetInfo = false;
      });
    } else {
      setState(() {
        _displayMessage = response.message!;
      });
    }
  }

  Future<void> updateInfo(
      {String fieldUpdate = '',
      bool isResetBreakTime = false,
      bool isResetHoliday = false}) async {
    AttendanceInfoModel updatedData;

    if (isResetBreakTime || isResetHoliday) {
      updatedData = AttendanceInfoModel(
        breakTime: isResetBreakTime ? '' : null,
        nationalHoliday: isResetHoliday ? '' : null,
      );
    } else {
      updatedData = AttendanceInfoModel(
        breakTime: fieldUpdate == 'break' ? _breaktimeController.text : null,
        nationalHoliday:
            fieldUpdate == 'holiday' ? _nationalHolidayController.text : null,
      );
    }

    final response = await _dataProvider.updateAttendanceInfo(updatedData);

    if (response.status == 'success') {
      await _getInfo(isRefresh: true);
    }

    if (isResetBreakTime || isResetHoliday) return;

    setState(() {
      _displayMessage = response.message!;
    });
  }

  void _initData() {
    _timeProvider = Provider.of<TimeProvider>(context, listen: false);
    _dataProvider = Provider.of<DataProvider>(context, listen: false);
    _userProvider = Provider.of<UserProvider>(context, listen: false);
  }

  Future<void> _getTemporaryAdmin() async {
    final result = await _dataProvider.getTemporaryAdmins();
    if (result.status == 'success') {
      final temporaryAdmin = _dataProvider.temporaryAdmins;
      _temporaryAdmin = temporaryAdmin;
    }
  }

  Future<void> _getAppVersion() async {
    await VersionChecker.checkForUpdates();
  }

  Future<void> _getSheetNames({bool isRefresh = false}) async {
    final today = _timeProvider.currentTime.getDefaultDateTime();
/*
    final today = DateTime(
      _timeProvider.currentTime.getYear(),
      _timeProvider.currentTime.getMonth(),
      _timeProvider.currentTime.getDay() + 18,
      _timeProvider.currentTime.getHour(),
      _timeProvider.currentTime.getMinute(),
      _timeProvider.currentTime.getSecond(),
    );
*/

    String targetMonth = getTargetMonth(today);
    bool isButtonActive = false;

    bool checkTimeToCreateSheet = isStartAndLastMonthWithinRange(today);

    if (!checkTimeToCreateSheet) {
      print('Bukan waktunya untuk membuat sheet baru');
      return;
    }

    if (_dataProvider.isSheetNamesAvailable && !isRefresh) {
      final sheetNames = _dataProvider.sheetNames;
      isButtonActive = isStartAndLastMonthWithinRange(today) && isSheetNotExist(targetMonth, sheetNames);
      setState(() {
        _sheetNames = sheetNames;
        _sheetButtonActive = isButtonActive;
      });
      return;
    }

    try {
      final result = await _dataProvider.getSheetNames();
      if (result.status == 'success') {
        final sheetNames = _dataProvider.sheetNames;
        isButtonActive = isStartAndLastMonthWithinRange(today) && isSheetNotExist(targetMonth, sheetNames);
        setState(() {
          _sheetNames = sheetNames;
          _sheetButtonActive = isButtonActive;
        });
      }
    } catch (e) {
      return;
    }
  }

  Future<void> _createAttendanceSheet({required CustomTime dateTime}) async {
    // // Cek jika hari ini adalah akhir bulan atau tanggal 1
    // final today = dateTime.getDefaultDateTime();
    // final tomorrow = today.add(const Duration(days: 1));
    // bool isEndOfMonth = tomorrow.month != today.month;
    // bool isNewMonth = today.day == 1;

    // final today = DateTime(
    //   dateTime.getYear(),
    //   dateTime.getMonth(),
    //   dateTime.getDay(),
    //   dateTime.getHour(),
    //   dateTime.getMinute(),
    //   dateTime.getSecond(),
    // );
    // final today = dateTime.getDefaultDateTime();
    // final lastDayOfMonth = DateTime(today.year, today.month + 1, 0)
    //     .day; // Mendapatkan hari terakhir bulan ini
    // // bool isInTargetRange = (today.day >= lastDayOfMonth - 2) || (today.day <= 3);
    // bool isInLast3Days = today.day >= lastDayOfMonth - 2;
    // bool isInFirst3Days = today.day <= 3;
    //
    // // Tentukan tahunBulan berdasarkan kondisi H-3 atau H+3
    // final nextMonth = today.month == 12 ? 1 : today.month + 1;
    // final nextYear = today.month == 12 ? today.year + 1 : today.year;
    // String tahunBulan;
    //
    // if (isInLast3Days) {
    //   // Jika dalam 3 hari terakhir bulan ini, gunakan bulan depan
    //   tahunBulan = '${nextYear}${nextMonth.toString().padLeft(2, '0')}';
    // } else if (isInFirst3Days) {
    //   // Jika dalam 3 hari pertama bulan ini, gunakan bulan ini
    //   tahunBulan = '${today.year}${today.month.toString().padLeft(2, '0')}';
    // } else {
    //   return; // Jika tidak memenuhi H-3 atau H+3, tidak lanjutkan fungsi
    // }

    // print('tahunBulan: $tahunBulan');

    final today = dateTime.getDefaultDateTime();
/*
    final today = DateTime(
      dateTime.getYear(),
      dateTime.getMonth(),
      dateTime.getDay()+ 18,
      dateTime.getHour(),
      dateTime.getMinute(),
      dateTime.getSecond(),
    );
*/

    // Tentukan target bulan berdasarkan tanggal saat ini (gunakan helper function)
    String targetMonth = getTargetMonth(today);

    if (!isStartAndLastMonthWithinRange(today) && !isSheetNotExist(targetMonth, _sheetNames)) {
      return;
    }

    Attendance attendance =
        Attendance(action: 'create_attendance', tahunBulan: targetMonth);

    LoadingDialog.show(context, canPop: true);
    try {
      final result = await _dataProvider.createAttendanceSheet(attendance);
      if (result.status == 'success') {
        await _getSheetNames(isRefresh: true);
        ToastUtil.showToast(result.message!, ToastStatus.success);
      } else {
        ToastUtil.showToast(result.message!, ToastStatus.error);
      }
      if (mounted) LoadingDialog.hide(context);
    } catch (e) {
      if (mounted) LoadingDialog.hide(context);
      ToastUtil.showToast(e.toString(), ToastStatus.error);
    }
  }

/*  Future<void> _updateAppVersion() async {
    AppVersionModel appVersion = AppVersionModel(version: '3.0.0', buildNumber: 1, mandatory: false, link: 'https://play.google.com/store/apps/details?id=com.absensitoko.absensitoko');
    VersionChecker.setAppVersion(appVersion);
  }*/

  Future<void> _permissionCheck() async {
    final locationService = locator<LocationService>();

    final permission = await locationService.cekIzinLokasi();
    if (!permission.isGranted) {
      ToastUtil.showToast(permission.statusMessage, ToastStatus.error);
    }
  }

  Future<void> _initAndGetAttendanceHistory({bool isRefresh = false}) async {
    final currentTime = _timeProvider.currentTime;

    String keterangan = _attendanceInfo?.nationalHoliday ?? '';

    final initHistoryData = HistoryData(
      tanggalCreate: currentTime.postTime(),
      hari: currentTime.getDayName(),
      deviceInfo: _deviceName ?? '',
      keterangan: keterangan.isNotEmpty ? '(Libur) $keterangan' : '',
    );

    if (!isRefresh) {
      await _dataProvider.initializeHistory(_userName, initHistoryData);
    }

    if (_dataProvider.isSelectedDateHistoryAvailable && !isRefresh) {
      ToastUtil.showToast('Data absensi sudah ada', ToastStatus.success);
      return;
    }

    String action = isRefresh ? 'Memperbarui' : 'Mendapatkan';

    final result = await _dataProvider.getThisDayHistory(
        _userName, currentTime.postTime(),
        isRefresh: isRefresh);
    if (result.status == 'success') {
      ToastUtil.showToast('Berhasil $action data absensi', ToastStatus.success);
    } else {
      ToastUtil.showToast('Gagal $action data absensi', ToastStatus.error);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initData();
    _getAppVersion();
    _permissionCheck();
    _getInfo();
    _getSheetNames();
    _fetchUserData().then((_) async {
      if (!_isLogout) {
        await _initAndGetAttendanceHistory();
        await _getTemporaryAdmin();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _breaktimeController.dispose();
    _nationalHolidayController.dispose();
    _breaktimeFocus.dispose();
    _nationalHolidayFocus.dispose();
    unFocusAllField();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _getAppVersion();
      _fetchUserData(isRefresh: true);

      //   _timeProvider.refreshNtpTime();
      // } else if (state == AppLifecycleState.paused) {
      //   _timeProvider.stopUpdatingTime();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    // final textTheme = Theme.of(context).textTheme;
    final dateTime = Provider.of<TimeProvider>(context).currentTime;

    return Stack(
      children: [
        Container(
          height: double.infinity,
          width: double.infinity,
          color: Colors.brown,
        ),
        GestureDetector(
          onTap: () => unFocusAllField(),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Scaffold(
                  body: RefreshIndicator(
                    onRefresh: () async {
                      await Future.delayed(const Duration(seconds: 3));
                      await _fetchUserData(isRefresh: true);
                      await _initAndGetAttendanceHistory(isRefresh: true);
                      await _getTemporaryAdmin();
                      if (context.mounted) {
                        await Provider.of<TimeProvider>(context, listen: false)
                            .refreshNtpTime();
                      }
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: _infoRole == 'other'
                          ? _buildOtherRolePage()
                          : Stack(
                              children: [
                                Positioned(
                                  bottom: 0,
                                  child: Image.asset(
                                    AppImage.atk.path,
                                    width: screenWidth(context),
                                    fit: BoxFit.cover,
                                    alignment: Alignment.bottomCenter,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 16.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${dateTime.getIdnDayName()}, ',
                                              style: FontTheme.titleMedium(
                                                context,
                                                fontSize: 36,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                            SizedBox(
                                              child: PopupMenuButton(
                                                offset: const Offset(0, 50),
                                                onSelected: (value) async {
                                                  return _popupMenuAction(
                                                      context, value);
                                                },
                                                itemBuilder: _popupMenuItem,
                                                iconSize: 28,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 4.0),
                                        child: Text(
                                          dateTime.getIdnDate(),
                                          style: FontTheme.titleMedium(
                                            context,
                                            fontSize: 19,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // _shortAttendanceInfo(dateTime),
                                          ShortAttendanceInfo(
                                            currentTime: dateTime,
                                            userName: _userName,
                                            deviceName: _deviceName ?? '',
                                          ),
                                          const SizedBox(
                                            height: 20,
                                          ),
                                          Container(
                                            alignment: Alignment.center,
                                            child: Text(
                                              dateTime.getIdnTime(),
                                              style: FontTheme.titleMedium(
                                                context,
                                                fontSize: 36,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 20,
                                          ),
                                          Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondaryContainer,
                                            ),
                                            child: Stack(
                                              children: [
                                                Positioned(
                                                  left: 0,
                                                  bottom: 0,
                                                  child: Image.asset(
                                                    AppImage.watch.path,
                                                    width: 175,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Selamat Datang 👋',
                                                        style: FontTheme
                                                            .bodyMedium(
                                                          context,
                                                          fontSize: 28,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                left: 8.0),
                                                        child: Text(
                                                          _userName,
                                                          style: FontTheme
                                                              .bodyMedium(
                                                            context,
                                                            fontSize: 36,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Container(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    8.0),
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.pushNamed(
                                                                context,
                                                                '/attendance_history',
                                                                arguments:
                                                                    _userName);
                                                          },
                                                          child: const Text(
                                                            'Cek Absensi',
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Container(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    8.0),
                                                        child: FilledButton(
                                                          onPressed: () async {
                                                            bool isConnected =
                                                                await NetworkHelper
                                                                    .hasInternetConnection();
                                                            if (isConnected &&
                                                                context
                                                                    .mounted) {
                                                              Navigator.pushNamed(
                                                                  context,
                                                                  '/attendance',
                                                                  arguments: AttendancePageArguments(
                                                                      employeeName:
                                                                          _userName,
                                                                      deviceName:
                                                                          _deviceName ??
                                                                              ''));
                                                            } else {
                                                              ToastUtil.showToast(
                                                                  'Tidak ada koneksi internet',
                                                                  ToastStatus
                                                                      .error);
                                                            }
                                                          },
                                                          child: const Text(
                                                              'Pergi Absen'),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 20,
                                          ),

                                          /// Dashboard Next Update
                                          /*Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer,
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Image.asset(,
                                              width: 175,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'DashBoard 📊',
                                                  style: FontTheme.bodyMedium(
                                                    context,
                                                    fontSize: 28,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(
                                                      left: 8.0),
                                                  child: Text(
                                                    'Chart',
                                                    style: FontTheme.bodyMedium(
                                                      context,
                                                      fontSize: 36,
                                                      fontWeight: FontWeight.bold,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    ToastUtil.showToast(
                                                        'Fitur belum tersedia',
                                                        ToastStatus.warning);
                                                  },
                                                  child: const Text('null'),
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                FilledButton(
                                                  onPressed: () {
                                                    ToastUtil.showToast(
                                                        'Fitur belum tersedia',
                                                        ToastStatus.warning);
                                                  },
                                                  child: const Text('null'),
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),*/
                                          if (_temporaryAdmin[_userName
                                                      .toLowerCase()] ==
                                                  true ||
                                              _infoRole == 'admin' ||
                                              _infoRole == 'superadmin') ...[
                                            Stack(
                                              children: [
                                                Container(
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .secondaryContainer,
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Informasi Absen 🕜️',
                                                          style: FontTheme
                                                              .bodyMedium(
                                                            context,
                                                            fontSize: 28,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 10),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                            left: 8.0,
                                                          ),
                                                          child: Text(
                                                            'Atur waktu mulai istirahat:',
                                                            style: FontTheme
                                                                .bodyMedium(
                                                              context,
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary,
                                                            ),
                                                          ),
                                                        ),
                                                        BreaktimeField(
                                                          focusNode:
                                                              _breaktimeFocus,
                                                          controller:
                                                              _breaktimeController,
                                                          formKey:
                                                              _breaktimeFormKey,
                                                          labelText:
                                                              'breaktime',
                                                          hintText: !_breaktimeFocus
                                                                  .hasFocus
                                                              ? 'Waktu Istirahat'
                                                              : null,
                                                          errorMessage:
                                                              'Waktu istirahat tidak boleh kosong',
                                                          readonly: true,
                                                          enabled:
                                                              _enableUpdateBreakTime,
                                                          onCancel:
                                                              unFocusAllField,
                                                          onConfirm: () =>
                                                              updateInfo(
                                                                  fieldUpdate:
                                                                      'break'),
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                            left: 8.0,
                                                          ),
                                                          child: Text(
                                                            'Atur Libur Nasional:',
                                                            style: FontTheme
                                                                .bodyMedium(
                                                              context,
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary,
                                                            ),
                                                          ),
                                                        ),
                                                        BreaktimeField(
                                                          focusNode:
                                                              _nationalHolidayFocus,
                                                          controller:
                                                              _nationalHolidayController,
                                                          formKey:
                                                              _nationalHolidayFormKey,
                                                          errorMessage:
                                                              'Hari libur tidak boleh kosong',
                                                          prefixText:
                                                              _nationalHolidayFocus
                                                                      .hasFocus
                                                                  ? _holiday
                                                                  : null,
                                                          hintText:
                                                              !_nationalHolidayFocus
                                                                      .hasFocus
                                                                  ? 'Hari Libur '
                                                                  : null,
                                                          enabled:
                                                              _enableUpdateHoliday,
                                                          onConfirm: () =>
                                                              updateInfo(
                                                                  fieldUpdate:
                                                                      'holiday'),
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        const Divider(
                                                          thickness: 5,
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        Column(
                                                          children: [
                                                            if (_displayMessage
                                                                .isNotEmpty)
                                                              ListTile(
                                                                title:
                                                                    _isLoadingGetInfo
                                                                        ? const Center(
                                                                            child:
                                                                                CircularProgressIndicator())
                                                                        : Text(
                                                                            _displayMessage,
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                          ),
                                                              ),
                                                            const SizedBox(
                                                              height: 10,
                                                            ),
                                                            Center(
                                                              child:
                                                                  ElevatedButton(
                                                                onPressed:
                                                                    () async {
                                                                  setState(() =>
                                                                      _isLoadingGetInfo =
                                                                          true);
                                                                  await _getInfo(
                                                                      isRefresh:
                                                                          true);
                                                                },
                                                                child:
                                                                    const Text(
                                                                  'Peroleh Data',
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                //Clear Button
                                                if (_breaktimeController
                                                        .text.isNotEmpty ||
                                                    _nationalHolidayController
                                                        .text.isNotEmpty)
                                                  Positioned(
                                                    right: 16,
                                                    top: 16,
                                                    child: IconButton(
                                                      onPressed: () async {
                                                        _breaktimeController
                                                            .clear();
                                                        _nationalHolidayController
                                                            .clear();
                                                        setState(() =>
                                                            _displayMessage =
                                                                '');
                                                        unFocusAllField();
                                                        if (_attendanceInfo!
                                                                .breakTime!
                                                                .isNotEmpty ||
                                                            _attendanceInfo!
                                                                .nationalHoliday!
                                                                .isNotEmpty) {
                                                          await updateInfo(
                                                              isResetBreakTime:
                                                                  _attendanceInfo!
                                                                      .breakTime!
                                                                      .isNotEmpty,
                                                              isResetHoliday:
                                                                  _attendanceInfo!
                                                                      .nationalHoliday!
                                                                      .isNotEmpty);
                                                        }
                                                      },
                                                      icon: const Icon(
                                                          Icons.clear),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            if (_infoRole == 'admin' ||
                                                _infoRole == 'superadmin')
                                              Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondaryContainer,
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Buat Sheet untuk Bulan Baru: 📚️',
                                                        style: FontTheme
                                                            .bodyMedium(
                                                          context,
                                                          fontSize: 28,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: ElevatedButton(
                                                          onPressed: _sheetButtonActive ? () =>
                                                              _createAttendanceSheet(
                                                                  dateTime:
                                                                      dateTime) : null,
                                                          // ToastUtil.showToast(
                                                          //     'Masih dalam pengembangan',
                                                          //     ToastStatus
                                                          //         .warning),
                                                          child: const Text(
                                                              'Buat Sheet Baru'),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(
                                              height: 20,
                                            ),
                                          ],
                                          Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondaryContainer,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Data Akun 🧾',
                                                    style: FontTheme.bodyMedium(
                                                      context,
                                                      fontSize: 28,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      left: 8.0,
                                                    ),
                                                    child: Text(
                                                      'Akun: ',
                                                      style:
                                                          FontTheme.bodyMedium(
                                                        context,
                                                        fontSize: 36,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  Column(
                                                    children: [
                                                      CustomListTile(
                                                        title: 'Nama',
                                                        trailing: Text(
                                                          _userName,
                                                          style: FontTheme
                                                              .bodyMedium(
                                                                  context,
                                                                  fontSize: 14),
                                                        ),
                                                      ),
                                                      CustomListTile(
                                                        title: 'Email',
                                                        trailing: Text(
                                                          _user != null
                                                              ? _user!.email!
                                                              : '',
                                                          style: FontTheme
                                                              .bodyMedium(
                                                                  context,
                                                                  fontSize: 14),
                                                        ),
                                                      ),
                                                      CustomListTile(
                                                        title: 'Bagian',
                                                        trailing: Text(
                                                          _user != null
                                                              ? _user!
                                                                  .department!
                                                                  .toUpperCase()
                                                              : '',
                                                          style: FontTheme
                                                              .bodyMedium(
                                                                  context,
                                                                  fontSize: 14),
                                                        ),
                                                      ),
                                                      CustomListTile(
                                                        title: 'Login Terakhir',
                                                        trailing: Text(
                                                          _user != null
                                                              ? _user!.loginTimestamp!
                                                                      .isNotEmpty
                                                                  ? _user!
                                                                      .loginTimestamp!
                                                                  : _user!
                                                                      .firstTimeLogin!
                                                              : '',
                                                          style: FontTheme
                                                              .bodyMedium(
                                                                  context,
                                                                  fontSize: 14),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 20,
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
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

  Future<void> _popupMenuAction(BuildContext context, String value) async {
    if (value == 'logout') {
      bool isConnected = await NetworkHelper.hasInternetConnection();
      if (isConnected && context.mounted) {
        DialogUtils.showConfirmationDialog(
          context: context,
          title: 'Logout',
          content: const Text('Keluar dari aplikasi?'),
          onConfirm: () {
            _handleLogout();
          },
        );
      } else {
        ToastUtil.showToast('Tidak ada koneksi internet', ToastStatus.error);
      }
    } else if (value == 'profile') {
      bool updateProfile = await Navigator.pushNamed(
        context,
        '/profile',
      ) as bool;
      if (updateProfile) {
        _fetchUserData();
      }
      // Memastikan data diperbarui setelah kembali dari halaman edit
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _userProvider.getUser(_user!.uid);
      });
    } else if (value == 'information') {
      Navigator.pushNamed(context, '/information');
    } else if (value == 'admin access') {
      Navigator.pushNamed(context, '/temporary_admin');
    }
  }

  List<PopupMenuItem> _popupMenuItem(BuildContext context) {
    final imageUrl = _user?.photoURL ?? '';
    return homeMenuItem.entries.where((item) {
      // Tampilkan hanya item yang sesuai dengan peran pengguna
      if (item.key == 'Admin Access' &&
          _infoRole != 'admin' &&
          _infoRole != 'superadmin') {
        return false; // Jangan tampilkan item 'Account' jika bukan admin
      }
      return true; // Tampilkan item lainnya
    }).map((item) {
      return PopupMenuItem<String>(
        value: item.key.toLowerCase(),
        child: Row(
          children: [
            if (item.key == 'Profile')
              CircleAvatar(
                radius: 12,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) => Icon(item.value),
                  errorWidget: (context, url, error) => Icon(item.value),
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              )
            else
              Icon(item.value),
            const SizedBox(width: 10),
            Text(item.key),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildOtherRolePage() {
    return Container(
      height: screenHeight(context) -
          appBarHeight(context) -
          statusBarHeight(context),
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, size: 100, color: Colors.red),
          SizedBox(height: 20),
          Text(
            'Akun anda belum bisa digunakan\nTunggu konfirmasi dalam 1x24 Jam',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Mulish',
              fontSize: 20,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 30),
          Text(
            'Sambil direfresh yaa...',
            style: TextStyle(
              fontFamily: 'Mulish',
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  void unFocusAllField() {
    _breaktimeFocus.unfocus();
    _nationalHolidayFocus.unfocus();
  }
}
