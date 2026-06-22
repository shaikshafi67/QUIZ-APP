import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart';
import 'result_page.dart';
import 'quiz_summary_page.dart';
import 'app_theme.dart';

class QuizQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final String imageUrl;
  final String categoryName;
  final String difficulty;
  final int timerSeconds;
  final DateTime createdAt;

  const QuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.imageUrl,
    required this.categoryName,
    required this.difficulty,
    required this.timerSeconds,
    required this.createdAt,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> data) {
    return QuizQuestion(
      id: data['id']?.toString() ?? '',
      questionText: data['question_text'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswerIndex: (data['correct_answer_index'] as num?)?.toInt() ?? 0,
      imageUrl: data['image_url'] ?? '',
      categoryName: data['category'] ?? '',
      difficulty: data['difficulty'] ?? 'Easy',
      timerSeconds: (data['timer_seconds'] as num?)?.toInt() ?? 30,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class QuizPage extends StatefulWidget {
  final String categoryName;
  final String difficulty;
  const QuizPage(
      {super.key, required this.categoryName, required this.difficulty});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  late Future<List<QuizQuestion>> _questionsFuture;
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {};

  Timer? _timer;
  int _remainingSeconds = 0;

  late AnimationController _cardController;
  late Animation<double> _cardScale;
  late Animation<double> _cardOpacity;
  late AnimationController _optionController;
  int? _flashIndex;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _fetchQuestions();

    _cardController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _cardScale = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
    _optionController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _cardController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cardController.dispose();
    _optionController.dispose();
    super.dispose();
  }

  Future<List<QuizQuestion>> _fetchQuestions() async {
    final data = await supabase
        .from('quizzes')
        .select()
        .eq('category', widget.categoryName)
        .eq('difficulty', widget.difficulty);

    if (data.isEmpty) return [];
    final questions = data.map((d) => QuizQuestion.fromMap(d)).toList();
    if (questions.isNotEmpty) _startTimer(questions[0].timerSeconds);
    return questions;
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() => _remainingSeconds = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          t.cancel();
          _handleTimeUp();
        }
      }
    });
  }

  void _handleTimeUp() async {
    try {
      final questions = await _questionsFuture;
      if (_currentQuestionIndex < questions.length - 1) {
        _goToNextQuestion(questions);
      } else {
        _openSummary(questions);
      }
    } catch (_) {}
  }

  void _selectAnswer(int index) async {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = index;
      _flashIndex = index;
    });
    await Future.delayed(const Duration(milliseconds: 120));
    if (mounted) setState(() => _flashIndex = null);
  }

  void _openSummary(List<QuizQuestion> questions) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizSummaryPage(
          questions: questions,
          selectedAnswers: _selectedAnswers,
          onJumpToQuestion: (i) {
            setState(() {
              _currentQuestionIndex = i;
              _startTimer(questions[i].timerSeconds);
            });
            _animateCard();
          },
          onSubmit: () => _submitQuiz(questions),
        ),
      ),
    );
  }

  void _submitQuiz(List<QuizQuestion> questions) {
    int score = 0;
    _selectedAnswers.forEach((qi, ai) {
      if (questions[qi].correctAnswerIndex == ai) score++;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          score: score,
          totalQuestions: questions.length,
          categoryName: widget.categoryName,
        ),
      ),
    );
  }

  void _goToNextQuestion(List<QuizQuestion> questions) {
    _timer?.cancel();
    if (_currentQuestionIndex < questions.length - 1) {
      setState(() => _currentQuestionIndex++);
      _startTimer(questions[_currentQuestionIndex].timerSeconds);
      _animateCard();
    } else {
      _openSummary(questions);
    }
  }

  void _animateCard() {
    _cardController.reset();
    _cardController.forward();
  }

  Color _difficultyColor() {
    switch (widget.difficulty) {
      case 'Hard':
        return AppColors.pink;
      case 'Medium':
        return AppColors.orange;
      default:
        return AppColors.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final diffColor = _difficultyColor();

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<List<QuizQuestion>>(
            future: _questionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.purple));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: GlassCard(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('😕', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        const Text('No questions found',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        GradientButton(
                          label: 'Go Back',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final questions = snapshot.data!;
              if (_currentQuestionIndex >= questions.length) {
                return const Center(child: CircularProgressIndicator());
              }
              final question = questions[_currentQuestionIndex];
              final timerRatio = _remainingSeconds /
                  (question.timerSeconds > 0 ? question.timerSeconds : 1);
              final timerColor = _remainingSeconds < 10
                  ? AppColors.pink
                  : _remainingSeconds < 20
                      ? AppColors.orange
                      : AppColors.cyan;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: GlassCard(
                            padding: const EdgeInsets.all(10),
                            borderRadius: BorderRadius.circular(12),
                            child: const Icon(Icons.arrow_back_ios_new,
                                size: 16, color: Colors.white),
                          ),
                        ),
                        GlassCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          borderRadius: BorderRadius.circular(20),
                          child: Text(
                            'Q ${_currentQuestionIndex + 1} / ${questions.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _openSummary(questions),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            borderRadius: BorderRadius.circular(20),
                            child: Row(
                              children: [
                                Icon(Icons.list_rounded,
                                    color: diffColor, size: 16),
                                const SizedBox(width: 4),
                                Text('Finish',
                                    style: TextStyle(
                                        color: diffColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value:
                            (_currentQuestionIndex + 1) / questions.length,
                        backgroundColor: Colors.white.withAlpha(20),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.purple),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [diffColor, diffColor.withAlpha(180)]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.difficulty,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: timerRatio,
                                backgroundColor: Colors.white.withAlpha(20),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    timerColor),
                                strokeWidth: 3,
                              ),
                              Center(
                                child: Text(
                                  '$_remainingSeconds',
                                  style: TextStyle(
                                    color: timerColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ScaleTransition(
                      scale: _cardScale,
                      child: FadeTransition(
                        opacity: _cardOpacity,
                        child: GlassCard(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (question.imageUrl.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    question.imageUrl,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              // Question number indicator
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.purple.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.purple.withValues(alpha: 0.30)),
                                ),
                                child: Text(
                                  'Question ${_currentQuestionIndex + 1}',
                                  style: const TextStyle(
                                      color: AppColors.purple,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5),
                                ),
                              ),
                              Text(
                                question.questionText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: List.generate(question.options.length, (i) {
                        final isSelected =
                            _selectedAnswers[_currentQuestionIndex] == i;
                        final isFlashing = _flashIndex == i;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => _selectAnswer(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: AppColors.primaryGradient)
                                    : null,
                                color: isSelected
                                    ? null
                                    : isFlashing
                                        ? AppColors.purple.withAlpha(40)
                                        : isDark
                                            ? Colors.white.withAlpha(12)
                                            : Colors.white.withAlpha(180),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : AppColors.purple.withAlpha(
                                          isFlashing ? 80 : 30),
                                  width: isSelected ? 0 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color:
                                              AppColors.purple.withAlpha(80),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : [],
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Colors.white.withAlpha(50)
                                          : AppColors.purple.withAlpha(25),
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + i),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.purple,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      question.options[i],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Colors.white
                                            : isDark
                                                ? Colors.white70
                                                : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle,
                                        color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: GradientButton(
                      label: _currentQuestionIndex == questions.length - 1
                          ? 'Review & Submit'
                          : 'Next Question',
                      onPressed: () => _goToNextQuestion(questions),
                      icon: _currentQuestionIndex == questions.length - 1
                          ? Icons.check_circle_outline
                          : Icons.arrow_forward_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
