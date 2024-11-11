import 'package:absensitoko/data/models/attendance_model.dart';
import 'package:absensitoko/data/providers/data_provider.dart';
import 'package:absensitoko/ui/widgets/custom_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TemporaryAdminPage extends StatefulWidget {
  const TemporaryAdminPage({super.key});

  @override
  State<TemporaryAdminPage> createState() => _TemporaryAdminPageState();
}

class _TemporaryAdminPageState extends State<TemporaryAdminPage> {
  late DataProvider _dataProvider;
  Map<String, bool> _temporaryAdmin = {};

  Future<void> _getTemporaryAdmin() async {
    if (_dataProvider.isTemporaryAdminsAvailable) {
      final temporaryAdmin = _dataProvider.temporaryAdmins;
      _temporaryAdmin = temporaryAdmin;
      return;
    }

    final result = await _dataProvider.getTemporaryAdmins();
    if(result.status == 'success') {
      final temporaryAdmin = _dataProvider.temporaryAdmins;
      _temporaryAdmin = temporaryAdmin;
    }
  }

  Future<void> _updateTemporaryAdmin(String name, bool value) async {
    final result = await _dataProvider.updateTemporaryAdmin(name, value);
    if (result.status == 'success') {
      setState(() {
        _temporaryAdmin[name] = value; // Update state lokal
      });
    } else {
      // Beri pesan atau handling error jika gagal
      print('Failed to update $name to $value');
    }
  }

  @override
  void initState() {
    super.initState();
    _dataProvider = Provider.of<DataProvider>(context, listen: false);
    _getTemporaryAdmin();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temporary Admin'),
        backgroundColor: Colors.brown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<DataProvider>(builder: (context, dataProvider, child) {
          if (dataProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (!dataProvider.isTemporaryAdminsAvailable) {
            return const Center(child: Text('No Temporary Admins Available'));
          }
          return ListView.builder(
            itemCount: _temporaryAdmin.keys.length,
            itemBuilder: (context, index) {
              final name = _temporaryAdmin.keys.elementAt(index).toUpperCase();
              final value = _temporaryAdmin.values.elementAt(index);
              
              return CustomListTile(title: name, trailing: Switch(value: value, onChanged: (newValue) async{
                await _updateTemporaryAdmin(name.toLowerCase(), newValue);
              },));
            },
          );
        }),
      ),
    );
  }
}
