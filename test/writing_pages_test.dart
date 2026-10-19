import 'package:english_ai/core/settings/app_settings_store.dart';
import 'package:english_ai/core/statistics/learning_activity_store.dart';
import 'package:english_ai/feature/writing/toeic_writing_page.dart';
import 'package:english_ai/feature/writing/writing_hub_page.dart';
import 'package:english_ai/screens/grammar_check_screen.dart';
import 'package:english_ai/screens/tone_conversion_screen.dart';
import 'package:english_ai/screens/writing_assist_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _useLargeSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1200, 2200);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  setUp(() async {
    WritingAssistService.debugOverride = null;
    AppSettingsStore.instance.debugResetCache();
    await AppSettingsStore.instance.reset();
    LearningActivityStore.instance.debugResetCache();
    await LearningActivityStore.instance.reset();
  });

  tearDown(() {
    WritingAssistService.debugOverride = null;
  });

  testWidgets('writing hub shows three main tracks', (tester) async {
    _useLargeSurface(tester);

    await tester.pumpWidget(const MaterialApp(home: WritingHubPage()));
    await tester.pumpAndSettle();

    expect(find.text('Writing Hub'), findsOneWidget);
    expect(find.text('AI 문법 검사'), findsOneWidget);
    expect(find.text('문장 톤 변환'), findsOneWidget);
    expect(find.textContaining('TOEIC Writing'), findsWidgets);
  });

  testWidgets('toeic writing setup renders practice options', (tester) async {
    _useLargeSurface(tester);

    await tester.pumpWidget(const MaterialApp(home: ToeicWritingPage()));
    await tester.pumpAndSettle();

    expect(find.text('실전 유형 선택'), findsOneWidget);
    expect(find.text('사진 묘사'), findsOneWidget);
    expect(find.text('이메일 응답'), findsOneWidget);
    expect(find.text('의견 에세이'), findsOneWidget);
    expect(
      find.textContaining('TOEIC Writing에서 자주 나오는 3가지 유형'),
      findsOneWidget,
    );
  });

  testWidgets('writing hub TOEIC card navigates with Navigator push', (
    tester,
  ) async {
    _useLargeSurface(tester);

    await tester.pumpWidget(const MaterialApp(home: WritingHubPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('TOEIC Writing 연습'));
    await tester.pumpAndSettle();
    expect(find.text('실전 유형 선택'), findsOneWidget);
  });

  testWidgets('writing hub grammar card navigates with Navigator push', (
    tester,
  ) async {
    _useLargeSurface(tester);

    await tester.pumpWidget(const MaterialApp(home: WritingHubPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI 문법 검사'));
    await tester.pumpAndSettle();
    expect(find.text('영어 문장을 입력하세요'), findsOneWidget);
  });

  testWidgets('writing hub tone card navigates with Navigator push', (
    tester,
  ) async {
    _useLargeSurface(tester);

    await tester.pumpWidget(const MaterialApp(home: WritingHubPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('문장 톤 변환'));
    await tester.pumpAndSettle();
    expect(find.text('Original Sentence'), findsOneWidget);
  });

  testWidgets('grammar check uses typed sentence result', (tester) async {
    _useLargeSurface(tester);
    WritingAssistService.debugOverride = WritingAssistService(
      postJson: (path, data) async {
        return <String, dynamic>{
          'normalized_text': 'I am goes to school.',
          'corrected_text': 'I go to school.',
          'edits': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'replace',
              'start': 2,
              'end': 9,
              'replacement': 'go',
              'reason': 'Use the base verb after the subject.',
            },
          ],
        };
      },
    );

    await tester.pumpWidget(const MaterialApp(home: GrammarCheckScreen()));
    await tester.enterText(find.byType(TextField), 'I am goes to school.');
    await tester.tap(find.text('검사하기'));
    await tester.pumpAndSettle();

    expect(find.text('I go to school.'), findsOneWidget);
    expect(find.text('틀린 부분'), findsOneWidget);
    expect(find.text('수정'), findsOneWidget);
    expect(find.text('am goes'), findsOneWidget);
    expect(find.text('go'), findsOneWidget);
    expect(find.text('He went to school yesterday.'), findsNothing);
  });

  testWidgets('grammar check fixes past marker with goes', (tester) async {
    _useLargeSurface(tester);
    WritingAssistService.debugOverride = WritingAssistService(
      postJson: (path, data) async {
        return <String, dynamic>{
          'normalized_text': 'He goes to school yesterday.',
          'corrected_text': 'He went to school yesterday.',
          'edits': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'replace',
              'start': 3,
              'end': 7,
              'replacement': 'went',
              'reason': 'Use past tense with yesterday.',
            },
          ],
        };
      },
    );

    await tester.pumpWidget(const MaterialApp(home: GrammarCheckScreen()));
    await tester.enterText(
      find.byType(TextField),
      'He goes to school yesterday',
    );
    await tester.tap(find.text('검사하기'));
    await tester.pumpAndSettle();

    expect(find.text('He went to school yesterday.'), findsOneWidget);
    expect(find.text('He goes to school yesterday.'), findsNothing);
  });

  testWidgets('tone conversion uses typed sentence and selected tone', (
    tester,
  ) async {
    _useLargeSurface(tester);
    WritingAssistService.debugOverride = WritingAssistService(
      postJson: (path, data) async {
        return <String, dynamic>{
          'candidates': <Map<String, dynamic>>[
            <String, dynamic>{
              'text': 'Could you please send me the file?',
              'tone': 'polite',
            },
          ],
          'meta': <String, dynamic>{'llm': 'on'},
        };
      },
    );

    await tester.pumpWidget(const MaterialApp(home: ToneConversionScreen()));
    await tester.enterText(find.byType(TextField), 'Send me the file');
    await tester.tap(find.text('Polite'));
    await tester.tap(find.text('AI로 변환하기'));
    await tester.pumpAndSettle();

    expect(find.text('Could you please send me the file?'), findsOneWidget);
    expect(find.textContaining('Please note that'), findsNothing);
  });
}
