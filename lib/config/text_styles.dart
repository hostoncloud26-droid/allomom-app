import 'package:flutter/material.dart';

TextStyle headingStyle({Color? color}) {
  return TextStyle(
    color: color ?? const Color(0xff181A1D),
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
  );
}

TextStyle subHeadingStyle({Color? color, FontWeight? fontWeight}) {
  return TextStyle(
    color: color ?? Colors.grey[700],
    fontSize: 16,
    fontWeight: fontWeight ?? FontWeight.w500,
  );
}

TextStyle bodyStyle({Color? color, double? fontSize}) {
  return TextStyle(
    color: color ?? Colors.grey[600],
    fontSize: fontSize ?? 14,
    fontWeight: FontWeight.w400,
  );
}

TextStyle labelStyle({Color? color}) {
  return TextStyle(
    color: color ?? Colors.grey[500],
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}

TextStyle boldNumber({Color? color, double? fontSize}) {
  return TextStyle(
    color: color ?? const Color(0xff181A1D),
    fontSize: fontSize ?? 32,
    fontWeight: FontWeight.bold,
  );
}
