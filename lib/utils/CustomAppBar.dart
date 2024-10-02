import 'package:flutter/material.dart';

Widget customAppBar({
  List<Widget>? actions,
}) =>
    AppBar(
      backgroundColor: Colors.blueAccent,
      title: Image.asset(
        'assets/images/Logo_Najwa_Tsuroyya.png',
        height: 60,
      ),
      centerTitle: true,
      actions: actions,
    );
