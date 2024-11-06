import 'package:absensitoko/core/themes/fonts/fonts.dart';
import 'package:flutter/material.dart';

class CustomListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const CustomListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: _buildTrailing(context),
      onTap: onTap,
    );
  }

  Widget _buildTrailing(BuildContext context) {
    if (trailing is Text) {
      return DefaultTextStyle(
        style: FontTheme.bodyMedium(context, fontSize: 16),
        child: trailing,
      );
    }
    return trailing;
  }
}
