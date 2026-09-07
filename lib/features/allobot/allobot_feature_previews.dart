/// What each app feature AlloBot can open is actually for.
///
/// When the voice assistant matches a request to a feature it offers an
/// `Open <Feature>` button. On its own that button asks the mother to trust a
/// screen she has never seen — so this supplies the preview shown beside it:
/// the icon, a plain description, and the few things she can actually do there.
///
/// Keyed by the same `featureType` strings the assistant already routes on, so
/// adding a feature means adding one entry here and one case in the tab's
/// navigation switch.
library;

import 'package:flutter/material.dart';

/// The preview for one openable feature.
class AlloBotFeaturePreview {
  const AlloBotFeaturePreview({
    required this.name,
    required this.description,
    required this.uses,
    required this.icon,
  });

  final String name;

  /// One line on what the screen is.
  final String description;

  /// What she can do there. Three or four short lines — this is a preview, not
  /// a manual, and it has to fit above the button without scrolling.
  final List<String> uses;

  final IconData icon;
}

/// Previews for every feature the voice assistant can open.
const Map<String, AlloBotFeaturePreview> alloBotFeaturePreviews = {
  'kick': AlloBotFeaturePreview(
    name: 'Kick Counter',
    description: "Count and track your baby's movements",
    uses: [
      'Tap each time you feel a movement',
      'Counts towards 10 kicks in two hours',
      'Keeps a history you can show your doctor',
    ],
    icon: Icons.directions_walk_rounded,
  ),
  'cry': AlloBotFeaturePreview(
    name: 'AlloCry',
    description: 'Work out why your baby is crying',
    uses: [
      'Record a few seconds of crying',
      'Suggests hunger, discomfort, tiredness or pain',
      'Saves each reading so you can spot a pattern',
    ],
    icon: Icons.graphic_eq_rounded,
  ),
  'report': AlloBotFeaturePreview(
    name: 'Medical Reports',
    description: 'All your lab tests and scans in one place',
    uses: [
      'See which tests are done and which are pending',
      'Photograph or attach a report from the lab',
      'Carry the whole file to your next visit',
    ],
    icon: Icons.description_rounded,
  ),
  'health': AlloBotFeaturePreview(
    name: 'My Health Vitals',
    description: 'Your blood pressure, weight, sleep and heart rate',
    uses: [
      'Log a reading in a few taps',
      'See the trend across weeks, not just today',
      'Flags anything outside the usual range',
    ],
    icon: Icons.favorite_rounded,
  ),
  'prescription': AlloBotFeaturePreview(
    name: 'Prescriptions',
    description: 'Your medicines and when to take them',
    uses: [
      'Every tablet with its dose and timing',
      'Tick a dose off as you take it',
      'Reminders so a dose is not missed',
    ],
    icon: Icons.medication_rounded,
  ),
  'anc': AlloBotFeaturePreview(
    name: 'ANC Schedule',
    description: 'Your antenatal check-up plan',
    uses: [
      'Every visit with its date',
      'What is checked at each one',
      'Marks a visit done once you have been',
    ],
    icon: Icons.event_available_rounded,
  ),
  'vaccine': AlloBotFeaturePreview(
    name: 'Vaccination Schedule',
    description: 'The doses due through your pregnancy',
    uses: [
      'TT, Tdap and flu doses with their dates',
      'Why each dose matters',
      'Shows anything past due',
    ],
    icon: Icons.vaccines_rounded,
  ),
  'journey': AlloBotFeaturePreview(
    name: 'Pregnancy Journey',
    description: 'Your week-by-week story so far',
    uses: [
      'What is happening this week',
      'How your baby is growing',
      'Milestones already behind you',
    ],
    icon: Icons.timeline_rounded,
  ),
  'family': AlloBotFeaturePreview(
    name: 'Family & Contacts',
    description: 'The people supporting you',
    uses: [
      'Invite your partner or family to your care',
      'Choose what each of them can see',
      'Keep emergency contacts to hand',
    ],
    icon: Icons.people_alt_rounded,
  ),
  'settings': AlloBotFeaturePreview(
    name: 'Settings',
    description: 'Your profile, language and reminders',
    uses: [
      'Change the language AlloBot speaks',
      'Edit your profile and dates',
      'Turn reminders on or off',
    ],
    icon: Icons.settings_rounded,
  ),
  'feed': AlloBotFeaturePreview(
    name: 'Feeding Tracker',
    description: 'Breastfeeds and bottle feeds',
    uses: [
      'Log each feed with its side and length',
      'See how long since the last one',
      'Daily totals to show your paediatrician',
    ],
    icon: Icons.local_drink_rounded,
  ),
};

/// The preview for [featureType], or null when there is none.
///
/// Falls back to null rather than a placeholder: a preview that says nothing
/// is worse than no preview, and the button still works without one.
AlloBotFeaturePreview? featurePreviewFor(String featureType) =>
    alloBotFeaturePreviews[featureType];
