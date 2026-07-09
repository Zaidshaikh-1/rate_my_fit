import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/fit_card.dart';
import '../widgets/vibe_card_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Placeholder fit model — swap with Firestore model later
class _FitPost {
  final String id;
  final String username;
  final String timeAgo;
  final List<String> tags;
  final double avgScore;
  final int ratingCount;

  const _FitPost({
    required this.id,
    required this.username,
    required this.timeAgo,
    required this.tags,
    required this.avgScore,
    required this.ratingCount,
  });
}

// Sample data — replace with Firestore stream
final _sampleFits = [
  _FitPost(
    id: '1',
    username: '@zaidxo',
    timeAgo: '2h ago',
    tags: ['streetwear', 'grunge', 'oversized'],
    avgScore: 91,
    ratingCount: 34,
  ),
  _FitPost(
    id: '2',
    username: '@mia.fits',
    timeAgo: '4h ago',
    tags: ['y2k', 'denim', 'vintage'],
    avgScore: 74,
    ratingCount: 21,
  ),
  _FitPost(
    id: '3',
    username: '@kaito.drip',
    timeAgo: '6h ago',
    tags: ['minimal', 'monochrome'],
    avgScore: 52,
    ratingCount: 18,
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // tracks which vibe the user picked per post id
  final Map<String, Vibe?> _selectedVibes = {};
  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }


  void _rate(String postId, Vibe vibe) {
    setState(() {
      _selectedVibes[postId] = vibe;
    });
    // TODO: write to Firestore here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'rate',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: 'myfit',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No fits yet. Be the first!',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final data = posts[index].data() as Map<String, dynamic>;
              final postId = posts[index].id;
              final selected = _selectedVibes[postId];

              return Column(
                children: [
                  FitCard(
                    username: data['username'] ?? '@unknown',
                    timeAgo: _timeAgo(data['createdAt']),
                    tags: List<String>.from(data['tags'] ?? []),
                    avgScore: (data['avgScore'] ?? 0).toDouble(),
                    ratingCount: data['ratingCount'] ?? 0,
                    imageUrl: data['imageUrl'],
                  ),

                  // Vibe card row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: vibeCards.map((card) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: VibeCardButton(
                              card: card,
                              selected: selected == card.vibe,
                              onTap: () => _rate(postId, card.vibe),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),
                  Divider(color: AppColors.border, height: 1, indent: 16, endIndent: 16),
                  const SizedBox(height: 4),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
