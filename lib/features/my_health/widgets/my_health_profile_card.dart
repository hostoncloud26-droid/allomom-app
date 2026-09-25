import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:allomom/api/secure_token_api.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/my_health/widgets/health_info_editor_sheet.dart';

/// Port of AlloConnect's `MyHealthProfileCard`: a full-bleed gradient header
/// with an ECG backdrop, the user's avatar + Name / Age / Blood group on the
/// left and the health records QR on the right.
///
/// The QR carries a short-lived secure token, as AlloConnect's does, so the
/// link stops working 15 minutes after it was issued. The token is cached for
/// 14 minutes so the card does not ask for a new one on every rebuild.
///
/// Designed as a `SliverAppBar(expandedHeight: 230)` flexibleSpace background:
/// it pads itself by the status-bar inset and is 278px tall when unconstrained.
/// Tapping it opens [HealthInfoEditorSheet] unless [onTap] is given.
class MyHealthProfileCard extends StatefulWidget {
  final VoidCallback? onTap;

  const MyHealthProfileCard({super.key, this.onTap});

  /// Where a scanned QR lands, followed by the token.
  static const String healthProfileUrlBase =
      'https://allokonnect.com/health-profile/';

  @override
  State<MyHealthProfileCard> createState() => _MyHealthProfileCardState();
}

class _MyHealthProfileCardState extends State<MyHealthProfileCard> {
  static const _ink = Color(0xFF1F3D4D);
  static const _cacheToken = 'last_health_qr_data';
  static const _cacheAt = 'last_health_qr_generated_at';
  static const _cacheFor = Duration(minutes: 14);

