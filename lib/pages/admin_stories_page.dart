// pages/admin_stories_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hikaya_heroes/models/story.dart';
import 'package:hikaya_heroes/services/firebase_service.dart';
import 'package:hikaya_heroes/utils/constants.dart';
import 'package:hikaya_heroes/widgets/add_story_dialog.dart';

class AdminStoriesPage extends StatefulWidget {
  const AdminStoriesPage({super.key});

  @override
  State<AdminStoriesPage> createState() => _AdminStoriesPageState();
}

class _AdminStoriesPageState extends State<AdminStoriesPage> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Story> _stories = [];
  List<Story> _filteredStories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'الكل';
  TextEditingController _searchController = TextEditingController();

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadStories();
    _searchController.addListener(_onSearchChanged);
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

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredStories = _stories.where((story) {
        final matchesSearch = story.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            story.description.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategory == 'الكل' || story.theme == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل القصص: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showAddStoryDialog([Story? story]) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: AddStoryDialog(
          onAddStory: _addOrUpdateStory,
          existingStory: story,
        ),
      ),
    ).then((_) => _loadStories());
  }

  Future<void> _addOrUpdateStory(Story story, {bool isEditing = false}) async {
    try {



      if (isEditing) {
        await _firebaseService.updateStory(story.id, story);
      } else {
        await _firebaseService.addStory(story);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'تم تحديث القصة بنجاح' : 'تم إضافة القصة بنجاح'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showDeleteConfirmation(Story story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف القصة "${story.title}"؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteStory(story.id);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteStory(String storyId) async {
    try {
      await _firebaseService.deleteStory(storyId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حذف القصة بنجاح'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'تراجع',
            onPressed: () async {
              // Note: Undo functionality would require restoring from backup
              // This is a placeholder for undo implementation
            },
          ),
        ),
      );

      _loadStories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الحذف: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showStoryDetails(Story story) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => _buildStoryDetailsSheet(story),
    );
  }

  Widget _buildStoryDetailsSheet(Story story) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  story.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showAddStoryDialog(story);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'التصنيف: ${story.theme}',
            style: TextStyle(color: Colors.grey[600], fontFamily: 'Tajawal'),
          ),
          Text(
            'المستوى: ${story.difficulty}',
            style: TextStyle(color: Colors.grey[600], fontFamily: 'Tajawal'),
          ),
          const SizedBox(height: 15),
          Text(
            'الوصف:',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
          ),
          Text(
            story.description,
            style: TextStyle(fontFamily: 'Tajawal', height: 1.5),
          ),
          const SizedBox(height: 15),
          Text(
            'المحتوى:',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
          ),
          Text(
            story.content.length > 200 ? '${story.content.substring(0, 200)}...' : story.content,
            style: TextStyle(fontFamily: 'Tajawal', height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.kPrimaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('إغلاق', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'إدارة القصص',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Constants.kPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStories,
            tooltip: 'تحديث',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStoryDialog(),
        backgroundColor: Constants.kPrimaryColor,
        child: const Icon(Icons.add, size: 28),
      ),
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
            // Search and Filter Section
            _buildSearchFilterSection(),

            // Statistics Cards
            _buildStatisticsCards(),

            // Stories List
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _filteredStories.isEmpty
                  ? _buildEmptyState()
                  : _buildStoriesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث في القصص...',
                hintStyle: const TextStyle(fontFamily: 'Tajawal'),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => _searchController.clear(),
                )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category Filter
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                'الكل',
                ...Constants.categories,
              ].map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text(category, style: const TextStyle(fontFamily: 'Tajawal')),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : 'الكل';
                        _applyFilters();
                      });
                    },
                    backgroundColor: Colors.grey[100],
                    selectedColor: Constants.kPrimaryColor.withOpacity(0.2),
                    checkmarkColor: Constants.kPrimaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Constants.kPrimaryColor : Colors.grey[700],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('إجمالي القصص', _stories.length.toString(), Icons.book),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('المعروض', _filteredStories.length.toString(), Icons.filter_list),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Constants.kPrimaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Constants.kPrimaryColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Constants.kPrimaryColor,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Constants.kPrimaryColor),
          const SizedBox(height: 16),
          const Text(
            'جاري تحميل القصص...',
            style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'لا توجد قصص',
            style: TextStyle(fontSize: 18, fontFamily: 'Tajawal', color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'اضغط على زر الإضافة لإنشاء قصة جديدة',
            style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStories.length,
      itemBuilder: (context, index) {
        final story = _filteredStories[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key(story.id),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: Colors.red[400],
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white, size: 30),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("تأكيد الحذف"),
                    content: Text("هل تريد حذف قصة '${story.title}'؟"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("إلغاء"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("حذف", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) => _deleteStory(story.id),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Constants.kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.book, color: Constants.kPrimaryColor),
                ),
                title: Text(
                  story.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      story.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildChip(story.theme, Icons.category),
                        const SizedBox(width: 8),
                        _buildChip(story.difficulty, Icons.flag),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        _showStoryDetails(story);
                        break;
                      case 'edit':
                        _showAddStoryDialog(story);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(story);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(children: [
                        Icon(Icons.visibility, size: 20),
                        SizedBox(width: 8),
                        Text('عرض التفاصيل'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('تعديل'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('حذف', style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
                onTap: () => _showStoryDetails(story),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(String text, IconData icon) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 10, fontFamily: 'Tajawal'),
      ),
      avatar: Icon(icon, size: 14),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      backgroundColor: Colors.grey[100],
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}