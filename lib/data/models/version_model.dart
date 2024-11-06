
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class AppVersionModel {
  String? version;
  int? buildNumber;
  bool? mandatory;
  String? link;

  AppVersionModel({
    this.version,
    this.buildNumber,
    this.mandatory,
    this.link,
  });

  // Convert Firestore DocumentSnapshot to AppVersionModel
  factory AppVersionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppVersionModel(
      version: data['version'],
      buildNumber: data['buildNumber'],
      mandatory: data['mandatory'],
      link: data['link'],
    );
  }

  // Convert Firestore DocumentSnapshot to AppVersionModel
  factory AppVersionModel.fromMap(Map<String, dynamic> map) {
    return AppVersionModel(
      version: map['version'] ?? '',
      buildNumber: map['buildNumber'] ?? '',
      mandatory: map['mandatory'] ?? '',
      link: map['link'] ?? '',
    );
  }

  // Convert AppVersionModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'version': version ?? '',
      'buildNumber': buildNumber ?? '',
      'mandatory': mandatory ?? '',
      'link': link ?? '',
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return toJson().toString();
  }
}