  String? _token;
  bool _loadingToken = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken({bool force = false}) async {
    if (_loadingToken) return;
    setState(() => _loadingToken = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!force) {
        final cached = prefs.getString(_cacheToken);
        final at = DateTime.tryParse(prefs.getString(_cacheAt) ?? '');
        if (cached != null &&
            cached.isNotEmpty &&
            at != null &&
            DateTime.now().difference(at) < _cacheFor) {
          if (mounted) setState(() => _token = cached);
          return;
        }
      }

      final response = await SecureTokenApi.create(type: 'health-profile');
      final item = response.item;
      final token = item is String
          ? item
          : (item is Map ? item['token']?.toString() : null);

      if (response.success && token != null && token.isNotEmpty) {
        await prefs.setString(_cacheToken, token);
        await prefs.setString(_cacheAt, DateTime.now().toIso8601String());
        if (mounted) setState(() => _token = token);
      }
    } catch (e) {
      debugPrint('MyHealthProfileCard: could not create QR token: $e');
    } finally {
      if (mounted) setState(() => _loadingToken = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    return AnimatedBuilder(
      animation: Listenable.merge(
          [MainController.instance, HealthVitalsController.instance]),
      builder: (context, _) {
        final session = MainController.instance;
        final vitals = HealthVitalsController.instance;

        final primaryColor = Theme.of(context).primaryColor;
        final topPadding = MediaQuery.of(context).padding.top;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final userName = session.userName.trim();
        final userImage = session.profilePicture?.trim() ?? '';
        final hasImage = userImage.startsWith('http');

        final bgRaw = session.bloodGroup ?? vitals.bloodGroupVital?.unit;
        final bloodGroup =
            (bgRaw != null && bgRaw.trim().isNotEmpty) ? bgRaw.trim() : '--';
        final double? height = vitals.heightVital?.value;
        final double? weight = vitals.hasWeight ? vitals.weightValue : null;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ??
                () => HealthInfoEditorSheet.show(
                      context: context,
                      userId: session.userId,
                      height: height,
                      weight: weight,
                      bloodGroup: bloodGroup == '--' ? null : bloodGroup,
                      primaryColor: primaryColor,
                    ),
            child: Container(
              width: double.infinity,
              height: 278,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark ? Colors.black : const Color(0xFFF7FAFC),
                    primaryColor.withValues(alpha: 0.23),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _HeartBeatWavePainter(color: primaryColor),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, topPadding + 20, 16, 20),
                    child: Row(
                      children: [
                        // Left column: avatar and data rows
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primaryColor.withValues(alpha: 0.35),
                                    width: 1.4,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white,
                                  backgroundImage:
                                      hasImage ? NetworkImage(userImage) : null,
                                  child: hasImage
                                      ? null
                                      : Icon(
                                          Icons.person_rounded,
                                          size: 50,
                                          color: primaryColor.withValues(
                                              alpha: 0.6),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _dataRow('Name',
                                  userName.isEmpty ? '--' : userName, isDark),
                              const SizedBox(height: 4),
                              _dataRow('Age', _age(session.dob), isDark),
                              const SizedBox(height: 4),
                              _dataRow('Blood group', bloodGroup, isDark),
                              const Spacer(),
                            ],
                          ),
                        ),
                        // Right column: highlight panel + caption
                        Expanded(
                          flex: 4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 10,
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: primaryColor.withValues(
                                            alpha: 0.3),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withValues(
                                              alpha: 0.1),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: _qrPanel(primaryColor),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Scan for health records',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : _ink,
                                  letterSpacing: -0.2,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// What the code carries: the secure-token link once the server issues
  /// one, and until then a placeholder built from her user id.
  ///
  /// TODO: allomom-api-new has no `/stokens/create` yet, so the token request
  /// fails and the placeholder is what shows. It does not open anything when
  /// scanned — the scan-to-view logic is still to be decided.
  String _qrData() {
    final token = _token;
    if (token != null && token.isNotEmpty) {
      return '${MyHealthProfileCard.healthProfileUrlBase}$token';
    }
    return '${MyHealthProfileCard.healthProfileUrlBase}'
        '${MainController.instance.userId}';
  }

  /// Always a code — never a spinner or an "unavailable" note in its place.
  Widget _qrPanel(Color primaryColor) {
    return QrImageView(
      padding: const EdgeInsets.all(2),
      data: _qrData(),
      version: QrVersions.auto,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
    );
  }

  Widget _dataRow(String label, String value, bool isDark) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white.withValues(alpha: 0.9) : _ink,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : _ink.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static String _age(DateTime? dob) {
    if (dob == null) return '--';
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age.toString();
  }
}

/// Static ECG backdrop (AlloConnect's `HeartBeatWavePainter`, progress 0).
class _HeartBeatWavePainter extends CustomPainter {
  final Color color;

  const _HeartBeatWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final width = size.width;
    final centerY = size.height * 0.55;
    const cycleWidth = 200.0;

    for (double x = -cycleWidth; x < width + cycleWidth; x += 1) {
      final relX = x % cycleWidth;
      double y = centerY;

      if (relX < 20) {
        y = centerY;
      } else if (relX < 35) {
        final t = (relX - 20) / 15;
        y = centerY - (10 * (1 - (2 * t - 1).abs()));
      } else if (relX < 50) {
        y = centerY;
      } else if (relX < 55) {
        final t = (relX - 50) / 5;
        y = centerY + (8 * t);
      } else if (relX < 65) {
        final t = (relX - 55) / 10;
        y = centerY + 8 - (88 * t);
      } else if (relX < 75) {
        final t = (relX - 65) / 10;
        y = (centerY - 80) + (88 * t);
      } else if (relX < 80) {
        final t = (relX - 75) / 5;
        y = centerY + (8 * (1 - t));
      } else if (relX < 100) {
        y = centerY;
      } else if (relX < 130) {
        final t = (relX - 100) / 30;
        y = centerY - (18 * (1 - (2 * t - 1).abs()));
      }

      if (x == -cycleWidth) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final backgroundPath = Path();
    const bgCycleWidth = 280.0;
    for (double x = -bgCycleWidth; x < width + bgCycleWidth; x += 2) {
      final relX = x % bgCycleWidth;
      double y = centerY + 25;
      if (relX >= 40 && relX < 70) {
        final t = (relX - 40) / 30;
        y -= 20 * (1 - (2 * t - 1).abs());
      }
      if (x == -bgCycleWidth) {
        backgroundPath.moveTo(x, y);
      } else {
        backgroundPath.lineTo(x, y);
      }
    }
    canvas.drawPath(backgroundPath, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant _HeartBeatWavePainter oldDelegate) =>
      oldDelegate.color != color;
}
