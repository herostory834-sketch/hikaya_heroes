// widgets/story_card.dart
import 'package:flutter/material.dart';
import 'package:hikaya_heroes/models/story.dart';
import 'package:hikaya_heroes/utils/constants.dart';

class StoryCard extends StatelessWidget {
  final Story story;
  final bool gender;
  final VoidCallback onTap;

  const StoryCard({
    super.key,
    required this.story,
    required this.gender,
    required this.onTap, required bool showBookmarkIcon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Container(
            child: gender?Image.asset('assets/images/boy.png'):Image.asset('assets/images/girl.png'),
          ),
           Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Story title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Card(
                         // margin: EdgeInsets.all(6),
                          child: Text(
                            story.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Constants.kBlack,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Story description
                    Text(
                      story.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Constants.kGray,
                        fontFamily: 'Tajawal',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // Story details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Category
                        Card(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Constants.kPrimaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              story.theme,
                              style: TextStyle(
                                color: Constants.kPrimaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ),
                        ),
                        // Difficulty
                       ],
                    ),
                  ],
                ),
              ),
            ),

        ],
      ),
    );
  }
}