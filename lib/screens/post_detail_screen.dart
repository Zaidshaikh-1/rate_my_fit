import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/fit_card.dart';
import '../widgets/vibe_card_button.dart';
import '../widgets/vibe_reaction_overlay.dart';
import 'profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isDeleting = false;
  final GlobalKey<VibeReactionOverlayState> _overlayKey =
      GlobalKey<VibeReactionOverlayState>();

  Future<void> _openUrl(String url) async {
    var uri = url;
    if (!uri.startsWith('http://') && !uri.startsWith('https://')) {
      uri = 'https://$uri';
    }
    final parsed = Uri.tryParse(uri);
    if (parsed != null && await canLaunchUrl(parsed)) {
      await launchUrl(parsed, mode: LaunchMode.externalApplication);
    }
  }

  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'just now';
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _rate(Vibe vibe) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 🎬 Play the reaction animation immediately
    _overlayKey.currentState?.playReaction(vibe);

    final vibeCard = vibeCards.firstWhere((c) => c.vibe == vibe);
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);
    final ratingRef = postRef.collection('ratings').doc(user.uid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final ratingSnap = await transaction.get(ratingRef);
      final postSnap = await transaction.get(postRef);
      if (!postSnap.exists) return;

      final postData = postSnap.data() as Map<String, dynamic>;
      int ratingCount = (postData['ratingCount'] ?? 0) as int;
      double totalScore = ((postData['totalScore'] ?? 0) as num).toDouble();

      if (ratingSnap.exists) {
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

  Future<void> _deletePost(Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete this fit?',
          style: TextStyle(
            fontFamily: 'Syne',
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'This action cannot be undone. Your fit and all its ratings will be permanently removed.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      // Delete image from Storage
      final imageUrl = data['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          debugPrint('Could not delete image from Storage: $e');
        }
      }

      // Delete all sub-collection ratings first
      final ratingsSnap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('ratings')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final ratingDoc in ratingsSnap.docs) {
        batch.delete(ratingDoc.reference);
      }
      // Delete the post document itself
      batch.delete(
        FirebaseFirestore.instance.collection('posts').doc(widget.postId),
      );
      await batch.commit();

      if (mounted) {
        Navigator.pop(context, true); // return true to signal deletion
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Fit Detail',
          style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isDeleting
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.redAccent),
                  SizedBox(height: 16),
                  Text(
                    'Deleting fit...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text(
                      'Post not found',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                final data = snapshot.data!.data()!;
                final isOwner = currentUser?.uid == data['userId'];
                final imageUrl = data['imageUrl'] as String?;
                final tags = List<String>.from(data['tags'] ?? []);
                final avgScore = ((data['avgScore'] ?? 0) as num).toDouble();
                final ratingCount = (data['ratingCount'] ?? 0) as int;
                final username = data['username'] ?? 'Anonymous';
                final avatarUrl = data['avatarUrl'] as String?;
                final createdAt = data['createdAt'] as Timestamp?;
                final outfitItems =
                    (data['outfitItems'] as List<dynamic>?)
                        ?.map((e) => Map<String, dynamic>.from(e as Map))
                        .toList() ??
                    [];

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ──── Post card with reaction overlay ────
                      Stack(
                        children: [
                          FitCard(
                            username: username,
                            timeAgo: _timeAgo(createdAt),
                            tags: tags,
                            avgScore: avgScore,
                            ratingCount: ratingCount,
                            imageUrl: imageUrl,
                            avatarUrl: avatarUrl,
                            outfitItems: outfitItems,
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

                          // ── Reaction animation overlay ──
                          Positioned.fill(
                            child: VibeReactionOverlay(key: _overlayKey),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // ──── Vibe rating buttons ────
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: currentUser == null
                            ? null
                            : FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(widget.postId)
                                  .collection('ratings')
                                  .doc(currentUser.uid)
                                  .snapshots(),
                        builder: (context, ratingSnap) {
                          final myVibeName =
                              ratingSnap.data?.data()?['vibe'] as String?;
                          final selected = myVibeName != null
                              ? Vibe.values.firstWhere(
                                  (v) => v.name == myVibeName,
                                )
                              : null;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: vibeCards.map((card) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: VibeCardButton(
                                      card: card,
                                      selected: selected == card.vibe,
                                      onTap: () => _rate(card.vibe),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // ──── Stats row ────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _DetailStat(
                                icon: Icons.star_rounded,
                                label: 'Avg Score',
                                value: ratingCount > 0
                                    ? avgScore.toStringAsFixed(1)
                                    : '—',
                                color: AppColors.primary,
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: AppColors.border,
                              ),
                              _DetailStat(
                                icon: Icons.how_to_vote_rounded,
                                label: 'Ratings',
                                value: '$ratingCount',
                                color: AppColors.clean,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ──── Outfit Breakdown ────
                      if (outfitItems.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.checkroom_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Outfit Breakdown',
                                      style: TextStyle(
                                        fontFamily: 'Syne',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...outfitItems.map((item) {
                                  final name = (item['name'] ?? '') as String;
                                  final url = (item['url'] ?? '') as String;
                                  final hasUrl = url.isNotEmpty;
                                  return GestureDetector(
                                    onTap: hasUrl ? () => _openUrl(url) : null,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.08),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.shopping_bag_outlined,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                                if (hasUrl)
                                                  Text(
                                                    url,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.primary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (hasUrl)
                                            Icon(
                                              Icons.open_in_new_rounded,
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // ──── Delete button (owner only) ────
                      if (isOwner) ...[
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _deletePost(data),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                              label: const Text('Delete this Fit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: BorderSide(
                                  color: Colors.redAccent.withOpacity(0.4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
