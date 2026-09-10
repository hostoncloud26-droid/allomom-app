import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/features/home/widgets/allo_voice_prompt_card.dart';
import 'package:allomom/services/allobot/home_voice_flow.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  group('AlloVoicePromptCard', () {
    testWidgets('shows the message with no question pending', (tester) async {
      await tester.pumpWidget(
        wrap(const AlloVoicePromptCard(message: 'That is good to hear.')),
      );

      expect(find.text('That is good to hear.'), findsOneWidget);
      expect(find.text('Yes'), findsNothing);
      expect(find.text('No'), findsNothing);
    });

    testWidgets('lays Yes and No side by side, not stacked', (tester) async {
      await tester.pumpWidget(
        wrap(
          AlloVoicePromptCard(
            message: 'Breakfast time.',
            prompt: const HomePrompt(
              kind: HomePromptKind.breakfast,
              question: 'Have you had your breakfast?',
              answerKind: HomeAnswerKind.yesNo,
            ),
            onYes: () {},
            onNo: () {},
          ),
        ),
      );

      final yes = tester.getCenter(find.text('Yes'));
      final no = tester.getCenter(find.text('No'));
      expect(no.dx, greaterThan(yes.dx), reason: 'No should sit beside Yes');
      expect(no.dy, closeTo(yes.dy, 1), reason: 'and on the same line');
    });

    testWidgets('reports which button was tapped', (tester) async {
      var answer = '';
      await tester.pumpWidget(
        wrap(
          AlloVoicePromptCard(
            message: 'Breakfast time.',
            prompt: const HomePrompt(
              kind: HomePromptKind.breakfast,
              question: 'Have you had your breakfast?',
              answerKind: HomeAnswerKind.yesNo,
            ),
            onYes: () => answer = 'yes',
            onNo: () => answer = 'no',
          ),
        ),
      );

      await tester.tap(find.text('Yes'));
      expect(answer, 'yes');
      await tester.tap(find.text('No'));
      expect(answer, 'no');
    });

    testWidgets('offers a date picker for the next ANC date', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        wrap(
          AlloVoicePromptCard(
            message: 'Well done for going.',
            prompt: const HomePrompt(
              kind: HomePromptKind.ancNextDate,
              question: 'When is your next ANC check-up?',
              answerKind: HomeAnswerKind.date,
            ),
            onPickDate: (date) => picked = date,
            onNo: () {},
          ),
        ),
      );

      expect(find.text('Pick the date'), findsOneWidget);
      expect(find.text("Don't know yet"), findsOneWidget);

      await tester.tap(find.text('Pick the date'));
      await tester.pumpAndSettle();
      // The picker opens on a real calendar; confirming returns a date.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(picked, isNotNull);
    });

    testWidgets('takes free text for what the doctor said', (tester) async {
      String? saved;
      await tester.pumpWidget(
        wrap(
          AlloVoicePromptCard(
            message: 'Next.',
            prompt: const HomePrompt(
              kind: HomePromptKind.ancSummary,
              question: 'What did the doctor say today?',
              answerKind: HomeAnswerKind.text,
              submitLabel: 'Save to this visit',
            ),
            onSubmitText: (text) => saved = text,
            onNo: () {},
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'BP normal, continue iron');
      await tester.tap(find.text('Save to this visit'));
      expect(saved, 'BP normal, continue iron');
    });

    testWidgets('an empty note skips rather than saving a blank', (tester) async {
      var skipped = false;
      String? saved;
      await tester.pumpWidget(
        wrap(
          AlloVoicePromptCard(
            message: 'Next.',
            prompt: const HomePrompt(
              kind: HomePromptKind.ancSummary,
              question: 'What did the doctor say today?',
              answerKind: HomeAnswerKind.text,
              submitLabel: 'Save to this visit',
            ),
            onSubmitText: (text) => saved = text,
            onNo: () => skipped = true,
          ),
        ),
      );

      await tester.tap(find.text('Save to this visit'));
      expect(saved, isNull);
      expect(skipped, isTrue);
    });

    testWidgets('takes free text for what she ate', (tester) async {
      String? saved;
      await tester.pumpWidget(
        wrap(
          AlloVoicePromptCard(
            message: 'Good, I have logged your lunch.',
            prompt: mealDetailPrompt('lunch'),
            onSubmitText: (text) => saved = text,
            onNo: () {},
          ),
        ),
      );

      expect(find.text('What did you have for lunch?'), findsOneWidget);
      // The meal turn gets its own field hint and button, not the ANC one.
      expect(find.text('Save to this visit'), findsNothing);

      await tester.enterText(find.byType(TextField), 'rice, dal and spinach');
      await tester.tap(find.text('Save'));
      expect(saved, 'rice, dal and spinach');
    });

    testWidgets('the speaker and close controls fire', (tester) async {
      var spoke = false;
      var dismissed = false;
      await tester.pumpWidget(
        wrap(
          AlloVoicePromptCard(
            message: 'Hi mommy.',
            onSpeakerTap: () => spoke = true,
            onDismiss: () => dismissed = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      expect(spoke, isTrue);
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(dismissed, isTrue);
    });

    testWidgets('shows a speaking indicator while talking', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AlloVoicePromptCard(
            message: 'Hi mommy.',
            isSpeaking: true,
            onSpeakerTap: null,
          ),
        ),
      );
      expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
    });

    testWidgets('fits the carousel page height when scrolled', (tester) async {
      // Every carousel page gets the same fixed 345px, and the ANC notes turn
      // is the tallest thing this card renders.
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 345,
              child: SingleChildScrollView(
                child: AlloVoicePromptCard(
                  message: 'Well done for going, mommy. A few things and I '
                      'will have this visit on the record.',
                  prompt: const HomePrompt(
                    kind: HomePromptKind.ancSummary,
                    question: 'What did the doctor say today?',
                    answerKind: HomeAnswerKind.text,
                    submitLabel: 'Save to this visit',
                  ),
                  onSubmitText: (_) {},
                  onNo: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('sized like the Daily Summary card', () {
    /// The carousel gives every page the same fixed height.
    const carouselHeight = 345.0;

    Widget page(Widget child) => MaterialApp(
          home: Scaffold(
            body: SizedBox(height: carouselHeight, child: child),
          ),
        );

    testWidgets('fills the page height instead of shrinking to its content',
        (tester) async {
      await tester.pumpWidget(
        page(
          AlloVoicePromptCard(
            fillHeight: true,
            message: 'Hi mommy. You are at week 13 of your pregnancy.',
            prompt: const HomePrompt(
              kind: HomePromptKind.lunch,
              question: 'Have you had your lunch?',
              answerKind: HomeAnswerKind.yesNo,
            ),
            onYes: () {},
            onNo: () {},
          ),
        ),
      );

      // The card's own box, not the padding around it.
      final card = tester.getSize(find.byType(Container).first);
      expect(card.height, closeTo(carouselHeight, 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shrinks to its content when not filling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AlloVoicePromptCard(
                message: 'Short.',
                prompt: const HomePrompt(
                  kind: HomePromptKind.lunch,
                  question: 'Have you had your lunch?',
                  answerKind: HomeAnswerKind.yesNo,
                ),
                onYes: () {},
                onNo: () {},
              ),
            ),
          ),
        ),
      );

      final card = tester.getSize(find.byType(Container).first);
      expect(card.height, lessThan(carouselHeight));
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the answer buttons on the card however long the message',
        (tester) async {
      // A long reply must scroll the message, not push Yes and No off the
      // bottom of a height-bound card.
      await tester.pumpWidget(
        page(
          AlloVoicePromptCard(
            fillHeight: true,
            message: 'Mommy, you need to drink more water. ' * 12,
            prompt: const HomePrompt(
              kind: HomePromptKind.water,
              question: 'Have you had any water yet today?',
              answerKind: HomeAnswerKind.yesNo,
            ),
            onYes: () {},
            onNo: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final yes = tester.getRect(find.text('Yes'));
      expect(yes.bottom, lessThanOrEqualTo(carouselHeight));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('fits the tallest turn — the ANC notes field', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        page(
          AlloVoicePromptCard(
            fillHeight: true,
            message: 'Well done for going, mommy. A few things and I will '
                'have this visit on the record.',
            prompt: const HomePrompt(
              kind: HomePromptKind.ancSummary,
              question: 'What did the doctor say today?',
              answerKind: HomeAnswerKind.text,
              submitLabel: 'Save to this visit',
            ),
            onSubmitText: (_) {},
            onNo: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Save to this visit'), findsOneWidget);
    });
  });
}
