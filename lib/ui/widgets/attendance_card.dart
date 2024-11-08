import 'package:absensitoko/core/themes/fonts/fonts.dart';
import 'package:flutter/material.dart';

class AttendanceCard extends StatelessWidget {
  final String title;
  final String buttonText;
  final bool buttonActive;
  final VoidCallback onButtonPressed;
  final Widget attendanceStatus;
  final String message;
  final Color colorState;

  const AttendanceCard({
    super.key,
    required this.title,
    required this.buttonText,
    required this.buttonActive,
    required this.onButtonPressed,
    required this.attendanceStatus,
    required this.message,
    required this.colorState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        color: colorState,
        elevation: 5,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                title,
                style: FontTheme.bodyMedium(
                  context,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: buttonActive ? onButtonPressed : null,
                child: Text(buttonText),
              ),
              attendanceStatus,
              if (message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: 18,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}