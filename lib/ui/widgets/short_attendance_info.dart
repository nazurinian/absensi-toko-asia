import 'package:absensitoko/core/constants/constants.dart';
import 'package:absensitoko/core/themes/fonts/fonts.dart';
import 'package:absensitoko/data/models/time_model.dart';
import 'package:absensitoko/data/providers/data_provider.dart';
import 'package:absensitoko/routes.dart';
import 'package:absensitoko/utils/helpers/general_helper.dart';
import 'package:absensitoko/utils/helpers/network_helper.dart';
import 'package:absensitoko/utils/popup_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShortAttendanceInfo extends StatefulWidget {
  final CustomTime currentTime;
  final String userName;
  final String deviceName;

  const ShortAttendanceInfo({
    super.key,
    required this.currentTime,
    required this.userName,
    required this.deviceName,
  });

  @override
  State<ShortAttendanceInfo> createState() => _ShortAttendanceInfoState();
}

class _ShortAttendanceInfoState extends State<ShortAttendanceInfo>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTime();
  }

  void _checkTime() {
    final bool isMorningTime = isCurrentTimeWithinRange(
      widget.currentTime.getDefaultDateTime(),
      '$morningStartHour:$morningStartMinute',
      '12:00',
    );
    final bool isAfternoonTime = isCurrentTimeWithinRange(
      widget.currentTime.getDefaultDateTime(),
      '12:00',
      '$storeClosedHour:$storeClosedMinute',
    );

    setState(() {
      _isVisible = isMorningTime || isAfternoonTime;
    });
  }

  void _simulateLoadingDelay() async {
    await Future.delayed(const Duration(seconds: 2)); // Menunda selama 2 detik
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final historyData = dataProvider.selectedDateHistory;

        if (_isLoading) {
          _simulateLoadingDelay();
        }

        final String loadingMessage =
            _isLoading ? 'Memeriksa data absensi' : '(Cek koneksi internet)';

        final bool historyAvailable = historyData != null;
        final String morningHistoryStatus = historyAvailable
            ? (historyData.tLPagi?.isNotEmpty ?? false)
                ? 'Anda sudah absen pagi'
                : 'Anda belum absen pagi'
            : loadingMessage;

        final String afternoonHistoryStatus = historyAvailable
            ? (historyData.tLSiang?.isNotEmpty ?? false)
                ? 'Anda sudah absen siang'
                : 'Anda belum absen siang'
            : loadingMessage;

        final bool isMorningTime = isCurrentTimeWithinRange(
          widget.currentTime.getDefaultDateTime(),
          '$morningStartHour:$morningStartMinute',
          '12:00',
        );

        final bool isAfternoonTime = isCurrentTimeWithinRange(
          widget.currentTime.getDefaultDateTime(),
          '12:00',
          '$storeClosedHour:$storeClosedMinute',
        );

        final String? historyStatus = isMorningTime
            ? morningHistoryStatus
            : isAfternoonTime
                ? afternoonHistoryStatus
                : null;

        _isVisible = historyStatus != null;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: _isLoading || _isVisible ? 1.0 : 0.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: _isLoading || _isVisible ? 60 : 0,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.tertiaryContainer,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    splashColor: Colors.greenAccent,
                    onTap: () async {
                      final isConnected =
                          await NetworkHelper.hasInternetConnection();
                      if (isConnected && context.mounted) {
                        Navigator.pushNamed(context, '/attendance',
                            arguments: AttendancePageArguments(
                                employeeName: widget.userName,
                                deviceName: widget.deviceName));
                      } else {
                        ToastUtil.showToast(
                            'Tidak ada koneksi internet', ToastStatus.error);
                      }
                    },
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_alert_sharp,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          if (_isVisible) const SizedBox(width: 10),
                          Text(
                            historyStatus ?? '',
                            style: FontTheme.bodyLarge(context,
                                color: Theme.of(context).indicatorColor,
                                fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isLoading)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _isLoading ? 1.0 : 0.0,
                    child: const CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
