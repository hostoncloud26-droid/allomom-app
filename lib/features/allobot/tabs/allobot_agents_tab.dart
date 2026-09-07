import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlloBotAgentsTab extends StatefulWidget {
  final VoidCallback onAskTap;

  const AlloBotAgentsTab({super.key, required this.onAskTap});

  @override
  State<AlloBotAgentsTab> createState() => _AlloBotAgentsTabState();
}

class _AlloBotAgentsTabState extends State<AlloBotAgentsTab> {
  String _searchQuery = '';

  final List<Map<String, dynamic>> _agents = [
    {
      'name': 'AlloCry',
      'desc': 'Listens for baby crying',
      'icon': Icons.volume_up_rounded,
      'iconColor': const Color(0xFFD97706),
      'iconBg': const Color(0xFFFEF3C7),
      'status': 'Listening',
      'statusColor': const Color(0xFF2563EB),
      'statusBg': const Color(0xFFDBEAFE),
    },
    {
      'name': 'Kick counter',
      'desc': 'Counts kicks with you',
      'icon': Icons.directions_walk_rounded,
      'iconColor': const Color(0xFFFF4E6A),
      'iconBg': const Color(0xFFFFE4E9),
      'status': 'Active',
      'statusColor': const Color(0xFF059669),
      'statusBg': const Color(0xFFD1FAE5),
    },
    {
      'name': 'Feeding tracker',
      'desc': 'Logs every feed',
      'icon': Icons.restaurant_rounded,
      'iconColor': const Color(0xFF9333EA),
      'iconBg': const Color(0xFFF3E8FF),
      'status': 'Idle',
      'statusColor': const Color(0xFF64748B),
      'statusBg': const Color(0xFFF1F5F9),
    },
    {
      'name': 'Daily activity',
      'desc': "Today's five things",
      'icon': Icons.access_time_rounded,
      'iconColor': const Color(0xFF0891B2),
      'iconBg': const Color(0xFFCFFAFE),
      'status': 'Active',
      'statusColor': const Color(0xFF059669),
      'statusBg': const Color(0xFFD1FAE5),
    },
    {
      'name': 'Water',
      'desc': 'Nudges you to drink',
      'icon': Icons.water_drop_rounded,
      'iconColor': const Color(0xFF0284C7),
      'iconBg': const Color(0xFFE0F2FE),
      'status': 'Active',
      'statusColor': const Color(0xFF059669),
      'statusBg': const Color(0xFFD1FAE5),
    },
    {
      'name': 'Weight',
      'desc': 'Watches your gain',
      'icon': Icons.show_chart_rounded,
      'iconColor': const Color(0xFFDB2777),
      'iconBg': const Color(0xFFFCE7F3),
      'status': 'Idle',
      'statusColor': const Color(0xFF64748B),
      'statusBg': const Color(0xFFF1F5F9),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredAgents = _agents.where((agent) {
      final name = (agent['name'] as String).toLowerCase();
      final desc = (agent['desc'] as String).toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || desc.contains(q);
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // ─── HEADER ───
          Text(
            'Agents',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E2024),
            ),
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
          Container(
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
          ),
          const SizedBox(height: 18),

          // ─── 2-COLUMN AGENTS GRID ───
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredAgents.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final agent = filteredAgents[index];
              return _buildAgentCard(agent);
            },
          ),
          const SizedBox(height: 100), // Bottom space for bar
        ],
      ),
    );
  }

  Widget _buildAgentCard(Map<String, dynamic> agent) {
    final status = agent['status'] as String;
    final statusColor = agent['statusColor'] as Color;

    return Container(
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
                  color: agent['iconBg'] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  agent['icon'] as IconData,
                  color: agent['iconColor'] as Color,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: agent['statusBg'] as Color,
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
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
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
            agent['name'] as String,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E2024),
            ),
          ),
          const SizedBox(height: 2),

          // Description
          Text(
            agent['desc'] as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF8E95A5),
            ),
          ),
        ],
      ),
    );
  }
}
