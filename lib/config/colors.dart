import 'package:flutter/material.dart';

const Color primaryColor = Color(0xffFF626F);
const Color secondaryColor = Color(0xff448AFF);
const Color accentColor = Color(0xffffcfd3);
const Color accentLight = Color(0xFFFFF0F1);
const Color backgroundPink = Color(0xFFFFF5F6);

const Color textDark = Color(0xff181A1D);
const Color textMedium = Color(0xff474A57);
const Color textLight = Color(0xff969BAB);
const Color textMuted = Color(0xff9FA4B4);

const Color cardBackground = Color(0xffFFFFFF);
const Color dividerColor = Color(0xffEEEFF4);
const Color surfaceLight = Color(0xffF4F5F7);

const Color successGreen = Color(0xff4CAF50);
const Color warningAmber = Color(0xffFFA726);
const Color infoCyan = Color(0xff26C6DA);
const Color dangerRed = Color(0xffEF5350);

LinearGradient get primaryGradient => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFF8A95),
        primaryColor,
      ],
    );

LinearGradient get backgroundGradient => const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFF0F1),
        Color(0xFFFFFAFB),
        Colors.white,
      ],
    );
