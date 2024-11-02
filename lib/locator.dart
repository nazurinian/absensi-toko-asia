import 'package:absensitoko/data/providers/data_provider.dart';
import 'package:absensitoko/utils/dialogs/dialog_utils.dart';
import 'package:absensitoko/utils/base/utility_service.dart';
import 'package:get_it/get_it.dart';

// Instance global dari GetIt
final GetIt locator = GetIt.instance;

// Fungsi untuk register dependensi
void setupLocator() {
  locator.registerLazySingleton<UtilityService>(() => UtilityService());
  locator.registerLazySingleton<DialogUtils>(() => DialogUtils());
  locator.registerLazySingleton<DataProvider>(() => DataProvider());
}


