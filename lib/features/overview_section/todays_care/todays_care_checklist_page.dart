/// Today's care in full, on a page of its own.
///
/// Home only ever shows the window the clock is in — breakfast before 11, lunch
/// in the afternoon, dinner at night — so the rest of the day was there but out
/// of reach. "View more" opens this, which is the same [TodocareSection] asked
/// for every window instead of one: the same sheets, the same tick-offs and the
/// same completion rules, so anything logged here is logged everywhere.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/overview_section/todays_care/todocare_section.dart';

class TodaysCareChecklistPage extends StatelessWidget {
  const TodaysCareChecklistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.scaffoldSoft,
      appBar: AppBar(
        backgroundColor: p.scaffoldSoft,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: p.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Today's timeline",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
          ),
        ),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(0, 8, 0, 32),
          child: TodocareSection(allDayParts: true),
        ),
      ),
    );
  }
}
