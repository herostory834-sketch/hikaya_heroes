// pages/bookmark_page.dart
import 'package:flutter/material.dart';
import 'package:hikaya_heroes/models/story.dart';
import 'package:hikaya_heroes/services/firebase_service.dart';
import 'package:hikaya_heroes/widgets/story_card.dart';
import 'package:hikaya_heroes/pages/choose_story_page.dart';
import 'package:hikaya_heroes/utils/constants.dart';

class BookmarkPage extends StatefulWidget {
  final VoidCallback? onStoryRemoved;

  const BookmarkPage({
    super.key,
    this.onStoryRemoved,
  });

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  List<Story> _bookmarkedStories = [];
  bool _isLoading = true;
  bool _hasError = false;
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

  Future<void> _loadBookmarkedStories() async {
     if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final List<Story> bookmarks = await _firebaseService.getUserBookmarks();
      if (mounted) {
        setState(() {
          _bookmarkedStories = bookmarks;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading bookmarks: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _removeBookmark(Story story) async {
    try {
      await _firebaseService.removeBookmark(story.id);
      if (mounted) {
        setState(() {
          _bookmarkedStories.removeWhere((s) => s.id == story.id);
        });
        widget.onStoryRemoved?.call();
      }

      // Show undo snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تمت إزالة القصة من المحفوظات',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          action: SnackBarAction(
            label: 'تراجع',
            textColor: Colors.white,
            onPressed: () => _undoRemoveBookmark(story),
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      print("Error removing bookmark: $e");
      _showErrorSnackBar('فشل في إزالة القصة من المحفوظات');
    }
  }

  Future<void> _undoRemoveBookmark(Story story) async {
    try {
      await _firebaseService.addBookmark(story.id);
      if (mounted) {
        setState(() {
          _bookmarkedStories.add(story);
          _bookmarkedStories.sort((a, b) => a.title.compareTo(b.title));
        });
      }
    } catch (e) {
      _showErrorSnackBar('فشل في استعادة القصة');
    }
  }

  void _onStoryTap(Story story) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChooseStoryPage(
          story: story,
          isMark: true,
        ),
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

  void _onRefresh() async {
    await _loadBookmarkedStories();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('_bookmarkedStories.length');
    print(_bookmarkedStories.length);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildAppBar(),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Constants.kPrimaryColor,
            Constants.kSecondaryColor,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Constants.kPrimaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              const Text(
                "المحفوظات",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bookmark,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _bookmarkedStories.length.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_bookmarkedStories.isEmpty) {
      return _buildEmptyState();
    }

    return _buildBookmarksList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Constants.kPrimaryColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          const Text(
            "جاري تحميل المحفوظات...",
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Tajawal',
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          const Text(
            "حدث خطأ في تحميل المحفوظات",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "يرجى المحاولة مرة أخرى",
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Tajawal',
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _loadBookmarkedStories,
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.kPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              "إعادة المحاولة",
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

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () async => _loadBookmarkedStories(),
      backgroundColor: Colors.white,
      color: Constants.kPrimaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border_rounded,
                  size: 100,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                const Text(
                  "لا توجد قصص محفوظة",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "احفظ القصص المفضلة لديك لتظهر هنا",
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Tajawal',
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    elevation: 5,
                  ),
                  icon: const Icon(Icons.explore, size: 20),
                  label: const Text(
                    "استكشاف القصص",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarksList() {
    return RefreshIndicator(
      onRefresh: () async => _loadBookmarkedStories(),
      backgroundColor: Colors.white,
      color: Constants.kPrimaryColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Quick Stats
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    _bookmarkedStories.length.toString(),
                    "القصص المحفوظة",
                    Icons.bookmark,
                    Constants.kPrimaryColor,
                  ),
                  _buildStatItem(
                    _bookmarkedStories
                        .where((story) => story.theme == 'علوم')
                        .length
                        .toString(),
                    "تعليمية",
                    Icons.school,
                    Colors.blue,
                  ),
                  _buildStatItem(
                    _bookmarkedStories
                        .where((story) => story.theme == 'عائلة')
                        .length
                        .toString(),
                    "عائلية",
                    Icons.celebration,
                    Colors.amber,
                  ),
                ],
              ),
            ),

            // Stories Grid
            Expanded(
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
                  return _buildStoryCard(story);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'Tajawal',
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStoryCard(Story story) {
    return Dismissible(
      key: Key('bookmark_${story.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.bookmark_remove,
          color: Colors.white,
          size: 30,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text(
                "إزالة من المحفوظات",
                style: TextStyle(fontFamily: 'Tajawal'),
                textAlign: TextAlign.center,
              ),
              content: Text(
                "هل تريد إزالة '${story.title}' من المحفوظات؟",
                style: const TextStyle(fontFamily: 'Tajawal'),
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    "إلغاء",
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    "إزالة",
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) => _removeBookmark(story),
      child: StoryCard(
        story: story,
        onBookmarkTap: (isBookmarked) {

setState(() {
  _bookmarkedStories.removeWhere((story) => story.id == isBookmarked);
});
        },
        onTap: () => _onStoryTap(story),
        showBookmarkIcon: true,
       ),
    );
  }
}