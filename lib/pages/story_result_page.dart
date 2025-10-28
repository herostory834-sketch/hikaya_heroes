// pages/story_result_page.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hikaya_heroes/models/story.dart';
import 'package:hikaya_heroes/pages/review_questions_page.dart';
import 'package:hikaya_heroes/services/firebase_service.dart';
import 'package:hikaya_heroes/utils/constants.dart';

class StoryResultPage extends StatefulWidget {
  final Story story;
  final bool customized;
  final StoryCustomization? customization;

  const StoryResultPage({
    super.key,
    required this.story,
    this.customized = false,
    this.customization,
  });

  @override
  State<StoryResultPage> createState() => _StoryResultPageState();
}

class _StoryResultPageState extends State<StoryResultPage> with SingleTickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _textRevealAnimation;
  late Animation<Color?> _backgroundColorAnimation;
  bool _isTextExpanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Track story view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseService().trackStoryView(widget.story.id);
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _textRevealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _backgroundColorAnimation = ColorTween(
      begin: Constants.kPrimaryColor.withOpacity(0.1),
      end: Colors.transparent,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  void _toggleTextExpansion() {
    setState(() {
      _isTextExpanded = !_isTextExpanded;
    });

    // Scroll to top when expanding
    if (_isTextExpanded) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToQuestions() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ReviewQuestionsPage(
          story: widget.story,
          customized: widget.customized,
          customization: widget.customization,
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

  String? _generateStoryText() {
    if (!widget.customized) {
      return  widget.story.content;
    }

    String? customizedStory = widget.customization!.storyText;
    return customizedStory;
  }

  Widget _buildCustomizationBadge() {
    if (!widget.customized) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 14, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            'مخصصة',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageModeBadge() {
    if (!widget.customized || widget.customization?.imageMode == null) {
      return const SizedBox();
    }

    final isCartoon = widget.customization!.imageMode == 'cartoon';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCartoon ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCartoon ? Colors.orange : Colors.blue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCartoon ? Icons.animation : Icons.photo,
            size: 14,
            color: isCartoon ? Colors.orange : Colors.blue,
          ),
          const SizedBox(width: 4),
          Text(
            isCartoon ? 'كرتوني' : 'واقعي',
            style: TextStyle(
              fontSize: 12,
              color: isCartoon ? Colors.orange : Colors.blue,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryImage() {
    // If no customization or no image, show default image
    if (widget.customization == null ||
        widget.customization!.childImage == null ||
        widget.customization!.childImage!.isEmpty) {
      return _buildImageContainer(
          widget.story.photo == 'photo' ? Image.asset(
              'assets/images/happy.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ):Image.file(
            File(widget.story.photo),
            // width: 80,
            //   height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/happy.png',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              );
            },
          )
          , widget.story.photo == 'photo' ? 'الصورة الافتراضية' : 'الصورة المحددة'
      );
    }

    try {
      final imageBytes = base64Decode(widget.customization!.childImage!);
      final isCartoon = widget.customization?.imageMode == 'cartoon';

      return _buildImageContainer(
          Image.memory(
            imageBytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              print('Image memory error: $error');
              return _buildErrorImage();
            },
          ),
          isCartoon ? 'النمط الكرتوني' : 'النمط الواقعي'
      );
    } catch (e) {
      print('Base64 decode error: $e');
      return _buildImageContainer(
          _buildErrorImage(),
          'خطأ في تحميل الصورة'
      );
    }
  }

  Widget _buildImageContainer(Widget image, String label) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: image,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorImage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 50,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 10),
        Text(
          'تعذر تحميل الصورة',
          style: TextStyle(
            color: Colors.grey[500],
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }

  Widget _buildCustomizationInfo() {
    if (!widget.customized) return const SizedBox();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 20),
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
            const Text(
              'معلومات التخصيص',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildCustomizationBadge(),
                const SizedBox(width: 10),
                _buildImageModeBadge(),
              ],
            ),
            if (widget.customization?.imageMode != null) ...[
              const SizedBox(height: 10),
              Text(
                'نمط الصورة: ${widget.customization!.imageMode == 'cartoon' ? 'كرتوني' : 'واقعي'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyText = _generateStoryText();
    final wordCount = storyText!.split(' ').length;
    final estimatedTime = (wordCount / 200).ceil(); // Average reading speed

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Constants.kPrimaryColor.withOpacity(0.9),
                          Constants.kPrimaryColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: _backgroundColorAnimation,
                      builder: (context, child) {
                        return Container(
                          color: _backgroundColorAnimation.value,
                          child: child,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Transform.translate(
                                offset: Offset(0, _slideAnimation.value),
                                child: Row(
                                  children: [
                                    _buildCustomizationBadge(),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Transform.translate(
                                offset: Offset(0, _slideAnimation.value),
                                child: Text(
                                  widget.story.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Transform.translate(
                                offset: Offset(0, _slideAnimation.value),
                                child: Text(
                                  widget.story.theme,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Story Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Customization Info
                      _buildCustomizationInfo(),

                      // Story Image
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildStoryImage(),
                      ),

                      const SizedBox(height: 20),

                      // Story Stats
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(16),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(Icons.timer, '$estimatedTime دقيقة', 'وقت القراءة'),
                              _buildStatItem(Icons.auto_stories, '$wordCount كلمة', 'طول القصة'),
                              _buildStatItem(Icons.flag, widget.story.difficulty, 'المستوى'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Story Text Header
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          children: [
                            const Text(
                              'محتوى القصة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _toggleTextExpansion,
                              icon: Icon(
                                _isTextExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Constants.kPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Story Text Content
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _isTextExpanded ? null : 300,
                        child: Stack(
                          children: [
                            FadeTransition(
                              opacity: _textRevealAnimation,
                              child: Container(
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
                                child: Text(
                                  storyText,
                                  textAlign: TextAlign.justify,
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.8,
                                    color: Constants.kBlack,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ),
                            ),
                            if (!_isTextExpanded)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.white.withOpacity(0.9),
                                        Colors.white.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'اضغط للتوسيع',
                                      style: TextStyle(
                                        color: Constants.kPrimaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // Fixed Action Button
      floatingActionButton: FadeTransition(
        opacity: _fadeAnimation,
        child: Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            width: MediaQuery.of(context).size.width * 0.9,
            child: FloatingActionButton.extended(
              onPressed: _navigateToQuestions,
              backgroundColor: Constants.kPrimaryColor,
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              icon: const Icon(Icons.quiz, color: Colors.white),
              label: const Text(
                'ابدأ مراجعة الأسئلة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Constants.kPrimaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Constants.kPrimaryColor),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }
}