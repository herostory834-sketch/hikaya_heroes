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
  UserModel? _user;
  TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;

  // Animation controllers
  late AnimationController _pageAnimationController;
  late AnimationController _staggerAnimationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  List<Animation<double>> _categoryAnimations = [];

  @override
  void initState() {
    super.initState();

    _initializeAnimations();
    _loadUser();
    _loadStories();
    _searchController.addListener(() {
      _applyFilters(_searchController.text, _selectedCategory);
    });
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

    // Create staggered animations for categories
    for (int i = 0; i < Constants.categories.length; i++) {
      _categoryAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerAnimationController,
            curve: Interval(
              0.1 + (i * 0.15),
              0.6 + (i * 0.15),
              curve: Curves.elasticOut,
            ),
          ),
        ),
      );
    }

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageAnimationController.forward();
      _staggerAnimationController.forward();
    });
  }

  void _loadUser() async {
    String? uid = _firebaseService.currentUser?.uid;
    if (uid != null) {
      UserModel? user = await _firebaseService.getUserData(uid);
      setState(() {
        _user = user;
      });
    }
  }

  void _loadStories() async {
    setState(() => _isLoading = true);
    try {
      List<Story> stories = await _firebaseService.getAllStories();
      setState(() {
        _stories = stories;
        _filteredStories = stories;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading stories: $e");
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters(String query, String? category) {
    setState(() {
      _filteredStories = _stories.where((story) {
        bool matchesQuery = story.title.toLowerCase().contains(query.toLowerCase());
        bool matchesCategory = category == null || story.theme == category;
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  void _onCategoryTap(String category, int index) {
    // Animate category selection
    _searchAnimationController.forward().then((_) {
      _searchAnimationController.reverse();
    });

    setState(() {
      _selectedCategory = (_selectedCategory == category) ? null : category;
    });
    _applyFilters(_searchController.text, _selectedCategory);
  }

  void _onStoryTap(Story story) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChooseStoryPage(story: story, gender: _user!.gender=='male',),
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
            : AnimatedBuilder(
          animation: _pageAnimationController,
          builder: (context, child) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Welcome Section =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                backgroundImage: const AssetImage("assets/images/logo.png"),
                                backgroundColor: Colors.grey[300],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "مرحباً ${_user?.name ?? 'سدرة'} !",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===== Search Bar =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ===== Categories =====
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
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: Constants.categories.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _onCategoryTap(Constants.categories[index], index),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 80,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: _selectedCategory == Constants.categories[index]
                                    ? Colors.green[100]
                                    : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(_selectedCategory == Constants.categories[index] ? 0.2 : 0.05),
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
                                        ? Tween<double>(begin: 1.0, end: 1.2).animate(_searchAnimationController)
                                        : AlwaysStoppedAnimation(1.0),
                                    child: Image.asset(
                                      _getCategoryIcon(index),
                                      width: 48,
                                      height: 48,
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
                                          ? Colors.green[800]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ===== New Stories Section =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        "القصص الجديدة",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // ===== Stories Grid =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _filteredStories.isEmpty
                        ? FadeTransition(
                      opacity: _fadeAnimation,
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "لم يتم العثور على قصص",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _filteredStories.length,
                      itemBuilder: (context, index) {
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
                            gender:_user!.gender=='male',
                            onTap: () => _onStoryTap(story), showBookmarkIcon: true,
                            
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),

      // ===== Bottom Navigation =====
      bottomNavigationBar: FadeTransition(
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
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            selectedItemColor: Constants.kPrimaryColor,
            unselectedItemColor: Colors.grey,

            onTap: _onBottomNavTap, // Use the new method here

            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "الرئيسية",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark),
                label: "المحفوظات",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "حسابي",
              ),
            ],
          ),
        ),
      ),
    );
  }
// In your home_page.dart, inside the _HomePageState class

  void _onBottomNavTap(int index) {
    if (index == 1) {
      // Bookmark page
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>   BookmarkPage(gender: _user!.gender =='male'),
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
      // Profile page
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ProfilePage(),
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
    } else {
      // Home page (index 0) - just update the index
      setState(() {
        _selectedIndex = index;
      });
    }
  }  String _getCategoryIcon(int index) {
    switch (index) {
      case 0:
        return 'assets/icons/family.png';
      case 1:
        return 'assets/icons/scinceandhistory.png';
      case 2:
        return 'assets/icons/adventurs.png';
      case 3:
        return 'assets/icons/animal.png';
      case 4:
        return 'assets/icons/all.png';
      default:
        return 'assets/icons/all.png';
    }
  }
}