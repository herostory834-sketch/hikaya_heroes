// pages/home_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hikaya_heroes/pages/choose_story_page.dart';
import 'package:hikaya_heroes/pages/profile_page.dart';
import 'package:hikaya_heroes/services/firebase_service.dart';
import 'package:hikaya_heroes/utils/constants.dart';
import '../models/story.dart';
import '../widgets/story_card.dart';
import '../models/user_model.dart';
import 'bookmark_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();
  List<Story> _stories = [];
  List<Story> _filteredStories = [];
  bool _isLoading = true;
  bool _hasError = false;
  UserModel? _user;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;

  late AnimationController _pageAnimationController;
  late AnimationController _staggerAnimationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  final List<Animation<double>> _categoryAnimations = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUser();
    _loadStories();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeAnimations() {
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _staggerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Initialize category animations
    for (int i = 0; i < Constants.categories.length; i++) {
      final start = 0.1 + (i * 0.15);
      final end = (0.6 + i * 0.15).clamp(0.0, 1.0); // clamp to 1.0
      _categoryAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerAnimationController,
            curve: Interval(start, end, curve: Curves.elasticOut),
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageAnimationController.forward();
      _staggerAnimationController.forward();
    });
  }

  void _onSearchChanged() {
    _applyFilters(_searchController.text, _selectedCategory);
  }

  Future<void> _loadUser() async {
    try {
      final uid = _firebaseService.currentUser?.uid;
      if (uid != null) {
        final UserModel? user = await _firebaseService.getUserData(uid);
        if (mounted) {
          setState(() {
            _user = user;
          });
        }
      }
    } catch (e) {
      print("Error loading user: $e");
    }
  }

  Future<void> _loadStories() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final List<Story> stories = await _firebaseService.getAllStories();
      if (mounted) {
        setState(() {
          _stories = stories;
          _filteredStories = stories;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading stories: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _applyFilters(String query, String? category) {
    if (mounted) {
      setState(() {
        _filteredStories = _stories.where((story) {
          final bool matchesQuery = story.title.toLowerCase().contains(query.toLowerCase());
          final bool matchesCategory = category == null || story.theme == category;
          return matchesQuery && matchesCategory;
        }).toList();
      });
    }
  }

  void _onCategoryTap(String category, int index) {
    _searchAnimationController.forward().then((_) {
      _searchAnimationController.reverse();
    });

    if (mounted) {
      setState(() {
        _selectedCategory = (_selectedCategory == category) ? null : category;
      });
    }
    _applyFilters(_searchController.text, _selectedCategory);
  }

  void _onStoryTap(Story story) {
    final isBookmarked = _user?.bookMarks?.contains(story.id) ?? false;
    final isMale = _user?.gender == 'male';

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChooseStoryPage(
          story: story,
          isMark: isBookmarked,
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

  void _clearFilters() {
    _searchController.clear();
    if (mounted) {
      setState(() {
        _selectedCategory = null;
      });
    }
    _applyFilters('', null);
  }

  Future<void> _onRefresh() async {
    await _loadStories();
    await _loadUser();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    _staggerAnimationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      body: SafeArea(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Constants.kPrimaryColor),
          ),
        )
            : RefreshIndicator(
          onRefresh: _onRefresh,
          child: AnimatedBuilder(
            animation: _pageAnimationController,
            builder: (context, child) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header Section
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    expandedHeight: 140,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Padding(
                        padding: const EdgeInsets.all(20),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: Row(
                              children: [
                                ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage: _user?.profileImagePath != null &&
                                        File(_user!.profileImagePath!).existsSync()
                                        ? FileImage(File(_user!.profileImagePath!))
                                        : const AssetImage("assets/images/logo.png") as ImageProvider,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "مرحباً ${_user?.name ?? 'سدرة'}!",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "اكتشف قصصاً جديدة ومثيرة",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Search Section
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1 * _searchAnimationController.value),
                                  blurRadius: 15 * _searchAnimationController.value,
                                  spreadRadius: 2 * _searchAnimationController.value,
                                  offset: const Offset(0, 5),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                if (_searchController.text.isNotEmpty || _selectedCategory != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: _clearFilters,
                                  ),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    textAlign: TextAlign.right,
                                    decoration: const InputDecoration(
                                      hintText: "البحث في القصص...",
                                      hintStyle: TextStyle(fontFamily: 'Tajawal'),
                                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

                  // Categories Section - FIXED: Replaced problematic ListView
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: const Text(
                                "تصنيف الكتب",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          // FIXED: Using SizedBox with SingleChildScrollView instead of ListView
                          SizedBox(
                            height: 110,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: List.generate(Constants.categories.length, (index) {
                                    return AnimatedBuilder(
                                      animation: _categoryAnimations[index],

                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _categoryAnimations[index].value, // clamp to valid scale
                                          child: Opacity(
                                            opacity: _categoryAnimations[index].value.clamp(0.0, 1.0), // clamp to 0..1
                                            child: child,
                                          ),
                                        );;
                                      },
                                      child: GestureDetector(
                                        onTap: () => _onCategoryTap(Constants.categories[index], index),
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 12),
                                          width: 80,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            decoration: BoxDecoration(
                                              gradient: _selectedCategory == Constants.categories[index]
                                                  ? LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Constants.kPrimaryColor,
                                                  Constants.kSecondaryColor,
                                                ],
                                              )
                                                  : null,
                                              color: _selectedCategory == Constants.categories[index]
                                                  ? null
                                                  : Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(
                                                      _selectedCategory == Constants.categories[index] ? 0.2 : 0.05),
                                                  blurRadius: _selectedCategory == Constants.categories[index] ? 10 : 5,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                ScaleTransition(
                                                  scale: _selectedCategory == Constants.categories[index]
                                                      ? Tween<double>(begin: 1.0, end: 1.2)
                                                      .animate(_searchAnimationController)
                                                      : AlwaysStoppedAnimation(1.0),
                                                  child: Image.asset(
                                                    _getCategoryIcon(index),
                                                    width: 40,
                                                    height: 40,

                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  Constants.categories[index],
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontFamily: 'Tajawal',
                                                    fontWeight: _selectedCategory == Constants.categories[index]
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color: _selectedCategory == Constants.categories[index]
                                                        ? Colors.white
                                                        : Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Stories Section
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: _buildStoriesGrid(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            selectedItemColor: Constants.kPrimaryColor,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            elevation: 8,
            onTap: _onBottomNavTap,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: "الرئيسية",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark_rounded),
                label: "المحفوظات",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: "حسابي",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoriesGrid() {
    if (_hasError) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                "حدث خطأ في تحميل القصص",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadStories,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.kPrimaryColor,
                ),
                child: const Text(
                  "إعادة المحاولة",
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredStories.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                "لم يتم العثور على قصص",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "جرب البحث بكلمات مختلفة أو اختر تصنيفاً آخر",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontFamily: 'Tajawal',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _clearFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.kPrimaryColor,
                ),
                child: const Text(
                  "مسح الفلتر",
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final story = _filteredStories[index];
          return AnimatedBuilder(
            animation: _pageAnimationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(
                  CurvedAnimation(
                    parent: _pageAnimationController,
                    curve: Interval(
                      0.5 + (index * 0.1),
                      1.0,
                      curve: Curves.easeIn,
                    ),
                  ),
                ),
                child: Transform.translate(
                  offset: Offset(0, 50 * (1 - _pageAnimationController.value)),
                  child: child,
                ),
              );
            },
            child: StoryCard(
              story: story,
              onTap: () => _onStoryTap(story),
              onBookmarkTap: (isBookmarked) {
                // Handle bookmark toggle if needed
              },
              showBookmarkIcon: true,
              isBookmarked: _user?.bookMarks?.contains(story.id) ?? false,
            ),
          );
        },
        childCount: _filteredStories.length,
      ),
    );
  }

  void _onBottomNavTap(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => BookmarkPage(
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
    } else if (index == 2) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ProfilePage(
            onProfileImageUpdated: _loadUser,
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
      ).then((_) {
        _loadUser();
      });
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  String _getCategoryIcon(int index) {
    const icons = [
      'assets/icons/family.png',
      'assets/icons/scinceandhistory.png',
      'assets/icons/adventurs.png',
      'assets/icons/animal.png',
      'assets/icons/all.png',
    ];
    return icons[index < icons.length ? index : icons.length - 1];
  }
}