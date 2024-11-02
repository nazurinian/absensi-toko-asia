import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:flutter/material.dart';

const Map<String, String> countryCodes = {
  '+62': 'Indonesia',
  // '+1': 'United States',  // '+91': 'India',  // '+81': 'Japan',  // '+65': 'Singapore',  // '+60': 'Malaysia',  // '+61': 'Australia',  // '+966': 'Saudi Arabia',
};

const List<String> roleList = ['employee', 'other', 'admin'];

const List<String> categories = ['Pagi', 'Siang', 'Libur', 'Cuti'];
const List<String> subCategories = ['Telat', 'Izin', 'Sakit'];

enum AppImage {
  leaf('assets/images/daun.png'),
  leaf_flipped('assets/images/daun_flipped.png'),
  stopwatch('assets/images/stopwatch.png'),;

  final String path;

  const AppImage(this.path);
}

/*
enum TombolType {
  home('assets/icons/home.png', isAsset: true),
  history(Icons.bookmark_added_rounded, isAsset: false),
  log('assets/icons/document.png', isAsset: true),
  informasi('assets/icons/info.png', isAsset: true),
  sheet('assets/icons/sheet.png', isAsset: true);

  final dynamic icon;
  final bool isAsset;

  const TombolType(this.icon, {required this.isAsset});
}
*/
