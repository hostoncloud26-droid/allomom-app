import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// How the sign-in code is delivered. The values are what `/auth/send-otp`
/// takes as `channel`.
abstract final class OtpChannel {
  static const whatsapp = 'whatsapp';
  static const sms = 'sms';

  static String label(String channel) =>
      channel == whatsapp ? 'WhatsApp' : 'SMS';
}

/// The sign-in step that asks whether to send the code over WhatsApp or SMS,
/// the same choice AlloKonnect offers. Tapping an option sends the code; the
/// tapped one shows a spinner while [sendingChannel] is set.
class OtpChannelStepView extends StatelessWidget {
  const OtpChannelStepView({
    super.key,
    required this.phoneLabel,
    required this.onChannelSelected,
    this.sendingChannel,
  });

  final String phoneLabel;
  final ValueChanged<String> onChannelSelected;

  /// The channel a send is in flight on, or null when idle.
  final String? sendingChannel;

  @override
  Widget build(BuildContext context) {
    final busy = sendingChannel != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Color(0xFFFF5277),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How should we send your code?',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Send OTP to $phoneLabel',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ChannelOption(
          title: 'WhatsApp',
          subtitle: 'Instant code via WhatsApp message',
          badge: 'Recommended',
          icon: Icons.chat_rounded,
          gradient: const [Color(0xFF25D366), Color(0xFF128C7E)],
          loading: sendingChannel == OtpChannel.whatsapp,
          onTap: busy ? null : () => onChannelSelected(OtpChannel.whatsapp),
        ),
        const SizedBox(height: 12),
        _ChannelOption(
          title: 'SMS',
          subtitle: 'Receive OTP via standard SMS',
          icon: Icons.sms_rounded,
          gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          loading: sendingChannel == OtpChannel.sms,
          onTap: busy ? null : () => onChannelSelected(OtpChannel.sms),
        ),
      ],
    );
  }
}

class _ChannelOption extends StatelessWidget {
  const _ChannelOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.badge,
    this.loading = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onTap;
  final String? badge;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E2024),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: gradient.first.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                color: gradient.last,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: gradient.last,
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
