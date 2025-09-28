// ===== favorites_screen.dart =====
import 'package:flutter/material.dart';

class favoriteScreen extends StatefulWidget {
  const favoriteScreen({super.key});

  @override
  State<favoriteScreen> createState() => _favoriteScreenState();
}

class _favoriteScreenState extends State<favoriteScreen> {
  // Sample bookmarked stories data
  final List<Map<String, dynamic>> bookmarkedStories = [
    {
      'title': 'الخوارزمي عبقري الأرقام',
      'image': 'assets/story1.png',
    },
    {
      'title': 'فرحة العيد في بيت جدتي',
      'image': 'assets/story2.png',
    },
    {
      'title': 'مفاتيح معمل العلوم',
      'image': 'assets/story3.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 173, 125, 30),
        elevation: 0,
        title: const Text(
          "القصص المحفوظة",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text(
          "قائمة القصص المحفوظة",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: bookmarkedStories.isEmpty
              ? const Center(
            child: Text(
              "لا توجد قصص محفوظة بعد",
              style: TextStyle(fontSize: 16),
            ),
          )
              : ListView.builder(
            itemCount: bookmarkedStories.length,
            itemBuilder: (context, index) {
              final story = bookmarkedStories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        story['image'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        story['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmark, color: Colors.orange),
                      onPressed: () {
                        // Remove from bookmarks
                        setState(() {
                          bookmarkedStories.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        )],
        ),
      ),
    );
  }
}