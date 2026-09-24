/// What the "Try asking:" cards on the Ask Allo welcome view offer.
///
/// AlloBaby's AlloBot screen fills that strip with pregnancy tips. Here the
/// same strip opens the app's own helpers instead — My Health, the kick
/// counter, AlloCry — so the cards are the Agents tab's catalogue rather than a
/// second list that would drift away from it. My Health is the one entry with
/// no agent of its own: it is the page the health agents live inside, so it is
/// added here and nowhere else.
library;

import 'package:flutter/material.dart';

import 'package:allomom/features/allobot/data/agent_catalog.dart';
import 'package:allomom/features/my_health/my_health_page.dart';

/// The chips above the cards. Short labels, because they sit in one row.
enum FeatureCategory {
  all('All', '✨'),
  care('Care', '🤱'),
  vitals('Vitals', '📈'),
  readings('Readings', '🩺'),
  nutrition('Nutrition', '🥗');

  const FeatureCategory(this.label, this.emoji);

  final String label;
  final String emoji;

  String get chipLabel => '$emoji $label';

  /// Where an agent's group lands on the chip row.
  static FeatureCategory of(AgentGroup group) => switch (group) {
    AgentGroup.care => FeatureCategory.care,
    AgentGroup.vitals => FeatureCategory.vitals,
    AgentGroup.readings => FeatureCategory.readings,
    AgentGroup.nutrition => FeatureCategory.nutrition,
  };
}

/// One card: how it looks and where it opens.
class AlloBotFeature {
  const AlloBotFeature({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.color,
    required this.pageBuilder,
    this.image,
  });

  final String id;
  final String title;
  final String subtitle;
  final FeatureCategory category;

  /// Shown when there is no [image] for this feature.
  final IconData icon;

  /// Tints the card — its wash, its icon and its illustration's halo.
  final Color color;

  /// The 3D illustration a few of the headline features have.
  final String? image;

  final WidgetBuilder pageBuilder;
}

abstract final class AlloBotFeatureCatalog {
  /// The illustrations that exist. Everything else falls back to its icon.
  static const Map<String, String> _illustrations = {
    'my_health': 'assets/allobaby/MyHealth.png',
    'kick_counter': 'assets/allobaby/KickCounter.png',
    'allocry': 'assets/allobaby/AlloCry.png',
    'feeding_tracker': 'assets/allobaby/FeedingTracker.png',
    'daily_activity': 'assets/allobaby/daily_activity.png',
  };

  /// My Health first — it is the one she is sent to most — then every agent in
  /// catalogue order.
  static List<AlloBotFeature> get all => [
    const AlloBotFeature(
      id: 'my_health',
      title: 'My Health',
      subtitle: 'Every reading in one place',
      category: FeatureCategory.care,
      icon: Icons.favorite_rounded,
      color: Color(0xFFFF4E6A),
      image: 'assets/allobaby/MyHealth.png',
      pageBuilder: _myHealth,
    ),
    for (final agent in AgentCatalog.all) _fromAgent(agent),
  ];

  /// The cards in [category], with [FeatureCategory.all] meaning all of them.
  static List<AlloBotFeature> inCategory(FeatureCategory category) =>
      category == FeatureCategory.all
      ? all
      : all.where((f) => f.category == category).toList();

  static AlloBotFeature _fromAgent(AgentSpec agent) => AlloBotFeature(
    id: agent.id,
    title: agent.name,
    subtitle: agent.description,
    category: FeatureCategory.of(agent.group),
    icon: agent.icon,
    color: agent.iconColor,
    image: _illustrations[agent.id],
    pageBuilder: agent.pageBuilder,
  );

  static Widget _myHealth(BuildContext _) => const MyHealthPage();

  /// Opens a card's page.
  static Future<void> open(BuildContext context, AlloBotFeature feature) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: feature.pageBuilder));
  }
}
