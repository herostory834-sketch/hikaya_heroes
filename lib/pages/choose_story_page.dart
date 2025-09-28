// pages/choose_story_page.dart
import 'package:flutter/material.dart';
import 'package:hikaya_heroes/models/story.dart';
import 'package:hikaya_heroes/pages/story_customization_page.dart';
import 'package:hikaya_heroes/utils/constants.dart';
import 'package:hikaya_heroes/widgets/story_card.dart';
import 'package:hikaya_heroes/pages/story_result_page.dart';

import 'story_customization_page_old.dart';

class ChooseStoryPage extends StatefulWidget {
  final Story story;
  final bool gender;

  const ChooseStoryPage({
    super.key,
    required this.story,
    required this.gender,
  });

  @override
  State<ChooseStoryPage> createState() => _ChooseStoryPageState();
}

class _ChooseStoryPageState extends State<ChooseStoryPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  void _showCustomizationDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Constants.kPrimaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_search,
                  size: 30,
                  color: Constants.kPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'تخصيص القصة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                'يمكنك تخصيص الشخصيات لجعل القصة أكثر متعة وتشويقاً',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Tajawal',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _readStory(customized: false);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Constants.kPrimaryColor),
                      ),
                      child: const Text(
                        'قراءة عادية',
                        style: TextStyle(fontFamily: 'Tajawal'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToCustomization();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'تخصيص القصة',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCustomization() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => StoryCustomizationPageOld(
          storyId: widget.story.id,
          gender:widget.gender,
          onCustomizationComplete: (customization) {
            _readStory(customized: true, customization: customization);
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _readStory({bool customized = false, StoryCustomization? customization}) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => StoryResultPage(
          story: widget.story,
          gender:widget.gender,
          customized: customized,
          customization: customization,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.fastOutSlowIn,
              ),
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: Column(
          children: [
            // App Bar Section
            _buildAppBarSection(),

            // Story Content Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Story Card with Scale Animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildStoryCard(),
                    ),

                    const SizedBox(height: 30),

                    // Story Details
                    _buildStoryDetails(),

                    const SizedBox(height: 40),

                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Constants.kPrimaryColor.withOpacity(0.9),
            Constants.kPrimaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Constants.kPrimaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Back Button and Title Row
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'استعد للمغامرة!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Welcome Text
              Text(
                'اختر قصة لتتعلم وتتسلع',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontFamily: 'Tajawal',
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: StoryCard(
          story: widget.story,
          gender: widget.gender,
          onTap: _showCustomizationDialog,
          showBookmarkIcon: true,
         ),
      ),
    );
  }

  Widget _buildStoryDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Story Title
          Text(
            widget.story.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 10),

          // Category and Difficulty
          Row(
            children: [
              _buildDetailChip(widget.story.theme, Icons.category),
              const SizedBox(width: 10),
              _buildDetailChip(widget.story.difficulty, Icons.flag),
            ],
          ),
          const SizedBox(height: 15),

          // Description
          Text(
            'الوصف:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Constants.kPrimaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.story.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontFamily: 'Tajawal',
              height: 1.6,
            ),
          ),
          const SizedBox(height: 15),

          // Story Length Indicator
          _buildStoryLengthIndicator(),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String text, IconData icon) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 12, fontFamily: 'Tajawal'),
      ),
      avatar: Icon(icon, size: 16),
      backgroundColor: Constants.kPrimaryColor.withOpacity(0.1),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildStoryLengthIndicator() {
    final wordCount = widget.story.content.split(' ').length;
    final readingTime = (wordCount / 200).ceil(); // Average reading speed

    return Row(
      children: [
        Icon(Icons.timer, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 5),
        Text(
          'وقت القراءة: $readingTime دقيقة',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Tajawal',
          ),
        ),
        const Spacer(),
        Icon(Icons.auto_stories, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 5),
        Text(
          '$wordCount كلمة',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Quick Read Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _readStory(customized: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.kPrimaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
            ),
            icon: const Icon(Icons.auto_stories, color: Colors.white),
            label: const Text(
              'ابدأ القراءة الآن',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),

        // Customize Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showCustomizationDialog,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              side: BorderSide(color: Constants.kPrimaryColor),
            ),
            icon: Icon(Icons.person, color: Constants.kPrimaryColor),
            label: const Text(
              'تخصيص القصة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                color: Constants.kPrimaryColor,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Features Grid
        _buildFeaturesGrid(),
      ],
    );
  }

  Widget _buildFeaturesGrid() {
    final features = [
      {'icon': Icons.emoji_events, 'text': 'تحصيل النقاط'},
      {'icon': Icons.quiz, 'text': 'أسئلة تفاعلية'},
      {'icon': Icons.volume_up, 'text': 'قراءة صوتية'},
      {'icon': Icons.star, 'text': 'تقييم القصة'},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 3,
      children: features.map((feature) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(feature['icon'] as IconData, size: 16, color: Constants.kPrimaryColor),
              const SizedBox(width: 5),
              Text(
                feature['text'] as String,
                style: const TextStyle(fontSize: 12, fontFamily: 'Tajawal'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}