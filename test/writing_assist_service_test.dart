import 'package:english_ai/screens/writing_assist_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LLM grammar check', () {
    test('applies edits returned by the LLM endpoint', () async {
      final service = WritingAssistService(
        postJson: (path, data) async {
          expect(path, '/writing/eval');
          expect(data['text'], 'I am goes to school.');
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
                'category': 'grammar',
                'severity': 'major',
              },
            ],
          };
        },
      );

      final result = await service.checkGrammar('I am goes to school.');

      expect(result.correctedText, 'I go to school.');
      expect(result.issues.single.original, 'am goes');
      expect(result.issues.single.corrected, 'go');
    });

    test('prefers corrected_text and avoids duplicated edit output', () async {
      final service = WritingAssistService(
        postJson: (path, data) async {
          return <String, dynamic>{
            'normalized_text': 'He is going to school.',
            'corrected_text': 'He is going to school.',
            'edits': <Map<String, dynamic>>[
              <String, dynamic>{
                'kind': 'replace',
                'start': 3,
                'end': 7,
                'replacement': 'is going',
                'reason': 'Subject-verb agreement.',
              },
            ],
          };
        },
      );

      final result = await service.checkGrammar('He are go to school.');

      expect(result.correctedText, 'He is going to school.');
      expect(result.correctedText, isNot(contains('goingoing')));
    });

    test('does not use local rules when LLM returns no edits', () async {
      final service = WritingAssistService(
        postJson: (path, data) async {
          return <String, dynamic>{
            'normalized_text': 'He goes to school yesterday',
            'edits': <dynamic>[],
          };
        },
      );

      final result = await service.checkGrammar('He goes to school yesterday');

      expect(result.correctedText, 'He goes to school yesterday');
      expect(result.issues, isEmpty);
    });
  });

  group('LLM tone conversion', () {
    test('uses the LLM paraphrase candidate', () async {
      final service = WritingAssistService(
        postJson: (path, data) async {
          expect(path, '/paraphrase');
          expect(data['tone'], 'polite');
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

      final result = await service.convertTone(
        'Send me the file',
        ToneStyle.polite,
      );

      expect(result.text, 'Could you please send me the file?');
    });

    test('rejects mock paraphrase responses', () async {
      final service = WritingAssistService(
        postJson: (path, data) async {
          return <String, dynamic>{
            'candidates': <Map<String, dynamic>>[
              <String, dynamic>{'text': 'Please send me the file.'},
            ],
            'meta': <String, dynamic>{'llm': 'mock'},
          };
        },
      );

      expect(
        service.convertTone('Send me the file', ToneStyle.polite),
        throwsStateError,
      );
    });
  });
}
