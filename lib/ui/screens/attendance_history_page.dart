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
  MonthlyHistory? monthlyHistory;

  Future<void> getMonthlyUserHistory() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    if(dataProvider.allUserHistoryData != null) {
      setState(() {
        monthlyHistory = dataProvider.allUserHistoryData!;
      });
      return;
    }

    final result = await dataProvider.getAllMonthHistory(userName);

    if(result.status != 'success') {
      monthlyHistory = null;
      ToastUtil.showToast('Gagal memperoleh data bulanan user', ToastStatus.error);
      return;
    }

    setState(() {
      monthlyHistory = dataProvider.allUserHistoryData!;
    });
    ToastUtil.showToast('Berhasil memperoleh data bulanan user', ToastStatus.success);
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
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text('This is the attendance history page'),
              Consumer<DataProvider>(builder: (context, dataProvider, child) {
                if (dataProvider.allUserHistoryData == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Container(
                  child:
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: monthlyHistory!.dayHistory!.length,
                    itemBuilder: (context, userIndex) {
                      final dataMonthly = monthlyHistory!.dayHistory!;
                      return ExpansionTile(
                        title: Text('Riwayat absensi bulanan'),
                        children: dataMonthly.keys.map((monthKey) {
                          // Step 2: Ambil data bulan
                          DailyHistory dayHistory =
                          dataMonthly[monthKey]!;
                          return ExpansionTile(
                            title: Text('Bulan: $monthKey'),
                            children: dayHistory.historyData!.keys.map((dateKey) {
                              // Step 3: Ambil data tanggal
                              HistoryData historyData =
                              dayHistory.historyData![dateKey]!;

                              return ListTile(
                                title: Text('Tanggal: $dateKey'),
                                subtitle: Text(
                                    'Hadir Pagi: ${historyData.hadirPagi ?? "N/A"}\n'
                                        'Point Pagi: ${historyData.pointPagi ?? "N/A"}\n'
                                        'Keterangan: ${historyData.keterangan ?? "N/A"}\n'
                                        'Latitude: ${historyData.lat?.toStringAsFixed(4) ?? "N/A"}\n'
                                        'Longitude: ${historyData.lang?.toStringAsFixed(4) ?? "N/A"}'),
                              );
                            }).toList(),
                          );
                        }).toList(),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
