import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hikaya_heroes/models/story.dart';
import 'package:hikaya_heroes/utils/constants.dart';

class StoryCard extends StatelessWidget {
  final Story story;
  final VoidCallback onTap;
  final bool showBookmarkIcon;
  final Function(String) onBookmarkTap;
  final bool isBookmarked;

  const StoryCard({
    super.key,
    required this.story,
    required this.onTap,
    required this.showBookmarkIcon,
    required this.onBookmarkTap,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Image with Gradient Overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Background Character Image
                 story.photo == 'photo' ? Image.asset(
                      'assets/images/happy.png',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ):Image.file(
                   File(story.photo),
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
                      ,

                  // Gradient Overlay for better text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Story Title
                    Text(
                      story.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Tajawal',
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),

                    // Story Details Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Constants.kPrimaryColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            story.theme,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),

                        // Difficulty Indicator (if available)
                        if (story.difficulty != null) _buildDifficultyIndicator(story.difficulty!),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bookmark Icon
            if (showBookmarkIcon)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => onBookmarkTap(story.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: isBookmarked ? Constants.kSecondaryColor : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
              ),

            // New Badge for Recent Stories (Optional)
            if (_isNewStory(story.createdAt))
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'جديد',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyIndicator(String difficulty) {
    Color difficultyColor;
    String difficultyText;

    switch (difficulty.toLowerCase()) {
      case 'easy':
        difficultyColor = Colors.green;
        difficultyText = 'سهل';
        break;
      case 'medium':
        difficultyColor = Colors.orange;
        difficultyText = 'متوسط';
        break;
      case 'hard':
        difficultyColor = Colors.red;
        difficultyText = 'صعب';
        break;
      default:
        difficultyColor = Colors.grey;
        difficultyText = difficulty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: difficultyColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        difficultyText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }

  bool _isNewStory(DateTime? createdAt) {
    if (createdAt == null) return false;
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays < 7; // Consider story as new if created within last 7 days
  }
}