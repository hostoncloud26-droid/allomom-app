import 'package:flutter/material.dart';

const double smallSpacing = 8.0;
const double mediumSpacing = 16.0;
const double largeSpacing = 24.0;

SizedBox spacingBox({double spacing = 8, bool horizontal = false}) {
  return SizedBox(
    height: horizontal ? 0 : spacing,
    width: horizontal ? spacing : 0,
  );
}

SizedBox smallSpacingBox({bool horizontal = false}) {
  return SizedBox(
    height: horizontal ? 0 : smallSpacing,
    width: horizontal ? smallSpacing : 0,
  );
}

SizedBox mediumSpacingBox({bool horizontal = false}) {
  return SizedBox(
    height: horizontal ? 0 : mediumSpacing,
    width: horizontal ? mediumSpacing : 0,
  );
}

SizedBox largeSpacingBox({bool horizontal = false}) {
  return SizedBox(
    height: horizontal ? 0 : largeSpacing,
    width: horizontal ? largeSpacing : 0,
  );
}
