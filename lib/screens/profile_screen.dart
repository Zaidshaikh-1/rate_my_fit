import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'post_detail_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? targetUserId;
  final String? targetUsername;

  const ProfileScreen({super.key, this.targetUserId, this.targetUsername});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _useSimpleQuery = false;

  Future<void> _signOut(BuildContext context) async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildQuery(String uid) {
    final collection = FirebaseFirestore.instance.collection('posts');

    if (_useSimpleQuery) {
      // Fallback: no orderBy, avoids needing a composite index
      return collection.where('userId', isEqualTo: uid).snapshots();
    }

    // Primary: requires composite index (userId ASC, createdAt DESC)
    return collection
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Not signed in'));
    }

    final isCurrentUser =
        widget.targetUserId == null || widget.targetUserId == user.uid;
    final viewUid = widget.targetUserId ?? user.uid;
    final viewUsername =
        widget.targetUsername ?? user.displayName ?? 'Anonymous';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isCurrentUser ? 'My Profile' : viewUsername,
          style: const TextStyle(
            fontFamily: 'Syne',
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: isCurrentUser
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 22),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 22),
                  onPressed: () => _signOut(context),
                ),
              ]
            : null,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _buildQuery(viewUid),
        builder: (context, snapshot) {
          // If the composite-index query fails, fall back to simple query
          if (snapshot.hasError && !_useSimpleQuery) {
            debugPrint(
              'Profile composite-index query failed: ${snapshot.error}',
            );
            debugPrint('Falling back to simple query (no orderBy)...');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _useSimpleQuery = true);
            });
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (snapshot.hasError) {
            debugPrint('Profile query error: ${snapshot.error}');
          }

          // Sort client-side when using the simple (fallback) query
          if (_useSimpleQuery && docs.isNotEmpty) {
            docs.sort((a, b) {
              final aTime = a.data()['createdAt'] as Timestamp?;
              final bTime = b.data()['createdAt'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime); // descending
            });
          }

          final postCount = docs.length;
          double avgScore = 0;
          if (postCount > 0) {
            final total = docs.fold<double>(
              0,
              (sum, d) => sum + ((d.data()['avgScore'] ?? 0) as num).toDouble(),
            );
            avgScore = total / postCount;
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(viewUid)
                      .snapshots(),
                  builder: (context, userSnap) {
                    final data = userSnap.data?.data() as Map<String, dynamic>?;
                    final dbUsername = data?['username'];
                    final dbAvatarUrl = data?['avatarUrl'];

                    return _ProfileHeader(
                      photoUrl:
                          dbAvatarUrl ?? (isCurrentUser ? user.photoURL : null),
                      displayName: dbUsername ?? viewUsername,
                      email: isCurrentUser ? (user.email ?? '') : null,
                      postCount: postCount,
                      avgScore: avgScore,
                    );
                  },
                ),
              ),
              if (snapshot.hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error loading posts:\n${snapshot.error}',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (docs.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No fits posted yet',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.8,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      return _PostThumbnail(
                        imageUrl: data['imageUrl'] as String?,
                        avgScore: ((data['avgScore'] ?? 0) as num).toDouble(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(postId: doc.id),
                            ),
                          );
                        },
                      );
                    }, childCount: docs.length),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final String? email;
  final int postCount;
  final double avgScore;

  const _ProfileHeader({
    this.photoUrl,
    required this.displayName,
    this.email,
    required this.postCount,
    required this.avgScore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.surfaceCard,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? const Icon(Icons.person, size: 44, color: AppColors.textMuted)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: const TextStyle(
              fontFamily: 'Syne',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (email != null && email!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatBlock(label: 'Fits', value: '$postCount'),
              const SizedBox(width: 32),
              _StatBlock(
                label: 'Avg Score',
                value: postCount > 0 ? avgScore.toStringAsFixed(0) : '—',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Syne',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _PostThumbnail extends StatefulWidget {
  final String? imageUrl;
  final double avgScore;
  final VoidCallback onTap;

  const _PostThumbnail({
    required this.imageUrl,
    required this.avgScore,
    required this.onTap,
  });

  @override
  State<_PostThumbnail> createState() => _PostThumbnailState();
}

class _PostThumbnailState extends State<_PostThumbnail>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              image: widget.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(widget.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                if (widget.imageUrl == null)
                  const Center(
                    child: Icon(
                      Icons.photo,
                      color: AppColors.textMuted,
                      size: 28,
                    ),
                  ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.avgScore.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
