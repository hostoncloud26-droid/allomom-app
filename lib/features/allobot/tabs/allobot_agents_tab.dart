import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/allobot/data/agent_catalog.dart';

class AlloBotAgentsTab extends StatefulWidget {
  final VoidCallback onAskTap;

  const AlloBotAgentsTab({super.key, required this.onAskTap});

  @override
  State<AlloBotAgentsTab> createState() => _AlloBotAgentsTabState();
}

class _AlloBotAgentsTabState extends State<AlloBotAgentsTab> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // The status pills read from what has actually been recorded, so the tab
    // asks for the readings once when it opens rather than showing every agent
    // idle until she visits My Health.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HealthVitalsController.instance.fetchLatestVitals(showLoading: false);
    });
  }

  Future<void> _openAgent(AgentSpec agent) async {
    await AgentCatalog.open(context, agent);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HealthVitalsController.instance,
      builder: (context, _) {
        final groups = <AgentGroup, List<AgentSpec>>{};
        for (final group in AgentGroup.values) {
          final matches = AgentCatalog.inGroup(
            group,
          ).where((a) => a.matches(_searchQuery)).toList();
          if (matches.isNotEmpty) groups[group] = matches;
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ─── HEADER ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Agents',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                  ),
                  _buildAskPill(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Every feature is its own helper. Tap one, or ask AlloBot to open it.',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 18),

              // ─── SEARCH INPUT ───
              _buildSearchField(),
              const SizedBox(height: 18),

              // ─── GROUPED AGENTS ───
              if (groups.isEmpty)
                _buildNoResults()
              else
                for (final entry in groups.entries) ...[
                  _buildGroupHeader(entry.key, entry.value.length),
                  const SizedBox(height: 12),
                  _buildAgentGrid(entry.value),
                  const SizedBox(height: 22),
                ],

              const SizedBox(height: 90), // Bottom space for bar
            ],
          ),
        );
      },
    );
  }

  Widget _buildAskPill() {
    return GestureDetector(
      onTap: widget.onAskTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE4E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mic_rounded,
              size: 15,
              color: Color(0xFFFF4E6A),
            ),
            const SizedBox(width: 5),
            Text(
              'Ask AlloBot',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF4E6A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: const Color(0xFF1E2024),
              ),
              decoration: InputDecoration(
                hintText: 'Search specialized agents...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(AgentGroup group, int count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.title,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                group.subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgentGrid(List<AgentSpec> agents) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: agents.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) => _buildAgentCard(agents[index]),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 34,
              color: Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 10),
            Text(
              'No agent by that name',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Try "water", "sleep" or "kicks"',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentCard(AgentSpec agent) {
    final status = agent.status;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openAgent(agent),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: agent.iconBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      agent.icon,
                      color: agent.iconColor,
                      size: 20,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: status.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: status.color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status.label,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: status.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Name
              Text(
                agent.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 2),

              // Description
              Row(
                children: [
                  Expanded(
                    child: Text(
                      agent.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF8E95A5),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: Color(0xFFCBD5E1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
