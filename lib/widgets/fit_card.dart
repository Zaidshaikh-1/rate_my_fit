import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FitCard extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final String? imageUrl;
  final String timeAgo;
  final List<String> tags;
  final double avgScore;
  final int ratingCount;

  const FitCard({
    super.key,
    required this.username,
    required this.timeAgo,
    required this.tags,
    required this.avgScore,
    required this.ratingCount,
    this.avatarUrl,
    this.imageUrl,
  });

  String get _scoreLabel {
    if (avgScore >= 85) return 'Drip';
    if (avgScore >= 65) return 'Clean';
    if (avgScore >= 30) return 'Mid';
    return 'Not it';
  }

  Color get _scoreColor {
    if (avgScore >= 85) return AppColors.drip;
    if (avgScore >= 65) return AppColors.clean;
    if (avgScore >= 30) return AppColors.mid;
    return AppColors.notIt;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.border,
                    image: avatarUrl != null
                        ? DecorationImage(
                            image: NetworkImage(avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: avatarUrl == null
                      ? const Icon(Icons.person, size: 20, color: AppColors.textMuted)
                      : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                          ),
                    ),
                    Text(
                      timeAgo,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                const Spacer(),
                // Score badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

          // Outfit image
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.border,
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
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
                    children: tags
                        .map((tag) => _TagChip(label: tag))
                        .toList(),
                  ),
                ),
                Text(
                  '$ratingCount ratings',
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
