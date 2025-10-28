// pages/choose_story_page.dart
import 'package:flutter/material.dart';
import 'package:hikaya_heroes/models/story.dart';
import 'package:hikaya_heroes/pages/story_customization_page.dart';
import 'package:hikaya_heroes/utils/constants.dart';
import 'package:hikaya_heroes/widgets/story_card.dart';
import 'package:hikaya_heroes/pages/story_result_page.dart';

import '../models/user_model.dart';
import '../services/firebase_service.dart';

class ChooseStoryPage extends StatefulWidget {
  final Story story;
  final bool isMark;
  final bool gender;

  const ChooseStoryPage({
    super.key,
    required this.story,
    required this.isMark,
    required this.gender,
  });

  @override
  State<ChooseStoryPage> createState() => _ChooseStoryPageState();
}

class _ChooseStoryPageState extends State<ChooseStoryPage> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _user;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _backgroundColorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

  Future<void> _loadUserData() async {
    try {
      final uid = _firebaseService.currentUser?.uid;
      if (uid != null) {
        final user = await _firebaseService.getUserData(uid);
        if (mounted) {
          setState(() {
            _user = user;
          });
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _toggleBookmark(String removeBookmark) async {
    try {

        await _firebaseService.removeBookmark(removeBookmark);
        if (mounted) {
          setState(() {
            _user?.bookMarks.remove(removeBookmark);
          });
        }

      Navigator.pop(context);

    } catch (e) {
      print("Error toggling bookmark: $e");
      _showErrorSnackBar('فشل في تحديث المحفوظات');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showCustomizationDialog() {
    showDialog(
      context: context,
      builder: (context) => AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Constants.kPrimaryColor,
                        Constants.kSecondaryColor,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'تخصيص القصة',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'يمكنك تخصيص الشخصيات والإعدادات لجعل القصة أكثر متعة وتشويقاً وتناسب تفضيلاتك',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    fontFamily: 'Tajawal',
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),

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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          side: BorderSide(color: Constants.kPrimaryColor, width: 2),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'قراءة عادية',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToCustomization();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 4,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_rounded, size: 2),
                            SizedBox(width: 2),
                            Text(
                              'تخصيص القصة',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCustomization() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => StoryCustomizationPage(
          storyId: widget.story.id,
          gender: widget.gender,
          onCustomizationComplete: (customization) {
            _readStory(customized: true, customization: customization);
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn);
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(curve),
            child: FadeTransition(opacity: animation, child: child),
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
          gender: widget.gender,
          customized: customized,
          customization: customization,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn);
          return ScaleTransition(
            scale: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
            child: FadeTransition(opacity: animation, child: child),
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
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar Section
              SliverAppBar(
                expandedHeight: 180,
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
                          Constants.kPrimaryColor,
                          Constants.kSecondaryColor,
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
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed: () => Navigator.pop(context),
                                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_user != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'المستوى: ${_user?.totalPoints ?? 0}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Tajawal',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Transform.translate(
                                offset: Offset(0, _slideAnimation.value),
                                child: const Text(
                                  'استعد للمغامرة!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Transform.translate(
                                offset: Offset(0, _slideAnimation.value),
                                child: Text(
                                  'اختر قصة لتتعلم وتستمتع',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                    fontFamily: 'Tajawal',
                                    height: 1.5,
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

              // Content Section
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Story Card - FIXED: Added explicit height
                    SizedBox(
                      height: 400, // Explicit height to prevent layout issues
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildStoryCard(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Story Details
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: _buildStoryDetails(),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildActionButtons(),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStoryCard() {
    if (_user == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey[100],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Constants.kPrimaryColor),
          ),
        ),
      );
    }

    final isBookmarked = _user?.bookMarks?.contains(widget.story.id) ?? false;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
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
          isBookmarked: isBookmarked,
          onTap: _showCustomizationDialog,
          onBookmarkTap: _toggleBookmark,
          showBookmarkIcon: true,
        ),
      ),
    );
  }

  Widget _buildStoryDetails() {
    final wordCount = widget.story.content.split(' ').length;
    final readingTime = (wordCount / 200).ceil();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
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
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Category and Difficulty
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildDetailChip(widget.story.theme, Icons.category_rounded),
              _buildDetailChip(_getDifficultyText(widget.story.difficulty), Icons.flag_rounded),
              _buildDetailChip('$readingTime دقيقة', Icons.timer_rounded),
            ],
          ),
          const SizedBox(height: 20),

          // Description Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Constants.kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'وصف القصة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Constants.kPrimaryColor,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Description Text
          Text(
            widget.story.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              fontFamily: 'Tajawal',
              height: 1.7,
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 20),

          // Story Stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.auto_stories_rounded, '$wordCount', 'كلمة'),
                _buildStatItem(Icons.timer_outlined, '$readingTime', 'دقيقة'),
                _buildStatItem(Icons.emoji_events_rounded, widget.story.difficulty, 'مستوى'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String text, IconData icon) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w600,
        ),
      ),
      avatar: Icon(icon, size: 18, color: Constants.kPrimaryColor),
      backgroundColor: Constants.kPrimaryColor.withOpacity(0.1),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Constants.kPrimaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Constants.kPrimaryColor),
        ),
        const SizedBox(height: 6),
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
            fontSize: 11,
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
        // Main Action Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showCustomizationDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 6,
              shadowColor: Constants.kPrimaryColor.withOpacity(0.3),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: const Text(
              'ابدأ القراءة الآن',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ),


      ],
    );
  }

  String _getDifficultyText(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'سهل';
      case 'medium':
        return 'متوسط';
      case 'hard':
        return 'صعب';
      default:
        return difficulty;
    }
  }
}