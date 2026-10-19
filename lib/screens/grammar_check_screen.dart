import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/statistics/learning_activity_recorder.dart';
import 'theme.dart';
import 'writing_assist_service.dart';

/// AI 문법 검사 화면
class GrammarCheckScreen extends StatefulWidget {
  const GrammarCheckScreen({super.key});

  @override
  State<GrammarCheckScreen> createState() => _GrammarCheckScreenState();
}

class _GrammarCheckScreenState extends State<GrammarCheckScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isChecking = false;
  bool _hasResult = false;
  DateTime? _sessionStartedAt;

  String _correctedSentence = '';
  List<GrammarError> _errors = [];
  String? _errorMessage;
  final WritingAssistService _writingAssist = WritingAssistService.current;

  @override
  void initState() {
    super.initState();
    _sessionStartedAt = DateTime.now();
    _textController.addListener(_refreshInputState);
  }

  @override
  void dispose() {
    _textController.removeListener(_refreshInputState);
    _textController.dispose();
    super.dispose();
  }

  void _refreshInputState() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkGrammar() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('문장을 입력해주세요')));
      return;
    }

    setState(() {
      _isChecking = true;
      _hasResult = false;
      _errorMessage = null;
    });

    try {
      final result = await _writingAssist.checkGrammar(_textController.text);
      final visibleErrors = result.issues
          .map(
            (issue) => GrammarError(
              original: issue.original,
              corrected: issue.corrected,
              sentence: _textController.text,
              explanation: issue.explanation,
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _hasResult = true;
        _correctedSentence = result.correctedText;
        _errors = visibleErrors;
      });
      final startedAt = _sessionStartedAt;
      if (startedAt != null) {
        LearningActivityRecorder.recordGrammarCheck(
          durationSec: DateTime.now().difference(startedAt).inSeconds,
          errorCount: _errors.length,
          suggestionCount: _errors.length,
        );
        _sessionStartedAt = DateTime.now();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _hasResult = false;
        _errorMessage =
            'LLM 문법 검사에 실패했습니다. 서버 실행 상태, OPENAI_API_KEY, LLM 설정을 확인해주세요.';
      });
    }
  }

  void _clearText() {
    setState(() {
      _textController.clear();
      _hasResult = false;
      _errorMessage = null;
    });
    _sessionStartedAt = DateTime.now();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('클립보드에 복사되었습니다')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF18232E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI 문법 검사',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // 히스토리 기능 (향후 구현)
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 입력 필드
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '영어 문장을 입력하세요',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18232E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF364657)
                          : const Color(0xFFDBE0E6),
                    ),
                  ),
                  child: Stack(
                    children: [
                      TextField(
                        controller: _textController,
                        maxLines: 6,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? AppTheme.textLight
                              : AppTheme.textDark,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(
                            left: 16,
                            right: 48,
                            top: 16,
                            bottom: 16,
                          ),
                          hintText: '예: I am goes to school.',
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppTheme.textSecondary.withValues(alpha: 0.6)
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      if (_textController.text.isNotEmpty)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: IconButton(
                            icon: Icon(
                              Icons.cancel,
                              color: isDark
                                  ? AppTheme.textSecondary
                                  : AppTheme.textSecondary,
                              size: 20,
                            ),
                            onPressed: _clearText,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 검사 버튼
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _checkGrammar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        '검사하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFFE53935)),
              ),
            ],

            // 결과 섹션
            if (_hasResult) ...[
              const SizedBox(height: 32),

              Text(
                '검사 결과',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                ),
              ),

              const SizedBox(height: 12),

              // 수정된 문장 카드
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18232E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF364657)
                        : const Color(0xFFDBE0E6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '수정된 문장',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _correctedSentence,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppTheme.textLight
                                  : AppTheme.textDark,
                              height: 1.4,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.content_copy,
                            size: 20,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () => _copyToClipboard(_correctedSentence),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_errors.isEmpty)
                _NoGrammarErrorsCard(isDark: isDark)
              else
                _GrammarErrorsCard(errors: _errors, isDark: isDark),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// 문법 오류 모델
class GrammarError {
  final String original;
  final String corrected;
  final String sentence;
  final String explanation;

  GrammarError({
    required this.original,
    required this.corrected,
    required this.sentence,
    required this.explanation,
  });
}

class _NoGrammarErrorsCard extends StatelessWidget {
  const _NoGrammarErrorsCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18232E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF364657) : const Color(0xFFDBE0E6),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '문법상 큰 문제는 발견되지 않았습니다.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.textLight : AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrammarErrorsCard extends StatelessWidget {
  const _GrammarErrorsCard({required this.errors, required this.isDark});

  final List<GrammarError> errors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18232E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF364657) : const Color(0xFFDBE0E6),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: errors.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: isDark ? const Color(0xFF364657) : const Color(0xFFDBE0E6),
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final error = errors[index];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (error.original.isNotEmpty)
                      _ChangePill(
                        label: '틀린 부분',
                        text: error.original,
                        color: const Color(0xFFFF6B6B),
                        strikeThrough: true,
                      ),
                    if (error.corrected.isNotEmpty) ...[
                      const Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: Color(0xFF8A94A6),
                      ),
                      _ChangePill(
                        label: '수정',
                        text: error.corrected,
                        color: const Color(0xFF2EAD4B),
                        strikeThrough: false,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.backgroundDark
                        : AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.school, size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error.explanation,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChangePill extends StatelessWidget {
  const _ChangePill({
    required this.label,
    required this.text,
    required this.color,
    required this.strikeThrough,
  });

  final String label;
  final String text;
  final Color color;
  final bool strikeThrough;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              decoration: strikeThrough ? TextDecoration.lineThrough : null,
              decorationColor: color,
              decorationThickness: 2,
            ),
          ),
        ],
      ),
    );
  }
}
