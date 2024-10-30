import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:flutter/material.dart';

final Map<String, String> countryCodes = {
  '+62': 'Indonesia',
  // '+1': 'United States',  // '+91': 'India',  // '+81': 'Japan',  // '+65': 'Singapore',  // '+60': 'Malaysia',  // '+61': 'Australia',  // '+966': 'Saudi Arabia',
};

const List<String> roleList = ['employee', 'other', 'admin'];

const List<String> categories = ['Pagi', 'Siang', 'Libur', 'Cuti'];
const List<String> subCategories = ['Telat', 'Izin', 'Sakit'];

/*
enum AppImage {
  logo('assets/images/logo.png');

  final String path;

  const AppImage(this.path);
}

enum TombolType {
  home('assets/icons/home.png', isAsset: true),
  pesan('assets/icons/order.png', isAsset: true),
  listOrder('assets/icons/list.png', isAsset: true),
  cetakResiKirim('assets/icons/printer.png', isAsset: true),
  history(Icons.bookmark_added_rounded, isAsset: false),
  log('assets/icons/document.png', isAsset: true),
  listAgent('assets/icons/listagent.png', isAsset: true),
  listSender('assets/icons/listsender.png', isAsset: true),
  informasi('assets/icons/info.png', isAsset: true),
  sheet('assets/icons/sheet.png', isAsset: true);

  final dynamic icon;
  final bool isAsset;

  const TombolType(this.icon, {required this.isAsset});
}

const List<String> foto = [
  'assets/images/1.png',
  'assets/images/2.png',
  'assets/images/3.jpg',
  'assets/images/148100.jpg',
  'assets/images/858545.jpg',
];

const List<String> roleList = ['emplouee', 'other', 'admin'];
*/
