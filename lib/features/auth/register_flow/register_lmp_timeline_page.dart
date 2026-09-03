import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/features/auth/widgets/baby_speech_avatar.dart';
import 'package:allomom/features/auth/register_flow/register_edd_due_date_page.dart';

class RegisterLmpTimelinePage extends StatefulWidget {
  final String userName;
  final String status;
  final String phone;
  final String countryCode;

  const RegisterLmpTimelinePage({
    super.key,
    required this.userName,
    required this.status,
    this.phone = '',
    this.countryCode = '+91',
  });

  @override
  State<RegisterLmpTimelinePage> createState() =>
      _RegisterLmpTimelinePageState();
}

class _RegisterLmpTimelinePageState extends State<RegisterLmpTimelinePage> {
  late DateTime _selectedDate;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);

    _dayController = FixedExtentScrollController(
      initialItem: _selectedDate.day - 1,
    );
    _monthController = FixedExtentScrollController(
      initialItem: _selectedDate.month - 1,
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _onDayChanged(int dayIndex) {
    HapticFeedback.selectionClick();
    final maxDays = _getDaysInMonth(_selectedDate.year, _selectedDate.month);
    final targetDay = (dayIndex + 1).clamp(1, maxDays);
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        targetDay,
      );
    });
  }

  void _onMonthChanged(int monthIndex) {
    HapticFeedback.selectionClick();
    final targetMonth = monthIndex + 1;
    final maxDays = _getDaysInMonth(_selectedDate.year, targetMonth);
    final targetDay = _selectedDate.day.clamp(1, maxDays);

    setState(() {
      _selectedDate = DateTime(_selectedDate.year, targetMonth, targetDay);
    });

    if (_dayController.hasClients && _dayController.selectedItem >= maxDays) {
      _dayController.jumpToItem(maxDays - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedFormatted =
        '${_selectedDate.day} ${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';
    final daysInCurrentMonth = _getDaysInMonth(
      _selectedDate.year,
      _selectedDate.month,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
      body: SafeArea(
        child: Column(
          children: [
            // ─── TOP APP BAR ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF1E2024),
                        size: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Select LMP Date',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // ─── BABY SPEECH AVATAR ───
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: BabySpeechAvatar(
                speechText:
                    'When was the first day of your last\nmenstrual period? 🌸',
                onSpeakerTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Swipe Day or Month to set your LMP date!'),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                },
              ),
            ),

            const Spacer(),

            // ─── BOTTOM CARD CONTAINER (SINGLE VIEW, NO SCROLL) ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LAST MENSTRUAL PERIOD (LMP)',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8E95A5),
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Swipe to adjust',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF4E6A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Selected Date Display Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFF4E6A),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFF4E6A,
                            ).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Color(0xFFFF4E6A),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selectedFormatted,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E2024),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4E6A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Selected',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── SWIPEABLE DAY & MONTH WHEEL SELECTOR (NO YEAR, NO BUTTONS) ───
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6F7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF0E5E7)),
                    ),
                    child: Column(
                      children: [
                        // Column Titles
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                'DAY',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF8E95A5),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'MONTH',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF8E95A5),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Wheel Picker Area (Day & Month only)
                        SizedBox(
                          height: 145,
                          child: Stack(
                            children: [
                              // Center Selection Highlight Bar
                              Center(
                                child: Container(
                                  height: 44,
                                  width: double.infinity,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F3),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFFF4E6A,
                                      ).withValues(alpha: 0.6),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),

                              // The 2 Swipeable Wheels: DAY & MONTH
                              Row(
                                children: [
                                  // ─── DAY WHEEL ───
                                  Expanded(
                                    flex: 1,
                                    child: ListWheelScrollView.useDelegate(
                                      controller: _dayController,
                                      itemExtent: 44,
                                      perspective: 0.003,
                                      diameterRatio: 1.5,
                                      physics: const FixedExtentScrollPhysics(),
                                      onSelectedItemChanged: _onDayChanged,
                                      childDelegate:
                                          ListWheelChildBuilderDelegate(
                                            builder: (context, index) {
                                              if (index < 0 ||
                                                  index >= daysInCurrentMonth) {
                                                return null;
                                              }
                                              final dayNum = index + 1;
                                              final isSelected =
                                                  dayNum == _selectedDate.day;
                                              return Center(
                                                child: Text(
                                                  dayNum.toString().padLeft(
                                                    2,
                                                    '0',
                                                  ),
                                                  style: GoogleFonts.outfit(
                                                    fontSize: isSelected
                                                        ? 22
                                                        : 16,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w800
                                                        : FontWeight.w500,
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFFFF4E6A,
                                                          )
                                                        : const Color(
                                                            0xFF8E95A5,
                                                          ),
                                                  ),
                                                ),
                                              );
                                            },
                                            childCount: daysInCurrentMonth,
                                          ),
                                    ),
                                  ),

                                  // Divider
                                  Container(
                                    width: 1,
                                    height: 90,
                                    color: const Color(0xFFEFE8E9),
                                  ),

                                  // ─── MONTH WHEEL ───
                                  Expanded(
                                    flex: 1,
                                    child: ListWheelScrollView.useDelegate(
                                      controller: _monthController,
                                      itemExtent: 44,
                                      perspective: 0.003,
                                      diameterRatio: 1.5,
                                      physics: const FixedExtentScrollPhysics(),
                                      onSelectedItemChanged: _onMonthChanged,
                                      childDelegate:
                                          ListWheelChildBuilderDelegate(
                                            builder: (context, index) {
                                              if (index < 0 || index >= 12) {
                                                return null;
                                              }
                                              final monthName =
                                                  _monthNames[index];
                                              final isSelected =
                                                  (index + 1) ==
                                                  _selectedDate.month;
                                              return Center(
                                                child: Text(
                                                  monthName,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: isSelected
                                                        ? 20
                                                        : 15,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w800
                                                        : FontWeight.w500,
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFFFF4E6A,
                                                          )
                                                        : const Color(
                                                            0xFF8E95A5,
                                                          ),
                                                  ),
                                                ),
                                              );
                                            },
                                            childCount: 12,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── CALCULATE DUE DATE BUTTON ───
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final lmp = _selectedDate;
                        final edd = lmp.add(const Duration(days: 280));

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegisterEddDueDatePage(
                              userName: widget.userName,
                              status: widget.status,
                              lmpDate: lmp,
                              eddDate: edd,
                              phone: widget.phone,
                              countryCode: widget.countryCode,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5277),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Calculate Due Date',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
