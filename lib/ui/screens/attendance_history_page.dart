import 'package:absensitoko/core/themes/fonts/fonts.dart';
import 'package:absensitoko/data/models/history_model.dart';
import 'package:absensitoko/data/providers/data_provider.dart';
import 'package:absensitoko/utils/popup_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AttendanceHistoryPage extends StatefulWidget {
  final String employeeName;

  const AttendanceHistoryPage({super.key, required this.employeeName});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  late String userName;
  List<ExpansionTileController> expansionTileControllers = [];

  MonthlyHistory? monthlyHistory;

  Future<void> getMonthlyUserHistory({bool isRefresh = false}) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    if (dataProvider.allUserHistoryData != null && !isRefresh) {
      setState(() {
        monthlyHistory = dataProvider.allUserHistoryData!;

        expansionTileControllers = List.generate(
            monthlyHistory!.dayHistory!.length + 1, (_) => ExpansionTileController());
      });
      return;
    }

    final result =
        await dataProvider.getAllMonthHistory(userName, isRefresh: isRefresh);

    if (result.status != 'success') {
      monthlyHistory = null;
      ToastUtil.showToast(
          'Gagal ${!isRefresh ? 'memperoleh' : 'memperbarui'} data bulanan user',
          ToastStatus.error);
      return;
    }

    setState(() {
      monthlyHistory = dataProvider.allUserHistoryData!;

      expansionTileControllers = List.generate(
          monthlyHistory!.dayHistory!.length, (_) => ExpansionTileController());
    });
    ToastUtil.showToast(
        'Berhasil ${!isRefresh ? 'memperoleh' : 'memperbarui'} data bulanan user',
        ToastStatus.success);
  }

  @override
  void initState() {
    super.initState();
    userName = widget.employeeName;

    getMonthlyUserHistory();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Kehadiran'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          for (var element in expansionTileControllers) {
            if(element.isExpanded) element.collapse();
          }
          await Future.delayed(const Duration(seconds: 2));
          await getMonthlyUserHistory(isRefresh: true);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const Text('Riwayat absensi bulanan'),
                Consumer<DataProvider>(builder: (context, dataProvider, child) {
                  if (dataProvider.allUserHistoryData == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: monthlyHistory!.dayHistory!.length,
                    itemBuilder: (context, index) {
                      // Data Seluruh bulan
                      final dataMonthly = monthlyHistory!.dayHistory!;
                      final monthKey = dataMonthly.keys.elementAt(index);
                      // Data Seluruh bulan dijadikan list Data Harian
                      final List<DailyHistory> listDayHistory =
                          dataMonthly.values.map((e) => e).toList();
                      // Step 2: Ambil data Tiap harinya
                      DailyHistory dayHistory = listDayHistory[index];

                      return ExpansionTile(
                        controller: expansionTileControllers[index],
                        onExpansionChanged: (bool isOpen) {
                          if (isOpen) {
                            for (var i = 0; i < expansionTileControllers.length; i++) {
                              if (i != index) {
                                expansionTileControllers[i].collapse();
                              }
                            }
                          }
                        },
                        leading: const Icon(Icons.calendar_today),
                        title: Text(
                          monthKey,
                          style: FontTheme.titleMedium(context),
                        ),
                        children: dayHistory.historyData!.keys.map((dateKey) {
                          // Step 3: Ambil data tanggal
                          HistoryData historyData =
                              dayHistory.historyData![dateKey]!;
                          return ExpansionTile(
                            leading: Card(
                              color: Colors.blue,
                              child: Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                child: Text(dateKey,
                                  style: FontTheme.titleMedium(context),),
                              ),
                            ),
                            title: Text(
                              historyData.hari.toString(),
                              style: FontTheme.titleMedium(context),
                            ),
                            children: [
                              ListTile(
                                // title: Text(
                                //   'Tanggal: $dateKey | Hari: ${historyData.hari}',
                                //   style: FontTheme.titleMedium(context),
                                // ),
                                subtitle: Text(
                                    'Hadir Pagi: ${historyData.hadirPagi ?? "N/A"}\n'
                                    'T/L Pagi: ${historyData.tLPagi ?? "N/A"}\n'
                                    'Point Pagi: ${historyData.pointPagi ?? "N/A"}\n'
                                    'Jam istirahat: ${historyData.pulangSiang ?? "N/A"}\n'
                                    'Hadir Siang: ${historyData.hadirSiang ?? "N/A"}\n'
                                    'T/L Siang: ${historyData.tLSiang ?? "N/A"}\n'
                                    'Point Siang: ${historyData.pointSiang ?? "N/A"}\n'
                                    'Keterangan: ${historyData.keterangan ?? "N/A"}\n'
                                    'Latitude: ${historyData.lat?.toStringAsFixed(4) ?? "N/A"}\n'
                                    'Longitude: ${historyData.long?.toStringAsFixed(4) ?? "N/A"}'),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* return ExpansionTile(
title: Text('Riwayat absensi bulanan', style: FontTheme.titleLarge(context),),
children: dataMonthly.keys.map((monthKey) {
  // Step 2: Ambil data bulan
  DailyHistory dayHistory =
  dataMonthly[monthKey]!;
  return ExpansionTile(
    title: Text('Bulan: $monthKey', style: FontTheme.titleMedium(context),),
    children: dayHistory.historyData!.keys.map((dateKey) {
      // Step 3: Ambil data tanggal
      HistoryData historyData =
      dayHistory.historyData![dateKey]!;

      return ListTile(
        title: Text('Tanggal: $dateKey | Hari: ${historyData.hari}', style: FontTheme.titleMedium(context),),
        subtitle: Text(
            'Hadir Pagi: ${historyData.hadirPagi ?? "N/A"}\n'
                'T/L Pagi: ${historyData.tLPagi ?? "N/A"}\n'
                'Point Pagi: ${historyData.pointPagi ?? "N/A"}\n'
                'Jam istirahat: ${historyData.pulangSiang ?? "N/A"}\n'
                'Hadir Siang: ${historyData.hadirSiang ?? "N/A"}\n'
                'T/L Siang: ${historyData.tLSiang ?? "N/A"}\n'
                'Point Siang: ${historyData.pointSiang ?? "N/A"}\n'
                'Keterangan: ${historyData.keterangan ?? "N/A"}\n'
                'Latitude: ${historyData.lat?.toStringAsFixed(4) ?? "N/A"}\n'
                'Longitude: ${historyData.long?.toStringAsFixed(4) ?? "N/A"}'),
      );
    }).toList(),
  );
}).toList(),
);*/