import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/fit_card.dart';
import '../widgets/vibe_card_button.dart';
import '../widgets/vibe_reaction_overlay.dart';
import 'post_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Overlay keys mapped by post document ID
  final Map<String, GlobalKey<VibeReactionOverlayState>> _overlayKeys = {};
  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'just now';
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Get or create an overlay key for a particular post
  GlobalKey<VibeReactionOverlayState> _overlayKeyFor(String postId) {
    return _overlayKeys.putIfAbsent(
      postId,
      () => GlobalKey<VibeReactionOverlayState>(),
    );
  }

  Future<void> _rate(String postId, Vibe vibe) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 🎬 Play the reaction animation immediately
    _overlayKeyFor(postId).currentState?.playReaction(vibe);

    final vibeCard = vibeCards.firstWhere((c) => c.vibe == vibe);
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    final ratingRef = postRef.collection('ratings').doc(user.uid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final ratingSnap = await transaction.get(ratingRef);
      final postSnap = await transaction.get(postRef);
      if (!postSnap.exists) return;

      final postData = postSnap.data() as Map<String, dynamic>;
      int ratingCount = (postData['ratingCount'] ?? 0) as int;
      double totalScore = ((postData['totalScore'] ?? 0) as num).toDouble();

      if (ratingSnap.exists) {
        // user is changing their vote — swap old score for new
        final oldScore = ((ratingSnap.data()?['score'] ?? 0) as num).toDouble();
        totalScore = totalScore - oldScore + vibeCard.score;
      } else {
        ratingCount += 1;
        totalScore += vibeCard.score;
      }

      final newAvg = ratingCount > 0 ? totalScore / ratingCount : 0.0;

      transaction.set(ratingRef, {
        'vibe': vibe.name,
        'score': vibeCard.score,
        'ratedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(postRef, {
        'ratingCount': ratingCount,
        'totalScore': totalScore,
        'avgScore': newAvg,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No fits yet — be the first to post!',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: currentUserId == null
                    ? null
                    : doc.reference
                          .collection('ratings')
                          .doc(currentUserId)
                          .snapshots(),
                builder: (context, ratingSnap) {
                  final myVibeName =
                      ratingSnap.data?.data()?['vibe'] as String?;
                  final hasRated = myVibeName != null;
                  final selected = hasRated
                      ? Vibe.values.firstWhere((v) => v.name == myVibeName)
                      : null;

                  return Column(
                    children: [
                      // Wrap the FitCard in a Stack so the reaction overlay
                      // appears on top of the image
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PostDetailScreen(postId: doc.id),
                                ),
                              );
                            },
                            child: FitCard(
                              username: data['username'] ?? 'Anonymous',
                              timeAgo: _timeAgo(
                                data['createdAt'] as Timestamp?,
                              ),
                              tags: List<String>.from(data['tags'] ?? []),
                              avgScore: ((data['avgScore'] ?? 0) as num)
                                  .toDouble(),
                              ratingCount: (data['ratingCount'] ?? 0) as int,
                              imageUrl: data['imageUrl'] as String?,
                              avatarUrl: data['avatarUrl'] as String?,
                              outfitItems:
                                  (data['outfitItems'] as List<dynamic>?)
                                      ?.map(
                                        (e) =>
                                            Map<String, dynamic>.from(e as Map),
                                      )
                                      .toList() ??
                                  [],
                              onTapProfile: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileScreen(
                                      targetUserId: data['userId'],
                                      targetUsername: data['username'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // ── Reaction animation overlay ──
                          Positioned.fill(
                            child: VibeReactionOverlay(
                              key: _overlayKeyFor(doc.id),
                            ),
                          ),
                        ],
                      ),
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
                                  onTap: () => _rate(doc.id, card.vibe),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Divider(
                        color: AppColors.border,
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      const SizedBox(height: 4),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
