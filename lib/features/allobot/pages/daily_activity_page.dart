import 'package:flutter/material.dart';

import 'package:allomom/config/app_theme.dart';

import 'package:allomom/features/overview_section/todays_care/todocare_section.dart';

/// The "Daily activity" agent's own screen — today's five things, on a page of
/// their own instead of buried under the rest of home.
class DailyActivityPage extends StatelessWidget {
  const DailyActivityPage({super.key});

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
            color: p.pick(const Color(0xFF2D3142), p.textPrimary),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Daily activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: p.pick(const Color(0xFF2D3142), p.textPrimary),
          ),
        ),
      ),
      body: const SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(0, 6, 0, 32),
        child: TodocareSection(),
      ),
    );
  }
}
