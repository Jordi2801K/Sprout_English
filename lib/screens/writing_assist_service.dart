import 'package:dio/dio.dart';

import '../core/network/server_config.dart';

typedef PostJson =
    Future<Map<String, dynamic>> Function(
      String path,
      Map<String, dynamic> data,
    );

class WritingAssistService {
  WritingAssistService({PostJson? postJson})
    : _postJson = postJson ?? _defaultPostJson;

  static WritingAssistService? debugOverride;

  static WritingAssistService get current =>
      debugOverride ?? WritingAssistService();

  final PostJson _postJson;

  Future<GrammarCheckResult> checkGrammar(String rawText) async {
    final text = rawText.trim();
    final data = await _postJson('/writing/eval', <String, dynamic>{
      'text': text,
      'task': 'grammar_check',
      'style':
          'Correct grammar naturally while preserving the original meaning and tone.',
      'save': false,
    });

    final normalizedText = (data['normalized_text'] ?? text).toString();
    final correctedTextFromServer = (data['corrected_text'] ?? '')
        .toString()
        .trim();
    final edits = _withoutOverlaps(
      (data['edits'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_LlmEdit.fromJson)
          .where((edit) => edit.isValidFor(normalizedText))
          .toList(),
    );
    final correctedText = correctedTextFromServer.isNotEmpty
        ? correctedTextFromServer
        : _applyEdits(normalizedText, edits);
    final issues = edits
        .where((edit) => edit.reason.trim().isNotEmpty)
        .map((edit) => edit.toIssue(normalizedText))
        .toList();

    return GrammarCheckResult(correctedText: correctedText, issues: issues);
  }

  Future<ToneConversionResult> convertTone(
    String rawText,
    ToneStyle style,
  ) async {
    final data = await _postJson('/paraphrase', <String, dynamic>{
      'text': rawText.trim(),
      'tone': style.apiValue,
      'length': style == ToneStyle.concise ? 'shorter' : 'same',
      'n': 1,
    });

    final meta = data['meta'];
    if (meta is Map && meta['llm'] != 'on') {
      throw StateError('LLM paraphrase is not enabled on the server.');
    }

    final candidates = data['candidates'] as List<dynamic>? ?? <dynamic>[];
    final first = candidates.whereType<Map<String, dynamic>>().firstOrNull;
    final text = (first?['text'] ?? '').toString().trim();
    if (text.isEmpty) {
      throw StateError('LLM returned an empty tone conversion.');
    }
    return ToneConversionResult(text: text);
  }

  static String _applyEdits(String text, List<_LlmEdit> edits) {
    var result = text;
    final applicable = edits.where((edit) => edit.kind != 'comment').toList()
      ..sort((a, b) => b.start.compareTo(a.start));
    for (final edit in applicable) {
      final replacement = edit.kind == 'delete' ? '' : (edit.replacement ?? '');
      final adjustedEnd = _extendEndForReplacementOverlap(
        result,
        edit.end,
        replacement,
      );
      result = result.replaceRange(edit.start, adjustedEnd, replacement);
    }
    return result.trim().isEmpty ? text : result;
  }

  static List<_LlmEdit> _withoutOverlaps(List<_LlmEdit> edits) {
    final sorted = edits.toList()..sort((a, b) => a.start.compareTo(b.start));
    final accepted = <_LlmEdit>[];
    var lastEnd = -1;
    for (final edit in sorted) {
      if (edit.start < lastEnd) {
        continue;
      }
      accepted.add(edit);
      lastEnd = edit.end;
    }
    return accepted;
  }

  static int _extendEndForReplacementOverlap(
    String text,
    int end,
    String replacement,
  ) {
    final after = text.substring(end);
    final max = replacement.length < after.length
        ? replacement.length
        : after.length;
    for (var length = max; length > 0; length -= 1) {
      if (replacement.endsWith(after.substring(0, length))) {
        return end + length;
      }
    }
    return end;
  }
}

Future<Map<String, dynamic>> _defaultPostJson(
  String path,
  Map<String, dynamic> data,
) async {
  final dio = Dio(
    BaseOptions(
      baseUrl: serverBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 45),
    ),
  );
  final response = await dio.post<Map<String, dynamic>>(path, data: data);
  return response.data ?? <String, dynamic>{};
}

class _LlmEdit {
  const _LlmEdit({
    required this.kind,
    required this.start,
    required this.end,
    required this.replacement,
    required this.reason,
  });

  final String kind;
  final int start;
  final int end;
  final String? replacement;
  final String reason;

  factory _LlmEdit.fromJson(Map<String, dynamic> json) {
    return _LlmEdit(
      kind: (json['kind'] ?? 'comment').toString(),
      start: (json['start'] as num?)?.toInt() ?? 0,
      end: (json['end'] as num?)?.toInt() ?? 0,
      replacement: json['replacement']?.toString(),
      reason: (json['reason'] ?? '').toString(),
    );
  }

  bool isValidFor(String text) {
    return start >= 0 && end >= start && end <= text.length;
  }

  GrammarIssue toIssue(String text) {
    return GrammarIssue(
      original: text.substring(start, end),
      corrected: replacement ?? '',
      explanation: reason,
    );
  }
}

class GrammarCheckResult {
  const GrammarCheckResult({required this.correctedText, required this.issues});

  final String correctedText;
  final List<GrammarIssue> issues;
}

class GrammarIssue {
  const GrammarIssue({
    required this.original,
    required this.corrected,
    required this.explanation,
  });

  final String original;
  final String corrected;
  final String explanation;
}

class ToneConversionResult {
  const ToneConversionResult({required this.text});

  final String text;
}

enum ToneStyle {
  formal('formal'),
  polite('polite'),
  friendly('friendly'),
  concise('concise');

  const ToneStyle(this.apiValue);

  final String apiValue;
}
