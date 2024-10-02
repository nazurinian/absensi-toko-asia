import 'package:flutter/material.dart';

double statusBarHeight(BuildContext context) {
  return MediaQuery.of(context).padding.top;
}

double appBarHeight(BuildContext context) {
  return AppBar().preferredSize.height;
}

double screenWidth(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

double screenHeight(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

double normalBodyHeight(BuildContext context) {
  return screenHeight(context) - statusBarHeight(context) - appBarHeight(context);
}