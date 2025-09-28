// pages/bookmark_page.dart
import 'package:flutter/material.dart';
import 'package:hikaya_heroes/models/story.dart';
import 'package:hikaya_heroes/services/firebase_service.dart';
import 'package:hikaya_heroes/widgets/story_card.dart';
import 'package:hikaya_heroes/pages/choose_story_page.dart';

class BookmarkPage extends StatefulWidget {
  final bool gender;
  const BookmarkPage({super.key,
    required this.gender});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  List<Story> _bookmarkedStories = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBookmarkedStories();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  void _loadBookmarkedStories() async {
    setState(() => _isLoading = true);
    try {
      List<Story> bookmarks = await _firebaseService.getUserBookmarks();
      setState(() {
        _bookmarkedStories = bookmarks;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading bookmarks: $e");
      setState(() => _isLoading = false);
    }
  }

  void _removeBookmark(Story story) async {
    try {
      await _firebaseService.removeBookmark(story.id);
      setState(() {
        _bookmarkedStories.removeWhere((s) => s.id == story.id);
      });

      // Show undo snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تمت إزالة القصة من المحفوظات'),
          action: SnackBarAction(
            label: 'تراجع',
            onPressed: () async {
              await _firebaseService.addBookmark(story.id);
              setState(() {
                _bookmarkedStories.add(story);
              });
            },
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print("Error removing bookmark: $e");
    }
  }

  void _onStoryTap(Story story) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChooseStoryPage(story: story,gender: widget.gender,),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn),
            ),
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
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: AnimatedBuilder(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "المحفوظات",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.bookmark,
                      color: Colors.amber[700],
                      size: 28,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _bookmarkedStories.isEmpty
                    ? _buildEmptyState()
                    : _buildBookmarksGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          const Text(
            "لا توجد قصص محفوظة",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "احفظ القصص المفضلة لديك هنا",
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Tajawal',
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // Navigate to home page
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text(
              "استكشاف القصص",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _bookmarkedStories.length,
        itemBuilder: (context, index) {
          final story = _bookmarkedStories[index];
          return Dismissible(
            key: Key(story.id),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: Colors.red[400],
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 30,
              ),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("إزالة من المحفوظات"),
                    content: const Text("هل تريد إزالة هذه القصة من المحفوظات؟"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("إلغاء"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("حذف"),
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) => _removeBookmark(story),
            child: StoryCard(
              story: story,
              gender: widget.gender,
              onTap: () => _onStoryTap(story),
              showBookmarkIcon: false, // Hide bookmark icon since we're in bookmarks page
            ),
          );
        },
      ),
    );
  }
}