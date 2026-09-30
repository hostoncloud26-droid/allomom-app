import 'package:flutter/material.dart';

import 'package:allomom/api/community_api.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:allomom/features/people/community/community_widgets.dart';
import 'package:allomom/models/community.dart';

/// One community — banner, logo, about, and Join / Leave.
///
/// Opens straight away with the [community] it was given, then refreshes it
/// from `/communities/{id}`. Pops `true` if she joined or left.
class CommunityDetailPage extends StatefulWidget {
  const CommunityDetailPage({super.key, required this.community});

  final Community community;

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  AppPalette get _p => context.palette;

  late Community _community = widget.community;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    // Opening a community is the moment for the disclaimer: what she is
    // about to read is other mothers talking, not medical advice.
    speak(NarrationKeys.pgCommunityDisclaimer);
    _refresh();
  }

  Future<void> _refresh() async {
    final res = await CommunityApi.getCommunity(_community.id);
    if (!mounted || !res.success || res.item is! Map) return;
    setState(() {
      _community = Community.fromJson(Map<String, dynamic>.from(res.item));
    });
  }

  Future<void> _join() async {
    setState(() => _busy = true);
    final ok = await joinCommunity(context, _community);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _changed = true;
        _community = _community.withMembership(joined: true);
      }
    });
  }

  Future<void> _leave() async {
    setState(() => _busy = true);
    final ok = await leaveCommunityWithConfirm(context, _community);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _changed = true;
        _community = _community.withMembership(joined: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = _community;
    final place = [c.city, c.state].whereType<String>().join(', ');
    final banner = c.bannerUrl;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: _p.scaffoldSoft,
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 170,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _p.tint(primaryColor, accentLight),
                      image: banner == null || banner.isEmpty
                          ? null
                          : DecorationImage(
                              image: NetworkImage(banner),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircleAvatar(
                        backgroundColor: _p.card.withValues(alpha: 0.9),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: _p.textPrimary),
                          onPressed: () => Navigator.pop(context, _changed),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: -40,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _p.card,
                      ),
                      child: CommunityAvatar(community: c, size: 80),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 52),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (c.isJoined) const CommunityJoinedBadge(),
                        Text(
                          '${c.memberCount} '
                          '${c.memberCount == 1 ? 'member' : 'members'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: _p.textSecondary,
                          ),
                        ),
                        if (place.isNotEmpty)
                          Text(
                            place,
                            style: TextStyle(
                              fontSize: 13,
                              color: _p.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (c.description != null && c.description!.isNotEmpty) ...[
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.description!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: _p.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                    if (c.isJoined)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _leave,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text(
                            'Leave community',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: dangerRed,
                            side: const BorderSide(color: dangerRed),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      )
                    else
                      CommunityJoinButton(
                        joined: false,
                        busy: _busy,
                        onJoin: _join,
                        expand: true,
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
