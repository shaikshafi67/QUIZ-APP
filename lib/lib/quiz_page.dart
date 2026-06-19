import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import 'result_page.dart';
import 'quiz_summary_page.dart';

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

  const QuizPage({
    super.key,
    required this.categoryName,
    required this.difficulty,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late Future<List<QuizQuestion>> _questionsFuture;
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {};

  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _fetchQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<List<QuizQuestion>> _fetchQuestions() async {
    final data = await supabase
        .from('quizzes')
        .select()
        .eq('category', widget.categoryName)
        .eq('difficulty', widget.difficulty);

    if (data.isEmpty) return [];

    final loaded = data.map((d) => QuizQuestion.fromMap(d)).toList();
    if (loaded.isNotEmpty) _startTimer(loaded[0].timerSeconds);
    return loaded;
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() => _remainingSeconds = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          timer.cancel();
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
        _submitQuiz(questions);
      }
    } catch (e) {
      debugPrint("Timer Error: $e");
    }
  }

  void _selectAnswer(int index) {
    setState(() => _selectedAnswers[_currentQuestionIndex] = index);
  }

  void _openSummary(List<QuizQuestion> questions) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizSummaryPage(
          questions: questions,
          selectedAnswers: _selectedAnswers,
          onJumpToQuestion: (index) {
            setState(() {
              _currentQuestionIndex = index;
              _startTimer(questions[index].timerSeconds);
            });
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
    } else {
      _openSummary(questions);
    }
  }

  Color _getOptionColor(int index) {
    final selected = _selectedAnswers[_currentQuestionIndex];
    return selected == index ? Colors.blue.shade100 : Colors.grey.shade200;
  }

  Border _getOptionBorder(int index) {
    final selected = _selectedAnswers[_currentQuestionIndex];
    return selected == index
        ? Border.all(color: Colors.blue, width: 2)
        : Border.all(color: Colors.grey.shade300);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryName} (${widget.difficulty})'),
        actions: [
          FutureBuilder<List<QuizQuestion>>(
            future: _questionsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox();
              }
              return TextButton(
                onPressed: () => _openSummary(snapshot.data!),
                child: const Text("Finish",
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<QuizQuestion>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No questions found for this mode.'));
          }

          final questions = snapshot.data!;
          if (_currentQuestionIndex >= questions.length) {
            return const Center(child: CircularProgressIndicator());
          }

          final question = questions[_currentQuestionIndex];

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Q ${_currentQuestionIndex + 1}/${questions.length}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ),
                    Chip(
                      label: Text('$_remainingSeconds s'),
                      backgroundColor: _remainingSeconds < 10
                          ? Colors.red.shade100
                          : Colors.blue.shade100,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (question.imageUrl.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(question.imageUrl,
                          fit: BoxFit.cover),
                    ),
                  ),
                Text(question.questionText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w500)),
                const SizedBox(height: 32),
                ...List.generate(question.options.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () => _selectAnswer(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getOptionColor(index),
                          borderRadius: BorderRadius.circular(12),
                          border: _getOptionBorder(index),
                        ),
                        child: Text(question.options[index],
                            style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _goToNextQuestion(questions),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(
                    _currentQuestionIndex == questions.length - 1
                        ? 'Review & Submit'
                        : 'Next',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
