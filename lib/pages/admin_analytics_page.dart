// pages/admin_analytics_page.dart
import 'package:flutter/material.dart';
import 'package:hikaya_heroes/services/firebase_service.dart';
import 'package:hikaya_heroes/utils/constants.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> analytics = await _firebaseService.getAnalytics();
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading analytics: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإحصائيات'),
        centerTitle: true,
        backgroundColor: Constants.kPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Text(
              'ملخص الإحصائيات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Constants.kBlack,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('المستخدمون', '${_analytics['totalUsers'] ?? 0}', Icons.people),
                const SizedBox(width: 16),
                _buildStatCard('القصص', '${_analytics['totalStories'] ?? 0}', Icons.book),
                const SizedBox(width: 16),
                _buildStatCard('المشاهدات', '${_analytics['totalViews'] ?? 0}', Icons.visibility),
              ],
            ),
            const SizedBox(height: 24),

            // Active users
            Text(
              'المستخدمون النشطون (آخر 7 أيام)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Constants.kBlack,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(height: 8),
            _buildStatCard('', '${_analytics['activeUsers'] ?? 0}', Icons.trending_up),
            const SizedBox(height: 24),

            // Popular stories
            Text(
              'القصص الأكثر شهرة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Constants.kBlack,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: (_analytics['popularStories'] as List?)?.length ?? 0,
                itemBuilder: (context, index) {
                  final story = (_analytics['popularStories'] as List)[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Constants.kPrimaryColor.withOpacity(0.1),
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            color: Constants.kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        story['title'] ?? 'بدون عنوان',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        '${story['views'] ?? 0} مشاهدة',
                        style: TextStyle(
                          color: Constants.kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color: Constants.kPrimaryColor,
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Constants.kBlack,
                  fontFamily: 'Tajawal',
                ),
              ),
              if (title.isNotEmpty)
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Constants.kGray,
                    fontFamily: 'Tajawal',
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}