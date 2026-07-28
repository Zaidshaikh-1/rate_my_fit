import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class FitCard extends StatefulWidget {
  final String username;
  final String? avatarUrl;
  final String? imageUrl;
  final String timeAgo;
  final List<String> tags;
  final double avgScore;
  final int ratingCount;
  final List<Map<String, dynamic>> outfitItems;
  final VoidCallback? onTapProfile;

  const FitCard({
    super.key,
    required this.username,
    required this.timeAgo,
    required this.tags,
    required this.avgScore,
    required this.ratingCount,
    this.avatarUrl,
    this.imageUrl,
    this.outfitItems = const [],
    this.onTapProfile,
  });

  @override
  State<FitCard> createState() => _FitCardState();
}

class _FitCardState extends State<FitCard> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String get _scoreLabel {
    if (widget.avgScore >= 85) return 'Drip';
    if (widget.avgScore >= 65) return 'Clean';
    if (widget.avgScore >= 30) return 'Mid';
    return 'Not it';
  }

  Color get _scoreColor {
    if (widget.avgScore >= 85) return AppColors.drip;
    if (widget.avgScore >= 65) return AppColors.clean;
    if (widget.avgScore >= 30) return AppColors.mid;
    return AppColors.notIt;
  }

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

  @override
  Widget build(BuildContext context) {
    final hasOutfitItems = widget.outfitItems.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                // Avatar + Name clickable area
                GestureDetector(
                  onTap: widget.onTapProfile,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.border,
                          image: widget.avatarUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(widget.avatarUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.avatarUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 20,
                                color: AppColors.textMuted,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.username,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(fontSize: 14),
                          ),
                          Text(
                            widget.timeAgo,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Score badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _scoreColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _scoreColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    _scoreLabel,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _scoreColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ──── Swipeable image area ────
          AspectRatio(
            aspectRatio: 4 / 5,
            child: hasOutfitItems
                ? PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Page 1: The Image
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.border,
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
                                  Icons.photo_size_select_actual_outlined,
                                  size: 48,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            // ── Swipe hint badge ──
                            Positioned(
                              bottom: 12,
                              right:
                                  12, // moved to right to indicate swiping left goes to next page
                              child: _SwipeHintBadge(),
                            ),
                          ],
                        ),
                      ),

                      // Page 2: Outfit Details Panel
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1A1A2E),
                              Color(0xFF16213E),
                              Color(0xFF0F3460),
                            ],
                          ),
                        ),
                        child: _OutfitInfoPanel(
                          items: widget.outfitItems,
                          onOpenUrl: _openUrl,
                          onClose: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.border,
                      image: widget.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(widget.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: widget.imageUrl == null
                        ? const Center(
                            child: Icon(
                              Icons.photo_size_select_actual_outlined,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                          )
                        : null,
                  ),
          ),

          // Tags + rating count
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.tags
                        .map((tag) => _TagChip(label: tag))
                        .toList(),
                  ),
                ),
                Text(
                  '${widget.ratingCount} ratings',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  OUTFIT INFO PANEL —  revealed when image is swiped right
// ────────────────────────────────────────────────────────────

class _OutfitInfoPanel extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Future<void> Function(String url) onOpenUrl;
  final VoidCallback onClose;

  const _OutfitInfoPanel({
    required this.items,
    required this.onOpenUrl,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No outfit details',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.checkroom_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Outfit Breakdown',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Text(
            'Swipe left to go back',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),

          const SizedBox(height: 14),

          // ── Item list ──
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final name = (item['name'] ?? '') as String;
                final url = (item['url'] ?? '') as String;
                final hasUrl = url.isNotEmpty;

                return GestureDetector(
                  onTap: hasUrl ? () => onOpenUrl(url) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.2),
                                AppColors.primary.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (hasUrl) ...[
                                const SizedBox(height: 2),
                                Text(
                                  url,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (hasUrl)
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  SWIPE HINT BADGE — shown on top of image
// ────────────────────────────────────────────────────────────

class _SwipeHintBadge extends StatefulWidget {
  @override
  State<_SwipeHintBadge> createState() => _SwipeHintBadgeState();
}

class _SwipeHintBadgeState extends State<_SwipeHintBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.6,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _shimmer, curve: Curves.easeInOut)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swipe_right_rounded, size: 14, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              'Swipe for outfit',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#$label',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
