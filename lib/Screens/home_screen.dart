// ===== home_screen.dart =====
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // Sample categories data
  final List<Map<String, dynamic>> categories = [
    {'title': 'الكل', 'image': 'assets/all.png'},
    {'title': 'حيوانات', 'image': 'assets/animals.png'},
    {'title': 'مغامرات', 'image': 'assets/adventure.png'},
    {'title': 'العلوم والتاريخ', 'image': 'assets/science.png'},
    {'title': 'العائلة', 'image': 'assets/family.png'},
  ];
  Widget storyCard(String image, String title, String storyId) {
    return GestureDetector(
      onTap: () {
        // Navigate to story detail screen
        Navigator.pushNamed(
          context,
          '/story-detail',
          arguments: {
            'title': title,
            'image': image,
            'content': 'هنا يأتي محتوى القصة باللغة العربية. يمكن تخصيص القصة باسم الطفل وصورته لجعلها أكثر تفاعلية ومتعة.',
            'storyId': storyId,
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(2, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.orange[100],
                      child: const Icon(Icons.book, size: 40, color: Colors.orange),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Sample stories data
  final List<Map<String, dynamic>> stories = [
    {
      'id': '1',
      'title': 'الخوارزمي عبقري الأرقام',
      'image': 'assets/story1.png',
      'theme': 'العلوم والتاريخ',
    },
    {
      'id': '2',
      'title': 'فرحة العيد في بيت جدتي',
      'image': 'assets/story2.png',
      'theme': 'العائلة',
    },
    {
      'id': '3',
      'title': 'مفاتيح معمل العلوم',
      'image': 'assets/story3.png',
      'theme': 'العلوم والتاريخ',
    },
    {
      'id': '4',
      'title': 'رحلة إلى الفضاء',
      'image': 'assets/story4.png',
      'theme': 'مغامرات',
    },
    {
      'id': '5',
      'title': 'قصة الأسد الشجاع',
      'image': 'assets/story5.png',
      'theme': 'حيوانات',
    },
    {
      'id': '6',
      'title': 'الأميرة والضفدع',
      'image': 'assets/story6.png',
      'theme': 'مغامرات',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        backgroundColor: Color(0xFFFFFAF0),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
        ],
        onTap: (index) {
          // Handle navigation based on index
          if (index == 1) {
            Navigator.pushNamed(context, '/favorites');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "مرحباً سدرة !",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// Search bar
              TextField(
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: "البحث",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              /// Categories
              const Text(
                "تصنيف الكتب",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: categories.map((category) {
                    return categoryItem(
                      category['image'] ?? 'assets/placeholder.png',
                      category['title'],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              /// New Stories
              const Text(
                "القصص الجديدة",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
                children: stories.map((story) {
                  return storyCard(
                    story['image'] ?? 'assets/placeholder.png',
                    story['title'],
                    story['id'],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category Widget
Widget categoryItem(String image, String title) {
  return Container(
    width: 80,
    margin: const EdgeInsets.only(left: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 4,
          offset: const Offset(2, 2),
        )
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          image,
          height: 30,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.category, size: 30, color: Colors.orange);
          },
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}

/// Story Card Widget
