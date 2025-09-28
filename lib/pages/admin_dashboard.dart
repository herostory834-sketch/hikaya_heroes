// pages/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:hikaya_heroes/pages/admin_stories_page.dart';
import 'package:hikaya_heroes/pages/admin_users_page.dart';
import 'package:hikaya_heroes/pages/admin_analytics_page.dart';
import 'package:hikaya_heroes/utils/constants.dart';
import '../services/firebase_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<Color?> _backgroundColorAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
        curve: Curves.easeOutBack,
      ),
    );

    _backgroundColorAnimation = ColorTween(
      begin: Constants.kPrimaryColor.withOpacity(0.9),
      end: Constants.kPrimaryColor,
    ).animate(_animationController);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });

    // Restart animation for page transition
    _animationController.forward(from: 0.0);
  }

  Future<void> _signOut() async {
    // Show confirmation dialog with animation
    await _showLogoutConfirmation();
  }

  Future<void> _showLogoutConfirmation() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => _LogoutConfirmationDialog(
        animationController: _animationController,
      ),
    );

    if (shouldLogout == true) {
      await FirebaseService().signOut();
      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildAnimatedBody(),
      bottomNavigationBar: _buildAnimatedBottomNavBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0.0, (1 - _animationController.value) * -20),
            child: Opacity(
              opacity: _animationController.value,
              child: child,
            ),
          );
        },
        child: const Text(
          'لوحة التحكم',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
      ),
      centerTitle: true,
      backgroundColor: Constants.kPrimaryColor,
      elevation: 8,
      shadowColor: Constants.kPrimaryColor.withOpacity(0.3),
      actions: [
        ScaleTransition(
          scale: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'تسجيل الخروج',
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final slideAnimation = Tween<Offset>(
          begin: Offset(_currentIndex > _previousIndex ? 1.0 : -1.0, 0.0),
          end: Offset.zero,
        ).animate(animation);

        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      child: _buildCurrentPage(),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const AdminStoriesPage(key: ValueKey('stories'));
      case 1:
        return const AdminUsersPage(key: ValueKey('users'));
      case 2:
        return const AdminAnalyticsPage(key: ValueKey('analytics'));
      default:
        return const AdminStoriesPage(key: ValueKey('stories'));
    }
  }

  Widget _buildAnimatedBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Constants.kPrimaryColor,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.7),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Tajawal',
          ),
          type: BottomNavigationBarType.fixed,
          items: [
            _buildBottomNavItem(
              icon: Icons.book,
              label: 'القصص',
              index: 0,
            ),
            _buildBottomNavItem(
              icon: Icons.people,
              label: 'المستخدمون',
              index: 1,
            ),
            _buildBottomNavItem(
              icon: Icons.analytics,
              label: 'الإحصائيات',
              index: 2,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    return BottomNavigationBarItem(
      icon: Stack(
        children: [
          Icon(icon),
          if (_currentIndex == index)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      activeIcon: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.2).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }
}

class _LogoutConfirmationDialog extends StatefulWidget {
  final AnimationController animationController;

  const _LogoutConfirmationDialog({required this.animationController});

  @override
  State<_LogoutConfirmationDialog> createState() =>
      _LogoutConfirmationDialogState();
}

class _LogoutConfirmationDialogState extends State<_LogoutConfirmationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _dialogController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _dialogController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _dialogController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _dialogController,
        curve: Curves.easeInOut,
      ),
    );

    _dialogController.forward();
  }

  @override
  void dispose() {
    _dialogController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Icon(
                Icons.logout,
                color: Colors.red,
                size: 40,
              ),
              const SizedBox(height: 10),
              const Text(
                'تأكيد تسجيل الخروج',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          content: const Text(
            'هل أنت متأكد أنك تريد تسجيل الخروج؟',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: Constants.kPrimaryColor),
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}