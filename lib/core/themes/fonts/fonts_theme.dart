part of 'fonts.dart';

class FontTheme {
  static TextStyle bodyLarge(
      BuildContext context, {
        Color? color,
        FontWeight? fontWeight,
        double? fontSize,
      }) {
    final textTheme = Theme.of(context).textTheme;
    return textTheme.bodyLarge!.copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }

  static TextStyle bodyMedium(
      BuildContext context, {
        Color? color,
        FontWeight? fontWeight,
        double? fontSize,
      }) {
    final textTheme = Theme.of(context).textTheme;
    return textTheme.bodyMedium!.copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }

  static TextStyle bodySmall(
      BuildContext context, {
        Color? color,
        FontWeight? fontWeight,
        double? fontSize,
      }) {
    final textTheme = Theme.of(context).textTheme;
    return textTheme.bodySmall!.copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }

  static TextStyle titleLarge(
      BuildContext context, {
        Color? color,
        FontWeight? fontWeight,
        double? fontSize,
      }) {
    final textTheme = Theme.of(context).textTheme;
    return textTheme.titleLarge!.copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }

  static TextStyle titleMedium(
      BuildContext context, {
        Color? color,
        FontWeight? fontWeight,
        double? fontSize,
      }) {
    final textTheme = Theme.of(context).textTheme;
    return textTheme.titleMedium!.copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }

  static TextStyle titleSmall(
      BuildContext context, {
        Color? color,
        FontWeight? fontWeight,
        double? fontSize,
      }) {
    final textTheme = Theme.of(context).textTheme;
    return textTheme.titleSmall!.copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }
}


// titleTextStyle: textTheme.titleLarge?.copyWith(
//   color: Theme.of(context).colorScheme.primary,
//   fontWeight: FontWeight.bold,
//   fontSize: 28
// ),