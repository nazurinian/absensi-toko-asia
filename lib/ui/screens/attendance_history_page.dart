import 'package:absensitoko/core/themes/fonts/fonts.dart';
import 'package:absensitoko/data/models/history_model.dart';
import 'package:absensitoko/data/providers/data_provider.dart';
import 'package:absensitoko/utils/display_size_util.dart';
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

    print('ExpansionTileControllers length: ${expansionTileControllers.length}');

    if (dataProvider.allUserHistoryData != null && !isRefresh) {
      setState(() {
        monthlyHistory = dataProvider.allUserHistoryData!;

        // Reinitialize controllers only if data length has changed
        if (expansionTileControllers.length != monthlyHistory!.dayHistory!.length + 1) {
          _initializeExpansionTileControllers(monthlyHistory!.dayHistory!.length);
        }
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

      // Reinitialize controllers only if data length has changed
      if (expansionTileControllers.length != monthlyHistory!.dayHistory!.length) {
        _initializeExpansionTileControllers(monthlyHistory!.dayHistory!.length);
      }
    });
    ToastUtil.showToast(
        'Berhasil ${!isRefresh ? 'memperoleh' : 'memperbarui'} data bulanan user',
        ToastStatus.success);
  }

  // Fungsi untuk membersihkan dan menginisialisasi ulang controller
  void _initializeExpansionTileControllers(int length) {
    expansionTileControllers.clear();
    expansionTileControllers = List.generate(length, (_) => ExpansionTileController());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Panggil inisialisasi jika data ada
    if (monthlyHistory == null) {
      getMonthlyUserHistory();
    } else {
      _initializeExpansionTileControllers(monthlyHistory!.dayHistory!.length);
    }
  }

  @override
  void initState() {
    super.initState();
    userName = widget.employeeName;

    // Ensure controllers are initialized when page loads
    getMonthlyUserHistory();
  }

  @override
  void dispose() {
    // Clear controllers when the page is disposed
    expansionTileControllers.clear();
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
                  title: const Text('Riwayat Kehadiran'),
                ),
                body: RefreshIndicator(
                  onRefresh: () async {
                    for (var element in expansionTileControllers) {
                      if (element.isExpanded) element.collapse();
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
                              itemCount: monthlyHistory?.dayHistory?.length ?? 0,
                              itemBuilder: (context, index) {
                                // final dataMonthly = monthlyHistory!.dayHistory!;
                                // final monthKey = dataMonthly.keys.elementAt(index);
                                // final List<DailyHistory> listDayHistory =
                                // dataMonthly.values.toList();
                                // DailyHistory dayHistory = listDayHistory[index];

                                final dataMonthly = monthlyHistory!.dayHistory!;

                                // Urutkan data bulan (tahun-bulan)
                                List<MapEntry<String, DailyHistory>> sortedMonthEntries = dataMonthly.entries.toList()
                                  ..sort((a, b) => b.key.compareTo(a.key)); // Urutkan berdasarkan bulan

                                final monthEntry = sortedMonthEntries[index];
                                final monthKey = monthEntry.key;
                                final DailyHistory monthData = monthEntry.value;

                                // Urutkan berdasarkan tanggal di dalam setiap bulan
                                List<MapEntry<String, HistoryData>> sortedDayEntries = monthData.historyData!.entries.toList()
                                  ..sort((a, b) => b.key.compareTo(a.key)); // Urutkan berdasarkan tanggal


                                return ExpansionTile(
                                  controller: expansionTileControllers[index],
                                  onExpansionChanged: (bool isOpen) {
                                    if (isOpen) {
                                      for (var i = 0; i < expansionTileControllers.length; i++) {
                                        if (i != index && mounted) {
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
                                  // children: dayHistory.historyData!.keys.map((dateKey) {
                                  //   HistoryData historyData = dayHistory.historyData![dateKey]!;
                                  children: sortedDayEntries.map((dayEntry) {
                                    final dayKey = dayEntry.key;
                                    final historyData = dayEntry.value;

                                    return ExpansionTile(
                                      leading: Card(
                                        color: Colors.blue,
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          alignment: Alignment.center,
                                          child: Text(dayKey, style: FontTheme.titleMedium(context)),
                                        ),
                                      ),
                                      title: Text(
                                        historyData.hari.toString(),
                                        style: FontTheme.titleMedium(context),
                                      ),
                                      children: [
                                        ListTile(
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
                                                'Longitude: ${historyData.long?.toStringAsFixed(4) ?? "N/A"}',
                                          ),
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
              ),
            ),
          ),
        ),
      ],
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