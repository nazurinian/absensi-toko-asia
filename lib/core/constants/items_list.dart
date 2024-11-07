// '+1': 'United States',  // '+91': 'India',  // '+81': 'Japan',  // '+65': 'Singapore',  // '+60': 'Malaysia',  // '+61': 'Australia',  // '+966': 'Saudi Arabia',
const Map<String, String> countryCodes = {
  '+62': 'Indonesia',
};

const List<String> roleList = ['employee', 'other', 'admin'];
const List<String> employeeList = ['Syarifuddin', 'Abdurrahman', 'Sadiq', 'Ilham'];

const List<String> categories = ['Pagi', 'Siang', 'Libur', 'Cuti'];
const List<String> subCategories = ['Telat', 'Izin', 'Sakit'];

enum AppImage {
  attendanceApp('images/01.png'),
  atk('images/02.png'),
  leaf('images/03.png'),
  leafFlipped('images/04.png'),
  watch('images/05.png'),
  logo('images/06.png'),
  stopwatch('images/07.png'),
  blankUser('images/08.png');

  final String path;

  const AppImage(this.path);
}

/*
enum TombolType {
  home('icons/home.png', isAsset: true),
  log('icons/document.png', isAsset: true),
  informasi('icons/info.png', isAsset: true),
  sheet('icons/sheet.png', isAsset: true);

  final dynamic icon;
  final bool isAsset;

  const TombolType(this.icon, {required this.isAsset});
}
*/
