// pages/review_questions_page.dart
import 'package:flutter/material.dart';
import 'package:hikaya_heroes/models/story.dart';
import 'package:hikaya_heroes/utils/constants.dart';

class ReviewQuestionsPage extends StatefulWidget {
  final Story story;
  final bool customized;
  final StoryCustomization? customization;

  const ReviewQuestionsPage({
    super.key,
    required this.story,
    this.customized = false,
    this.customization,
  });

  @override
  State<ReviewQuestionsPage> createState() => _ReviewQuestionsPageState();
}

class _ReviewQuestionsPageState extends State<ReviewQuestionsPage> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  List<String?> _selectedAnswers = List.filled(5, null); // Initialize with nulls

  @override
  Widget build(BuildContext context) {
    final question = widget.story.questions[_currentQuestionIndex];
    final isLastQuestion = _currentQuestionIndex == widget.story.questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.story.title),
        centerTitle: true,
        backgroundColor: Constants.kPrimaryColor,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.story.questions.length,
            backgroundColor: Constants.kLightGray,
            valueColor: AlwaysStoppedAnimation<Color>(Constants.kPrimaryColor),
          ),
          const SizedBox(height: 20),
          // Question card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Question text
                  Text(
                    question.text,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Constants.kBlack,
                      fontFamily: 'Tajawal',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  // Story illustration
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Constants.kLightGray,
                    ),
                    child: const Icon(
                      Icons.auto_stories,
                      size: 100,
                      color: Constants.kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Answer options
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: question.options.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedAnswers[_currentQuestionIndex] == question.options[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: isSelected ? Constants.kPrimaryColor.withOpacity(0.1) : Constants.kLightGray,
                          child: ListTile(
                            title: Text(
                              question.options[index],
                              style: TextStyle(
                                color: isSelected ? Constants.kPrimaryColor : Constants.kBlack,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            leading: Radio<String>(
                              value: question.options[index],
                              groupValue: _selectedAnswers[_currentQuestionIndex],
                              onChanged: (value) {
                                setState(() {
                                  _selectedAnswers[_currentQuestionIndex] = value;
                                });
                              },
                              activeColor: Constants.kPrimaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                if (_currentQuestionIndex > 0)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentQuestionIndex--;
                      });},

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.kLightGray,
                    ),
                    child: const Text('السابق'),
                  ),
                // Next/Submit button
                ElevatedButton(
                  onPressed: () {
                    if (isLastQuestion) {
                      _calculateScore();
                      _showResults();
                    } else {
                      setState(() {
                        _currentQuestionIndex++;
                      });
                    }
                  },
                  child: Text(isLastQuestion ? 'إرسال' : 'التالي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _calculateScore() {
    for (int i = 0; i < widget.story.questions.length; i++) {
      if (_selectedAnswers[i] == widget.story.questions[i].correctAnswer) {
        _score++;
      }
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نتائجك'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'لقد أجبت على ${widget.story.questions.length} سؤال',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            Text(
              'أجبت بشكل صحيح على $_score سؤال',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            const SizedBox(height: 20),
            Text(
              'ممتاز! لقد فهمت القصة جيداً',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Constants.kPrimaryColor,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
             },
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}