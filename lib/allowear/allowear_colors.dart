
import 'package:flutter/material.dart';

const PrimaryColor = Color(0xffFF626F);
const SecondaryColor = Color(0xff448AFF);
const accentColor = Color(0xffffcfd3);
const Blue800 = Color(0xffffcfd3);
const Blue100 = Color(0xffE9E7FC);
const Black = Color(0xff181A1D);
const Black800 = Color(0xff474A57);
const Black700 = Color(0xff969BAB);
const Black300 = Color(0xff9FA4B4);
const Black200 = Color(0xffEEEFF4);
const Black100 = Color(0xffF4F5F7);
const White = Color(0xffFFFFFF);
const darkGrey = Color(0xff121212);
const darkGrey2 = Color(0xff1F1F1F);
const darkGrey3 = Color(0xff373737);


Color getPrimaryColor(BuildContext context){
  return Theme.of(context).primaryColor;
}


LinearGradient getPrimaryGradient(BuildContext context){

  final primaryColor = getPrimaryColor(context);
  return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                      primaryColor.withOpacity(0.85),
                      primaryColor.withOpacity(0.65),
                    ],
            );
}
